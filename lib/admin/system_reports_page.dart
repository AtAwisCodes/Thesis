import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rexplore/services/report_service.dart';

class SystemReportsPage extends StatefulWidget {
  const SystemReportsPage({super.key});

  @override
  State<SystemReportsPage> createState() => _SystemReportsPageState();
}

class _SystemReportsPageState extends State<SystemReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentFilter = 'all';

  Map<String, int> _stats = {
    'pending': 0,
    'reviewing': 0,
    'resolved': 0,
    'dismissed': 0,
  };

  Stream<QuerySnapshot> _getReportsStream() {
    Query query = _firestore
        .collection('system_reports')
        .orderBy('createdAt', descending: true);

    if (_currentFilter != 'all') {
      query = query.where('status', isEqualTo: _currentFilter);
    }

    return query.snapshots();
  }

  void _updateStats(List<QueryDocumentSnapshot> docs) {
    final stats = {
      'pending': 0,
      'reviewing': 0,
      'resolved': 0,
      'dismissed': 0,
    };

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'pending';
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
    }

    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bug_report, size: 28),
            SizedBox(width: 12),
            Text(
              'System Reports',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_currentFilter),
        stream: _getReportsStream(),
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
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          // Update stats whenever data changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateStats(reports);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 1200
                        ? (constraints.maxWidth - 60) / 4
                        : constraints.maxWidth > 800
                            ? (constraints.maxWidth - 40) / 2
                            : constraints.maxWidth;

                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        _buildStatCard(
                          'Pending',
                          _stats['pending']!,
                          Icons.pending,
                          Colors.orange,
                          cardWidth,
                          'pending',
                        ),
                        _buildStatCard(
                          'Reviewing',
                          _stats['reviewing']!,
                          Icons.visibility,
                          Colors.blue,
                          cardWidth,
                          'reviewing',
                        ),
                        _buildStatCard(
                          'Resolved',
                          _stats['resolved']!,
                          Icons.check_circle,
                          Colors.green,
                          cardWidth,
                          'resolved',
                        ),
                        _buildStatCard(
                          'Dismissed',
                          _stats['dismissed']!,
                          Icons.cancel,
                          Colors.red,
                          cardWidth,
                          'dismissed',
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
                          _buildFilterChip('All Reports', 'all'),
                          _buildFilterChip('Pending', 'pending'),
                          _buildFilterChip('Reviewing', 'reviewing'),
                          _buildFilterChip('Resolved', 'resolved'),
                          _buildFilterChip('Dismissed', 'dismissed'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Reports List
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
                  child: reports.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No reports found',
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
                          itemCount: reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            final data = report.data() as Map<String, dynamic>;
                            return _buildReportCard(report.id, data);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color color,
    double width,
    String filter,
  ) {
    return InkWell(
      onTap: () => setState(() => _currentFilter = filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _currentFilter = filter),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    final category = data['categoryDisplay'] as String? ?? 'Unknown';
    final title = data['title'] as String? ?? 'Untitled';
    final description = data['description'] as String? ?? '';
    final reporterName = data['reporterName'] as String? ?? 'Anonymous';
    final createdAt = data['createdAt'] as dynamic;

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

    final categoryValue = data['category'] as String? ?? 'other';
    final categoryIcon =
        SystemReportCategoryExtension.fromString(categoryValue).icon;

    return InkWell(
      onTap: () => _showReportDetailDialog(reportId, data),
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
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  reporterName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
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

  void _showReportDetailDialog(String reportId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _ReportDetailDialog(
        reportId: reportId,
        data: data,
        onStatusChanged: () => setState(() {}),
      ),
    );
  }
}

class _ReportDetailDialog extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onStatusChanged;

  const _ReportDetailDialog({
    required this.reportId,
    required this.data,
    required this.onStatusChanged,
  });

  @override
  State<_ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends State<_ReportDetailDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.data['adminNotes'] as String? ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      final reportService = ReportService();
      await reportService.updateSystemReportStatus(
        reportId: widget.reportId,
        status: newStatus,
        adminNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] as String? ?? 'pending';
    final category = widget.data['categoryDisplay'] as String? ?? 'Unknown';
    final title = widget.data['title'] as String? ?? 'Untitled';
    final description = widget.data['description'] as String? ?? '';
    final reporterName = widget.data['reporterName'] as String? ?? 'Anonymous';
    final reporterEmail = widget.data['reporterEmail'] as String? ?? '';
    final createdAt = widget.data['createdAt'] as dynamic;

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Report Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 30),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Status', status.toUpperCase()),
                    _buildInfoRow('Category', category),
                    _buildInfoRow('Title', title),
                    _buildInfoRow('Reporter', '$reporterName ($reporterEmail)'),
                    _buildInfoRow('Date', formattedDate),
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
                    Text(description, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 24),
                    const Text(
                      'Admin Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      enabled: !_isProcessing,
                      decoration: InputDecoration(
                        hintText: 'Add notes about this report...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (status != 'reviewing')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('reviewing'),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Mark as Reviewing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status != 'resolved')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('resolved'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status != 'dismissed')
                  OutlinedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('dismissed'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Dismiss'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
