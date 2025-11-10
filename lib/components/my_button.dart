import 'package:flutter/material.dart';
import 'package:rexplore/utilities/responsive_helper.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsive.padding(all: 15),
        margin: responsive.padding(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(responsive.borderRadius(20)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: responsive.fontSize(16),
            ),
          ),
        ),
      ),
    );
  }
}
