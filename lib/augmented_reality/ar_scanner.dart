/// ⚠️ DEPRECATED - USE ar_scanner_page.dart INSTEAD
/// 
/// This file is kept for reference only.
/// The new integrated AR Scanner is located at:
/// lib/augmented_reality/ar_scanner_page.dart
/// 
/// Access from app: Home → Menu → AR Scanner

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ARImageScannerApp());
}

class ARImageScannerApp extends StatelessWidget {
  const ARImageScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Image Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ARScannerPage(),
    );
  }
}

class ARScannerPage extends StatefulWidget {
  const ARScannerPage({super.key});

  @override
  State<ARScannerPage> createState() => _ARScannerPageState();
}

class _ARScannerPageState extends State<ARScannerPage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isScanning = false;
  List<ScannedObject> _scannedObjects = [];
  ScannedObject? _selectedObject;
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
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
      if (cameras.isEmpty) return;
      
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
          
          // Scanning overlay
          if (_isScanning) _buildScanningOverlay(),
          
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
                  'This app needs camera access to scan objects in AR.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return SizedBox.expand(
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

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Scanning frame
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
                    
                    // Scanning line
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 300 * _scanAnimationController.value,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.cyan,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scan instruction
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3 - 80,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                ),
                child: const Text(
                  'Point camera at object to scan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
            bottom: alignment.y > 0 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
            left: alignment.x < 0 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
            right: alignment.x > 0 ? BorderSide(color: Colors.cyan, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScannedObject(ScannedObject obj) {
    final isSelected = _selectedObject?.id == obj.id;
    
    return Positioned(
      left: obj.position.dx - (obj.size * obj.scale / 2),
      top: obj.position.dy - (obj.size * obj.scale / 2),
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
                width: obj.size * obj.scale,
                height: obj.size * obj.scale,
                decoration: BoxDecoration(
                  color: obj.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.yellow : Colors.cyan,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? Colors.yellow : Colors.cyan).withOpacity(0.5),
                      blurRadius: isSelected ? 15 : 10,
                      spreadRadius: isSelected ? 3 : 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
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
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _isScanning ? Icons.qr_code_scanner : Icons.camera_alt,
                  color: _isScanning ? Colors.cyan : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isScanning 
                      ? 'Scanning...' 
                      : 'Objects: ${_scannedObjects.length}',
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
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isScanning && _scannedObjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Tap "Scan Object" to detect items',
                      style: TextStyle(
                        color: Colors.cyan.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isScanning ? Icons.stop : Icons.qr_code_scanner,
                      label: _isScanning ? 'Stop' : 'Scan Object',
                      color: _isScanning ? Colors.red : Colors.cyan,
                      onPressed: _toggleScanning,
                    ),
                    if (_scannedObjects.isNotEmpty) ...[
                      _buildControlButton(
                        icon: Icons.delete_sweep,
                        label: 'Clear All',
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      bottom: 120,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.yellow.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editing: ${_selectedObject!.name}',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                          position: Offset(obj.position.dx + 20, obj.position.dy + 20),
                          size: obj.size,
                          scale: obj.scale,
                          rotation: obj.rotation,
                          color: obj.color,
                          icon: obj.icon,
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
          Icon(icon, color: Colors.cyan, size: 20),
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
              activeColor: Colors.cyan,
              inactiveColor: Colors.cyan.withOpacity(0.3),
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

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
    
    if (_isScanning) {
      _showMessage('Scanning for objects...');
      // Simulate object detection after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_isScanning) {
          _simulateObjectDetection();
        }
      });
    } else {
      _showMessage('Scanning stopped');
    }
  }

  void _simulateObjectDetection() {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random();
    
    final objects = [
      {'name': 'Bottle', 'icon': Icons.local_drink, 'color': Colors.blue},
      {'name': 'Cup', 'icon': Icons.coffee, 'color': Colors.brown},
      {'name': 'Phone', 'icon': Icons.phone_android, 'color': Colors.grey},
      {'name': 'Book', 'icon': Icons.book, 'color': Colors.orange},
      {'name': 'Watch', 'icon': Icons.watch, 'color': Colors.black},
      {'name': 'Box', 'icon': Icons.inventory_2, 'color': Colors.amber},
    ];
    
    final randomObject = objects[random.nextInt(objects.length)];
    
    setState(() {
      _scannedObjects.add(ScannedObject(
        id: DateTime.now().millisecondsSinceEpoch,
        name: randomObject['name'] as String,
        position: Offset(
          screenSize.width / 2 + (random.nextDouble() - 0.5) * 100,
          screenSize.height / 2 + (random.nextDouble() - 0.5) * 100,
        ),
        size: 120,
        scale: 1.0,
        rotation: 0,
        color: randomObject['color'] as Color,
        icon: randomObject['icon'] as IconData,
      ));
      _isScanning = false;
    });
    
    _showMessage('${randomObject['name']} detected!');
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
        backgroundColor: Colors.cyan.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

class ScannedObject {
  final int id;
  String name;
  Offset position;
  double size;
  double scale;
  double rotation;
  Color color;
  IconData icon;

  ScannedObject({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    required this.scale,
    required this.rotation,
    required this.color,
    required this.icon,
  });
}
