import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rexplore/camera/cam_func.dart';
import 'package:rexplore/components/fullscreen_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:rexplore/services/favorites_manager.dart';

class UploadedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String uploadedAt;

  const UploadedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.uploadedAt,
  });

  @override
  State<UploadedVideoPlayer> createState() => _UploadedVideoPlayerState();
}

class _UploadedVideoPlayerState extends State<UploadedVideoPlayer> {
  late VideoPlayerController _controller;
  final List<String> comments = [];
  final _commentController = TextEditingController();

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;

  User? _currentUser;

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

    _currentUser = FirebaseAuth.instance.currentUser;

    // Load initial liked state
    isLiked = FavoritesManager.instance.contains(widget.videoUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => cameraFunc(camera: cameras[0]),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras found')),
        );
      }
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

                      // title
                      Row(
                        children: [
                          const Icon(Icons.comment_rounded,
                              color: Colors.green),
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
    final uploaderName = _currentUser?.displayName ?? "Anonymous";
    final uploaderAvatarUrl = _currentUser?.photoURL ?? "";

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
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Like / Dislike / Follow
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Uploader Avatar + Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: uploaderAvatarUrl.isNotEmpty
                            ? NetworkImage(uploaderAvatarUrl)
                            : null,
                        child: uploaderAvatarUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        uploaderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
    );
  }
}
