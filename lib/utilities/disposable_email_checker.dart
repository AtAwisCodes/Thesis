import 'package:flutter/services.dart';

/// Utility class to check if an email address uses a disposable email domain
class DisposableEmailChecker {
  static Set<String>? _disposableDomains;

  /// Load the disposable email domains list from assets
  static Future<void> loadDisposableDomains() async {
    if (_disposableDomains != null) return; // Already loaded

    try {
      final String fileContent =
          await rootBundle.loadString('assets/disposable_email_blocklist.txt');
      _disposableDomains = fileContent
          .split('\n')
          .map((line) => line.trim().toLowerCase())
          .where((line) => line.isNotEmpty)
          .toSet();
    } catch (e) {
      // If loading fails, initialize with empty set to prevent crashes
      _disposableDomains = {};
      print('Error loading disposable email domains: $e');
    }
  }

  /// Check if an email address uses a disposable domain
  /// Returns true if the email is disposable, false otherwise
  static Future<bool> isDisposable(String email) async {
    // Ensure domains are loaded
    await loadDisposableDomains();

    if (email.isEmpty || !email.contains('@')) {
      return false; // Invalid email format
    }

    // Extract domain from email
    final domain = email.split('@').last.toLowerCase().trim();

    // Check if domain is in blocklist
    return _disposableDomains?.contains(domain) ?? false;
  }

  /// Check if an email address uses a disposable domain and get the domain name
  /// Returns a map with 'isDisposable' and 'domain' keys
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final domain =
        email.contains('@') ? email.split('@').last.toLowerCase().trim() : '';
    final bool disposable = await isDisposable(email);

    return {
      'isDisposable': disposable,
      'domain': domain,
    };
  }
}
