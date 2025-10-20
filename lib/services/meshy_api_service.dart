import 'dart:convert';
import 'package:http/http.dart' as http;

class MeshyApiService {
  //DITO MO LAGAY IP MO LANS YESHUA DE GUZMAN
  static const String baseUrl = 'http://192.168.100.25:5000';

  /// Generate a 3D model from a video's modelImages
  static Future<Map<String, dynamic>> generateModel({
    required String videoId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate-3d'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate model: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating model: $e');
    }
  }

  /// Check the status of model generation
  static Future<Map<String, dynamic>> checkModelStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/model-status/$taskId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking status: $e');
    }
  }

  /// Fetch the completed model and save to Supabase
  static Future<Map<String, dynamic>> fetchCompletedModel({
    required String taskId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/fetch-model'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': taskId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch model: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching model: $e');
    }
  }

  /// Get all models available for a specific video
  static Future<List<Map<String, dynamic>>> getModelsForVideo(
      String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/models/video/$videoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['models'] ?? []);
      } else {
        throw Exception('Failed to get models: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting models: $e');
    }
  }

  /// List all available models (optionally filtered by user)
  static Future<List<Map<String, dynamic>>> listAllModels(
      {String? userId}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/models/list');
      final finalUri = userId != null
          ? uri.replace(queryParameters: {'user_id': userId})
          : uri;

      final response = await http.get(
        finalUri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['models'] ?? []);
      } else {
        throw Exception('Failed to list models: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error listing models: $e');
    }
  }

  /// Stream model status updates (for real-time progress)
  static Stream<Map<String, dynamic>> streamModelStatus(String taskId) async* {
    try {
      final client = http.Client();
      final request =
          http.Request('GET', Uri.parse('$baseUrl/api/stream-status/$taskId'));

      request.headers.addAll({
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });

      final response = await client.send(request);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            if (jsonStr.trim().isNotEmpty) {
              try {
                final data = jsonDecode(jsonStr);
                yield data;
              } catch (e) {
                // Skip invalid JSON
              }
            }
          }
        }
      }
    } catch (e) {
      yield {'error': 'Stream error: $e'};
    }
  }

  /// Delete a model from both Supabase and Firestore
  static Future<bool> deleteModel(String modelId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/delete-model/$modelId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting model: $e');
    }
  }

  /// Health check for backend
  static Future<bool> isBackendHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Automatically fetch model if ready (for background processing)
  /// Returns true if model was fetched, false if not ready yet
  static Future<bool> autoFetchModelIfReady({
    required String taskId,
    required String userId,
  }) async {
    try {
      // First check status
      final statusResponse = await checkModelStatus(taskId);
      final status = statusResponse['status']?.toString().toLowerCase();

      if (status == 'succeeded') {
        // Model is ready, fetch it
        print('Auto-fetching completed model: $taskId');
        final result = await fetchCompletedModel(
          taskId: taskId,
          userId: userId,
        );

        if (result['success'] == true) {
          print('Auto-fetch successful: ${result['model_public_url']}');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Auto-fetch error: $e');
      return false;
    }
  }

  /// Fetch model with detailed result
  static Future<Map<String, dynamic>> fetchModel({
    required String taskId,
    required String userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/fetch-model'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'task_id': taskId,
              'user_id': userId,
            }),
          )
          .timeout(
            const Duration(minutes: 5), // GLB download can take time
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Model fetched successfully');
        print('URL: ${data['model_public_url']}');
        print('Firestore ID: ${data['firestore_doc_id']}');
        return data;
      } else {
        throw Exception('Failed to fetch model: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching model: $e');
    }
  }
}
