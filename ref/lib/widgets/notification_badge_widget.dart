import 'package:flutter/material.dart';
import '../repositories/announcement_repository.dart';
import '../models/announcement.dart';

class NotificationBadgeWidget extends StatefulWidget {
  final int userId;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    required this.userId,
    this.onTap,
  });

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
  final _repo = AnnouncementRepository();
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  @override
  void didUpdateWidget(NotificationBadgeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh count khi widget được rebuild
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _repo.getUnreadAnnouncementCount(widget.userId);
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  void updateUnreadCount() {
    _loadUnreadCount();
  }

  // Method để refresh count từ bên ngoài
  void refreshCount() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF57BCCE),
            Color(0xFFA8D3CA),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57BCCE).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: _isLoading
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF57BCCE)),
                    ),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
      ),
    );
  }
}
