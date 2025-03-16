import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/services/yt_api_service.dart';

class YtVideoviewModel extends ChangeNotifier {
  List<YtVideo> _playlistItems = [];

  List<YtVideo> get playlistItems => _playlistItems;

  getAllVideos() async {
    _playlistItems = await YtApiService().getAllVideosFromPlaylist();
    notifyListeners();
  }
}
