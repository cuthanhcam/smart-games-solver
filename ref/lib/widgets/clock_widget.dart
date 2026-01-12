import 'package:flutter/material.dart';

class ClockWidget extends StatelessWidget {
  final double fontSize;
  final Color textColor;

  const ClockWidget({
    super.key,
    this.fontSize = 36,
    this.textColor = const Color(0xFF2D3748),
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final timeString = _formatTime(now);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF57BCCE),
                Color(0xFFA8D3CA),
                Color(0xFFDADCB7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF57BCCE).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF57BCCE).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeSegment(timeString.substring(0, 2), 'GIỜ'),
              const SizedBox(width: 6),
              _buildSeparator(),
              const SizedBox(width: 6),
              _buildTimeSegment(timeString.substring(3, 5), 'PHÚT'),
              const SizedBox(width: 6),
              _buildSeparator(),
              const SizedBox(width: 6),
              _buildTimeSegment(timeString.substring(6, 8), 'GIÂY'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSegment(String time, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: fontSize * 0.3,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Text(
      ':',
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
