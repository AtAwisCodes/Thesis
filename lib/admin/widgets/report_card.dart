import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.reportId,
    required this.data,
    required this.onTap,
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
            const SizedBox(height: 12),
            Text(
              videoTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reported by: $reporterEmail',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
