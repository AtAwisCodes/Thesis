import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/services/yt_api_service.dart';

class YtVideoviewModel extends ChangeNotifier {
  List<YtVideo> playlistItems = [];
  String? nextPageToken;
  bool isLoading = false;
  String searchQuery = '';

  get allVideos => null;

  Future<void> getAllVideos({bool loadMore = false}) async {
    if (isLoading) return;
    isLoading = true;

    final result = await YtApiService().getAllVideosFromPlaylist(
      pageToken: loadMore ? nextPageToken : null,
    );

    final List<YtVideo> newVideos = result['videos'];
    final String? newToken = result['nextPageToken'];

    if (!loadMore) {
      playlistItems = newVideos;
    } else {
      playlistItems.addAll(newVideos);
    }

    nextPageToken = newToken;
    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    print(
        'DEBUG YtVideoviewModel.setSearchQuery: searchQuery is now "$searchQuery"');
    notifyListeners();
    print('DEBUG YtVideoviewModel.setSearchQuery: notifyListeners() called');
  }

  void clearSearch() {
    searchQuery = '';
    print('DEBUG YtVideoviewModel.clearSearch: searchQuery cleared');
    notifyListeners();
  }

  void getUploadedVideos() {}
}
