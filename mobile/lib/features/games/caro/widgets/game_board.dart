import 'package:flutter/material.dart';
import '../utils/game_state.dart';
import '../utils/cell_widget.dart';
import '../utils/grid_painter.dart';

class GameBoard extends StatefulWidget {
  final GameState gameState;
  final Function(int, int) onCellTap;
  final List<int>? hintMove;
  final List<int>? lastAIMove;

  const GameBoard({
    super.key,
    required this.gameState,
    required this.onCellTap,
    this.hintMove,
    this.lastAIMove,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TransformationController _transformController =
      TransformationController();
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.gameState.board.length;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final double cellSize = 36.0;
        final double boardPixels = size * cellSize;
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Center the board once after layout
              if (!_hasCenteredOnce) {
                final double viewportW = constraints.maxWidth;
                final double viewportH = constraints.maxHeight;
                final double dx = (viewportW - boardPixels) / 2;
                final double dy = (viewportH - boardPixels) / 2;
                final Matrix4 m = Matrix4.identity()..translate(dx, dy);
                _transformController.value = m;
                _hasCenteredOnce = true;
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.3,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(200),
                  constrained: false,
                  child: SizedBox(
                    width: boardPixels,
                    height: boardPixels,
                    child: GridView.builder(
                      itemCount: size * size,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: size,
                      ),
                      itemBuilder: (context, index) {
                        final row = index ~/ size;
                        final col = index % size;
                        final isWinningCell = widget.gameState.winningLine.any(
                          (pos) => pos[0] == row && pos[1] == col,
                        );
                        final isHint =
                            widget.hintMove != null &&
                            widget.hintMove![0] == row &&
                            widget.hintMove![1] == col;

                        return CellWidget(
                          cellState: widget.gameState.board[row][col],
                          onTap: () => widget.onCellTap(row, col),
                          isWinningCell: isWinningCell,
                          isHint: isHint,
                          isAIMove:
                              widget.lastAIMove != null &&
                              widget.lastAIMove![0] == row &&
                              widget.lastAIMove![1] == col,
                          row: row,
                          col: col,
                          boardSize: size,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
