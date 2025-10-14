import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/utilities/keys.dart';

class YtApiService {
  String baseUrl = "https://www.googleapis.com/youtube/v3/playlistItems";

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

        for (var videoData in playListItems) {
          String thumbnail = videoData['snippet']['thumbnails']['maxres']
                  ?['url'] ??
              videoData['snippet']['thumbnails']['high']?['url'] ??
              videoData['snippet']['thumbnails']['default']?['url'] ??
              '';

          YtVideo video = YtVideo(
            videoId: videoData['snippet']['resourceId']['videoId'],
            videoTitle: videoData['snippet']['title'],
            thumbnailUrl: thumbnail,
            viewsCount: "100M",
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

  static allVideos() {}
}
