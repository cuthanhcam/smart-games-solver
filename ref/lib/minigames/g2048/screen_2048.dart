import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'board_2048.dart';
import '../../screens/leaderboard_screen.dart';
import '../../utils/leaderboard_helper.dart';
import '../../utils/user_activity_helper.dart';
import '../../repositories/auth_repository.dart';

enum ToolMode { none, swapPickFirst, swapPickSecond, deletePick }

class Game2048Screen extends StatefulWidget {
  final int size;             // mặc định 4x4
  const Game2048Screen({super.key, this.size = 4});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> with TickerProviderStateMixin {
  late Board2048 board;
  Board2048? _undo; // 1 bước undo
  bool _saving = false;
  bool _gameEndShown = false; // tránh hiển thị nhiều lần

  // Tool charges (0..2)
  int undoCharges = 2;
  int swapCharges = 1;
  int deleteCharges = 1;

  // Highest tile seen to award charges once per threshold
  int _highestTileSeen = 0;

  // Tool mode
  ToolMode _mode = ToolMode.none;

  // Remember first pick for swap
  Point<int>? _swapA;

  // Animation controllers for title
  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;
  late Animation<double> _titleOpacityAnimation;

  // State for tile selection
  Point<int>? _selectedTile;

  @override
  void initState() {
    super.initState();
    board = Board2048(size: widget.size, rnd: Random());

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
      curve: Curves.easeIn,
    ));

    _titleAnimationController.forward();
    _saveGameEntry();
  }

  // Lưu lịch sử khi vào game
  void _saveGameEntry() async {
    try {
      // Removed to avoid duplicate entries - game history is now saved from home_page.dart
      debugPrint('2048 game entry - history already saved from home page');
    } catch (e) {
      debugPrint('Error saving game entry: $e');
    }
  }

  Future<void> _saveBestIfNeeded() async {
    try {
      // Lấy username từ AuthRepository thay vì dựa vào widget.username
      final repo = AuthRepository();
      final user = await repo.getCurrentUser();
      final username = user?.username ?? 'Player';
      
      debugPrint('DEBUG 2048: Saving score ${board.score} for user: $username');
      
      // Sử dụng LeaderboardHelper để lưu điểm
      await LeaderboardHelper.save2048Result(
        username: username,
        score: board.score,
      );
      
      debugPrint('DEBUG 2048: Successfully saved score ${board.score} for user: $username');
    } catch (e) {
      debugPrint('DEBUG 2048: Error saving score: $e');
    }
  }

  Future<void> _showGameEndDialog({required bool won}) async {
    if (_gameEndShown) return;
    _gameEndShown = true;
    final titleText = won ? 'You Win!' : 'Game Over';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFFFAF8F0),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B7355), width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF776E65),
                    shadows: [
                      Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,2)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFCDC1B4), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Score', style: TextStyle(color: Color(0xFF776E65), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      Text(
                        '${board.score}',
                        style: const TextStyle(color: Color(0xFF776E65), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFCDC1B4), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Best', style: TextStyle(color: Color(0xFF776E65), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      Text(
                        '${board.bestScore}',
                        style: const TextStyle(color: Color(0xFF776E65), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Nút New Game và Home
                Row(
                  children: [
                    // Nút New Game
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startNewGame();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('New Game', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8B0A3),
                          foregroundColor: const Color(0xFF776E65),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF8B7355), width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút Home (quay lại màn hình chính)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Đóng dialog
                          Navigator.of(context).pop(); // Quay lại màn hình chính
                        },
                        icon: const Icon(Icons.home, size: 18),
                        label: const Text('Home', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B7355), // Màu đậm hơn để phân biệt
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF776E65), width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMove(Dir d) async {
    // Block moves while using tools
    if (_mode != ToolMode.none) return;
    if (board.isGameOver) return;
    setState(() => _undo = Board2048.fromMap(board.toMap()));
    final moved = board.move(d);
    if (moved) {
      setState(() {});
      _maybeAwardCharges(_currentMaxTile());
      if (board.isGameOver || board.won) {
        if (_saving) return;
        _saving = true;
        await _saveBestIfNeeded();
        _saving = false;
        if (!mounted) return;
        await _showGameEndDialog(won: board.won);
      }
    }
  }

  void _newGame() {
    setState(() {
      board.reset();
      _undo = null;
    });
  }

  void _undoOnce() {
    if (_mode != ToolMode.none) return; // don't allow during tool modes
    if (undoCharges <= 0) return;
    if (_undo == null) return;
    setState(() {
      board = Board2048.fromMap(_undo!.toMap());
      _undo = null;
      undoCharges = (undoCharges - 1).clamp(0, 2);
    });
  }

  int _currentMaxTile() {
    int m = 0;
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        final v = board.grid[r][c];
        if (v > m) m = v;
      }
    }
    return m;
  }

  void _maybeAwardCharges(int newMax) {
    if (_highestTileSeen >= newMax) return;
    if (_highestTileSeen < 64 && newMax >= 64) {
      undoCharges = (undoCharges + 1).clamp(0, 2);
    }
    if (_highestTileSeen < 128 && newMax >= 128) {
      swapCharges = (swapCharges + 1).clamp(0, 2);
    }
    if (_highestTileSeen < 512 && newMax >= 512) {
      deleteCharges = (deleteCharges + 1).clamp(0, 2);
    }
    _highestTileSeen = newMax;
  }

  void _toggleSwapMode() {
    if (_mode == ToolMode.swapPickFirst || _mode == ToolMode.swapPickSecond) {
      setState(() {
        _mode = ToolMode.none;
        _swapA = null;
      });
      return;
    }
    if (swapCharges <= 0) return;
    setState(() {
      _mode = ToolMode.swapPickFirst;
      _swapA = null;
    });
  }

  void _toggleDeleteMode() {
    if (_mode == ToolMode.deletePick) {
      setState(() => _mode = ToolMode.none);
      return;
    }
    if (deleteCharges <= 0) return;
    setState(() => _mode = ToolMode.deletePick);
  }

  void _onTileTapForTools(int r, int c) {
    switch (_mode) {
      case ToolMode.swapPickFirst:
        if (board.grid[r][c] == 0) return;
        setState(() {
          _swapA = Point(r, c);
          _mode = ToolMode.swapPickSecond;
        });
        break;
      case ToolMode.swapPickSecond:
        if (_swapA == null) {
          setState(() => _mode = ToolMode.swapPickFirst);
          return;
        }
        if (board.grid[r][c] == 0) return;
        final a = _swapA!;
        setState(() {
          final tmp = board.grid[a.x][a.y];
          board.grid[a.x][a.y] = board.grid[r][c];
          board.grid[r][c] = tmp;
          swapCharges = (swapCharges - 1).clamp(0, 2);
          _mode = ToolMode.none;
          _swapA = null;
        });
        break;
      case ToolMode.deletePick:
        if (board.grid[r][c] == 0) return;
        setState(() {
          board.grid[r][c] = 0;
          deleteCharges = (deleteCharges - 1).clamp(0, 2);
          _mode = ToolMode.none;
        });
        break;
      case ToolMode.none:
        break;
    }
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Control button methods
  void _handleUndo() {
    if (board.undo()) {
      setState(() {});
    }
  }

  void _handleSwap() {
    if (board.swapUses <= 0) {
      return;
    }

    // For now, swap two random tiles
    final positions = board.getNonEmptyPositions();
    if (positions.length < 2) {
      return;
    }

    final pos1 = positions[Random().nextInt(positions.length)];
    final pos2 = positions[Random().nextInt(positions.length)];

    if (board.swapTiles(pos1, pos2)) {
      setState(() {});
    }
  }

  void _handleDelete() {
    if (!_canDelete()) {
      return;
    }

    // For now, delete a random tile
    final positions = board.getNonEmptyPositions();
    if (positions.isEmpty) {
      return;
    }

    final pos = positions[Random().nextInt(positions.length)];
    if (board.deleteTile(pos)) {
      setState(() {});
    }
  }

  bool _canDelete() {
    // Check if there's at least one 256 tile
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        if (board.grid[r][c] == 256) {
          return true;
        }
      }
    }
    return false;
  }

  void _startNewGame() async {
    setState(() {
      board.reset();
      _selectedTile = null;
      // Reset tool charges to initial values
      undoCharges = 2;
      swapCharges = 1;
      deleteCharges = 1;
      _highestTileSeen = 0;
      _mode = ToolMode.none;
      _swapA = null;
      _gameEndShown = false;
    });
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? const Color(0xFF57BCCE) : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // New styled square tool button with badge and bars
  Widget _toolButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool active,
    required bool enabled,
    required int charges,
  }) {
    const Color baseBg = Color(0xFFEFE9DD);
    const Color activeBg = Color(0xFFCFC4B5);
    const Color disabledBg = Color(0xFFF3EEE5);
    const Color iconInactive = Color(0xFFCDC1B4);
    const Color iconActive = Color(0xFFCDC1B4);
    const Color badgeBg = Color(0xFFCDC1B4);

    // Chỉ dùng màu nền cơ bản, không thay đổi khi active
    final Color bg = !enabled ? disabledBg : baseBg;
    // Chỉ thay đổi màu icon khi active, không thay đổi màu nền
    final Color iconColor = active ? iconActive : iconInactive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.black.withOpacity(0.6),
            highlightColor: Colors.black.withOpacity(0.4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active ? activeBg : const Color(0xFFCDC1B4),
                        width: active ? 5 : 2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                Positioned(
                  right: -4,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$charges',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (i) {
            final bool filled = i < charges;
            return Container(
              width: 16,
              height: 4,
              margin: EdgeInsets.only(right: i == 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: filled ? Color(0xFFCDC1B4) : Color(0xFFE5DFD6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF2D3748),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Game title
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _titleAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _titleScaleAnimation.value,
                                child: Opacity(
                                  opacity: _titleOpacityAnimation.value,
                                  child: Text(
                                    '2048',
                                    style: TextStyle(
                                      color: const Color(0xFF877355),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        Shadow(
                                          offset: const Offset(-1, -1),
                                          blurRadius: 2,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ],
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Leaderboard icon
                      GestureDetector(
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
                            color: const Color(0xFFF5F0E6), // Màu be nhạt như trong hình
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24), // Màu vàng gold
                        ),
                      ),
                    ],
                  ),
                ),
                // Game Stats - Score và Best
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Score Card
                      Container(
                        width: 110, // Tăng chiều rộng từ 80 lên 110 (+30px)
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Giảm padding dọc
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEBE0), // Màu beige nhạt
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCDC1B4), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SCORE',
                              style: TextStyle(
                                color: const Color(0xFF776E65), // Màu nâu xám
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2), // Giảm khoảng cách
                            Text(
                              '${board.score}',
                              style: TextStyle(
                                color: const Color(0xFF776E65),
                                fontSize: 14, // Tăng font size cho số điểm
                                fontWeight: FontWeight.w900, // In đậm hơn
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Best Card
                      Container(
                        width: 110, // Tăng chiều rộng từ 80 lên 110 (+30px)
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Giảm padding dọc
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E6), // Màu beige sáng hơn
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCDC1B4), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'BEST',
                              style: TextStyle(
                                color: const Color(0xFF776E65),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2), // Giảm khoảng cách
                            Text(
                              '${board.bestScore}',
                              style: TextStyle(
                                color: const Color(0xFF776E65),
                                fontSize: 14, // Tăng font size cho số điểm
                                fontWeight: FontWeight.w900, // In đậm hơn
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                // Game Board
                Center(
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onVerticalDragEnd: (d) {
                          if (_mode != ToolMode.none) return;
                          if (d.primaryVelocity == null) return;
                          _handleMove(d.primaryVelocity! < 0 ? Dir.up : Dir.down);
                        },
                        onHorizontalDragEnd: (d) {
                          if (_mode != ToolMode.none) return;
                          if (d.primaryVelocity == null) return;
                          _handleMove(d.primaryVelocity! < 0 ? Dir.left : Dir.right);
                        },
                        child: LayoutBuilder(
                          builder: (_, c) {
                            final size = min(c.maxWidth, c.maxHeight); // KHÔNG trừ thêm ở đây
                            return _BoardView(
                              board: board,
                              side: size,
                              mode: _mode,
                              swapA: _swapA,
                              onTapTile: (r, c) => _onTileTapForTools(r, c),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Control Buttons - styled like the provided design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _toolButton(
                        icon: Icons.undo,
                        onTap: _undoOnce,
                        active: false,
                        enabled: undoCharges > 0 && _mode == ToolMode.none,
                        charges: undoCharges,
                      ),
                      const SizedBox(width: 8),
                      _toolButton(
                        icon: Icons.swap_horiz,
                        onTap: _toggleSwapMode,
                        active: _mode == ToolMode.swapPickFirst || _mode == ToolMode.swapPickSecond,
                        enabled: swapCharges > 0 || _mode == ToolMode.swapPickFirst || _mode == ToolMode.swapPickSecond,
                        charges: swapCharges,
                      ),
                      const SizedBox(width: 8),
                      _toolButton(
                        icon: Icons.grid_view_rounded,
                        onTap: _toggleDeleteMode,
                        active: _mode == ToolMode.deletePick,
                        enabled: deleteCharges > 0 || _mode == ToolMode.deletePick,
                        charges: deleteCharges,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // New Game Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 47),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startNewGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB8B0A3),
                        foregroundColor: const Color(0xFF776E65),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF8B7355), width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _BoardView extends StatelessWidget {
  final Board2048 board;
  final double side;
  final dynamic mode; // ToolMode
  final Point<int>? swapA;
  final void Function(int r, int c)? onTapTile;
  const _BoardView({required this.board, required this.side, this.mode, this.swapA, this.onTapTile});

  @override
  Widget build(BuildContext context) {
    final n = board.size;

    // Tham số bố cục: dùng 1 giá trị cho padding & spacing
    const double outerPadding = 10.0; // đệm quanh khung
    const double spacing = 8.0;       // khoảng giữa các ô

    // Phần diện tích bên trong sau khi trừ padding
    final double innerAvail = side - outerPadding * 2;

    // Tính size 1 ô: làm tròn xuống để tránh dôi 1px gây overflow
    final double cell = ((innerAvail - spacing * (n - 1)) / n).floorToDouble();

    // Kích thước lưới thực tế sau khi làm tròn
    final double innerSize = cell * n + spacing * (n - 1);

    Color tileColor(int v) {
      // Nền cho ô rỗng (không có số)
      if (v == 0) return const Color(0xFFCDC1B4); // Empty tile background
      switch (v) {
        case 2: return const Color(0xFFEEE4DA);
        case 4: return const Color(0xFFEDE0C8);
        case 8: return const Color(0xFFF2B179);
        case 16: return const Color(0xFFF59563);
        case 32: return const Color(0xFFF67C5F);
        case 64: return const Color(0xFFF65E3B);
        case 128: return const Color(0xFFEDCF72);
        case 256: return const Color(0xFFEDCC61);
        case 512: return const Color(0xFFEDC850);
        case 1024: return const Color(0xFFEDC53F);
        case 2048: return const Color(0xFFEDC22E);
        default: return const Color(0xFF3C3A32); // >2048
      }
    }

    Color numColor(int v) {
      if (v == 0) return Colors.transparent; // Không hiển thị chữ cho ô trống
      if (v <= 4) return const Color(0xFF776E65); // Chữ nâu xám cho số nhỏ (2, 4)
      return Colors.white; // Chữ trắng cho số lớn (8, 16, 32, 512...)
    }

    return Container(
      width: side,
      height: side,
      clipBehavior: Clip.hardEdge, // cắt phần dư nếu còn sai số 1px
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0), // Board background color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B7355), width: 2), // Viền màu nâu đậm
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // padding: const EdgeInsets.all(outerPadding),
      padding: EdgeInsets.only(
        left: 2.0,
        right: 2.0,
        top: 2.0,
        bottom: 2.0,
      ),
      child: Center(
        // Grid luôn căn giữa, kích thước KHỚP CHUẨN innerSize
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: Column(
            children: [
              for (var r = 0; r < n; r++) ...[
                Row(
                  children: [
                    for (var c = 0; c < n; c++) ...[
                      GestureDetector(
                        onTap: onTapTile == null ? null : () => onTapTile!(r, c),
                        child: AnimatedOpacity(
                          opacity: board.grid[r][c] == 0 ? 0.6 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: cell,
                            height: cell,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tileColor(board.grid[r][c]),
                              borderRadius: BorderRadius.circular(8),
                              border: (swapA?.x == r && swapA?.y == c) ? Border.all(color: Colors.orange, width: 3) : null,
                              boxShadow: [
                                // Shadow cho ô rỗng (nhẹ hơn)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                  spreadRadius: 0.2,
                                ),
                                // Shadow cho ô có số (đậm hơn)
                                if (board.grid[r][c] != 0) ...[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: Offset(0, 3),
                                    spreadRadius: 0.5,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 6),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ],
                            ),
                            child: AnimatedScale(
                              scale: board.grid[r][c] == 0 ? 0.9 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Text(
                                board.grid[r][c] == 0 ? '' : '${board.grid[r][c]}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: cell * 0.45, // tỉ lệ theo ô
                                  color: numColor(board.grid[r][c]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (c < n - 1) const SizedBox(width: spacing),
                    ],
                  ],
                ),
                if (r < n - 1) const SizedBox(height: spacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
