import 'package:flutter/material.dart';
import 'screens/rubik_color_picker_screen.dart';

/// 🎮 Rubik Game Main Entry Point (Kociemba-style)
class RubikMain extends StatelessWidget {
  const RubikMain({super.key});

  @override
  Widget build(BuildContext context) {
    return const RubikColorPickerScreen();
  }
}