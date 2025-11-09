import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/utilities/keys.dart';

class YtApiService {
  String baseUrl = "https://www.googleapis.com/youtube/v3/playlistItems";
  String videosUrl = "https://www.googleapis.com/youtube/v3/videos";
  String channelsUrl = "https://www.googleapis.com/youtube/v3/channels";

  Future<Map<String, dynamic>> getAllVideosFromPlaylist(
      {String? pageToken}) async {
    String url = "";
    try {
      List<YtVideo> allVideos = [];

      url =
          "$baseUrl?part=snippet,status&maxResults=50&playlistId=PLoaTLsTsV3hM7dBxY2mI-tMFlI3YW6DPE&key=${ApiKeys.youtubeApiKey}";

      if (pageToken != null) {
        url += "&pageToken=$pageToken";
      }

      print(" Fetching YouTube videos from API...");
      print(" API URL: $url");
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List playListItems = jsonData['items'] ?? [];

        print(
            " Successfully fetched ${playListItems.length} videos from playlist");

        // Extract video IDs to fetch statistics and check embeddability
        List<String> videoIds = playListItems
            .where((item) => item['snippet']?['resourceId']?['videoId'] != null)
            .map((item) => item['snippet']['resourceId']['videoId'] as String)
            .toList();

        print("📹 Video IDs extracted: ${videoIds.length}");

        // Fetch video statistics and embeddable status
        Map<String, dynamic> videoDetails = await _getVideoDetails(videoIds);
        Map<String, String> videoStats = videoDetails['stats'] ?? {};
        Map<String, bool> videoEmbeddable = videoDetails['embeddable'] ?? {};
        Map<String, String> videoChannelIds = videoDetails['channelIds'] ?? {};

        // Extract unique channel IDs and fetch their avatars
        Set<String> uniqueChannelIds = videoChannelIds.values.toSet();
        Map<String, String> channelAvatars =
            await _getChannelAvatars(uniqueChannelIds.toList());

        int skippedCount = 0;
        for (var videoData in playListItems) {
          String videoId = videoData['snippet']['resourceId']['videoId'];

          // Check if video is embeddable
          bool isEmbeddable = videoEmbeddable[videoId] ?? false;
          if (!isEmbeddable) {
            skippedCount++;
            print(" Video '$videoId' is NOT embeddable - SKIPPING");
            continue; // Skip non-embeddable videos
          }

          String thumbnail = videoData['snippet']['thumbnails']['maxres']
                  ?['url'] ??
              videoData['snippet']['thumbnails']['high']?['url'] ??
              videoData['snippet']['thumbnails']['default']?['url'] ??
              '';

          String channelId = videoChannelIds[videoId] ?? '';
          String? channelAvatar = channelAvatars[channelId];

          YtVideo video = YtVideo(
            videoId: videoId,
            videoTitle: videoData['snippet']['title'],
            thumbnailUrl: thumbnail,
            viewsCount: videoStats[videoId] ?? 'N/A',
            channelName: videoData['snippet']['channelTitle'],
            channelAvatarUrl: channelAvatar,
          );

          allVideos.add(video);
        }

        print(" Added ${allVideos.length} embeddable videos");
        if (skippedCount > 0) {
          print(" Skipped $skippedCount non-embeddable videos");
        }

        print(" Added ${allVideos.length} embeddable videos");
        if (skippedCount > 0) {
          print(" Skipped $skippedCount non-embeddable videos");
        }

        // Include nextPageToken for future calls
        return {
          'videos': allVideos,
          'nextPageToken': jsonData['nextPageToken']
        };
      } else {
        print(" YouTube API Error - Status Code: ${response.statusCode}");
        print(" Response Body: ${response.body}");
        print(" URL: $url");
      }
    } catch (e) {
      print(" Error fetching YouTube data: $e");
      print("URL: $url");
    }

    return {'videos': [], 'nextPageToken': null};
  }

  /// Fetch video statistics and embeddable status for multiple videos
  Future<Map<String, dynamic>> _getVideoDetails(List<String> videoIds) async {
    Map<String, String> stats = {};
    Map<String, bool> embeddable = {};
    Map<String, String> channelIds = {};

    if (videoIds.isEmpty) {
      return {
        'stats': stats,
        'embeddable': embeddable,
        'channelIds': channelIds
      };
    }

    try {
      // Join video IDs with commas (YouTube API allows up to 50 IDs per request)
      String ids = videoIds.join(',');
      // Add 'status' part to check embeddable property and snippet for channelId
      String url =
          "$videosUrl?part=statistics,status,snippet&id=$ids&key=${ApiKeys.youtubeApiKey}";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List items = jsonData['items'] ?? [];

        for (var item in items) {
          String videoId = item['id'];
          String viewCount = item['statistics']?['viewCount'] ?? '0';
          bool isEmbeddable = item['status']?['embeddable'] ?? false;
          String channelId = item['snippet']?['channelId'] ?? '';

          // Format view count (e.g., 1000000 -> 1M)
          stats[videoId] = _formatViewCount(viewCount);
          embeddable[videoId] = isEmbeddable;
          channelIds[videoId] = channelId;
        }

        print(" Fetched details for ${items.length} videos");
      } else {
        print(
            " Error fetching video details, status code ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print(" Error fetching video details: $e");
    }

    return {'stats': stats, 'embeddable': embeddable, 'channelIds': channelIds};
  }

  /// Fetch channel avatars for multiple channels
  Future<Map<String, String>> _getChannelAvatars(
      List<String> channelIds) async {
    Map<String, String> avatars = {};

    if (channelIds.isEmpty) {
      return avatars;
    }

    try {
      // Join channel IDs with commas (YouTube API allows up to 50 IDs per request)
      String ids = channelIds.join(',');
      String url =
          "$channelsUrl?part=snippet&id=$ids&key=${ApiKeys.youtubeApiKey}";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List items = jsonData['items'] ?? [];

        for (var item in items) {
          String channelId = item['id'];
          String avatarUrl =
              item['snippet']?['thumbnails']?['default']?['url'] ?? '';

          if (avatarUrl.isNotEmpty) {
            avatars[channelId] = avatarUrl;
          }
        }

        print("🎭 Fetched avatars for ${avatars.length} channels");
      } else {
        print(
            "⚠️ Error fetching channel avatars, status code ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching channel avatars: $e");
    }

    return avatars;
  }

  /// Format view count to readable format (e.g., 1M, 5.2K)
  String _formatViewCount(String viewCountStr) {
    try {
      int viewCount = int.parse(viewCountStr);

      if (viewCount >= 1000000000) {
        return '${(viewCount / 1000000000).toStringAsFixed(1)}B';
      } else if (viewCount >= 1000000) {
        return '${(viewCount / 1000000).toStringAsFixed(1)}M';
      } else if (viewCount >= 1000) {
        return '${(viewCount / 1000).toStringAsFixed(1)}K';
      } else {
        return viewCount.toString();
      }
    } catch (e) {
      return 'N/A';
    }
  }

  static allVideos() {}
}
