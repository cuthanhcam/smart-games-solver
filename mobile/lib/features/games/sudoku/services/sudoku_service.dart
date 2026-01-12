// Sudoku Service
// Handles Sudoku game API calls

import '../../../../shared/models/sudoku.dart';
import '../../../../core/config/api_config.dart';
import '../../../../shared/services/api_service.dart';

class SudokuService {
  /// Create a new puzzle
  static Future<SudokuPuzzle> createNewPuzzle(String difficulty) async {
    try {
      final response = await ApiService.post(
        ApiConfig.sudokuNew,
        body: {'difficulty': difficulty},
        includeAuth: false,
      );
      return SudokuPuzzle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create new puzzle: $e');
    }
  }

  /// Make a move
  static Future<Map<String, dynamic>> makeMove({
    required int puzzleId,
    required int row,
    required int col,
    required int value,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.sudokuMove,
        body: {'puzzle_id': puzzleId, 'row': row, 'col': col, 'value': value},
        includeAuth: false,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to make move: $e');
    }
  }

  /// Validate solution
  static Future<SudokuValidationResult> validateSolution({
    required int puzzleId,
    required String userSolution,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.sudokuValidate,
        body: {'puzzle_id': puzzleId, 'user_solution': userSolution},
        includeAuth: false,
      );
      return SudokuValidationResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to validate solution: $e');
    }
  }

  /// Get hint
  static Future<SudokuHint> getHint(int puzzleId) async {
    try {
      final response = await ApiService.post(
        ApiConfig.sudokuHint,
        body: {'puzzle_id': puzzleId},
        includeAuth: false,
      );
      return SudokuHint.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get hint: $e');
    }
  }

  /// Save score (requires authentication)
  static Future<void> saveScore({
    required int puzzleId,
    required String difficulty,
    required int timeTaken,
    required bool completed,
    int hintsUsed = 0,
  }) async {
    try {
      await ApiService.post(
        ApiConfig.sudokuSaveScore,
        body: {
          'puzzle_id': puzzleId,
          'difficulty': difficulty,
          'time_seconds': timeTaken,
          'hints_used': hintsUsed,
        },
        includeAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to save score: $e');
    }
  }

  /// Get leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String? difficulty,
    int limit = 10,
  }) async {
    try {
      String url = '${ApiConfig.sudokuLeaderboard}?limit=$limit';
      if (difficulty != null) {
        url += '&difficulty=$difficulty';
      }
      final response = await ApiService.get(url, includeAuth: false);
      return (response['entries'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }
}
