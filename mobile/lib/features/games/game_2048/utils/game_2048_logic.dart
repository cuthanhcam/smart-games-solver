// Game 2048 Logic
// Client-side game logic for 2048

import 'dart:math';

class Game2048Logic {
  static const int gridSize = 4;

  /// Create initial game state with 2 random tiles
  static List<List<int>> createInitialGrid() {
    List<List<int>> grid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0),
    );

    // Add 2 random tiles
    _addRandomTile(grid);
    _addRandomTile(grid);

    return grid;
  }

  /// Add a random tile (2 or 4) to an empty cell
  static void _addRandomTile(List<List<int>> grid) {
    List<List<int>> emptyCells = [];

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isEmpty) return;

    final random = Random();
    final cell = emptyCells[random.nextInt(emptyCells.length)];
    grid[cell[0]][cell[1]] = random.nextDouble() < 0.9 ? 2 : 4;
  }

  /// Make a move in the specified direction
  static Map<String, dynamic> makeMove(List<List<int>> grid, String direction) {
    List<List<int>> newGrid = grid.map((row) => List<int>.from(row)).toList();
    int pointsEarned = 0;
    bool moved = false;

    switch (direction) {
      case 'up':
        for (int col = 0; col < gridSize; col++) {
          List<int> column = [
            for (int row = 0; row < gridSize; row++) newGrid[row][col],
          ];
          var result = _mergeLine(column);
          for (int row = 0; row < gridSize; row++) {
            if (newGrid[row][col] != result['line'][row]) moved = true;
            newGrid[row][col] = result['line'][row];
          }
          pointsEarned += result['points'] as int;
        }
        break;

      case 'down':
        for (int col = 0; col < gridSize; col++) {
          List<int> column = [
            for (int row = gridSize - 1; row >= 0; row--) newGrid[row][col],
          ];
          var result = _mergeLine(column);
          for (int row = 0; row < gridSize; row++) {
            if (newGrid[gridSize - 1 - row][col] != result['line'][row])
              moved = true;
            newGrid[gridSize - 1 - row][col] = result['line'][row];
          }
          pointsEarned += result['points'] as int;
        }
        break;

      case 'left':
        for (int row = 0; row < gridSize; row++) {
          var result = _mergeLine(newGrid[row]);
          if (newGrid[row].toString() != result['line'].toString())
            moved = true;
          newGrid[row] = result['line'];
          pointsEarned += result['points'] as int;
        }
        break;

      case 'right':
        for (int row = 0; row < gridSize; row++) {
          List<int> reversed = newGrid[row].reversed.toList();
          var result = _mergeLine(reversed);
          List<int> line = (result['line'] as List<int>).reversed.toList();
          if (newGrid[row].toString() != line.toString()) moved = true;
          newGrid[row] = line;
          pointsEarned += result['points'] as int;
        }
        break;
    }

    if (moved) {
      _addRandomTile(newGrid);
    }

    return {
      'grid': newGrid,
      'moved': moved,
      'points': pointsEarned,
      'gameOver': _isGameOver(newGrid),
      'won': _hasWon(newGrid),
    };
  }

  /// Merge a line (row or column) according to 2048 rules
  static Map<String, dynamic> _mergeLine(List<int> line) {
    List<int> newLine = List.filled(gridSize, 0);
    int points = 0;
    int index = 0;

    // Remove zeros
    List<int> nonZero = line.where((x) => x != 0).toList();

    // Merge adjacent equal tiles
    int i = 0;
    while (i < nonZero.length) {
      if (i < nonZero.length - 1 && nonZero[i] == nonZero[i + 1]) {
        newLine[index] = nonZero[i] * 2;
        points += nonZero[i] * 2;
        i += 2;
      } else {
        newLine[index] = nonZero[i];
        i++;
      }
      index++;
    }

    return {'line': newLine, 'points': points};
  }

  /// Check if game is over (no valid moves)
  static bool _isGameOver(List<List<int>> grid) {
    // Check for empty cells
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) return false;
      }
    }

    // Check for possible merges
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (j < gridSize - 1 && grid[i][j] == grid[i][j + 1]) return false;
        if (i < gridSize - 1 && grid[i][j] == grid[i + 1][j]) return false;
      }
    }

    return true;
  }

  /// Check if player has won (reached 2048)
  static bool _hasWon(List<List<int>> grid) {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] >= 2048) return true;
      }
    }
    return false;
  }

  /// Check if any move is possible
  static bool canMove(List<List<int>> grid) {
    return !_isGameOver(grid);
  }
}
