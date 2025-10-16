import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/model/yt_video.dart';
import 'package:rexplore/model/yt_video_card.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:rexplore/services/upload_function.dart';
import 'package:rexplore/model/uploaded_video_card.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final VideoUploadService _videoService = VideoUploadService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<YtVideoviewModel>(context, listen: false).getAllVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to search query changes to trigger rebuild
    // ignore: unused_local_variable
    final searchQuery = context.watch<YtVideoviewModel>().searchQuery;

    return Scaffold(
      body: Consumer<YtVideoviewModel>(
        builder: (context, ytVideoViewModel, _) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _videoService.getPublicVideos(),
            builder: (context, snapshot) {
              final uploadedVideos = snapshot.data ?? [];
              // combine both uploaded + YouTube videos
              final combinedList = [
                ...uploadedVideos.map((v) => {"type": "uploaded", "data": v}),
                ...ytVideoViewModel.playlistItems
                    .map((yt) => {"type": "youtube", "data": yt}),
              ];
              final searchQuery =
                  ytVideoViewModel.searchQuery.toLowerCase().trim();

              print(
                  'DEBUG VideosPage: searchQuery="$searchQuery", combinedList.length=${combinedList.length}');

              final filteredList = searchQuery.isEmpty
                  ? combinedList
                  : combinedList.where((item) {
                      if (item["type"] == "uploaded") {
                        final video = item["data"] as Map<String, dynamic>;
                        final title =
                            (video['title'] ?? '').toString().toLowerCase();
                        final description = (video['description'] ?? '')
                            .toString()
                            .toLowerCase();
                        final matches = title.contains(searchQuery) ||
                            description.contains(searchQuery);

                        print(
                            'DEBUG UPLOADED: title="$title", description="$description", searchQuery="$searchQuery", matches=$matches');

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
                  'DEBUG VideosPage: filteredList.length=${filteredList.length}');

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      ytVideoViewModel.nextPageToken != null &&
                      !ytVideoViewModel.isLoading) {
                    ytVideoViewModel.getAllVideos(loadMore: true);
                  }
                  return false;
                },
                child: combinedList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading videos...',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : filteredList.isEmpty && searchQuery.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No videos found for '$searchQuery'",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Try different keywords or check your spelling",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Provider.of<YtVideoviewModel>(context,
                                              listen: false)
                                          .clearSearch();
                                    },
                                    icon: const Icon(Icons.clear,
                                        color: Colors.white, size: 20),
                                    label: const Text("Clear Search",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
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
                          )
                        : Column(
                            children: [
                              // DEBUG: Show filtered count at top
                              if (searchQuery.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  color: Colors.green.withOpacity(0.1),
                                  child: Text(
                                    'DEBUG: Showing ${filteredList.length} filtered results for "$searchQuery"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];

                                    // DEBUG: Print each item being rendered
                                    print(
                                        'DEBUG: Rendering item $index, type: ${item["type"]}');

                                    try {
                                      if (item["type"] == "uploaded") {
                                        final videoData = item["data"]
                                            as Map<String, dynamic>;
                                        print(
                                            'DEBUG: Uploaded video title: ${videoData["title"]}');
                                        return UploadedVideoCard(
                                          videos: videoData,
                                        );
                                      } else {
                                        final ytVideo = item["data"] as YtVideo;
                                        print(
                                            'DEBUG: YouTube video title: ${ytVideo.videoTitle}');
                                        return YoutubeVideoCard(
                                          ytVideo: ytVideo,
                                        );
                                      }
                                    } catch (e) {
                                      print(
                                          'DEBUG: Error rendering item $index: $e');
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        margin: const EdgeInsets.all(8),
                                        color: Colors.red.withOpacity(0.1),
                                        child: Text(
                                            'Error rendering item $index: $e'),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
              );
            },
          );
        },
      ),
    );
  }
}
