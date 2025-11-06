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

    return GestureDetector(
      onTap: () {
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
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + play icon overlay
            Stack(
              children: [
                Hero(
                  tag: ytVideo.videoId, // smooth transition
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      ytVideo.thumbnailUrl,
                      width: double.infinity,
                      height: screenHeight * 0.23,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Play button overlay
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white.withOpacity(0.9),
                      size: screenWidth * 0.18,
                    ),
                  ),
                ),
              ],
            ),

            // Video details
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with YouTube tag
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ytVideo.videoTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.008),

                  // Channel + Views Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.04,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: ytVideo.channelAvatarUrl != null
                            ? NetworkImage(ytVideo.channelAvatarUrl!)
                            : null,
                        child: ytVideo.channelAvatarUrl == null
                            ? const Icon(Icons.person, color: Colors.white70)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Expanded(
                        child: Text(
                          ytVideo.channelName,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                      Icon(Icons.visibility, size: 16, color: Colors.white54),
                      SizedBox(width: 4),
                      Text(
                        ytVideo.viewsCount,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: screenWidth * 0.032,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
