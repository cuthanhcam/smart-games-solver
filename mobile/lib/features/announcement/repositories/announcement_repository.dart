import 'dart:convert';
import '../../../shared/services/api_client.dart';

class AnnouncementRepository {
  final ApiClient _apiClient;

  AnnouncementRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // Lấy tất cả thông báo (admin xem tất cả, user chỉ xem active)
  Future<List<Map<String, dynamic>>> getAllAnnouncements(
      {int skip = 0, int limit = 20, bool? activeOnly}) async {
    try {
      final response = await _apiClient.getAnnouncements(
        skip: skip,
        limit: limit,
        activeOnly: activeOnly ?? false, // Admin mặc định xem tất cả
      );

      print('getAllAnnouncements: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            'getAllAnnouncements: received ${(data as List).length} announcements');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('getAllAnnouncements: error - ${response.body}');
        throw Exception('Failed to get announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('getAllAnnouncements: exception - $e');
      rethrow;
    }
  }

  // Lấy thông báo đang hoạt động
  Future<List<Map<String, dynamic>>> getActiveAnnouncements(
      {int skip = 0, int limit = 20}) async {
    try {
      final response = await _apiClient.getAnnouncements(
        skip: skip,
        limit: limit,
        activeOnly: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Filter only active announcements
        return List<Map<String, dynamic>>.from(data)
            .where((item) => item['is_active'] == true)
            .toList();
      } else {
        throw Exception('Failed to get active announcements');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy thông báo cụ thể
  Future<Map<String, dynamic>?> getAnnouncement(int announcementId) async {
    try {
      final response = await _apiClient.getAnnouncement(announcementId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get announcement');
      }
    } catch (e) {
      return null;
    }
  }

  // Tạo thông báo mới
  Future<Map<String, dynamic>> createAnnouncement(
      String title, String content, String type) async {
    try {
      final response =
          await _apiClient.createAnnouncement(title, content, type);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to create announcement');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật trạng thái thông báo
  Future<void> updateAnnouncementStatus(int id, bool isActive) async {
    try {
      final response = await _apiClient.updateAnnouncement(
        id,
        {'is_active': isActive},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update announcement status');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Xóa thông báo
  Future<void> deleteAnnouncement(int id) async {
    try {
      final response = await _apiClient.deleteAnnouncement(id);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy tất cả thông báo cho user
  Future<List<Map<String, dynamic>>> getAllAnnouncementsForUser(
      int userId) async {
    try {
      final response = await _apiClient.getAnnouncements(activeOnly: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get announcements for user');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ẩn thông báo cho user
  Future<void> hideAnnouncementForUser(int userId, int announcementId) async {
    try {
      final response = await _apiClient.hideAnnouncement(announcementId);

      if (response.statusCode != 200) {
        throw Exception('Failed to hide announcement');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Kiểm tra thông báo đã đọc chưa
  Future<bool> isAnnouncementReadByUser(int userId, int announcementId) async {
    try {
      final response = await _apiClient.checkAnnouncementRead(announcementId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_read'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markAnnouncementAsRead(int userId, int announcementId) async {
    try {
      final response = await _apiClient.markAnnouncementAsRead(announcementId);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark announcement as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy số thông báo chưa đọc
  Future<int> getUnreadAnnouncementCount(int userId) async {
    try {
      final response = await _apiClient.getUnreadAnnouncementCount();

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
