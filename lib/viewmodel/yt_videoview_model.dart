import 'package:flutter/material.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/services/yt_api_service.dart';

class YtVideoviewModel extends ChangeNotifier {
  List<YtVideo> playlistItems = [];
  String? nextPageToken;
  bool isLoading = false;
  String searchQuery = '';

  get allVideos => null;

  // Modified to load all videos at once
  Future<void> getAllVideos({bool loadMore = false}) async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners(); // Notify that loading has started

    if (!loadMore) {
      // Initial load - fetch all videos at once
      playlistItems = [];
      await _fetchAllVideosRecursively();
    } else {
      // This is now deprecated as we load all videos initially
      // But kept for backward compatibility
      final result = await YtApiService().getAllVideosFromPlaylist(
        pageToken: nextPageToken,
      );

      final List<YtVideo> newVideos = result['videos'];
      final String? newToken = result['nextPageToken'];

      playlistItems.addAll(newVideos);
      nextPageToken = newToken;
    }

    isLoading = false;
    notifyListeners();
  }

  // Recursively fetch all pages of videos
  Future<void> _fetchAllVideosRecursively({String? pageToken}) async {
    final result = await YtApiService().getAllVideosFromPlaylist(
      pageToken: pageToken,
    );

    final List<YtVideo> newVideos = result['videos'];
    final String? newToken = result['nextPageToken'];

    playlistItems.addAll(newVideos);

    print(
        '📺 Loaded ${newVideos.length} videos. Total so far: ${playlistItems.length}');

    // If there's a next page, fetch it recursively
    if (newToken != null) {
      notifyListeners(); // Update UI with progress
      await _fetchAllVideosRecursively(pageToken: newToken);
    } else {
      print('✅ Finished loading all videos. Total: ${playlistItems.length}');
      nextPageToken = null; // No more pages
    }
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

  // Reset all data when user signs out or switches accounts
  void reset() {
    playlistItems = [];
    nextPageToken = null;
    isLoading = false;
    searchQuery = '';
    print('DEBUG YtVideoviewModel.reset: All data cleared');
    notifyListeners();
  }

  void getUploadedVideos() {}
}
