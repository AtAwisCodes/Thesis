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
      print('🎯 ARModelService.uploadARModel called');
      print('   VideoId: $videoId');
      print('   ModelName: $modelName');
      print('   ImageFile: ${imageFile.path}');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      print('✅ User authenticated: ${user.uid}');

      // Get video data to verify uploader
      print('🔍 Fetching video document...');
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (!videoDoc.exists) {
        print('❌ Video not found: $videoId');
        throw Exception('Video not found');
      }

      final videoData = videoDoc.data()!;
      final videoUploaderId = videoData['userId'] as String;
      print('✅ Video found. Uploader: $videoUploaderId');

      // Create storage path: {videoId}/{uploaderId}/{uuid}_{filename}
      final ext = path.extension(imageFile.path).toLowerCase();
      final fileName = '${_uuid.v4()}$ext';
      final filePath = '$videoId/$videoUploaderId/$fileName';

      print('📂 Storage path: models/$filePath');
      print('⬆️ Uploading to Supabase...');

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

      print('✅ Uploaded to Supabase. Public URL: $publicUrl');

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

      print('💾 Saving to Firestore: videos/$videoId/arModels');
      final docRef = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('arModels')
          .add(arModelData);

      await docRef.update({'modelId': docRef.id});

      print('✅ AR model metadata saved to Firestore: ${docRef.id}');
      print('   Full path: videos/$videoId/arModels/${docRef.id}');

      final result = {
        'modelId': docRef.id,
        'imageUrl': publicUrl,
        ...arModelData,
      };

      print('🎉 Successfully created AR model: $modelName');
      return result;
    } catch (e, stackTrace) {
      print('❌ Error uploading AR model: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all AR models for a specific video
  /// Returns all active models for the video - visible to ALL users (not just uploader)
  /// Flow: User uploader → Fill details → Image uploaded to Supabase →
  ///       Firebase gets URL → Firebase stores metadata → Models displayed for video → All users see models
  Stream<List<Map<String, dynamic>>> getVideoARModels(String videoId) {
    print('🔍 ARModelService: Fetching models for videoId: $videoId');
    print('📍 Path: videos/$videoId/arModels');

    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('arModels')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ Firestore stream error in getVideoARModels: $error');
      print('   VideoId: $videoId');
      print('   Error type: ${error.runtimeType}');
    }).map((snapshot) {
      print('📦 Received ${snapshot.docs.length} AR model documents');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No AR models found in videos/$videoId/arModels');
        print('   This could mean:');
        print('   1. No models have been uploaded yet');
        print('   2. All models are marked as inactive');
        print('   3. Firestore security rules are blocking access');
      }

      final models = snapshot.docs.map((doc) {
        final data = doc.data();
        print(
            '   - Model: ${doc.id}, Name: ${data['modelName']}, Active: ${data['isActive']}');
        return {
          'modelId': doc.id,
          ...data,
        };
      }).toList();

      print('✅ Returning ${models.length} active AR models');
      return models;
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
