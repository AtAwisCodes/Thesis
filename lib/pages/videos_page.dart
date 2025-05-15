import 'package:cloud_firestore/cloud_firestore.dart';
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
    Provider.of<YtVideoviewModel>(context, listen: false).getAllVideos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Videos
      backgroundColor: Colors.transparent,
      body: Consumer<YtVideoviewModel>(builder: (context, YtVideoviewModel, _) {
        if (YtVideoviewModel.playlistItems.isEmpty) {
          return Center(
            child: Text("No Videos"),
          );
        } else {
          return ListView.builder(
              itemCount: YtVideoviewModel.playlistItems.length,
              itemBuilder: (context, index) {
                return YoutubeVideoCard(
                  ytVideo: YtVideoviewModel.playlistItems[index],
                );
              });
        }
      }),
    );
  }
}
