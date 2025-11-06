import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/utilities/keys.dart';

class YtApiService {
  String baseUrl = "https://www.googleapis.com/youtube/v3/playlistItems";
  String videosUrl = "https://www.googleapis.com/youtube/v3/videos";

  Future<Map<String, dynamic>> getAllVideosFromPlaylist(
      {String? pageToken}) async {
    try {
      List<YtVideo> allVideos = [];

      String url =
          "$baseUrl?part=snippet&maxResults=50&playlistId=PLoaTLsTsV3hM7dBxY2mI-tMFlI3YW6DPE&key=${ApiKeys.youtubeApiKey}";

      if (pageToken != null) {
        url += "&pageToken=$pageToken";
      }

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List playListItems = jsonData['items'];

        // Extract video IDs to fetch statistics
        List<String> videoIds = playListItems
            .map((item) => item['snippet']['resourceId']['videoId'] as String)
            .toList();

        // Fetch video statistics (view counts)
        Map<String, String> videoStats = await _getVideoStatistics(videoIds);

        for (var videoData in playListItems) {
          String videoId = videoData['snippet']['resourceId']['videoId'];
          String thumbnail = videoData['snippet']['thumbnails']['maxres']
                  ?['url'] ??
              videoData['snippet']['thumbnails']['high']?['url'] ??
              videoData['snippet']['thumbnails']['default']?['url'] ??
              '';

          YtVideo video = YtVideo(
            videoId: videoId,
            videoTitle: videoData['snippet']['title'],
            thumbnailUrl: thumbnail,
            viewsCount: videoStats[videoId] ?? 'N/A',
            channelName: videoData['snippet']['channelTitle'],
          );

          allVideos.add(video);
        }

        // Include nextPageToken for future calls
        return {
          'videos': allVideos,
          'nextPageToken': jsonData['nextPageToken']
        };
      } else {
        print("Error fetching data, status code ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    return {'videos': [], 'nextPageToken': null};
  }

  /// Fetch video statistics (view counts) for multiple videos
  Future<Map<String, String>> _getVideoStatistics(List<String> videoIds) async {
    Map<String, String> stats = {};

    if (videoIds.isEmpty) return stats;

    try {
      // Join video IDs with commas (YouTube API allows up to 50 IDs per request)
      String ids = videoIds.join(',');
      String url =
          "$videosUrl?part=statistics&id=$ids&key=${ApiKeys.youtubeApiKey}";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        List items = jsonData['items'] ?? [];

        for (var item in items) {
          String videoId = item['id'];
          String viewCount = item['statistics']?['viewCount'] ?? '0';

          // Format view count (e.g., 1000000 -> 1M)
          stats[videoId] = _formatViewCount(viewCount);
        }
      } else {
        print(
            "Error fetching video statistics, status code ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching video statistics: $e");
    }

    return stats;
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
