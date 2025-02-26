import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17),
            child: SizedBox(
              width: 40,
              height: 40,
              child: const CircleAvatar(
                backgroundImage: AssetImage('lib/icons/ReXplore.png'),
              ),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Louis'),
              accountEmail: const Text('libusadal@gmail.com'),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  border: Border.all(width: 2, color: Colors.blueAccent),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('lib/icons/ReXplore.png'),
                ),
              ),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: signUserOut,
            ),
          ],
        ),
      ),
    );
  }
}
