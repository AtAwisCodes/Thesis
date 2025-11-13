import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// AR Scanner Page - Advanced Augmented Reality Scanner
///
/// Features:
/// - Real camera feed with AR overlay
/// - Photo capture with automatic background removal
/// - Image upload from gallery
/// - Tap-to-place 2D AR objects on camera feed
/// - Interactive object manipulation (scale, rotate, move)
/// - Multi-object support with real-time editing
class ARScannerPage extends StatefulWidget {
  const ARScannerPage({super.key});

  @override
  State<ARScannerPage> createState() => _ARScannerPageState();
}

class _ARScannerPageState extends State<ARScannerPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isProcessingPhoto = false;
  List<ScannedObject> _scannedObjects = [];
  ScannedObject? _selectedObject;
  late AnimationController _pulseController;
  Offset? _selectedPlacementPosition;

  // Remove.bg API key for background removal
  static const String _removeBgApiKey = 'V2BJ2X9HigKJ7hFJqp8TeUNu';

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });

    if (_hasPermission) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        // No cameras available (e.g., on desktop), use simulated mode
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      // Fallback to simulated mode on error
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionScreen();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AR Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Scanned objects overlay
          ..._scannedObjects.map((obj) => _buildScannedObject(obj)),

          // UI Controls
          _buildUIControls(),

          // Object manipulation panel
          if (_selectedObject != null) _buildManipulationPanel(),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 100, color: Colors.white70),
              const SizedBox(height: 24),
              const Text(
                'Camera Permission Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This AR Scanner needs camera access to capture and overlay objects in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.refresh),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Initializing AR Camera...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    Widget cameraView;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Simulated camera view for desktop or when camera is not available
      cameraView = Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF2a2a3e),
              Color(0xFF1a1a2e),
              Color(0xFF0f0f1f),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Simulated camera feed with grid
            CustomPaint(
              size: Size.infinite,
              painter: CameraSimulatorPainter(),
            ),
            // "Simulated Camera" indicator
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Simulated Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      cameraView = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    // Wrap camera view with GestureDetector for tap-to-place
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _selectedPlacementPosition = details.localPosition;
        });
      },
      child: Stack(
        children: [
          cameraView,

          // Show placement marker when position is selected
          if (_selectedPlacementPosition != null)
            Positioned(
              left: _selectedPlacementPosition!.dx - 20,
              top: _selectedPlacementPosition!.dy - 20,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                      color: Colors.green
                          .withOpacity(0.2 + (_pulseController.value * 0.2)),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.green,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannedObject(ScannedObject obj) {
    final isSelected = _selectedObject?.id == obj.id;

    // Calculate actual display dimensions
    double displayWidth = obj.size * obj.scale;
    double displayHeight = obj.size * obj.scale;

    // Use actual aspect ratio for images
    if (obj.imagePath != null &&
        obj.imageWidth != null &&
        obj.imageHeight != null) {
      final aspectRatio = obj.imageWidth! / obj.imageHeight!;
      displayWidth = obj.size * obj.scale;
      displayHeight = displayWidth / aspectRatio;
    }

    return Positioned(
      left: obj.position.dx - (displayWidth / 2),
      top: obj.position.dy - (displayHeight / 2),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedObject = isSelected ? null : obj;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            obj.position = Offset(
              obj.position.dx + details.delta.dx,
              obj.position.dy + details.delta.dy,
            );
          });
        },
        child: Transform.rotate(
          angle: obj.rotation,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: displayWidth,
                height: displayHeight,
                decoration: BoxDecoration(
                  color: obj.imagePath != null
                      ? Colors.transparent
                      : obj.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: obj.imagePath != null
                      ? null
                      : Border.all(
                          color: isSelected ? Colors.yellow : Colors.cyan,
                          width: isSelected ? 3 : 2,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : obj.imagePath == null
                          ? [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                ),
                child: Stack(
                  children: [
                    // Display captured image if available
                    if (obj.imagePath != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(obj.imagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      // Default icon display
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                obj.icon,
                                size: obj.size * obj.scale * 0.4,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                obj.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUIControls() {
    return SafeArea(
      child: Column(
        children: [
          // Top status bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_enhance,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isProcessingPhoto
                        ? 'Processing...'
                        : 'AR Objects: ${_scannedObjects.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom controls
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_scannedObjects.isEmpty && !_isProcessingPhoto)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          'Tap screen to choose placement location',
                          style: TextStyle(
                            color: Colors.yellow.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Then capture photo or upload image',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isProcessingPhoto
                          ? Icons.hourglass_empty
                          : Icons.camera,
                      label: _isProcessingPhoto ? 'Processing' : 'Capture',
                      color: _isProcessingPhoto ? Colors.grey : Colors.green,
                      onPressed: _isProcessingPhoto ? () {} : _capturePhoto,
                    ),
                    _buildControlButton(
                      icon: Icons.upload_file,
                      label: 'Upload',
                      color: Colors.blue,
                      onPressed: _isProcessingPhoto ? () {} : _uploadImage,
                    ),
                    if (_scannedObjects.isNotEmpty) ...[
                      _buildControlButton(
                        icon: Icons.delete_sweep,
                        label: 'Clear',
                        color: Colors.orange,
                        onPressed: _clearAllObjects,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManipulationPanel() {
    if (_selectedObject == null) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      right: 20,
      bottom: 150,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.yellow.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Editing: ${_selectedObject!.name}',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedObject = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scale control
            _buildSliderControl(
              icon: Icons.photo_size_select_large,
              label: 'Size',
              value: _selectedObject!.scale,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _selectedObject!.scale = value;
                });
              },
            ),

            // Rotation control
            _buildSliderControl(
              icon: Icons.rotate_right,
              label: 'Rotation',
              value: _selectedObject!.rotation / (2 * math.pi),
              min: 0,
              max: 1,
              onChanged: (value) {
                setState(() {
                  _selectedObject!.rotation = value * 2 * math.pi;
                });
              },
            ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _scannedObjects.remove(_selectedObject);
                        _selectedObject = null;
                      });
                      _showMessage('Object deleted');
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final obj = _selectedObject!;
                      setState(() {
                        _scannedObjects.add(ScannedObject(
                          id: DateTime.now().millisecondsSinceEpoch,
                          name: '${obj.name} Copy',
                          position: Offset(
                              obj.position.dx + 20, obj.position.dy + 20),
                          size: obj.size,
                          scale: obj.scale,
                          rotation: obj.rotation,
                          color: obj.color,
                          icon: obj.icon,
                          imagePath: obj.imagePath,
                          imageWidth: obj.imageWidth,
                          imageHeight: obj.imageHeight,
                        ));
                      });
                      _showMessage('Object duplicated');
                    },
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Duplicate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderControl({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: Colors.green,
              inactiveColor: Colors.green.withOpacity(0.3),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showMessage('Camera not available');
      return;
    }

    try {
      setState(() {
        _isProcessingPhoto = true;
      });

      _showMessage('Capturing photo...');

      // Take the picture
      final image = await _cameraController!.takePicture();

      _showMessage('Removing background...');

      // Remove background using remove.bg API
      final processedImagePath = await _removeBackgroundWithApi(image.path);

      if (processedImagePath == null) {
        throw Exception('Background removal failed');
      }

      // Get actual image dimensions
      final imageFile = File(processedImagePath);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();

      // Scale image to fit screen while maintaining aspect ratio
      final screenSize = MediaQuery.of(context).size;
      final maxDisplaySize = screenSize.width * 0.6;
      final aspectRatio = imageWidth / imageHeight;

      double displayWidth;
      if (aspectRatio > 1) {
        displayWidth = maxDisplaySize;
      } else {
        displayWidth = maxDisplaySize * aspectRatio;
      }

      // Use tapped position or default to center
      final placementPosition = _selectedPlacementPosition ??
          Offset(screenSize.width / 2, screenSize.height / 2);

      setState(() {
        _scannedObjects.add(ScannedObject(
          id: DateTime.now().millisecondsSinceEpoch,
          name: 'Captured Photo',
          position: placementPosition,
          size: displayWidth,
          scale: 1.0,
          rotation: 0,
          color: Colors.transparent,
          imagePath: processedImagePath,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        ));
        _isProcessingPhoto = false;
        _selectedPlacementPosition = null;
      });

      _showMessage('Photo captured! Background removed ✓');
    } catch (e) {
      print('Error capturing photo: $e');
      setState(() {
        _isProcessingPhoto = false;
      });
      _showMessage('Failed to process photo');
    }
  }

  Future<void> _uploadImage() async {
    try {
      setState(() {
        _isProcessingPhoto = true;
      });

      _showMessage('Select an image...');

      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        setState(() {
          _isProcessingPhoto = false;
        });
        return;
      }

      _showMessage('Removing background...');

      // Remove background using remove.bg API
      final processedImagePath =
          await _removeBackgroundWithApi(pickedFile.path);

      if (processedImagePath == null) {
        throw Exception('Background removal failed');
      }

      // Get actual image dimensions
      final imageFile = File(processedImagePath);
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();

      // Scale image to fit screen
      final screenSize = MediaQuery.of(context).size;
      final maxDisplaySize = screenSize.width * 0.6;
      final aspectRatio = imageWidth / imageHeight;

      double displayWidth;
      if (aspectRatio > 1) {
        displayWidth = maxDisplaySize;
      } else {
        displayWidth = maxDisplaySize * aspectRatio;
      }

      // Use tapped position or default to center
      final placementPosition = _selectedPlacementPosition ??
          Offset(screenSize.width / 2, screenSize.height / 2);

      setState(() {
        _scannedObjects.add(ScannedObject(
          id: DateTime.now().millisecondsSinceEpoch,
          name: 'Uploaded Image',
          position: placementPosition,
          size: displayWidth,
          scale: 1.0,
          rotation: 0,
          color: Colors.transparent,
          imagePath: processedImagePath,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        ));
        _isProcessingPhoto = false;
        _selectedPlacementPosition = null;
      });

      _showMessage('Image uploaded! Background removed ✓');
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isProcessingPhoto = false;
      });
      _showMessage('Failed to upload image');
    }
  }

  Future<String?> _removeBackgroundWithApi(String imagePath) async {
    try {
      // Read the image file
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
      );

      // Add API key header
      request.headers['X-Api-Key'] = _removeBgApiKey;

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Add parameters
      request.fields['size'] = 'auto';
      request.fields['format'] = 'png';

      // Send request
      final response = await request.send();

      if (response.statusCode == 200) {
        // Get the response bytes
        final responseBytes = await response.stream.toBytes();

        // Save the processed image
        final directory = await getApplicationDocumentsDirectory();
        final processedPath = path.join(
          directory.path,
          'ar_nobg_${DateTime.now().millisecondsSinceEpoch}.png',
        );

        await File(processedPath).writeAsBytes(responseBytes);

        return processedPath;
      } else {
        print('Remove.bg API error: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        print('Error details: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error calling remove.bg API: $e');
      return null;
    }
  }

  void _clearAllObjects() {
    setState(() {
      _scannedObjects.clear();
      _selectedObject = null;
    });
    _showMessage('All objects cleared');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.green),
            SizedBox(width: 8),
            Text('AR Scanner Help'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('1. Tap anywhere on screen to set placement location'),
              SizedBox(height: 8),
              Text(
                  '2. Use "Capture" to take photo or "Upload" to select from gallery'),
              SizedBox(height: 8),
              Text('3. Background will be automatically removed'),
              SizedBox(height: 8),
              Text('4. Tap object to select it for editing'),
              SizedBox(height: 8),
              Text('5. Drag object to move it around'),
              SizedBox(height: 8),
              Text('6. Use sliders to adjust size and rotation'),
              SizedBox(height: 8),
              Text('7. Duplicate or delete objects as needed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

/// Model class for scanned AR objects
class ScannedObject {
  final int id;
  String name;
  Offset position;
  double size;
  double scale;
  double rotation;
  Color color;
  IconData? icon;
  String? imagePath;
  double? imageWidth;
  double? imageHeight;

  ScannedObject({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    required this.scale,
    required this.rotation,
    required this.color,
    this.icon,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
  });
}

/// Custom painter for simulated camera view
class CameraSimulatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    // Draw grid
    final gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some "features" to simulate camera feed
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.white.withOpacity(0.1),
      );
    }
  }

  @override
  bool shouldRepaint(CameraSimulatorPainter oldDelegate) => false;
}
