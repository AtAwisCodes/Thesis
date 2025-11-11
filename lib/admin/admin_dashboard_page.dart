import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rexplore/admin/widgets/report_card.dart';
import 'package:rexplore/admin/widgets/stats_card.dart';
import 'package:rexplore/admin/report_detail_page.dart';
import 'package:rexplore/admin/user_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _currentFilter = 'all';

  Map<String, int> _stats = {
    'pending': 0,
    'reviewing': 0,
    'resolved': 0,
    'dismissed': 0,
  };

  Future<void> _logout() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 8),
              Text('You are logging out.'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with logout
    if (confirmed == true) {
      try {
        await _auth.signOut();
      } catch (e) {
        print('Logout error: $e');
      }
    }
  }

  Stream<QuerySnapshot> _getReportsStream() {
    Query query = _firestore
        .collection('video_reports')
        .orderBy('createdAt', descending: true);

    if (_currentFilter != 'all') {
      query = query.where('status', isEqualTo: _currentFilter);
    }

    return query.snapshots();
  }

  /// Filter out YouTube video reports and only show user-uploaded video reports
  List<QueryDocumentSnapshot> _filterUserUploadedReports(
      List<QueryDocumentSnapshot> reports) {
    return reports.where((report) {
      final data = report.data() as Map<String, dynamic>;
      final videoUrl = data['videoUrl'] as String? ?? '';

      // Exclude YouTube videos (contain 'youtube.com' or 'youtu.be')
      return !videoUrl.contains('youtube.com') &&
          !videoUrl.contains('youtu.be');
    }).toList();
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
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard, size: 28),
            SizedBox(width: 12),
            Text(
              'User Video Reports',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'User Management',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserManagementPage(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allReports = snapshot.data!.docs;

          // Filter out YouTube video reports, only show user-uploaded videos
          final reports = _filterUserUploadedReports(allReports);

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
                        InkWell(
                          onTap: () {
                            setState(() => _currentFilter = 'pending');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: StatsCard(
                            title: 'Pending',
                            count: _stats['pending']!,
                            icon: Icons.pending,
                            color: Colors.orange,
                            width: cardWidth,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _currentFilter = 'reviewing');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: StatsCard(
                            title: 'Reviewing',
                            count: _stats['reviewing']!,
                            icon: Icons.remove_red_eye,
                            color: Colors.blue,
                            width: cardWidth,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _currentFilter = 'resolved');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: StatsCard(
                            title: 'Resolved',
                            count: _stats['resolved']!,
                            icon: Icons.check_circle,
                            color: Colors.green,
                            width: cardWidth,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _currentFilter = 'dismissed');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: StatsCard(
                            title: 'Dismissed',
                            count: _stats['dismissed']!,
                            icon: Icons.cancel,
                            color: Colors.red,
                            width: cardWidth,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Filter by Status Section
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
                      : _buildUnifiedReportView(reports),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build unified view showing one entry per video per status (grouped by videoId and status)
  Widget _buildUnifiedReportView(List<QueryDocumentSnapshot> reports) {
    // If showing all reports, group by videoId only (merge all statuses)
    // If filtering by specific status, show individual reports
    if (_currentFilter == 'all') {
      return _buildGroupedByVideoView(reports);
    } else {
      return _buildIndividualReportsView(reports);
    }
  }

  /// Build view with reports grouped by videoId (for "All Reports" filter)
  Widget _buildGroupedByVideoView(List<QueryDocumentSnapshot> reports) {
    // Group reports by videoId only
    final groupedReports = <String, List<QueryDocumentSnapshot>>{};
    for (var report in reports) {
      final data = report.data() as Map<String, dynamic>;
      final videoId = data['videoId'] as String? ?? '';

      if (videoId.isNotEmpty) {
        groupedReports.putIfAbsent(videoId, () => []);
        groupedReports[videoId]!.add(report);
      }
    }

    // Sort by number of reports (most reported first)
    final sortedVideoIds = groupedReports.keys.toList()
      ..sort((a, b) =>
          groupedReports[b]!.length.compareTo(groupedReports[a]!.length));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedVideoIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final videoId = sortedVideoIds[index];
        final videoReports = groupedReports[videoId]!;
        final reportCount = videoReports.length;

        // Use the first report as the representative
        final report = videoReports.first;
        final data = report.data() as Map<String, dynamic>;

        return InkWell(
          onTap: () {
            // If multiple reports, show dialog to select which one to view
            if (reportCount > 1) {
              _showVideoReportsDialog(videoReports, data['videoTitle']);
            } else {
              // Single report, go directly to detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailPage(
                    reportId: report.id,
                    reportData: data,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: reportCount > 3
                    ? Colors.red
                    : reportCount > 1
                        ? Colors.orange
                        : Colors.grey[300]!,
                width: reportCount > 3 ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: reportCount > 3
                  ? Colors.red.withOpacity(0.05)
                  : reportCount > 1
                      ? Colors.orange.withOpacity(0.05)
                      : null,
            ),
            child: Stack(
              children: [
                // Main report card
                ReportCard(
                  reportId: report.id,
                  data: data,
                  showStatusAndReason: false,
                  showReportedBy: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailPage(
                          reportId: report.id,
                          reportData: data,
                        ),
                      ),
                    );
                  },
                ),
                // Report count badge (only if multiple reports for same video)
                if (reportCount > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reportCount > 3 ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.layers,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$reportCount Reports',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // High priority indicator
                if (reportCount > 3)
                  Positioned(
                    top: 48,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high,
                              size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'HIGH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build view with individual reports (for specific status filters)
  Widget _buildIndividualReportsView(List<QueryDocumentSnapshot> reports) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final report = reports[index];
        final data = report.data() as Map<String, dynamic>;

        return ReportCard(
          reportId: report.id,
          data: data,
          showStatusAndReason: false,
          showReportedBy: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailPage(
                  reportId: report.id,
                  reportData: data,
                ),
              ),
            );
          },
        );
      },
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

  /// Show dialog with all reports for a video when there are multiple
  void _showVideoReportsDialog(
      List<QueryDocumentSnapshot> reports, String? videoTitle) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.video_library, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          videoTitle ?? 'Untitled Video',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reports.length} ${reports.length == 1 ? 'Report' : 'Reports'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text(
                'Select a report to view details:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final data = report.data() as Map<String, dynamic>;
                    return ReportCard(
                      reportId: report.id,
                      data: data,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(
                              reportId: report.id,
                              reportData: data,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
