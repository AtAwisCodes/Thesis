import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class cameraFunc extends StatefulWidget {
  final CameraDescription camera;
  const cameraFunc({super.key, required this.camera});

  @override
  State<cameraFunc> createState() => _CameraFuncState();
}

class _CameraFuncState extends State<cameraFunc> {
  late CameraController controller;
  final ImagePicker _picker = ImagePicker();
  XFile? _galleryImage;

  @override
  void initState() {
    super.initState();
    controller = CameraController(widget.camera, ResolutionPreset.high);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final image = await controller.takePicture();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo captured: ${image.path}")),
      );
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _galleryImage = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (!controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: Colors.black,
              height: screenHeight * 0.1,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 50),

            // Camera Preview (Square, Centered)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CameraPreview(controller),
              ),
            ),

            // Spacer below the camera
            const SizedBox(height: 80),

            // Bottom Control Panel
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Text(
                      'PHOTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery icon
                        GestureDetector(
                          onTap: _pickFromGallery,
                          child: _galleryImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_galleryImage!.path),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white12,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(0.2),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: const Icon(Icons.image,
                                      size: 32, color: Colors.white),
                                ),
                        ),

                        // Capture button
                        GestureDetector(
                          onTap: _captureImage,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                        ),

                        const SizedBox(width: 50), // Spacer to balance layout
                      ],
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
