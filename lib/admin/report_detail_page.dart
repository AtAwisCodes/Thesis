import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'dart:html' as html;

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const ReportDetailPage({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;
  bool _isProcessing = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.reportData['videoUrl'] as String?;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      setState(() {
        _isLoadingVideo = true;
        _videoError = null;
      });
      try {
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        setState(() => _isLoadingVideo = false);
      } catch (e) {
        print('Video initialization error: $e');
        setState(() {
          _isLoadingVideo = false;
          _videoError = e.toString();
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus,
      {bool showSnackbar = true}) async {
    setState(() => _isProcessing = true);
    try {
      await _firestore.collection('video_reports').doc(widget.reportId).update({
        'status': newStatus,
        'reviewedBy': _auth.currentUser?.email,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted && newStatus == 'resolved') {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text(
          'This will hide the video from public view. You can restore it later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final videoId = widget.reportData['videoId'] as String?;
      if (videoId != null) {
        // Soft delete: Mark video as deleted instead of removing it
        await _firestore.collection('videos').doc(videoId).update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': _auth.currentUser?.email,
          'deleteReason': 'Reported content violation',
        });
      }

      // Mark report as resolved
      await _updateStatus('resolved', showSnackbar: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Video deleted successfully. Can be restored if needed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _restoreVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Video'),
        content: const Text(
          'This will make the video visible again to all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final videoId = widget.reportData['videoId'] as String?;
      if (videoId != null) {
        // Restore video by removing deleted flags
        await _firestore.collection('videos').doc(videoId).update({
          'isDeleted': false,
          'restoredAt': FieldValue.serverTimestamp(),
          'restoredBy': _auth.currentUser?.email,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendWarning() async {
    final textController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a custom warning message to send to the video uploader:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Your content has been reported for...',
                border: const OutlineInputBorder(),
                counterStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      textController.dispose();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final uploaderId = widget.reportData['uploaderId'] as String?;
      if (uploaderId != null && textController.text.isNotEmpty) {
        // Create a warning notification in the user's notifications subcollection
        await _firestore
            .collection('count')
            .doc(uploaderId)
            .collection('notifications')
            .add({
          'type': 'warning',
          'title': 'Content Warning',
          'message': textController.text,
          'videoId': widget.reportData['videoId'],
          'videoTitle': widget.reportData['videoTitle'],
          'reportId': widget.reportId,
          'fromUserId': _auth.currentUser?.uid ?? 'admin',
          'fromUserName': 'Admin',
          'fromUserAvatar': '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update report status
        await _updateStatus('resolved', showSnackbar: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending warning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      textController.dispose();
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'inappropriate':
        return 'Inappropriate Content';
      case 'spam':
        return 'Spam';
      case 'misleading':
        return 'Misleading';
      case 'copyright':
        return 'Copyright Violation';
      case 'violence':
        return 'Violence';
      case 'hatespeech':
        return 'Hate Speech';
      case 'other':
        return 'Other';
      default:
        return reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData;
    final status = data['status'] as String? ?? 'pending';
    final reason = data['reason'] as String? ?? 'other';
    final description = data['description'] as String? ?? '';
    final videoTitle = data['videoTitle'] as String? ?? 'Untitled Video';
    final reporterEmail = data['reporterEmail'] as String? ?? 'Unknown';
    final uploaderEmail = data['uploaderEmail'] as String? ?? 'Unknown';
    final videoUrl = data['videoUrl'] as String? ?? '';
    final createdAt = data['createdAt'] as dynamic;

    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      try {
        final timestamp = createdAt;
        final date = timestamp is int
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : (timestamp as dynamic).toDate() as DateTime;
        formattedDate = DateFormat('MMMM dd, yyyy HH:mm').format(date);
      } catch (e) {
        print('Date parsing error: $e');
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            if (videoUrl.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoadingVideo
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _videoError != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.grey.shade900,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.video_library_outlined,
                                        size: 80,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Video Preview Unavailable',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Browser doesn\'t support this video format',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Open video in new tab
                                          html.window.open(videoUrl, '_blank');
                                        },
                                        icon: const Icon(Icons.open_in_new),
                                        label:
                                            const Text('Open Video in New Tab'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: () {
                                          // Copy URL to clipboard
                                          Clipboard.setData(
                                              ClipboardData(text: videoUrl));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Video URL copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy Video URL'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _videoController != null &&
                                _videoController!.value.isInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AspectRatio(
                                      aspectRatio:
                                          _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_videoController!
                                              .value.isPlaying) {
                                            _videoController!.pause();
                                          } else {
                                            _videoController!.play();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Video unavailable',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
              ),
              const SizedBox(height: 20),
            ],

            // Report Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 30),
                  _buildInfoRow('Status', status.toUpperCase(),
                      valueColor: _getStatusColor(status)),
                  _buildInfoRow('Reason', _formatReason(reason)),
                  _buildInfoRow('Video Title', videoTitle),
                  _buildInfoRow('Reported By', reporterEmail),
                  _buildInfoRow('Uploader', uploaderEmail),
                  _buildInfoRow('Date Reported', formattedDate),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Check if video is deleted
                  FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('videos')
                        .doc(widget.reportData['videoId'])
                        .get(),
                    builder: (context, snapshot) {
                      final isDeleted = snapshot.hasData &&
                          (snapshot.data?.data()
                                  as Map<String, dynamic>?)?['isDeleted'] ==
                              true;

                      // If video is deleted, show restore button
                      if (isDeleted) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'This video has been deleted',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _restoreVideo,
                              icon: const Icon(Icons.restore),
                              label: const Text('Restore Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Normal action buttons if not resolved/dismissed
                      if (status == 'resolved' || status == 'dismissed') {
                        return const Text(
                          'This report has been closed.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (status != 'reviewing')
                            ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _updateStatus('reviewing'),
                              icon: const Icon(Icons.visibility),
                              label: const Text('Mark as Reviewing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _sendWarning,
                            icon: const Icon(Icons.warning),
                            label: const Text('Send Warning'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _deleteVideo,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _updateStatus('dismissed'),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Dismiss Report'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
