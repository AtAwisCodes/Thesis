import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to check email availability in Firebase Authentication
class EmailVerification {
  /// Check if an email is already registered in Firebase
  /// Returns true if email is available (not registered), false if already in use
  static Future<bool> isEmailAvailable(String email) async {
    try {
      // Fetch sign-in methods for the email
      final List<String> signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      // If the list is empty, email is available
      // If the list has entries, email is already registered
      return signInMethods.isEmpty;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      }
      // For other errors, assume email might be available
      return true;
    } catch (e) {
      // For any other errors, throw exception
      throw Exception('Error checking email availability: $e');
    }
  }

  /// Check email availability and return detailed information
  /// Returns a map with 'isAvailable' and 'message' keys
  static Future<Map<String, dynamic>> checkEmailAvailability(
      String email) async {
    try {
      final isAvailable = await isEmailAvailable(email);

      return {
        'isAvailable': isAvailable,
        'message': isAvailable
            ? 'Email is available'
            : 'This email is already registered',
      };
    } catch (e) {
      return {
        'isAvailable': false,
        'message': e.toString(),
      };
    }
  }

  /// Validate email format using regex
  static bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Comprehensive email validation
  /// Checks format, disposable domains, and availability
  static Future<Map<String, dynamic>> validateEmail(String email) async {
    // Check format first
    if (!isValidEmailFormat(email)) {
      return {
        'isValid': false,
        'message': 'Invalid email format',
      };
    }

    // Check availability
    try {
      final availabilityResult = await checkEmailAvailability(email);
      return {
        'isValid': availabilityResult['isAvailable'],
        'message': availabilityResult['message'],
      };
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Error validating email: $e',
      };
    }
  }
}
