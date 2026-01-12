// Sudoku Screen
// Classic 9x9 Sudoku puzzle game with client-side logic

import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/sudoku_logic.dart';
import '../services/sudoku_service.dart';
import '../../../auth/services/auth_service.dart';
import '../../../../shared/widgets/gradient_background.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  List<int> _puzzle = [];
  List<int> _solution = [];
  List<int> _currentBoard = [];
  List<int> _initialPuzzle = [];
  String _difficulty = 'Easy';
  int? _selectedCell;
  bool _isLoading = false;
  int _startTime = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showErrors = false;
  List<int> _conflicts = [];

  @override
  void initState() {
    super.initState();
    _showDifficultyDialog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _startTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) - _startTime;
      });
    });
  }

  Future<void> _showDifficultyDialog() async {
    final difficulty = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption('Easy'),
            _buildDifficultyOption('Medium'),
            _buildDifficultyOption('Hard'),
            _buildDifficultyOption('Expert'),
          ],
        ),
      ),
    );

    if (difficulty != null) {
      setState(() => _difficulty = difficulty);
      _startNewPuzzle();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildDifficultyOption(String difficulty) {
    return ListTile(
      title: Text(difficulty),
      leading: Radio<String>(
        value: difficulty,
        groupValue: _difficulty,
        onChanged: (value) => Navigator.pop(context, value),
      ),
      onTap: () => Navigator.pop(context, difficulty),
    );
  }

  void _startNewPuzzle() {
    setState(() => _isLoading = true);

    // Generate puzzle using client-side logic
    final puzzleData = SudokuLogic.createNewPuzzle(_difficulty);

    setState(() {
      _puzzle = puzzleData['puzzle'];
      _solution = puzzleData['solution'];
      _currentBoard = List<int>.from(_puzzle);
      _initialPuzzle = List<int>.from(_puzzle);
      _selectedCell = null;
      _conflicts = [];
      _showErrors = false;
      _isLoading = false;
    });

    _startTimer();
  }

  void _placeNumber(int number) {
    if (_selectedCell == null) return;
    if (_initialPuzzle[_selectedCell!] != 0)
      return; // Can't change initial numbers

    setState(() {
      _currentBoard[_selectedCell!] = number;

      // Update conflicts
      if (_showErrors) {
        _conflicts = SudokuLogic.getConflicts(_currentBoard);
      }
    });

    // Check if puzzle is complete
    if (!_currentBoard.contains(0)) {
      _checkCompletion();
    }
  }

  void _checkCompletion() {
    final isCorrect = SudokuLogic.isComplete(_currentBoard, _solution);

    if (isCorrect) {
      _timer?.cancel();
      _showCompletionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some numbers are incorrect. Keep trying!'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _showErrors = true;
        _conflicts = SudokuLogic.getConflicts(_currentBoard);
      });
    }
  }

  Future<void> _showCompletionDialog() async {
    // Save score to backend
    if (authService.isAuthenticated) {
      try {
        await SudokuService.saveScore(
          puzzleId: 0, // Client-side puzzle doesn't have ID
          difficulty: _difficulty,
          timeTaken: _elapsedSeconds,
          completed: true,
        );
      } catch (e) {
        debugPrint('Error saving score: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You solved the puzzle correctly!'),
            const SizedBox(height: 16),
            Text(
              'Time: ${_formatTime(_elapsedSeconds)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDifficultyDialog();
            },
            child: const Text('New Puzzle'),
          ),
        ],
      ),
    );
  }

  void _getHint() {
    final hint = SudokuLogic.getHint(_currentBoard, _solution);
    if (hint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puzzle is already complete!')),
      );
      return;
    }

    final index = hint['row']! * 9 + hint['col']!;
    setState(() {
      _currentBoard[index] = hint['value']!;
      _selectedCell = index;
      if (_showErrors) {
        _conflicts = SudokuLogic.getConflicts(_currentBoard);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hint placed!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearCell() {
    if (_selectedCell == null) return;
    if (_initialPuzzle[_selectedCell!] != 0) return;

    setState(() {
      _currentBoard[_selectedCell!] = 0;
      if (_showErrors) {
        _conflicts = SudokuLogic.getConflicts(_currentBoard);
      }
    });
  }

  void _toggleErrorCheck() {
    setState(() {
      _showErrors = !_showErrors;
      if (_showErrors) {
        _conflicts = SudokuLogic.getConflicts(_currentBoard);
      } else {
        _conflicts = [];
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku - $_difficulty'),
        actions: [
          IconButton(
            icon: Icon(_showErrors ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleErrorCheck,
            tooltip: 'Toggle Error Check',
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _getHint,
            tooltip: 'Get Hint',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showDifficultyDialog,
            tooltip: 'New Puzzle',
          ),
        ],
      ),
      body: GradientBackground(
        colors: [Colors.blue.shade50, Colors.blue.shade100, Colors.white],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // Timer
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sudoku Grid
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(4),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 9,
                                mainAxisSpacing: 1,
                                crossAxisSpacing: 1,
                              ),
                              itemCount: 81,
                              itemBuilder: (context, index) {
                                return _buildCell(index);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Number Pad
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int i = 1; i <= 5; i++)
                                _buildNumberButton(i),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int i = 6; i <= 9; i++)
                                _buildNumberButton(i),
                              _buildClearButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final row = index ~/ 9;
    final col = index % 9;
    final isInitial = _initialPuzzle[index] != 0;
    final isSelected = _selectedCell == index;
    final number = _currentBoard[index];
    final hasError = _showErrors && _conflicts.contains(index);

    // Cell border styling
    final showThickRight = (col + 1) % 3 == 0 && col != 8;
    final showThickBottom = (row + 1) % 3 == 0 && row != 8;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCell = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasError
              ? Colors.red.shade100
              : isSelected
                  ? Colors.blue.shade100
                  : isInitial
                      ? Colors.grey.shade200
                      : Colors.white,
          border: Border(
            right: BorderSide(
              width: showThickRight ? 2 : 0.5,
              color: showThickRight ? Colors.black : Colors.grey.shade400,
            ),
            bottom: BorderSide(
              width: showThickBottom ? 2 : 0.5,
              color: showThickBottom ? Colors.black : Colors.grey.shade400,
            ),
          ),
        ),
        child: Center(
          child: number == 0
              ? null
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isInitial ? FontWeight.bold : FontWeight.normal,
                    color: hasError
                        ? Colors.red
                        : isInitial
                            ? Colors.black
                            : Colors.blue,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _placeNumber(number),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$number',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: _clearCell,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.clear, size: 28),
      ),
    );
  }
}
