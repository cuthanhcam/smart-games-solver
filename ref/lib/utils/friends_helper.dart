import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FriendsHelper {
  static const int _maxFriends = 50; // Giới hạn số lượng bạn bè

  /// Thêm bạn bè mới
  static Future<bool> addFriend({
    required String currentUsername,
    required String friendUsername,
    String? friendEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kiểm tra không được tự kết bạn với chính mình
      if (currentUsername == friendUsername) {
        debugPrint('FRIENDS: Cannot add yourself as friend');
        return false;
      }

      // Kiểm tra bạn bè đã tồn tại chưa
      final friendsKey = 'friends_$currentUsername';
      final friendsList = prefs.getStringList(friendsKey) ?? [];
      
      if (friendsList.contains(friendUsername)) {
        debugPrint('FRIENDS: Friend $friendUsername already exists');
        return false;
      }

      // Kiểm tra giới hạn số lượng bạn bè
      if (friendsList.length >= _maxFriends) {
        debugPrint('FRIENDS: Maximum friends limit reached');
        return false;
      }

      // Thêm bạn bè mới với email (nếu có)
      final friendData = friendEmail != null 
          ? '$friendUsername|$friendEmail' 
          : friendUsername;
      friendsList.add(friendData);
      await prefs.setStringList(friendsKey, friendsList);
      
      debugPrint('FRIENDS: Added $friendUsername${friendEmail != null ? ' ($friendEmail)' : ''} as friend for $currentUsername');
      return true;
    } catch (e) {
      debugPrint('FRIENDS: Error adding friend: $e');
      return false;
    }
  }

  /// Xóa bạn bè
  static Future<bool> removeFriend({
    required String currentUsername,
    required String friendUsername,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsKey = 'friends_$currentUsername';
      final friendsList = prefs.getStringList(friendsKey) ?? [];
      
      if (friendsList.remove(friendUsername)) {
        await prefs.setStringList(friendsKey, friendsList);
        debugPrint('FRIENDS: Removed $friendUsername from friends of $currentUsername');
        return true;
      }
      
      debugPrint('FRIENDS: Friend $friendUsername not found');
      return false;
    } catch (e) {
      debugPrint('FRIENDS: Error removing friend: $e');
      return false;
    }
  }

  /// Lấy danh sách bạn bè
  static Future<List<Map<String, String>>> getFriends(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsKey = 'friends_$username';
      final friendsList = prefs.getStringList(friendsKey) ?? [];
      
      final friends = friendsList.map((friendData) {
        if (friendData.contains('|')) {
          final parts = friendData.split('|');
          return {
            'username': parts[0],
            'email': parts.length > 1 ? parts[1] : '',
          };
        } else {
          return {
            'username': friendData,
            'email': '',
          };
        }
      }).toList();
      
      debugPrint('FRIENDS: Retrieved ${friends.length} friends for $username');
      return friends;
    } catch (e) {
      debugPrint('FRIENDS: Error getting friends: $e');
      return [];
    }
  }

  /// Kiểm tra có phải bạn bè không
  static Future<bool> isFriend({
    required String currentUsername,
    required String friendUsername,
  }) async {
    try {
      final friends = await getFriends(currentUsername);
      return friends.any((friend) => friend['username'] == friendUsername);
    } catch (e) {
      debugPrint('FRIENDS: Error checking friendship: $e');
      return false;
    }
  }

  /// Lấy số lượng bạn bè
  static Future<int> getFriendsCount(String username) async {
    try {
      final friends = await getFriends(username);
      return friends.length;
    } catch (e) {
      debugPrint('FRIENDS: Error getting friends count: $e');
      return 0;
    }
  }

  /// Xóa tất cả bạn bè
  static Future<bool> clearAllFriends(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsKey = 'friends_$username';
      await prefs.remove(friendsKey);
      debugPrint('FRIENDS: Cleared all friends for $username');
      return true;
    } catch (e) {
      debugPrint('FRIENDS: Error clearing friends: $e');
      return false;
    }
  }

  /// Tìm kiếm bạn bè theo tên
  static Future<List<Map<String, String>>> searchFriends({
    required String username,
    required String query,
  }) async {
    try {
      final friends = await getFriends(username);
      if (query.isEmpty) return friends;
      
      return friends.where((friend) => 
        friend['username']!.toLowerCase().contains(query.toLowerCase()) ||
        friend['email']!.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      debugPrint('FRIENDS: Error searching friends: $e');
      return [];
    }
  }
}
