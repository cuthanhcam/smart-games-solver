import 'dart:convert';
import '../../../shared/services/api_client.dart';

class MessageRepository {
  static final MessageRepository _instance = MessageRepository._internal();
  factory MessageRepository() => _instance;
  MessageRepository._internal();

  final ApiClient _apiClient = ApiClient();

  // Gửi tin nhắn
  Future<int> sendMessage(int senderId, int receiverId, String content) async {
    try {
      final response = await _apiClient.sendMessage(receiverId, content);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] ?? 0;
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy tin nhắn giữa 2 user
  Future<List<Map<String, dynamic>>> getMessages(
      int userId1, int userId2) async {
    try {
      final response = await _apiClient.getMessagesWithUser(userId2);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get messages');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách chat (bao gồm tất cả bạn bè)
  Future<List<Map<String, dynamic>>> getChatList(int userId) async {
    try {
      final response = await _apiClient.getChatList();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get chat list');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      final response = await _apiClient.markMessageAsRead(messageId);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mark all messages from user as read
  Future<void> markAllMessagesRead(int userId) async {
    try {
      final response = await _apiClient.markAllMessagesRead(userId);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all messages as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mark messages as read for a specific sender
  Future<void> markAsRead(int senderId, int receiverId) async {
    try {
      final response = await _apiClient.markAllMessagesRead(senderId);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete message
  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await _apiClient.deleteMessage(messageId);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      return false;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(int userId) async {
    try {
      final response = await _apiClient.getUnreadMessageCount();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      return 0;
    }
  }

  // Get unread count for a user
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _apiClient.getUnreadMessageCount();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}
