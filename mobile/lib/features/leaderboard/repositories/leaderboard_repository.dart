import 'dart:convert';
import '../../../shared/services/api_client.dart';

class LeaderboardRepository {
  final ApiClient _apiClient;

  LeaderboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Lấy bảng xếp hạng Sudoku từ backend
  Future<List<Map<String, dynamic>>> getSudokuLeaderboard({
    int limit = 10,
    String? difficulty,
  }) async {
    try {
      final response = await _apiClient.getSudokuLeaderboard(limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaderboard = List<Map<String, dynamic>>.from(
          (data['entries'] as List?)?.map((e) {
                final map = Map<String, dynamic>.from(e);
                // Map backend fields to UI fields
                map['played_at'] = map['created_at'];
                return map;
              }) ??
              [],
        );
        return leaderboard;
      } else {
        throw Exception(
            'Failed to load Sudoku leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Sudoku leaderboard: $e');
    }
  }

  /// Lấy bảng xếp hạng Caro từ backend
  Future<List<Map<String, dynamic>>> getCaroLeaderboard(
      {int limit = 10}) async {
    try {
      final response = await _apiClient.getCaroLeaderboard(limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaderboard = List<Map<String, dynamic>>.from(
          (data['entries'] as List?)?.map((e) {
                final map = Map<String, dynamic>.from(e);
                // Map backend fields to UI fields
                map['played_at'] = map['created_at'];
                map['moveCount'] = map['moves'];
                return map;
              }) ??
              [],
        );
        return leaderboard;
      } else {
        throw Exception(
            'Failed to load Caro leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading Caro leaderboard: $e');
    }
  }

  /// Lấy bảng xếp hạng 2048 từ backend
  Future<List<Map<String, dynamic>>> get2048Leaderboard(
      {int limit = 10}) async {
    try {
      final response = await _apiClient.get2048Leaderboard(limit: limit);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leaderboard = List<Map<String, dynamic>>.from(
          (data['entries'] as List?)?.map((e) {
                final map = Map<String, dynamic>.from(e);
                // Map backend fields to UI fields
                map['played_at'] = map['created_at'];
                return map;
              }) ??
              [],
        );
        return leaderboard;
      } else {
        throw Exception(
            'Failed to load 2048 leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading 2048 leaderboard: $e');
    }
  }
}
