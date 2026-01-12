import 'dart:convert';

import '../../../shared/services/api_client.dart';

class FriendRequestRepository {
  final ApiClient _apiClient;

  FriendRequestRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Tìm user bằng username hoặc email
  Future<Map<String, dynamic>?> findUserByUsernameOrEmail(String query) async {
    try {
      final response = await _apiClient.searchUsers(query, limit: 1);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Gửi lời mời kết bạn
  Future<bool> sendFriendRequest(int senderId, int receiverId) async {
    try {
      final response = await _apiClient.sendFriendRequest(receiverId);

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error sending friend request: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // Lấy danh sách lời mời kết bạn đã nhận
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests(
      int userId) async {
    try {
      final response = await _apiClient.getIncomingFriendRequests();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get incoming friend requests');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách lời mời kết bạn đã gửi
  Future<List<Map<String, dynamic>>> getSentFriendRequests(int userId) async {
    try {
      final response = await _apiClient.getOutgoingFriendRequests();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get outgoing friend requests');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Chấp nhận lời mời kết bạn
  Future<bool> acceptFriendRequest(int requestId) async {
    try {
      final response = await _apiClient.acceptFriendRequest(requestId);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error accepting friend request: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  // Từ chối lời mời kết bạn
  Future<bool> rejectFriendRequest(int requestId) async {
    try {
      final response = await _apiClient.rejectFriendRequest(requestId);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error rejecting friend request: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  // Lấy danh sách bạn bè
  Future<List<Map<String, dynamic>>> getFriends(int userId) async {
    try {
      final response = await _apiClient.getFriendsList();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get friends');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Hủy kết bạn
  Future<bool> removeFriend(int userId, int friendId) async {
    try {
      final response = await _apiClient.removeFriend(friendId);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error removing friend: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // Kiểm tra xem 2 user đã là bạn bè chưa
  Future<bool> areFriends(int userId1, int userId2) async {
    try {
      final response = await _apiClient.getFriendshipStatus(userId2);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'friends';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Kiểm tra xem đã gửi lời mời kết bạn chưa
  Future<bool> hasPendingRequest(int senderId, int receiverId) async {
    try {
      final response = await _apiClient.getFriendshipStatus(receiverId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'pending_sent';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Kiểm tra trạng thái friend request giữa 2 user
  Future<String?> getFriendRequestStatus(int userId1, int userId2) async {
    try {
      final response = await _apiClient.getFriendshipStatus(userId2);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        if (status == 'friends') return 'accepted';
        if (status == 'pending_sent') return 'pending';
        if (status == 'pending_received') return 'pending';
        if (status == 'rejected') return 'rejected';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
