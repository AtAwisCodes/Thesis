import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/model/yt_video_card.dart';
import 'package:rexplore/services/yt_api_service.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

//sign out
final user = FirebaseAuth.instance.currentUser!;
void signUserOut() {
  FirebaseAuth.instance.signOut();
}

//bottom navigation bar
final List<Widget> _navigationItem = [
  const Icon(Icons.search),
  const Icon(Icons.home),
  CircleAvatar(
    backgroundImage: AssetImage('lib/icons/ReXplore.png'),
  ),
];

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Provider.of<YtVideoviewModel>(context, listen: false).getAllVideos();
    super.initState();
  }

  static const Color earthyBeige = Color(0xFFF5F5DC); // Background beige
  static const Color lightGreen = Color(0xFF8BC34A); // Secondary green

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: earthyBeige,
      appBar: AppBar(
        backgroundColor: lightGreen,
        title: const Text(''),
      ),

      //drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(''),
              accountEmail: Text(''),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(200)),
                  border: Border.all(width: 2, color: Colors.white70),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('lib/icons/ReXplore.png'),
                ),
              ),
            ),
            ListTile(
              title: const Text('About Us'),
            ),
            ListTile(
              title: const Text('Library'),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: signUserOut,
            ),
          ],
        ),
      ),

      //Videos
      body: Consumer<YtVideoviewModel>(builder: (context, YtVideoviewModel, _) {
        if (YtVideoviewModel.playlistItems.isEmpty) {
          return Center(
            child: Text("No Videos"),
          );
        } else {
          return ListView.builder(
              itemCount: YtVideoviewModel.playlistItems.length,
              itemBuilder: (context, Index) {
                return YoutubeVideoCard(
                  ytVideo: YtVideoviewModel.playlistItems[Index],
                );
              });
        }
      }),

      //floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_enhance_rounded),
      ),

      //Bottom Navigation
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        items: _navigationItem,
        animationDuration: const Duration(milliseconds: 300),
        index: 1,
        onTap: (Index) async {
          if (Index == 1) {
            await YtApiService().getAllVideosFromPlaylist();
          }
        },
      ),
    );
  }
}
