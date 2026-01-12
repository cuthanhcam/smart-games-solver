// Sudoku Models
// Models for Sudoku game state and responses

class SudokuPuzzle {
  final int puzzleId;
  final String difficulty;
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final List<List<int>> userSolution;
  final List<List<bool>> isFixed; // Track which cells are original puzzle cells

  SudokuPuzzle({
    required this.puzzleId,
    required this.difficulty,
    required this.puzzle,
    required this.solution,
    required this.userSolution,
    required this.isFixed,
  });

  SudokuPuzzle copyWith({
    int? puzzleId,
    String? difficulty,
    List<List<int>>? puzzle,
    List<List<int>>? solution,
    List<List<int>>? userSolution,
    List<List<bool>>? isFixed,
  }) {
    return SudokuPuzzle(
      puzzleId: puzzleId ?? this.puzzleId,
      difficulty: difficulty ?? this.difficulty,
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      userSolution: userSolution ?? this.userSolution,
      isFixed: isFixed ?? this.isFixed,
    );
  }

  factory SudokuPuzzle.fromJson(Map<String, dynamic> json) {
    // Parse puzzle_data (81 character string) to 9x9 grid
    String puzzleData = json['puzzle_data'] as String;
    String solutionData = json['solution_data'] as String;

    List<List<int>> puzzle = _parseGrid(puzzleData);
    List<List<int>> solution = _parseGrid(solutionData);
    List<List<int>> userSolution = puzzle
        .map((row) => List<int>.from(row))
        .toList();
    List<List<bool>> isFixed = puzzle
        .map((row) => row.map((cell) => cell != 0).toList())
        .toList();

    return SudokuPuzzle(
      puzzleId: json['puzzle_id'] as int,
      difficulty: json['difficulty'] as String,
      puzzle: puzzle,
      solution: solution,
      userSolution: userSolution,
      isFixed: isFixed,
    );
  }

  static List<List<int>> _parseGrid(String data) {
    List<List<int>> grid = [];
    for (int i = 0; i < 9; i++) {
      List<int> row = [];
      for (int j = 0; j < 9; j++) {
        int index = i * 9 + j;
        row.add(int.parse(data[index]));
      }
      grid.add(row);
    }
    return grid;
  }

  String getUserSolutionString() {
    return userSolution
        .expand((row) => row)
        .map((cell) => cell.toString())
        .join('');
  }

  bool isComplete() {
    for (var row in userSolution) {
      if (row.contains(0)) return false;
    }
    return true;
  }
}

class SudokuValidationResult {
  final bool isCorrect;
  final List<SudokuError> errors;
  final double completionPercentage;

  SudokuValidationResult({
    required this.isCorrect,
    required this.errors,
    required this.completionPercentage,
  });

  factory SudokuValidationResult.fromJson(Map<String, dynamic> json) {
    return SudokuValidationResult(
      isCorrect: json['is_correct'] as bool,
      errors:
          (json['errors'] as List?)
              ?.map((e) => SudokuError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
    );
  }
}

class SudokuError {
  final int row;
  final int col;
  final String type;
  final String message;

  SudokuError({
    required this.row,
    required this.col,
    required this.type,
    required this.message,
  });

  factory SudokuError.fromJson(Map<String, dynamic> json) {
    return SudokuError(
      row: json['row'] as int,
      col: json['col'] as int,
      type: json['type'] as String,
      message: json['message'] as String,
    );
  }
}

class SudokuHint {
  final int row;
  final int col;
  final int value;
  final String strategy;

  SudokuHint({
    required this.row,
    required this.col,
    required this.value,
    required this.strategy,
  });

  factory SudokuHint.fromJson(Map<String, dynamic> json) {
    return SudokuHint(
      row: json['row'] as int,
      col: json['col'] as int,
      value: json['value'] as int,
      strategy: json['strategy'] as String,
    );
  }
}
