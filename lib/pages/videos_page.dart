import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/model/yt_video_card.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPage();
}

class _VideosPage extends State<VideosPage> {
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
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  ytVideoViewModel.nextPageToken != null &&
                  !ytVideoViewModel.isLoading) {
                ytVideoViewModel.getAllVideos(loadMore: true);
              }
              return false;
            },
            child: ytVideoViewModel.playlistItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: ytVideoViewModel.playlistItems.length,
                    itemBuilder: (context, index) {
                      return YoutubeVideoCard(
                        ytVideo: ytVideoViewModel.playlistItems[index],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
