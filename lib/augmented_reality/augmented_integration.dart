import 'dart:convert';
import 'package:http/http.dart' as http;

class MeshyIntegration {
  static const String _baseUrl = 'https://api.meshy.ai/v1';
  static const String _apiKey = 'msy_zkhom6uoX6vtWwvnrtsOB5PT01yO049AIXRX';

  Future<Map<String, dynamic>> generate3DModel(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generations'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'model': 'base-model',
          'format': 'glb',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate 3D model: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating 3D model: $e');
    }
  }

  Future<String?> checkGenerationStatus(String generationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/generations/$generationId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      } else {
        throw Exception('Failed to check generation status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking generation status: $e');
    }
  }
}
