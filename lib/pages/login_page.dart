import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/pages/home_page.dart';
import 'package:rexplore/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signInUser() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pop(context);
    } on FirebaseAuthException {
      Navigator.pop(context);
      showErrorMessage("Some information not matched in our system");
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          CardDialog(screenWidth: screenWidth, screenHeight: screenHeight),
          Positioned(
            top: 0,
            right: screenWidth * 0.04,
            height: 28,
            width: 28,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(screenWidth * 0.01),
                shape: const CircleBorder(),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.transparent),
              ),
              child: Icon(
                Icons.cancel,
                size: screenWidth * 0.07,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget CardDialog(
      {required double screenWidth, required double screenHeight}) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: screenWidth * 0.06,
      ),
      margin: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xff2A303E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Login to your account!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Email
              MyTextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              SizedBox(height: screenHeight * 0.015),

              // Password
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              SizedBox(height: screenHeight * 0.015),

              // Forgot Password
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Sign In Button
              MyButton(text: "Sign In", onTap: signInUser),
              SizedBox(height: screenHeight * 0.03),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white)),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                    child: Text('Or continue with',
                        style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(child: Divider(color: Colors.white)),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Google Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SquareTile(
                    onTap: () async {
                      try {
                        final userCredential =
                            await AuthService().signInWithGoogle();
                        if (userCredential != null) {
                          Navigator.of(context).pop(); // close login dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                          );
                        }
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.deepPurple,
                            title: const Center(
                              child: Text(
                                'Google sign-in failed',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            content: Text(
                              e.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    imagePath: 'lib/icons/Google.png',
                  )
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Don't have an account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account yet?',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      'Register now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
