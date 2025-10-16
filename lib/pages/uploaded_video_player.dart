import 'package:flutter/material.dart';
import 'package:rexplore/components/fullscreen_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/augmented_reality/augmented_camera.dart';
import 'package:rexplore/services/upload_function.dart';

class UploadedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId; // Added videoId to pass to AR camera
  final String title;
  final String uploadedAt;
  final String avatarUrl;
  final String firstName;
  final String lastName;

  const UploadedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId, // Make sure videoId is passed
    required this.title,
    required this.uploadedAt,
    required this.avatarUrl,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<UploadedVideoPlayer> createState() => _UploadedVideoPlayerState();
}

class _UploadedVideoPlayerState extends State<UploadedVideoPlayer> {
  late VideoPlayerController _controller;
  final List<String> comments = [];
  final _commentController = TextEditingController();
  final VideoUploadService _uploadService = VideoUploadService();

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool _has3DModel = false;
  bool _isCheckingModel = true;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });

    // Load initial liked state
    isLiked = FavoritesManager.instance.contains(widget.videoUrl);

    // Check 3D model status
    _check3DModelStatus();
  }

  Future<void> _check3DModelStatus() async {
    try {
      final status = await _uploadService.getModelStatus(widget.videoId);

      if (mounted) {
        setState(() {
          _has3DModel = status['has3DModel'] ?? false;
          _modelError = status['modelGenerationError'];
          _isCheckingModel = false;
        });

        // Show success notification if model is ready
        if (_has3DModel && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('3D Model Ready! Tap "View in AR" to explore'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingModel = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ✅ Updated to use Meshy AR Camera with videoId
  Future<void> _openARCamera() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeshyARCamera(
            videoId: widget.videoId, // Pass the video ID to AR camera
          ),
        ),
      );
    }
  }

  void _enterFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(controller: _controller),
      ),
    );
  }

  Future<void> _toggleLikeAndFavorite() async {
    final videoData = {
      "id": widget.videoUrl,
      "title": widget.title,
      "url": widget.videoUrl,
      "uploadedAt": widget.uploadedAt,
    };

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        isDisliked = false; // clear dislike
        FavoritesManager.instance.addFavorite(videoData);
      } else {
        FavoritesManager.instance.removeFavorite(widget.videoUrl);
      }
    });
  }

  // Open comments modal
  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController _dialogCommentController =
            TextEditingController();

        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  final textColor =
                      Theme.of(context).textTheme.bodyMedium?.color;

                  return Column(
                    children: [
                      // drag handle
                      Container(
                        height: 5,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: textColor?.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      Row(
                        children: [
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.comment_rounded,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // comments list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .iconTheme
                                    .color
                                    ?.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                              ),
                              title: Text(
                                "user${index + 1}",
                                style: TextStyle(color: textColor),
                              ),
                              subtitle: Text(
                                comments[index],
                                style: TextStyle(color: textColor),
                              ),
                            );
                          },
                        ),
                      ),

                      // input
                      SafeArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border(
                              top: BorderSide(
                                color: textColor!.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dialogCommentController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Write a comment...",
                                    hintStyle: TextStyle(
                                        color: textColor.withOpacity(0.6)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: textColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.black54),
                                onPressed: () {
                                  if (_dialogCommentController
                                      .text.isNotEmpty) {
                                    setState(() {
                                      comments.insert(
                                          0, _dialogCommentController.text);
                                    });
                                    setModalState(() {});
                                    _dialogCommentController.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploaderName = "${widget.firstName} ${widget.lastName}".trim();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            SizedBox(
              height: 280,
              width: double.infinity,
              child: _controller.value.isInitialized
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.all(8.0),
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen,
                                color: Colors.blueGrey),
                            onPressed: _enterFullscreen,
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Uploader Avatar + Name + Actions
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Uploader info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.avatarUrl.isNotEmpty
                            ? NetworkImage(widget.avatarUrl)
                            : null,
                        child: widget.avatarUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        uploaderName.isNotEmpty ? uploaderName : "Anonymous",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Like / Dislike / Follow
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.green : Colors.grey,
                        ),
                        onPressed: _toggleLikeAndFavorite,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: isDisliked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isDisliked = !isDisliked;
                            if (isDisliked) isLiked = false;
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isFollowed = !isFollowed;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowed
                                ? Colors.grey
                                : const Color(0xff5BEC84),
                            padding: EdgeInsets.zero,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isFollowed ? "Followed" : "Follow",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isFollowed ? Colors.white70 : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // comments trigger
            GestureDetector(
              onTap: () => _openComments(context),
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width * 0.97,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Comments...",
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ],
        ),
      ),

      // Updated Floating Action Button with Model Status
      floatingActionButton: _buildARButton(),
    );
  }

  Widget _buildARButton() {
    if (_isCheckingModel) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: const Text(
          "Checking...",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (_has3DModel) {
      return FloatingActionButton.extended(
        onPressed: _openARCamera,
        backgroundColor: const Color(0xff5BEC84),
        icon: const Icon(Icons.view_in_ar, color: Colors.black),
        label: const Text(
          "View in AR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    if (_modelError != null) {
      return FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('3D Model Error: $_modelError'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implement retry logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Retry feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        label: const Text(
          "Model Failed",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No 3D model available for this video'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.block, color: Colors.white),
      label: const Text(
        "No Model",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
