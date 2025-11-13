import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// Service for managing video-specific AR models
/// 
/// Features:
/// - Store AR models per video in Supabase (models bucket)
/// - Firebase Firestore stores only the public URL
/// - Only video uploader can delete their models
/// - Models are video-specific (only available for that video)
/// - Automatic background removal integration
class ARModelService {
  static final ARModelService _instance = ARModelService._internal();
  factory ARModelService() => _instance;
  ARModelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  /// Upload AR model image for a specific video
  /// Stores image in Supabase 'models' bucket, publicUrl in Firestore
  Future<Map<String, dynamic>?> uploadARModel({
    required String videoId,
    required File imageFile,
    required String modelName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get video data to verify uploader
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) throw Exception('Video not found');

      final videoData = videoDoc.data()!;
      final videoUploaderId = videoData['userId'] as String;

      // Create storage path: {videoId}/{uploaderId}/{uuid}_{filename}
      final ext = path.extension(imageFile.path).toLowerCase();
      final fileName = '${_uuid.v4()}$ext';
      final filePath = '$videoId/$videoUploaderId/$fileName';

      print('Uploading AR model to Supabase: models/$filePath');

      // Upload image to Supabase Storage (models bucket)
      await _supabase.storage.from('models').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL from Supabase
      final publicUrl = _supabase.storage.from('models').getPublicUrl(filePath);

      print('AR model uploaded to Supabase. Public URL: $publicUrl');

      // Create AR model document in Firestore with public URL
      final arModelData = {
        'videoId': videoId,
        'uploaderId': videoUploaderId,
        'uploaderName': user.displayName ?? 'Anonymous',
        'uploaderEmail': user.email ?? '',
        'modelName': modelName,
        'imageUrl': publicUrl,
        'storagePath': filePath, // Supabase path for deletion
        'storageBucket': 'models', // Supabase bucket name
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .add(arModelData);

      await docRef.update({'modelId': docRef.id});

      print('AR model metadata saved to Firestore: ${docRef.id}');

      return {
        'modelId': docRef.id,
        'imageUrl': publicUrl,
        ...arModelData,
      };
    } catch (e) {
      print('Error uploading AR model: $e');
      return null;
    }
  }

  /// Get all AR models for a specific video
  Stream<List<Map<String, dynamic>>> getVideoARModels(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('arModels')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'modelId': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  /// Get AR models uploaded by current user for a specific video
  Future<List<Map<String, dynamic>>> getMyVideoARModels(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .where('uploaderId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'modelId': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error fetching user AR models: $e');
      return [];
    }
  }

  /// Delete AR model (only by the video uploader)
  /// Deletes from Supabase storage and marks as inactive in Firestore
  Future<bool> deleteARModel({
    required String videoId,
    required String modelId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get video data to verify uploader
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) throw Exception('Video not found');

      final videoData = videoDoc.data()!;
      final videoUploaderId = videoData['userId'] as String;

      // Only video uploader can delete AR models
      if (user.uid != videoUploaderId) {
        throw Exception('Only the video uploader can delete AR models');
      }

      // Get AR model data
      final modelDoc = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .doc(modelId)
          .get();

      if (!modelDoc.exists) throw Exception('AR model not found');

      final modelData = modelDoc.data()!;
      final storagePath = modelData['storagePath'] as String?;
      final storageBucket = modelData['storageBucket'] as String? ?? 'models';

      // Delete from Supabase Storage
      if (storagePath != null) {
        try {
          print('Deleting from Supabase: $storageBucket/$storagePath');
          await _supabase.storage.from(storageBucket).remove([storagePath]);
          print('File deleted from Supabase successfully');
        } catch (e) {
          print('Supabase storage delete warning: $e');
          // Continue even if storage delete fails
        }
      }

      // Mark as inactive (soft delete) in Firestore
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .doc(modelId)
          .update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': user.uid,
      });

      print('AR model marked as inactive in Firestore: $modelId');
      return true;
    } catch (e) {
      print('Error deleting AR model: $e');
      return false;
    }
  }

  /// Check if current user is the video uploader
  Future<bool> isVideoUploader(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) return false;

      final videoData = videoDoc.data()!;
      final videoUploaderId = videoData['userId'] as String;

      return user.uid == videoUploaderId;
    } catch (e) {
      print('Error checking video uploader: $e');
      return false;
    }
  }

  /// Get AR model count for a video
  Future<int> getVideoARModelCount(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting AR model count: $e');
      return 0;
    }
  }

  /// Update AR model name
  Future<bool> updateARModelName({
    required String videoId,
    required String modelId,
    required String newName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get video data to verify uploader
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) throw Exception('Video not found');

      final videoData = videoDoc.data()!;
      final videoUploaderId = videoData['userId'] as String;

      // Only video uploader can update AR models
      if (user.uid != videoUploaderId) {
        throw Exception('Only the video uploader can update AR models');
      }

      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .doc(modelId)
          .update({
        'modelName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating AR model name: $e');
      return false;
    }
  }
}

