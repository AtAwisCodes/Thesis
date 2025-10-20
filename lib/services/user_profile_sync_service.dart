import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

// Update all videos uploaded by the user with new profile info
  Future<void> syncUserProfileToVideos({
    required String userId,
    required String firstName,
    required String lastName,
    required String avatarUrl,
  }) async {
    try {
      print('Syncing profile to videos for user: $userId');

      // Query all videos uploaded by this user
      final videosSnapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .get();

      print('📹 Found ${videosSnapshot.docs.length} videos to update');

      // Batch update for efficiency
      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in videosSnapshot.docs) {
        batch.update(doc.reference, {
          'firstName': firstName,
          'lastName': lastName,
          'avatarUrl': avatarUrl,
        });
        updateCount++;
      }

      if (updateCount > 0) {
        await batch.commit();
        print('Updated $updateCount video documents');
      } else {
        print('No videos to update');
      }
    } catch (e) {
      print('Error syncing profile to videos: $e');
      rethrow;
    }
  }

// Update all comments made by the user with new profile info
  Future<void> syncUserProfileToComments({
    required String userId,
    required String firstName,
    required String lastName,
    required String avatarUrl,
  }) async {
    try {
      print('Syncing profile to comments for user: $userId');

      // Get all videos
      final videosSnapshot = await _firestore.collection('videos').get();

      int totalCommentsUpdated = 0;

      // For each video, update comments by this user
      for (var videoDoc in videosSnapshot.docs) {
        final commentsSnapshot = await videoDoc.reference
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get();

        if (commentsSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();

          for (var commentDoc in commentsSnapshot.docs) {
            batch.update(commentDoc.reference, {
              'firstName': firstName,
              'lastName': lastName,
              'avatarUrl': avatarUrl,
            });
            totalCommentsUpdated++;
          }

          await batch.commit();
        }
      }

      print('Updated $totalCommentsUpdated comment documents');
    } catch (e) {
      print('Error syncing profile to comments: $e');
      rethrow;
    }
  }

// Update user profile in history entries
  Future<void> syncUserProfileToHistory({
    required String userId,
    required String firstName,
    required String lastName,
    required String avatarUrl,
  }) async {
    try {
      print('Syncing profile to history for user: $userId');

      // Update history entries where this user is the uploader
      final historySnapshot = await _firestore
          .collection('history')
          .where('uploaderUserId', isEqualTo: userId)
          .get();

      if (historySnapshot.docs.isEmpty) {
        print('No history entries to update');
        return;
      }

      final batch = _firestore.batch();

      for (var doc in historySnapshot.docs) {
        batch.update(doc.reference, {
          'firstName': firstName,
          'lastName': lastName,
          'avatarUrl': avatarUrl,
        });
      }

      await batch.commit();
      print('Updated ${historySnapshot.docs.length} history entries');
    } catch (e) {
      print('Error syncing profile to history: $e');
      // Don't rethrow - history sync is not critical
    }
  }

// Sync user profile changes across all user-related data
  Future<void> syncAllUserData({
    String? userId,
    required String firstName,
    required String lastName,
    required String avatarUrl,
  }) async {
    try {
      // Use provided userId or get current user
      final uid = userId ?? _auth.currentUser?.uid;

      if (uid == null) {
        throw Exception('No user ID provided and no user logged in');
      }

      print('Starting full profile sync for user: $uid');
      print('Name: $firstName $lastName');
      print('Avatar: ${avatarUrl.isNotEmpty ? "Updated" : "Empty"}');

      // Run all sync operations
      await Future.wait([
        syncUserProfileToVideos(
          userId: uid,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: avatarUrl,
        ),
        syncUserProfileToComments(
          userId: uid,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: avatarUrl,
        ),
        syncUserProfileToHistory(
          userId: uid,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: avatarUrl,
        ),
      ]);

      print('Profile sync completed successfully');
    } catch (e) {
      print('Error in full profile sync: $e');
      rethrow;
    }
  }

  /// Stream user profile data for real-time updates
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore
        .collection('count')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  /// Get user profile data once
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('count').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
}
