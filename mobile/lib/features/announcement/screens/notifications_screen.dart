import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/announcement_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../shared/models/announcement.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AnnouncementRepository _repo = AnnouncementRepository();
  List<Announcement> _announcements = [];
  Set<int> _readAnnouncementIds = {};
  int? _currentUserId;
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndAnnouncements();
  }

  Future<void> _loadUserAndAnnouncements() async {
    try {
      // Lấy user ID từ AuthRepository thay vì SharedPreferences
      final authRepo = AuthRepository();
      final user = await authRepo.getCurrentUser();

      if (user?.id != null) {
        _currentUserId = user!.id;
        print(
            'DEBUG: Current user ID from AuthRepository: $_currentUserId (${user.username})');
        await _loadAnnouncements();
      } else {
        print('DEBUG: No user logged in');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnnouncements() async {
    if (_currentUserId == null) {
      print('DEBUG: User ID is null, cannot load announcements');
      setState(() => _isLoading = false);
      return;
    }

    print('DEBUG: Loading announcements for user $_currentUserId');
    setState(() => _isLoading = true);

    try {
      // Thêm timeout để tránh load mãi
      await Future.delayed(const Duration(milliseconds: 500));

      // Lấy thông báo active để debug (user chỉ xem active)
      final allAnnouncementsMaps =
          await _repo.getAllAnnouncements(activeOnly: true);
      final allAnnouncements =
          allAnnouncementsMaps.map((map) => Announcement.fromMap(map)).toList();
      print(
          'DEBUG: Found ${allAnnouncements.length} active announcements in database');

      // Lấy thông báo cho user (chỉ active)
      final announcementsMaps =
          await _repo.getAllAnnouncementsForUser(_currentUserId!);
      final announcements =
          announcementsMaps.map((map) => Announcement.fromMap(map)).toList();
      print(
          'DEBUG: Found ${announcements.length} active announcements for user');

      // Debug: In ra chi tiết các thông báo
      for (final announcement in announcements) {
        print(
            'DEBUG: Announcement ${announcement.id}: "${announcement.title}" (active: ${announcement.isActive})');
      }

      // Get read announcement IDs
      final readIds = <int>{};
      for (final announcement in announcements) {
        if (announcement.id != null) {
          final isRead = await _repo.isAnnouncementReadByUser(
              _currentUserId!, announcement.id!);
          if (isRead) {
            readIds.add(announcement.id!);
          }
        }
      }
      print('DEBUG: ${readIds.length} read announcements');

      setState(() {
        _announcements = announcements;
        _readAnnouncementIds = readIds;
        _unreadCount = announcements
            .where((a) => a.id != null && !readIds.contains(a.id))
            .length;
        _isLoading = false;
      });
      print(
          'DEBUG: Loading completed. Announcements: ${_announcements.length}, Unread: $_unreadCount');
    } catch (e) {
      print('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        title: Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xóa thông báo này?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Bạn có chắc chắn muốn xóa thông báo "${announcement.title}"?',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('Xóa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repo.hideAnnouncementForUser(_currentUserId!, announcement.id!);

      if (mounted) {
        setState(() {
          _announcements.removeWhere((a) => a.id == announcement.id);
          _readAnnouncementIds.remove(announcement.id!);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        });
      }
    } catch (e) {
      print('Error deleting announcement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa thông báo: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllAnnouncements() async {
    if (_currentUserId == null || _announcements.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        title: Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xóa tất cả thông báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Bạn có chắc chắn muốn xóa tất cả ${_announcements.length} thông báo?',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('Xóa tất cả'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final announcement in _announcements) {
        if (announcement.id != null) {
          await _repo.hideAnnouncementForUser(
              _currentUserId!, announcement.id!);
        }
      }

      if (mounted) {
        setState(() {
          _announcements.clear();
          _readAnnouncementIds.clear();
          _unreadCount = 0;
        });
      }
    } catch (e) {
      print('Error deleting all announcements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa thông báo: $e'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAnnouncementDetail(Announcement announcement) async {
    final isRead = announcement.id != null &&
        _readAnnouncementIds.contains(announcement.id);

    if (!isRead && announcement.id != null) {
      try {
        await _repo.markAnnouncementAsRead(_currentUserId!, announcement.id!);
        setState(() {
          _readAnnouncementIds.add(announcement.id!);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        });
      } catch (e) {
        print('Error marking as read: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF57BCCE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications,
                color: Color(0xFF57BCCE),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                announcement.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5568),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  'Người tạo',
                  announcement.adminId != null
                      ? 'Admin #${announcement.adminId}'
                      : 'Admin'),
              _buildDetailRow(
                  'Ngày tạo', _formatDateTime(announcement.createdAt)),
              _buildDetailRow('Trạng thái', isRead ? 'Đã đọc' : 'Chưa đọc',
                  valueColor:
                      isRead ? Colors.grey.shade600 : Colors.red.shade600),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(announcement);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text('Xóa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF718096),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';

    try {
      // Parse UTC datetime and convert to Vietnam timezone (UTC+7)
      final utcDateTime = DateTime.parse(dateTimeString);
      final vietnamDateTime = utcDateTime.add(const Duration(hours: 7));
      final now = DateTime.now();
      final difference = now.difference(vietnamDateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF57BCCE),
              Color(0xFFA8D3CA),
              Color(0xFFDADCB7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Badge số lượng chưa đọc
                    if (_unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadCount chưa đọc',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Nút xóa tất cả
                    if (_announcements.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _deleteAllAnnouncements,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_sweep,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF57BCCE)),
                          ),
                        )
                      : _announcements.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Color(0xFF57BCCE),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Không có thông báo nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF57BCCE),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Các thông báo từ admin sẽ hiển thị ở đây',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF57BCCE),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAnnouncements,
                              color: const Color(0xFF57BCCE),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _announcements.length,
                                itemBuilder: (context, index) {
                                  final announcement = _announcements[index];
                                  final isActive = announcement.isActive;
                                  final isRead = announcement.id != null &&
                                      _readAnnouncementIds
                                          .contains(announcement.id);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF57BCCE),
                                          Color(0xFFA8D3CA),
                                          Color(0xFFDADCB7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF57BCCE)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.9),
                                        child: Icon(
                                          Icons.notifications,
                                          color: const Color(0xFF57BCCE),
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        announcement.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 3),
                                          Text(
                                            announcement.content,
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 10,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  announcement.adminId != null
                                                      ? 'Admin #${announcement.adminId}'
                                                      : 'Admin',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 10,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.access_time,
                                                size: 10,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                announcement.createdAt != null
                                                    ? _formatDateTime(
                                                        announcement.createdAt!)
                                                    : 'N/A',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Status indicator - chỉ hiển thị viền đỏ cho "chưa đọc"
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isRead
                                                  ? Colors.transparent
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                              border: isRead
                                                  ? Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () =>
                                          _showAnnouncementDetail(announcement),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
