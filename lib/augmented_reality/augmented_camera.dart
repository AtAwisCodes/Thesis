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
import 'dart:io';

class MeshyARCamera extends StatefulWidget {
  final String? videoId;

  const MeshyARCamera({super.key, this.videoId});

  @override
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

  @override
  void initState() {
    super.initState();
    _checkARCompatibility();
    _loadAvailableModels();
  }

  // Load available 3D models for this specific video
  Future<void> _loadAvailableModels() async {
    try {
      setState(() {
        _isLoadingModel = true;
        _statusMessage = "Loading available 3D models...";
      });

      List<Map<String, dynamic>> models = [];

      // If videoId is provided, load models specifically for this video
      if (widget.videoId != null) {
        models = await MeshyApiService.getModelsForVideo(widget.videoId!);
      } else {
        // Otherwise load all available models
        models = await MeshyApiService.listAllModels();
      }

      setState(() {
        _availableModels = models;
        _isLoadingModel = false;
        if (_availableModels.isNotEmpty) {
          _statusMessage =
              "${_availableModels.length} models available for this video";
        } else {
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
          _statusMessage = "Model status: $status (${progress}%)";
        });

        if (status == 'SUCCEEDED') {
          // Fetch the completed model
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
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        setState(() {
          _deviceInfo = """
Device: ${iosInfo.name}
iOS Version: ${iosInfo.systemVersion}
Model: ${iosInfo.model}
""";
          _isCheckingCompatibility = false;
          _isARSupported = true;
          _statusMessage =
              "iOS device detected\n\nAttempting to initialize AR...";
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
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
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
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _removeAllNodes,
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
                  ? 'Tap screen to place 3D model from Meshy AI'
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
                        subtitle: Text(model['status'] ?? 'ready'),
                        onTap: () {
                          setState(() {
                            _selectedModelUrl = model['modelFileUrl'];
                            _statusMessage = "Model selected. Tap to place!";
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
      arSessionManager!.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: false,
      );

      arObjectManager!.onInitialize();
      arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

      setState(() {
        _statusMessage = "AR Session Active\nMove device to detect planes";
      });

      debugPrint("AR initialized successfully");
    } catch (e) {
      debugPrint("AR initialization error: $e");
      setState(() {
        _statusMessage = "AR Init Failed: $e";
      });
    }
  }

  Future<void> _onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || _selectedModelUrl == null) return;

    final hit = hitTestResults.first;

    setState(() {
      _statusMessage = "Placing Meshy AI model...";
    });

    try {
      final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Use the Meshy AI model URL instead of local asset
        final node = ARNode(
          type: NodeType.webGLB,
          uri: _selectedModelUrl!,
          scale: vector.Vector3(0.2, 0.2, 0.2),
          position: vector.Vector3(
            hit.worldTransform.getColumn(3).x,
            hit.worldTransform.getColumn(3).y,
            hit.worldTransform.getColumn(3).z,
          ),
          rotation: vector.Vector4(0, 0, 0, 1),
        );

        bool? didAddNode =
            await arObjectManager!.addNode(node, planeAnchor: newAnchor);

        if (didAddNode == true) {
          nodes.add(node);
          setState(() {
            _statusMessage = "Meshy model placed! Total: ${nodes.length}";
          });
        } else {
          setState(() {
            _statusMessage = "Failed to place model";
          });
          await arAnchorManager!.removeAnchor(newAnchor);
          anchors.remove(newAnchor);
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _removeAllNodes() async {
    for (var node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    nodes.clear();

    for (var anchor in anchors) {
      await arAnchorManager?.removeAnchor(anchor);
    }
    anchors.clear();

    setState(() {
      _statusMessage = "All objects cleared";
    });
  }
}
