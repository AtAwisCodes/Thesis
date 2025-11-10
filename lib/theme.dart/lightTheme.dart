import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Elegant Light Theme - Professional & Consistent Color Palette
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,

  // Color Scheme - Elegant & Consistent
  colorScheme: const ColorScheme.light(
    primary: Color(0xff5BEC84), // Primary Green
    onPrimary: Color(0xff1A1A1A), // Dark text on primary
    secondary: Color(0xff2D6A4F), // Secondary Dark Green
    onSecondary: Colors.white, // White text on secondary
    tertiary: Color(0xff40916C), // Tertiary Medium Green
    error: Color(0xffE63946), // Error Red
    onError: Colors.white,
    surface: Colors.white, // Card/Surface color
    onSurface: Color(0xff1A1A1A), // Text on surface
    surfaceContainerHighest: Color(0xffF5F5F5), // Subtle background
    outline: Color(0xffE0E0E0), // Border color
    shadow: Color(0xff000000),
  ),

  scaffoldBackgroundColor: const Color(0xffFAFAFA),

  // AppBar - Clean & Elegant
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xff1A1A1A),
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: Color(0xff2D6A4F), size: 24),
    titleTextStyle: GoogleFonts.inter(
      color: const Color(0xff1A1A1A),
      fontWeight: FontWeight.w600,
      fontSize: 20,
      letterSpacing: -0.5,
    ),
  ),

  // Card - Elevated & Clean
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colors.black.withOpacity(0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

  // Icons - Consistent
  iconTheme: const IconThemeData(
    color: Color(0xff2D6A4F),
    size: 24,
  ),

  // Text - Professional Typography with Inter Font
  textTheme: GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        color: Color(0xff1A1A1A),
        fontWeight: FontWeight.bold,
        fontSize: 32,
        letterSpacing: -1,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        color: Color(0xff1A1A1A),
        fontWeight: FontWeight.bold,
        fontSize: 28,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: Color(0xff1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: Color(0xff1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        color: Color(0xff1A1A1A),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: Color(0xff4A4A4A),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: Color(0xff757575),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: Color(0xff1A1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.4,
      ),
    ),
  ),

  // Buttons - Elegant & Consistent
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xff5BEC84),
      foregroundColor: const Color(0xff1A1A1A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xff2D6A4F),
      side: const BorderSide(color: Color(0xff5BEC84), width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xff2D6A4F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
    ),
  ),

  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: const Color(0xff2D6A4F),
      iconSize: 24,
    ),
  ),

  // Input Fields - Clean & Consistent
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xffF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffE0E0E0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xff5BEC84), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffE63946), width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: GoogleFonts.inter(
      color: const Color(0xff9E9E9E),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: GoogleFonts.inter(
      color: const Color(0xff2D6A4F),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),

  // Switch - Elegant
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xff5BEC84);
      }
      return const Color(0xffBDBDBD);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xff5BEC84).withOpacity(0.5);
      }
      return const Color(0xffE0E0E0);
    }),
  ),

  // Floating Action Button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xff5BEC84),
    foregroundColor: Color(0xff1A1A1A),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: Color(0xffE0E0E0),
    thickness: 1,
    space: 1,
  ),

  // Bottom Navigation Bar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xff5BEC84),
    unselectedItemColor: const Color(0xff9E9E9E),
    selectedLabelStyle: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);
