import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YtVideoPlayer extends StatefulWidget {
  final String videoId;

  const YtVideoPlayer({super.key, required this.videoId});

  @override
  State<YtVideoPlayer> createState() => _YtVideoPlayerState();
}

class _YtVideoPlayerState extends State<YtVideoPlayer> {
  late YoutubePlayerController _controller;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightGreen,
      ),
      body: YoutubePlayerBuilder(
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
                //some other widgets
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Title",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }),

      //floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),
    );
  }
}
