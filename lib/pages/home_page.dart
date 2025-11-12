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
import 'package:rexplore/pages/about_us_page.dart';
import 'package:rexplore/pages/settings_page.dart';
import 'package:rexplore/services/auth_service.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

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
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 8),
              Text('Logging Out!'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with logout
    if (confirmed == true) {
      // Clear any cached data before signing out
      final ytVideoViewModel =
          Provider.of<YtVideoviewModel>(context, listen: false);
      ytVideoViewModel.reset();

      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: responsive.appBarHeight,
        title: Text(
          getAppBarTitle(page),
          style: textHelper.titleLarge(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
        actions: page != 2
            ? [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      size: responsive.iconSize(24),
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ]
            : null,
      ),

      // Drawer
      drawer: (page != 2)
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

                  return Column(
                    children: [
                      // Header
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          accountEmail: Text(
                            currentUser?.email ?? "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

                      // Menu Items
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text('Settings'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About Us'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AboutUsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Logout Button at Bottom
                      const Divider(height: 1),
                      Container(
                        color: Colors.red.withOpacity(0.1),
                        child: ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: signUserOut,
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          : null,

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: getSelectedWidget(page: page),
      ),

      //Camera Floating Action Button AI - Only visible on home page
      floatingActionButton: page == 0
          ? Padding(
              padding: EdgeInsets.only(bottom: responsive.spacing(0)),
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
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: responsive.iconSize(28),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: responsive.spacing(0)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(responsive.borderRadius(25)),
              topRight: Radius.circular(responsive.borderRadius(25)),
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(responsive.borderRadius(25)),
              topRight: Radius.circular(responsive.borderRadius(25)),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: SizedBox(
                height: responsive.bottomNavHeight,
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
                        size: responsive.iconSize(24),
                      ),
                      Icon(
                        page == 1 ? Icons.favorite : Icons.favorite_border,
                        color: theme.iconTheme.color,
                        size: responsive.iconSize(24),
                      ),
                      Icon(
                        page == 2 ? Icons.add_circle : Icons.add_circle_outline,
                        size: responsive.iconSize(30),
                        color: theme.iconTheme.color,
                      ),
                      Icon(
                        page == 3
                            ? Icons.notifications
                            : Icons.notifications_none,
                        color: theme.iconTheme.color,
                        size: responsive.iconSize(24),
                      ),
                      CircleAvatar(
                        radius: responsive.iconSize(18),
                        backgroundColor: page == 4
                            ? theme.colorScheme.primary
                            : Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: responsive.iconSize(16),
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(
                                  "$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                              : defaultAvatar,
                        ),
                      ),
                    ];

                    return CurvedNavigationBar(
                      backgroundColor: Colors.transparent,
                      buttonBackgroundColor: Colors.transparent,
                      color: theme.appBarTheme.backgroundColor ?? Colors.white,
                      items: navigationItems,
                      height: 60,
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
