import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/image_recognition/SimpleYOLOCamera.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rexplore/services/favorites_manager.dart';

class YtVideoPlayer extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String viewsCount;
  final String channelName;
  final String thumbnailUrl;

  const YtVideoPlayer({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.viewsCount,
    required this.channelName,
    required this.thumbnailUrl,
  });

  @override
  State<YtVideoPlayer> createState() => _YtVideoPlayerState();
}

class _YtVideoPlayerState extends State<YtVideoPlayer> {
  late YoutubePlayerController _controller;
  final List<String> comments = [];

  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    // load initial liked state
    isLiked = FavoritesManager.instance.contains(widget.videoId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleYOLOCamera(camera: cameras[0]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0, backgroundColor: Colors.transparent, actions: []),
      body: SingleChildScrollView(
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(controller: _controller),
          builder: (context, player) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,

                // title
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.videoTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // views
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.viewsCount} views",
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),

                // Channel thumbnail + actions
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: CachedNetworkImageProvider(
                              widget.thumbnailUrl,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.channelName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: isLiked ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isLiked = !isLiked;
                                if (isLiked) {
                                  isDisliked = false;
                                  FavoritesManager.instance.addFavorite({
                                    'id': widget.videoId,
                                    'title': widget.videoTitle,
                                    'channel': widget.channelName,
                                    'thumbnail': widget.thumbnailUrl,
                                    'views': widget.viewsCount,
                                  });
                                } else {
                                  FavoritesManager.instance
                                      .removeFavorite(widget.videoId);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 2), // closer spacing
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
                          const SizedBox(width: 8),
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
                                    color: isFollowed
                                        ? Colors.white70
                                        : Colors.black,
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
            );
          },
        ),
      ),

      // AR Camera button
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
    );
  }
}
