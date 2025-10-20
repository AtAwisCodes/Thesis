import 'package:flutter/material.dart';
import 'package:rexplore/pages/uploaded_video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rexplore/services/user_profile_sync_service.dart';

class UploadedVideoCard extends StatelessWidget {
  final Map<String, dynamic> videos;
  final UserProfileSyncService _profileService = UserProfileSyncService();

  UploadedVideoCard({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final videoUrl = videos["publicUrl"] as String? ?? "";
    final userId = videos["userId"] as String? ?? "";
    final videoId = videos["id"] ?? "";

    // video details
    final title = videos["title"] as String? ?? "Untitled";
    final views = videos["views"] ?? 0;

    // thumbnail
    final thumbnailUrl = videos["thumbnailUrl"] as String? ?? "";

    //Safely parse Firestore Timestamp and format it
    String uploadedAtText = "Unknown date";
    if (videos["uploadedAt"] is Timestamp) {
      final date = (videos["uploadedAt"] as Timestamp).toDate();
      uploadedAtText = DateFormat("MMM d, yyyy").format(date);
    }

    // Get real-time user profile data
    return StreamBuilder<Map<String, dynamic>?>(
      stream: userId.isNotEmpty
          ? _profileService.getUserProfileStream(userId)
          : Stream.value(null),
      builder: (context, profileSnapshot) {
        // Use real-time data if available, otherwise fallback to video data
        final firstName = profileSnapshot.hasData &&
                profileSnapshot.data != null
            ? (profileSnapshot.data!['first_name'] ?? videos["firstName"] ?? "")
            : (videos["firstName"] ?? "");
        final lastName = profileSnapshot.hasData && profileSnapshot.data != null
            ? (profileSnapshot.data!['last_name'] ?? videos["lastName"] ?? "")
            : (videos["lastName"] ?? "");
        final avatarUrl = profileSnapshot.hasData &&
                profileSnapshot.data != null
            ? (profileSnapshot.data!['avatar_url'] ?? videos["avatarUrl"] ?? "")
            : (videos["avatarUrl"] ?? "");

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
                  avatarUrl: avatarUrl,
                  firstName: firstName,
                  lastName: lastName,
                  videoId: videoId,
                  thumbnailUrl: thumbnailUrl,
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
                // Thumbnail with play icon overlay
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

                // Video Details
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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

                      // Uploader + Views/likes Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.04,
                            backgroundColor: Colors.grey[700],
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    color: Colors.white70)
                                : null,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Text(
                              "$firstName $lastName",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: screenWidth * 0.035,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.visibility,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            "$views",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: screenWidth * 0.032,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
