import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/components/error_notification.dart';
import 'package:rexplore/services/auth_service.dart';
import 'package:rexplore/utilities/disposable_email_checker.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

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
    // Check for empty email
    final emailText = emailController.text.trim();
    if (emailText.isEmpty) {
      ErrorNotification.show(context, "Please enter your email address");
      return;
    }

    // Check for empty password
    if (passwordController.text.trim().isEmpty) {
      ErrorNotification.show(context, "Please enter your password");
      return;
    }

    // Check for disposable email
    final isDisposable = await DisposableEmailChecker.isDisposable(emailText);
    if (isDisposable) {
      ErrorNotification.show(
        context,
        "Disposable email addresses are not allowed.\nPlease use a permanent email address.",
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: passwordController.text.trim(),
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Sign out the user
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          showEmailVerificationDialog(userCredential.user!);
        }
        return;
      }

      // Check if account is deleted or suspended
      if (userCredential.user != null) {
        try {
          await AuthService().checkAccountStatus(userCredential.user!);
        } catch (e) {
          // Account is deleted or suspended, show error
          if (mounted) {
            String errorMessage = e.toString();
            // Remove 'Exception: ' prefix if present
            if (errorMessage.startsWith('Exception: ')) {
              errorMessage = errorMessage.substring(11);
            }
            ErrorNotification.show(context, errorMessage);
          }
          return;
        }
      }

      // Close the login dialog - AuthPage StreamBuilder will handle navigation
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;

        // Provide user-friendly error messages
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No account found with this email";
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password";
            break;
          case 'invalid-email':
            errorMessage = "Invalid email address";
            break;
          case 'user-disabled':
            errorMessage = "This account has been disabled";
            break;
          case 'too-many-requests':
            errorMessage = "Too many failed attempts. Please try again later";
            break;
          case 'invalid-credential':
            errorMessage = "Invalid email or password";
            break;
          default:
            errorMessage = "Invalid email or password";
        }

        ErrorNotification.show(context, errorMessage);
      }
    }
  }

  void showEmailVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff2A303E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Email Not Verified',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please verify your email address before logging in.',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'Email sent to:',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check your spam folder if you don\'t see the email.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Resend verification email
              try {
                await user.sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Resend Email',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: responsive.padding(all: 12),
      child: Stack(
        children: [
          _cardDialog(context),
        ],
      ),
    );
  }

  Widget _cardDialog(BuildContext context) {
    final responsive = context.responsive;
    final textHelper = ResponsiveText(responsive);

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: responsive.padding(
        vertical: 16,
        horizontal: 20,
      ),
      margin: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: const Color(0xff2A303E),
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome!',
                  style: textHelper.headlineLarge(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  'Login to your account!',
                  style: textHelper.bodyLarge(context).copyWith(
                        color: Colors.white,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(24)),

                // Email
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  enforceLimit: false,
                ),
                SizedBox(height: responsive.spacing(12)),

                // Password
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  enforceLimit: false,
                ),
                SizedBox(height: responsive.spacing(12)),

                // Sign In Button
                MyButton(text: "Sign In", onTap: signInUser),
                SizedBox(height: responsive.spacing(24)),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white)),
                    Padding(
                      padding: responsive.padding(horizontal: 12),
                      child: Text(
                        'Or continue with',
                        style: textHelper.bodyMedium(context).copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white)),
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),

                // Google Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: () async {
                        try {
                          final userCredential =
                              await AuthService().signInWithGoogle();
                          if (userCredential != null && mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            // Show the actual error message from checkAccountStatus
                            String errorMessage = e.toString();
                            // Remove 'Exception: ' prefix if present
                            if (errorMessage.startsWith('Exception: ')) {
                              errorMessage = errorMessage.substring(11);
                            }
                            ErrorNotification.show(context, errorMessage);
                          }
                        }
                      },
                      imagePath: 'lib/icons/Google.png',
                    )
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),

                // Don't have an account
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: responsive.spacing(8),
                  children: [
                    Text(
                      'Don\'t have an account yet?',
                      style: textHelper.bodyMedium(context).copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Register',
                        style: textHelper.bodyMedium(context).copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
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
