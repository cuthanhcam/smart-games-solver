import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/game_state.dart';
import '../utils/ai_service.dart';
import '../widgets/game_board.dart';
import '../../../auth/repositories/auth_repository.dart';
import '../../../leaderboard/screens/leaderboard_screen.dart';
import '../../../leaderboard/utils/leaderboard_helper.dart';
import '../../../profile/utils/user_activity_helper.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final Difficulty difficulty;

  const GameScreen({
    Key? key,
    required this.gameMode,
    required this.difficulty,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState gameState;
  List<int>? hintMove;
  bool isAIThinking = false;
  Timer? _aiTimer;
  List<int>? _lastAIMove;
  bool _isInitializing = false;

  // New: header data
  String _currentUsername = 'Khách';
  int _totalMoveCount = 0;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    gameState = GameState.newGame(
      mode: widget.gameMode,
      difficulty: widget.difficulty,
    );
    _startElapsedTimer();
    _initializeGame();
    if (widget.gameMode == GameMode.evE) {
      _startAIvsAI();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  Future<void> _initializeGame() async {
    await _loadCurrentUser();
    await _saveGameEntry();
  }

  // Lưu lịch sử khi vào game
  Future<void> _saveGameEntry() async {
    try {
      // Removed to avoid duplicate entries - game history is now saved from home_page.dart
      debugPrint('Caro game entry - history already saved from home page');
    } catch (e) {
      debugPrint('Error saving caro game entry: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    final repo = AuthRepository();
    final user = await repo.getCurrentUser();
    if (mounted) setState(() => _currentUsername = user?.username ?? 'Khách');
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startAIvsAI() {
    // Bắt đầu AI ngay lập tức
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !gameState.gameOver) {
        _makeAIMove();
      }
    });

    // Sau đó tiếp tục với timer
    _aiTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (gameState.gameOver) {
        timer.cancel();
        return;
      }
      if (mounted) {
        _makeAIMove();
      }
    });
  }

  void _onCellTap(int row, int col) {
    if (gameState.gameOver || isAIThinking) return;
    if (widget.gameMode == GameMode.evE) return;

    setState(() {
      hintMove = null;
      _lastAIMove = null; // Clear AI move highlight when player moves
      if (gameState.makeMove(row, col, Player.x)) {
        _totalMoveCount++;
        if (!gameState.gameOver) {
          _makeAIMove();
        } else {
          _showGameOverDialog();
        }
      }
    });
  }

  void _makeAIMove() async {
    if (!mounted) return;

    setState(() => isAIThinking = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Sử dụng currentPlayer để xác định AI nào đang chơi
    final currentPlayer = gameState.currentPlayer;
    final move = AIService.getBestMoveWithDifficultyForPlayer(
        gameState, widget.difficulty, currentPlayer);
    print('AI move for ${currentPlayer.name}: $move'); // Debug logging
    print(
        'Current board state before move: ${gameState.board[0][0]}'); // Debug logging

    if (mounted) {
      setState(() {
        if (move[0] != -1 && move[1] != -1) {
          print(
              'Making AI move at: ${move[0]}, ${move[1]} for ${currentPlayer.name}'); // Debug logging
          final moveSuccess =
              gameState.makeMove(move[0], move[1], currentPlayer);
          print('AI move success: $moveSuccess'); // Debug logging
          print(
              'Board after move: ${gameState.board[move[0]][move[1]]}'); // Debug logging
          print(
              'Game over: ${gameState.gameOver}, Winner: ${gameState.winner}'); // Debug logging
          _lastAIMove = [move[0], move[1]];
          _totalMoveCount++;
          if (gameState.gameOver) {
            print('Game ended! Winner: ${gameState.winner}'); // Debug logging
            _showGameOverDialog();
          }
        } else {
          print('Invalid AI move: $move'); // Debug logging
        }
        isAIThinking = false;
      });
    }
  }

  void _showHint() {
    if (gameState.gameOver || widget.gameMode == GameMode.evE) return;

    setState(() {
      hintMove = AIService.getHint(gameState);
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => hintMove = null);
      }
    });
  }

  void _undoMove() {
    if (gameState.gameOver || gameState.moveHistory.isEmpty) return;

    setState(() {
      // Hoàn tác cả bước đi của người và máy (2 bước đi)
      if (gameState.moveHistory.length >= 2) {
        // Hoàn tác bước đi của máy (O)
        gameState.undoMove();
        // Hoàn tác bước đi của người (X)
        gameState.undoMove();
        _totalMoveCount -= 2; // Giảm số lượt đi tổng
      } else if (gameState.moveHistory.length == 1) {
        // Chỉ có 1 bước đi (người chơi chưa đánh)
        gameState.undoMove();
        _totalMoveCount = 0;
      }
      _lastAIMove = null; // Clear AI move highlight when undoing
    });
  }

  void _showGameOverDialog() {
    // Lưu kết quả vào leaderboard nếu người chơi thắng
    if (gameState.winner == Player.x) {
      _saveGameResult();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(minWidth: 380, maxWidth: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gameState.winner == null
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : widget.gameMode == GameMode.evE
                              ? [Colors.blue.shade400, Colors.blue.shade600]
                              : (gameState.winner == Player.x
                                  ? [Colors.blue.shade400, Colors.blue.shade600]
                                  : [Colors.red.shade400, Colors.red.shade600]),
                    ),
                  ),
                  child: Icon(
                    gameState.winner == null
                        ? Icons.handshake
                        : Icons.emoji_events,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  gameState.winner == null
                      ? 'Hòa!'
                      : widget.gameMode == GameMode.evE
                          ? 'Chiến thắng!'
                          : (gameState.winner == Player.x
                              ? 'Thắng cuộc!'
                              : 'Thua cuộc!'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  gameState.winner == null
                      ? 'Trận đấu hòa'
                      : widget.gameMode == GameMode.evE
                          ? (gameState.winner == Player.x
                              ? 'Máy 1 thắng!'
                              : 'Máy 2 thắng!')
                          : (gameState.winner == Player.x
                              ? 'Bạn đã thắng!'
                              : 'Máy đã thắng!'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng số lượt đi: $_totalMoveCount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gameState.winner == null
                                  ? [Colors.blue.shade400, Colors.blue.shade600]
                                  : widget.gameMode == GameMode.evE
                                      ? [
                                          Colors.blue.shade400,
                                          Colors.blue.shade600
                                        ]
                                      : (gameState.winner == Player.x
                                          ? [
                                              Colors.blue.shade400,
                                              Colors.blue.shade600
                                            ]
                                          : [
                                              Colors.red.shade400,
                                              Colors.red.shade600
                                            ]),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: gameState.winner == null
                                    ? Colors.blue.withOpacity(0.3)
                                    : widget.gameMode == GameMode.evE
                                        ? Colors.blue.withOpacity(0.3)
                                        : (gameState.winner == Player.x
                                            ? Colors.blue.withOpacity(0.3)
                                            : Colors.red.withOpacity(0.3)),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetGame();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Chơi lại',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
        ),
      );
    });
  }

  void _resetGame() async {
    setState(() {
      _isInitializing = true;
      gameState = GameState.newGame(
        mode: widget.gameMode,
        difficulty: widget.difficulty,
      );
      hintMove = null;
      isAIThinking = false;
      _lastAIMove = null;
      _totalMoveCount = 0;
    });
    _startElapsedTimer();

    if (widget.gameMode == GameMode.evE) {
      _startAIvsAI();
    }
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatHMS(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
    }
  }

  void _saveGameResult() async {
    try {
      // Save Caro game result to leaderboard
      await LeaderboardHelper.saveCaroResult(
        username: _currentUsername,
        difficulty: _difficultyLabel(widget.difficulty),
        timeSeconds: _elapsedSeconds,
        moveCount: _totalMoveCount,
      );
    } catch (e) {
      debugPrint('Error saving Caro result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3748),
        title: Text(
          widget.gameMode == GameMode.pvE ? 'Người vs Máy' : 'AI vs AI',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF2D3748),
          ),
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
                child: const Icon(Icons.leaderboard,
                    color: Color(0xFF4299E1), size: 24), // Professional Blue
              ),
            ),
          ),
          // Refresh button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
              onPressed: _resetGame,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF7FAFC),
            child: Column(
              children: [
                // Thanh thông tin người chơi và máy (2 hàng)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== Hàng trên: biểu tượng, tên, máy =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // --- Người chơi (X)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade400,
                                      Colors.red.shade600
                                    ],
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
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.gameMode == GameMode.evE
                                        ? 'Máy 1'
                                        : _currentUsername,
                                    style: const TextStyle(
                                      color: Color(0xFF2D3748),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.gameMode == GameMode.evE
                                        ? 'AI Tấn công'
                                        : 'Người chơi',
                                    style: const TextStyle(
                                        color: Color(0xFF718096), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // --- Máy (O)
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.gameMode == GameMode.evE
                                        ? 'Máy 2'
                                        : 'Máy',
                                    style: const TextStyle(
                                      color: Color(0xFF2D3748),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.gameMode == GameMode.evE
                                        ? 'AI Phòng thủ'
                                        : '${_difficultyLabel(widget.difficulty)}',
                                    style: const TextStyle(
                                        color: Color(0xFF718096), fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.circle_outlined,
                                    color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ===== Hàng dưới: bộ đếm thời gian & số lượt đi =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // --- Số lượt đi ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Lượt đi: $_totalMoveCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // --- Bộ đếm thời gian (Stopwatch style) ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade600
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _formatHMS(_elapsedSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Game Board
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: GameBoard(
                        gameState: gameState,
                        onCellTap: _onCellTap,
                        hintMove: hintMove,
                        lastAIMove: _lastAIMove,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons - 2 nút tròn ở cuối màn hình
          if (widget.gameMode == GameMode.pvE && !gameState.gameOver)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Undo Button
                    GestureDetector(
                      onTap: gameState.moveHistory.isEmpty ? null : _undoMove,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gameState.moveHistory.isEmpty
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade600
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: gameState.moveHistory.isEmpty
                                  ? Colors.grey.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.undo,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    // Hint Button
                    GestureDetector(
                      onTap: isAIThinking ? null : _showHint,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isAIThinking
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade600
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: isAIThinking
                                  ? Colors.grey.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          isAIThinking
                              ? Icons.hourglass_empty
                              : Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isInitializing)
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
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
}
