import 'package:flutter/material.dart';
import '../../../shared/models/announcement.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;
  final int userId;
  final VoidCallback? onRead;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    required this.userId,
    this.onRead,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final _repo = AnnouncementRepository();
  bool _isRead = false;

  @override
  void initState() {
    super.initState();
    _checkIfRead();
  }

  Future<void> _checkIfRead() async {
    if (widget.announcement.id == null) return;

    try {
      final isRead = await _repo.isAnnouncementReadByUser(
          widget.userId, widget.announcement.id!);
      if (mounted) {
        setState(() {
          _isRead = isRead;
        });
      }
    } catch (e) {
      print('Error checking read status: $e');
    }
  }

  Future<void> _markAsRead() async {
    if (_isRead || widget.announcement.id == null) return;

    try {
      await _repo.markAnnouncementAsRead(
          widget.userId, widget.announcement.id!);
      if (mounted) {
        setState(() {
          _isRead = true;
        });
        widget.onRead?.call();
        // Delay một chút để đảm bảo database đã được cập nhật
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onRead?.call();
        });
      }
    } catch (e) {
      print('Error marking as read: $e');
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
                        'Chi tiết thông báo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isRead ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isRead ? 'Đã đọc' : 'Chưa đọc',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'User: ${widget.announcement.createdBy}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Role
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Role: Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Row(
                          children: [
                            Icon(
                              Icons.title,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tiêu đề: ${widget.announcement.title}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ngày tạo: ${widget.announcement.createdAt}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Divider
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF57BCCE).withOpacity(0.3),
                                const Color(0xFFA8D3CA).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Content
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nội dung: ${widget.announcement.content}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Mark as read button (if not read)
                        if (!_isRead)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _markAsRead,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF57BCCE),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đánh dấu đã đọc',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
