import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/pages/landing_page.dart';
import 'package:rexplore/pages/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // If user is logged in, show HomePage
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          // If not logged in, show LandingPage
          return const LandingPage();
        }
      },
    );
  }
}
