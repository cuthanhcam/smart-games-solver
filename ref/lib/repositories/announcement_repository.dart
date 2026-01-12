import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  Future<Database> get _db async {
    // Đảm bảo database được sửa lỗi trước khi sử dụng
    await AppDatabase.instance.fixDatabaseIssues();
    return AppDatabase.instance.database;
  }

  // Tạo thông báo mới
  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required String createdBy,
    // int displayDurationMinutes = 2, // Đã bỏ chức năng
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final announcement = Announcement(
      title: title.trim(),
      content: content.trim(),
      createdAt: createdAt,
      createdBy: createdBy,
      // displayDurationMinutes: displayDurationMinutes, // Đã bỏ chức năng
    );

    final id = await db.insert('announcements', announcement.toMap());
    return announcement.copyWith(id: id);
  }

  // Lấy tất cả thông báo (admin)
  Future<List<Announcement>> getAllAnnouncements() async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Announcement.fromMap(map)).toList();
  }

  // Lấy thông báo đang hoạt động (user) - Đã bỏ chức năng thời gian
  Future<List<Announcement>> getActiveAnnouncements({int? userId}) async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => Announcement.fromMap(map)).toList();
  }

  // Lấy tất cả thông báo cho user (bao gồm cả đã đọc và chưa đọc) - Đã bỏ chức năng thời gian
  Future<List<Announcement>> getAllAnnouncementsForUser(int userId) async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => Announcement.fromMap(map)).toList();
  }

  // Ẩn thông báo cho user cụ thể
  Future<void> hideAnnouncementForUser(int userId, int announcementId) async {
    final db = await _db;
    await db.insert(
      'hidden_announcements',
      {
        'user_id': userId,
        'announcement_id': announcementId,
        'hidden_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Kiểm tra thông báo có bị ẩn bởi user không
  Future<bool> isAnnouncementHiddenByUser(int userId, int announcementId) async {
    final db = await _db;
    final maps = await db.query(
      'hidden_announcements',
      where: 'user_id = ? AND announcement_id = ?',
      whereArgs: [userId, announcementId],
    );
    return maps.isNotEmpty;
  }

  // Lấy danh sách ID thông báo đã bị ẩn bởi user
  Future<List<int>> getHiddenAnnouncementIds(int userId) async {
    final db = await _db;
    final maps = await db.query(
      'hidden_announcements',
      where: 'user_id = ?',
      whereArgs: [userId],
      columns: ['announcement_id'],
    );
    return maps.map((map) => map['announcement_id'] as int).toList();
  }

  // Hiển thị lại thông báo cho user
  Future<void> showAnnouncementForUser(int userId, int announcementId) async {
    final db = await _db;
    await db.delete(
      'hidden_announcements',
      where: 'user_id = ? AND announcement_id = ?',
      whereArgs: [userId, announcementId],
    );
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markAnnouncementAsRead(int userId, int announcementId) async {
    final db = await _db;
    await db.insert(
      'read_announcements',
      {
        'user_id': userId,
        'announcement_id': announcementId,
        'read_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Kiểm tra thông báo đã được đọc bởi user chưa
  Future<bool> isAnnouncementReadByUser(int userId, int announcementId) async {
    final db = await _db;
    final maps = await db.query(
      'read_announcements',
      where: 'user_id = ? AND announcement_id = ?',
      whereArgs: [userId, announcementId],
    );
    return maps.isNotEmpty;
  }

  // Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadAnnouncementCount(int userId) async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    
    int unreadCount = 0;
    for (final map in maps) {
      final announcementId = map['id'] as int;
      final isRead = await isAnnouncementReadByUser(userId, announcementId);
      if (!isRead) {
        unreadCount++;
      }
    }
    
    return unreadCount;
  }

  // Cập nhật trạng thái thông báo
  Future<void> updateAnnouncementStatus(int id, bool isActive) async {
    final db = await _db;
    await db.update(
      'announcements',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Xóa thông báo
  Future<void> deleteAnnouncement(int id) async {
    final db = await _db;
    await db.delete(
      'announcements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lấy thông báo theo ID
  Future<Announcement?> getAnnouncementById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'announcements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Announcement.fromMap(maps.first);
  }

  // Xóa tất cả thông báo đã đọc của user
  Future<void> deleteAllReadAnnouncements(int userId) async {
    final db = await _db;
    await db.delete(
      'read_announcements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
