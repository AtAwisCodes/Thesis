import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YtVideoPlayer extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String viewsCount;
  final String channelName;
  final String thumbnailUrl;

  YtVideoPlayer({
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
  final _commentController = TextEditingController();

  @override
  void initState() {
    _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ));
    super.initState();
  }

  static const Color lightGreen = Color(0xFF8BC34A); // Secondary green
  bool isFollowed = false;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightGreen,
      ),
      body: SingleChildScrollView(
        child: YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
            ),
            builder: (
              context,
              player,
            ) {
              return Column(
                children: [
                  // some widgets
                  player,
                  //some other widget
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.videoTitle,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  //Views
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${widget.viewsCount} views",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                  //Thumbnail
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: CachedNetworkImageProvider(
                                widget.thumbnailUrl,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(widget.channelName)
                          ],
                        ),
                        //Buttons
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
                                  if (isLiked) isDisliked = false;
                                });
                              },
                            ),
                            //  Dislike button
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

                            // Follow/Followed button
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isFollowed = !isFollowed;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowed
                                    ? Colors.grey
                                    : Color(0xff5BEC84),
                              ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  //Comment
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController _dialogCommentController =
                              TextEditingController();
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            content: TextField(
                              controller: _dialogCommentController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: "Write your comment here...",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Use _dialogCommentController.text as needed
                                  Navigator.pop(context);
                                },
                                child: Text("Post"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 50,
                      width: 400,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Write something...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),

      //floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
    );
  }
}
