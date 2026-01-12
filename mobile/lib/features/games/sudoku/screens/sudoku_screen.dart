import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/sudoku_models.dart';
import '../utils/sudoku_generator.dart';
import '../utils/sudoku_board.dart';
import '../../../../shared/widgets/game_bg.dart';
import '../../../leaderboard/utils/leaderboard_helper.dart';
import '../../../profile/utils/user_activity_helper.dart';
import '../../../leaderboard/screens/leaderboard_screen.dart';
import '../../../auth/repositories/auth_repository.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen>
    with TickerProviderStateMixin {
  final _gen = SudokuGenerator();

  SudokuPuzzle? _puzzle;
  SudokuBoardState? _state;
  int? _selected;
  String _level = 'Easy';
  late final Stopwatch _timer;
  bool _noteMode = false;
  int _mistakes = 0;
  bool _gameOver = false;
  Set<int> _highlightedCells = {}; // Các ô cần highlight khi chọn sai
  Set<int> _selectedAreaCells =
      {}; // Các ô trong vùng được chọn (3x3 + hàng + cột)
  String _currentGameLevel = 'Easy'; // Độ khó của game hiện tại (cố định)
  bool _isPaused = false; // Trạng thái tạm dừng game
  bool _gameCompleted = false; // Trạng thái hoàn thành game

  // Animation cho mistake counter
  late AnimationController _mistakeAnimationController;
  late Animation<double> _mistakeAnimation;
  bool _isMistakeFlashing = false; // Trạng thái nháy đỏ

  // Animation cho title
  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;
  late Animation<double> _titleOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch();

    // Khởi tạo animation controller cho mistake counter
    _mistakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _mistakeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _mistakeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Khởi tạo animation controller cho title
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

    // Bắt đầu animation cho title
    _titleAnimationController.forward();

    _newGame();
    _saveGameEntry();
  }

  // Lưu lịch sử khi vào game
  void _saveGameEntry() async {
    try {
      // Removed to avoid duplicate entries - game history is now saved from home_page.dart
      debugPrint('Sudoku game entry - history already saved from home page');
    } catch (e) {
      debugPrint('Error saving game entry: $e');
    }
  }

  @override
  void dispose() {
    _timer.stop();
    _mistakeAnimationController.dispose();
    _titleAnimationController.dispose();
    super.dispose();
  }

  void _newGame() async {
    final sol = _gen.generateSolution();
    final givens = _gen.makePuzzleFromSolution(sol, level: _level);
    final p = SudokuPuzzle(givens: givens, solution: sol, difficulty: _level);
    setState(() {
      _puzzle = p;
      _state = SudokuBoardState(List<int>.from(givens));
      _selected = null;
      _timer.reset();
      _timer.start();
      _mistakes = 0;
      _gameOver = false;
      _gameCompleted = false;
      _noteMode = false;
      _highlightedCells.clear();
      _selectedAreaCells.clear();
      _currentGameLevel = _level; // Cập nhật độ khó của game hiện tại
      _isPaused = false; // Reset trạng thái tạm dừng
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer.stop();
      } else {
        _timer.start();
      }
    });
  }

  Future<void> _saveBestTime(int timeInSeconds) async {
    print('DEBUG: _saveBestTime called with time: $timeInSeconds seconds');

    try {
      // Lấy username từ AuthRepository thay vì SharedPreferences
      final repo = AuthRepository();
      final user = await repo.getCurrentUser();
      final currentUser = user?.username ?? 'Player';

      debugPrint('DEBUG Sudoku: Saving best time for user: $currentUser');

      // Gọi hàm static từ LeaderboardHelper
      await LeaderboardHelper.saveSudokuResult(
        username: currentUser,
        difficulty: _currentGameLevel, // 'Easy' | 'Normal' | 'Hard' | 'Expert'
        timeSeconds: timeInSeconds,
      );

      debugPrint('DEBUG Sudoku: Successfully saved best time for $currentUser');
    } catch (e) {
      debugPrint('DEBUG Sudoku: Error saving best time: $e');
    }
  }

  Future<int?> _getBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sudoku_best_time_${_currentGameLevel.toLowerCase()}';
    return prefs.getInt(key);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showGameCompletedDialog() {
    final timeInSeconds = _timer.elapsed.inSeconds;
    final timeString = _formatTime(timeInSeconds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon chúc mừng
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                const Text(
                  'Chúc mừng!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Thời gian hoàn thành và độ khó
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Thời gian hoàn thành:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Độ khó:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentGameLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Nút chơi lại
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _newGame();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          'Chơi lại',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF57BCCE),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home, size: 18),
                        label: const Text(
                          'Trang chủ',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF57BCCE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
  }

  void _onCellTap(int index) {
    if (_gameOver || _isPaused) return;
    setState(() {
      _selected = index;
      _updateSelectedArea(index);
    });
  }

  void _updateSelectedArea(int index) {
    _selectedAreaCells.clear();

    // Tính toán vị trí trong lưới 9x9
    final row = index ~/ 9;
    final col = index % 9;

    // Highlight hàng ngang
    for (int c = 0; c < 9; c++) {
      _selectedAreaCells.add(row * 9 + c);
    }

    // Highlight cột dọc
    for (int r = 0; r < 9; r++) {
      _selectedAreaCells.add(r * 9 + col);
    }

    // Highlight khung 3x3
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        _selectedAreaCells.add(r * 9 + c);
      }
    }
  }

  void _onNumberTap(int n) {
    if (_puzzle == null ||
        _state == null ||
        _selected == null ||
        _gameOver ||
        _isPaused) return;
    final fixed = _puzzle!.givens[_selected!] != 0;
    if (fixed) return;

    setState(() {
      if (_noteMode) {
        // Chế độ note: toggle số trong notes
        _state = _state!.toggleNote(_selected!, n);
      } else {
        // Chế độ bình thường: điền số chính
        _state = _state!.setCell(_selected!, n);

        // Kiểm tra lỗi: so sánh với đáp án
        if (_puzzle!.solution[_selected!] != n) {
          _mistakes++;

          // Tìm và highlight các ô có số trùng
          _highlightedCells.clear();
          for (int i = 0; i < 81; i++) {
            if (_state!.cells[i] == n) {
              _highlightedCells.add(i);
            }
          }

          // _showSnack('Sai! Lỗi: $_mistakes/3', success: false); // Bỏ thông báo lỗi

          // Chạy animation nháy đỏ cho mistake counter
          setState(() {
            _isMistakeFlashing = true;
          });
          _mistakeAnimationController.forward().then((_) {
            _mistakeAnimationController.reverse().then((_) {
              setState(() {
                _isMistakeFlashing = false;
              });
            });
          });

          // Kiểm tra game over
          if (_mistakes >= 3) {
            _gameOver = true;
            _timer.stop();
            _showGameOverDialog();
          }
        } else {
          // Xóa highlight khi chọn đúng
          _highlightedCells.clear();

          // Kiểm tra thắng game
          if (_isSolved(_state!.cells, _puzzle!.solution)) {
            _timer.stop();
            _gameCompleted = true;
            _saveBestTime(_timer.elapsed.inSeconds);
            _showGameCompletedDialog();
          }
        }
      }

      // Kiểm tra hoàn thành game sau mỗi thay đổi
      if (!_gameCompleted && !_gameOver && _puzzle != null && _state != null) {
        print('DEBUG: Checking if game is solved...');
        if (_isSolved(_state!.cells, _puzzle!.solution)) {
          print('DEBUG: Game is solved! Stopping timer and saving...');
          _timer.stop();
          _gameCompleted = true;
          _saveBestTime(_timer.elapsed.inSeconds);
          _showGameCompletedDialog();
        }
      }
    });
  }

  void _onErase() {
    if (_puzzle == null ||
        _state == null ||
        _selected == null ||
        _gameOver ||
        _isPaused) return;
    final fixed = _puzzle!.givens[_selected!] != 0;
    if (fixed) return;
    setState(() {
      if (_noteMode) {
        // Chế độ note: xóa tất cả notes trong ô
        _state = _state!.clearNotes(_selected!);
      } else {
        // Chế độ bình thường: xóa số chính
        _state = _state!.setCell(_selected!, 0);
      }
      // Xóa highlight khi xóa số
      _highlightedCells.clear();
      _selectedAreaCells.clear();

      // Kiểm tra hoàn thành game sau khi xóa
      if (!_gameCompleted && !_gameOver && _puzzle != null && _state != null) {
        if (_isSolved(_state!.cells, _puzzle!.solution)) {
          _timer.stop();
          _gameCompleted = true;
          _saveBestTime(_timer.elapsed.inSeconds);
          _showGameCompletedDialog();
        }
      }
    });
  }

  void _onUndo() {
    if (_state == null || !_state!.canUndo() || _gameOver || _isPaused) return;
    setState(() {
      _state = _state!.undo();

      // Kiểm tra hoàn thành game sau khi undo
      if (!_gameCompleted && !_gameOver && _puzzle != null && _state != null) {
        if (_isSolved(_state!.cells, _puzzle!.solution)) {
          _timer.stop();
          _gameCompleted = true;
          _saveBestTime(_timer.elapsed.inSeconds);
          _showGameCompletedDialog();
        }
      }
    });
  }

  void _toggleNoteMode() {
    setState(() {
      _noteMode = !_noteMode;
    });
  }

  void _check() {
    if (_puzzle == null || _state == null || _gameOver || _isPaused) return;
    final ok = _isSolved(_state!.cells, _puzzle!.solution);
    if (ok) {
      _timer.stop();
      _gameCompleted = true;
      _saveBestTime(_timer.elapsed.inSeconds);
      _showGameCompletedDialog();
    } else {
      // Bỏ thông báo SnackBar
    }
  }

  bool _isSolved(List<int> cells, List<int> solution) {
    for (int i = 0; i < 81; i++) {
      if (cells[i] != solution[i]) return false;
    }
    return true;
  }

  void _giveHint() {
    // Hint đơn giản nhất: điền 1 ô sai hoặc trống thành đúng
    if (_puzzle == null || _state == null || _gameOver || _isPaused) return;

    for (int i = 0; i < 81; i++) {
      if (_state!.cells[i] == 0 || _state!.cells[i] != _puzzle!.solution[i]) {
        if (_puzzle!.givens[i] == 0) {
          setState(() {
            _state = _state!.setCell(i, _puzzle!.solution[i]);
            _selected = i;
          });

          // _showSnack('Hint: Đã điền số ${_puzzle!.solution[i]} vào ô ${i + 1}');

          return;
        }
      }
    }

    // Bỏ thông báo SnackBar
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Game Over
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_dissatisfied,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Game Over!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                const Text(
                  'Bạn đã sai quá 3 lần!\nHãy thử lại!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Difficulty Selection
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dropdownMenuTheme: DropdownMenuThemeData(
                          textStyle: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        popupMenuTheme: PopupMenuThemeData(
                          color: Colors.white,
                          textStyle: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _level,
                        isExpanded: true,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF2D3748)),
                        dropdownColor: Colors.white,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _level = newValue;
                            });
                          }
                        },
                        items: <String>['Easy', 'Medium', 'Hard', 'Expert']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Color(0xFF2D3748),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Play Again Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _newGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF57BCCE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Chơi lại',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Exit Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.exit_to_app, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Thoát',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    final state = _state;
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Positioned.fill(
            child: Container(
              color: const Color(0xFFC0E5EE),
            ),
          ),
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    'Sudoku Game',
                                    style: TextStyle(
                                      color: const Color(0xFF2D3748),
                                      fontSize: 22,
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
                      ),
                    ],
                  ),
                ),
                // Game stats
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mistakes counter với animation
                      AnimatedBuilder(
                        animation: _mistakeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _mistakeAnimation.value,
                            child: Row(
                              children: [
                                // const Icon(Icons.close, color: Colors.red, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  'Mistakes: $_mistakes/3',
                                  style: TextStyle(
                                    color: _mistakes >= 3
                                        ? Colors.red
                                        : (_isMistakeFlashing
                                            ? Colors.red
                                            : Colors.grey[600]),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Difficulty
                      Text(
                        _currentGameLevel,
                        style: const TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Timer
                      Row(
                        children: [
                          StreamBuilder<int>(
                            stream: Stream.periodic(
                                const Duration(seconds: 1), (i) => i),
                            builder: (context, snapshot) {
                              final elapsed = _timer.elapsed;
                              final minutes = (elapsed.inSeconds ~/ 60)
                                  .toString()
                                  .padLeft(2, '0');
                              final seconds = (elapsed.inSeconds % 60)
                                  .toString()
                                  .padLeft(2, '0');
                              return Text(
                                '$minutes:$seconds',
                                style: TextStyle(
                                  color: _isPaused
                                      ? Colors.grey[600]
                                      : const Color(0xFF2D3748),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _togglePause,
                            child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: _isPaused
                                  ? Colors.green
                                  : const Color(0xFF2D3748),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sudoku board
                Expanded(
                  child: Container(
                    child: puzzle == null || state == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF57BCCE)),
                            ),
                          )
                        : Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 400),
                                    child: SudokuBoard(
                                      givens: puzzle.givens,
                                      current: state.cells,
                                      selected: _selected,
                                      notes: state.notes,
                                      noteMode: _noteMode,
                                      highlightedCells: _highlightedCells,
                                      selectedAreaCells: _selectedAreaCells,
                                      onCellTap: _onCellTap,
                                      onNumberTap: _onNumberTap,
                                      onErase: _onErase,
                                      onUndo: _onUndo,
                                      onHint: _giveHint,
                                      onToggleNote: _toggleNoteMode,
                                      canUndo: state.canUndo(),
                                      level: _level,
                                      onLevelChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _level = newValue;
                                          });
                                        }
                                      },
                                      onNewGame: _newGame,
                                    ),
                                  ),
                                ),
                              ),
                              // Pause overlay
                              if (_isPaused)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.8),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.pause_circle_outline,
                                              size: 48,
                                              color: Color(0xFF57BCCE),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Trò chơi tạm dừng',
                                              style: TextStyle(
                                                color: Color(0xFF2D3748),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            ElevatedButton.icon(
                                              onPressed: _togglePause,
                                              icon: const Icon(Icons.play_arrow,
                                                  size: 18),
                                              label: const Text('Tiếp tục'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF57BCCE),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
