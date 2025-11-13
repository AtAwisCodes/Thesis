import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:rexplore/services/ar_model_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

/// AR Model Manager Page - For video uploaders only
///
/// Features:
/// - Upload AR model images
/// - Automatic background removal
/// - View uploaded models
/// - Delete models (uploader only)
/// - Model naming
class ARModelManagerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;

  const ARModelManagerPage({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  State<ARModelManagerPage> createState() => _ARModelManagerPageState();
}

class _ARModelManagerPageState extends State<ARModelManagerPage> {
  final ARModelService _arModelService = ARModelService();
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _models = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isVideoUploader = false;
  String? _loadError;

  // Remove.bg API key for background removal
  static const String _removeBgApiKey = 'V2BJ2X9HigKJ7hFJqp8TeUNu';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadModels();
  }

  Future<void> _checkPermissions() async {
    final isUploader = await _arModelService.isVideoUploader(widget.videoId);
    setState(() {
      _isVideoUploader = isUploader;
    });

    if (!isUploader) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the video uploader can manage AR models'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      print('🔍 AR Manager: Loading models for video: ${widget.videoId}');

      _arModelService.getVideoARModels(widget.videoId).listen(
        (models) {
          if (mounted) {
            print('✅ AR Manager: Loaded ${models.length} models');
            setState(() {
              _models = models;
              _isLoading = false;
              _loadError = null;
            });
          }
        },
        onError: (error) {
          print('❌ AR Manager: Error loading models: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadError = error.toString();
            });
          }
        },
      );
    } catch (e) {
      print('❌ AR Manager: Exception in _loadModels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _uploadModel() async {
    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Removing background...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Remove background
      final processedFile = await _removeBackground(File(image.path));

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (processedFile == null) {
        throw Exception('Failed to process image');
      }

      // Ask for model name
      final modelName = await _showNameDialog();
      if (modelName == null || modelName.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload to Firebase
      final result = await _arModelService.uploadARModel(
        videoId: widget.videoId,
        imageFile: processedFile,
        modelName: modelName,
      );

      if (result != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AR model uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<File?> _removeBackground(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );

      request.headers['X-Api-Key'] = _removeBgApiKey;
      request.files
          .add(await http.MultipartFile.fromPath('image_file', imageFile.path));
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

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your AR Model'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter model name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModel(String modelId, String modelName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AR Model'),
        content: Text('Are you sure you want to delete "$modelName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _arModelService.deleteARModel(
      videoId: widget.videoId,
      modelId: modelId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AR model deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete model'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Model Manager'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Video info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.videoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage AR models for this video',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Models list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error loading AR models',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadModels,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _models.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No AR models yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload images to create AR models',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _models.length,
                            itemBuilder: (context, index) {
                              final model = _models[index];
                              return _buildModelCard(model);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _isVideoUploader && !_isUploading
          ? FloatingActionButton.extended(
              onPressed: _uploadModel,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Model'),
            )
          : null,
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Model image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                model['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ),

          // Model info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model['modelName'] ?? 'Unnamed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(model['createdAt']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          if (_isVideoUploader)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: () => _deleteModel(
                  model['modelId'],
                  model['modelName'] ?? 'Unnamed',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is firestore.Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}
