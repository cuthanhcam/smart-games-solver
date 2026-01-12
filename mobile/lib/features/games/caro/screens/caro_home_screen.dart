import 'package:flutter/material.dart';
import '../utils/game_state.dart';
import 'caro_screen.dart';
import '../../../leaderboard/screens/leaderboard_screen.dart';
import '../../../auth/repositories/auth_repository.dart';
import '../../../profile/utils/user_activity_helper.dart';

class CaroHomeScreen extends StatefulWidget {
  const CaroHomeScreen({Key? key}) : super(key: key);

  @override
  State<CaroHomeScreen> createState() => _CaroHomeScreenState();
}

class _CaroHomeScreenState extends State<CaroHomeScreen>
    with TickerProviderStateMixin {
  GameMode selectedMode = GameMode.pvE;
  Difficulty selectedDifficulty = Difficulty.easy;
  bool _isStarting = false;

  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;
  late Animation<double> _titleOpacityAnimation;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize title animation
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _titleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.elasticOut,
    ));

    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize content animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _titleAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });

    // Precache caro icons to speed up first render in game screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/caro/icon_x.jpg'), context);
      precacheImage(const AssetImage('assets/caro/icon_o.jpg'), context);
    });

    // Ghi lại hoạt động khi vào Caro Home Screen
    _saveCaroEntry();
  }

  // Lưu lịch sử khi vào Caro Home Screen
  void _saveCaroEntry() async {
    try {
      final repo = AuthRepository();
      // Removed to avoid duplicate entries - game history is now saved from home_page.dart
      debugPrint(
          'Caro home screen entry - history already saved from home page');
    } catch (e) {
      debugPrint('Error saving caro home screen entry: $e');
    }
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC), // App Theme Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3748), // Dark Text
        title: AnimatedBuilder(
          animation: _titleAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _titleScaleAnimation.value,
              child: Opacity(
                opacity: _titleOpacityAnimation.value,
                child: Text(
                  'Caro Game',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: const Color(0xFF2D3748),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          // Leaderboard button - styled like 2048
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.leaderboard,
                    color: Color(0xFF4299E1), size: 24), // Professional Blue
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF7FAFC),
            child: SafeArea(
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1E293B),
                                        Color(0xFF334155),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade400,
                                              Colors.blue.shade600
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.grid_on,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Caro Game',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Game mode selection
                                _buildSection(
                                  title: 'Chế độ chơi',
                                  child: Column(
                                    children: [
                                      _buildModeOption(
                                        GameMode.pvE,
                                        'Người vs Máy',
                                        Icons.person,
                                        'Chơi với máy',
                                      ),

                                      // Difficulty dropdown (only for PvE mode)
                                      if (selectedMode == GameMode.pvE) ...[
                                        const SizedBox(height: 12),
                                        _buildDifficultyDropdown(),
                                      ],

                                      const SizedBox(height: 20),
                                      _buildModeOption(
                                        GameMode.evE,
                                        'Máy vs Máy',
                                        Icons.smart_toy,
                                        'Xem máy đấu với nhau',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Start button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isStarting ? null : _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 28, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Bắt đầu chơi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isStarting)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.8)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade600),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Đang tải...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModeOption(
      GameMode mode, String title, IconData icon, String subtitle) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade400
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDropdown() {
    final difficulties = [
      {
        'difficulty': Difficulty.easy,
        'title': 'Easy',
        'subtitle': 'AI ngẫu nhiên',
        'color': Colors.green
      },
      {
        'difficulty': Difficulty.normal,
        'title': 'Normal',
        'subtitle': 'AI cơ bản',
        'color': Colors.orange
      },
      {
        'difficulty': Difficulty.hard,
        'title': 'Hard',
        'subtitle': 'AI nâng cao',
        'color': Colors.red
      },
      {
        'difficulty': Difficulty.expert,
        'title': 'Expert',
        'subtitle': 'AI tối ưu',
        'color': Colors.purple
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Difficulty>(
          value: selectedDifficulty,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white70,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          dropdownColor: const Color(0xFF1E293B),
          items: difficulties.map((diff) {
            return DropdownMenuItem<Difficulty>(
              value: diff['difficulty'] as Difficulty,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: diff['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        diff['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        diff['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Difficulty? newValue) {
            if (newValue != null) {
              setState(() => selectedDifficulty = newValue);
            }
          },
        ),
      ),
    );
  }

  void _startGame() {
    setState(() => _isStarting = true);
    Future.delayed(const Duration(milliseconds: 100), () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameMode: selectedMode,
            difficulty: selectedDifficulty,
          ),
        ),
      );
      if (mounted) setState(() => _isStarting = false);
    });
  }
}
