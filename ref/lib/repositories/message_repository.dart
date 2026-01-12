import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../data/app_database.dart';
import '../models/message.dart';

class MessageRepository {
  static final MessageRepository _instance = MessageRepository._internal();
  factory MessageRepository() => _instance;
  MessageRepository._internal();

  Future<Database> get _db => AppDatabase.instance.database;

  // Gửi tin nhắn
  Future<int> sendMessage(int senderId, int receiverId, String content) async {
    final db = await _db;
    final now = DateTime.now();
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return await db.insert('messages', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt,
      'is_read': 0,
    });
  }

  // Lấy tin nhắn giữa 2 user
  Future<List<Message>> getMessages(int userId1, int userId2) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT * FROM messages 
      WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)
      ORDER BY created_at ASC
    ''', [userId1, userId2, userId2, userId1]);
    
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  // Lấy danh sách chat (bao gồm cả bạn bè chưa nhắn tin)
  Future<List<Map<String, dynamic>>> getChatList(int userId) async {
    final db = await _db;
    
    // Lấy danh sách bạn bè
    final friendsMaps = await db.rawQuery('''
      SELECT DISTINCT
        CASE 
          WHEN user_id = ? THEN friend_id 
          ELSE user_id 
        END as other_user_id,
        u.username,
        u.email,
        NULL as last_message,
        NULL as last_message_time,
        1 as is_read,
        0 as is_sent_by_me
      FROM friends f
      JOIN users u ON u.id = CASE 
        WHEN f.user_id = ? THEN f.friend_id 
        ELSE f.user_id 
      END
      WHERE f.user_id = ? OR f.friend_id = ?
    ''', [userId, userId, userId, userId]);
    
    // Lấy tin nhắn cuối cùng với mỗi bạn bè
    final messagesMaps = await db.rawQuery('''
      SELECT DISTINCT
        CASE 
          WHEN sender_id = ? THEN receiver_id 
          ELSE sender_id 
        END as other_user_id,
        u.username,
        u.email,
        m.content as last_message,
        m.created_at as last_message_time,
        m.is_read,
        CASE 
          WHEN sender_id = ? THEN 1 
          ELSE 0 
        END as is_sent_by_me
      FROM messages m
      JOIN users u ON u.id = CASE 
        WHEN m.sender_id = ? THEN m.receiver_id 
        ELSE m.sender_id 
      END
      WHERE m.id IN (
        SELECT MAX(id) 
        FROM messages 
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY CASE 
          WHEN sender_id = ? THEN receiver_id 
          ELSE sender_id 
        END
      )
    ''', [userId, userId, userId, userId, userId, userId]);
    
    // Merge danh sách bạn bè và tin nhắn
    final Map<int, Map<String, dynamic>> chatMap = {};
    
    // Thêm bạn bè vào map
    for (final friend in friendsMaps) {
      final otherUserId = friend['other_user_id'] as int;
      chatMap[otherUserId] = friend;
    }
    
    // Cập nhật với tin nhắn cuối cùng
    for (final message in messagesMaps) {
      final otherUserId = message['other_user_id'] as int;
      if (chatMap.containsKey(otherUserId)) {
        chatMap[otherUserId] = message;
      }
    }
    
    // Sắp xếp theo thời gian tin nhắn cuối (tin nhắn trước, bạn bè chưa nhắn tin sau)
    final chatList = chatMap.values.toList();
    chatList.sort((a, b) {
      final timeA = a['last_message_time'] as String?;
      final timeB = b['last_message_time'] as String?;
      
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1; // Bạn bè chưa nhắn tin xuống cuối
      if (timeB == null) return -1;
      
      return timeB.compareTo(timeA); // Tin nhắn mới nhất lên đầu
    });
    
    return chatList;
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markAsRead(int senderId, int receiverId) async {
    final db = await _db;
    await db.update(
      'messages',
      {'is_read': 1},
      where: 'sender_id = ? AND receiver_id = ?',
      whereArgs: [senderId, receiverId],
    );
  }

  // Đếm tin nhắn chưa đọc
  Future<int> getUnreadCount(int userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM messages 
      WHERE receiver_id = ? AND is_read = 0
    ''', [userId]);
    
    return result.first['count'] as int;
  }

  // Xóa tin nhắn
  Future<void> deleteMessage(int messageId) async {
    final db = await _db;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Xóa tất cả tin nhắn với một user
  Future<void> deleteAllMessages(int userId1, int userId2) async {
    final db = await _db;
    await db.delete(
      'messages',
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [userId1, userId2, userId2, userId1],
    );
  }
}
