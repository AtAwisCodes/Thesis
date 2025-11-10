import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, suspended, deleted
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore.collection('users');

    // Filter by status
    if (_filterStatus == 'suspended') {
      query = query.where('isSuspended', isEqualTo: true);
    } else if (_filterStatus == 'deleted') {
      query = query.where('isDeleted', isEqualTo: true);
    } else if (_filterStatus == 'active') {
      query = query
          .where('isSuspended', isEqualTo: false)
          .where('isDeleted', isEqualTo: false);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Future<Map<String, int>> _getUserStats(String userId) async {
    final videosSnapshot = await _firestore
        .collection('videos')
        .where('uploaderId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .get();

    final reportsSnapshot = await _firestore
        .collection('video_reports')
        .where('uploaderId', isEqualTo: userId)
        .get();

    return {
      'videos': videosSnapshot.docs.length,
      'reports': reportsSnapshot.docs.length,
    };
  }

  Future<void> _suspendUser(
      String userId, Map<String, dynamic> userData) async {
    final reasonController = TextEditingController();
    final durationController = TextEditingController(text: '7');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 8),
            Text('Suspend User'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suspend ${userData['displayName'] ?? 'User'}?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${userData['email'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Suspension Reason',
                  hintText: 'Multiple community guideline violations...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  hintText: '7',
                  border: OutlineInputBorder(),
                  suffixText: 'days',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User will not be able to upload videos or comment during suspension.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('Suspend User'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      durationController.dispose();
      return;
    }

    try {
      final duration = int.tryParse(durationController.text) ?? 7;
      final suspensionEndDate = DateTime.now().add(Duration(days: duration));

      await _firestore.collection('users').doc(userId).update({
        'isSuspended': true,
        'suspensionReason': reasonController.text,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': _auth.currentUser?.email,
        'suspensionEndDate': Timestamp.fromDate(suspensionEndDate),
      });

      // Send notification to user
      await _firestore
          .collection('count')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'suspension',
        'title': 'Account Suspended',
        'message':
            'Your account has been suspended for ${duration} days. Reason: ${reasonController.text}',
        'suspensionEndDate': Timestamp.fromDate(suspensionEndDate),
        'fromUserId': _auth.currentUser?.uid ?? 'admin',
        'fromUserName': 'Admin',
        'fromUserAvatar': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User suspended successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error suspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      reasonController.dispose();
      durationController.dispose();
    }
  }

  Future<void> _unsuspendUser(
      String userId, Map<String, dynamic> userData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Unsuspend User'),
          ],
        ),
        content: Text(
          'Remove suspension from ${userData['displayName'] ?? 'this user'}?\n\nThey will regain full access to the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': false,
        'unsuspendedAt': FieldValue.serverTimestamp(),
        'unsuspendedBy': _auth.currentUser?.email,
      });

      // Send notification
      await _firestore
          .collection('count')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'unsuspension',
        'title': 'Account Restored',
        'message': 'Your account suspension has been lifted. Welcome back!',
        'fromUserId': _auth.currentUser?.uid ?? 'admin',
        'fromUserName': 'Admin',
        'fromUserAvatar': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User suspension removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unsuspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> userData) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User Account'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete ${userData['displayName'] ?? 'User'}?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${userData['email'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deletion Reason',
                  hintText: 'Severe violations, spam account, etc...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• User will not be able to login\n'
                      '• All videos will be hidden\n'
                      '• Profile will be marked as deleted\n'
                      '• User can be restored later if needed',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    try {
      // Mark user as deleted (soft delete)
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletionReason': reasonController.text,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.email,
      });

      // Hide all user's videos
      final videosSnapshot = await _firestore
          .collection('videos')
          .where('uploaderId', isEqualTo: userId)
          .get();

      for (var doc in videosSnapshot.docs) {
        await doc.reference.update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': _auth.currentUser?.email,
          'deleteReason': 'User account deleted',
        });
      }

      // Send notification
      await _firestore
          .collection('count')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'account_deletion',
        'title': 'Account Deleted',
        'message':
            'Your account has been deleted by admin. Reason: ${reasonController.text}',
        'fromUserId': _auth.currentUser?.uid ?? 'admin',
        'fromUserName': 'Admin',
        'fromUserAvatar': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User account deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _restoreUser(
      String userId, Map<String, dynamic> userData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('Restore User Account'),
          ],
        ),
        content: Text(
          'Restore ${userData['displayName'] ?? 'this user'}\'s account?\n\nThey will regain access to the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isDeleted': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': _auth.currentUser?.email,
      });

      // Send notification
      await _firestore
          .collection('count')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'account_restoration',
        'title': 'Account Restored',
        'message': 'Your account has been restored. Welcome back!',
        'fromUserId': _auth.currentUser?.uid ?? 'admin',
        'fromUserName': 'Admin',
        'fromUserAvatar': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User account restored'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people, size: 28),
            SizedBox(width: 12),
            Text(
              '👥 User Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 16),
                // Filter Chips
                Wrap(
                  spacing: 12,
                  children: [
                    _buildFilterChip('All Users', 'all'),
                    _buildFilterChip('Active', 'active'),
                    _buildFilterChip('Suspended', 'suspended'),
                    _buildFilterChip('Deleted', 'deleted'),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['displayName'] ?? '').toLowerCase();
                    final email = (data['email'] ?? '').toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    return _buildUserCard(user.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _filterStatus == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = filter);
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

  Widget _buildUserCard(String userId, Map<String, dynamic> data) {
    final displayName = data['displayName'] ?? 'Unknown User';
    final email = data['email'] ?? 'No email';
    final isSuspended = data['isSuspended'] ?? false;
    final isDeleted = data['isDeleted'] ?? false;
    final avatarUrl = data['avatarUrl'] as String?;
    final createdAt = data['createdAt'] as dynamic;

    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      try {
        final date = (createdAt as Timestamp).toDate();
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        // Handle date parsing error
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isSuspended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SUSPENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isDeleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DELETED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: $formattedDate',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // User Stats
            FutureBuilder<Map<String, int>>(
              future: _getUserStats(userId),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {'videos': 0, 'reports': 0};
                return Row(
                  children: [
                    _buildStatChip(
                      Icons.video_library,
                      '${stats['videos']} Videos',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.report,
                      '${stats['reports']} Reports',
                      stats['reports']! > 0 ? Colors.red : Colors.grey,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isDeleted && !isSuspended)
                  OutlinedButton.icon(
                    onPressed: () => _suspendUser(userId, data),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Suspend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                if (isSuspended && !isDeleted)
                  ElevatedButton.icon(
                    onPressed: () => _unsuspendUser(userId, data),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Unsuspend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                    ),
                  ),
                if (!isDeleted)
                  OutlinedButton.icon(
                    onPressed: () => _deleteUser(userId, data),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                if (isDeleted)
                  ElevatedButton.icon(
                    onPressed: () => _restoreUser(userId, data),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                    ),
                  ),
              ],
            ),
            // Suspension/Deletion Info
            if (isSuspended || isDeleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSuspended ? Colors.orange : Colors.red).shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isSuspended ? Colors.orange : Colors.red).shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuspended ? 'Suspension Info' : 'Deletion Info',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSuspended && data['suspensionReason'] != null)
                      Text(
                        'Reason: ${data['suspensionReason']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (isDeleted && data['deletionReason'] != null)
                      Text(
                        'Reason: ${data['deletionReason']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
