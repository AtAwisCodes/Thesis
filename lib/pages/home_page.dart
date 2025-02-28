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
      backgroundColor: Colors.white,
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
              accountName: const Text(''),
              accountEmail: Text(''),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(200)),
                  border: Border.all(width: 2, color: Colors.blueAccent),
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('lib/icons/ReXplore.png'),
                ),
              ),
            ),
            ListTile(
              title: const Text('Profile'),
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.amber,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.yellow,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.blue,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.black12,
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
