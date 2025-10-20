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
    return Scaffold(
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
                            CircularProgressIndicator(color: Colors.green),
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
              );
            },
          );
        },
      ),
    );
  }
}
