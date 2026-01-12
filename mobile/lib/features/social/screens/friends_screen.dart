import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/friend_request_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../shared/widgets/gradient_snackbar.dart';
import 'chat_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addFriendController = TextEditingController();

  final _friendRepo = FriendRequestRepository();
  final _authRepo = AuthRepository();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _filteredFriends = [];

  String _currentUsername = '';
  int _currentUserId = 0;
  bool _isLoading = true;
  bool _hasNewFriendRequest = false;
  String _searchQuery = '';
  String _searchResult = '';
  Map<String, dynamic>? _foundUser;
  bool _isSearching = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('username') ?? '';
      _currentUserId = prefs.getInt('session_user_id') ?? 0;

      // Load friends, received requests, sent requests
      final friends = await _friendRepo.getFriends(_currentUserId);
      final receivedRequests =
          await _friendRepo.getReceivedFriendRequests(_currentUserId);
      final sentRequests =
          await _friendRepo.getSentFriendRequests(_currentUserId);

      setState(() {
        _friends = friends;
        _receivedRequests = receivedRequests;
        _sentRequests = sentRequests;
        _filteredFriends = friends;
        _hasNewFriendRequest = receivedRequests.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi khi tải dữ liệu: ${e.toString()}');
    }
  }

  Future<void> _searchUser() async {
    final query = _addFriendController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResult = '';
      _foundUser = null;
    });

    try {
      final user = await _friendRepo.findUserByUsernameOrEmail(query);

      if (user != null) {
        // Kiểm tra xem có phải chính mình không
        if (user['id'] == _currentUserId) {
          setState(() {
            _searchResult = 'Không thể kết bạn với chính mình';
            _foundUser = null;
            _isSearching = false;
          });
          return;
        }

        // LOGIC ĐƠN GIẢN: Chỉ kiểm tra xem đã là bạn bè chưa
        final areFriends =
            await _friendRepo.areFriends(_currentUserId, user['id']);

        if (areFriends) {
          // Nếu đã là bạn bè → không thể gửi lời mời
          setState(() {
            _searchResult = 'Đã là bạn bè';
            _foundUser = null;
            _isSearching = false;
          });
          return;
        }

        // Kiểm tra có lời mời pending không
        final requestStatus = await _friendRepo.getFriendRequestStatus(
            _currentUserId, user['id']);

        if (requestStatus == 'pending') {
          // Kiểm tra xem ai là người gửi
          final sentRequests =
              await _friendRepo.getSentFriendRequests(_currentUserId);
          final isSentByMe =
              sentRequests.any((req) => req['receiver_id'] == user['id']);

          if (isSentByMe) {
            setState(() {
              _searchResult = 'Đã gửi lời mời kết bạn';
              _foundUser = null;
              _isSearching = false;
            });
            return;
          } else {
            setState(() {
              _searchResult = 'Đã nhận lời mời kết bạn từ user này';
              _foundUser = null;
              _isSearching = false;
            });
            return;
          }
        }

        // Tất cả trường hợp khác (rejected, null, etc.) → cho phép gửi lời mời
        setState(() {
          _foundUser = user;
          _searchResult = '';
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResult = 'User không tồn tại';
          _foundUser = null;
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResult = 'Lỗi khi tìm kiếm: ${e.toString()}';
        _foundUser = null;
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_foundUser == null) return;

    try {
      final success = await _friendRepo.sendFriendRequest(
        _currentUserId,
        _foundUser!['id'],
      );

      if (success) {
        _showSuccessSnackBar('Đã gửi lời mời kết bạn');
        _addFriendController.clear();
        setState(() {
          _foundUser = null;
          _searchResult = '';
        });
        await _loadData(); // Reload để cập nhật sent requests
      } else {
        _showErrorSnackBar('Đã gửi lời mời kết bạn trước đó');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi gửi lời mời: ${e.toString()}');
    }
  }

  Future<void> _acceptFriendRequest(int requestId) async {
    try {
      final success = await _friendRepo.acceptFriendRequest(requestId);
      if (success) {
        _showSuccessSnackBar('Đã chấp nhận lời mời kết bạn');
        await _loadData(); // Reload để cập nhật danh sách
        setState(() {
          _hasNewFriendRequest = false; // Xóa highlight
        });
      } else {
        _showErrorSnackBar('Lỗi khi chấp nhận lời mời');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chấp nhận lời mời: ${e.toString()}');
    }
  }

  Future<void> _rejectFriendRequest(int requestId) async {
    try {
      final success = await _friendRepo.rejectFriendRequest(requestId);
      if (success) {
        _showSuccessSnackBar('Đã từ chối lời mời kết bạn');
        await _loadData(); // Reload để cập nhật danh sách
        setState(() {
          _hasNewFriendRequest = false; // Xóa highlight
        });
      } else {
        _showErrorSnackBar('Lỗi khi từ chối lời mời');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi từ chối lời mời: ${e.toString()}');
    }
  }

  // Hiển thị dialog xác nhận xóa bạn bè - GIAO DIỆN ĐẸP
  void _showRemoveFriendDialog(int friendId, String friendName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF57BCCE).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header với icon
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Icon xóa bạn bè
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_remove_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Xóa bạn bè',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message chính
                      Text(
                        'Bạn có chắc chắn muốn xóa bạn bè "$friendName" không?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cảnh báo - MÀU ĐỎ NỔI BẬT
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.withOpacity(0.2),
                              Colors.red.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Hành động này không thể hoàn tác.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Nút Hủy
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Nút Xóa
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _removeFriend(friendId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mở chat với bạn bè
  void _openChat(int friendId, String friendUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          otherUserId: friendId,
          otherUsername: friendUsername,
          currentUserId: _currentUserId,
        ),
      ),
    );
  }

  Future<void> _removeFriend(int friendId) async {
    try {
      final success = await _friendRepo.removeFriend(_currentUserId, friendId);
      if (success) {
        _showSuccessSnackBar('Đã hủy kết bạn');
        await _loadData(); // Reload để cập nhật danh sách
      } else {
        _showErrorSnackBar('Lỗi khi hủy kết bạn');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi hủy kết bạn: ${e.toString()}');
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          final username = friend['username']?.toString().toLowerCase() ?? '';
          final email = friend['email']?.toString().toLowerCase() ?? '';
          return username.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade50,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade200),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade50,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getButtonText() {
    if (_foundUser == null) return 'Gửi lời mời kết bạn';

    // Kiểm tra trạng thái để hiển thị text phù hợp
    return 'Gửi lời mời kết bạn';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _addFriendController.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                            'Bạn bè',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF57BCCE)),
                              ),
                            )
                          : DefaultTabController(
                              length: 3,
                              child: Column(
                                children: [
                                  // Tab bar
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: TabBar(
                                      labelColor: const Color(0xFF57BCCE),
                                      unselectedLabelColor: Colors.grey,
                                      indicatorColor: const Color(0xFF57BCCE),
                                      tabs: [
                                        const Tab(text: 'Bạn bè'),
                                        Tab(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Lời mời'),
                                              if (_hasNewFriendRequest) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const Tab(text: 'Tìm bạn'),
                                      ],
                                    ),
                                  ),
                                  // Tab content
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _buildFriendsTab(),
                                        _buildRequestsTab(),
                                        _buildSearchTab(),
                                      ],
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
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _filterFriends,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bạn bè...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF57BCCE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF57BCCE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: const Color(0xFF57BCCE).withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF57BCCE), width: 2),
              ),
            ),
          ),
        ),
        // Friends list
        Expanded(
          child: _filteredFriends.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có bạn bè nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _filteredFriends[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            color: const Color(0xFF57BCCE).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Text(
                            friend['username'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF57BCCE),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          friend['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          friend['email'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút nhắn tin
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () => _openChat(
                                    friend['friend_id'], friend['username']),
                                icon: const Icon(Icons.chat_bubble_outline,
                                    color: Colors.white),
                                tooltip: 'Nhắn tin',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút xóa bạn bè
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () => _showRemoveFriendDialog(
                                    friend['friend_id'], friend['username']),
                                icon: const Icon(Icons.person_remove,
                                    color: Colors.white),
                                tooltip: 'Xóa bạn bè',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      children: [
        // Received requests
        if (_receivedRequests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Lời mời kết bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF57BCCE),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _receivedRequests.length,
              itemBuilder: (context, index) {
                final request = _receivedRequests[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        request['username'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      request['username'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(request['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _acceptFriendRequest(request['id']),
                          icon: const Icon(Icons.check, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () => _rejectFriendRequest(request['id']),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text(
                'Không có lời mời kết bạn nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _addFriendController,
            decoration: InputDecoration(
              hintText: 'Nhập username hoặc email',
              prefixIcon:
                  const Icon(Icons.person_search, color: Color(0xFF57BCCE)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF57BCCE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: const Color(0xFF57BCCE).withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF57BCCE), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _searchUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF57BCCE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Tìm kiếm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // Search result
          if (_searchResult.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _searchResult,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Found user
          if (_foundUser != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF57BCCE),
                        child: Text(
                          _foundUser!['username'][0].toUpperCase(),
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
                            Text(
                              _foundUser!['username'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _foundUser!['email'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendFriendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _getButtonText(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Thêm khoảng trống để tránh bị che bởi keyboard
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
