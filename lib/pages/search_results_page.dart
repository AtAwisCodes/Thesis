import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/model/uploaded_video_card.dart';
import 'package:rexplore/model/yt_video_card.dart' show YoutubeVideoCard;

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final VideoUploadService _videoService = VideoUploadService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () {
            // Clear search when going back
            Provider.of<YtVideoviewModel>(context, listen: false).clearSearch();
            Navigator.pop(context);
          },
        ),
        title: Consumer<YtVideoviewModel>(
          builder: (context, viewModel, _) {
            return Text(
              'Results for "${viewModel.searchQuery}"',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.green),
            tooltip: 'Clear search',
            onPressed: () {
              Provider.of<YtVideoviewModel>(context, listen: false)
                  .clearSearch();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<YtVideoviewModel>(
        builder: (context, ytVideoViewModel, _) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _videoService.getPublicVideos(),
            builder: (context, snapshot) {
              final uploadedVideos = snapshot.data ?? [];

              // Combine both uploaded + YouTube videos
              final combinedList = [
                ...uploadedVideos.map((v) => {"type": "uploaded", "data": v}),
                ...ytVideoViewModel.playlistItems
                    .map((yt) => {"type": "youtube", "data": yt}),
              ];

              final searchQuery =
                  ytVideoViewModel.searchQuery.toLowerCase().trim();

              print(
                  'Result: searchQuery="$searchQuery", combinedList.length=${combinedList.length}');

              // Filter the list based on search query
              final filteredList = combinedList.where((item) {
                if (item["type"] == "uploaded") {
                  final video = item["data"] as Map<String, dynamic>;
                  final title = (video['title'] ?? '').toString().toLowerCase();
                  final description =
                      (video['description'] ?? '').toString().toLowerCase();
                  final matches = title.contains(searchQuery) ||
                      description.contains(searchQuery);

                  print(
                      'Result: title="$title", description="$description", searchQuery="$searchQuery", matches=$matches');

                  return matches;
                } else {
                  final ytVideo = item["data"] as YtVideo;
                  final title = ytVideo.videoTitle.toLowerCase();
                  final channelName = ytVideo.channelName.toLowerCase();
                  final matches = title.contains(searchQuery) ||
                      channelName.contains(searchQuery);

                  print(
                      'DEBUG YOUTUBE: title="$title", channelName="$channelName", searchQuery="$searchQuery", matches=$matches');

                  return matches;
                }
              }).toList();

              print(
                  'DEBUG SearchResultsPage: filteredList.length=${filteredList.length}');

              // Show loading indicator if still loading
              if (combinedList.isEmpty && ytVideoViewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              // Show no results message
              if (filteredList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No videos found for "$searchQuery"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different keywords or check your spelling',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Provider.of<YtVideoviewModel>(context,
                                    listen: false)
                                .clearSearch();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Browse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show results
              return Column(
                children: [
                  // Results count banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.green.withOpacity(0.1),
                    child: Text(
                      'Found ${filteredList.length} ${filteredList.length == 1 ? 'video' : 'videos'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Results list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        print(
                            'DEBUG: Rendering item $index, type: ${item["type"]}');

                        if (item["type"] == "uploaded") {
                          final video = item["data"] as Map<String, dynamic>;
                          print(
                              'DEBUG: Uploaded video title: ${video['title']}');
                          return UploadedVideoCard(
                            videos: video,
                          );
                        } else {
                          final ytVideo = item["data"] as YtVideo;
                          print(
                              'DEBUG: YouTube video title: ${ytVideo.videoTitle}');
                          return YoutubeVideoCard(ytVideo: ytVideo);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
