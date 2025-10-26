import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to access 3D models directly from Firestore
/// This bypasses the backend for model retrieval, allowing access from any network
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
}
