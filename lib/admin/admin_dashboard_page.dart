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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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
        // Don't navigate manually - let the StreamBuilder in main_admin.dart handle it
        // The authStateChanges stream will automatically show the login page
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

  /// Delete all YouTube video reports from the database (one-time cleanup)
  Future<void> _deleteYouTubeReports() async {
    try {
      final allReports = await _firestore.collection('video_reports').get();

      int deletedCount = 0;

      for (var doc in allReports.docs) {
        final data = doc.data();
        final videoUrl = data['videoUrl'] as String? ?? '';

        // Delete if it's a YouTube video report
        if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
          await doc.reference.delete();
          deletedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deleted $deletedCount YouTube video reports'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting YouTube reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              '📊 User Video Reports',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Delete YouTube Reports (Cleanup)',
            color: Colors.red[700],
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Delete YouTube Reports?'),
                    ],
                  ),
                  content: const Text(
                    'This will permanently delete all YouTube video reports from the database. User-uploaded video reports will remain. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await _deleteYouTubeReports();
              }
            },
          ),
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
                        StatsCard(
                          title: 'Pending',
                          count: _stats['pending']!,
                          icon: Icons.pending,
                          color: Colors.orange,
                          width: cardWidth,
                        ),
                        StatsCard(
                          title: 'Reviewing',
                          count: _stats['reviewing']!,
                          icon: Icons.remove_red_eye,
                          color: Colors.blue,
                          width: cardWidth,
                        ),
                        StatsCard(
                          title: 'Resolved',
                          count: _stats['resolved']!,
                          icon: Icons.check_circle,
                          color: Colors.green,
                          width: cardWidth,
                        ),
                        StatsCard(
                          title: 'Dismissed',
                          count: _stats['dismissed']!,
                          icon: Icons.cancel,
                          color: Colors.red,
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Filters
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
                  child: Wrap(
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
                            return ReportCard(
                              reportId: report.id,
                              data: data,
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
                        ),
                ),
              ],
            ),
          );
        },
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
}
