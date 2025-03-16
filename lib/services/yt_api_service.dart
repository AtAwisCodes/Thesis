import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/utilities/keys.dart';

class YtApiService {
  String baseUrl = "https://www.googleapis.com/youtube/v3/playlistItems";

  getAllVideosFromPlaylist() async {
    try {
      List<YtVideo> allVideos = [];
      var response = await http.get(Uri.parse(
          "$baseUrl?part=snippet&playlistId=PLoaTLsTsV3hPJDj7YaE1p0k-Pp1GdWPcV&key=${ApiKeys.youtubeApiKey}"));

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        List playListItems = jsonData['items'];

        for (var videoData in playListItems) {
          YtVideo video = YtVideo(
              videoId: videoData['snippet']['resourceId']['videoId'],
              videoTitle: videoData['snippet']['title'],
              thumbnailUrl: videoData['snippet']['thumbnails']['maxres']['url'],
              viewsCount: "",
              channelName: videoData['snippet']['channelTitle']);

          allVideos.add(video);
        }

        print("The data from the API is $playListItems");
      } else {
        print(
            "Error fetching data, status code ${response.statusCode} body ${response.body}");
      }
      return allVideos;
    } catch (e) {
      print("Error fetching data $e");
    }
  }
}
