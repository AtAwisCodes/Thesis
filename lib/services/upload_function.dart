import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoUploadResult {
  final bool success;
  final String? videoId;
  final String? publicUrl;
  final String? error;

  VideoUploadResult({
    required this.success,
    this.videoId,
    this.publicUrl,
    this.error,
  });

  factory VideoUploadResult.success({
    required String videoId,
    required String publicUrl,
  }) {
    return VideoUploadResult(
      success: true,
      videoId: videoId,
      publicUrl: publicUrl,
    );
  }

  factory VideoUploadResult.failure(String error) {
    return VideoUploadResult(
      success: false,
      error: error,
    );
  }
}

class VideoUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Upload video with progress callback
  Future<VideoUploadResult> uploadVideoWithProgress({
    required String videoPath,
    required String title,
    required String description,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      // Step 1: Validate user authentication
      onProgress(0.1, 'Checking authentication...');
      final user = _auth.currentUser;
      if (user == null) {
        return VideoUploadResult.failure("User not authenticated");
      }

      // Step 2: Validate file
      onProgress(0.2, 'Validating video file...');
      final file = File(videoPath);
      if (!await file.exists()) {
        return VideoUploadResult.failure("Video file not found");
      }

      final fileSize = await file.length();
      const maxFileSize = 100 * 1024 * 1024; // 100MB limit
      if (fileSize > maxFileSize) {
        return VideoUploadResult.failure("File size exceeds 100MB limit");
      }

      // Step 3: Generate file path and name
      onProgress(0.3, 'Preparing upload...');
      final fileExtension = path.extension(videoPath).toLowerCase();
      var fileName = '${_uuid.v4()}$fileExtension';
      var filePath = '${user.uid}/$fileName';

      // Step 4: Upload to Supabase Storage
      onProgress(0.4, 'Uploading to storage...');
      try {
        await _supabase.storage
            .from('videos')
            .upload(filePath, File(videoPath));
      } catch (e) {
        if (e.toString().contains('already exists')) {
          final newFileName =
              '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
          final newFilePath = '${user.uid}/$newFileName';

          await _supabase.storage
              .from('videos')
              .upload(newFilePath, File(videoPath));

          fileName = newFileName;
          filePath = newFilePath;
        } else {
          throw e;
        }
      }
      onProgress(0.7, 'Getting public URL...');

      // Step 5: Get public URL
      final publicUrl = _supabase.storage.from('videos').getPublicUrl(filePath);

      onProgress(0.8, 'Saving metadata...');

      // Step 6: Create metadata (includes userId)
      final videoMetadata = {
        'userId': user.uid,
        'title': title,
        'description': description,
        'fileName': fileName,
        'originalName': path.basename(videoPath),
        'filePath': filePath,
        'publicUrl': publicUrl,
        'fileSize': fileSize,
        'mimeType': _getAndroidMimeType(fileExtension),
        'duration': null,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': user.email,
        'userEmail': user.email,
        'userDisplayName': user.displayName ?? 'Anonymous',
        'status': 'active',
        'views': 0,
        'likes': 0,
        'tags': [],
        'isPublic': true,
      };

      // Step 7: Save to Firestore (global collection only)
      onProgress(0.9, 'Finalizing...');
      final docRef = await _firestore.collection('videos').add(videoMetadata);

      // Step 8: Add videoId field
      await docRef.update({'videoId': docRef.id});

      onProgress(1.0, 'Upload completed!');

      return VideoUploadResult.success(
        videoId: docRef.id,
        publicUrl: publicUrl,
      );
    } catch (e) {
      return VideoUploadResult.failure(e.toString());
    }
  }

  // Delete video from Supabase + Firestore
  Future<bool> deleteVideo({
    required String videoId,
    required String filePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Delete from Supabase Storage
      await _supabase.storage.from('videos').remove([filePath]);

      // Delete from global collection only
      await _firestore.collection('videos').doc(videoId).delete();

      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // Get all public videos
  Stream<List<Map<String, dynamic>>> getPublicVideos({int limit = 20}) {
    return _firestore
        .collection('videos')
        .where('status', isEqualTo: 'active')
        .where('isPublic', isEqualTo: true)
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

  // Get videos uploaded by current user
  Stream<List<Map<String, dynamic>>> getUserVideos() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('videos')
        .where('userId', isEqualTo: user.uid)
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

  // Update video metadata
  Future<bool> updateVideoMetadata({
    required String videoId,
    String? title,
    String? description,
    bool? isPublic,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (tags != null) updateData['tags'] = tags;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Update only in global videos collection
      await _firestore.collection('videos').doc(videoId).update(updateData);

      return true;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }

  // Determine MIME type
  String _getAndroidMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp4':
        return 'video/mp4';
      case '.webm':
        return 'video/webm';
      case '.3gp':
        return 'video/3gpp';
      default:
        return 'video/mp4'; // fallback to mp4
    }
  }

  // Get video analytics
  Future<Map<String, int>> getVideoAnalytics(String videoId) async {
    try {
      final doc = await _firestore.collection('videos').doc(videoId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'views': data['views'] ?? 0,
          'likes': data['likes'] ?? 0,
        };
      }
      return {'views': 0, 'likes': 0};
    } catch (_) {
      return {'views': 0, 'likes': 0};
    }
  }

  // Increment views
  Future<void> incrementViews(String videoId) async {
    try {
      await _firestore.collection('videos').doc(videoId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to increment views: $e');
    }
  }

  // Toggle like
  Future<void> toggleLike(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userLikeDoc = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('likes')
          .doc(user.uid);

      final likeExists = await userLikeDoc.get();

      if (likeExists.exists) {
        await userLikeDoc.delete();
        await _firestore.collection('videos').doc(videoId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        await userLikeDoc.set({
          'userId': user.uid,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('videos').doc(videoId).update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Failed to toggle like: $e');
    }
  }
}

//Posts count function
Future<void> incrementPostCount(String uid) async {
  final userDoc = FirebaseFirestore.instance.collection('videos').doc(uid);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(userDoc);

    if (!snapshot.exists) {
      transaction.set(userDoc, {'posts': 1});
    } else {
      final currentCount = snapshot['posts'] ?? 0;
      transaction.update(userDoc, {'posts': currentCount + 1});
    }
  });
}
