// Sudoku Logic
// Client-side Sudoku game logic

import 'dart:math';

class SudokuLogic {
  static final _random = Random();

  /// Generate a complete Sudoku solution
  static List<int> generateSolution() {
    final board = List<int>.filled(81, 0);
    _fillBoard(board, 0);
    return board;
  }

  /// Fill board using backtracking with random numbers
  static bool _fillBoard(List<int> board, int index) {
    if (index == 81) return true;

    final row = index ~/ 9;
    final col = index % 9;
    final numbers = List<int>.generate(9, (i) => i + 1)..shuffle(_random);

    for (final num in numbers) {
      if (_canPlace(board, row, col, num)) {
        board[index] = num;
        if (_fillBoard(board, index + 1)) return true;
        board[index] = 0;
      }
    }
    return false;
  }

  /// Check if number can be placed at position
  static bool _canPlace(List<int> board, int row, int col, int num) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (board[row * 9 + c] == num) return false;
    }

    // Check column
    for (int r = 0; r < 9; r++) {
      if (board[r * 9 + col] == num) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (board[(boxRow + r) * 9 + (boxCol + c)] == num) return false;
      }
    }

    return true;
  }

  /// Check if a number placement is valid in current board state
  static bool isValidPlacement(List<int> board, int row, int col, int num) {
    // Temporarily clear this cell
    final temp = board[row * 9 + col];
    board[row * 9 + col] = 0;

    final valid = _canPlace(board, row, col, num);

    // Restore original value
    board[row * 9 + col] = temp;
    return valid;
  }

  /// Generate a puzzle from solution by removing numbers
  static List<int> makePuzzle(List<int> solution, String difficulty) {
    final targetHoles = _getHolesForDifficulty(difficulty);
    final puzzle = List<int>.from(solution);
    final indices = List<int>.generate(81, (i) => i)..shuffle(_random);

    int holesCreated = 0;
    for (final index in indices) {
      if (holesCreated >= targetHoles) break;

      final original = puzzle[index];
      puzzle[index] = 0;

      // For simplicity, we don't check uniqueness here
      // A proper implementation would verify unique solution
      holesCreated++;
    }

    return puzzle;
  }

  /// Get number of holes based on difficulty
  static int _getHolesForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 35 + _random.nextInt(5); // 35-39 holes
      case 'medium':
        return 45 + _random.nextInt(5); // 45-49 holes
      case 'hard':
        return 52 + _random.nextInt(4); // 52-55 holes
      case 'expert':
        return 57 + _random.nextInt(3); // 57-59 holes
      default:
        return 45;
    }
  }

  /// Check if puzzle is complete and correct
  static bool isComplete(List<int> board, List<int> solution) {
    if (board.contains(0)) return false;

    for (int i = 0; i < 81; i++) {
      if (board[i] != solution[i]) return false;
    }

    return true;
  }

  /// Get hint - find an empty cell and show correct number
  static Map<String, int>? getHint(List<int> board, List<int> solution) {
    final emptyCells = <int>[];
    for (int i = 0; i < 81; i++) {
      if (board[i] == 0) emptyCells.add(i);
    }

    if (emptyCells.isEmpty) return null;

    final hintIndex = emptyCells[_random.nextInt(emptyCells.length)];
    return {
      'row': hintIndex ~/ 9,
      'col': hintIndex % 9,
      'value': solution[hintIndex],
    };
  }

  /// Validate current board state (check for conflicts)
  static List<int> getConflicts(List<int> board) {
    final conflicts = <int>[];

    for (int i = 0; i < 81; i++) {
      final num = board[i];
      if (num == 0) continue;

      final row = i ~/ 9;
      final col = i % 9;

      // Temporarily remove this number
      board[i] = 0;

      // Check if this position would be valid
      if (!_canPlace(board, row, col, num)) {
        conflicts.add(i);
      }

      // Restore number
      board[i] = num;
    }

    return conflicts;
  }

  /// Check if board has any conflicts
  static bool hasConflicts(List<int> board) {
    return getConflicts(board).isNotEmpty;
  }

  /// Create a new puzzle with given difficulty
  static Map<String, dynamic> createNewPuzzle(String difficulty) {
    final solution = generateSolution();
    final puzzle = makePuzzle(solution, difficulty);

    return {'puzzle': puzzle, 'solution': solution, 'difficulty': difficulty};
  }
}
