import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:rexplore/services/meshy_api_service.dart';
import 'package:rexplore/services/firestore_model_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MeshyARCamera extends StatefulWidget {
  final String? videoId;

  const MeshyARCamera({super.key, this.videoId});

  @override
  // ignore: library_private_types_in_public_api
  _MeshyARCameraState createState() => _MeshyARCameraState();
}

class _MeshyARCameraState extends State<MeshyARCamera> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  bool _isCheckingCompatibility = true;
  bool _isARSupported = false;
  bool _isLoadingModel = false;
  String _deviceInfo = "";
  String _statusMessage = "Checking device compatibility...";

  // Meshy AI model data
  List<Map<String, dynamic>> _availableModels = [];
  String? _selectedModelUrl;
  String? _currentTaskId;
// Local path to downloaded GLB file

  @override
  void initState() {
    super.initState();
    _checkARCompatibility();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    try {
      debugPrint(" Loading available models...");
      setState(() {
        _isLoadingModel = true;
        _statusMessage = "Loading available 3D models...";
      });

      List<Map<String, dynamic>> models = [];

      // If videoId is provided, load models specifically for this video
      if (widget.videoId != null) {
        debugPrint(" Loading models for video: ${widget.videoId}");

        //NEW: Use Firestore directly - works from any network!
        models = await FirestoreModelService.getModelsForVideo(widget.videoId!);

        // If models exist, automatically select the first/latest one
        if (models.isNotEmpty) {
          debugPrint("Found ${models.length} models for video");
          debugPrint("Auto-selecting model: ${models[0]['taskId']}");
          debugPrint("Model URL: ${models[0]['modelFileUrl']}");

          setState(() {
            _availableModels = models;
            _selectedModelUrl = models[0]['modelFileUrl'];
            _isLoadingModel = false;
            _statusMessage = "Model loaded! Tap screen to place in AR";
          });

          return;
        } else {
          debugPrint("No models found for video ${widget.videoId}");
        }
      } else {
        //Otherwise load all available models
        debugPrint("Loading all available models");

        //NEW: Use Firestore directly - works from any network!
        models = await FirestoreModelService.listAllModels();
      }

      setState(() {
        _availableModels = models;
        _isLoadingModel = false;
        if (_availableModels.isNotEmpty) {
          debugPrint("Found ${_availableModels.length} total models");
          _statusMessage =
              "${_availableModels.length} models available. Tap icon to select.";
        } else {
          debugPrint("No models found at all");
          _statusMessage = "No models found. Generate a new one!";
        }
      });
    } catch (e) {
      debugPrint("Error loading models: $e");
      setState(() {
        _isLoadingModel = false;
        _statusMessage = "Error loading models: $e";
      });
    }
  }

  // Generate 3D model from video images via backend
  Future<void> _generateModelFromVideo(String videoId) async {
    try {
      setState(() {
        _isLoadingModel = true;
        _statusMessage = "Requesting 3D model generation...";
      });

      // Use the service to generate the model
      final result = await MeshyApiService.generateModel(
        videoId: videoId,
        userId:
            'current_user_id', // Replace with actual user ID from Firebase Auth
      );

      _currentTaskId = result['task_id'];

      setState(() {
        _statusMessage = "Model generation started. Task ID: $_currentTaskId";
      });

      // Start streaming status updates
      await _streamModelStatus(_currentTaskId!);
    } catch (e) {
      debugPrint("Error generating model: $e");
      setState(() {
        _isLoadingModel = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  // Stream model status updates in real-time
  Future<void> _streamModelStatus(String taskId) async {
    try {
      await for (final update in MeshyApiService.streamModelStatus(taskId)) {
        if (update.containsKey('error')) {
          setState(() {
            _isLoadingModel = false;
            _statusMessage = "Error: ${update['error']}";
          });
          break;
        }

        final status = update['status'];
        final progress = update['progress'] ?? 0;

        setState(() {
          _statusMessage = "Model status: $status ($progress%)";
        });

        if (status == 'SUCCEEDED') {
          await _fetchGeneratedModel(taskId);
          break;
        } else if (status == 'FAILED' || status == 'CANCELED') {
          setState(() {
            _isLoadingModel = false;
            _statusMessage = "Model generation $status";
          });
          break;
        }
      }
    } catch (e) {
      debugPrint("Error streaming status: $e");
      setState(() {
        _isLoadingModel = false;
        _statusMessage = "Error checking status: $e";
      });
    }
  }

  // Fetch the generated model from backend
  Future<void> _fetchGeneratedModel(String taskId) async {
    try {
      final result = await MeshyApiService.fetchCompletedModel(
        taskId: taskId,
        userId:
            'current_user_id', // Replace with actual user ID from Firebase Auth
      );

      setState(() {
        _selectedModelUrl = result['model_public_url'];
        _isLoadingModel = false;
        _statusMessage = "Model ready! Tap to place in AR";
      });

      // Refresh the available models list
      await _loadAvailableModels();
    } catch (e) {
      debugPrint("Error fetching model: $e");
      setState(() {
        _isLoadingModel = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _checkARCompatibility() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        setState(() {
          _deviceInfo = """
            Device: ${androidInfo.brand} ${androidInfo.model}
            Android Version: ${androidInfo.version.release}
            SDK: ${androidInfo.version.sdkInt}
            Manufacturer: ${androidInfo.manufacturer}
            """;
        });

        if (androidInfo.version.sdkInt < 24) {
          setState(() {
            _isCheckingCompatibility = false;
            _isARSupported = false;
            _statusMessage =
                "Device NOT supported\n\nYour Android version is too old.\nARCore requires Android 7.0 (API 24) or higher.\nYour device: Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})";
          });
          return;
        }

        String deviceModel = androidInfo.model.toLowerCase();
        List<String> knownIncompatible = ['emulator', 'sdk'];

        bool isEmulator =
            knownIncompatible.any((term) => deviceModel.contains(term));

        if (isEmulator) {
          setState(() {
            _isCheckingCompatibility = false;
            _isARSupported = false;
            _statusMessage =
                "Emulator detected\n\nARCore does not work on emulators.\nPlease use a real physical device.";
          });
          return;
        }

        setState(() {
          _isCheckingCompatibility = false;
          _isARSupported = true;
          _statusMessage =
              "Device appears compatible\n\nAttempting to initialize AR...";
        });
      }
    } catch (e) {
      debugPrint("Error checking compatibility: $e");
      setState(() {
        _isCheckingCompatibility = false;
        _isARSupported = true;
        _statusMessage =
            "Could not verify compatibility\n\nAttempting to initialize AR anyway...";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: _isARSupported && !_isCheckingCompatibility
            ? [
                IconButton(
                  icon: const Icon(Icons.view_in_ar),
                  onPressed: _showModelSelector,
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCheckingCompatibility) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Checking device compatibility..."),
          ],
        ),
      );
    }

    if (!_isARSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _deviceInfo,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                if (_isLoadingModel)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedModelUrl != null
                  ? 'Tap screen to place 3D model'
                  : 'Select a model from the menu above',
              style: TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select 3D Model',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Clear all models button
              if (nodes.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text('Clear all models'),
                  subtitle: Text('Remove ${nodes.length} placed models'),
                  onTap: () async {
                    await _clearAllModels();
                    Navigator.pop(context);
                  },
                ),

              if (_availableModels.isEmpty)
                ListTile(
                  leading: Icon(Icons.add_circle, color: Colors.green),
                  title: Text('Generate from current video'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.videoId != null) {
                      _generateModelFromVideo(widget.videoId!);
                    }
                  },
                )
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableModels.length,
                    itemBuilder: (context, index) {
                      final model = _availableModels[index];
                      return ListTile(
                        leading: Icon(Icons.view_in_ar),
                        title: Text(model['taskId'] ?? 'Model ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(model['status'] ?? 'ready'),
                            Text(
                              model['modelFileUrl'] ?? 'No URL',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedModelUrl = model['modelFileUrl'];
                            // Reset to force new download
                            _statusMessage =
                                "Model selected. Tap screen to place!";
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    debugPrint("=== AR VIEW CREATED ===");

    setState(() {
      arSessionManager = sessionManager;
      arObjectManager = objectManager;
      arAnchorManager = anchorManager;
    });

    try {
      debugPrint("Initializing AR session with enhanced settings...");
      arSessionManager!.onInitialize(
        showFeaturePoints: true,
        showPlanes: true,
        showWorldOrigin: true,
        handleTaps: false,
        handlePans: true,
        handleRotation: true,
      );

      debugPrint(" Initializing AR object manager...");
      arObjectManager!.onInitialize();

      debugPrint(" Setting up tap handler...");
      arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

      debugPrint(" Setting up plane detection handler...");
      arSessionManager!.onPlaneDetected = (planeId) {
        debugPrint(" Plane detected with ID: $planeId");
        setState(() {
          _statusMessage = "Plane detected! Tap to place model.";
        });
      };

      setState(() {
        _statusMessage = " AR Session Active\n Move device to detect planes";
      });

      debugPrint(" AR initialized successfully");
    } catch (e) {
      debugPrint(" AR initialization error: $e");
      setState(() {
        _statusMessage = " AR Init Failed: $e";
      });
    }
  }

  // Download GLB model to local storage for better AR compatibility
  Future<String?> _downloadModelToLocal(String url) async {
    try {
      debugPrint("Downloading model from: $url");

      setState(() {
        _statusMessage = "Downloading 3D model...";
      });

      // Get the application's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/ar_models');

      // Create directory if it doesn't exist
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      // Generate unique filename from URL or timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.glb';
      final filePath = '${modelsDir.path}/$fileName';

      // Download the file
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw Exception(
              'Download timeout - model file too large or slow connection');
        },
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        final fileSize = await file.length();
        debugPrint("Model downloaded successfully!");
        debugPrint("Local path: $filePath");
        debugPrint("File size: ${(fileSize / 1024).toStringAsFixed(2)} KB");

        setState(() {
          _statusMessage = "Model ready! Tap to place in AR";
        });

        return filePath;
      } else {
        debugPrint("Download failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error downloading model: $e");
      setState(() {
        _statusMessage = "Download failed: $e";
      });
      return null;
    }
  }

  // Get optimal scale based on file size (Meshy AI optimization)
  double _getOptimalScale(int fileSizeBytes) {
    final double sizeMB = fileSizeBytes / (1024 * 1024);

    debugPrint(
        "Calculating optimal scale for ${sizeMB.toStringAsFixed(2)} MB model");

    double scale;
    if (sizeMB < 5.0) {
      debugPrint("  Small model: Using 100% scale");
      scale = 1.0; // Small models: full scale
    } else if (sizeMB < 15.0) {
      debugPrint("  Medium model: Using 60% scale");
      scale = 0.6; // Medium models: balanced scale
    } else {
      debugPrint("  Large model: Using 40% scale");
      scale = 0.4; // Large models: reduced scale for performance
    }

    debugPrint("  Returning scale: $scale (type: ${scale.runtimeType})");
    return scale;
  }

  // Validate that the model URL is accessible
  Future<bool> _validateModelUrl(String url) async {
    try {
      debugPrint(" Validating model URL: $url");
      final response = await http.head(Uri.parse(url));
      debugPrint(" URL response status: ${response.statusCode}");
      debugPrint(" Content-Type: ${response.headers['content-type']}");
      debugPrint(" Content-Length: ${response.headers['content-length']}");

      if (response.statusCode == 200) {
        debugPrint(" Model URL is accessible");
        return true;
      } else {
        debugPrint(" Model URL returned status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint(" Error validating model URL: $e");
      return false;
    }
  }

  Future<void> _onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    debugPrint("=== PLANE TAP DETECTED ===");
    debugPrint("Hit results count: ${hitTestResults.length}");
    debugPrint("Selected model URL: $_selectedModelUrl");

    if (hitTestResults.isEmpty) {
      debugPrint("No hit test results");
      setState(() {
        _statusMessage = "No surface detected. Try moving the camera.";
      });
      return;
    }

    if (_selectedModelUrl == null) {
      debugPrint("No model URL selected");
      setState(() {
        _statusMessage = "No model selected. Choose a model first.";
      });
      return;
    }

    final hit = hitTestResults.first;
    debugPrint("Hit position: ${hit.worldTransform.getColumn(3)}");

    setState(() {
      _statusMessage = "Placing Meshy AI model...";
    });

    try {
      final isUrlValid = await _validateModelUrl(_selectedModelUrl!);
      if (!isUrlValid) {
        setState(() {
          _statusMessage = "Invalid model URL. Please select another model.";
        });
        return;
      }

      // Download the model to local storage
      final localModelPath = await _downloadModelToLocal(_selectedModelUrl!);
      if (localModelPath == null) {
        setState(() {
          _statusMessage = "Failed to download model. Please try again.";
        });
        return;
      }

// Store for cleanup

      // Get file size for optimal scaling
      final fileSize = await File(localModelPath).length();
      final optimalScale = _getOptimalScale(fileSize);

      debugPrint("Meshy AI Model Optimization:");
      debugPrint(
          "  - File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB");
      debugPrint("  - Optimal scale: $optimalScale");
      debugPrint("  - Scale type check: ${optimalScale.runtimeType}");
      debugPrint("  - Is finite: ${optimalScale.isFinite}");

      final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
      debugPrint("⚓ Anchor added: $didAddAnchor");

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Ensure scale is a valid double and create Vector3 components explicitly
        final double scaleValue = optimalScale.isFinite ? optimalScale : 0.5;
        debugPrint("  - Final scale value: $scaleValue");

        // Create AR node optimized for Meshy AI GLB models
        ARNode node = ARNode(
          type: NodeType.webGLB,
          uri:
              'file://$localModelPath', // Local file path (ar_flutter_plugin_2 compatible)
          scale: vector.Vector3(scaleValue, scaleValue, scaleValue),
          position: vector.Vector3(
            hit.worldTransform.getColumn(3).x,
            hit.worldTransform.getColumn(3).y + 0.15, // Elevated for visibility
            hit.worldTransform.getColumn(3).z,
          ),
          rotation: vector.Vector4(0, 0, 0, 1),
        );

        debugPrint("Meshy AI Model AR Configuration:");
        debugPrint("  - Plugin: ar_flutter_plugin_2 v0.0.3");
        debugPrint("  - Format: GLB (Binary GLTF)");
        debugPrint("  - Features: PBR materials, optimized mesh");
        debugPrint("  - Type: ${node.type}");
        debugPrint("  - Path: ${node.uri}");
        debugPrint("  - Scale: ${node.scale}");
        debugPrint("  - Position: ${node.position}");

        setState(() {
          _statusMessage = "Placing 3D model in AR...";
        });

        bool? didAddNode =
            await arObjectManager!.addNode(node, planeAnchor: newAnchor);
        debugPrint("📦 Node added result: $didAddNode");

        // Add more detailed error checking
        if (didAddNode == null) {
          debugPrint("⚠️ addNode returned null - possible plugin error");
          setState(() {
            _statusMessage = "Plugin error - check logs";
          });
          await arAnchorManager!.removeAnchor(newAnchor);
          anchors.remove(newAnchor);
        } else if (didAddNode == false) {
          debugPrint("❌ addNode returned false - node creation failed");
          debugPrint("   Troubleshooting:");
          debugPrint("   - File path: $localModelPath");
          debugPrint(
              "   - File exists: ${await File(localModelPath).exists()}");
          debugPrint(
              "   - File size: ${await File(localModelPath).length()} bytes");
          debugPrint("   Possible causes:");
          debugPrint("   - GLB file format incompatible with ARCore");
          debugPrint("   - File corrupted during download");
          debugPrint("   - ARCore version incompatibility");
          debugPrint("   - Insufficient device resources");

          setState(() {
            _statusMessage = "Failed to load 3D model. Try a different model.";
          });
          await arAnchorManager!.removeAnchor(newAnchor);
          anchors.remove(newAnchor);
        } else if (didAddNode == true) {
          nodes.add(node);
          setState(() {
            _statusMessage = "3D Model placed! (${nodes.length} total)";
          });
          debugPrint("Model placed successfully!");

          // Additional debugging for model visibility
          debugPrint("🔍 Model placement details:");
          debugPrint("  - Total nodes in scene: ${nodes.length}");
          debugPrint("  - Total anchors in scene: ${anchors.length}");
          debugPrint("  - Local file: $localModelPath");
          debugPrint("  - Node URI: ${node.uri}");
          debugPrint("  - Node scale: ${node.scale}");
          debugPrint("  - Node position: ${node.position}");
          debugPrint("  - Anchor transformation: ${newAnchor.transformation}");

          // Give user feedback
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _statusMessage = "Model visible! Look at the placed location.";
              });
            }
          });
        }
      } else {
        setState(() {
          _statusMessage = "Failed to place model (anchor)";
        });
        debugPrint("Failed to add anchor to AR scene");
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
      debugPrint("Exception in _onPlaneOrPointTapped: $e");
    }
  }

  // Clear all placed models and anchors
  Future<void> _clearAllModels() async {
    try {
      debugPrint("Clearing all models...");

      // Remove all nodes
      for (final node in nodes) {
        await arObjectManager?.removeNode(node);
      }

      // Remove all anchors
      for (final anchor in anchors) {
        await arAnchorManager?.removeAnchor(anchor);
      }

      // Clear lists
      nodes.clear();
      anchors.clear();

      setState(() {
        _statusMessage = "All models cleared. Select a new model to place.";
      });

      debugPrint(" All models cleared successfully");
    } catch (e) {
      debugPrint(" Error clearing models: $e");
      setState(() {
        _statusMessage = "Error clearing models: $e";
      });
    }
  }
}
