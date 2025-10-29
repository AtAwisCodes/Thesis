import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/image_recognition/cameraFunc.dart';
import 'package:rexplore/pages/favorite_page.dart';
import 'package:rexplore/pages/notif_page.dart';
import 'package:rexplore/pages/profile_page.dart';
import 'package:rexplore/pages/upload_page.dart';
import 'package:rexplore/pages/videos_page.dart';
import 'package:rexplore/pages/search_bar.dart';
import 'package:rexplore/services/ThemeProvider.dart';
import 'package:rexplore/services/auth_service.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

//Const fallback avatar image
const ImageProvider defaultAvatar = AssetImage('lib/icons/ReXplore.png');

class _HomePageState extends State<HomePage> {
  int page = 0;

  // Get current user dynamically instead of using a static variable
  User? get currentUser => FirebaseAuth.instance.currentUser;

  void signUserOut() async {
    // Clear any cached data before signing out
    final ytVideoViewModel =
        Provider.of<YtVideoviewModel>(context, listen: false);
    ytVideoViewModel.reset();

    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          getAppBarTitle(page),
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: page == 4
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          if (page == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: MySearchDelegate());
              },
            ),
        ],
      ),

      // Drawer
      drawer: (page == 4)
          ? Drawer(
              child: StreamBuilder<DocumentSnapshot>(
                stream: currentUser != null
                    ? FirebaseFirestore.instance
                        .collection("count")
                        .doc(currentUser!.uid)
                        .snapshots()
                    : Stream.empty(),
                builder: (context, snapshot) {
                  String? avatarUrl;
                  if (snapshot.hasData &&
                      snapshot.data!.data() != null &&
                      (snapshot.data!.data() as Map<String, dynamic>)
                          .containsKey("avatar_url")) {
                    avatarUrl = (snapshot.data!.data()
                        as Map<String, dynamic>)["avatar_url"];
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.teal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: UserAccountsDrawerHeader(
                          decoration:
                              const BoxDecoration(color: Colors.transparent),
                          accountName: Text(
                            currentUser?.displayName ?? "User",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          accountEmail: Text(currentUser?.email ?? ""),
                          currentAccountPicture: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(
                                    "$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                                : defaultAvatar,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text("Theme Mode"),
                        value: Provider.of<ThemeProvider>(context).isDarkMode,
                        onChanged: (val) {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme(val);
                        },
                        secondary: const Icon(Icons.brightness_6),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('About Us'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: signUserOut,
                      ),
                    ],
                  );
                },
              ),
            )
          : null,

      body: Column(
        children: [
          if (page == 0)
            Consumer<YtVideoviewModel>(
              builder: (context, ytVideoViewModel, _) {
                if (ytVideoViewModel.searchQuery.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.green.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt,
                            size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtering by: "${ytVideoViewModel.searchQuery}"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.green),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ytVideoViewModel.clearSearch();
                          },
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: getSelectedWidget(page: page),
            ),
          ),
        ],
      ),

      //Camera Floating Action Button AI - Only visible on home page
      floatingActionButton: page == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: FloatingActionButton(
                onPressed: () async {
                  final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => cameraFunc(camera: cameras[0]),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No cameras found')),
                    );
                  }
                },
                backgroundColor: theme.colorScheme.primary,
                elevation: 6,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: SizedBox(
                height: 100,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: currentUser != null
                      ? FirebaseFirestore.instance
                          .collection("count")
                          .doc(currentUser!.uid)
                          .snapshots()
                      : Stream.empty(),
                  builder: (context, snapshot) {
                    String? avatarUrl;
                    if (snapshot.hasData &&
                        snapshot.data!.data() != null &&
                        (snapshot.data!.data() as Map<String, dynamic>)
                            .containsKey("avatar_url")) {
                      avatarUrl = (snapshot.data!.data()
                          as Map<String, dynamic>)["avatar_url"];
                    }

                    final List<Widget> navigationItems = [
                      Icon(
                        page == 0 ? Icons.home : Icons.home_outlined,
                        color: theme.iconTheme.color,
                      ),
                      Icon(
                        page == 1 ? Icons.favorite : Icons.favorite_border,
                        color: theme.iconTheme.color,
                      ),
                      Icon(
                        page == 2 ? Icons.add_circle : Icons.add_circle_outline,
                        size: 30,
                        color: theme.iconTheme.color,
                      ),
                      Icon(
                        page == 3
                            ? Icons.notifications
                            : Icons.notifications_none,
                        color: theme.iconTheme.color,
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: page == 4
                            ? theme.colorScheme.primary
                            : Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(
                                  "$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                              : defaultAvatar,
                        ),
                      ),
                    ];

                    return CurvedNavigationBar(
                      backgroundColor: Colors.transparent,
                      buttonBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.9),
                      color: theme.appBarTheme.backgroundColor ?? Colors.white,
                      items: navigationItems,
                      animationDuration: const Duration(milliseconds: 300),
                      index: page,
                      onTap: (selectedIndex) {
                        setState(() => page = selectedIndex);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getAppBarTitle(int page) {
    switch (page) {
      case 0:
        return "REXPLORE";
      case 1:
        return "Favorites";
      case 2:
        return "Upload";
      case 3:
        return "Notifications";
      case 4:
        return "Profile";
      default:
        return "";
    }
  }

  Widget getSelectedWidget({required int page}) {
    switch (page) {
      case 0:
        return const VideosPage();
      case 1:
        return const FavoritePage();
      case 2:
        return const UploadPage();
      case 3:
        return const NotifPage();
      case 4:
        return ProfilePage();
      default:
        return const VideosPage();
    }
  }
}
