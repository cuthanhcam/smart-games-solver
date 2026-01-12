import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/app_user.dart';

class AuthRepository {
  static const _kSessionUserId = 'session_user_id';

  Future<Database> get _db async => AppDatabase.instance.database;

  // Salt ngẫu nhiên (hex)
  String _generateSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Hash = SHA-256(salt + password)
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Đăng ký: username + email + password
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final db = await _db;

    // trùng username / email?
    final existingUser = await db.query('users',
        where: 'username = ? OR email = ?', whereArgs: [username.trim(), email.trim()]);
    if (existingUser.isNotEmpty) {
      throw Exception('Username hoặc email đã tồn tại');
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    final user = AppUser(
      username: username.trim(),
      email: email.trim(),
      passwordHash: hash,
      salt: salt,
      createdAt: DateTime.now(),
      isAdmin: false,
    );

    final id = await db.insert('users', user.toMap());
    final newUser = user.copyWith(id: id);

    return newUser;
  }

  // Đăng nhập: username/email + password
  Future<AppUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final db = await _db;

      // Tìm user theo username hoặc email
      final users = await db.query('users',
          where: 'username = ? OR email = ?',
          whereArgs: [usernameOrEmail.trim(), usernameOrEmail.trim()]);

      if (users.isEmpty) {
        throw Exception('Tài khoản không tồn tại');
      }

      final userData = users.first;
      final user = AppUser.fromMap(userData);

      // Kiểm tra password
      final hash = _hashPassword(password, user.salt);
      if (hash != user.passwordHash) {
        throw Exception('Mật khẩu không đúng');
      }

      // Kiểm tra user có bị cấm không
      if (user.bannedUntil != null) {
        final now = DateTime.now();
        if (now.isBefore(user.bannedUntil!)) {
          final remainingSeconds = user.bannedUntil!.difference(now).inSeconds;
          final remainingMinutes = (remainingSeconds / 60).ceil();
          final remainingHours = (remainingSeconds / 3600).ceil();
          
          String timeString;
          if (remainingSeconds < 60) {
            timeString = '$remainingSeconds giây';
          } else if (remainingSeconds < 3600) {
            timeString = '$remainingMinutes phút';
          } else {
            timeString = '$remainingHours giờ';
          }
          
          throw Exception('Tài khoản của bạn đã bị cấm trong vòng $timeString, vui lòng quay lại sau');
        }
      }

      // Lưu session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSessionUserId, user.id!);

      return user;
    } catch (e) {
      // Re-throw exception để login_page có thể xử lý
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUserId);
  }

  // Lấy user hiện tại
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_kSessionUserId);
    if (userId == null) return null;

    final db = await _db;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (users.isEmpty) return null;

    return AppUser.fromMap(users.first);
  }

  // Lấy tất cả users (cho admin)
  Future<List<AppUser>> getAllUsers() async {
    final db = await _db;
    final users = await db.query('users', orderBy: 'created_at DESC');
    return users.map((user) => AppUser.fromMap(user)).toList();
  }

  // Đếm số users
  Future<int> getUserCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int;
  }

  // Kiểm tra user có tồn tại không
  Future<bool> userExists(String usernameOrEmail) async {
    final db = await _db;
    final users = await db.query('users',
        where: 'username = ? OR email = ?',
        whereArgs: [usernameOrEmail, usernameOrEmail]);
    return users.isNotEmpty;
  }

  // Kiểm tra user hiện tại có phải admin không
  Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  // Xóa user (chỉ admin)
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await _db;
      
      // Kiểm tra quyền admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Chỉ admin mới có quyền xóa user');
      }

      // Không cho phép xóa chính mình
      final currentUser = await getCurrentUser();
      if (currentUser?.id == userId) {
        throw Exception('Không thể xóa chính mình');
      }

      // Xóa user
      final result = await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi xóa user: $e');
    }
  }

  // Xóa tài khoản của chính mình
  Future<bool> deleteOwnAccount() async {
    try {
      final db = await _db;
      final currentUser = await getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Xóa tài khoản của chính mình
      final result = await db.delete('users', where: 'id = ?', whereArgs: [currentUser.id]);
      
      if (result > 0) {
        // Xóa session sau khi xóa tài khoản thành công
        await logout();
      }
      
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi xóa tài khoản: $e');
    }
  }

  // Cập nhật trạng thái admin (chỉ admin)
  Future<bool> updateUserAdminStatus(int userId, bool isAdmin) async {
    try {
      final db = await _db;
      
      // Kiểm tra quyền admin
      final currentUserIsAdmin = await isCurrentUserAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Chỉ admin mới có quyền cập nhật trạng thái admin');
      }

      // Không cho phép thay đổi trạng thái admin của chính mình
      final currentUser = await getCurrentUser();
      if (currentUser?.id == userId) {
        throw Exception('Không thể thay đổi trạng thái admin của chính mình');
      }

      // Cập nhật trạng thái admin
      final result = await db.update(
        'users',
        {'is_admin': isAdmin ? 1 : 0},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái admin: $e');
    }
  }

  // Đổi mật khẩu
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final db = await _db;
      final currentUser = await getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Kiểm tra mật khẩu hiện tại
      final currentHash = _hashPassword(currentPassword, currentUser.salt);
      if (currentHash != currentUser.passwordHash) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }

      // Tạo salt và hash mới
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);

      // Cập nhật mật khẩu mới
      final result = await db.update(
        'users',
        {
          'password_hash': newHash,
          'salt': newSalt,
        },
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi đổi mật khẩu: $e');
    }
  }

  // Ban user với thời gian cụ thể
  Future<bool> banUser(int userId, Duration duration) async {
    try {
      final db = await _db;
      final bannedUntil = DateTime.now().add(duration);
      
      final result = await db.update(
        'users',
        {'banned_until': bannedUntil.toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi cấm user: $e');
    }
  }

  // Unban user (bỏ cấm)
  Future<bool> unbanUser(int userId) async {
    try {
      final db = await _db;
      
      final result = await db.update(
        'users',
        {'banned_until': null},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi bỏ cấm user: $e');
    }
  }

  // Kiểm tra user có bị cấm không
  Future<bool> isUserBanned(AppUser user) async {
    if (user.bannedUntil == null) return false;
    
    final now = DateTime.now();
    return now.isBefore(user.bannedUntil!);
  }

  // Lấy thời gian còn lại của ban (giây)
  Future<int?> getRemainingBanTime(AppUser user) async {
    if (user.bannedUntil == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(user.bannedUntil!)) return null;
    
    return user.bannedUntil!.difference(now).inSeconds;
  }
}