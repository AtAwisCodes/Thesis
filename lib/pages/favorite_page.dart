import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rexplore/services/favorites_manager.dart'; // added import
import 'package:rexplore/pages/yt_video_player.dart'; // <-- added import

/// Favorite Page (UI only)
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
                    return _videoCard(
                      video["id"] ?? '',
                      video["title"] ?? '',
                      video["channel"] ?? '',
                      video["thumbnail"] ?? '',
                      video["views"] ?? '',
                    );
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

  // changed signature to accept thumbnail + views, and made the card tappable to play
  Widget _videoCard(String videoId, String title, String channel,
      String thumbnail, String views) {
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    return InkWell(
      onTap: () {
        // navigate to full video player with the saved metadata
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
                  // remove from favorites when heart icon tapped
                  FavoritesManager.instance.removeFavorite(videoId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
