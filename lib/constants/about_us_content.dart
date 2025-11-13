/// About Us Content for ReXplore
/// This file contains reusable information about the ReXplore application
class AboutUsContent {
  static const String appName = 'ReXplore';

  static const String tagline = 'Recycling Made Smart with AR & AI';

  static const String description =
      'ReXplore is an innovative mobile application that combines Augmented Reality (AR) '
      'and Artificial Intelligence (AI) to revolutionize recycling education and practice. '
      'Our mission is to make recycling accessible, educational, and engaging for everyone.';

  static const String mission =
      'Our mission is to empower individuals and communities to make informed recycling '
      'decisions through cutting-edge technology, promoting environmental sustainability '
      'and reducing waste one item at a time.';

  static const String vision =
      'We envision a world where everyone has the knowledge and tools to recycle correctly, '
      'creating a sustainable future for generations to come.';

  static const List<Feature> features = [
    Feature(
      icon: '📷',
      title: 'AI Image Recognition',
      description:
          'Instantly identify recyclable materials using advanced AI technology. '
          'Simply take a photo and let our AI guide you on proper disposal.',
    ),
    Feature(
      icon: '🥽',
      title: 'Augmented Reality',
      description:
          'Experience interactive 2D models of recyclable items in AR. '
          'Learn how materials are processed and understand their environmental impact.',
    ),
    Feature(
      icon: '📚',
      title: 'Educational Content',
      description:
          'Access a comprehensive library of recycling guides, tutorials, '
          'and best practices to become a recycling expert.',
    ),
    Feature(
      icon: '🌍',
      title: 'Environmental Impact',
      description:
          'Track your recycling contributions and see the positive impact '
          'you\'re making on the environment.',
    ),
    Feature(
      icon: '💡',
      title: 'Smart Recommendations',
      description:
          'Get personalized tips and recommendations based on your recycling '
          'habits and local recycling programs.',
    ),
    Feature(
      icon: '👥',
      title: 'Community Driven',
      description: 'Join a community of environmentally conscious individuals, '
          'share knowledge, and inspire others to recycle.',
    ),
  ];

  static const String developedBy = 'Rexplore Team';

  static const String version = '1.0.0';

  static const String copyright = '© 2025 ReXplore. All rights reserved.';

  static const String contactEmail = 'rexplore@gmail.com';

  static const List<String> technologies = [
    'Flutter',
    'Firebase',
    'TensorFlow Lite',
    'AR Flutter Plugin',
    'Cloud Firestore',
  ];

  static const String disclaimer =
      'ReXplore provides recycling information based on general guidelines. '
      'Please check with your local recycling center for specific regulations '
      'in your area as recycling rules may vary by location.';
}

/// Feature model for About Us content
class Feature {
  final String icon;
  final String title;
  final String description;

  const Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
