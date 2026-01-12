import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../social/widgets/notification_badge_widget.dart';
import '../../social/widgets/message_badge_widget.dart';
import '../../../shared/widgets/clock_widget.dart';
import '../../../shared/widgets/game_bg.dart';
import '../../../shared/widgets/gradient_snackbar.dart';
import '../../profile/utils/user_activity_helper.dart';
import '../../games/sudoku/screens/sudoku_screen.dart';
import '../../games/rubik/screens/rubik_main.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../profile/screens/user_activity_screen.dart';
import '../../social/screens/friends_screen.dart';
import '../../admin/screens/admin_page.dart';
import '../../announcement/screens/announcement_screen.dart';
import '../../social/screens/chat_list_screen.dart';
import '../../announcement/screens/notifications_screen.dart';
import '../../profile/screens/user_profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? _username;
  String? _currentUsername;
  bool _isInitialLoad = true;
  bool _isAdmin = false;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    _gradientController.repeat(reverse: true);
    _loadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoad) {
      _refreshAllData();
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  // Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều';
    } else {
      return 'Chào buổi tối';
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthRepository().getCurrentUser();
      if (user != null) {
        setState(() {
          _username = user.username;
          _currentUsername = user.username;
        });

        // Check if user is admin
        final isAdmin = await AuthRepository().isCurrentUserAdmin();
        setState(() {
          _isAdmin = isAdmin;
        });

        // Save login history
        await UserActivityHelper.saveLoginHistory(
            username: _username ?? 'Player');

        // Show welcome message only on initial load
        if (mounted) {
          GradientSnackBar.show(
            context,
            message: 'Chào mừng ${_username ?? 'Player'}!',
            icon: Icons.waving_hand,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _loadUserSilently() async {
    try {
      final user = await AuthRepository().getCurrentUser();
      if (user != null) {
        setState(() {
          _username = user.username;
          _currentUsername = user.username;
        });

        // Check if user is admin
        final isAdmin = await AuthRepository().isCurrentUserAdmin();
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      debugPrint('Error loading user silently: $e');
    }
  }

  Future<void> _refreshAllData() async {
    await _loadUserSilently();
  }

  Future<void> _onRefresh() async {
    await _refreshAllData();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<String> _getCurrentUsername() async {
    try {
      final repo = AuthRepository();
      final user = await repo.getCurrentUser();
      final username = user?.username ?? 'Unknown User';

      debugPrint(
          'GAME_HISTORY: Current user: ${user?.id}, username: $username');

      return username;
    } catch (e) {
      debugPrint('Error getting current username: $e');
      return 'Unknown User';
    }
  }

  Future<void> _saveGameHistory(String gameName) async {
    try {
      final username = await _getCurrentUsername();

      debugPrint(
          'GAME_HISTORY: Attempting to save $gameName game history for $username');

      await UserActivityHelper.saveGameHistory(
        username: username,
        gameName: gameName,
      );

      debugPrint(
          'GAME_HISTORY: Successfully saved $gameName game history for $username');
    } catch (e) {
      debugPrint('GAME_HISTORY: Error saving game history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isInitialLoad = false;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF57BCCE),
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      edgeOffset: 0,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _isAdmin ? _buildAdminDrawer() : _buildUserDrawer(),
        body: Stack(
          children: [
            // Background with gradient colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.indigo.shade100,
                  ],
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Welcome Section
                          _buildWelcomeSection(),

                          const SizedBox(height: 16),

                          // Mini Games
                          _buildMiniGames(),
                        ],
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Logo - Clickable to open drawer
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const AppLogo(size: 45),
          ),

          // Right side - Leaderboard for admin, Notifications for regular users
          _isAdmin
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 24),
                  ),
                )
              : NotificationBadgeWidget(
                  userId: 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // Greeting
          Text(
            '${_getGreeting()}, ${_currentUsername ?? 'tu'}!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),

          // Admin Role Badge (only show if user is admin)
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Question
          Text(
            _isAdmin
                ? 'Chào mừng Admin đã quay trở lại!'
                : 'Sẵn sàng để chiến các mini-game chưa?',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionCard(
                  title: 'Bạn bè',
                  icon: Icons.people,
                  backgroundColor: const Color(0xFF57BCCE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  title: 'Tin nhắn',
                  icon: Icons.message,
                  backgroundColor: const Color(0xFF4A90E2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  title: 'Bảng xếp hạng',
                  icon: Icons.leaderboard,
                  backgroundColor: const Color(0xFF9B59B6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF57BCCE),
              Color(0xFFA8D3CA),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF57BCCE).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniGames() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mini games',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            title: 'Sudoku',
            subtitle: 'Rèn luyện trí tuệ mỗi ngày!',
            icon: _buildSudokuIcon(),
            backgroundColor: const Color(0xFF57BCCE),
            onTap: () {
              _showSudokuDialog(context);
            },
            onPlayTap: () async {
              await _saveGameHistory('sudoku');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SudokuScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildGameCard(
            title: '2048',
            subtitle: 'Trượt số, nhân đôi niềm vui!',
            icon: _build2048Icon(),
            backgroundColor: const Color(0xFFE67E22),
            onTap: () {
              _show2048Dialog(context);
            },
            onPlayTap: () async {
              await _saveGameHistory('2048');
              Navigator.pushNamed(context, '/2048');
            },
          ),
          const SizedBox(height: 12),
          _buildGameCard(
            title: 'Caro',
            subtitle: 'Đấu trí từng nước cờ!',
            icon: _buildCaroIcon(),
            backgroundColor: const Color(0xFF2C3E50),
            onTap: () {
              _showCaroDialog(context);
            },
            onPlayTap: () async {
              await _saveGameHistory('caro');
              Navigator.pushNamed(context, '/caro');
            },
          ),
          const SizedBox(height: 12),
          _buildGameCard(
            title: 'Rubik',
            subtitle: 'Giải đố 3D thử thách!',
            icon: _buildRubikIcon(),
            backgroundColor: const Color(0xFF8E44AD),
            onTap: () {
              _showRubikDialog(context);
            },
            onPlayTap: () async {
              await _saveGameHistory('rubik');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RubikMain()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback onTap,
    required VoidCallback onPlayTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.7),
              backgroundColor.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Game Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 16),
            // Game Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Play Button
            GestureDetector(
              onTap: onPlayTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSudokuIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          'assets/images/sudoku_icon.jpg',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _build2048Icon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          'assets/images/g2048_icon.jpg',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCaroIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          'assets/images/caro_icon.jpg',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRubikIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFF8E44AD),
      ),
      child: const Icon(
        Icons.view_in_ar,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _showGameDescriptionDialog(
    BuildContext context,
    String gameName,
    String description,
    String instructions,
    VoidCallback onPlay,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Icon(
                Icons.games,
                color: const Color(0xFF57BCCE),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  gameName,
                  style: const TextStyle(
                    fontSize: 20,
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
                  'Mô tả:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hướng dẫn:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  instructions,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onPlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF57BCCE),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Chơi ngay'),
            ),
          ],
        );
      },
    );
  }

  void _showSudokuDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF57BCCE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/sudoku_icon.jpg',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sudoku',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Trò chơi logic phổ biến với lưới 9x9. Điền số từ 1-9 vào các ô trống.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cách chơi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Chọn ô trống và nhập số 1-9\n• Không trùng số trong hàng, cột, vùng 3x3\n• Hoàn thành lưới để thắng',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _show2048Dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE67E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/g2048_icon.jpg',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '2048',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Trò chơi puzzle với lưới 4x4. Kết hợp các ô có cùng số để tạo ra số lớn hơn.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cách chơi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Vuốt để di chuyển các ô\n• Các ô cùng số sẽ kết hợp\n• Mục tiêu: tạo ra ô 2048',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showCaroDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3E50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/caro_icon.jpg',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Game Caro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Trò chơi đấu trí với lưới 3x3. Tạo thành hàng 3 ký hiệu giống nhau để thắng.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cách chơi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Luân phiên đặt X hoặc O\n• Tạo hàng 3 ô liên tiếp\n• Thắng theo hàng, cột hoặc chéo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showRubikDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF8E44AD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Rubik Cube',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Trò chơi giải đố 3D kinh điển. Xoay các mặt để đưa cube về trạng thái đã giải.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cách chơi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Drag để xoay cube 3D\n• Tap mặt để xoay mặt cụ thể\n• Nhập cách giải bằng ký hiệu F, R, U, D, L, B\n• Sử dụng \' cho ngược chiều',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  // User Drawer
  Widget _buildUserDrawer() {
    return Drawer(
      child: Container(
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // User Profile Section
                _buildUserProfileSection(),

                const SizedBox(height: 20),

                // Games Section
                _buildGamesSection(),

                const SizedBox(height: 20),

                // Utilities Section
                _buildUtilitiesSection(),

                const SizedBox(height: 20),

                // Other Section
                _buildOtherSection(),

                const SizedBox(height: 20),

                // Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Admin Drawer
  Widget _buildAdminDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE74C3C),
              Color(0xFF9B59B6),
              Color(0xFF3498DB),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Admin Profile Section
                _buildAdminProfileSection(),

                const SizedBox(height: 20),

                // Admin Games Section
                _buildAdminGamesSection(),

                const SizedBox(height: 20),

                // Admin Utilities Section
                _buildAdminUtilitiesSection(),

                const SizedBox(height: 20),

                // Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUsername ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'User',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // Admin Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUsername ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mini Games',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Game Icons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGameIconButton(
                icon: _buildSudokuIcon(),
                backgroundColor: const Color(0xFF57BCCE).withOpacity(0.8),
                onTap: () async {
                  await _saveGameHistory('sudoku');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SudokuScreen()),
                  );
                },
              ),
              _buildGameIconButton(
                icon: _build2048Icon(),
                backgroundColor: const Color(0xFF4A90E2).withOpacity(0.8),
                onTap: () async {
                  await _saveGameHistory('2048');
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/2048');
                },
              ),
              _buildGameIconButton(
                icon: _buildCaroIcon(),
                backgroundColor: const Color(0xFFE74C3C).withOpacity(0.8),
                onTap: () async {
                  await _saveGameHistory('caro');
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/caro');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameIconButton({
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _buildAdminGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Game Cards
        _buildDrawerGameCard(
          title: 'Sudoku',
          icon: Icons.grid_on,
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () async {
            await _saveGameHistory('sudoku');
            Navigator.pop(context); // Đóng drawer sau khi lưu lịch sử
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SudokuScreen()),
            );
          },
        ),

        _buildDrawerGameCard(
          title: '2048',
          icon: Icons.apps,
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () async {
            await _saveGameHistory('2048');
            Navigator.pop(context);
            Navigator.pushNamed(context, '/2048');
          },
        ),

        _buildDrawerGameCard(
          title: 'Caro',
          icon: Icons.close,
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () async {
            await _saveGameHistory('caro');
            Navigator.pop(context);
            Navigator.pushNamed(context, '/caro');
          },
        ),

        _buildDrawerGameCard(
          title: 'Rubik',
          icon: Icons.view_in_ar,
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: Colors.black,
          textColor: Colors.black,
          onTap: () async {
            await _saveGameHistory('rubik');
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RubikMain()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cộng đồng',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decorationColor: Colors.yellow,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Utility Cards
        _buildUtilityCard(
          title: 'Bạn bè',
          icon: Icons.people,
          backgroundColor: const Color(0xFFF5A623).withOpacity(0.8),
          onTap: () async {
            // Lưu thời gian truy cập nếu cần
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Tin nhắn',
          icon: Icons.message,
          backgroundColor: const Color(0xFF3498DB).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Thông báo',
          icon: Icons.notifications,
          backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Bảng xếp hạng',
          icon: Icons.bar_chart,
          backgroundColor: const Color(0xFF9B59B6).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'User Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decorationColor: Colors.yellow,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Admin Utility Cards
        _buildUtilityCard(
          title: 'Quản lý user',
          icon: Icons.admin_panel_settings,
          backgroundColor: const Color(0xFFE74C3C).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPage()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Thông báo hệ thống',
          icon: Icons.announcement,
          backgroundColor: const Color(0xFF9B59B6).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Hoạt động user',
          icon: Icons.analytics,
          backgroundColor: const Color(0xFF27AE60).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserActivityScreen()),
            );
          },
        ),

        _buildUtilityCard(
          title: 'Bảng xếp hạng',
          icon: Icons.leaderboard,
          backgroundColor: const Color(0xFF9B59B6).withOpacity(0.8),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawerGameCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Khác',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decorationColor: Colors.yellow,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Other Cards
        _buildUtilityCard(
          title: 'Thông tin cá nhân',
          icon: Icons.person,
          backgroundColor: const Color(0xFF9B59B6).withOpacity(0.8),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              // Close drawer first
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Perform logout
              await AuthRepository().logout();

              // Close loading dialog
              if (mounted) {
                Navigator.pop(context);

                // Navigate to login
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            } catch (e) {
              debugPrint('Error during logout: $e');

              // Close loading dialog if it exists
              if (mounted) {
                Navigator.pop(context);

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi đăng xuất: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
