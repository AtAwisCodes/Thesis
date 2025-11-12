import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rexplore/services/report_service.dart';

class UserFeedbackPage extends StatefulWidget {
  const UserFeedbackPage({super.key});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final ReportService _reportService = ReportService();
  String _currentFilter = 'all';

  Map<String, int> _stats = {
    'pending': 0,
    'reviewed': 0,
    'resolved': 0,
  };

  Stream<List<Map<String, dynamic>>> _getFeedbackStream() {
    if (_currentFilter == 'all') {
      return _reportService.streamUserFeedback();
    }
    return _reportService.streamUserFeedback(status: _currentFilter);
  }

  void _updateStats(List<Map<String, dynamic>> feedbacks) {
    final stats = {
      'pending': 0,
      'reviewed': 0,
      'resolved': 0,
    };

    for (var feedback in feedbacks) {
      final status = feedback['status'] as String? ?? 'pending';
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
    }

    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_currentFilter),
      stream: _getFeedbackStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final feedbacks = snapshot.data!;

        // Update stats
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateStats(feedbacks);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth > 900
                      ? (constraints.maxWidth - 40) / 3
                      : constraints.maxWidth > 600
                          ? (constraints.maxWidth - 20) / 2
                          : constraints.maxWidth;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _currentFilter = 'pending'),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildStatsCard(
                          'Pending',
                          _stats['pending']!,
                          Icons.pending_outlined,
                          Colors.orange,
                          cardWidth,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _currentFilter = 'reviewed'),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildStatsCard(
                          'Reviewed',
                          _stats['reviewed']!,
                          Icons.visibility_outlined,
                          Colors.blue,
                          cardWidth,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _currentFilter = 'resolved'),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildStatsCard(
                          'Resolved',
                          _stats['resolved']!,
                          Icons.check_circle_outline,
                          Colors.green,
                          cardWidth,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // Filter Section
              Container(
                padding: const EdgeInsets.all(16),
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
                      'Filter by Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFilterChip('All Feedback', 'all'),
                        _buildFilterChip('Pending', 'pending'),
                        _buildFilterChip('Reviewed', 'reviewed'),
                        _buildFilterChip('Resolved', 'resolved'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feedback List
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
                child: feedbacks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No feedback found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feedbacks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final feedback = feedbacks[index];
                          return _buildFeedbackCard(feedback);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(
      String title, int count, IconData icon, Color color, double width) {
    return Container(
      width: width,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _currentFilter = filter);
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final feedbackId = feedback['id'] as String;
    final userName = feedback['userName'] as String? ?? 'Anonymous';
    final userEmail = feedback['userEmail'] as String? ?? '';
    final feedbackText = feedback['feedback'] as String? ?? '';
    final status = feedback['status'] as String? ?? 'pending';
    final createdAt = feedback['createdAt'] as Timestamp?;
    final adminNotes = feedback['adminNotes'] as String? ?? '';

    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'reviewed'
            ? Colors.blue
            : Colors.green;

    final statusIcon = status == 'pending'
        ? Icons.pending_outlined
        : status == 'reviewed'
            ? Icons.visibility_outlined
            : Icons.check_circle_outline;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Feedback text
            Text(
              'Feedback:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedbackText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

            if (adminNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Admin Notes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  adminNotes,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Footer info
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  createdAt != null
                      ? DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(createdAt.toDate())
                      : 'Unknown date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                // Action buttons
                if (status != 'resolved')
                  TextButton.icon(
                    onPressed: () =>
                        _showUpdateStatusDialog(feedbackId, status),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update Status'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(String feedbackId, String currentStatus) {
    String selectedStatus = currentStatus;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Feedback Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select new status:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: ['pending', 'reviewed', 'resolved']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Admin Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes or comments...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _reportService.updateFeedbackStatus(
                  feedbackId: feedbackId,
                  status: selectedStatus,
                  adminNotes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Feedback status updated successfully'
                            : 'Failed to update status',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
