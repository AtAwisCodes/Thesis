import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF9F9F9),
  primaryColor: const Color(0xFF2A303E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2A303E),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
  ),
  iconTheme: const IconThemeData(color: Colors.black54),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(Color(0xFF2A303E)),
    trackColor: MaterialStateProperty.all(Color(0xFFB0BEC5)),
  ),
);
