import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/services/api_client.dart';


class LeaderboardHelper {
  /// Gọi khi người chơi hoàn thành Sudoku: chỉ cập nhật nếu tốt hơn
  static Future<void> saveSudokuResult({
    required String username,
    required String difficulty, // 'Easy' | 'Normal' | 'Hard' | 'Expert'
    required int timeSeconds,   // tổng thời gian hoàn thành (giây)
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final diffLower = difficulty.toLowerCase(); // easy|normal|hard|expert

    final bestKey = 'sudoku_best_time_${username}_$diffLower';
    final prev    = prefs.getInt(bestKey);

    if (prev == null || timeSeconds < prev) {
      await prefs.setInt(bestKey, timeSeconds);
      await prefs.setString(
        'sudoku_completed_date_${username}_$diffLower',
        DateTime.now().toIso8601String(),
      );
      debugPrint('LEADERBOARD: new best Sudoku for $username/$diffLower = $timeSeconds s');
      
      // Save to backend
      try {
        final apiClient = ApiClient();
        final response = await apiClient.saveSudokuScore(
          difficulty: difficulty,
          timeSeconds: timeSeconds,
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('LEADERBOARD: Successfully saved Sudoku score to backend');
        } else {
          debugPrint('LEADERBOARD: Failed to save Sudoku score to backend: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('LEADERBOARD: Error saving Sudoku score to backend: $e');
      }
    } else {
      debugPrint('LEADERBOARD: keep old best Sudoku ($prev s) for $username/$diffLower');
    }
  }

  /// Gọi khi người chơi hoàn thành Caro: lưu tất cả kết quả
  static Future<void> saveCaroResult({
    required String username,
    required String difficulty, // 'Easy' | 'Normal' | 'Hard' | 'Expert'
    required int timeSeconds,   // tổng thời gian hoàn thành (giây)
    required int moveCount,     // số lượt đi của người chơi
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final diffLower = difficulty.toLowerCase(); // easy|normal|hard|expert

    // Lưu thời gian hoàn thành
    final timeKey = 'caro_best_time_${username}_$diffLower';
    final prevTime = prefs.getInt(timeKey);

    if (prevTime == null || timeSeconds < prevTime) {
      await prefs.setInt(timeKey, timeSeconds);
    }

    // Lưu số lượt đi
    final moveKey = 'caro_move_count_${username}_$diffLower';
    final prevMoves = prefs.getInt(moveKey);

    if (prevMoves == null || moveCount < prevMoves) {
      await prefs.setInt(moveKey, moveCount);
    }

    // Lưu ngày hoàn thành
    await prefs.setString(
      'caro_completed_date_${username}_$diffLower',
      DateTime.now().toIso8601String(),
    );

    debugPrint('LEADERBOARD: Saved Caro result for $username/$diffLower - Time: $timeSeconds s, Moves: $moveCount');
    
    // Save to backend
    try {
      final apiClient = ApiClient();
      final response = await apiClient.saveCaroScore(
        difficulty: difficulty,
        timeSeconds: timeSeconds,
        moveCount: moveCount,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('LEADERBOARD: Successfully saved Caro score to backend');
      } else {
        debugPrint('LEADERBOARD: Failed to save Caro score to backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LEADERBOARD: Error saving Caro score to backend: $e');
    }
  }

  /// Gọi khi người chơi hoàn thành 2048: chỉ cập nhật nếu điểm cao hơn
  static Future<void> save2048Result({
    required String username,
    required int score, // điểm số cao nhất
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Sử dụng format mới g2048_... để nhất quán với code hiện tại
    final bestKey = 'g2048_best_score_$username';
    final prev = prefs.getInt(bestKey);
    
    if (prev == null || score > prev) {
      await prefs.setInt(bestKey, score);
      await prefs.setString(
        'g2048_completed_date_$username',
        DateTime.now().toIso8601String(),
      );
      debugPrint('LEADERBOARD: new best 2048 score for $username = $score');
      
      // Save to backend
      try {
        final apiClient = ApiClient();
        final response = await apiClient.save2048Score(score: score);
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('LEADERBOARD: Successfully saved 2048 score to backend');
        } else {
          debugPrint('LEADERBOARD: Failed to save 2048 score to backend: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('LEADERBOARD: Error saving 2048 score to backend: $e');
      }
    } else {
      debugPrint('LEADERBOARD: keep old best 2048 score ($prev) for $username');
    }
  }
}