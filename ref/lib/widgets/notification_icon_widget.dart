import 'package:flutter/material.dart';
import 'dart:async';
import '../repositories/announcement_repository.dart';
import '../repositories/auth_repository.dart';
import '../screens/notifications_screen.dart';

class NotificationIconWidget extends StatefulWidget {
  const NotificationIconWidget({super.key});

  @override
  State<NotificationIconWidget> createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  final _repo = AnnouncementRepository();
  final _authRepo = AuthRepository();
  int _unreadCount = 0;
  int? _currentUserId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final user = await _authRepo.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.id;
        });
        // Load unread count sau khi có user ID
        if (_currentUserId != null) {
          await _loadUnreadCount();
        }
      }
    } catch (e) {
      print('DEBUG NOTIFICATION ICON: Error getting current user: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_currentUserId == null) return;
    
    try {
      print('DEBUG NOTIFICATION ICON: Loading unread count for user $_currentUserId');
      final count = await _repo.getUnreadAnnouncementCount(_currentUserId!);
      print('DEBUG NOTIFICATION ICON: Unread count: $count');
      
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
        print('DEBUG NOTIFICATION ICON: Updated unread count to: $_unreadCount');
      }
    } catch (e) {
      print('DEBUG NOTIFICATION ICON: Error loading unread count: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentUserId != null) {
        _loadUnreadCount();
      }
    });
  }

  void _navigateToNotifications() {
    print('DEBUG NOTIFICATION ICON: Navigating to notifications screen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) {
      // Refresh unread count khi quay lại từ notifications screen
      print('DEBUG NOTIFICATION ICON: Returned from notifications screen, refreshing count');
      _loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToNotifications,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon thông báo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Badge số lượng thông báo chưa đọc
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

