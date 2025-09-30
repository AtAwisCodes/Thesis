import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final lastNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    lastNameController.dispose();
    firstNameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void createAccount() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validate Date of Birth
    DateTime? dob;
    try {
      List<String> parts = ageController.text.trim().split('/');
      if (parts.length == 3) {
        int month = int.parse(parts[0]);
        int day = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        dob = DateTime(year, month, day);
      } else {
        showErrorMessage("Invalid date of birth format.");
        return;
      }
    } catch (e) {
      showErrorMessage("Invalid date of birth.");
      return;
    }

    int userAge = calculateAge(dob);

    // Age restriction check
    if (userAge < 16) {
      showErrorMessage(
        "You must be at least 16 years old to register.\nParental guidance is required.",
      );
      return;
    }

    // Check password requirements individually
    List<String> missing = [];
    if (password.length < 8) {
      missing.add("At least 8 characters,");
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missing.add("At least one uppercase letter,");
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      missing.add("At least one lowercase letter,");
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      missing.add("At least one number,");
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      missing.add("At least one special character");
    }

    if (missing.isNotEmpty) {
      showErrorMessage(
        "${missing.join("\n")}",
      );
      return;
    }

    // Confirm password match
    if (password != confirmPassword) {
      showErrorMessage("Passwords do not match.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: password,
      );

      await FirebaseService().addUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: userAge,
        email: emailController.text.trim(),
      );

      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      showErrorMessage("Registration failed: ${e.toString()}");
    }
  }

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12), // helps small screens
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          // Clamp values for consistency across devices
          double titleSize = (screenWidth * 0.08).clamp(20, 32);
          double textSize = (screenWidth * 0.034).clamp(12, 16);

          return Stack(
            children: [
              _cardDialog(screenWidth, screenHeight, titleSize, textSize),
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
      double textSize) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500), // prevents stretching
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
                  'Sign Up',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                MyTextfield(
                  controller: lastNameController,
                  hintText: 'Last Name',
                  obscureText: false,
                ),
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: firstNameController,
                  hintText: 'First Name',
                  obscureText: false,
                ),
                SizedBox(height: screenHeight * 0.015),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      ),
                    );
                    if (pickedDate != null) {
                      ageController.text =
                          "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
                    }
                  },
                  child: AbsorbPointer(
                    child: MyTextfield(
                      controller: ageController,
                      hintText: 'Date of Birth (MM/DD/YYYY)',
                      obscureText: false,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                SizedBox(height: screenHeight * 0.02),
                MyButton(
                  text: "Create Account",
                  onTap: createAccount,
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.white),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
                      child: const Text('Or continue with',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: 'lib/icons/Google.png',
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Already have an account?',
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
                        'Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
