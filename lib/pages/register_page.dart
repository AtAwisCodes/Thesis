import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/components/error_notification.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/services/auth_service.dart';
import 'package:rexplore/services/email_verification_service.dart';
import 'package:rexplore/utilities/disposable_email_checker.dart';
import 'package:rexplore/utilities/email_verification.dart';
import 'package:rexplore/constants/terms_and_conditions.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

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
      ErrorNotification.show(context, "Please enter an email address");
      return;
    }

    // Validate email format
    if (!EmailVerification.isValidEmailFormat(emailText)) {
      ErrorNotification.show(context, "Please enter a valid email address");
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

    // Check if email is already registered
    try {
      final isAvailable = await EmailVerification.isEmailAvailable(emailText);
      if (!isAvailable) {
        ErrorNotification.show(
          context,
          "This email is already registered.\nPlease use a different email or try logging in.",
        );
        return;
      }
    } catch (e) {
      ErrorNotification.show(
          context, "Error verifying email. Please try again");
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
        ErrorNotification.show(context, "Invalid date of birth format");
        return;
      }
    } catch (e) {
      ErrorNotification.show(context, "Invalid date of birth");
      return;
    }

    int userAge = calculateAge(dob);

    // Age restriction check
    if (userAge < 16) {
      ErrorNotification.show(
        context,
        "You must be at least 16 years old to register",
      );
      return;
    }

    // Check password requirements
    if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasNumber ||
        !hasSpecialChar) {
      ErrorNotification.show(context, "Please meet all password requirements");
      return;
    }

    // Confirm password match
    if (password != confirmPassword) {
      ErrorNotification.show(context, "Passwords do not match");
      return;
    }

    // Check if terms and conditions are accepted
    if (!acceptedTerms) {
      ErrorNotification.show(
          context, "Please accept the Terms and Conditions to continue");
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

      // Verify user was created
      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Send email verification using the service
      await EmailVerificationService()
          .sendVerificationEmail(userCredential.user!);

      // Add user to Firestore (pass UID directly to avoid race condition)
      final success = await FirebaseService().addUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: userAge,
        email: emailText,
        uid: userCredential.user!.uid, // Pass UID directly
      );

      if (!success) {
        throw Exception('Failed to create user profile in database');
      }

      // Store the registered email and password for resend functionality
      final String registeredEmail = emailText;
      final String registeredPassword = password;

      // Sign out the user immediately to prevent login without verification
      await FirebaseAuth.instance.signOut();

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
                  registeredEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your inbox and click the verification link to activate your account. You must verify your email before you can log in.',
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
                  // Resend verification email using the service
                  try {
                    await EmailVerificationService().resendVerificationEmail(
                      email: registeredEmail,
                      password: registeredPassword,
                    );

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
                  // Close the verification dialog
                  Navigator.of(context).pop();

                  // Schedule the page toggle for the next frame to ensure clean state transition
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onTap?.call();
                  });
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
      ErrorNotification.show(context, "Registration failed. Please try again");
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
                  'Sign Up',
                  style: textHelper.headlineLarge(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(24)),
                MyTextfield(
                  controller: lastNameController,
                  hintText: 'Last Name',
                  obscureText: false,
                ),
                SizedBox(height: responsive.spacing(12)),
                MyTextfield(
                  controller: firstNameController,
                  hintText: 'First Name',
                  obscureText: false,
                ),
                SizedBox(height: responsive.spacing(12)),
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
                SizedBox(height: responsive.spacing(12)),
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                if (emailValidationMessage != null) ...[
                  SizedBox(height: responsive.spacing(8)),
                  _buildEmailValidationIndicator(responsive.fontSize(14)),
                ],
                SizedBox(height: responsive.spacing(12)),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                if (showPasswordRequirements) ...[
                  SizedBox(height: responsive.spacing(8)),
                  _buildPasswordRequirements(responsive.fontSize(14)),
                ],
                SizedBox(height: responsive.spacing(12)),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                if (confirmPasswordController.text.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(8)),
                  _buildPasswordMatchIndicator(responsive.fontSize(14)),
                ],
                SizedBox(height: responsive.spacing(12)),
                _buildTermsAndConditions(responsive.fontSize(14)),
                SizedBox(height: responsive.spacing(12)),
                MyButton(
                  text: "Create Account",
                  onTap: createAccount,
                ),
                SizedBox(height: responsive.spacing(24)),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.white),
                    ),
                    Padding(
                      padding: responsive.padding(horizontal: 12),
                      child: const Text('Or continue with',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const Expanded(
                      child: Divider(thickness: 1, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),
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
                            ErrorNotification.show(
                              context,
                              'Unable to sign in with Google. Please try again.',
                            );
                          }
                        }
                      },
                      imagePath: 'lib/icons/Google.png',
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: responsive.fontSize(14),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize(14),
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
                  TermsAndConditions.welcomeTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  TermsAndConditions.welcomeMessage,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                const SizedBox(height: 15),
                ...TermsAndConditions.terms.map(
                  (term) => _buildTermItem(term.title, term.description),
                ),
                const SizedBox(height: 10),
                Text(
                  'Last updated: ${TermsAndConditions.lastUpdated}',
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
