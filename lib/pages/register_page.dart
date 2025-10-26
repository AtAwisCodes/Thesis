import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/services/auth_service.dart';
import 'package:rexplore/utilities/disposable_email_checker.dart';
import 'package:rexplore/utilities/email_verification.dart';

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

  // Password validation state
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool passwordsMatch = false;
  bool showPasswordRequirements = false;

  // Terms and Conditions acceptance
  bool acceptedTerms = false;

  // Email validation state
  bool isCheckingEmail = false;
  bool? isEmailAvailable;
  String? emailValidationMessage;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validatePassword);
    emailController.addListener(_validateEmail);
  }

  void _validatePassword() {
    setState(() {
      final password = passwordController.text;
      hasMinLength = password.length >= 8;
      hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      hasNumber = RegExp(r'\d').hasMatch(password);
      hasSpecialChar = RegExp(r'[^\w\s]').hasMatch(password);
      passwordsMatch =
          password.isNotEmpty && password == confirmPasswordController.text;
      showPasswordRequirements = password.isNotEmpty;
    });
  }

  // Email validation with debouncing
  void _validateEmail() async {
    final email = emailController.text.trim();

    // Reset state if email is empty
    if (email.isEmpty) {
      setState(() {
        isCheckingEmail = false;
        isEmailAvailable = null;
        emailValidationMessage = null;
      });
      return;
    }

    // Check email format first
    if (!EmailVerification.isValidEmailFormat(email)) {
      setState(() {
        isCheckingEmail = false;
        isEmailAvailable = false;
        emailValidationMessage = 'Invalid email format';
      });
      return;
    }

    // Check for disposable email
    final isDisposable = await DisposableEmailChecker.isDisposable(email);
    if (isDisposable) {
      setState(() {
        isCheckingEmail = false;
        isEmailAvailable = false;
        emailValidationMessage = 'Disposable email not allowed';
      });
      return;
    }

    // Show loading state
    setState(() {
      isCheckingEmail = true;
      emailValidationMessage = 'Checking availability...';
    });

    // Wait a bit to avoid too many API calls (debouncing)
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if the text changed during the delay
    if (email != emailController.text.trim()) {
      return; // User is still typing, don't check
    }

    try {
      final available = await EmailVerification.isEmailAvailable(email);
      setState(() {
        isCheckingEmail = false;
        isEmailAvailable = available;
        emailValidationMessage =
            available ? 'Email is available' : 'Email already registered';
      });
    } catch (e) {
      setState(() {
        isCheckingEmail = false;
        isEmailAvailable = null;
        emailValidationMessage = 'Error checking email';
      });
    }
  }

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
    final emailText = emailController.text.trim();

    // Validate email is not empty
    if (emailText.isEmpty) {
      showErrorMessage("Please enter an email address.");
      return;
    }

    // Validate email format
    if (!EmailVerification.isValidEmailFormat(emailText)) {
      showErrorMessage("Please enter a valid email address.");
      return;
    }

    // Check for disposable email
    final isDisposable = await DisposableEmailChecker.isDisposable(emailText);
    if (isDisposable) {
      showErrorMessage(
          "Disposable email addresses are not allowed.\nPlease use a permanent email address.");
      return;
    }

    // Check if email is already registered
    try {
      final isAvailable = await EmailVerification.isEmailAvailable(emailText);
      if (!isAvailable) {
        showErrorMessage(
            "This email is already registered.\nPlease use a different email or try logging in.");
        return;
      }
    } catch (e) {
      showErrorMessage("Error verifying email: ${e.toString()}");
      return;
    }

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

    // Check password requirements
    if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasNumber ||
        !hasSpecialChar) {
      showErrorMessage("Meet all password requirements.");
      return;
    }

    // Confirm password match
    if (password != confirmPassword) {
      showErrorMessage("Passwords do not match.");
      return;
    }

    // Check if terms and conditions are accepted
    if (!acceptedTerms) {
      showErrorMessage("Accept the Terms and Conditions to continue.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailText,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Add user to Firestore
      await FirebaseService().addUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: userAge,
        email: emailText,
      );

      Navigator.of(context).pop(); // Close loading dialog

      // Show success message with email verification instruction
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xff2A303E),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify Your Email',
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
                const Text(
                  'Account created successfully!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A verification email has been sent to:',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  emailText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your inbox and click the verification link to activate your account.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 20),
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
                    await userCredential.user?.sendEmailVerification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email resent!'),
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
                  Navigator.of(context).pop(); // Close verification dialog
                  Navigator.of(context).pop(); // Close register dialog
                  // User will need to verify email before logging in
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
                if (emailValidationMessage != null) ...[
                  SizedBox(height: screenHeight * 0.01),
                  _buildEmailValidationIndicator(textSize),
                ],
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                if (showPasswordRequirements) ...[
                  SizedBox(height: screenHeight * 0.01),
                  _buildPasswordRequirements(textSize),
                ],
                SizedBox(height: screenHeight * 0.015),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                if (confirmPasswordController.text.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.01),
                  _buildPasswordMatchIndicator(textSize),
                ],
                SizedBox(height: screenHeight * 0.015),
                _buildTermsAndConditions(textSize),
                SizedBox(height: screenHeight * 0.015),
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
                      onTap: () async {
                        try {
                          final userCredential =
                              await AuthService().signInWithGoogle();
                          if (userCredential != null && mounted) {
                            Navigator.of(context)
                                .pop(); // close register dialog
                          }
                        } catch (e) {
                          if (mounted) {
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
                        }
                      },
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

//PASSWORD VALIDATOR BOX
  Widget _buildPasswordRequirements(double textSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1E2330),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: textSize * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
              'At least 8 characters', hasMinLength, textSize),
          _buildRequirementItem('One uppercase letter', hasUppercase, textSize),
          _buildRequirementItem('One lowercase letter', hasLowercase, textSize),
          _buildRequirementItem('One number', hasNumber, textSize),
          _buildRequirementItem(
              'One special character', hasSpecialChar, textSize),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet, double textSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.green : Colors.grey,
            size: textSize * 1.2,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey[400],
              fontSize: textSize * 0.85,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordMatchIndicator(double textSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1E2330),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passwordsMatch
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passwordsMatch ? Icons.check_circle : Icons.cancel,
            color: passwordsMatch ? Colors.green : Colors.red,
            size: textSize * 1.2,
          ),
          const SizedBox(width: 8),
          Text(
            passwordsMatch ? 'Passwords match' : 'Passwords do not match',
            style: TextStyle(
              color: passwordsMatch ? Colors.green : Colors.red,
              fontSize: textSize * 0.85,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailValidationIndicator(double textSize) {
    Color indicatorColor;
    IconData icon;

    if (isCheckingEmail) {
      indicatorColor = Colors.blue;
      icon = Icons.hourglass_empty;
    } else if (isEmailAvailable == true) {
      indicatorColor = Colors.green;
      icon = Icons.check_circle;
    } else {
      indicatorColor = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1E2330),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: indicatorColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          if (isCheckingEmail)
            SizedBox(
              width: textSize * 1.2,
              height: textSize * 1.2,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            )
          else
            Icon(
              icon,
              color: indicatorColor,
              size: textSize * 1.2,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              emailValidationMessage ?? '',
              style: TextStyle(
                color: indicatorColor,
                fontSize: textSize * 0.85,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions(double textSize) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.3,
          child: Checkbox(
            value: acceptedTerms,
            onChanged: (value) {
              setState(() {
                acceptedTerms = value ?? false;
              });
            },
            activeColor: Colors.grey[600],
            checkColor: Colors.white70,
            side: BorderSide(color: Colors.grey[500]!, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showTermsAndConditionsDialog();
            },
            child: Text(
              'I Accept the Terms and Conditions',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: textSize * 1.0,
                decoration: TextDecoration.underline,
                decorationColor: Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsAndConditionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff2A303E),
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to ReXplore!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'By using this application, you agree to the following terms and conditions:',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                const SizedBox(height: 15),
                _buildTermItem(
                  '1. Account Registration',
                  'You must be at least 16 years old to register. All information provided must be accurate and up-to-date.',
                ),
                _buildTermItem(
                  '2. Privacy',
                  'We collect and store your personal information securely. Your data will not be shared with third parties without your consent.',
                ),
                _buildTermItem(
                  '3. User Conduct',
                  'You agree to use this application responsibly and not engage in any activities that may harm other users or the service.',
                ),
                _buildTermItem(
                  '4. Intellectual Property',
                  'All content and features in this app are owned by ReXplore and protected by intellectual property laws.',
                ),
                _buildTermItem(
                  '5. Limitation of Liability',
                  'ReXplore is not liable for any damages arising from the use of this application.',
                ),
                _buildTermItem(
                  '6. Changes to Terms',
                  'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of any changes.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Last updated: October 24, 2025',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  acceptedTerms = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
