import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:rexplore/services/ar_model_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rexplore/debug/ar_model_debugger.dart';

/// Video-Specific AR Scanner Page
///
/// Features:
/// - Loads 2D models from video's AR model collection
/// - Models are uploaded by video owner
/// - Real camera feed with AR overlay
/// - Tap-to-place models on camera feed
/// - Interactive object manipulation (scale, rotate, move)
/// - Only video uploader can delete models
class VideoARScannerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;

  const VideoARScannerPage({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  State<VideoARScannerPage> createState() => _VideoARScannerPageState();
}

class _VideoARScannerPageState extends State<VideoARScannerPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  List<PlacedARObject> _placedObjects = [];
  PlacedARObject? _selectedObject;
  late AnimationController _pulseController;
  Offset? _selectedPlacementPosition;
  List<Map<String, dynamic>> _availableModels = [];
  bool _isLoadingModels = true;
  String? _selectedModelId;
  String? _modelLoadError;
  // Track initial scale and position for pinch/pan gestures
  Map<int, double> _initialScales = {};
  Map<int, Offset> _initialPositions = {};
  Map<int, Offset> _initialFocalPoints = {};

  // Stream subscription for AR models - CRITICAL for proper cleanup
  StreamSubscription<List<Map<String, dynamic>>>? _modelsSubscription;
  final ARModelService _arModelService = ARModelService();

  // Cache key for local persistence
  String get _cacheKey => 'ar_models_${widget.videoId}';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _requestPermissions();
    _loadARModels();
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
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  Future<void> _loadARModels() async {
    setState(() {
      _isLoadingModels = true;
      _modelLoadError = null;
    });

    try {
      print('🔍 Loading AR models for video: ${widget.videoId}');

      // DIAGNOSTIC: Run debugger to check what's in Firestore
      await ARModelDebugger.debugVideoARModels(widget.videoId);

      // Step 1: Load cached models immediately (offline-first)
      await _loadCachedModels();

      // Step 2: Cancel any existing subscription to prevent duplicates
      await _modelsSubscription?.cancel();

      // Step 3: Subscribe to live updates from Firestore
      print('📡 Subscribing to AR model stream...');
      _modelsSubscription =
          _arModelService.getVideoARModels(widget.videoId).listen(
        (models) async {
          if (mounted) {
            print('✅ Loaded ${models.length} AR models from Firestore');
            if (models.isNotEmpty) {
              print(
                  '📦 First model: ${models[0]['modelName']} - ${models[0]['imageUrl']}');
            } else {
              print('⚠️ Stream returned ZERO models');
              print('   → Check if models exist in Firestore');
              print('   → Check Firestore security rules');
              print('   → Check if models are marked as active');
            }

            // Update UI with fresh data
            setState(() {
              _availableModels = models;
              _isLoadingModels = false;
              _modelLoadError = null;
            });

            // Save to cache for offline access
            await _cacheModels(models);
          }
        },
        onError: (error) {
          print('❌ Error loading AR models from Firestore: $error');
          if (mounted) {
            setState(() {
              _isLoadingModels = false;
              // Only show error if we don't have cached models
              if (_availableModels.isEmpty) {
                _modelLoadError = 'Failed to load models: ${error.toString()}';
              } else {
                _modelLoadError = null; // Use cached models
                print('⚠️ Using cached models due to Firestore error');
              }
            });
          }
        },
        cancelOnError: false, // Keep subscription alive even after errors
      );

      print('✅ Stream subscription created successfully');
    } catch (e) {
      print('❌ Exception in _loadARModels: $e');
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          // Only show error if we don't have cached models
          if (_availableModels.isEmpty) {
            _modelLoadError = 'Exception: ${e.toString()}';
          } else {
            print('⚠️ Using cached models due to exception');
          }
        });
      }
    }
  }

  /// Load models from local cache (instant, offline-first)
  Future<void> _loadCachedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final cachedModels =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();

        if (cachedModels.isNotEmpty) {
          print('📦 Loaded ${cachedModels.length} cached AR models');
          setState(() {
            _availableModels = cachedModels;
            _isLoadingModels = false;
          });
        }
      } else {
        print('ℹ️ No cached AR models found');
      }
    } catch (e) {
      print('⚠️ Error loading cached models: $e');
      // Don't throw - cache is optional
    }
  }

  /// Save models to local cache for offline access
  Future<void> _cacheModels(List<Map<String, dynamic>> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(models);
      await prefs.setString(_cacheKey, jsonString);
      print('💾 Cached ${models.length} AR models locally');
    } catch (e) {
      print('⚠️ Error caching models: $e');
      // Don't throw - cache failure shouldn't break the app
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
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Placed AR objects
          ..._placedObjects.map((obj) => _buildPlacedObject(obj)),

          // UI Controls
          _buildUIControls(),

          // Object manipulation panel
          if (_selectedObject != null) _buildManipulationPanel(),

          // Model selection drawer
          if (_selectedPlacementPosition != null) _buildModelSelector(),
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
                  'This AR Scanner needs camera access to overlay models in real-time.',
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
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    Widget cameraView;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      cameraView = Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else {
      cameraView = CameraPreview(_cameraController!);
    }

    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _selectedPlacementPosition = details.localPosition;
          _selectedObject = null; // Deselect any selected object
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

  Widget _buildPlacedObject(PlacedARObject obj) {
    final isSelected = _selectedObject?.id == obj.id;

    double displayWidth = obj.size * obj.scale;
    double displayHeight = obj.size * obj.scale;

    if (obj.imageWidth != null && obj.imageHeight != null) {
      final aspectRatio = obj.imageWidth! / obj.imageHeight!;
      displayHeight = displayWidth / aspectRatio;
    }

    return Positioned(
      left: obj.position.dx - (displayWidth / 2),
      top: obj.position.dy - (displayHeight / 2),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedObject = obj;
            _selectedPlacementPosition = null; // Clear placement position
          });
        },
        onScaleStart: (details) {
          // Store initial scale, position, and focal point when gesture starts
          _initialScales[obj.id] = obj.scale;
          _initialPositions[obj.id] = obj.position;
          _initialFocalPoints[obj.id] = details.focalPoint;
        },
        onScaleUpdate: (details) {
          setState(() {
            final initialScale = _initialScales[obj.id] ?? obj.scale;
            final initialPosition = _initialPositions[obj.id] ?? obj.position;
            final initialFocalPoint =
                _initialFocalPoints[obj.id] ?? details.focalPoint;

            // Handle scaling (pinch gesture)
            obj.scale = (initialScale * details.scale).clamp(0.5, 3.0);

            // Handle panning (drag gesture)
            // Calculate the movement from the initial focal point
            final delta = details.focalPoint - initialFocalPoint;
            obj.position = initialPosition + delta;
          });
        },
        onScaleEnd: (details) {
          // Clear all tracking data
          _initialScales.remove(obj.id);
          _initialPositions.remove(obj.id);
          _initialFocalPoints.remove(obj.id);
        },
        child: Transform.rotate(
          angle: obj.rotation,
          child: Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: Colors.yellow, width: 3)
                  : null,
            ),
            child: Image.network(
              obj.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                );
              },
            ),
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.videoTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'AR Objects: ${_placedObjects.length} | Models: ${_availableModels.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom instructions
          if (_modelLoadError != null && !_isLoadingModels)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Error loading AR models',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modelLoadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadARModels,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_availableModels.isEmpty && !_isLoadingModels)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No AR models available for this video yet.\nVideo uploader needs to add AR models first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

          if (_availableModels.isNotEmpty)
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
                children: [
                  Text(
                    _selectedPlacementPosition != null
                        ? 'Select a model to place'
                        : 'Tap screen to place AR models',
                    style: TextStyle(
                      color: Colors.yellow.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_availableModels.length} models available',
                    style: TextStyle(
                      color: Colors.green.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelSelector() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select AR Model',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedPlacementPosition = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Model list
            Expanded(
              child: _isLoadingModels
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableModels.length,
                      itemBuilder: (context, index) {
                        final model = _availableModels[index];
                        return _buildModelCard(model);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    return GestureDetector(
      onTap: () => _placeModel(model),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedModelId == model['modelId']
                ? Colors.green
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  model['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white30,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                model['modelName'] ?? 'Model ${model['modelId']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeModel(Map<String, dynamic> model) async {
    if (_selectedPlacementPosition == null) return;

    // Load image to get dimensions
    int? width, height;
    try {
      final response = await http.get(Uri.parse(model['imageUrl']));
      if (response.statusCode == 200) {
        final decodedImage = img.decodeImage(response.bodyBytes);
        if (decodedImage != null) {
          width = decodedImage.width;
          height = decodedImage.height;
        }
      }
    } catch (e) {
      print('Error loading image dimensions: $e');
    }

    final newObject = PlacedARObject(
      id: DateTime.now().millisecondsSinceEpoch,
      modelId: model['modelId'],
      modelName: model['modelName'] ?? 'Unnamed',
      position: _selectedPlacementPosition!,
      imageUrl: model['imageUrl'],
      size: 150,
      scale: 1.0,
      rotation: 0.0,
      imageWidth: width?.toDouble(),
      imageHeight: height?.toDouble(),
    );

    setState(() {
      _placedObjects.add(newObject);
      _selectedPlacementPosition = null;
      _selectedModelId = model['modelId'];
    });
  }

  Widget _buildManipulationPanel() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            // Scale controls
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedObject!.scale =
                      (_selectedObject!.scale + 0.1).clamp(0.5, 3.0);
                });
              },
            ),
            Text(
              '${(_selectedObject!.scale * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedObject!.scale =
                      (_selectedObject!.scale - 0.1).clamp(0.5, 3.0);
                });
              },
            ),
            const Divider(color: Colors.white30),

            // Rotation control
            IconButton(
              icon: const Icon(Icons.rotate_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedObject!.rotation += math.pi / 8;
                });
              },
            ),
            const Divider(color: Colors.white30),

            // Delete control
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _placedObjects.remove(_selectedObject);
                  _selectedObject = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('🧹 Disposing VideoARScannerPage...');

    // Cancel stream subscription to prevent memory leaks
    _modelsSubscription?.cancel();
    print('✅ Stream subscription cancelled');

    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

/// Model class for placed AR objects
class PlacedARObject {
  final int id;
  final String modelId;
  final String modelName;
  Offset position;
  final String imageUrl;
  double size;
  double scale;
  double rotation;
  double? imageWidth;
  double? imageHeight;

  PlacedARObject({
    required this.id,
    required this.modelId,
    required this.modelName,
    required this.position,
    required this.imageUrl,
    required this.size,
    required this.scale,
    required this.rotation,
    this.imageWidth,
    this.imageHeight,
  });
}
