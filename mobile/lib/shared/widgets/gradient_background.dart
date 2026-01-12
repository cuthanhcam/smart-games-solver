// Gradient Background Widget
// Reusable gradient background for screens

import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              colors ??
              [
                const Color(0xFFDEE8FF),
                const Color(0xFFEAF0FF),
                const Color(0xFFF7F9FF),
              ],
        ),
      ),
      child: child,
    );
  }
}
