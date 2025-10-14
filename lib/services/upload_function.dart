import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  static const String _backendUrl = 'msy_zkhom6uoX6vtWwvnrtsOB5PT01yO049AIXRX';

  //Upload multiple model images to Supabase bucket "ar_pics"
  Future<List<String>> uploadModelImages({
    required List<File> imageFiles,
    required String userId,
    required Function(double progress, String status) onProgress,
  }) async {
    final List<String> publicUrls = [];
    try {
      if (imageFiles.isEmpty) return publicUrls;

      double step = 1.0 / imageFiles.length;
      double currentProgress = 0.0;

      for (int i = 0; i < imageFiles.length; i++) {
        final image = imageFiles[i];
        final ext = path.extension(image.path).toLowerCase();
        final fileName = '${_uuid.v4()}$ext';
        final filePath = '$userId/$fileName';

        onProgress(currentProgress,
            'Uploading image ${i + 1}/${imageFiles.length}...');
        await _supabase.storage.from('ar_pics').upload(filePath, image);

        final publicUrl =
            _supabase.storage.from('ar_pics').getPublicUrl(filePath);
        publicUrls.add(publicUrl);

        currentProgress += step;
        onProgress(
            currentProgress, 'Uploaded image ${i + 1}/${imageFiles.length}');
      }

      onProgress(1.0, 'All images uploaded successfully.');
      return publicUrls;
    } catch (e) {
      print('Error uploading model images: $e');
      rethrow;
    }
  }

  //Generate 3D model from uploaded images via Meshy AI
  Future<Map<String, dynamic>?> generate3DModelFromImages({
    required String videoId,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      onStatusUpdate('Requesting 3D model generation...');

      // Step 1: Call backend to generate 3D model
      final response = await http.post(
        Uri.parse('$_backendUrl/api/generate-3d'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'user_id': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate 3D model: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final taskId = data['task_id'];

      onStatusUpdate('3D model generation started (Task: $taskId)');

      // Step 2: Poll for completion (you can also use SSE for real-time updates)
      return await _pollModelCompletion(
        taskId: taskId,
        userId: user.uid,
        onStatusUpdate: onStatusUpdate,
      );
    } catch (e) {
      print('Error generating 3D model: $e');
      onStatusUpdate('Error: $e');
      return null;
    }
  }

  //Poll Meshy AI for model completion
  Future<Map<String, dynamic>?> _pollModelCompletion({
    required String taskId,
    required String userId,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      int attempts = 0;
      const maxAttempts = 60; // 5 minutes max (5s intervals)

      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 5));

        // Check status from backend
        final statusResponse = await http.get(
          Uri.parse('$_backendUrl/api/model-status/$taskId'),
        );

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          final status = statusData['status'];
          final progress = statusData['progress'] ?? 0;

          onStatusUpdate('Model generation: $status ($progress%)');

          if (status == 'succeeded') {
            // Model is ready, fetch it
            onStatusUpdate('Fetching completed model...');
            return await _fetchCompletedModel(
              taskId: taskId,
              userId: userId,
              onStatusUpdate: onStatusUpdate,
            );
          } else if (status == 'failed' || status == 'canceled') {
            throw Exception('Model generation $status');
          }
        }

        attempts++;
      }

      throw Exception('Model generation timed out');
    } catch (e) {
      print('Error polling model: $e');
      onStatusUpdate('Error: $e');
      return null;
    }
  }

  //Fetch completed model and save to Firestore
  Future<Map<String, dynamic>?> _fetchCompletedModel({
    required String taskId,
    required String userId,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      onStatusUpdate('Downloading and storing model...');

      final response = await http.post(
        Uri.parse('$_backendUrl/api/fetch-model'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': taskId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        onStatusUpdate('3D model ready!');
        return data;
      } else {
        throw Exception('Failed to fetch model: ${response.body}');
      }
    } catch (e) {
      print('Error fetching completed model: $e');
      onStatusUpdate('Error: $e');
      return null;
    }
  }

  //Upload video with automatic 3D model generation
  Future<VideoUploadResult> uploadVideoWithProgress({
    required String videoPath,
    required String title,
    required String description,
    required List<File>? modelImages, //Optional model images
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      // Step 1: Validate user authentication
      onProgress(0.05, 'Checking authentication...');
      final user = _auth.currentUser;
      if (user == null) {
        return VideoUploadResult.failure("User not authenticated");
      }

      // Step 2: Validate file
      onProgress(0.1, 'Validating video file...');
      final file = File(videoPath);
      if (!await file.exists()) {
        return VideoUploadResult.failure("Video file not found");
      }

      final fileSize = await file.length();
      const maxFileSize = 100 * 1024 * 1024; // 100MB limit
      if (fileSize > maxFileSize) {
        return VideoUploadResult.failure("File size exceeds 100MB limit");
      }

      // Step 3: Upload model images if provided
      List<String> modelImageUrls = [];
      if (modelImages != null && modelImages.isNotEmpty) {
        onProgress(0.15, 'Uploading model images...');
        modelImageUrls = await uploadModelImages(
          imageFiles: modelImages,
          userId: user.uid,
          onProgress: (imgProgress, imgStatus) {
            // Scale progress from 0.15 to 0.25
            onProgress(0.15 + (imgProgress * 0.1), imgStatus);
          },
        );
      }

      // Step 4: Generate file path and name
      onProgress(0.3, 'Preparing video upload...');
      final fileExtension = path.extension(videoPath).toLowerCase();
      var fileName = '${_uuid.v4()}$fileExtension';
      var filePath = '${user.uid}/$fileName';

      // Step 5: Upload video to Supabase Storage
      onProgress(0.4, 'Uploading video to storage...');
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
      onProgress(0.6, 'Video uploaded. Getting URL...');

      // Step 6: Get public URL
      final publicUrl = _supabase.storage.from('videos').getPublicUrl(filePath);

      // Step 7: Fetch uploader profile
      onProgress(0.7, 'Fetching user profile...');
      final userProfileDoc =
          await _firestore.collection('count').doc(user.uid).get();

      String avatarUrl = '';
      String firstName = '';
      String lastName = '';

      if (userProfileDoc.exists) {
        final data = userProfileDoc.data()!;
        avatarUrl = data['avatar_url'] ?? '';
        firstName = data['first_name'] ?? '';
        lastName = data['last_name'] ?? '';
      }

      onProgress(0.75, 'Saving video metadata...');

      // Step 8: Create video metadata with model images
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
        'avatarUrl': avatarUrl,
        'firstName': firstName,
        'lastName': lastName,
        'status': 'active',
        'views': 0,
        'likes': 0,
        'tags': [],
        'isPublic': true,
        'modelImages': modelImageUrls, //Store model image URLs
        'has3DModel': false, // Will be updated when model is generated
      };

      // Step 9: Save to Firestore
      onProgress(0.8, 'Saving to database...');
      final docRef = await _firestore.collection('videos').add(videoMetadata);

      // Step 10: Add videoId field
      await docRef.update({'videoId': docRef.id});

      onProgress(0.9, 'Video upload completed!');

      // Step 11: Generate 3D model if model images were uploaded
      if (modelImageUrls.isNotEmpty && modelImageUrls.length >= 3) {
        onProgress(0.95, 'Initiating 3D model generation...');

        // Generate 3D model asynchronously (don't wait for completion)
        _generate3DModelAsync(
          videoId: docRef.id,
          onStatusUpdate: (status) {
            print('3D Model Status: $status');
          },
        );
      }

      onProgress(1.0, 'All done!');

      return VideoUploadResult.success(
        videoId: docRef.id,
        publicUrl: publicUrl,
      );
    } catch (e) {
      print('Upload error: $e');
      return VideoUploadResult.failure(e.toString());
    }
  }

  //Generate 3D model asynchronously (non-blocking)
  Future<void> _generate3DModelAsync({
    required String videoId,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      final modelData = await generate3DModelFromImages(
        videoId: videoId,
        onStatusUpdate: onStatusUpdate,
      );

      if (modelData != null) {
        // Update Firestore with generated model info
        await _firestore.collection('videos').doc(videoId).update({
          'has3DModel': true,
          'generatedModelUrl': modelData['model_public_url'],
          'generatedModelId': modelData['firestore_doc_id'],
          'modelGeneratedAt': FieldValue.serverTimestamp(),
        });

        onStatusUpdate('3D model generated and saved!');
      }
    } catch (e) {
      print('Error in async 3D model generation: $e');
      onStatusUpdate('Failed to generate 3D model: $e');
    }
  }

  //Get generated 3D model URL for a video
  Future<String?> getGeneratedModelUrl(String videoId) async {
    try {
      final doc = await _firestore.collection('videos').doc(videoId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['generatedModelUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting model URL: $e');
      return null;
    }
  }

  //Check if video has a 3D model
  Future<bool> hasGeneratedModel(String videoId) async {
    try {
      final doc = await _firestore.collection('videos').doc(videoId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['has3DModel'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking model status: $e');
      return false;
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

  // Get all public videos (sorted by latest first)
  Stream<List<Map<String, dynamic>>> getPublicVideos() {
    return _firestore
        .collection('videos')
        .orderBy('uploadedAt', descending: true)
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
