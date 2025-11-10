import 'package:flutter/material.dart';

/// Responsive helper utility for consistent sizing across different screen sizes
class ResponsiveHelper {
  final BuildContext context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _screenDiagonal;
  late final bool _isSmallScreen;
  late final bool _isMediumScreen;
  late final bool _isLargeScreen;

  ResponsiveHelper(this.context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _screenDiagonal = _calculateDiagonal(_screenWidth, _screenHeight);

    // Define screen size categories based on width
    _isSmallScreen = _screenWidth < 360;
    _isMediumScreen = _screenWidth >= 360 && _screenWidth < 400;
    _isLargeScreen = _screenWidth >= 400;
  }

  double _calculateDiagonal(double width, double height) {
    return (width * width + height * height);
  }

  /// Screen width
  double get screenWidth => _screenWidth;

  /// Screen height
  double get screenHeight => _screenHeight;

  /// Screen diagonal (squared for performance)
  double get screenDiagonal => _screenDiagonal;

  /// Check if device has small screen (< 360dp)
  bool get isSmallScreen => _isSmallScreen;

  /// Check if device has medium screen (360dp - 400dp)
  bool get isMediumScreen => _isMediumScreen;

  /// Check if device has large screen (> 400dp)
  bool get isLargeScreen => _isLargeScreen;

  /// Get responsive width based on percentage of screen width
  double widthPercentage(double percentage) {
    return _screenWidth * (percentage / 100);
  }

  /// Get responsive height based on percentage of screen height
  double heightPercentage(double percentage) {
    return _screenHeight * (percentage / 100);
  }

  /// Get responsive font size
  /// Base size is for a standard 360dp width screen
  double fontSize(double baseSize) {
    final scaleFactor = _screenWidth / 360;
    return baseSize * scaleFactor.clamp(0.8, 1.3);
  }

  /// Get responsive spacing
  double spacing(double baseSpacing) {
    final scaleFactor = _screenWidth / 360;
    return baseSpacing * scaleFactor.clamp(0.85, 1.2);
  }

  /// Get responsive padding
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(spacing(all));
    }
    return EdgeInsets.only(
      left: spacing(left ?? horizontal ?? 0),
      top: spacing(top ?? vertical ?? 0),
      right: spacing(right ?? horizontal ?? 0),
      bottom: spacing(bottom ?? vertical ?? 0),
    );
  }

  /// Get responsive icon size
  double iconSize(double baseSize) {
    final scaleFactor = _screenWidth / 360;
    return baseSize * scaleFactor.clamp(0.85, 1.2);
  }

  /// Get responsive border radius
  double borderRadius(double baseRadius) {
    final scaleFactor = _screenWidth / 360;
    return baseRadius * scaleFactor.clamp(0.9, 1.1);
  }

  /// Get responsive size based on screen type
  double responsiveSize({
    required double small,
    required double medium,
    required double large,
  }) {
    if (_isSmallScreen) return small;
    if (_isMediumScreen) return medium;
    return large;
  }

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(context).padding;

  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(context).viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Get orientation
  Orientation get orientation => MediaQuery.of(context).orientation;

  /// Check if portrait orientation
  bool get isPortrait => orientation == Orientation.portrait;

  /// Check if landscape orientation
  bool get isLandscape => orientation == Orientation.landscape;

  /// Get device pixel ratio
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  /// Calculate responsive button height
  double get buttonHeight => responsiveSize(
        small: 45,
        medium: 50,
        large: 56,
      );

  /// Calculate responsive app bar height
  double get appBarHeight => responsiveSize(
        small: 56,
        medium: 60,
        large: 64,
      );

  /// Calculate responsive bottom nav bar height
  double get bottomNavHeight => responsiveSize(
        small: 60,
        medium: 70,
        large: 80,
      );

  /// Calculate responsive card padding
  EdgeInsets get cardPadding => padding(
        horizontal: responsiveSize(small: 12, medium: 16, large: 20),
        vertical: responsiveSize(small: 12, medium: 16, large: 20),
      );

  /// Calculate responsive list tile height
  double get listTileHeight => responsiveSize(
        small: 60,
        medium: 70,
        large: 80,
      );
}

/// Extension on BuildContext for easier access to ResponsiveHelper
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

/// Responsive text styles helper
class ResponsiveText {
  final ResponsiveHelper responsive;

  ResponsiveText(this.responsive);

  /// Get responsive display large text style
  TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!.copyWith(
          fontSize: responsive.fontSize(32),
        );
  }

  /// Get responsive display medium text style
  TextStyle displayMedium(BuildContext context) {
    return Theme.of(context).textTheme.displayMedium!.copyWith(
          fontSize: responsive.fontSize(28),
        );
  }

  /// Get responsive display small text style
  TextStyle displaySmall(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: responsive.fontSize(24),
        );
  }

  /// Get responsive headline large text style
  TextStyle headlineLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
          fontSize: responsive.fontSize(22),
        );
  }

  /// Get responsive headline medium text style
  TextStyle headlineMedium(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: responsive.fontSize(20),
        );
  }

  /// Get responsive headline small text style
  TextStyle headlineSmall(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontSize: responsive.fontSize(18),
        );
  }

  /// Get responsive title large text style
  TextStyle titleLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          fontSize: responsive.fontSize(18),
        );
  }

  /// Get responsive title medium text style
  TextStyle titleMedium(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontSize: responsive.fontSize(16),
        );
  }

  /// Get responsive title small text style
  TextStyle titleSmall(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          fontSize: responsive.fontSize(14),
        );
  }

  /// Get responsive body large text style
  TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: responsive.fontSize(16),
        );
  }

  /// Get responsive body medium text style
  TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: responsive.fontSize(14),
        );
  }

  /// Get responsive body small text style
  TextStyle bodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          fontSize: responsive.fontSize(12),
        );
  }

  /// Get responsive label large text style
  TextStyle labelLarge(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: responsive.fontSize(14),
        );
  }

  /// Get responsive label medium text style
  TextStyle labelMedium(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          fontSize: responsive.fontSize(12),
        );
  }

  /// Get responsive label small text style
  TextStyle labelSmall(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: responsive.fontSize(10),
        );
  }
}
