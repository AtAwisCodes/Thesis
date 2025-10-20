import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  follow,
  like,
  newVideo,
  comment,
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a follow notification
  Future<void> sendFollowNotification({
    required String targetUserId,
    required String followerUserId,
  }) async {
    try {
      // Get follower info
      final followerDoc =
          await _firestore.collection('count').doc(followerUserId).get();

      if (!followerDoc.exists) return;

      final followerData = followerDoc.data()!;
      final firstName = followerData['first_name'] ?? 'Someone';
      final lastName = followerData['last_name'] ?? '';
      final avatarUrl = followerData['avatar_url'] ?? '';

      // Create notification
      await _firestore
          .collection('count')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': 'follow',
        'title': 'New Follower',
        'message': '$firstName $lastName started following you',
        'fromUserId': followerUserId,
        'fromUserName': '$firstName $lastName'.trim(),
        'fromUserAvatar': avatarUrl,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending follow notification: $e');
    }
  }

  /// Send a like notification
  Future<void> sendLikeNotification({
    required String videoId,
    required String videoOwnerId,
    required String likerUserId,
    required String videoTitle,
  }) async {
    try {
      // Don't send notification if user likes their own video
      if (videoOwnerId == likerUserId) return;

      // Get liker info
      final likerDoc =
          await _firestore.collection('count').doc(likerUserId).get();

      if (!likerDoc.exists) return;

      final likerData = likerDoc.data()!;
      final firstName = likerData['first_name'] ?? 'Someone';
      final lastName = likerData['last_name'] ?? '';
      final avatarUrl = likerData['avatar_url'] ?? '';

      // Create notification
      await _firestore
          .collection('count')
          .doc(videoOwnerId)
          .collection('notifications')
          .add({
        'type': 'like',
        'title': 'New Like',
        'message': '$firstName $lastName liked your video "$videoTitle"',
        'fromUserId': likerUserId,
        'fromUserName': '$firstName $lastName'.trim(),
        'fromUserAvatar': avatarUrl,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending like notification: $e');
    }
  }

  /// Send new video notification to all followers
  Future<void> sendNewVideoNotification({
    required String uploaderUserId,
    required String videoId,
    required String videoTitle,
    required String videoThumbnailUrl,
  }) async {
    try {
      // Get uploader info
      final uploaderDoc =
          await _firestore.collection('count').doc(uploaderUserId).get();

      if (!uploaderDoc.exists) return;

      final uploaderData = uploaderDoc.data()!;
      final firstName = uploaderData['first_name'] ?? 'Someone';
      final lastName = uploaderData['last_name'] ?? '';
      final avatarUrl = uploaderData['avatar_url'] ?? '';

      // Get all followers
      final followersSnapshot = await _firestore
          .collection('count')
          .doc(uploaderUserId)
          .collection('followers')
          .get();

      // Send notification to each follower
      for (var followerDoc in followersSnapshot.docs) {
        final followerId = followerDoc.data()['userId'];

        await _firestore
            .collection('count')
            .doc(followerId)
            .collection('notifications')
            .add({
          'type': 'newVideo',
          'title': 'New Video',
          'message': '$firstName $lastName posted a new video: "$videoTitle"',
          'fromUserId': uploaderUserId,
          'fromUserName': '$firstName $lastName'.trim(),
          'fromUserAvatar': avatarUrl,
          'videoId': videoId,
          'videoTitle': videoTitle,
          'videoThumbnailUrl': videoThumbnailUrl,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print(
          'Sent new video notifications to ${followersSnapshot.docs.length} followers');
    } catch (e) {
      print('Error sending new video notification: $e');
    }
  }

  /// Get notifications for current user
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('count')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('count')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('count')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('count')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get unread notifications count
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('count')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
