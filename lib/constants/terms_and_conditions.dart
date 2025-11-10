/// Terms and Conditions constants for ReXplore application
/// This file contains all terms and conditions content for reusability across the app

class TermsAndConditions {
  // Last updated date
  static const String lastUpdated = 'November 11, 2025';

  // Welcome message
  static const String welcomeTitle = 'Welcome to ReXplore!';
  static const String welcomeMessage =
      'By using this application, you agree to the following terms and conditions:';

  // Terms items
  static const List<TermItem> terms = [
    TermItem(
      title: '1. Account Registration',
      description:
          'You must be at least 16 years old to register. All information provided must be accurate and up-to-date.',
    ),
    TermItem(
      title: '2. Privacy',
      description:
          'We collect and store your personal information securely. Your data will not be shared with third parties without your consent.',
    ),
    TermItem(
      title: '3. User Conduct',
      description:
          'You agree to use this application responsibly and not engage in any activities that may harm other users or the service.',
    ),
    TermItem(
      title: '4. Intellectual Property',
      description:
          'All content and features in this app are owned by ReXplore and protected by intellectual property laws.',
    ),
    TermItem(
      title: '5. Limitation of Liability',
      description:
          'ReXplore is not liable for any damages arising from the use of this application.',
    ),
    TermItem(
      title: '6. Changes to Terms',
      description:
          'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of any changes.',
    ),
  ];

  // Get full terms and conditions text (for text-only displays)
  static String getFullText() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(welcomeTitle);
    buffer.writeln();
    buffer.writeln(welcomeMessage);
    buffer.writeln();

    for (final term in terms) {
      buffer.writeln(term.title);
      buffer.writeln(term.description);
      buffer.writeln();
    }

    buffer.writeln('Last updated: $lastUpdated');
    return buffer.toString();
  }
}

/// Model class for individual term items
class TermItem {
  final String title;
  final String description;

  const TermItem({
    required this.title,
    required this.description,
  });
}
