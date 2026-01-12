import 'package:flutter/material.dart';
import '../repositories/announcement_repository.dart';
import '../models/announcement.dart';
import 'announcement_detail_screen.dart';
import 'friends_screen.dart';

class UserNotificationScreen extends StatefulWidget {
  final int userId;
  final VoidCallback? onNotificationRead;

  const UserNotificationScreen({
    super.key,
    required this.userId,
    this.onNotificationRead,
  });

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final _repo = AnnouncementRepository();
  List<Announcement> _announcements = [];
  Set<int> _readAnnouncementIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final announcements = await _repo.getAllAnnouncementsForUser(widget.userId);
      final readIds = <int>{};
      
      for (final announcement in announcements) {
        if (announcement.id != null) {
          final isRead = await _repo.isAnnouncementReadByUser(widget.userId, announcement.id!);
          if (isRead) {
            readIds.add(announcement.id!);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _readAnnouncementIds = readIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int announcementId) async {
    try {
      await _repo.markAnnouncementAsRead(widget.userId, announcementId);
      if (mounted) {
        setState(() {
          _readAnnouncementIds.add(announcementId);
        });
        // Refresh notification badge count
        _refreshNotificationBadge();
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void _refreshNotificationBadge() {
    // Gọi callback để refresh notification badge
    widget.onNotificationRead?.call();
  }

  Future<void> _deleteAllRead() async {
    try {
      await _repo.deleteAllReadAnnouncements(widget.userId);
      if (mounted) {
        await _loadAnnouncements();
      }
    } catch (e) {
      print('Error deleting read announcements: $e');
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
                    // Delete all read button
                    if (_readAnnouncementIds.isNotEmpty)
                      GestureDetector(
                        onTap: _deleteAllRead,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                            size: 24,
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF57BCCE)),
                          ),
                        )
                      : _announcements.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có thông báo nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = _announcements[index];
                                final isRead = announcement.id != null && 
                                    _readAnnouncementIds.contains(announcement.id);
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRead 
                                          ? Colors.grey[300]! 
                                          : const Color(0xFFDC2626),
                                      width: isRead ? 1 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        // Điều hướng đến chi tiết thông báo
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AnnouncementDetailScreen(
                                              announcement: announcement,
                                              userId: widget.userId,
                                              onRead: () {
                                                if (announcement.id != null) {
                                                  _markAsRead(announcement.id!);
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                        // Reload to update read status
                                        await _loadAnnouncements();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header row
                                            Row(
                                              children: [
                                                // Admin badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDC2626),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.admin_panel_settings,
                                                        color: Colors.white,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        announcement.createdBy,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Unread indicator
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFDC2626),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Title
                                            Text(
                                              announcement.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isRead ? Colors.grey[600] : const Color(0xFF1F2937),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            // Content preview
                                            Text(
                                              announcement.content,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isRead ? Colors.grey[500] : Colors.grey[700],
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),
                                            // Date
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: Colors.grey[500],
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  announcement.createdAt,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Read status
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isRead ? Colors.green[100] : Colors.orange[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isRead ? 'Đã đọc' : 'Chưa đọc',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isRead ? Colors.green[700] : Colors.orange[700],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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