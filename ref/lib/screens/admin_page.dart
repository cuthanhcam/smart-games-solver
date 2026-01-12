import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/auth_repository.dart';
import '../models/app_user.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _repo = AuthRepository();
  List<AppUser> _users = [];
  bool _isLoading = true;
  int _totalUsers = 0;
  int _adminCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _repo.getAllUsers();
      final totalUsers = await _repo.getUserCount();
      final adminCount = users.where((user) => user.isAdmin).length;
      
      // Sắp xếp: admin lên đầu, sau đó theo thời gian tạo
      final sortedUsers = List<AppUser>.from(users);
      sortedUsers.sort((a, b) {
        // Admin lên đầu
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        // Nếu cùng loại, sắp xếp theo thời gian tạo (mới nhất lên đầu)
        return b.createdAt.compareTo(a.createdAt);
      });
      
      setState(() {
        _users = sortedUsers;
        _totalUsers = totalUsers;
        _adminCount = adminCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi khi tải danh sách user: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    if (user.id == null) return;

    // Bảo vệ user "thien" - không thể bị xóa
    if (user.username.toLowerCase() == 'thien') {
      _showErrorSnackBar('Không thể xóa user "thien"');
      return;
    }

    // Chỉ user "thien" mới được xóa user khác
    final currentUser = await _repo.getCurrentUser();
    if (currentUser?.username.toLowerCase() != 'thien') {
      _showErrorSnackBar('Chỉ có user "thien" mới được xóa user');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa user "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _repo.deleteUser(user.id!);
        if (success) {
          _showSuccessSnackBar('Đã xóa user "${user.username}"');
          _loadUsers();
        } else {
          _showErrorSnackBar('Không thể xóa user');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi khi xóa user: $e');
      }
    }
  }

  Future<void> _toggleAdminStatus(AppUser user) async {
    if (user.id == null) return;

    // Bảo vệ user "thien" - không thể thay đổi quyền admin
    if (user.username.toLowerCase() == 'thien') {
      _showErrorSnackBar('Không thể thay đổi quyền của user "thien"');
      return;
    }

    try {
      final success = await _repo.updateUserAdminStatus(user.id!, !user.isAdmin);
      if (success) {
        final status = !user.isAdmin ? 'admin' : 'user thường';
        _showSuccessSnackBar('Đã cập nhật "${user.username}" thành $status');
        _loadUsers();
      } else {
        _showErrorSnackBar('Không thể cập nhật quyền user');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi cập nhật quyền: $e');
    }
  }

  Future<void> _showBanDialog(AppUser user) async {
    if (user.id == null) return;

    // Bảo vệ user "thien" - không thể bị cấm
    if (user.username.toLowerCase() == 'thien') {
      _showErrorSnackBar('Không thể cấm user "thien"');
      return;
    }

    final banDuration = await showDialog<Duration?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cấm user "${user.username}"',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn thời gian cấm:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange[200]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: const Text(
                  '1 phút',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(const Duration(minutes: 1)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: const Text(
                  '5 phút',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(const Duration(minutes: 5)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red[200]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: const Text(
                  'Vĩnh viễn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(const Duration(days: 365 * 100)), // 100 years
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );

    if (banDuration != null) {
      try {
        final success = await _repo.banUser(user.id!, banDuration);
        if (success) {
          _showSuccessSnackBar('Đã cấm user "${user.username}" trong ${_formatDuration(banDuration)}');
          _loadUsers(); // Reload để cập nhật UI
        } else {
          _showErrorSnackBar('Không thể cấm user');
        }
      } catch (e) {
        _showErrorSnackBar('Lỗi khi cấm user: $e');
      }
    }
  }

  Future<void> _unbanUser(AppUser user) async {
    if (user.id == null) return;

    // Bảo vệ user "thien" - không thể bị cấm
    if (user.username.toLowerCase() == 'thien') {
      _showErrorSnackBar('User "thien" không thể bị cấm');
      return;
    }

    try {
      final success = await _repo.unbanUser(user.id!);
      if (success) {
        _showSuccessSnackBar('Đã hủy cấm user "${user.username}"');
        _loadUsers(); // Reload để cập nhật UI
      } else {
        _showErrorSnackBar('Không thể hủy cấm user');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi hủy cấm user: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 365) return 'vĩnh viễn';
    if (duration.inDays > 0) return '${duration.inDays} ngày';
    if (duration.inHours > 0) return '${duration.inHours} giờ';
    if (duration.inMinutes > 0) return '${duration.inMinutes} phút';
    return '${duration.inSeconds} giây';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay with gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x80667eea),
                    Color(0x80764ba2),
                    Color(0x80f093fb),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quản lý User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Statistics
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Tổng User', _totalUsers.toString(), Colors.blue),
                      _buildStatCard('Admin', _adminCount.toString(), Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Users List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                          ? const Center(
                              child: Text(
                                'Không có user nào',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return _buildUserCard(user);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isAdmin ? Colors.red : Colors.blue,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (user.bannedUntil != null && DateTime.now().isBefore(user.bannedUntil!)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'BANNED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black,
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'toggle_admin':
                      _toggleAdminStatus(user);
                      break;
                    case 'ban':
                      _showBanDialog(user);
                      break;
                    case 'unban':
                      _unbanUser(user);
                      break;
                    case 'delete':
                      _deleteUser(user);
                      break;
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 8,
                itemBuilder: (context) {
                  // User "thien" không thể bị thay đổi
                  if (user.username.toLowerCase() == 'thien') {
                    return [
                      PopupMenuItem(
                        enabled: false,
                        height: 48,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Không thể thay đổi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  }
                  
                  // Các user khác có thể được quản lý
                  List<PopupMenuItem<String>> items = [
                    PopupMenuItem(
                      value: 'toggle_admin',
                      height: 48,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: user.isAdmin ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: user.isAdmin ? Colors.orange[200]! : Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.isAdmin ? 'Bỏ quyền admin' : 'Cấp quyền admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: user.isAdmin ? Colors.orange[700] : Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'ban',
                      height: 48,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Cấm user',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 48,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Xóa user',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];

                  // Thêm tùy chọn "Hủy cấm" nếu user đang bị cấm
                  if (user.bannedUntil != null && DateTime.now().isBefore(user.bannedUntil!)) {
                    items.insert(2, PopupMenuItem(
                      value: 'unban',
                      height: 48,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green[200]!,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Hủy cấm',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ));
                  }

                  return items;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}