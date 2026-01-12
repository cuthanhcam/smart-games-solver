import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiClient {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  // For iOS simulator, use: 'http://localhost:8000/api'
  // For real device, use: 'http://your-server-ip:8000/api'

  static const String _tokenKey = 'auth_token';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ApiClient() {
    _init();
  }

  Future<void> _init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  Future<String?> getToken() async {
    await _init(); // Đảm bảo khởi tạo trước khi dùng
    return _prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _init(); // Đảm bảo khởi tạo trước khi dùng
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _init(); // Đảm bảo khởi tạo trước khi dùng
    await _prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  Future<http.Response> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'username_or_email': usernameOrEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> logout() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/logout'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getCurrentUser() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/me'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Game endpoints
  Future<http.Response> solveRubik(String cubeState) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/rubik/solve'),
            headers: await _getHeaders(),
            body: jsonEncode({'cube_state': cubeState}),
          )
          .timeout(const Duration(seconds: 60));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getRubikHistory({int skip = 0, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/rubik/history?skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getRubikLeaderboard({int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/leaderboard/rubik?limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> create2048Game() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/2048/new'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> make2048Move(String gameId, String direction) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/2048/move'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'game_id': gameId,
              'direction': direction,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get2048History({int skip = 0, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/games/2048/history?skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get2048Leaderboard({int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/leaderboard/2048?limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> save2048Score({required int score}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/2048/save-score'),
            headers: await _getHeaders(),
            body: jsonEncode({'score': score}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  Future<http.Response> createSudokuGame(String difficulty) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/sudoku/new?difficulty=$difficulty'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> makeSudokuMove(
    String gameId,
    int row,
    int col,
    int value,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/sudoku/move'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'game_id': gameId,
              'row': row,
              'col': col,
              'value': value,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getSudokuHint(String gameId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/games/sudoku/hint/$gameId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> validateSudoku(String gameId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/sudoku/validate'),
            headers: await _getHeaders(),
            body: jsonEncode({'game_id': gameId}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getSudokuLeaderboard({int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/leaderboard/sudoku?limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> saveSudokuScore({
    required String difficulty,
    required int timeSeconds,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/sudoku/save-score'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'difficulty': difficulty,
              'time_seconds': timeSeconds,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  Future<http.Response> getCaroLeaderboard({int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/leaderboard/caro?limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> saveCaroScore({
    required String difficulty,
    required int timeSeconds,
    required int moveCount,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/caro/save-score'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'difficulty': difficulty,
              'time_seconds': timeSeconds,
              'move_count': moveCount,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  Future<http.Response> createCaroGame() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/caro/new'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> makeCaroMove(String gameId, int row, int col) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/games/caro/move'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'game_id': gameId,
              'row': row,
              'col': col,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getCaroAIMove(String gameId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/games/caro/ai-move/$gameId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getCaroHistory({int skip = 0, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/games/caro/history?skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Admin/User endpoints
  Future<http.Response> _getAllUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/users'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _getUserCount() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/users/count'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _checkUserExists(String usernameOrEmail) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/auth/check-user?username_or_email=$usernameOrEmail'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _deleteUser(int userId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/users/$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _deleteOwnAccount() async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/auth/me'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _updateUserAdminStatus(int userId, bool isAdmin) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/admin/users/$userId/admin-status'),
            headers: await _getHeaders(),
            body: jsonEncode({'is_admin': isAdmin}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> _changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/change-password'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> banUser(
      int userId, Duration duration, String reason) async {
    try {
      // Endpoint: /api/admin/users/{id}/ban
      final uri = Uri.parse('$_baseUrl/admin/users/$userId/ban').replace(
        queryParameters: {
          'duration_minutes': duration.inMinutes.toString(),
          'reason': reason,
        },
      );

      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> unbanUser(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/users/$userId/unban'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============= FRIEND ENDPOINTS =============
  Future<http.Response> searchUsers(String query,
      {int skip = 0, int limit = 10}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/friends/search?query=$query&skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getFriendsList() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/friends/list'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getIncomingFriendRequests() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/friends/requests/incoming'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getOutgoingFriendRequests() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/friends/requests/outgoing'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> sendFriendRequest(int receiverId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/friends/request'),
            headers: await _getHeaders(),
            body: jsonEncode({'receiver_id': receiverId}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> acceptFriendRequest(int friendshipId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/friends/request/accept'),
            headers: await _getHeaders(),
            body: jsonEncode({'friendship_id': friendshipId}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> rejectFriendRequest(int friendshipId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/friends/request/reject'),
            headers: await _getHeaders(),
            body: jsonEncode({'friendship_id': friendshipId}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> removeFriend(int friendId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/friends/remove/$friendId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getFriendshipStatus(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/friends/status/$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============= MESSAGE ENDPOINTS =============
  Future<http.Response> sendMessage(int receiverId, String content) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/messages/send'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'receiver_id': receiverId,
              'content': content,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getMessagesWithUser(int userId,
      {int skip = 0, int limit = 50}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/messages/with/$userId?skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getChatList() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/messages/list'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> markMessageAsRead(int messageId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/messages/mark-read'),
            headers: await _getHeaders(),
            body: jsonEncode({'message_id': messageId}),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> markAllMessagesRead(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/messages/mark-all-read/$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getUnreadMessageCount() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/messages/unread-count'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> deleteMessage(int messageId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/messages/delete/$messageId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============= ANNOUNCEMENT ENDPOINTS =============
  Future<http.Response> getAnnouncements(
      {int skip = 0, int limit = 20, bool activeOnly = true}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/announcements/list?skip=$skip&limit=$limit&active_only=$activeOnly'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> getAnnouncement(int announcementId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/announcements/$announcementId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> createAnnouncement(
      String title, String content, String type) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/announcements/create'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'title': title,
              'content': content,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> updateAnnouncement(
      int announcementId, Map<String, dynamic> updates) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/announcements/$announcementId'),
            headers: await _getHeaders(),
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> deleteAnnouncement(int announcementId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/announcements/$announcementId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> activateAnnouncement(int announcementId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/announcements/$announcementId/activate'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> deactivateAnnouncement(int announcementId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/announcements/$announcementId/deactivate'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Mark announcement as read
  Future<http.Response> markAnnouncementAsRead(int announcementId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/announcements/$announcementId/mark-read'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Check if announcement is read
  Future<http.Response> checkAnnouncementRead(int announcementId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/announcements/$announcementId/is-read'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Hide announcement
  Future<http.Response> hideAnnouncement(int announcementId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/announcements/$announcementId/hide'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get unread announcement count
  Future<http.Response> getUnreadAnnouncementCount() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/announcements/unread-count'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============= ADMIN ENDPOINTS =============
  Future<http.Response> getAllUsers({int skip = 0, int limit = 100}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/users?skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> searchUsersAdmin(String query,
      {int skip = 0, int limit = 100}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/admin/users/search?query=$query&skip=$skip&limit=$limit'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> updateUserAdminStatus(int userId, bool isAdmin) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                '$_baseUrl/admin/users/$userId/admin-status?is_admin=$isAdmin'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> deleteUserAdmin(int userId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/admin/users/$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
