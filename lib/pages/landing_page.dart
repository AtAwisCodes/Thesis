import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/pages/auth_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        splash: "lib/icons/Loading.gif",
        splashIconSize: 5000.0,
        centered: true,
        backgroundColor: Color(0xff008080),
        nextScreen: AuthPage(),
        duration: 9000,
      ),
    );
  }
}
