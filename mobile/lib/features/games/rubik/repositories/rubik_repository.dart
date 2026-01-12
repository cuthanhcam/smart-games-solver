import 'dart:convert';

import '../../../../shared/services/api_client.dart';

class RubikRepository {
  final ApiClient _apiClient;

  RubikRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> solveRubik(String cubeState) async {
    try {
      final response = await _apiClient.solveRubik(cubeState);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to solve rubik');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
      {int skip = 0, int limit = 10}) async {
    try {
      final response =
          await _apiClient.getRubikHistory(skip: skip, limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        throw Exception('Failed to get rubik history');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _apiClient.getRubikLeaderboard(limit: limit);

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
