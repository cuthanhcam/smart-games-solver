import 'dart:convert';

import '../../../../shared/services/api_client.dart';

class CaroRepository {
  final ApiClient _apiClient;

  CaroRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> createGame() async {
    try {
      final response = await _apiClient.createCaroGame();

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create caro game');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> makeMove(String gameId, int row, int col) async {
    try {
      final response = await _apiClient.makeCaroMove(gameId, row, col);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to make move');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAIMove(String gameId) async {
    try {
      final response = await _apiClient.getCaroAIMove(gameId);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get AI move');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
      {int skip = 0, int limit = 10}) async {
    try {
      final response =
          await _apiClient.getCaroHistory(skip: skip, limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        throw Exception('Failed to get caro history');
      }
    } catch (e) {
      rethrow;
    }
  }
}
