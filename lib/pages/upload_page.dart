import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rexplore/utilities/uploadSelection.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPage();
}

class _UploadPage extends State<UploadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const CustomDialogWidget(),
            );
          },
          child: const Text("Upload Video"),
        ),
      ),
    );
  }
}

class CustomDialogWidget extends StatefulWidget {
  const CustomDialogWidget({super.key});

  @override
  State<CustomDialogWidget> createState() => _CustomDialogWidgetState();
}

class _CustomDialogWidgetState extends State<CustomDialogWidget> {
  String? _videoPath;
  VideoPlayerController? _videoController;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  final VideoUploadService _uploadService = VideoUploadService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('count').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  //Image picker with limit validation
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) return;

      final totalCount = _selectedImages.length + images.length;
      if (totalCount > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You can only upload up to 4 images."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(images);
      });
    } catch (e) {
      _showError("Error picking images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.06,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              )
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Video",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),

                //Video Selection Area
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: screenHeight * 0.25,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _videoController != null &&
                          _videoController!.value.isInitialized
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                });
                                _resetControlsTimer();
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AspectRatio(
                                        aspectRatio:
                                            _videoController!.value.aspectRatio,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      opacity: _showControls ? 1.0 : 0.0,
                                      child: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.8),
                                        size: constraints.maxHeight * 0.4,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: _isUploading ? null : _pickVideo,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.video_collection_outlined,
                                          color: _isUploading
                                              ? theme.colorScheme.onSurface
                                                  .withOpacity(0.3)
                                              : theme.colorScheme.primary,
                                          size: constraints.maxHeight * 0.15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : OutlinedButton(
                          onPressed: _isUploading ? null : _pickVideo,
                          child: const Text("Select Video from File"),
                        ),
                ),

                SizedBox(height: screenHeight * 0.03),

                //Upload Progress Section
                if (_isUploading) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor:
                              theme.colorScheme.onSurface.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _uploadStatus,
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],

                //User Info + Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Details",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          _userData != null && _userData!['avatar_url'] != null
                              ? NetworkImage(_userData!['avatar_url'])
                              : const AssetImage('assets/avatar.png')
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _userData != null
                          ? "${_userData!['first_name'] ?? ''} ${_userData!['last_name'] ?? ''}"
                          : "Username",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.015),

                // Title input
                TextField(
                  controller: _titleController,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                // Description input
                TextField(
                  controller: _descriptionController,
                  enabled: !_isUploading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Details (ex. height, width, etc.)",
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                //Model Images Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Model",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isUploading ? null : _pickImages,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Formats: .png, .jpg, .jpeg, .webp (3–4 images, 20MB Max)",
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.add_photo_alternate,
                          color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                //Image Thumbnails
                if (_selectedImages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages.map((image) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(image.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.remove(image);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                SizedBox(height: screenHeight * 0.03),

                //Upload + Cancel Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: OutlinedButton(
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadVideo,
                        child: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                "Upload",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Video helper functions
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 1),
        () => setState(() => _showControls = false));
  }

  void _resetControlsTimer() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _pickVideo() async {
    try {
      _videoPath = await pickVideo();
      if (_videoPath != null) _initializeVideoPlayer();
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  void _initializeVideoPlayer() {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(_videoPath!))
      ..initialize().then((_) {
        setState(() {});
        _videoController!
          ..setLooping(true)
          ..play();
        _startHideControlsTimer();
      }).catchError((error) {
        _showError('Failed to initialize video player: $error');
      });
  }

  Future<void> _uploadVideo() async {
    if (_videoPath == null || _titleController.text.trim().isEmpty) {
      _showError("Please select a video and enter a title");
      return;
    }

    if (_selectedImages.length < 3) {
      _showError("Please select at least 3 images before uploading.");
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      //Step 1: Upload model images first
      final imageFiles = _selectedImages.map((x) => File(x.path)).toList();
      final imageUrls = await _uploadService.uploadModelImages(
        imageFiles: imageFiles,
        userId: userId,
        onProgress: (progress, status) {
          setState(() {
            _uploadProgress = progress * 0.4; // first 40% for images
            _uploadStatus = status;
          });
        },
      );

      //Step 2: Upload video next
      final result = await _uploadService.uploadVideoWithProgress(
        videoPath: _videoPath!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        modelImages: null,
        onProgress: (progress, status) {
          setState(() {
            _uploadProgress = 0.4 + (progress * 0.6);
            _uploadStatus = status;
          });
        },
      );

      //Step 3: If video upload succeeded, attach image metadata to Firestore
      if (result.success) {
        await FirebaseFirestore.instance
            .collection('videos')
            .doc(result.videoId)
            .update({'modelImages': imageUrls});

        _showSuccess("Upload successful!");
        Navigator.of(context).pop();
      } else {
        _showError(result.error ?? "Upload failed");
      }
    } catch (e) {
      _showError("Upload failed: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  // Snackbar Helpers
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
