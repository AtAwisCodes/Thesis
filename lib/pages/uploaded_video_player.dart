import 'package:flutter/material.dart';
import 'package:rexplore/components/fullscreen_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/augmented_reality/augmented_camera.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/services/follow_service.dart';
import 'package:rexplore/services/notification_service.dart';
import 'package:rexplore/services/video_history_service.dart';
import 'package:rexplore/services/user_profile_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String title;
  final String uploadedAt;
  final String avatarUrl;
  final String firstName;
  final String lastName;
  final String thumbnailUrl;

  const UploadedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.title,
    required this.uploadedAt,
    required this.avatarUrl,
    required this.firstName,
    required this.lastName,
    this.thumbnailUrl = '',
  });

  @override
  State<UploadedVideoPlayer> createState() => _UploadedVideoPlayerState();
}

class _UploadedVideoPlayerState extends State<UploadedVideoPlayer> {
  late VideoPlayerController _controller;
  final List<Map<String, dynamic>> comments = [];
  final _commentController = TextEditingController();
  final VideoUploadService _uploadService = VideoUploadService();
  final FollowService _followService = FollowService();
  final NotificationService _notificationService = NotificationService();
  final VideoHistoryService _historyService = VideoHistoryService();
  final UserProfileSyncService _profileSyncService = UserProfileSyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool _has3DModel = false;
  bool _isCheckingModel = true;
  String? _modelError;
  bool _isLoadingComments = true;
  int _viewCount = 0;
  String? _uploaderUserId;

  @override
  void initState() {
    super.initState();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('UploadedVideoPlayer initialized');
    print('Video ID: ${widget.videoId}');
    print('Video URL: ${widget.videoUrl}');
    print('Title: ${widget.title}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });

    // Load initial liked state
    isLiked = FavoritesManager.instance.contains(widget.videoId);

    // Add video to watch history
    _addToHistory();

    // Increment view count when video is opened
    _incrementViewCount();

    // Check 3D model status
    _check3DModelStatus();

    // Load comments
    _loadComments();

    // Load uploader user ID and check follow status
    _loadUploaderInfo();
  }

  /// Load uploader user ID from video document and check follow status
  Future<void> _loadUploaderInfo() async {
    try {
      if (widget.videoId.isEmpty) return;

      final videoDoc =
          await _firestore.collection('videos').doc(widget.videoId).get();
      if (videoDoc.exists) {
        final data = videoDoc.data()!;
        _uploaderUserId = data['userId'] as String?;

        if (_uploaderUserId != null) {
          // Check if current user is following this uploader
          final following = await _followService.isFollowing(_uploaderUserId!);
          if (mounted) {
            setState(() {
              isFollowed = following;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading uploader info: $e');
    }
  }

  /// Add video to user's watch history
  Future<void> _addToHistory() async {
    await _historyService.addToHistory(
      videoId: widget.videoId,
      videoUrl: widget.videoUrl,
      title: widget.title,
      thumbnailUrl: widget.thumbnailUrl,
      uploadedAt: widget.uploadedAt,
      avatarUrl: widget.avatarUrl,
      firstName: widget.firstName,
      lastName: widget.lastName,
      videoType: 'uploaded',
    );
  }

  // Increment view count in Firestore
  Future<void> _incrementViewCount() async {
    if (widget.videoId.isEmpty) {
      print('Cannot increment views: Video ID is empty');
      return;
    }

    try {
      print('Incrementing view count for video: ${widget.videoId}');
      await _uploadService.incrementViews(widget.videoId);
      print('View count incremented successfully');

      // Fetch updated view count
      await _fetchViewCount();
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Fetch current view count from Firestore
  Future<void> _fetchViewCount() async {
    if (widget.videoId.isEmpty) return;

    try {
      final analytics = await _uploadService.getVideoAnalytics(widget.videoId);
      if (mounted) {
        setState(() {
          _viewCount = analytics['views'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching view count: $e');
    }
  }

  Future<void> _check3DModelStatus() async {
    try {
      final status = await _uploadService.getModelStatus(widget.videoId);

      if (mounted) {
        setState(() {
          _has3DModel = status['has3DModel'] ?? false;
          _modelError = status['modelGenerationError'];
          _isCheckingModel = false;
        });

        // Show success notification if model is ready
        if (_has3DModel && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('3D Model Ready! Tap "View in AR" to explore'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingModel = false;
        });
      }
    }
  }

  // Load comments from Firestore
  Future<void> _loadComments() async {
    if (widget.videoId.isEmpty) {
      print('❌ Cannot load comments: Video ID is empty');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
      return;
    }

    try {
      print('Loading comments for video: ${widget.videoId}');
      print('Path: videos/${widget.videoId}/comments');

      final snapshot = await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${snapshot.docs.length} comments');

      if (mounted) {
        setState(() {
          comments.clear();
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print(
                'Comment: ${data['comment']} by ${data['firstName']} ${data['lastName']}');
            comments.add({
              'id': doc.id,
              ...data,
            });
          }
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments with ordering: $e');
      // If ordering fails, try without ordering
      try {
        print('Retrying without ordering...');
        final snapshot = await _firestore
            .collection('videos')
            .doc(widget.videoId)
            .collection('comments')
            .get();

        print('Loaded ${snapshot.docs.length} comments without ordering');

        if (mounted) {
          setState(() {
            comments.clear();
            for (var doc in snapshot.docs) {
              comments.add({
                'id': doc.id,
                ...doc.data(),
              });
            }
            _isLoadingComments = false;
          });
        }
      } catch (e2) {
        print('Error loading comments without ordering: $e2');
        if (mounted) {
          setState(() {
            _isLoadingComments = false;
          });
        }
      }
    }
  }

  // Add a new comment to Firestore
  Future<void> _addComment(String commentText) async {
    if (widget.videoId.isEmpty) {
      print('Cannot add comment');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to comment')),
          );
        }
        return;
      }

      print('Adding comment for user: ${user.uid}');
      print('Video ID: ${widget.videoId}');

      // Get user info from Firestore
      final userDoc = await _firestore.collection('count').doc(user.uid).get();

      if (!userDoc.exists) {
        print('User document not found in Firestore');
      }

      final userData = userDoc.data();
      print('User data: $userData');

      final String firstName = userData?['first_name'] ?? 'Anonymous';
      final String lastName = userData?['last_name'] ?? '';
      final String avatarUrl = userData?['avatar_url'] ?? '';

      // Add comment to Firestore
      final commentData = {
        'userId': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('Saving comment to: videos/${widget.videoId}/comments');
      print('Comment data: $commentData');

      final docRef = await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add(commentData);

      print('Comment added with ID: ${docRef.id}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload comments to show the new one
      await _loadComments();
    } catch (e) {
      print('Error adding comment: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Delete a comment from Firestore
  Future<void> _deleteComment(String commentId, String commentUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in');
        return;
      }

      // Check if the current user owns this comment
      if (user.uid != commentUserId) {
        print('User ${user.uid} cannot delete comment owned by $commentUserId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only delete your own comments'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('Deleting comment: $commentId');
      print('Path: videos/${widget.videoId}/comments/$commentId');

      await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .doc(commentId)
          .delete();

      print('Comment deleted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload comments
      await _loadComments();
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  Future<void> _confirmDeleteComment(
      String commentId, String commentUserId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != commentUserId) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComment(commentId, commentUserId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  //Updated to use Meshy AR Camera with videoId
  Future<void> _openARCamera() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeshyARCamera(
            videoId: widget.videoId, // Pass the video ID to AR camera
          ),
        ),
      );
    }
  }

  void _enterFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(controller: _controller),
      ),
    );
  }

  Future<void> _toggleLikeAndFavorite() async {
    final videoData = {
      "id": widget.videoId, // Use videoId instead of videoUrl
      "videoId": widget.videoId,
      "title": widget.title,
      "url": widget.videoUrl,
      "publicUrl": widget.videoUrl,
      "uploadedAt": widget.uploadedAt,
      "thumbnailUrl": widget.thumbnailUrl,
      "avatarUrl": widget.avatarUrl,
      "firstName": widget.firstName,
      "lastName": widget.lastName,
      "views": _viewCount,
    };

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        isDisliked = false; // clear dislike
        FavoritesManager.instance.addFavorite(videoData);
      } else {
        FavoritesManager.instance.removeFavorite(widget.videoId);
      }
    });

    // Send like notification if user liked the video
    if (isLiked && _uploaderUserId != null) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _notificationService.sendLikeNotification(
          videoId: widget.videoId,
          videoOwnerId: _uploaderUserId!,
          likerUserId: currentUser.uid,
          videoTitle: widget.title,
        );
      }
    }
  }

  /// Toggle follow/unfollow for the video uploader
  Future<void> _toggleFollow() async {
    if (_uploaderUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to follow user at this time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to follow users'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Don't allow following yourself
    if (currentUser.uid == _uploaderUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot follow yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isFollowed = !isFollowed;
    });

    bool success;
    if (isFollowed) {
      success = await _followService.followUser(_uploaderUserId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Now following ${widget.firstName} ${widget.lastName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      success = await _followService.unfollowUser(_uploaderUserId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unfollowed ${widget.firstName} ${widget.lastName}'),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // If operation failed, revert the state
    if (!success) {
      setState(() {
        isFollowed = !isFollowed;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open comments modal
  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController _dialogCommentController =
            TextEditingController();

        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  final textColor =
                      Theme.of(context).textTheme.bodyMedium?.color;

                  return Column(
                    children: [
                      // drag handle
                      Container(
                        height: 5,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: textColor?.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      Row(
                        children: [
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.comment_rounded,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // comments list
                      Expanded(
                        child: _isLoadingComments
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Loading comments...'),
                                  ],
                                ),
                              )
                            : comments.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.comment_outlined,
                                          size: 48,
                                          color: textColor?.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "No comments yet. Be the first to comment!",
                                          style: TextStyle(
                                            color: textColor?.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = comments[index];
                                      final String commentId =
                                          comment['id'] ?? '';
                                      final String commentUserId =
                                          comment['userId'] ?? '';
                                      final String firstName =
                                          comment['firstName'] ?? 'Anonymous';
                                      final String lastName =
                                          comment['lastName'] ?? '';
                                      final String avatarUrl =
                                          comment['avatarUrl'] ?? '';
                                      final String commentText =
                                          comment['comment'] ?? '';
                                      final String displayName =
                                          "$firstName $lastName".trim();

                                      // Check if current user owns this comment
                                      final currentUser = _auth.currentUser;
                                      final isOwnComment =
                                          currentUser != null &&
                                              currentUser.uid == commentUserId;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: avatarUrl.isNotEmpty
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          backgroundColor: avatarUrl.isEmpty
                                              ? Theme.of(context)
                                                  .iconTheme
                                                  .color
                                                  ?.withOpacity(0.2)
                                              : null,
                                          child: avatarUrl.isEmpty
                                              ? Icon(
                                                  Icons.person,
                                                  color: Theme.of(context)
                                                      .iconTheme
                                                      .color,
                                                )
                                              : null,
                                        ),
                                        title: Text(
                                          displayName.isNotEmpty
                                              ? displayName
                                              : "Anonymous",
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          commentText,
                                          style: TextStyle(color: textColor),
                                        ),
                                        trailing: isOwnComment
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  _confirmDeleteComment(
                                                    commentId,
                                                    commentUserId,
                                                  );
                                                },
                                                tooltip: 'Delete comment',
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                      ),

                      // input
                      SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border(
                              top: BorderSide(
                                color: textColor!.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dialogCommentController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Write a comment...",
                                    hintStyle: TextStyle(
                                        color: textColor.withOpacity(0.6)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: textColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.black54),
                                onPressed: () async {
                                  if (_dialogCommentController
                                      .text.isNotEmpty) {
                                    final commentText =
                                        _dialogCommentController.text;
                                    _dialogCommentController.clear();

                                    // Close keyboard
                                    FocusScope.of(context).unfocus();

                                    // Add comment to Firestore
                                    await _addComment(commentText);

                                    // Update modal state
                                    setModalState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _uploaderUserId != null
            ? _profileSyncService.getUserProfileStream(_uploaderUserId!)
            : Stream.value(null),
        builder: (context, profileSnapshot) {
          // Use real-time data if available, otherwise use widget data
          final firstName =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['first_name'] ?? widget.firstName)
                  : widget.firstName;
          final lastName =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['last_name'] ?? widget.lastName)
                  : widget.lastName;
          final avatarUrl =
              profileSnapshot.hasData && profileSnapshot.data != null
                  ? (profileSnapshot.data!['avatar_url'] ?? widget.avatarUrl)
                  : widget.avatarUrl;

          final uploaderName = "$firstName $lastName".trim();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Video Player
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: _controller.value.isInitialized
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              padding: const EdgeInsets.all(8.0),
                              colors: const VideoProgressColors(
                                playedColor: Colors.red,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.black26,
                              ),
                            ),
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen,
                                    color: Colors.blueGrey),
                                onPressed: _enterFullscreen,
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // View counts
                      Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            '$_viewCount ${_viewCount == 1 ? 'view' : 'views'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Uploader Avatar + Name + Actions
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Uploader info with real-time data
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            uploaderName.isNotEmpty
                                ? uploaderName
                                : "Anonymous",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Like / Dislike / Follow
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: isLiked ? Colors.green : Colors.grey,
                            ),
                            onPressed: _toggleLikeAndFavorite,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down,
                              color: isDisliked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isDisliked = !isDisliked;
                                if (isDisliked) isLiked = false;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowed
                                    ? Colors.grey
                                    : const Color(0xff5BEC84),
                                padding: EdgeInsets.zero,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isFollowed ? "Followed" : "Follow",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFollowed
                                        ? Colors.white70
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // comments trigger
                GestureDetector(
                  onTap: () {
                    if (widget.videoId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comments cannot be loaded.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    _openComments(context);
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.97,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            widget.videoId.isEmpty ? Colors.red : Colors.grey,
                        width: widget.videoId.isEmpty ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (widget.videoId.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.warning,
                                    color: Colors.red, size: 20),
                              ),
                            Text(
                              widget.videoId.isEmpty
                                  ? "Comments (missing something)"
                                  : "Comments...",
                              style: TextStyle(
                                color: widget.videoId.isEmpty
                                    ? Colors.red
                                    : Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        if (comments.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${comments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // Updated Floating Action Button with Model Status
      floatingActionButton: _buildARButton(),
    );
  }

  Widget _buildARButton() {
    if (_isCheckingModel) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: const Text(
          "Checking...",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (_has3DModel) {
      return FloatingActionButton.extended(
        onPressed: _openARCamera,
        backgroundColor: const Color(0xff5BEC84),
        icon: const Icon(Icons.view_in_ar, color: Colors.black),
        label: const Text(
          "View in AR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    if (_modelError != null) {
      return FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('3D Model Error: $_modelError'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implement retry logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Retry feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        label: const Text(
          "Model Failed",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No 3D model available for this video'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.block, color: Colors.white),
      label: const Text(
        "No Model",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
