import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:provider/provider.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/model/compact_video_card.dart';
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
    'Glass',
    'Cardboard',
    'Clothes',
    'Empty',
  ];

  int _modelInputHeight = 0;
  int _modelInputWidth = 0;
  int _modelInputChannels = 0;
  tfl.TensorType? _inputType;
  tfl.TensorType? _outputType;

  // Detection state
  String _detectedLabel = '';
  bool _isProcessing = false;
  bool _showFlash = false;

  // Draggable sheet state
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _loadModel();
      await _initCamera();
      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadModel() async {
    // Model path declared in pubspec assets
    final tfl.InterpreterOptions options = tfl.InterpreterOptions();
    final tfl.Interpreter interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/model.tflite',
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
        });
      }
    } catch (e) {
      print('Camera switch error: $e');
      // Reset the switching flag on error
      _isSwitchingCamera = false;

      if (mounted) {
        setState(() {});
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
        setState(() {});
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
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

      // Navigate to preview page
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoPreviewPage(
              imageBytes: imageBytes,
              onAnalyze: (bytes) => _analyzeImage(bytes),
            ),
          ),
        );

        // If analysis was performed, update the state
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _detectedLabel = result['label'];
          });
        }
      }
    } catch (e) {
      print('Capture error: $e');
      if (mounted) {
        setState(() {
          _showFlash = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeImage(Uint8List imageBytes) async {
    try {
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

      // Debug: Print all probabilities for analysis
      print('=== Model Predictions ===');
      for (int i = 0; i < _labels.length; i++) {
        print('${_labels[i]}: ${(probs[i] * 100).toStringAsFixed(2)}%');
      }

      // Find best prediction
      int maxIdx = 0;
      double maxVal = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxVal) {
          maxVal = probs[i];
          maxIdx = i;
        }
      }

      print(
          'Max prediction: ${_labels[maxIdx]} with ${(maxVal * 100).toStringAsFixed(2)}%');

      // Higher threshold for real objects (PlasticBottles, Glass, Cardboard, Clothes)
      // Even higher threshold for Empty class
      const double objectThreshold = 0.85; // 85% confidence for real objects
      const double emptyThreshold = 0.95; // 95% confidence for Empty

      String text;
      String label;

      if (_labels[maxIdx] == 'Empty') {
        // Empty class needs very high confidence
        if (maxVal >= emptyThreshold) {
          text = '${_labels[maxIdx]} ${(maxVal * 100).toStringAsFixed(1)}%';
          label = _labels[maxIdx];
        } else {
          text = 'Uncertain... Try again or scan a recyclable object';
          label = '';
        }
      } else {
        // Regular objects need moderate-high confidence
        if (maxVal >= objectThreshold) {
          text = '${_labels[maxIdx]} ${(maxVal * 100).toStringAsFixed(1)}%';
          label = _labels[maxIdx];
        } else {
          text = 'Uncertain... Try again or scan a recyclable object';
          label = '';
        }
      }

      // Debug: Print final result
      print(
          'Final result: "$label" (confidence: ${(maxVal * 100).toStringAsFixed(2)}%)');

      return {
        'text': text,
        'label': label,
        'confidence': maxVal,
      };
    } catch (e) {
      print('Analyze error: $e');
      return {
        'text': 'Error analyzing image',
        'label': '',
        'confidence': 0.0,
      };
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

    // Dispose draggable controller
    _sheetController.dispose();

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate camera height to end at the scroll sheet position
            final cameraHeight =
                constraints.maxHeight * 0.67; // 67% because sheet starts at 33%

            return Stack(
              children: <Widget>[
                // Camera section - sized to end at scroll sheet
                SizedBox(
                  height: cameraHeight,
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
                            onPressed:
                                _cameras.length > 1 ? _toggleCamera : null,
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
                      // Capture button - centered at bottom of camera section
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isProcessing ? null : _capturePhoto,
                              borderRadius: BorderRadius.circular(35),
                              child: Container(
                                width: 70,
                                height: 70,
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
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _isProcessing
                                    ? const Padding(
                                        padding: EdgeInsets.all(18.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 32,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Draggable video suggestions sheet
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.33,
                  minChildSize: 0.33,
                  maxChildSize: 0.85,
                  snap: true,
                  snapSizes: const [0.33, 0.55, 0.85],
                  builder: (BuildContext context,
                      ScrollController scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle and header
                          GestureDetector(
                            onTap: () {
                              // Cycle through snap sizes on tap (33% -> 55% -> 85% -> 33%)
                              if (_sheetController.size < 0.44) {
                                _sheetController.animateTo(
                                  0.55,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else if (_sheetController.size < 0.7) {
                                _sheetController.animateTo(
                                  0.85,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _sheetController.animateTo(
                                  0.33,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  // Drag indicator
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline,
                                            color: Colors.greenAccent,
                                            size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _detectedLabel.isNotEmpty
                                                ? 'Videos about $_detectedLabel'
                                                : 'Suggested Videos',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Expand/collapse icon hint
                                        Icon(
                                          Icons.drag_handle,
                                          color: Colors.grey[600],
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Video list with StreamBuilder
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
                                    final searchTerm =
                                        originalLabel.toLowerCase();

                                    // Check if "Empty" was detected - show error message then videos
                                    if (originalLabel == 'Empty') {
                                      // Combine all videos for display
                                      final allVideos = [
                                        ...uploadedVideos.map((v) => {
                                              "type": "uploaded",
                                              "data": v,
                                            }),
                                        ...ytViewModel.playlistItems
                                            .map((yt) => {
                                                  "type": "youtube",
                                                  "data": yt,
                                                }),
                                      ];

                                      return Column(
                                        children: [
                                          // Error message at the top
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            margin: const EdgeInsets.fromLTRB(
                                                16, 16, 16, 8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    Colors.red.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.red,
                                                    size: 24),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'Please scan a recyclable object (Plastic Bottles, Cardboard, Glass, or Clothes)',
                                                    style: TextStyle(
                                                      color: Colors.red[300],
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Video list below error message
                                          Expanded(
                                            child: ListView.builder(
                                              controller: scrollController,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              itemCount: allVideos.length,
                                              itemBuilder: (context, index) {
                                                final item = allVideos[index];
                                                return CompactVideoCard(
                                                    item: item);
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }

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

                                      print(
                                          'Search variations: $searchVariations');
                                    }

                                    // Separate matching and non-matching videos
                                    final matchingUploaded =
                                        <Map<String, dynamic>>[];
                                    final nonMatchingUploaded =
                                        <Map<String, dynamic>>[];

                                    for (var video in uploadedVideos) {
                                      if (searchTerm.isEmpty) {
                                        nonMatchingUploaded.add(video);
                                        continue;
                                      }

                                      final title = (video['title'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final description =
                                          (video['description'] ?? '')
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
                                        matchingUploaded.add(video);
                                      } else {
                                        nonMatchingUploaded.add(video);
                                      }
                                    }

                                    final matchingYt = <dynamic>[];
                                    final nonMatchingYt = <dynamic>[];

                                    for (var yt in ytViewModel.playlistItems) {
                                      if (searchTerm.isEmpty) {
                                        nonMatchingYt.add(yt);
                                        continue;
                                      }

                                      final title = yt.videoTitle.toLowerCase();

                                      // Check if any search variation matches
                                      final matches = searchVariations.any(
                                          (variant) => title.contains(variant));

                                      if (matches) {
                                        print(
                                            'YouTube video matched: ${yt.videoTitle}');
                                        matchingYt.add(yt);
                                      } else {
                                        nonMatchingYt.add(yt);
                                      }
                                    }

                                    print(
                                        'Matching uploaded: ${matchingUploaded.length}');
                                    print(
                                        'Matching YouTube: ${matchingYt.length}');
                                    print(
                                        'Non-matching uploaded: ${nonMatchingUploaded.length}');
                                    print(
                                        'Non-matching YouTube: ${nonMatchingYt.length}');

                                    // Combine: matching videos first, then non-matching
                                    final combinedList = [
                                      ...matchingUploaded.map((v) => {
                                            "type": "uploaded",
                                            "data": v,
                                            "isMatch": true
                                          }),
                                      ...matchingYt.map((yt) => {
                                            "type": "youtube",
                                            "data": yt,
                                            "isMatch": true
                                          }),
                                      ...nonMatchingUploaded.map((v) => {
                                            "type": "uploaded",
                                            "data": v,
                                            "isMatch": false
                                          }),
                                      ...nonMatchingYt.map((yt) => {
                                            "type": "youtube",
                                            "data": yt,
                                            "isMatch": false
                                          }),
                                    ];

                                    if (combinedList.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.video_library,
                                                color: Colors.grey, size: 48),
                                            SizedBox(height: 16),
                                            Text(
                                              'No videos found',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Try scanning an object!',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    // Calculate where the divider should be
                                    final matchingCount =
                                        matchingUploaded.length +
                                            matchingYt.length;
                                    final hasMatching = matchingCount > 0 &&
                                        searchTerm.isNotEmpty;
                                    final hasNonMatching =
                                        combinedList.length > matchingCount;
                                    final objectDetectedButNoMatch =
                                        searchTerm.isNotEmpty &&
                                            matchingCount == 0 &&
                                            hasNonMatching;

                                    // Calculate number of headers needed
                                    int headerCount = 0;
                                    if (hasMatching && hasNonMatching) {
                                      headerCount =
                                          2; // Both matching and other videos headers
                                    } else if (objectDetectedButNoMatch) {
                                      headerCount = 1; // Only "no match" header
                                    }

                                    return ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount:
                                          combinedList.length + headerCount,
                                      itemBuilder: (context, index) {
                                        // Show matching section header at the top
                                        if (index == 0 && hasMatching) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 12),
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.greenAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.black,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Related to ${_detectedLabel}',
                                                        style: const TextStyle(
                                                          color: Colors
                                                              .greenAccent,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$matchingCount video${matchingCount != 1 ? 's' : ''} found',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .greenAccent
                                                              .withOpacity(0.7),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        // Show "no match found" header when object detected but no matching videos
                                        if (index == 0 &&
                                            objectDetectedButNoMatch) {
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.info_outline,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'No matches for "${_detectedLabel}"',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.orange,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Showing all available videos',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .orange
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(
                                                    height: 16,
                                                    color: Colors.grey),
                                                Row(
                                                  children: [
                                                    Icon(Icons.video_library,
                                                        color: Colors.grey,
                                                        size: 18),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'All Videos (${combinedList.length})',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        // Show other videos section header
                                        if (hasMatching &&
                                            hasNonMatching &&
                                            index == matchingCount + 1) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 12),
                                            margin: const EdgeInsets.only(
                                                top: 8, bottom: 8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.video_library,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Other Videos',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${combinedList.length - matchingCount} more video${(combinedList.length - matchingCount) != 1 ? 's' : ''}',
                                                        style: TextStyle(
                                                          color: Colors.grey
                                                              .withOpacity(0.7),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        // Adjust index for actual video items
                                        int videoIndex;
                                        if (hasMatching && hasNonMatching) {
                                          videoIndex = index <= matchingCount
                                              ? index - 1
                                              : index - 2;
                                        } else if (objectDetectedButNoMatch) {
                                          videoIndex = index - 1;
                                        } else if (hasMatching) {
                                          videoIndex = index - 1;
                                        } else {
                                          videoIndex = index;
                                        }

                                        if (videoIndex < 0 ||
                                            videoIndex >= combinedList.length) {
                                          return const SizedBox.shrink();
                                        }

                                        final item = combinedList[videoIndex];

                                        // Use compact video card for better UX
                                        return CompactVideoCard(item: item);
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Separate page for photo preview
class PhotoPreviewPage extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<Map<String, dynamic>> Function(Uint8List) onAnalyze;

  const PhotoPreviewPage({
    Key? key,
    required this.imageBytes,
    required this.onAnalyze,
  }) : super(key: key);

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  bool _isAnalyzing = false;
  String? _resultText;
  bool _hasAnalyzed = false;

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await widget.onAnalyze(widget.imageBytes);
      setState(() {
        _resultText = result['text'];
        _hasAnalyzed = true;
        _isAnalyzing = false;
      });

      // Wait a moment to show the result, then return
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Photo preview
            Expanded(
              child: Stack(
                children: [
                  // Image
                  Center(
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Result overlay
                  if (_hasAnalyzed && _resultText != null)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.black,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _resultText!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Retake button
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            _isAnalyzing ? null : () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Analyze button
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isAnalyzing || _hasAnalyzed ? null : _analyze,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color:
                                _hasAnalyzed ? Colors.grey : Colors.greenAccent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _hasAnalyzed
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.greenAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _isAnalyzing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _hasAnalyzed
                                          ? Icons.check
                                          : Icons.psychology,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _hasAnalyzed ? 'Done' : 'Analyze',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
