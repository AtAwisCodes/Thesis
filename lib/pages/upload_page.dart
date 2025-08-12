import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rexplore/utilities/uploadSelection.dart';
import 'package:video_player/video_player.dart';
import 'package:rexplore/firebase_service.dart';

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
            showDialog(
              context: context,
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
  String? _downloadUrl;
  Timer? _hideControlsTimer;
  bool _showControls = true;

  @override
  void dispose() {
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          minWidth: screenWidth * 0.8,
        ),
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.02,
          horizontal: screenWidth * 0.06,
        ),
        decoration: BoxDecoration(
          color: const Color(0xff2A303E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    "Video",
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),

              // Video selection area
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(5),
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
                                // Video
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: AspectRatio(
                                      aspectRatio:
                                          _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  ),
                                ),
                                // Play/Pause Icon with Fade
                                Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: _showControls ? 1.0 : 0.0,
                                    child: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: Colors.white70,
                                      size: constraints.maxHeight * 0.4,
                                    ),
                                  ),
                                ),
                                // Change video button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () {
                                      _pickVideo();
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.change_circle,
                                        color: Colors.white,
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
                        onPressed: _pickVideo,
                        child: const Text("Select Video from File"),
                      ),
              ),

              SizedBox(height: screenHeight * 0.03),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    "Details",
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.015),

              // Title
              TextField(
                decoration: InputDecoration(
                  hintText: "Title (required)",
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: const OutlineInputBorder(),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Description
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Description",
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Tags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.06,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Flexible(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5BEC84),
                        foregroundColor: const Color(0xff2A303E),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.06,
                        ),
                      ),
                      onPressed: () {
                        _uploadVideo();
                      },
                      child: const Text(
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
      ),
    );
  }

//Play button fade transition logic
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  void _resetControlsTimer() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  //upload video logic
  void _pickVideo() async {
    _videoPath = await pickVideo();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.file(File(_videoPath!))
      ..initialize().then((_) {
        setState(() {});
        _videoController!
          ..setLooping(true)
          ..play();
        _startHideControlsTimer();
      });
  }

//video preview widget
  Widget _buildVideoPlayer() {
    if (_videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return const CircularProgressIndicator();
    }
  }

  // Upload video logic
  void _uploadVideo() async {
    _downloadUrl = await FirebaseService().uploadVideo(_videoPath!);
    await FirebaseService().saveVideoToUser(_downloadUrl!);
    setState(() {
      _videoPath = null;
    });
  }
}
