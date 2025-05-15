import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/pages/favorite_page.dart';
import 'package:rexplore/pages/notif_page.dart';
import 'package:rexplore/pages/profile_page.dart';
import 'package:rexplore/pages/upload_page.dart';
import 'package:rexplore/pages/videos_page.dart';
import 'package:rexplore/pages/search_bar.dart';
import 'package:rexplore/services/ThemeProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final user = FirebaseAuth.instance.currentUser!;
void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> {
  static const Color forestGreen = Color(0xFF228B22); //Kahit saan
  static const Color earthyBeige = Color(0xFFF5F5DC); // Background beige
  static const Color lightGreen = Color(0xFF8BC34A); // Secondary green

  //defaultPage
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    //Navigation Items
    final List<Widget> navigationItems = [
      Icon(Icons.home, color: theme.iconTheme.color),
      Icon(Icons.favorite, color: theme.iconTheme.color),
      Icon(Icons.add, color: theme.iconTheme.color),
      Icon(Icons.notifications, color: theme.iconTheme.color),
      CircleAvatar(
        radius: 18,
        backgroundColor: Colors.transparent,
        backgroundImage: const AssetImage('lib/icons/ReXplore.png'),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: page == 4,
        title: Text(
          getAppBarTitle(page),
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (page == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: MySearchDelegate(),
                );
              },
            ),
        ],
      ),
      drawer: (page == 4)
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: const Text(''),
                    accountEmail: const Text(''),
                    currentAccountPicture: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(200)),
                        border: Border.all(width: 2, color: Colors.white70),
                      ),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('lib/icons/ReXplore.png'),
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
                  const ListTile(title: Text('About Us')),
                  const ListTile(title: Text('Library')),
                  const ListTile(title: Text('Settings')),
                  ListTile(
                    title: const Text('Logout'),
                    onTap: signUserOut,
                  ),
                ],
              ),
            )
          : null,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: getSelectedWidget(page: page),
      ),
      //Bottom Navigation
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: theme.appBarTheme.backgroundColor ?? Colors.grey,
        color: theme.appBarTheme.backgroundColor ?? Colors.white,
        items: navigationItems,
        animationDuration: const Duration(milliseconds: 300),
        index: page,
        onTap: (selectedIndex) {
          setState(() {
            page = selectedIndex;
          });
        },
      ),
    );
  }

//appbar condition
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

// NavigationSaHomePage
  Widget getSelectedWidget({required int page}) {
    Widget widget;
    switch (page) {
      case 0:
        widget = const VideosPage();
        break;

      case 1:
        widget = const FavoritePage();
        break;

      case 2:
        widget = const UploadPage();
        break;

      case 3:
        widget = const NotifPage();
        break;

      case 4:
        widget = ProfilePage();
        break;

      default:
        widget = const VideosPage();
        break;
    }
    return widget;
  }
}
