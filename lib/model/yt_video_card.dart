import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/pages/yt_video_player.dart';

class YoutubeVideoCard extends StatelessWidget {
  final YtVideo ytVideo;

  const YoutubeVideoCard({super.key, required this.ytVideo});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.4,
      width: double.infinity,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Card(
            color: Colors.transparent,
            margin: EdgeInsets.all(screenWidth * 0.025), // Responsive margin
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Image.network(
                  ytVideo.thumbnailUrl,
                  width: double.infinity,
                  height: screenHeight * 0.22,
                  fit: BoxFit.cover,
                ),

                // Video Title
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  child: Text(
                    ytVideo.videoTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045, // Responsive font
                    ),
                  ),
                ),

                // Channel Name
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                  child: Text(
                    ytVideo.channelName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),

                // Views Count
                SizedBox(height: screenHeight * 0.015),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                  child: Text(
                    ytVideo.viewsCount,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Play Icon Button (overlay)
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
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.play_circle,
              color: Colors.redAccent,
              size: screenWidth * 0.15, // Responsive icon size
            ),
          ),
        ],
      ),
    );
  }
}
