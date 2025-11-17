import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:provider/provider.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/model/yt_video_card.dart';
import 'package:rexplore/model/uploaded_video_card.dart';
import 'package:image/image.dart' as img;

class cameraFunc extends StatefulWidget {
  final CameraDescription camera;
  const cameraFunc({super.key, required this.camera});

  @override
  State<cameraFunc> createState() => _cameraFuncState();
}

class _cameraFuncState extends State<cameraFunc> {
  CameraController? _controller;
  tfl.Interpreter? _interpreter;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isSwitchingCamera = false;

  // Video service for suggestions
  final VideoUploadService _videoService = VideoUploadService();

  // Mirror Java labels
  static const List<String> _labels = <String>[
    'PlasticBottles',
    'Cardboard',
    'Glass',
    'Clothes',
  ];

  String _predictionText = 'Loading model...';
  int _modelInputHeight = 0;
  int _modelInputWidth = 0;
  int _modelInputChannels = 0;
  tfl.TensorType? _inputType;
  tfl.TensorType? _outputType;

  // Detection state
  String _detectedLabel = '';
  bool _isProcessing = false;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _loadModel();
      await _initCamera();
      setState(() {
        _predictionText = 'Tap capture button to analyze';
      });
    } catch (e) {
      setState(() {
        _predictionText = 'Init error: $e';
      });
    }
  }

  Future<void> _loadModel() async {
    // Model path declared in pubspec assets
    final tfl.InterpreterOptions options = tfl.InterpreterOptions();
    final tfl.Interpreter interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/recycle.tflite',
      options: options,
    );

    // Inspect model IO
    final tfl.Tensor inputTensor = interpreter.getInputTensor(0);
    final List<int> inputShape = inputTensor.shape;
    _inputType = inputTensor.type;
    _modelInputHeight = inputShape[1];
    _modelInputWidth = inputShape[2];
    _modelInputChannels = inputShape[3];

    final tfl.Tensor outputTensor = interpreter.getOutputTensor(0);
    _outputType = outputTensor.type;

    _interpreter = interpreter;
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    // Start with BACK camera if available, otherwise first camera
    _selectedCameraIndex = 0;
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        _selectedCameraIndex = i;
        break;
      }
    }
    await _switchCamera();
  }

  Future<void> _switchCamera() async {
    if (_cameras.isEmpty) return;

    try {
      // Stop image stream first to prevent race conditions
      if (_controller?.value.isStreamingImages ?? false) {
        await _controller?.stopImageStream();
      }

      // Dispose current controller with longer wait
      final oldController = _controller;

      // Clear the controller first in UI
      if (mounted) {
        setState(() {
          _controller = null;
          _detectedLabel = '';
          _predictionText = 'Switching camera...';
        });
      }

      // Now dispose the old controller
      await oldController?.dispose();

      // Longer delay to ensure complete cleanup
      await Future.delayed(const Duration(milliseconds: 200));

      final CameraDescription selected = _cameras[_selectedCameraIndex];
      final CameraController controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      // Verify controller is ready
      if (!controller.value.isInitialized) {
        throw Exception('Controller failed to initialize');
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _predictionText = 'Tap capture button to analyze';
        });
      }
    } catch (e) {
      print('Camera switch error: $e');
      // Reset the switching flag on error
      _isSwitchingCamera = false;

      if (mounted) {
        setState(() {
          _predictionText = 'Camera switch failed';
        });
      }

      // Try to recover by reinitializing with the current index
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isSwitchingCamera) {
        _isSwitchingCamera = true;
        try {
          await _switchCamera();
        } finally {
          _isSwitchingCamera = false;
        }
      }
    }
  }

  void _toggleCamera() {
    if (_cameras.length <= 1 || _isSwitchingCamera) return;

    _isSwitchingCamera = true;

    // Update the camera index
    final newIndex = (_selectedCameraIndex + 1) % _cameras.length;

    if (mounted) {
      setState(() {
        _selectedCameraIndex = newIndex;
      });
    }

    // Perform the switch with proper error handling
    _switchCamera().then((_) {
      if (mounted) {
        _isSwitchingCamera = false;
      }
    }).catchError((e) {
      print('Toggle camera error: $e');
      if (mounted) {
        _isSwitchingCamera = false;
        setState(() {
          _predictionText = 'Failed to switch camera';
        });
      }
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _predictionText = 'Analyzing...';
      _showFlash = true;
    });

    // Show flash effect for a brief moment
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
      }
    });

    try {
      // Capture image
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode image
      final img.Image? capturedImage = img.decodeImage(imageBytes);

      if (capturedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final img.Image resizedImage = img.copyResize(
        capturedImage,
        width: _modelInputWidth,
        height: _modelInputHeight,
      );

      // Convert to RGB and run inference
      final Uint8List rgbBytes = _imageToRgbBytes(resizedImage);
      final Object inputBuffer = _buildInput(rgbBytes);
      final List<double> probs = _runInference(_interpreter!, inputBuffer);

      // Find best prediction
      int maxIdx = 0;
      double maxVal = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxVal) {
          maxVal = probs[i];
          maxIdx = i;
        }
      }

      const double threshold = 0.6;
      final String text = (maxVal > threshold)
          ? '${_labels[maxIdx]} ${(maxVal * 100).toStringAsFixed(1)}%'
          : 'Uncertain... Try again';

      if (mounted) {
        setState(() {
          _predictionText = text;
          _detectedLabel = maxVal > threshold ? _labels[maxIdx] : '';
          _isProcessing = false;
        });

        // Debug: Print detected label
        if (_detectedLabel.isNotEmpty) {
          print('Detected label: "$_detectedLabel"');
        }
      }
    } catch (e) {
      print('Capture and analyze error: $e');
      if (mounted) {
        setState(() {
          _predictionText = 'Error analyzing image';
          _isProcessing = false;
        });
      }
    }
  }

  // Convert img.Image to RGB bytes
  Uint8List _imageToRgbBytes(img.Image image) {
    final Uint8List bytes = Uint8List(image.width * image.height * 3);
    int index = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel pixel = image.getPixel(x, y);
        bytes[index++] = pixel.r.toInt();
        bytes[index++] = pixel.g.toInt();
        bytes[index++] = pixel.b.toInt();
      }
    }

    return bytes;
  }

  Object _buildInput(Uint8List rgbBytes) {
    // rgbBytes is length = width * height * 3, channel order RGB 0..255
    if (_inputType == tfl.TensorType.float32) {
      final Float32List floats = Float32List(
          _modelInputWidth * _modelInputHeight * _modelInputChannels);
      int j = 0;
      for (int i = 0; i < rgbBytes.length; i += 3) {
        floats[j++] = rgbBytes[i] / 255.0; // R
        if (_modelInputChannels >= 2)
          floats[j++] = rgbBytes[i + 1] / 255.0; // G
        if (_modelInputChannels >= 3)
          floats[j++] = rgbBytes[i + 2] / 255.0; // B
      }
      return floats.reshape(
          <int>[1, _modelInputHeight, _modelInputWidth, _modelInputChannels]);
    } else {
      // uint8 input
      return rgbBytes.reshape(
          <int>[1, _modelInputHeight, _modelInputWidth, _modelInputChannels]);
    }
  }

  List<double> _runInference(tfl.Interpreter interpreter, Object input) {
    final List<double> output = List<double>.filled(_labels.length, 0.0);

    if (_outputType == tfl.TensorType.float32) {
      final List<List<double>> out = <List<double>>[output];
      interpreter.run(input, out);
      return out[0];
    } else {
      // Quantized outputs (uint8/int8)
      final List<List<int>> out = <List<int>>[
        List<int>.filled(_labels.length, 0)
      ];
      interpreter.run(input, out);
      final List<int> raw = out[0];
      // Heuristic: map uint8 -> [0,1], int8 -> [-1,1]
      if (_outputType == tfl.TensorType.uint8) {
        return raw.map((int v) => v / 255.0).toList(growable: false);
      }
      // int8
      return raw.map((int v) => v / 127.0).toList(growable: false);
    }
  }

  @override
  void dispose() {
    _isSwitchingCamera = false;

    // Stop image stream before disposal
    if (_controller?.value.isStreamingImages ?? false) {
      _controller?.stopImageStream().catchError((e) {
        print('Error stopping image stream: $e');
      });
    }

    _controller?.dispose().catchError((e) {
      print('Error disposing controller: $e');
    });

    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  controller == null || !controller.value.isInitialized
                      ? Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.greenAccent),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSwitchingCamera
                                      ? 'Switching camera...'
                                      : 'Initializing camera...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.previewSize!.height,
                              height: controller.value.previewSize!.width,
                              child: CameraPreview(controller),
                            ),
                          ),
                        ),
                  // Flash overlay
                  if (_showFlash)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                  // Back button - stylish design
                  Positioned(
                    top: 12,
                    left: 8,
                    child: SafeArea(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Camera toggle button
                  Positioned(
                    top: 12,
                    right: 8,
                    child: SafeArea(
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.black54,
                        onPressed: _cameras.length > 1 ? _toggleCamera : null,
                        child: Icon(
                          _cameras.isNotEmpty &&
                                  _cameras[_selectedCameraIndex]
                                          .lensDirection ==
                                      CameraLensDirection.front
                              ? Icons.camera_front
                              : Icons.camera_rear,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Capture button - centered at bottom
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : _captureAndAnalyze,
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isProcessing
                                  ? Colors.grey
                                  : Colors.greenAccent,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _isProcessing
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Detection info bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.black,
              width: double.infinity,
              child: Text(
                _predictionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // Video suggestions section
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.greenAccent, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _detectedLabel.isNotEmpty
                                ? 'Learn about $_detectedLabel'
                                : 'Suggested Videos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Video list
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _videoService.getPublicVideos(),
                        builder: (context, uploadedSnapshot) {
                          return Consumer<YtVideoviewModel>(
                            builder: (context, ytViewModel, _) {
                              final uploadedVideos =
                                  uploadedSnapshot.data ?? [];

                              // Get the original label (not lowercase yet)
                              final originalLabel = _detectedLabel;
                              final searchTerm = originalLabel.toLowerCase();

                              // Debug: Print search term
                              if (searchTerm.isNotEmpty) {
                                print('Original label: "$originalLabel"');
                                print(
                                    'Searching for videos with: "$searchTerm"');
                                print(
                                    'Total uploaded videos: ${uploadedVideos.length}');
                                print(
                                    'Total YouTube videos: ${ytViewModel.playlistItems.length}');
                              }

                              // Create search variations for better matching
                              List<String> searchVariations = [];
                              if (originalLabel.isNotEmpty) {
                                // Add original lowercase version
                                searchVariations.add(searchTerm);

                                // Handle camelCase BEFORE converting to lowercase
                                // "PlasticBottles" -> "Plastic Bottles" -> "plastic bottles"
                                final spacedTerm = originalLabel
                                    .replaceAllMapped(
                                      RegExp(r'([a-z])([A-Z])'),
                                      (match) =>
                                          '${match.group(1)} ${match.group(2)}',
                                    )
                                    .replaceAllMapped(
                                      RegExp(r'([A-Z])([A-Z][a-z])'),
                                      (match) =>
                                          '${match.group(1)} ${match.group(2)}',
                                    )
                                    .toLowerCase();

                                if (spacedTerm != searchTerm) {
                                  searchVariations.add(spacedTerm);
                                }

                                // Add individual words (only if more than one word and length > 2)
                                final words = spacedTerm
                                    .split(' ')
                                    .where((w) => w.length > 2)
                                    .toList();
                                if (words.length > 1) {
                                  searchVariations.addAll(words);
                                }

                                // Remove duplicates
                                searchVariations =
                                    searchVariations.toSet().toList();

                                print('Search variations: $searchVariations');
                              }

                              // Filter videos by detected object only
                              final filteredUploaded =
                                  uploadedVideos.where((video) {
                                if (searchTerm.isEmpty) return true;

                                final title = (video['title'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final description = (video['description'] ?? '')
                                    .toString()
                                    .toLowerCase();

                                // Check if any search variation matches
                                final matches = searchVariations.any(
                                    (variant) =>
                                        title.contains(variant) ||
                                        description.contains(variant));

                                if (matches) {
                                  print(
                                      'Uploaded video matched: ${video['title']}');
                                }

                                return matches;
                              }).toList();

                              final filteredYt =
                                  ytViewModel.playlistItems.where((yt) {
                                if (searchTerm.isEmpty) return true;

                                final title = yt.videoTitle.toLowerCase();

                                // Check if any search variation matches
                                final matches = searchVariations
                                    .any((variant) => title.contains(variant));

                                if (matches) {
                                  print(
                                      'YouTube video matched: ${yt.videoTitle}');
                                }

                                return matches;
                              }).toList();

                              print(
                                  'Filtered uploaded: ${filteredUploaded.length}');
                              print('Filtered YouTube: ${filteredYt.length}');

                              // Combine and limit to 10 videos
                              final combinedList = [
                                ...filteredUploaded.map(
                                    (v) => {"type": "uploaded", "data": v}),
                                ...filteredYt.map(
                                    (yt) => {"type": "youtube", "data": yt}),
                              ].take(10).toList();

                              if (combinedList.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.video_library,
                                          color: Colors.grey, size: 48),
                                      SizedBox(height: 16),
                                      Text(
                                        'No videos found',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Try scanning an object!',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: combinedList.length,
                                itemBuilder: (context, index) {
                                  final item = combinedList[index];

                                  if (item["type"] == "uploaded") {
                                    final videoData =
                                        item["data"] as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child:
                                          UploadedVideoCard(videos: videoData),
                                    );
                                  } else {
                                    final ytVideo = item["data"] as dynamic;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: YoutubeVideoCard(ytVideo: ytVideo),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
