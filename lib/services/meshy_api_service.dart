import 'dart:convert';
import 'package:http/http.dart' as http;

/// Backend environment options
enum BackendEnvironment {
  local, // Same WiFi network only
  ngrok, // Temporary public access (for testing)
  production, // Deployed to cloud (Render/Railway/etc)
}

class MeshyApiService {
  /// Current environment - change this to switch between local/ngrok/production
  static const BackendEnvironment _environment = BackendEnvironment.local;

  /// Backend URLs for different environments
  static const String _localUrl =
      'http://192.168.100.25:5000'; // Same WiFi only
  static const String _ngrokUrl =
      'https://your-ngrok-url.ngrok.io'; // Update when using ngrok
  static const String _productionUrl =
      'https://your-app.onrender.com'; // Update when deployed

  /// Get the active backend URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case BackendEnvironment.local:
        return _localUrl;
      case BackendEnvironment.ngrok:
        return _ngrokUrl;
      case BackendEnvironment.production:
        return _productionUrl;
    }
  }

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

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get current environment name
  static String get currentEnvironment {
    return _environment.toString().split('.').last;
  }

  /// Check if backend is reachable with helpful error messages
  static Future<Map<String, dynamic>> checkBackendStatus() async {
    try {
      print('🔍 Checking backend at: $baseUrl');
      print('📍 Environment: $currentEnvironment');

      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Backend is healthy!');
        return {
          'status': 'healthy',
          'url': baseUrl,
          'environment': currentEnvironment,
          'message': 'Backend is accessible and running correctly',
        };
      } else {
        print('Backend returned status: ${response.statusCode}');
        return {
          'status': 'error',
          'url': baseUrl,
          'environment': currentEnvironment,
          'message': 'Backend returned status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Backend not reachable: $e');

      // Provide helpful error messages based on environment
      String helpMessage = '';
      switch (_environment) {
        case BackendEnvironment.local:
          helpMessage = '''
Backend not reachable on local network.
Troubleshooting:
1. Is the backend running? (python backend/app.py)
2. Are you on the same WiFi network?
3. Check firewall settings
4. Verify the IP address: $_localUrl
5. Try pinging the server

For testing from different networks, use ngrok instead!
''';
          break;
        case BackendEnvironment.ngrok:
          helpMessage = '''
ngrok tunnel not reachable.
Troubleshooting:
1. Is ngrok running? (ngrok http 5000)
2. Did you update _ngrokUrl with your ngrok URL?
3. ngrok URLs change each time - check for a new one
4. Verify the URL: $_ngrokUrl
''';
          break;
        case BackendEnvironment.production:
          helpMessage = '''
Production backend not reachable.
Troubleshooting:
1. Is the backend deployed?
2. Check deployment logs on Render/Railway
3. Verify the URL: $_productionUrl
4. Check for deployment errors
''';
          break;
      }

      return {
        'status': 'unreachable',
        'url': baseUrl,
        'environment': currentEnvironment,
        'error': e.toString(),
        'message': 'Cannot reach backend',
        'help': helpMessage,
      };
    }
  }

  /// Get configuration info for debugging
  static Map<String, dynamic> getConfigInfo() {
    return {
      'environment': currentEnvironment,
      'baseUrl': baseUrl,
      'localUrl': _localUrl,
      'ngrokUrl': _ngrokUrl,
      'productionUrl': _productionUrl,
      'note':
          'For viewing models, use FirestoreModelService (no backend needed!)',
    };
  }

  /// Print helpful setup information
  static void printSetupInfo() {
    print('\n' + '=' * 70);
    print('🔧 MESHY API SERVICE CONFIGURATION');
    print('=' * 70);
    print('Current Environment: $currentEnvironment');
    print('Backend URL: $baseUrl');
    print('');
    print('TIPS:');
    print('');
    if (_environment == BackendEnvironment.local) {
      print('You\'re using LOCAL mode - only works on same WiFi');
      print('   To test from any network, use ngrok:');
      print('   1. Run: ngrok http 5000');
      print('   2. Update _ngrokUrl in meshy_api_service.dart');
      print('   3. Set _environment = BackendEnvironment.ngrok');
    } else if (_environment == BackendEnvironment.ngrok) {
      print('You\'re using NGROK mode - works from any network');
      print('   Remember: ngrok URL changes when you restart ngrok');
      print('   Current URL: $_ngrokUrl');
    } else {
      print('You\'re using PRODUCTION mode - works from any network');
      print('   Deployment URL: $_productionUrl');
    }
    print('');
    print('For VIEWING models (no backend needed):');
    print('   Use: FirestoreModelService.getModelsForVideo(videoId)');
    print('   Works from ANY network without backend!');
    print('');
    print('🔨 For GENERATING models (backend required):');
    print('   Use: MeshyApiService.generateModel(videoId, userId)');
    print('   Requires backend to be running and accessible');
    print('=' * 70 + '\n');
  }
}
