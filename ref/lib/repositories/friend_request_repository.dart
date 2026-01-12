import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import 'announcement_repository.dart';

class FriendRequestRepository {
  Future<Database> get _db async {
    return AppDatabase.instance.database;
  }

  // Tìm user bằng username hoặc email (chỉ tìm user thường, không phải admin)
  Future<Map<String, dynamic>?> findUserByUsernameOrEmail(String query) async {
    final db = await _db;
    final maps = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND is_admin = ?',
      whereArgs: [query, query, 0],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  // Gửi lời mời kết bạn - LOGIC ĐƠN GIẢN
  Future<bool> sendFriendRequest(int senderId, int receiverId) async {
    final db = await _db;
    final now = DateTime.now();
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      // LOGIC ĐƠN GIẢN: Chỉ kiểm tra xem đã là bạn bè chưa
      final isAlreadyFriends = await areFriends(senderId, receiverId);
      if (isAlreadyFriends) {
        print('DEBUG: Cannot send request - already friends');
        return false;
      }

      // Xóa tất cả requests cũ giữa 2 user này (nếu có)
      await db.delete(
        'friend_requests',
        where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        whereArgs: [senderId, receiverId, receiverId, senderId],
      );

      // Tạo request mới
      await db.insert('friend_requests', {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
        'created_at': createdAt,
      });
      
      print('DEBUG: Friend request sent successfully');
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  // Lấy danh sách lời mời kết bạn đã nhận
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests(int userId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT fr.*, u.username, u.email 
      FROM friend_requests fr
      JOIN users u ON fr.sender_id = u.id
      WHERE fr.receiver_id = ? AND fr.status = 'pending'
      ORDER BY fr.created_at DESC
    ''', [userId]);
    return maps;
  }

  // Lấy danh sách lời mời kết bạn đã gửi
  Future<List<Map<String, dynamic>>> getSentFriendRequests(int userId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT fr.*, u.username, u.email 
      FROM friend_requests fr
      JOIN users u ON fr.receiver_id = u.id
      WHERE fr.sender_id = ? AND fr.status = 'pending'
      ORDER BY fr.created_at DESC
    ''', [userId]);
    return maps;
  }

  // Chấp nhận lời mời kết bạn
  Future<bool> acceptFriendRequest(int requestId) async {
    final db = await _db;
    final now = DateTime.now();
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      await db.transaction((txn) async {
        // Cập nhật status của friend_request
        await txn.update(
          'friend_requests',
          {'status': 'accepted'},
          where: 'id = ?',
          whereArgs: [requestId],
        );

        // Lấy thông tin request
        final request = await txn.query(
          'friend_requests',
          where: 'id = ?',
          whereArgs: [requestId],
        );
        
        if (request.isNotEmpty) {
          final senderId = request.first['sender_id'] as int;
          final receiverId = request.first['receiver_id'] as int;

          // Thêm vào bảng friends (cả 2 chiều)
          await txn.insert('friends', {
            'user_id': senderId,
            'friend_id': receiverId,
            'created_at': createdAt,
          });
          
          await txn.insert('friends', {
            'user_id': receiverId,
            'friend_id': senderId,
            'created_at': createdAt,
          });
        }
      });
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  // Từ chối lời mời kết bạn
  Future<bool> rejectFriendRequest(int requestId) async {
    final db = await _db;
    try {
      await db.update(
        'friend_requests',
        {'status': 'rejected'},
        where: 'id = ?',
        whereArgs: [requestId],
      );
      return true;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  // Lấy danh sách bạn bè
  Future<List<Map<String, dynamic>>> getFriends(int userId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT f.*, u.username, u.email 
      FROM friends f
      JOIN users u ON f.friend_id = u.id
      WHERE f.user_id = ?
      ORDER BY f.created_at DESC
    ''', [userId]);
    return maps;
  }

  // Hủy kết bạn - LOGIC ĐƠN GIẢN
  Future<bool> removeFriend(int userId, int friendId) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // Xóa cả 2 chiều trong bảng friends
        await txn.delete(
          'friends',
          where: 'user_id = ? AND friend_id = ?',
          whereArgs: [userId, friendId],
        );
        await txn.delete(
          'friends',
          where: 'user_id = ? AND friend_id = ?',
          whereArgs: [friendId, userId],
        );
        
        // Xóa cả 2 chiều trong bảng friend_requests (để có thể gửi lại lời mời)
        await txn.delete(
          'friend_requests',
          where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
          whereArgs: [userId, friendId, friendId, userId],
        );
      });
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // Kiểm tra xem 2 user đã là bạn bè chưa
  Future<bool> areFriends(int userId1, int userId2) async {
    final db = await _db;
    final maps = await db.query(
      'friends',
      where: '(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
    );
    return maps.isNotEmpty;
  }

  // Kiểm tra xem đã gửi lời mời kết bạn chưa
  Future<bool> hasPendingRequest(int senderId, int receiverId) async {
    final db = await _db;
    final maps = await db.query(
      'friend_requests',
      where: 'sender_id = ? AND receiver_id = ? AND status = ?',
      whereArgs: [senderId, receiverId, 'pending'],
    );
    return maps.isNotEmpty;
  }

  // Kiểm tra trạng thái friend request giữa 2 user
  Future<String?> getFriendRequestStatus(int userId1, int userId2) async {
    final db = await _db;
    final maps = await db.query(
      'friend_requests',
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return maps.first['status'] as String?;
  }
}
