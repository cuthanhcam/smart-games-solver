import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  
  const AppLogo({
    super.key,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF57BCCE),
        shape: BoxShape.circle, // Hình tròn hoàn hảo
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57BCCE).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.1), // Padding hợp lý cho hình tròn
          child: Icon(
            Icons.games,
            size: size * 0.6, // Size phù hợp với hình tròn
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
