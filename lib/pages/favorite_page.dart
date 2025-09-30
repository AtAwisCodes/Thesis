import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rexplore/services/favorites_manager.dart';
import 'package:rexplore/pages/yt_video_player.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final FavoritesManager _manager = FavoritesManager.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _manager,
        builder: (context, _) {
          final sampleVideos = _manager.favorites;
          return sampleVideos.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  itemCount: sampleVideos.length,
                  itemBuilder: (context, index) {
                    final video = sampleVideos[index];

                    // Detect uploaded vs YouTube videos
                    if (video.containsKey("url") ||
                        video.containsKey("publicUrl")) {
                      // Uploaded video card
                      return _uploadedVideoCard(video);
                    } else {
                      // YouTube video card
                      return _youtubeVideoCard(
                        video["id"] ?? '',
                        video["title"] ?? '',
                        video["channel"] ?? '',
                        video["thumbnail"] ?? '',
                        video["views"] ?? '',
                      );
                    }
                  },
                );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 100, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(height: 20),
          Text(
            "No favorites yet",
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Like some videos on Home to see them here!",
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// YouTube video card
  Widget _youtubeVideoCard(String videoId, String title, String channel,
      String thumbnail, String views) {
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YtVideoPlayer(
              videoId: videoId,
              videoTitle: title,
              viewsCount: views,
              channelName: channel,
              thumbnailUrl: thumbnail,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
        elevation: 4,
        child: Column(
          children: [
            YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
            ),
            ListTile(
              title: Text(title),
              subtitle: Text(channel),
              trailing: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  FavoritesManager.instance.removeFavorite(videoId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Uploaded video card styled like YouTube
  Widget _uploadedVideoCard(Map<String, dynamic> video) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final videoId = video["id"] ?? "";
    final videoUrl = video["publicUrl"] ?? video["url"] ?? "";
    final title = video["title"] ?? "Untitled";
    final likes = video["likes"] ?? 0;
    final uploaderName = video["uploaderName"] ?? "Unknown uploader";
    final uploaderAvatar = video["uploaderAvatar"];
    final thumbnailUrl = video["thumbnailUrl"] ?? "";

    // Format uploaded date if available
    String uploadedAtText = "Unknown date";
    if (video["uploadedAt"] is Timestamp) {
      final date = (video["uploadedAt"] as Timestamp).toDate();
      uploadedAtText = DateFormat("MMM d, yyyy").format(date);
    }

    return GestureDetector(
      onTap: () {
        if (videoUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video URL is missing")),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadedVideoPlayer(
              videoUrl: videoUrl,
              title: title,
              uploadedAt: uploadedAtText,
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
            // Thumbnail with gradient + play icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          height: screenHeight * 0.23,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: screenHeight * 0.23,
                          color: Colors.black,
                          child: const Icon(Icons.videocam,
                              color: Colors.white70, size: 60),
                        ),
                ),
                Container(
                  height: screenHeight * 0.23,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
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

            // Details
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.04,
                        backgroundColor: Colors.grey[700],
                        backgroundImage: uploaderAvatar != null
                            ? NetworkImage(uploaderAvatar)
                            : null,
                        child: uploaderAvatar == null
                            ? const Icon(Icons.person, color: Colors.white70)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Expanded(
                        child: Text(
                          uploaderName,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.035,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      //Favorite/Delete button
                      IconButton(
                        icon:
                            const Icon(Icons.favorite, color: Colors.redAccent),
                        onPressed: () {
                          FavoritesManager.instance.removeFavorite(videoId);
                        },
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
