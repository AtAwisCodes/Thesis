import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import 'ar_model_service.dart';

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
  final NotificationService _notificationService = NotificationService();
  final ARModelService _arModelService = ARModelService();

  //DITO MO LAGAY IP MO LANS YESHUA DE GUZMAN
  static const String _backendUrl = 'http://192.168.100.25:5000';
  
  // Remove.bg API key for background removal
  static const String _removeBgApiKey = 'V2BJ2X9HigKJ7hFJqp8TeUNu';

  //Upload AR model images to Supabase bucket "ar_pics" (for AR models only)
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
      final response = await http
          .post(
        Uri.parse('$_backendUrl/api/generate-3d'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'user_id': user.uid,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Backend connection timeout. Is the backend running at $_backendUrl?');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        print('Backend error (${response.statusCode}): $errorBody');
        throw Exception('Failed to generate 3D model: $errorBody');
      }

      final data = jsonDecode(response.body);
      final taskId = data['task_id'];

      if (taskId == null || taskId.isEmpty) {
        throw Exception('Backend returned empty task_id');
      }

      onStatusUpdate('3D model generation started (Task: $taskId)');
      print('3D generation task created: $taskId');

      // Step 2: Poll for completion (you can also use SSE for real-time updates)
      return await _pollModelCompletion(
        taskId: taskId,
        userId: user.uid,
        onStatusUpdate: onStatusUpdate,
      );
    } on http.ClientException catch (e) {
      final errorMsg =
          'Cannot connect to backend at $_backendUrl. Is it running? Error: $e';
      print('$errorMsg');
      onStatusUpdate(errorMsg);
      return null;
    } catch (e) {
      final errorMsg = 'Error generating 3D model: $e';
      print('$errorMsg');
      onStatusUpdate(errorMsg);
      return null;
    }
  }

  //Poll Meshy AI for model completion
  Future<Map<String, dynamic>?> _pollModelCompletion({
    required String taskId,
    required String userId,
    required Function(String status) onStatusUpdate,
  }) async {
    int attempts = 0;
    const maxAttempts =
        120; // 10 minutes max (5s intervals) - Meshy can be slow

    print(
        'Starting polling for task: $taskId (max ${maxAttempts * 5} seconds)');

    try {
      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 5));

        // Check status from backend
        print('Polling attempt ${attempts + 1}/$maxAttempts for task: $taskId');
        final statusResponse = await http
            .get(
          Uri.parse('$_backendUrl/api/model-status/$taskId'),
        )
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Status check timed out, will retry...');
            throw Exception('Status check timeout');
          },
        );

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          final status = statusData['status'];
          final progress = statusData['progress'] ?? 0;

          print('Status received: "$status" | Progress: $progress%');
          onStatusUpdate('Model generation: $status ($progress%)');

          // Check status case-insensitively (Meshy returns UPPERCASE)
          final statusLower = status?.toString().toLowerCase();

          if (statusLower == 'succeeded') {
            // Model is ready, fetch it immediately
            onStatusUpdate('Model completed! Fetching GLB file...');

            final fetchResult = await _fetchCompletedModel(
              taskId: taskId,
              userId: userId,
              onStatusUpdate: onStatusUpdate,
            );

            if (fetchResult != null && fetchResult['success'] == true) {
              print('GLB file downloaded and saved!');
              print('   Model URL: ${fetchResult['model_public_url']}');
              print('   Firestore ID: ${fetchResult['firestore_doc_id']}');
              onStatusUpdate('3D model ready for AR!');
              return fetchResult;
            } else {
              print('Fetch returned null or failed');
              onStatusUpdate('Model completed but download failed');
              return null;
            }
          } else if (statusLower == 'failed' || statusLower == 'canceled') {
            throw Exception('Model generation $status');
          }
        } else {
          print('Status check failed with code: ${statusResponse.statusCode}');
          print('Response: ${statusResponse.body}');
        }

        attempts++;
      }

      final timeoutMsg =
          'Model generation timed out after ${maxAttempts * 5} seconds';
      print(timeoutMsg);
      throw Exception(timeoutMsg);
    } on http.ClientException catch (e) {
      // Network error - don't fail immediately, let it retry
      print('Network error during polling (attempt $attempts): $e');
      return null;
    } catch (e) {
      // Only fail on non-timeout errors
      if (e.toString().contains('Status check timeout')) {
        print('Temporary timeout, continuing polling...');
        return null;
      }
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
    required List<File>? modelImages,
    required File? thumbnailImage,
    String? disposalCategory,
    List<String>? customSteps,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      // Step 1: Validate user authentication
      onProgress(0.05, 'Checking authentication...');
      final user = _auth.currentUser;
      if (user == null) {
        return VideoUploadResult.failure("User not authenticated");
      }

      // Step 1.5: Check if user is suspended or deleted
      onProgress(0.07, 'Checking account status...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Check if user is deleted
        final isDeleted = userData['isDeleted'] ?? false;
        if (isDeleted) {
          return VideoUploadResult.failure(
              "Your account has been deleted by administrators. You cannot upload videos.");
        }

        // Check if user is suspended
        final isSuspended = userData['isSuspended'] ?? false;
        if (isSuspended) {
          final suspensionReason =
              userData['suspensionReason'] ?? 'Community guideline violations';
          final suspensionEndDate = userData['suspensionEndDate'] as Timestamp?;

          // Check if suspension has expired
          if (suspensionEndDate != null) {
            final endDate = suspensionEndDate.toDate();
            if (DateTime.now().isAfter(endDate)) {
              // Auto-unsuspend
              await _firestore.collection('users').doc(user.uid).update({
                'isSuspended': false,
              });
              // Allow upload to continue
            } else {
              // Still suspended
              final daysLeft = endDate.difference(DateTime.now()).inDays + 1;
              return VideoUploadResult.failure(
                  "Your account is suspended for $daysLeft more day(s). Reason: $suspensionReason");
            }
          } else {
            // No end date specified, account is permanently suspended
            return VideoUploadResult.failure(
                "Your account is suspended. Reason: $suspensionReason");
          }
        }
      }

      // Step 2: Validate file
      onProgress(0.1, 'Validating video file...');
      final file = File(videoPath);
      if (!await file.exists()) {
        return VideoUploadResult.failure("Video file not found");
      }

      final fileSize = await file.length();
      const maxFileSize =
          2 * 1024 * 1024 * 1024; // 2GB limit (supports longer HD videos)
      if (fileSize > maxFileSize) {
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        return VideoUploadResult.failure(
            "File size ($fileSizeMB MB) exceeds 2GB limit. Please compress your video.");
      }

      // Log file size for debugging
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      print('Video file size: $fileSizeMB MB');

      // Step 3: Upload thumbnail image if provided
      String thumbnailUrl = '';
      if (thumbnailImage != null) {
        onProgress(0.12, 'Uploading thumbnail...');
        final ext = path.extension(thumbnailImage.path).toLowerCase();
        final thumbnailFileName = '${_uuid.v4()}$ext';
        final thumbnailFilePath = '${user.uid}/thumbnails/$thumbnailFileName';

        await _supabase.storage
            .from('videos')
            .upload(thumbnailFilePath, thumbnailImage);
        thumbnailUrl =
            _supabase.storage.from('videos').getPublicUrl(thumbnailFilePath);
        onProgress(0.15, 'Thumbnail uploaded');
      }

      // Step 4: Upload AR model images if provided (for AR models only)
      List<String> modelImageUrls = [];
      if (modelImages != null && modelImages.isNotEmpty) {
        onProgress(0.18, 'Uploading AR model images...');
        modelImageUrls = await uploadModelImages(
          imageFiles: modelImages,
          userId: user.uid,
          onProgress: (imgProgress, imgStatus) {
            // Scale progress from 0.18 to 0.28
            onProgress(0.18 + (imgProgress * 0.1), imgStatus);
          },
        );
      }

      // Step 5: Generate file path and name
      onProgress(0.3, 'Preparing video upload...');
      final fileExtension = path.extension(videoPath).toLowerCase();
      var fileName = '${_uuid.v4()}$fileExtension';
      var filePath = '${user.uid}/$fileName';

      // Step 6: Upload video to Supabase Storage with timeout and retry
      onProgress(0.4, 'Uploading video to storage...');
      try {
        // Use upsert to handle conflicts and set longer timeout
        await _supabase.storage.from('videos').upload(
              filePath,
              File(videoPath),
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true, // Overwrite if exists
              ),
            );
      } catch (e) {
        print('Upload error: $e');

        // Handle specific error cases
        if (e.toString().contains('already exists')) {
          try {
            final newFileName =
                '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
            final newFilePath = '${user.uid}/$newFileName';

            await _supabase.storage.from('videos').upload(
                  newFilePath,
                  File(videoPath),
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: true,
                  ),
                );

            fileName = newFileName;
            filePath = newFilePath;
          } catch (retryError) {
            print('Retry upload failed: $retryError');
            return VideoUploadResult.failure(
                'Failed to upload video after retry: ${retryError.toString()}');
          }
        } else if (e.toString().contains('Payload') ||
            e.toString().contains('size') ||
            e.toString().contains('limit')) {
          return VideoUploadResult.failure(
              'Video file is too large for upload. Please compress your video or use a shorter duration.');
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('network')) {
          return VideoUploadResult.failure(
              'Upload timeout. Please check your internet connection and try again.');
        } else {
          return VideoUploadResult.failure(
              'Upload failed: ${e.toString()}. Please try again.');
        }
      }
      onProgress(0.6, 'Video uploaded. Getting URL...');

      // Step 7: Get public URL
      final publicUrl = _supabase.storage.from('videos').getPublicUrl(filePath);

      // Step 8: Fetch uploader profile
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

      // Step 9: Create video metadata with model images and thumbnail
      final videoMetadata = {
        'userId': user.uid,
        'title': title,
        'description': description,
        'fileName': fileName,
        'originalName': path.basename(videoPath),
        'filePath': filePath,
        'publicUrl': publicUrl,
        'thumbnailUrl': thumbnailUrl,
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
        'modelImages': modelImageUrls, //Store AR model image URLs (for reference)
        'has3DModel': false, // 3D models are generated separately, not from upload images
        'disposalCategory': disposalCategory, // Store disposal category
        'customSteps': customSteps, // Store custom steps
      };

      // Step 10: Save to Firestore
      onProgress(0.8, 'Saving to database...');
      final docRef = await _firestore.collection('videos').add(videoMetadata);

      // Step 11: Add videoId field
      await docRef.update({'videoId': docRef.id});
      final videoId = docRef.id;

      // Step 11.5: Process model images into AR models (if provided)
      // Model images are ONLY used for AR models, not for 3D model generation
      if (modelImages != null && modelImages.isNotEmpty) {
        onProgress(0.85, 'Processing AR models...');
        await _processModelImagesIntoARModels(
          videoId: videoId,
          modelImages: modelImages,
          onProgress: (progress, status) {
            // Scale from 0.85 to 1.0 (AR models are the final step)
            onProgress(0.85 + (progress * 0.15), status);
          },
        );
      }

      onProgress(1.0, 'Video upload completed! AR models ready.');

      // Send notification to followers about new video (asynchronously)
      _sendNewVideoNotificationAsync(
        videoId: docRef.id,
        userId: user.uid,
        videoTitle: title,
        thumbnailUrl: thumbnailUrl,
      );

      return VideoUploadResult.success(
        videoId: docRef.id,
        publicUrl: publicUrl,
      );
    } catch (e) {
      print('Upload error: $e');
      return VideoUploadResult.failure(e.toString());
    }
  }


  //Send notification to followers asynchronously (non-blocking)
  Future<void> _sendNewVideoNotificationAsync({
    required String videoId,
    required String userId,
    required String videoTitle,
    required String thumbnailUrl,
  }) async {
    try {
      print('Sending new video notifications to followers...');
      await _notificationService.sendNewVideoNotification(
        uploaderUserId: userId,
        videoId: videoId,
        videoTitle: videoTitle,
        videoThumbnailUrl: thumbnailUrl,
      );
      print('New video notifications sent successfully');
    } catch (e) {
      print('Error sending new video notifications: $e');
      // Don't fail the upload if notification fails
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

  //Check if backend is healthy and accessible
  Future<bool> isBackendHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Backend health check timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  //Get video model status with details
  Future<Map<String, dynamic>> getModelStatus(String videoId) async {
    try {
      final doc = await _firestore.collection('videos').doc(videoId).get();
      if (!doc.exists) {
        return {'exists': false};
      }

      final data = doc.data()!;
      return {
        'exists': true,
        'has3DModel': data['has3DModel'] ?? false,
        'generatedModelUrl': data['generatedModelUrl'],
        'modelGenerationError': data['modelGenerationError'],
        'modelGenerationAttemptedAt': data['modelGenerationAttemptedAt'],
        'modelGeneratedAt': data['modelGeneratedAt'],
      };
    } catch (e) {
      print('Error getting model status: $e');
      return {'exists': false, 'error': e.toString()};
    }
  }

  //Fetch uploaded models from backend storage
  /// Fetches all uploaded models from the backend storage
  /// This calls the backend API to get models that are actually stored in Supabase
  Future<List<Map<String, dynamic>>> fetchUploadedModelsFromStorage({
    String? userId,
    String? videoId,
  }) async {
    try {
      print('Fetching uploaded models from backend storage...');
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (userId != null) {
        queryParams['user_id'] = userId;
      }
      if (videoId != null) {
        queryParams['video_id'] = videoId;
      }

      final uri = Uri.parse('$_backendUrl/api/models/list')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('Calling backend API: $uri');

      final response = await http
          .get(uri)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Backend connection timeout while fetching models');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<Map<String, dynamic>> models = [];
        if (data is List) {
          models = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('models')) {
          models = List<Map<String, dynamic>>.from(data['models']);
        } else if (data is Map && data.containsKey('data')) {
          models = List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Unexpected response format from backend: $data');
          return [];
        }

        print('Successfully fetched ${models.length} models from backend storage');
        return models;
      } else {
        print('Backend returned error status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch models: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      final errorMsg = 'Cannot connect to backend at $_backendUrl. Is it running? Error: $e';
      print(errorMsg);
      return [];
    } catch (e) {
      print('Error fetching uploaded models from storage: $e');
      return [];
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

  /// Remove background from image using remove.bg API
  Future<File?> _removeBackground(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );

      request.headers['X-Api-Key'] = _removeBgApiKey;
      request.files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));
      request.fields['size'] = 'auto';

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'ar_model_$timestamp.png';
        final outputPath = path.join(tempDir.path, fileName);
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(bytes);
        return outputFile;
      } else {
        print('Background removal failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error removing background: $e');
      return null;
    }
  }

  /// Process model images into AR models during video upload
  /// This creates AR models with background removal, uploads to Supabase, and saves to Firestore
  Future<void> _processModelImagesIntoARModels({
    required String videoId,
    required List<File> modelImages,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      if (modelImages.isEmpty) return;

      final totalImages = modelImages.length;
      double step = 1.0 / totalImages;
      double currentProgress = 0.0;

      for (int i = 0; i < totalImages; i++) {
        final imageFile = modelImages[i];
        
        onProgress(
          currentProgress,
          'Processing AR model ${i + 1}/$totalImages (removing background)...',
        );

        // Step 1: Remove background
        final processedFile = await _removeBackground(imageFile);
        
        if (processedFile == null) {
          print('Failed to remove background for image ${i + 1}, skipping...');
          currentProgress += step;
          continue;
        }

        onProgress(
          currentProgress + (step * 0.3),
          'Processing AR model ${i + 1}/$totalImages (uploading)...',
        );

        // Step 2: Upload to AR models (using ARModelService)
        // Generate model name based on index
        final modelName = 'Model ${i + 1}';
        
        final result = await _arModelService.uploadARModel(
          videoId: videoId,
          imageFile: processedFile,
          modelName: modelName,
        );

        if (result != null) {
          print('AR model ${i + 1} created successfully: ${result['modelId']}');
        } else {
          print('Failed to create AR model ${i + 1}');
        }

        currentProgress += step;
        onProgress(
          currentProgress,
          'AR model ${i + 1}/$totalImages completed',
        );
      }

      onProgress(1.0, 'All AR models processed successfully');
    } catch (e) {
      print('Error processing model images into AR models: $e');
      // Don't throw - allow video upload to complete even if AR processing fails
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
