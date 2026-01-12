import 'dart:convert';

import '../../../../shared/services/api_client.dart';

class SudokuRepository {
  final ApiClient _apiClient;

  SudokuRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> createGame(String difficulty) async {
    try {
      final response = await _apiClient.createSudokuGame(difficulty);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create sudoku game');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> makeMove(
    String gameId,
    int row,
    int col,
    int value,
  ) async {
    try {
      final response = await _apiClient.makeSudokuMove(gameId, row, col, value);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make move');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHint(String gameId) async {
    try {
      final response = await _apiClient.getSudokuHint(gameId);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get hint');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> validateGame(String gameId) async {
    try {
      final response = await _apiClient.validateSudoku(gameId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_valid'] ?? false;
      } else {
        throw Exception('Failed to validate');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _apiClient.getSudokuLeaderboard(limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get leaderboard');
      }
    } catch (e) {
      rethrow;
    }
  }
}
