// Game 2048 Screen
// Classic 2048 sliding puzzle game

import 'package:flutter/material.dart';
import '../../../../shared/models/game_2048.dart';
import '../services/game_2048_service.dart';
import '../utils/game_2048_logic.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  List<List<int>> _grid = [];
  int _score = 0;
  int _moves = 0;
  bool _gameOver = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _grid = Game2048Logic.createInitialGrid();
      _score = 0;
      _moves = 0;
      _gameOver = false;
      _won = false;
    });
  }

  void _makeMove(String direction) {
    if (_gameOver) return;

    final result = Game2048Logic.makeMove(_grid, direction);

    if (result['moved'] as bool) {
      setState(() {
        _grid = result['grid'] as List<List<int>>;
        _score += result['points'] as int;
        _moves++;
        _gameOver = result['gameOver'] as bool;

        // Check for win
        if (!_won && result['won'] as bool) {
          _won = true;
          Future.delayed(const Duration(milliseconds: 300), _showWinDialog);
        }
      });

      if (_gameOver) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _showGameOverDialog();
          _saveScore();
        });
      }
    }
  }

  Future<void> _saveScore() async {
    try {
      await Game2048Service.saveScore(score: _score, moves: _moves, won: _won);
    } catch (e) {
      // Silently fail - score saving is not critical
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Your score: $_score\nMoves: $_moves'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('New Game'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 You Won!'),
        content: Text('You reached 2048!\nScore: $_score\nMoves: $_moves'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('New Game'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Playing'),
          ),
        ],
      ),
    );
  }

  Color _getTileColor(int value) {
    final colors = {
      0: const Color(0xFFCDC1B4),
      2: const Color(0xFFEEE4DA),
      4: const Color(0xFFEDE0C8),
      8: const Color(0xFFF2B179),
      16: const Color(0xFFF59563),
      32: const Color(0xFFF67C5F),
      64: const Color(0xFFF65E3B),
      128: const Color(0xFFEDCF72),
      256: const Color(0xFFEDCC61),
      512: const Color(0xFFEDC850),
      1024: const Color(0xFFEDC53F),
      2048: const Color(0xFFEDC22E),
    };
    return colors[value] ?? const Color(0xFF3C3A32);
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _startNewGame),
        ],
      ),
      body: _grid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _makeMove('right');
                } else if (details.primaryVelocity! < 0) {
                  _makeMove('left');
                }
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _makeMove('down');
                } else if (details.primaryVelocity! < 0) {
                  _makeMove('up');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.orange.shade50, Colors.orange.shade100],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Score Panel
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreCard('SCORE', _score, Colors.orange),
                            _buildScoreCard('MOVES', _moves, Colors.deepOrange),
                          ],
                        ),
                      ),

                      // Game Grid
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBADA0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: 16,
                                itemBuilder: (context, index) {
                                  final row = index ~/ 4;
                                  final col = index % 4;
                                  final value = _grid[row][col];
                                  return _buildTile(value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Controls
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Swipe to move tiles',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildControlButton(Icons.arrow_upward, 'up'),
                                _buildControlButton(
                                  Icons.arrow_downward,
                                  'down',
                                ),
                                _buildControlButton(Icons.arrow_back, 'left'),
                                _buildControlButton(
                                  Icons.arrow_forward,
                                  'right',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildScoreCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int value) {
    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: value > 0
            ? Text(
                value.toString(),
                style: TextStyle(
                  color: _getTextColor(value),
                  fontSize: value >= 1000 ? 20 : 28,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String direction) {
    return IconButton(
      onPressed: () => _makeMove(direction),
      icon: Icon(icon),
      iconSize: 32,
      style: IconButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
