import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserActivityHelper {
  static const int _maxHistoryItems = 50; // Giới hạn số lượng lịch sử

  /// Lưu lịch sử đăng nhập
  static Future<void> saveLoginHistory({
    required String username,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      final key = 'login_history_${now}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Format: username|datetime
      final data = '$username|$now';
      await prefs.setString(key, data);
      
      // Cleanup old entries
      await _cleanupOldEntries(prefs, 'login_history_');
      
      debugPrint('USER_ACTIVITY: Saved login history for $username');
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error saving login history: $e');
    }
  }

  /// Lưu lịch sử chơi game
  static Future<void> saveGameHistory({
    required String username,
    required String gameName, // 'sudoku', '2048', 'caro'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final key = 'game_history_${timestamp}_${now.microsecondsSinceEpoch}';
      
      // Format: username|game|datetime
      final data = '$username|$gameName|${now.toIso8601String()}';
      await prefs.setString(key, data);
      
      // Cleanup old entries
      await _cleanupOldEntries(prefs, 'game_history_');
      
      debugPrint('USER_ACTIVITY: Saved game history for $username playing $gameName with key: $key');
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error saving game history: $e');
    }
  }

  /// Lấy lịch sử đăng nhập
  static Future<List<Map<String, dynamic>>> getLoginHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('login_history_')).toList();
      
      final List<Map<String, dynamic>> history = [];
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final parts = data.split('|');
          if (parts.length >= 2) {
            history.add({
              'username': parts[0],
              'datetime': parts[1],
              'key': key,
            });
          }
        }
      }
      
      // Sắp xếp theo thời gian giảm dần
      history.sort((a, b) => b['datetime'].compareTo(a['datetime']));
      
      return history;
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error getting login history: $e');
      return [];
    }
  }

  /// Lấy lịch sử chơi game
  static Future<List<Map<String, dynamic>>> getGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('game_history_')).toList();
      
      final List<Map<String, dynamic>> history = [];
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final parts = data.split('|');
          if (parts.length >= 3) {
            history.add({
              'username': parts[0],
              'game': parts[1],
              'datetime': parts[2],
              'key': key,
            });
          }
        }
      }
      
      // Sắp xếp theo thời gian giảm dần
      history.sort((a, b) => b['datetime'].compareTo(a['datetime']));
      
      return history;
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error getting game history: $e');
      return [];
    }
  }

  /// Xóa lịch sử cũ để tránh quá tải
  static Future<void> _cleanupOldEntries(SharedPreferences prefs, String prefix) async {
    try {
      final keys = prefs.getKeys().where((key) => key.startsWith(prefix)).toList();
      
      if (keys.length > _maxHistoryItems) {
        // Sắp xếp keys theo thời gian (key chứa timestamp)
        keys.sort((a, b) {
          final aTime = a.split('_').last;
          final bTime = b.split('_').last;
          return bTime.compareTo(aTime); // Giảm dần
        });
        
        // Xóa các entry cũ nhất
        final keysToRemove = keys.skip(_maxHistoryItems);
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }
        
        debugPrint('USER_ACTIVITY: Cleaned up ${keysToRemove.length} old $prefix entries');
      }
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error cleaning up old entries: $e');
    }
  }

  /// Xóa tất cả lịch sử (cho admin)
  static Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('login_history_') || key.startsWith('game_history_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('USER_ACTIVITY: Cleared all history (${keys.length} entries)');
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error clearing all history: $e');
    }
  }

  /// Xóa lịch sử của một user cụ thể
  static Future<void> clearUserHistory(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('login_history_') || key.startsWith('game_history_')).toList();
      
      int removedCount = 0;
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null && data.startsWith('$username|')) {
          await prefs.remove(key);
          removedCount++;
        }
      }
      
      debugPrint('USER_ACTIVITY: Cleared history for $username ($removedCount entries)');
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error clearing user history: $e');
    }
  }

  /// Lấy thống kê hoạt động
  static Future<Map<String, dynamic>> getActivityStats() async {
    try {
      final loginHistory = await getLoginHistory();
      final gameHistory = await getGameHistory();
      
      // Đếm số lần đăng nhập theo user
      final Map<String, int> loginCounts = {};
      for (final login in loginHistory) {
        final username = login['username'];
        loginCounts[username] = (loginCounts[username] ?? 0) + 1;
      }
      
      // Đếm số lần chơi game theo user
      final Map<String, int> gameCounts = {};
      for (final game in gameHistory) {
        final username = game['username'];
        gameCounts[username] = (gameCounts[username] ?? 0) + 1;
      }
      
      // Đếm số lần chơi theo game
      final Map<String, int> gameTypeCounts = {};
      for (final game in gameHistory) {
        final gameType = game['game'];
        gameTypeCounts[gameType] = (gameTypeCounts[gameType] ?? 0) + 1;
      }
      
      return {
        'totalLogins': loginHistory.length,
        'totalGames': gameHistory.length,
        'uniqueUsers': loginCounts.keys.length,
        'loginCounts': loginCounts,
        'gameCounts': gameCounts,
        'gameTypeCounts': gameTypeCounts,
      };
    } catch (e) {
      debugPrint('USER_ACTIVITY: Error getting activity stats: $e');
      return {};
    }
  }
}
