import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rexplore/constants/input_limits.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

class MyTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLength;
  final bool enforceLimit;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.maxLength,
    this.enforceLimit = true, // Default to enforcing limits
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

  // Get max length based on hint text
  int? _getMaxLength() {
    // If enforceLimit is false, don't apply any limits
    if (!widget.enforceLimit) return null;

    if (widget.maxLength != null) return widget.maxLength;

    switch (widget.hintText.toLowerCase()) {
      case 'email':
        return InputLimits.email;
      case 'password':
      case 'confirm password':
        return InputLimits.password;
      case 'first name':
        return InputLimits.firstName;
      case 'last name':
        return InputLimits.lastName;
      case 'middle initial':
        return InputLimits.middleInitial;
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

    return null; // Valid
  }

  @override
  Widget build(BuildContext context) {
    final maxLen = _getMaxLength();
    final responsive = context.responsive;

    return Padding(
      padding: responsive.padding(horizontal: 25, vertical: 8),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        style: TextStyle(
          color: Colors.white,
          fontSize: responsive.fontSize(14),
        ),
        cursorColor: Colors.blueAccent,
        validator: _validatePassword,
        maxLength: maxLen,
        inputFormatters:
            maxLen != null ? [LengthLimitingTextInputFormatter(maxLen)] : null,
        decoration: InputDecoration(
          labelText: widget.hintText,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: _getPrefixIcon(widget.hintText),

          // Hide the default counter for a cleaner look
          counterText: '',

          suffixIcon: (widget.hintText.toLowerCase() == "password" ||
                  widget.hintText.toLowerCase() == "confirm password")
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: responsive.iconSize(20),
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
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A3C),
          contentPadding: responsive.padding(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
