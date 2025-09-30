import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

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

  // Password validator (Goal 2)
  String? _validatePassword(String? value) {
    if (widget.hintText.toLowerCase() != "password" &&
        widget.hintText.toLowerCase() != "confirm password") {
      return null; // Only validate password fields
    }

    String password = value ?? "";

    // Minimum length 11
    if (password.length < 11) {
      return "Password must be at least 11 characters long";
    }

    // Uppercase
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter";
    }

    // Lowercase
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter";
    }

    // Number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number";
    }

    // Special character
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Password must contain at least one special character";
    }

    return null; // ✅ Valid
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.blueAccent,
        validator: _validatePassword, // Apply validation (Goal 2)
        decoration: InputDecoration(
          labelText: widget.hintText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: _getPrefixIcon(widget.hintText),

          // Goal 1: Eye toggle only for password fields
          suffixIcon: (widget.hintText.toLowerCase() == "password" ||
                  widget.hintText.toLowerCase() == "confirm password")
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,

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
