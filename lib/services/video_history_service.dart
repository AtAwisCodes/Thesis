import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoHistoryService {
  static final VideoHistoryService _instance = VideoHistoryService._internal();
  factory VideoHistoryService() => _instance;
  VideoHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add video to user's watch history
  Future<void> addToHistory({
    required String videoId,
    required String videoUrl,
    required String title,
    required String thumbnailUrl,
    String? uploadedAt,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? videoType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not logged in, cannot save to history');
        return;
      }

      final historyRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videoHistory')
          .doc(videoId);

      // Check if video already exists in history
      final existingDoc = await historyRef.get();

      if (existingDoc.exists) {
        // Update timestamp and increment view count
        await historyRef.update({
          'lastWatchedAt': FieldValue.serverTimestamp(),
          'watchCount': FieldValue.increment(1),
        });
        print('Updated existing history entry for video: $videoId');
      } else {
        // Create new history entry
        await historyRef.set({
          'videoId': videoId,
          'videoUrl': videoUrl,
          'title': title,
          'thumbnailUrl': thumbnailUrl,
          'uploadedAt': uploadedAt ?? '',
          'avatarUrl': avatarUrl ?? '',
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'videoType': videoType ?? 'uploaded',
          'addedToHistoryAt': FieldValue.serverTimestamp(),
          'lastWatchedAt': FieldValue.serverTimestamp(),
          'watchCount': 1,
        });
        print('Added new video to history: $videoId');
      }
    } catch (e) {
      print('Error adding video to history: $e');
    }
  }

  // Get user's video watch history as a stream
  Stream<List<Map<String, dynamic>>> getHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('videoHistory')
        .orderBy('lastWatchedAt', descending: true)
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

  /// Remove a video from history
  Future<void> removeFromHistory(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videoHistory')
          .doc(videoId)
          .delete();

      print('Removed video from history: $videoId');
    } catch (e) {
      print('Error removing video from history: $e');
    }
  }

  /// Clear all video history
  Future<void> clearHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final historyDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videoHistory')
          .get();

      for (var doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleared all video history');
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Check if a video is in history
  Future<bool> isInHistory(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videoHistory')
          .doc(videoId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking history: $e');
      return false;
    }
  }
}
