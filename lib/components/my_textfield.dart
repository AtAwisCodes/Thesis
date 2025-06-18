import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  Icon? _getPrefixIcon(String hintText) {
    switch (hintText.toLowerCase()) {
      case 'email':
        return const Icon(Icons.email, color: Colors.grey);
      case 'password':
      case 'confirm password':
        return const Icon(Icons.lock, color: Colors.grey);
      case 'date of birth (mm/dd/yyyy)':
        return const Icon(Icons.calendar_today, color: Colors.grey);
      case 'first name':
      case 'last name':
      case 'middle initial':
        return const Icon(Icons.person, color: Colors.grey);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.blueAccent,
        decoration: InputDecoration(
          labelText: hintText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: _getPrefixIcon(hintText),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A3C), // updated dark tone
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
