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
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          // Clamp text sizes
          double titleSize = (screenWidth * 0.08).clamp(20, 32);
          double subtitleSize = (screenWidth * 0.04).clamp(14, 18);
          double textSize = (screenWidth * 0.032).clamp(12, 16);

          return Stack(
            children: [
              _cardDialog(
                  screenWidth, screenHeight, titleSize, subtitleSize, textSize),
              Positioned(
                top: 0,
                right: screenWidth * 0.04,
                height: screenHeight * 0.04,
                width: screenHeight * 0.04,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(screenHeight * 0.005),
                    shape: const CircleBorder(),
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                  ),
                  child: Icon(Icons.cancel, size: screenHeight * 0.035),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _cardDialog(double screenWidth, double screenHeight, double titleSize,
      double subtitleSize, double textSize) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: screenWidth * 0.06,
      ),
      margin: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xff2A303E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Login to your account!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: subtitleSize,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Forgot Password?',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: textSize),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Sign In Button
                MyButton(text: "Sign In", onTap: signInUser),
                SizedBox(height: screenHeight * 0.03),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white)),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                      child: Text('Or continue with',
                          style: TextStyle(
                              color: Colors.white, fontSize: textSize)),
                    ),
                    const Expanded(child: Divider(color: Colors.white)),
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
                    Flexible(
                      child: Text(
                        'Don\'t have an account yet?',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: textSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
