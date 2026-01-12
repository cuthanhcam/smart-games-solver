// Caro Service
// Handles Caro game API calls

import '../../../../shared/models/caro.dart';
import '../../../../core/config/api_config.dart';
import '../../../../shared/services/api_service.dart';

class CaroService {
  /// Create a new game
  static Future<CaroGame> createNewGame({
    int boardSize = 15,
    int winLength = 5,
    String mode = 'pvp',
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.caroNew,
        body: {'board_size': boardSize, 'win_length': winLength, 'mode': mode},
        includeAuth: false,
      );
      return CaroGame.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create new game: $e');
    }
  }

  /// Make a move
  static Future<CaroGame> makeMove(CaroMoveRequest request) async {
    try {
      final response = await ApiService.post(
        ApiConfig.caroMove,
        body: request.toJson(),
        includeAuth: false,
      );
      return CaroGame.fromJson(response);
    } catch (e) {
      throw Exception('Failed to make move: $e');
    }
  }

  /// Get AI move
  static Future<CaroGame> getAIMove({
    required int? gameId,
    required List<List<int>> board,
    required String difficulty,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.caroAIMove,
        body: {'game_id': gameId, 'board': board, 'difficulty': difficulty},
        includeAuth: false,
      );
      return CaroGame.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get AI move: $e');
    }
  }

  /// Save score (requires authentication)
  static Future<void> saveScore({
    required String mode,
    required String result,
    required int moves,
  }) async {
    try {
      await ApiService.post(
        ApiConfig.caroSaveScore,
        body: {'mode': mode, 'result': result, 'moves': moves},
        includeAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to save score: $e');
    }
  }

  /// Get leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.caroLeaderboard}?limit=$limit',
        includeAuth: false,
      );
      return (response['entries'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }
}
