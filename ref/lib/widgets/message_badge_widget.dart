import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/message_repository.dart';

class MessageBadgeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final ValueNotifier<int>? refreshNotifier;

  const MessageBadgeWidget({
    super.key,
    required this.child,
    this.onTap,
    this.refreshNotifier,
  });

  @override
  State<MessageBadgeWidget> createState() => _MessageBadgeWidgetState();
}

class _MessageBadgeWidgetState extends State<MessageBadgeWidget> {
  final MessageRepository _messageRepo = MessageRepository();
  int _unreadCount = 0;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Lắng nghe SharedPreferences để refresh real-time
    _startListeningToRefresh();
  }

  @override
  void dispose() {
    // Hủy lắng nghe ValueNotifier
    widget.refreshNotifier?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _loadUnreadCount();
  }

  void _startListeningToRefresh() {
    // Lắng nghe SharedPreferences để refresh khi có thay đổi
    _checkForRefresh();
  }

  void _checkForRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshCount = prefs.getInt('message_refresh_count') ?? 0;
    
    // Nếu có thay đổi, refresh và lưu lại
    if (refreshCount > 0) {
      _loadUnreadCount();
      await prefs.setInt('message_refresh_count', 0);
    }
    
    // Kiểm tra lại sau 1 giây
    Future.delayed(const Duration(seconds: 1), _checkForRefresh);
  }

  Future<void> _loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('session_user_id') ?? 0;
    
    if (_currentUserId == 0) return;

    try {
      // Đếm tổng số tin nhắn chưa đọc
      final count = await _messageRepo.getUnreadCount(_currentUserId);
      
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread message count: $e');
    }
  }

  void refreshCount() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: _unreadCount > 0 
              ? Border.all(color: Colors.red, width: 2)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
