import 'dart:convert';

import '../../../../shared/services/api_client.dart';

class Game2048Repository {
  final ApiClient _apiClient;

  Game2048Repository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> createGame() async {
    try {
      final response = await _apiClient.create2048Game();

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create 2048 game');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> makeMove(String gameId, String direction) async {
    try {
      final response = await _apiClient.make2048Move(gameId, direction);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make move');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
      {int skip = 0, int limit = 10}) async {
    try {
      final response =
          await _apiClient.get2048History(skip: skip, limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        throw Exception('Failed to get game history');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _apiClient.get2048Leaderboard(limit: limit);

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
