import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rexplore/services/upload_function.dart';

/// Service to access 3D models directly from Firestore
/// This bypasses the backend for model retrieval, allowing access from any network
/// Also supports fetching from backend storage when needed
class FirestoreModelService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all models for a specific video (bypasses backend)
  /// This works from any network since it connects directly to Firebase
  static Future<List<Map<String, dynamic>>> getModelsForVideo(
    String videoId,
  ) async {
    try {
      print('Fetching models for video: $videoId from Firestore');

      final snapshot = await _firestore
          .collection('generated_models_files')
          .where('videoId', isEqualTo: videoId)
          .where('status', isEqualTo: 'ready')
          .get();

      final models = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['taskId'] = data['taskId'] ?? doc.id; // Fallback to doc ID
        return data;
      }).toList();

      // Sort by createdAt (most recent first)
      models.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      print('Found ${models.length} models for video $videoId');
      return models;
    } catch (e) {
      print('Error fetching models from Firestore: $e');
      return [];
    }
  }

  /// List all available models (bypasses backend)
  /// Optional: filter by userId
  static Future<List<Map<String, dynamic>>> listAllModels({
    String? userId,
  }) async {
    try {
      print('Listing all models from Firestore');

      Query query = _firestore
          .collection('generated_models_files')
          .where('status', isEqualTo: 'ready');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();

      final models = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['taskId'] = data['taskId'] ?? doc.id;
        return data;
      }).toList();

      // Sort by createdAt (most recent first)
      models.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      print('Found ${models.length} total models');
      return models;
    } catch (e) {
      print('Error listing models from Firestore: $e');
      return [];
    }
  }

  /// Check if a video has completed models
  static Future<bool> hasCompletedModel(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection('generated_models_files')
          .where('videoId', isEqualTo: videoId)
          .where('status', isEqualTo: 'ready')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking model status: $e');
      return false;
    }
  }

  /// Get a specific model by ID
  static Future<Map<String, dynamic>?> getModelById(String modelId) async {
    try {
      final doc = await _firestore
          .collection('generated_models_files')
          .doc(modelId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('Error getting model by ID: $e');
      return null;
    }
  }

  /// Listen to model updates for a video (real-time)
  static Stream<List<Map<String, dynamic>>> watchModelsForVideo(
    String videoId,
  ) {
    return _firestore
        .collection('generated_models_files')
        .where('videoId', isEqualTo: videoId)
        .where('status', isEqualTo: 'ready')
        .snapshots()
        .map((snapshot) {
      final models = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['taskId'] = data['taskId'] ?? doc.id;
        return data;
      }).toList();

      // Sort by createdAt
      models.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return models;
    });
  }

  /// Get model generation progress from video document
  static Future<Map<String, dynamic>?> getVideoGenerationStatus(
    String videoId,
  ) async {
    try {
      final doc = await _firestore.collection('videos').doc(videoId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return {
        'taskId': data['meshyTaskId'],
        'status': data['meshyStatus'],
        'has3DModel': data['has3DModel'] ?? false,
        'generatedModelUrl': data['generatedModelUrl'],
        'generatedModelId': data['generatedModelId'],
      };
    } catch (e) {
      print('Error getting video generation status: $e');
      return null;
    }
  }

  /// Check if backend is needed for this operation
  /// Returns true if we need to call the backend API
  static bool needsBackend(String operation) {
    // These operations require backend:
    const backendOperations = [
      'generate', // Initiating new 3D model generation
      'stream_status', // Real-time SSE status updates
    ];

    return backendOperations.contains(operation);
  }

  /// Get health status of model service
  /// This checks if we can access Firestore (doesn't need backend)
  static Future<bool> isServiceHealthy() async {
    try {
      // Try to read a single document to verify Firestore access
      await _firestore
          .collection('generated_models_files')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print('Firestore health check failed: $e');
      return false;
    }
  }

  /// Fetch models from backend storage
  /// This calls the backend API to get models that are actually stored in Supabase storage
  /// Falls back to Firestore if backend is unavailable
  static Future<List<Map<String, dynamic>>> fetchModelsFromBackendStorage({
    String? userId,
    String? videoId,
    bool fallbackToFirestore = true,
  }) async {
    try {
      final uploadService = VideoUploadService();
      final models = await uploadService.fetchUploadedModelsFromStorage(
        userId: userId,
        videoId: videoId,
      );

      if (models.isNotEmpty) {
        print(
            'Successfully fetched ${models.length} models from backend storage');
        return models;
      } else if (fallbackToFirestore) {
        print('No models from backend, falling back to Firestore...');
        if (videoId != null) {
          return await getModelsForVideo(videoId);
        } else {
          return await listAllModels(userId: userId);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching models from backend storage: $e');
      if (fallbackToFirestore) {
        print('Falling back to Firestore...');
        try {
          if (videoId != null) {
            return await getModelsForVideo(videoId);
          } else {
            return await listAllModels(userId: userId);
          }
        } catch (firestoreError) {
          print('Firestore fallback also failed: $firestoreError');
          return [];
        }
      }
      return [];
    }
  }

  /// Get models for a video, trying backend storage first, then Firestore
  /// This is the recommended method to fetch models as it checks both sources
  static Future<List<Map<String, dynamic>>> getModelsForVideoWithBackend(
    String videoId, {
    bool tryBackendFirst = true,
  }) async {
    if (tryBackendFirst) {
      try {
        final backendModels = await fetchModelsFromBackendStorage(
          videoId: videoId,
          fallbackToFirestore: true,
        );
        if (backendModels.isNotEmpty) {
          return backendModels;
        }
      } catch (e) {
        print('Backend fetch failed, using Firestore: $e');
      }
    }

    // Fallback to Firestore
    return await getModelsForVideo(videoId);
  }

  /// List all models, trying backend storage first, then Firestore
  /// This is the recommended method to list models as it checks both sources
  static Future<List<Map<String, dynamic>>> listAllModelsWithBackend({
    String? userId,
    bool tryBackendFirst = true,
  }) async {
    if (tryBackendFirst) {
      try {
        final backendModels = await fetchModelsFromBackendStorage(
          userId: userId,
          fallbackToFirestore: true,
        );
        if (backendModels.isNotEmpty) {
          return backendModels;
        }
      } catch (e) {
        print('Backend fetch failed, using Firestore: $e');
      }
    }

    // Fallback to Firestore
    return await listAllModels(userId: userId);
  }
}
