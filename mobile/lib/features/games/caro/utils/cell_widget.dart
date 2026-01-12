import 'package:flutter/material.dart';
import 'game_state.dart';

class CellWidget extends StatefulWidget {
  final CellState cellState;
  final VoidCallback onTap;
  final bool isHint;
  final bool isWinningCell;
  final bool isAIMove;
  final int row;
  final int col;
  final int boardSize;

  const CellWidget({
    super.key,
    required this.cellState,
    required this.onTap,
    this.isWinningCell = false,
    this.isHint = false,
    this.isAIMove = false,
    required this.row,
    required this.col,
    required this.boardSize,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.cellState != CellState.empty) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cellState != oldWidget.cellState &&
        widget.cellState != CellState.empty) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.cellState == CellState.empty ? widget.onTap : null,
      child: Container(
        decoration: BoxDecoration(color: _getCellColor(), border: _getBorder()),
        child: Center(child: _buildSymbol()),
      ),
    );
  }

  Color _getCellColor() {
    if (widget.isWinningCell) {
      return const Color(0x90FFD700); // Màu vàng cho winning cell
    } else if (widget.isHint) {
      return const Color(0x354CAF50); // Màu xanh lá cho hint
    } else {
      return Colors.white.withOpacity(0.1); // Màu trắng trong suốt
    }
  }

  Border _getBorder() {
    if (widget.isWinningCell) {
      return Border.all(color: Colors.amber.shade400, width: 3);
    }

    if (widget.isAIMove) {
      return Border.all(color: Colors.blue.shade400, width: 2);
    }

    // Uniform borders for all cells - no thick/thin distinction
    return Border.all(color: Colors.white.withOpacity(0.3), width: 1);
  }

  Widget _buildSymbol() {
    if (widget.cellState == CellState.empty) {
      return widget.isHint
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (_animationController.value * 0.5),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green.shade400,
                    size: 18,
                  ),
                );
              },
            )
          : const SizedBox();
    }

    final isX = widget.cellState == CellState.x;
    final String assetPath = isX
        ? 'assets/caro/icon_x.jpg'
        : 'assets/caro/icon_o.jpg';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Icon should fit nicely inside the cell with small padding
              final double size = (constraints.biggest.shortestSide * 0.72)
                  .clamp(12.0, 26.0);
              return Center(
                child: Image.asset(
                  assetPath,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
