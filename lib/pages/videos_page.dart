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
  String _sourceFilter = 'all'; // 'all', 'youtube', 'user-uploaded'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<YtVideoviewModel>(context, listen: false).getAllVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<YtVideoviewModel>(
        builder: (context, ytVideoViewModel, _) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _videoService.getPublicVideos(),
            builder: (context, snapshot) {
              final uploadedVideos = snapshot.data ?? [];
              // Combine both uploaded + YouTube videos
              List<Map<String, dynamic>> combinedList = [
                ...uploadedVideos.map((v) => {"type": "uploaded", "data": v}),
                ...ytVideoViewModel.playlistItems
                    .map((yt) => {"type": "youtube", "data": yt}),
              ];

              // Apply source filter
              if (_sourceFilter == 'youtube') {
                combinedList = combinedList
                    .where((item) => item["type"] == "youtube")
                    .toList();
              } else if (_sourceFilter == 'user-uploaded') {
                combinedList = combinedList
                    .where((item) => item["type"] == "uploaded")
                    .toList();
              }

              return Column(
                children: [
                  // Filter chips at the top
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Videos', 'all',
                              Icons.video_library, Colors.purple),
                          const SizedBox(width: 8),
                          _buildFilterChip('YouTube', 'youtube',
                              Icons.play_circle_filled, Colors.red),
                          const SizedBox(width: 8),
                          _buildFilterChip('User Uploads', 'user-uploaded',
                              Icons.person, Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  // Video list
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
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
                                  CircularProgressIndicator(
                                      color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading videos...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: combinedList.length,
                              itemBuilder: (context, index) {
                                final item = combinedList[index];

                                if (item["type"] == "uploaded") {
                                  final videoData =
                                      item["data"] as Map<String, dynamic>;
                                  return UploadedVideoCard(
                                    videos: videoData,
                                  );
                                } else {
                                  final ytVideo = item["data"] as YtVideo;
                                  return YoutubeVideoCard(
                                    ytVideo: ytVideo,
                                  );
                                }
                              },
                            ),
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

  Widget _buildFilterChip(
      String label, String filter, IconData icon, Color color) {
    final isSelected = _sourceFilter == filter;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _sourceFilter = filter);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
