import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/pages/yt_video_player.dart';

class YoutubeVideoCard extends StatelessWidget {
  final YtVideo ytVideo;

  const YoutubeVideoCard({super.key, required this.ytVideo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      width: double.maxFinite,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Card(
            color: Colors.transparent,
            margin: EdgeInsets.all(10),
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(ytVideo.thumbnailUrl),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    ytVideo.videoTitle,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    ytVideo.channelName,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    ytVideo.viewsCount,
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => YtVideoPlayer(
                              videoId: ytVideo.videoId,
                              videoTitle: ytVideo.videoTitle,
                              viewsCount: ytVideo.viewsCount,
                              channelName: ytVideo.channelName,
                              thumbnailUrl: ytVideo.thumbnailUrl,
                            )));
              },
              icon: Icon(
                Icons.play_circle,
                color: Colors.red,
                size: 60,
              ))
        ],
      ),
    );
  }
}
