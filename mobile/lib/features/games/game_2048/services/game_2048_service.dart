// Game 2048 Service
// Handles 2048 game API calls

import '../../../../shared/models/game_2048.dart';
import '../../../../core/config/api_config.dart';
import '../../../../shared/services/api_service.dart';

class Game2048Service {
  /// Create a new game
  static Future<Game2048State> createNewGame() async {
    try {
      final response = await ApiService.post(
        ApiConfig.game2048New,
        body: {},
        includeAuth: false,
      );
      return Game2048State.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create new game: $e');
    }
  }

  /// Make a move
  static Future<Game2048State> makeMove(Game2048MoveRequest request) async {
    try {
      final response = await ApiService.post(
        ApiConfig.game2048Move,
        body: request.toJson(),
        includeAuth: false,
      );
      return Game2048State.fromJson(response);
    } catch (e) {
      throw Exception('Failed to make move: $e');
    }
  }

  /// Save score (requires authentication)
  static Future<void> saveScore({
    required int score,
    required int moves,
    required bool won,
  }) async {
    try {
      await ApiService.post(
        ApiConfig.game2048SaveScore,
        body: {'score': score, 'moves': moves, 'won': won},
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
        '${ApiConfig.game2048Leaderboard}?limit=$limit',
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
