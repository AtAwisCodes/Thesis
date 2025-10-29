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

// Custom painter for bounding box overlay
class BoundingBoxPainter extends CustomPainter {
  final bool showBox;
  final String label;
  final double confidence;
  final Rect? boundingBox;

  BoundingBoxPainter({
    required this.showBox,
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showBox || boundingBox == null) return;

    // Use the provided bounding box
    final Rect rect = boundingBox!;

    // Draw semi-transparent filled rectangle
    final Paint fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(rect, borderPaint);

    // Draw corner accents (more stylish)
    final Paint accentPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;
    final double left = rect.left;
    final double top = rect.top;
    final double boxWidth = rect.width;
    final double boxHeight = rect.height;

    // Top-left corner
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLength, top), accentPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left, top + cornerLength), accentPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + boxWidth, top),
        Offset(left + boxWidth - cornerLength, top), accentPaint);
    canvas.drawLine(Offset(left + boxWidth, top),
        Offset(left + boxWidth, top + cornerLength), accentPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + boxHeight),
        Offset(left + cornerLength, top + boxHeight), accentPaint);
    canvas.drawLine(Offset(left, top + boxHeight),
        Offset(left, top + boxHeight - cornerLength), accentPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(left + boxWidth, top + boxHeight),
        Offset(left + boxWidth - cornerLength, top + boxHeight), accentPaint);
    canvas.drawLine(Offset(left + boxWidth, top + boxHeight),
        Offset(left + boxWidth, top + boxHeight - cornerLength), accentPaint);

    // Draw label background and text
    if (label.isNotEmpty) {
      final TextSpan span = TextSpan(
        text: '$label ${(confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      final TextPainter textPainter = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background for text
      final double textWidth = textPainter.width + 16;
      final double textHeight = textPainter.height + 8;
      final Rect textBg = Rect.fromLTWH(
        left,
        top - textHeight - 4,
        textWidth,
        textHeight,
      );

      final Paint textBgPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(textBg, const Radius.circular(4)),
        textBgPaint,
      );

      // Draw text
      textPainter.paint(canvas, Offset(left + 8, top - textHeight));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.showBox != showBox ||
        oldDelegate.label != label ||
        oldDelegate.confidence != confidence ||
        oldDelegate.boundingBox != boundingBox;
  }
}

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

  // Video service for suggestions
  final VideoUploadService _videoService = VideoUploadService();

  // Mirror Java labels
  static const List<String> _labels = <String>[
    'PlasticBottles',
    'Cardboard',
    'Glass',
    'AluminumCans',
    'Clothes',
  ];

  String _predictionText = 'Loading model...';
  int _modelInputHeight = 0;
  int _modelInputWidth = 0;
  int _modelInputChannels = 0;
  tfl.TensorType? _inputType;
  tfl.TensorType? _outputType;

  // Frame throttle - reduced for better performance
  int _lastInferenceMs = 0;
  static const int _minIntervalMs =
      400; // Increased to 2.5 FPS for better performance

  // Adaptive scanning - only scan grid when needed
  int _frameCounter = 0;
  static const int _fullScanInterval = 3; // Do full grid scan every 3rd frame

  // Bounding box state
  bool _showBoundingBox = false;
  String _detectedLabel = '';
  double _confidence = 0.0;
  Rect? _boundingBox;

  // Smoothing for bounding box movement
  Rect? _previousBoundingBox;
  static const double _smoothingFactor =
      0.5; // Increased for better performance and smoother motion

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
        _predictionText = 'Point camera at an item';
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

    // Dispose current controller
    await _controller?.dispose();

    final CameraDescription selected = _cameras[_selectedCameraIndex];
    final CameraController controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();
    await controller.startImageStream(_onFrame);

    setState(() {
      _controller = controller;
    });
  }

  void _toggleCamera() {
    if (_cameras.length <= 1) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    unawaited(_switchCamera());
  }

  void _onFrame(CameraImage image) {
    final tfl.Interpreter? interpreter = _interpreter;
    if (interpreter == null) return;

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInferenceMs < _minIntervalMs) return;
    _lastInferenceMs = now;

    // Convert and run on a microtask to keep stream smooth
    scheduleMicrotask(() {
      try {
        final Uint8List rgb = _convertYUV420toRGB(image);

        _frameCounter++;

        // Adaptive strategy: Alternate between full scan and center-only detection
        Map<String, dynamic> result;

        if (_frameCounter % _fullScanInterval == 0) {
          // Every 3rd frame: Do a quick 2x2 grid scan (4 regions instead of 9)
          result = _findObjectLocationOptimized(
              rgb, image.width, image.height, interpreter);
        } else {
          // Other frames: Just check center region for better performance
          result =
              _checkCenterRegion(rgb, image.width, image.height, interpreter);
        }

        _updatePredictionWithLocation(
          result['probs'] as List<double>,
          result['boundingBox'] as Rect?,
        );
      } catch (e) {
        print('Frame processing error: $e');
      }
    });
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

  // Optimized: Quick center region check (single inference)
  Map<String, dynamic> _checkCenterRegion(
    Uint8List rgb,
    int width,
    int height,
    tfl.Interpreter interpreter,
  ) {
    // Just check the center region with previous bounding box or default center
    final Uint8List resized = _resizeRgbSimple(
      rgb,
      width,
      height,
      _modelInputWidth,
      _modelInputHeight,
    );

    final Object inputBuffer = _buildInput(resized);
    final List<double> probs = _runInference(interpreter, inputBuffer);

    // Use previous bounding box or default center
    Rect? boundingBox =
        _previousBoundingBox ?? const Rect.fromLTRB(0.25, 0.3, 0.75, 0.7);

    return {
      'probs': probs,
      'boundingBox': boundingBox,
    };
  }

  // Optimized: 2x2 grid scan (4 regions instead of 9)
  Map<String, dynamic> _findObjectLocationOptimized(
    Uint8List rgb,
    int width,
    int height,
    tfl.Interpreter interpreter,
  ) {
    // Use 2x2 grid for faster scanning
    const int gridRows = 2;
    const int gridCols = 2;

    double bestConfidence = 0.0;
    int bestRow = 0;
    int bestCol = 0;
    List<double> bestProbs = List<double>.filled(_labels.length, 0.0);

    // Scan each grid cell
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        // Extract region
        final Uint8List region =
            _extractRegion(rgb, width, height, row, col, gridRows, gridCols);

        // Resize and run inference
        final Uint8List resized = _resizeRgbSimple(
          region,
          width ~/ gridCols,
          height ~/ gridRows,
          _modelInputWidth,
          _modelInputHeight,
        );

        final Object inputBuffer = _buildInput(resized);
        final List<double> probs = _runInference(interpreter, inputBuffer);

        // Find max confidence in this region
        for (int i = 0; i < probs.length; i++) {
          if (probs[i] > bestConfidence) {
            bestConfidence = probs[i];
            bestRow = row;
            bestCol = col;
            bestProbs = probs;
          }
        }
      }
    }

    // Calculate bounding box in normalized coordinates
    Rect? boundingBox;
    const double threshold = 0.6;

    if (bestConfidence > threshold) {
      // Map grid position to screen coordinates
      final double cellWidth = 1.0 / gridCols;
      final double cellHeight = 1.0 / gridRows;

      // Add padding
      const double padding = 0.08;

      boundingBox = Rect.fromLTRB(
        (bestCol * cellWidth - padding).clamp(0.0, 1.0),
        (bestRow * cellHeight - padding).clamp(0.0, 1.0),
        ((bestCol + 1) * cellWidth + padding).clamp(0.0, 1.0),
        ((bestRow + 1) * cellHeight + padding).clamp(0.0, 1.0),
      );
    }

    return {
      'probs': bestProbs,
      'boundingBox': boundingBox,
    };
  }

  // Original 3x3 grid scan - kept for reference but not used
  // ignore: unused_element
  Map<String, dynamic> _findObjectLocation(
    Uint8List rgb,
    int width,
    int height,
    tfl.Interpreter interpreter,
  ) {
    // Define grid for scanning (3x3 grid for better tracking)
    const int gridRows = 3;
    const int gridCols = 3;

    double bestConfidence = 0.0;
    int bestRow = 1;
    int bestCol = 1;
    List<double> bestProbs = List<double>.filled(_labels.length, 0.0);

    // Scan each grid cell
    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        // Extract region
        final Uint8List region =
            _extractRegion(rgb, width, height, row, col, gridRows, gridCols);

        // Resize and run inference
        final Uint8List resized = _resizeRgbSimple(
          region,
          width ~/ gridCols,
          height ~/ gridRows,
          _modelInputWidth,
          _modelInputHeight,
        );

        final Object inputBuffer = _buildInput(resized);
        final List<double> probs = _runInference(interpreter, inputBuffer);

        // Find max confidence in this region
        for (int i = 0; i < probs.length; i++) {
          if (probs[i] > bestConfidence) {
            bestConfidence = probs[i];
            bestRow = row;
            bestCol = col;
            bestProbs = probs;
          }
        }
      }
    }

    // Calculate bounding box in normalized coordinates
    Rect? boundingBox;
    const double threshold = 0.6;

    if (bestConfidence > threshold) {
      // Map grid position to screen coordinates
      final double cellWidth = 1.0 / gridCols;
      final double cellHeight = 1.0 / gridRows;

      // Add some padding around the detected cell
      const double padding = 0.05;

      boundingBox = Rect.fromLTRB(
        (bestCol * cellWidth - padding).clamp(0.0, 1.0),
        (bestRow * cellHeight - padding).clamp(0.0, 1.0),
        ((bestCol + 1) * cellWidth + padding).clamp(0.0, 1.0),
        ((bestRow + 1) * cellHeight + padding).clamp(0.0, 1.0),
      );
    }

    return {
      'probs': bestProbs,
      'boundingBox': boundingBox,
    };
  }

  // Extract a region from the RGB image
  Uint8List _extractRegion(
    Uint8List rgb,
    int width,
    int height,
    int row,
    int col,
    int gridRows,
    int gridCols,
  ) {
    final int regionWidth = width ~/ gridCols;
    final int regionHeight = height ~/ gridRows;
    final int startX = col * regionWidth;
    final int startY = row * regionHeight;

    final Uint8List region = Uint8List(regionWidth * regionHeight * 3);
    int idx = 0;

    for (int y = 0; y < regionHeight; y++) {
      for (int x = 0; x < regionWidth; x++) {
        final int srcX = startX + x;
        final int srcY = startY + y;
        if (srcX < width && srcY < height) {
          final int srcIdx = (srcY * width + srcX) * 3;
          region[idx++] = rgb[srcIdx];
          region[idx++] = rgb[srcIdx + 1];
          region[idx++] = rgb[srcIdx + 2];
        } else {
          idx += 3;
        }
      }
    }

    return region;
  }

  /* Old comment block removed - methods are now active above */

  // Simplified resize without rotation
  Uint8List _resizeRgbSimple(
      Uint8List src, int srcW, int srcH, int dstW, int dstH) {
    final Uint8List out = Uint8List(dstW * dstH * 3);
    for (int y = 0; y < dstH; y++) {
      final int sy = (y * srcH / dstH).floor();
      for (int x = 0; x < dstW; x++) {
        final int sx = (x * srcW / dstW).floor();
        final int srcIdx = (sy * srcW + sx) * 3;
        final int dstIdx = (y * dstW + x) * 3;
        if (srcIdx + 2 < src.length) {
          out[dstIdx] = src[srcIdx];
          out[dstIdx + 1] = src[srcIdx + 1];
          out[dstIdx + 2] = src[srcIdx + 2];
        }
      }
    }
    return out;
  }

  void _updatePredictionWithLocation(List<double> probs, Rect? normalizedBox) {
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
        : 'Uncertain...';

    // Apply smoothing to bounding box for smoother transitions
    Rect? smoothedBox;
    if (normalizedBox != null && _previousBoundingBox != null) {
      // Interpolate between previous and current box
      smoothedBox =
          Rect.lerp(_previousBoundingBox!, normalizedBox, _smoothingFactor);
    } else {
      smoothedBox = normalizedBox;
    }

    if (mounted) {
      setState(() {
        _predictionText = text;
        _showBoundingBox = maxVal > threshold && smoothedBox != null;
        _detectedLabel = maxVal > threshold ? _labels[maxIdx] : '';
        _confidence = maxVal;
        _boundingBox = smoothedBox;
        _previousBoundingBox = smoothedBox;
      });
    }
  }

  // Convert CameraImage in YUV420 to RGB bytes (R,G,B order)
  Uint8List _convertYUV420toRGB(CameraImage image) {
    // Based on standard YUV420SP to RGB conversion
    final int width = image.width;
    final int height = image.height;
    final Uint8List y = image.planes[0].bytes;
    final Uint8List u = image.planes[1].bytes;
    final Uint8List v = image.planes[2].bytes;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

    final Uint8List rgb = Uint8List(width * height * 3);
    int rgbIndex = 0;

    for (int yRow = 0; yRow < height; yRow++) {
      final int uvRow = (yRow ~/ 2) * uvRowStride;
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvRow + (x ~/ 2) * uvPixelStride;
        final int yp = y[yRow * image.planes[0].bytesPerRow + x];
        final int up = u[uvIndex];
        final int vp = v[uvIndex];

        // YUV to RGB conversion
        final double yy = yp.toDouble();
        final double uu = up.toDouble() - 128.0;
        final double vv = vp.toDouble() - 128.0;

        double r = yy + 1.402 * vv;
        double g = yy - 0.344136 * uu - 0.714136 * vv;
        double b = yy + 1.772 * uu;

        r = r.clamp(0.0, 255.0);
        g = g.clamp(0.0, 255.0);
        b = b.clamp(0.0, 255.0);

        rgb[rgbIndex++] = r.toInt();
        rgb[rgbIndex++] = g.toInt();
        rgb[rgbIndex++] = b.toInt();
      }
    }
    return rgb;
  }

  // Nearest-neighbor resize for RGB planar bytes (RGBRGB...)
  // ignore: unused_element
  Uint8List _resizeRgb(Uint8List src, int srcW, int srcH, int dstW, int dstH) {
    // This method is kept for potential future use with full-frame analysis
    final Uint8List out = Uint8List(dstW * dstH * 3);
    for (int y = 0; y < dstH; y++) {
      final int sy = (y * srcH / dstH).floor();
      for (int x = 0; x < dstW; x++) {
        final int sx = (x * srcW / dstW).floor();
        final int srcIdx = (sy * srcW + sx) * 3;
        final int dstIdx = (y * dstW + x) * 3;
        out[dstIdx] = src[srcIdx];
        out[dstIdx + 1] = src[srcIdx + 1];
        out[dstIdx + 2] = src[srcIdx + 2];
      }
    }
    // Rotate 270 degrees to mimic Java rotation for front-camera if needed
    return _rotateRgb270(out, dstW, dstH);
  }

  // Rotate RGB buffer 270 degrees (width x height)
  Uint8List _rotateRgb270(Uint8List src, int width, int height) {
    final int newW = height;
    final int newH = width;
    final Uint8List out = Uint8List(newW * newH * 3);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int srcIdx = (y * width + x) * 3;
        final int rx = y; // rotated x
        final int ry = newH - 1 - x; // rotated y
        final int dstIdx = (ry * newW + rx) * 3;
        out[dstIdx] = src[srcIdx];
        out[dstIdx + 1] = src[srcIdx + 1];
        out[dstIdx + 2] = src[srcIdx + 2];
      }
    }
    return out;
  }

  @override
  void dispose() {
    _controller?.dispose();
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
                      ? const Center(child: CircularProgressIndicator())
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
                  // Bounding box overlay
                  if (controller != null && controller.value.isInitialized)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Convert normalized bounding box to screen coordinates
                          Rect? screenBox;
                          if (_boundingBox != null) {
                            final double width = constraints.maxWidth;
                            final double height = constraints.maxHeight;
                            screenBox = Rect.fromLTRB(
                              _boundingBox!.left * width,
                              _boundingBox!.top * height,
                              _boundingBox!.right * width,
                              _boundingBox!.bottom * height,
                            );
                          }

                          return CustomPaint(
                            painter: BoundingBoxPainter(
                              showBox: _showBoundingBox,
                              label: _detectedLabel,
                              confidence: _confidence,
                              boundingBox: screenBox,
                            ),
                          );
                        },
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
                              final searchTerm = _detectedLabel.isNotEmpty
                                  ? _detectedLabel.toLowerCase()
                                  : '';

                              // Filter videos by detected object
                              final filteredUploaded =
                                  uploadedVideos.where((video) {
                                final title = (video['title'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final description = (video['description'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return searchTerm.isEmpty ||
                                    title.contains(searchTerm) ||
                                    description.contains(searchTerm) ||
                                    title.contains('recycle') ||
                                    title.contains('plastic') ||
                                    title.contains('cardboard') ||
                                    title.contains('glass') ||
                                    title.contains('aluminum') ||
                                    title.contains('clothes');
                              }).toList();

                              final filteredYt =
                                  ytViewModel.playlistItems.where((yt) {
                                final title = yt.videoTitle.toLowerCase();
                                return searchTerm.isEmpty ||
                                    title.contains(searchTerm) ||
                                    title.contains('recycle') ||
                                    title.contains('plastic') ||
                                    title.contains('cardboard') ||
                                    title.contains('glass') ||
                                    title.contains('aluminum') ||
                                    title.contains('clothes');
                              }).toList();

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
