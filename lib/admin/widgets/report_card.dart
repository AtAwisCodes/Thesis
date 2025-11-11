import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rexplore/admin/user_management_page.dart';

class ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final bool showStatusAndReason;
  final bool showReportedBy;

  const ReportCard({
    super.key,
    required this.reportId,
    required this.data,
    required this.onTap,
    this.showStatusAndReason = true,
    this.showReportedBy = true,
  });

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

  IconData _getReasonIcon(String reason) {
    switch (reason.toLowerCase()) {
      case 'inappropriate':
        return Icons.warning;
      case 'spam':
        return Icons.block;
      case 'misleading':
        return Icons.error_outline;
      case 'copyright':
        return Icons.copyright;
      case 'violence':
        return Icons.dangerous;
      case 'hatespeech':
        return Icons.report;
      case 'other':
        return Icons.info_outline;
      default:
        return Icons.flag;
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
    final status = data['status'] as String? ?? 'pending';
    final reason = data['reason'] as String? ?? 'other';
    final videoTitle = data['videoTitle'] as String? ?? 'Untitled Video';
    final reporterEmail = data['reporterEmail'] as String? ?? 'Unknown';
    final uploaderEmail = data['uploaderEmail'] as String? ?? 'Unknown';
    final createdAt = (data['createdAt'] as dynamic);

    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      try {
        final timestamp = createdAt;
        final date = timestamp is int
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : (timestamp as dynamic).toDate() as DateTime;
        formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(date);
      } catch (e) {
        print('Date parsing error: $e');
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showStatusAndReason)
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reason Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getReasonIcon(reason),
                          size: 14,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatReason(reason),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            if (showStatusAndReason) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    videoTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!showStatusAndReason) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ],
            ),
            if (showReportedBy) ...[
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserManagementPage(
                          initialSearchQuery: reporterEmail,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _HoverableText(
                          text: 'Reported by: $reporterEmail',
                          normalColor: Colors.grey,
                          hoverColor: Colors.blue,
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserManagementPage(
                          initialSearchQuery: uploaderEmail,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.video_library,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _HoverableText(
                          text: 'Uploader: $uploaderEmail',
                          normalColor: Colors.grey,
                          hoverColor: Colors.blue,
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoverable text widget that changes color on hover
class _HoverableText extends StatefulWidget {
  final String text;
  final Color normalColor;
  final Color hoverColor;

  const _HoverableText({
    required this.text,
    required this.normalColor,
    required this.hoverColor,
  });

  @override
  State<_HoverableText> createState() => _HoverableTextState();
}

class _HoverableTextState extends State<_HoverableText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: 14,
          color: _isHovered ? widget.hoverColor : widget.normalColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
