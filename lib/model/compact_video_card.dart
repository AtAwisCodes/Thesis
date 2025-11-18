import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/pages/yt_video_player.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Compact video card optimized for camera screen with better touch targets
class CompactVideoCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const CompactVideoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isYouTube = item["type"] == "youtube";

    if (isYouTube) {
      return _buildYouTubeCard(context);
    } else {
      return _buildUploadedCard(context);
    }
  }

  Widget _buildYouTubeCard(BuildContext context) {
    final ytVideo = item["data"] as YtVideo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                channelAvatarUrl: ytVideo.channelAvatarUrl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail with play overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ytVideo.thumbnailUrl,
                      width: 120,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      ytVideo.videoTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Channel info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'YouTube',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ytVideo.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Views
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          ytVideo.viewsCount,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildUploadedCard(BuildContext context) {
    final videoData = item["data"] as Map<String, dynamic>;
    final videoUrl = videoData["publicUrl"] as String? ?? "";
    final title = videoData["title"] as String? ?? "Untitled";
    final views = videoData["views"] ?? 0;
    final thumbnailUrl = videoData["thumbnailUrl"] as String? ?? "";
    final firstName = videoData["firstName"] ?? "";
    final lastName = videoData["lastName"] ?? "";
    final avatarUrl = videoData["avatarUrl"] ?? "";
    final videoId = videoData["id"] ?? "";

    String uploadedAtText = "Unknown date";
    if (videoData["uploadedAt"] is Timestamp) {
      final date = (videoData["uploadedAt"] as Timestamp).toDate();
      uploadedAtText = DateFormat("MMM d, yyyy").format(date);
    }

    // Format view count
    String formatViewCount(dynamic viewCount) {
      if (viewCount is String) return viewCount;
      if (viewCount is int) {
        if (viewCount >= 1000000000) {
          return '${(viewCount / 1000000000).toStringAsFixed(1)}B';
        } else if (viewCount >= 1000000) {
          return '${(viewCount / 1000000).toStringAsFixed(1)}M';
        } else if (viewCount >= 1000) {
          return '${(viewCount / 1000).toStringAsFixed(1)}K';
        } else {
          return viewCount.toString();
        }
      }
      return '0';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                avatarUrl: avatarUrl,
                firstName: firstName,
                lastName: lastName,
                videoId: videoId,
                thumbnailUrl: thumbnailUrl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail with play overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 120,
                            height: 90,
                            color: Colors.black,
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.white54,
                              size: 40,
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // User info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$firstName $lastName",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Views
                    Row(
                      children: [
                        const Icon(Icons.visibility,
                            size: 14, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          formatViewCount(views),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
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
      ),
    );
  }
}
