import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class SimpleYOLOCamera extends StatefulWidget {
  final CameraDescription camera;

  const SimpleYOLOCamera({super.key, required this.camera});

  @override
  _SimpleYOLOCameraState createState() => _SimpleYOLOCameraState();
}

class _SimpleYOLOCameraState extends State<SimpleYOLOCamera> {
  // Camera
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  // YOLO Model
  Interpreter? _interpreter;
  List<String> _labels = [];

  // Detection Results
  List<Detection> _detections = [];
  String? _capturedImagePath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadYOLOModel();
    _loadLabels();
  }

  // Initialize Camera
  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();

    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Load YOLO Model
  Future<void> _loadYOLOModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/my_model.tflite',
      );

      print('YOLO Model loaded successfully!');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Failed to load model: $e');
      _showError(
          'Failed to load YOLO model. Make sure yolo_model.tflite is in assets/models/');
    }
  }

  // Load Labels
  Future<void> _loadLabels() async {
    try {
      final labelData = await DefaultAssetBundle.of(context)
          .loadString('assets/label/labels.txt');

      _labels =
          labelData.split('\n').where((label) => label.isNotEmpty).toList();
      print('Loaded ${_labels.length} labels');
    } catch (e) {
      print('Failed to load labels: $e');
      _showError('Failed to load labels.txt');
    }
  }

  // Capture Photo and Run Detection
  Future<void> _captureAndDetect() async {
    if (!_isCameraInitialized || _isProcessing || _interpreter == null) return;

    setState(() {
      _isProcessing = true;
      _detections.clear();
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController.takePicture();
      _capturedImagePath = imageFile.path;

      // Run YOLO detection
      await _runYOLODetection(imageFile.path);

      setState(() {
        _isProcessing = false;
      });

      // Show results
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_detections.isEmpty
              ? 'No objects detected'
              : 'Found ${_detections.length} object(s)!'),
          backgroundColor: _detections.isEmpty ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print('Error during detection: $e');
      setState(() {
        _isProcessing = false;
      });
      _showError('Detection failed: $e');
    }
  }

  // Run YOLO Detection
  Future<void> _runYOLODetection(String imagePath) async {
    // Load image
    final imageBytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    print('Image size: ${decodedImage.width}x${decodedImage.height}');

    // Step 1: Preprocess image
    final input = _preprocessImage(decodedImage);

    // Step 2: Run inference
    final output = _runInference(input);

    // Step 3: Process output
    final detections = _processOutput(
      output,
      decodedImage.width,
      decodedImage.height,
    );

    setState(() {
      _detections = detections;
    });

    print('Detections: ${detections.length}');
  }

  // Preprocess Image for YOLO
  Float32List _preprocessImage(img.Image image) {
    const int inputSize = 640; // YOLO input size

    // Resize image to 640x640
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Float32 and normalize to [0, 1]
    final inputData = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputData[pixelIndex++] = pixel.r / 255.0;
        inputData[pixelIndex++] = pixel.g / 255.0;
        inputData[pixelIndex++] = pixel.b / 255.0;
      }
    }

    // Return the flat Float32List; do not call reshape() which returns a List<dynamic>
    return inputData;
  }

  // Run YOLO Inference
  dynamic _runInference(Float32List input) {
    // Get output shape
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    print('📊 Output shape: $outputShape');

    // Create output buffer based on actual shape
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(input.reshape([1, 640, 640, 3]), {0: output});

    return output;
  }

  // Process YOLO Output
  List<Detection> _processOutput(
    dynamic output,
    int imageWidth,
    int imageHeight,
  ) {
    List<Detection> detections = [];

    print('🔍 Output type: ${output.runtimeType}');
    print('🔍 Output length: ${output.length}');

    // Handle different output formats
    List<List<double>> predictions;

    if (output is List<List<List<double>>>) {
      // Format: [1, N, 85] - Remove batch dimension
      predictions = output[0];
    } else if (output is List<List<double>>) {
      // Format: [N, 85] - Already flat
      predictions = output;
    } else {
      print('Unexpected output format: ${output.runtimeType}');
      return detections;
    }

    print('Predictions count: ${predictions.length}');
    if (predictions.isNotEmpty) {
      print('First prediction length: ${predictions[0].length}');
      print(
          'First prediction: ${predictions[0].take(10)}'); // Print first 10 values
    }

    const int inputSize = 640;

    for (int i = 0; i < predictions.length; i++) {
      final prediction = predictions[i];

      // Safety check
      if (prediction.length < 5) {
        continue;
      }

      // Determine YOLO format
      if (prediction.length >= 85) {
        // YOLOv5/v8 format: [x, y, w, h, conf, class1, class2, ...]
        final confidence = prediction[4];
        if (confidence < 0.25) continue; // Lower threshold for testing

        // Find best class (classes start at index 5)
        double maxClassProb = 0.0;
        int bestClassIndex = 0;

        for (int j = 5; j < prediction.length; j++) {
          if (prediction[j] > maxClassProb) {
            maxClassProb = prediction[j];
            bestClassIndex = j - 5;
          }
        }

        final finalConfidence = confidence * maxClassProb;
        if (finalConfidence < 0.3) continue; // Lower threshold for testing

        // Extract bounding box (already in pixel coordinates)
        final centerX = prediction[0];
        final centerY = prediction[1];
        final width = prediction[2];
        final height = prediction[3];

        // Convert to corner format and normalize
        final left = ((centerX - width / 2) / inputSize).clamp(0.0, 1.0);
        final top = ((centerY - height / 2) / inputSize).clamp(0.0, 1.0);
        final right = ((centerX + width / 2) / inputSize).clamp(0.0, 1.0);
        final bottom = ((centerY + height / 2) / inputSize).clamp(0.0, 1.0);

        final label = bestClassIndex < _labels.length
            ? _labels[bestClassIndex]
            : 'Class $bestClassIndex';

        detections.add(Detection(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          confidence: finalConfidence,
          label: label,
          classIndex: bestClassIndex,
        ));
      } else if (prediction.length >= 6) {
        // Minimal format: [x, y, w, h, conf, class]
        final confidence = prediction[4];
        if (confidence < 0.3) continue;

        final centerX = prediction[0];
        final centerY = prediction[1];
        final width = prediction[2];
        final height = prediction[3];
        final classIndex = prediction[5].toInt();

        final left = ((centerX - width / 2) / inputSize).clamp(0.0, 1.0);
        final top = ((centerY - height / 2) / inputSize).clamp(0.0, 1.0);
        final right = ((centerX + width / 2) / inputSize).clamp(0.0, 1.0);
        final bottom = ((centerY + height / 2) / inputSize).clamp(0.0, 1.0);

        final label = classIndex < _labels.length
            ? _labels[classIndex]
            : 'Class $classIndex';

        detections.add(Detection(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          confidence: confidence,
          label: label,
          classIndex: classIndex,
        ));
      }
    }

    print('Found ${detections.length} detections before NMS');

    // Apply Non-Maximum Suppression
    final result = _applyNMS(detections, 0.45);
    print('Final detections after NMS: ${result.length}');

    return result;
  }

  // Non-Maximum Suppression
  List<Detection> _applyNMS(List<Detection> detections, double iouThreshold) {
    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> results = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      results.add(detections[i]);

      // Suppress overlapping boxes
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIOU(detections[i], detections[j]);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return results;
  }

  // Calculate Intersection over Union
  double _calculateIOU(Detection a, Detection b) {
    final xLeft = [a.left, b.left].reduce((c, n) => c > n ? c : n);
    final yTop = [a.top, b.top].reduce((c, n) => c > n ? c : n);
    final xRight = [a.right, b.right].reduce((c, n) => c < n ? c : n);
    final yBottom = [a.bottom, b.bottom].reduce((c, n) => c < n ? c : n);

    if (xLeft >= xRight || yTop >= yBottom) return 0.0;

    final intersectionArea = (xRight - xLeft) * (yBottom - yTop);
    final areaA = (a.right - a.left) * (a.bottom - a.top);
    final areaB = (b.right - b.left) * (b.bottom - b.top);
    final unionArea = areaA + areaB - intersectionArea;

    return intersectionArea / unionArea;
  }

  // Reset to camera view
  void _resetCamera() {
    setState(() {
      _capturedImagePath = null;
      _detections.clear();
    });
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initializing Camera & AI...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview or Captured Image
          Positioned.fill(
            child: _capturedImagePath != null
                ? Image.file(
                    File(_capturedImagePath!),
                    fit: BoxFit.cover,
                  )
                : CameraPreview(_cameraController),
          ),

          // Detection Bounding Boxes
          ..._buildDetectionBoxes(),

          // Top Info Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOLO AI Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_detections.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_detections.length} detected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'AI is analyzing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button
                  if (_capturedImagePath != null)
                    FloatingActionButton(
                      heroTag: 'reset',
                      onPressed: _resetCamera,
                      backgroundColor: Colors.grey[800],
                      child: Icon(Icons.refresh, color: Colors.white),
                    ),

                  // Capture Button
                  FloatingActionButton(
                    heroTag: 'capture',
                    onPressed: _isProcessing ? null : _captureAndDetect,
                    backgroundColor: _isProcessing ? Colors.grey : Colors.blue,
                    child: _isProcessing
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.camera_alt, size: 32, color: Colors.white),
                  ),

                  // Info Button
                  FloatingActionButton(
                    heroTag: 'info',
                    onPressed: _showInfo,
                    backgroundColor: Colors.grey[800],
                    child: Icon(Icons.info_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Detection Bounding Boxes
  List<Widget> _buildDetectionBoxes() {
    if (_capturedImagePath == null || _detections.isEmpty) {
      return [];
    }

    return _detections.map((detection) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      return Positioned(
        left: detection.left * screenWidth,
        top: detection.top * screenHeight,
        child: Container(
          width: (detection.right - detection.left) * screenWidth,
          height: (detection.bottom - detection.top) * screenHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.green,
              width: 3,
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                '${detection.label} ${(detection.confidence * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Show Info Dialog
  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🤖 YOLO AI Camera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('1. Point camera at objects'),
            Text('2. Tap camera button to capture'),
            Text('3. AI will detect and label objects'),
            Text('4. Tap refresh to take another photo'),
            SizedBox(height: 15),
            Text('Model: ${_interpreter != null ? "Loaded" : "Not loaded"}'),
            Text('Labels: ${_labels.length} classes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _interpreter?.close();
    super.dispose();
  }
}

// Detection Class
class Detection {
  final double left, top, right, bottom;
  final double confidence;
  final String label;
  final int classIndex;

  Detection({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
    required this.label,
    required this.classIndex,
  });
}
