import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Object Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CameraScreen(cameras: cameras),
      routes: {
        '/Plastic': (context) => const ObjectDetailPage(objectName: 'Bottle'),
        '/Glass': (context) => const ObjectDetailPage(objectName: 'Cup'),
        '/Cardboard': (context) => const ObjectDetailPage(objectName: 'Phone'),
        '/Cloth': (context) => const ObjectDetailPage(objectName: 'Laptop'),
      },
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  Interpreter? _interpreter;
  List<String>? _labels;
  String _detectedObject = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadModel() async {
    try {
      // Load your YOLO model (you need to add your .tflite model to assets)
      _interpreter = await Interpreter.fromAsset('assets/my_model.tflite');

      // Load labels (you need to add your labels.txt to assets)
      _labels = await DefaultAssetBundle.of(context)
          .loadString('assets/labels.txt')
          .then((s) => s.split('\n'));

      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _takePictureAndDetect() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isDetecting) {
      return;
    }

    setState(() {
      _isDetecting = true;
    });

    try {
      final image = await _controller!.takePicture();

      // Process image and run detection
      final detectedObject = await _runObjectDetection(image.path);

      if (detectedObject != null && mounted) {
        // Navigate to appropriate page based on detected object
        _navigateToObjectPage(detectedObject);
      } else {
        _showMessage('No object detected or confidence too low');
      }
    } catch (e) {
      print('Error during detection: $e');
      _showMessage('Detection failed');
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  Future<String?> _runObjectDetection(String imagePath) async {
    if (_interpreter == null) {
      return null;
    }

    try {
      // Load and preprocess image
      final imageData = await _preprocessImage(imagePath);

      // Run inference
      var output = List.filled(1 * 25200 * 85, 0.0).reshape([1, 25200, 85]);
      _interpreter!.run(imageData, output);

      // Process output and get detected object
      final detectedObject = _processOutput(output);
      return detectedObject;
    } catch (e) {
      print('Error running detection: $e');
      return null;
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
      String imagePath) async {
    // This is a simplified preprocessing
    // You'll need to adjust based on your YOLO model's requirements
    final imageBytes = await img.decodeImageFile(imagePath);
    if (imageBytes == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(imageBytes, width: 640, height: 640);

    var input = List.generate(
      1,
      (_) => List.generate(
        640,
        (y) => List.generate(
          640,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  String? _processOutput(List output) {
    // This is a simplified output processing
    // You'll need to implement proper YOLO post-processing
    // including NMS (Non-Maximum Suppression) and confidence thresholding

    double maxConfidence = 0.0;
    int maxClassIndex = -1;

    for (var i = 0; i < output[0].length; i++) {
      final detection = output[0][i];
      final objectness = detection[4];

      if (objectness > 0.5) {
        for (var j = 5; j < detection.length; j++) {
          final classConfidence = objectness * detection[j];
          if (classConfidence > maxConfidence) {
            maxConfidence = classConfidence;
            maxClassIndex = j - 5;
          }
        }
      }
    }

    if (maxConfidence > 0.6 &&
        maxClassIndex >= 0 &&
        maxClassIndex < _labels!.length) {
      return _labels![maxClassIndex].trim();
    }

    return null;
  }

  void _navigateToObjectPage(String objectName) {
    // Map object names to routes
    final routeMap = {
      'Plastic': '/Plastic',
      'Glass': '/Glass',
      'Cardboard': '/Cardboard',
      'Cloth': '/Cloth',
    };

    final route = routeMap[objectName.toLowerCase()];

    if (route != null) {
      Navigator.pushNamed(context, route);
    } else {
      _showMessage('Detected: $objectName (no specific page)');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('YOLO Object Detection')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          if (_detectedObject.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Detected: $_detectedObject',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isDetecting ? null : _takePictureAndDetect,
              icon: _isDetecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera),
              label:
                  Text(_isDetecting ? 'Detecting...' : 'Take Picture & Detect'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ObjectDetailPage extends StatelessWidget {
  final String objectName;

  const ObjectDetailPage({Key? key, required this.objectName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(objectName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForObject(objectName),
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'You detected a $objectName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'This is the detail page for $objectName',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Camera'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForObject(String object) {
    switch (object.toLowerCase()) {
      case 'plastic':
        return Icons.local_drink;
      case 'glass':
        return Icons.coffee;
      case 'cardboard':
        return Icons.phone_android;
      case 'cloth':
        return Icons.laptop;
      default:
        return Icons.category;
    }
  }
}

/// Helper to match existing call sites that expect a `cameraFunc` symbol.
/// Pages call `cameraFunc(camera: cameras[0])`, so we provide a small
/// wrapper that creates a `CameraScreen` from a single CameraDescription.
Widget cameraFunc({required CameraDescription camera}) {
  return CameraScreen(cameras: [camera]);
}
