/// Character limits for all input fields in the application
class InputLimits {
  // Authentication fields
  static const int email = 100; // Reduced from 254 for signup
  static const int password = 64; // Reduced from 128 for signup
  static const int firstName = 30; // Reduced from 50
  static const int lastName = 30; // Reduced from 50
  static const int middleInitial = 1;

  // Profile fields
  static const int displayName = 25;
  static const int bio = 50;

  // Video fields
  static const int videoTitle = 100;
  static const int videoDescription = 2000;
  static const int videoSteps = 3000;

  // Comment fields
  static const int comment = 500;

  // Report fields
  static const int reportDescription = 500;
  static const int warningMessage = 1000;

  // Search
  static const int searchQuery = 100;
}
