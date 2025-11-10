import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationService {
  // Singleton pattern
  static final EmailVerificationService _instance =
      EmailVerificationService._internal();

  factory EmailVerificationService() {
    return _instance;
  }

  EmailVerificationService._internal();

  /// Send email verification to the current user (using default Firebase settings)
  Future<void> sendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send verification email: ${e.toString()}');
    }
  }

  /// Resend verification email by temporarily signing in with credentials
  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in temporarily to resend email
      UserCredential tempCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (tempCredential.user == null) {
        throw Exception('Failed to authenticate user');
      }

      // Send verification email
      await sendVerificationEmail(tempCredential.user!);

      // Sign out again
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Failed to resend verification email: ${e.toString()}');
    }
  }

  // Check if user's email is verified
  Future<bool> isEmailVerified(User user) async {
    await user.reload();
    return user.emailVerified;
  }

  // Wait for email verification with polling
  // Returns true if verified, false if timeout
  Future<bool> waitForEmailVerification({
    required User user,
    Duration timeout = const Duration(minutes: 5),
    Duration checkInterval = const Duration(seconds: 3),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await Future.delayed(checkInterval);

      if (await isEmailVerified(user)) {
        return true;
      }
    }

    return false;
  }
}
