import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1E1E1E),
  primaryColor: const Color(0xFF5BEC84),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2A303E),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
  ),
  iconTheme: const IconThemeData(color: Colors.white70),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white70),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(Color(0xFF5BEC84)),
    trackColor: MaterialStateProperty.all(Color(0xFF37474F)),
  ),
);
