import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/services/api_client.dart';

class AuthRepository {
  static const _kSessionUserId = 'session_user_id';
  static const _kCurrentUserKey = 'current_user';

  final ApiClient _apiClient;
  SharedPreferences? _prefs;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Đăng ký: username + email + password
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _apiClient.register(
        username: username,
        email: email,
        password: password,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Lưu token
        if (data['access_token'] != null) {
          await _apiClient.saveToken(data['access_token']);
        }

        // Tạo AppUser từ response
        final user = AppUser(
          id: data['user']['id'],
          username: data['user']['username'],
          email: data['user']['email'],
          passwordHash: '',
          salt: '',
          createdAt: DateTime.parse(data['user']['created_at']),
          isAdmin: data['user']['is_admin'] ?? false,
        );

        // Lưu vào SharedPreferences
        await _prefs!.setInt(_kSessionUserId, user.id!);
        await _prefs!.setString(_kCurrentUserKey, jsonEncode(user.toMap()));

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Đăng nhập: email + password
  Future<AppUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _apiClient.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Lưu token
        if (data['access_token'] != null) {
          await _apiClient.saveToken(data['access_token']);
        }

        // Tạo AppUser từ response
        final user = AppUser(
          id: data['user']['id'],
          username: data['user']['username'],
          email: data['user']['email'],
          passwordHash: '',
          salt: '',
          createdAt: DateTime.parse(data['user']['created_at']),
          isAdmin: data['user']['is_admin'] ?? false,
        );

        // Lưu vào SharedPreferences
        await _prefs!.setInt(_kSessionUserId, user.id!);
        await _prefs!.setString(_kCurrentUserKey, jsonEncode(user.toMap()));

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _ensureInitialized();
    try {
      await _apiClient.logout();
    } catch (e) {
      // Tiếp tục xóa local data dù API gặp lỗi
    }

    await _prefs!.remove(_kSessionUserId);
    await _prefs!.remove(_kCurrentUserKey);
    await _apiClient.clearToken();
  }

  // Lấy user hiện tại
  Future<AppUser?> getCurrentUser() async {
    await _ensureInitialized();

    try {
      // Kiểm tra cache trước
      final cachedUser = _prefs!.getString(_kCurrentUserKey);
      if (cachedUser != null) {
        return AppUser.fromMap(jsonDecode(cachedUser));
      }

      // Nếu không có cache, gọi API
      final response = await _apiClient.getCurrentUser();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = AppUser(
          id: data['id'],
          username: data['username'],
          email: data['email'],
          passwordHash: '',
          salt: '',
          createdAt: DateTime.parse(data['created_at']),
          isAdmin: data['is_admin'] ?? false,
        );

        // Lưu vào cache
        await _prefs!.setInt(_kSessionUserId, user.id!);
        await _prefs!.setString(_kCurrentUserKey, jsonEncode(user.toMap()));

        return user;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Lấy tất cả users (cho admin)
  Future<List<AppUser>> getAllUsers() async {
    await _ensureInitialized();

    try {
      final response = await _apiClient.getAllUsers();

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => AppUser(
                  id: json['id'],
                  username: json['username'],
                  email: json['email'],
                  passwordHash: '',
                  salt: '',
                  createdAt: DateTime.parse(json['created_at']),
                  isAdmin: json['is_admin'] ?? false,
                ))
            .toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Đếm số users
  Future<int> getUserCount() async {
    await _ensureInitialized();

    try {
      final users = await getAllUsers();
      return users.length;
    } catch (e) {
      rethrow;
    }
  }

  // Kiểm tra user có tồn tại không
  Future<bool> userExists(String usernameOrEmail) async {
    await _ensureInitialized();

    try {
      // Placeholder - tương lai sẽ call API
      return false;
    } catch (e) {
      return false;
    }
  }

  // Kiểm tra user hiện tại có phải admin không
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  // Xóa user (chỉ admin)
  Future<bool> deleteUser(int userId) async {
    await _ensureInitialized();

    try {
      final response = await _apiClient.deleteUserAdmin(userId);
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Xóa tài khoản của chính mình
  Future<bool> deleteOwnAccount() async {
    await _ensureInitialized();

    try {
      // Placeholder - tương lai sẽ call API
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật trạng thái admin (chỉ admin)
  Future<bool> updateUserAdminStatus(int userId, bool isAdmin) async {
    await _ensureInitialized();

    try {
      final response = await _apiClient.updateUserAdminStatus(userId, isAdmin);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Không thể cập nhật quyền');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Đổi mật khẩu
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _ensureInitialized();

    try {
      // Placeholder - tương lai sẽ call API
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Ban user với thời gian cụ thể
  Future<bool> banUser(int userId, Duration duration, {String? reason}) async {
    await _ensureInitialized();

    try {
      final response = await _apiClient.banUser(
        userId,
        duration,
        reason ?? 'Vi phạm quy định',
      );

      print('Ban user response status: ${response.statusCode}');
      print('Ban user response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Không thể cấm user');
      }
    } catch (e) {
      print('Ban user error: $e');
      rethrow;
    }
  }

  // Unban user (bỏ cấm)
  Future<bool> unbanUser(int userId) async {
    await _ensureInitialized();

    try {
      final response = await _apiClient.unbanUser(userId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Không thể bỏ cấm user');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Kiểm tra user có bị cấm không
  Future<bool> isUserBanned(AppUser user) async {
    // Backend sẽ handle logic check
    return false;
  }

  // Lấy thời gian còn lại của ban (giây)
  Future<int?> getRemainingBanTime(AppUser user) async {
    // Backend sẽ handle logic
    return null;
  }
}
