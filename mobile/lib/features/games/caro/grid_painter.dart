import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final int gridSize;
  final List<List<int>> board;
  final List<List<int>> winningLine;

  GridPainter({
    required this.gridSize,
    required this.board,
    required this.winningLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A90E2) // Light blue grid lines
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cellSize = size.width / gridSize;

    // Draw grid lines
    for (int i = 0; i <= gridSize; i++) {
      final offset = i * cellSize;
      
      // Vertical lines
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        paint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset),
        paint,
      );
    }


    // Draw game pieces
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (board[row][col] != -1) {
          final x = col * cellSize + cellSize / 2;
          final y = row * cellSize + cellSize / 2;
          final radius = cellSize * 0.35;

          final piecePaint = Paint()
            ..style = PaintingStyle.fill;

          if (board[row][col] == 0) { // O (AI)
            piecePaint.color = const Color(0xFFE91E63); // Pink
          } else { // X (Player)
            piecePaint.color = const Color(0xFF2196F3); // Blue
          }

          canvas.drawCircle(Offset(x, y), radius, piecePaint);

          // Draw symbol
          final textPainter = TextPainter(
            text: TextSpan(
              text: board[row][col] == 0 ? 'O' : 'X',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              x - textPainter.width / 2,
              y - textPainter.height / 2,
            ),
          );
        }
      }
    }

    // Draw winning line
    if (winningLine.isNotEmpty) {
      final winningPaint = Paint()
        ..color = const Color(0xFFFFD700) // Gold
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;

      final startPos = winningLine.first;
      final endPos = winningLine.last;
      
      final startX = startPos[1] * cellSize + cellSize / 2;
      final startY = startPos[0] * cellSize + cellSize / 2;
      final endX = endPos[1] * cellSize + cellSize / 2;
      final endY = endPos[0] * cellSize + cellSize / 2;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        winningPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
