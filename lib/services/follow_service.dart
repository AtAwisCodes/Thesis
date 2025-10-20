import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Follow a user
  Future<bool> followUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == targetUserId) {
        return false;
      }

      final currentUserId = currentUser.uid;

      // Add to following collection for current user
      await _firestore
          .collection('count')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .set({
        'followedAt': FieldValue.serverTimestamp(),
        'userId': targetUserId,
      });

      // Add to followers collection for target user
      await _firestore
          .collection('count')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({
        'followedAt': FieldValue.serverTimestamp(),
        'userId': currentUserId,
      });

      // Update follower/following counts
      await _firestore.collection('count').doc(targetUserId).update({
        'followersCount': FieldValue.increment(1),
      });

      await _firestore.collection('count').doc(currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });

      // Send notification to the followed user
      await _notificationService.sendFollowNotification(
        targetUserId: targetUserId,
        followerUserId: currentUserId,
      );

      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == targetUserId) {
        return false;
      }

      final currentUserId = currentUser.uid;

      // Remove from following collection for current user
      await _firestore
          .collection('count')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .delete();

      // Remove from followers collection for target user
      await _firestore
          .collection('count')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .delete();

      // Update follower/following counts
      await _firestore.collection('count').doc(targetUserId).update({
        'followersCount': FieldValue.increment(-1),
      });

      await _firestore.collection('count').doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Check if current user is following target user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == targetUserId) {
        return false;
      }

      final doc = await _firestore
          .collection('count')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  /// Get followers count for a user
  Future<int> getFollowersCount(String userId) async {
    try {
      final doc = await _firestore.collection('count').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['followersCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting followers count: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final doc = await _firestore.collection('count').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['followingCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  /// Get list of followers for a user
  Stream<List<Map<String, dynamic>>> getFollowers(String userId) {
    return _firestore
        .collection('count')
        .doc(userId)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> followers = [];

      for (var doc in snapshot.docs) {
        final followerUserId = doc.data()['userId'];
        final userDoc =
            await _firestore.collection('count').doc(followerUserId).get();

        if (userDoc.exists) {
          followers.add({
            'userId': followerUserId,
            'firstName': userDoc.data()?['first_name'] ?? '',
            'lastName': userDoc.data()?['last_name'] ?? '',
            'avatarUrl': userDoc.data()?['avatar_url'] ?? '',
            'followedAt': doc.data()['followedAt'],
          });
        }
      }

      return followers;
    });
  }

  /// Get list of users that current user is following
  Stream<List<Map<String, dynamic>>> getFollowing(String userId) {
    return _firestore
        .collection('count')
        .doc(userId)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> following = [];

      for (var doc in snapshot.docs) {
        final followingUserId = doc.data()['userId'];
        final userDoc =
            await _firestore.collection('count').doc(followingUserId).get();

        if (userDoc.exists) {
          following.add({
            'userId': followingUserId,
            'firstName': userDoc.data()?['first_name'] ?? '',
            'lastName': userDoc.data()?['last_name'] ?? '',
            'avatarUrl': userDoc.data()?['avatar_url'] ?? '',
            'followedAt': doc.data()['followedAt'],
          });
        }
      }

      return following;
    });
  }

  /// Get list of follower IDs (for sending notifications)
  Future<List<String>> getFollowerIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('count')
          .doc(userId)
          .collection('followers')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      print('Error getting follower IDs: $e');
      return [];
    }
  }
}
