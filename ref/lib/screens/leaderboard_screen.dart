import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/leaderboard_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedGame = 'Sudoku';
  String _selectedDifficulty = 'Easy';

  /// Chỉ còn 4 mức: easy | normal | hard | expert
  static const List<String> _difficultiesUi = ['Easy', 'Normal', 'Hard', 'Expert'];

  /// Map "tab" -> danh sách hậu tố key cần đọc (ở đây mỗi tab 1 hậu tố)
  static const Map<String, List<String>> _difficultyAliases = {
    'Easy':   ['easy'],
    'Normal': ['normal'],
    'Hard':   ['hard'],
    'Expert': ['expert'],
  };

  /// Dữ liệu leaderboard cho từng game/mức (đã bỏ Medium)
  final Map<String, Map<String, List<Map<String, dynamic>>>> _leaderboard = {
    'Sudoku': {
      'Easy':   [],
      'Normal': [],
      'Hard':   [],
      'Expert': [],
    },
    'Caro': {
      'Easy':   [],
      'Normal': [],
      'Hard':   [],
      'Expert': [],
    },
    '2048': {
      'Easy':   [],
      'Normal': [],
      'Hard':   [],
      'Expert': [],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  // sudoku_best_time_{username}_{suffix} với suffix ∈ (easy|normal|hard|expert)
  final RegExp _bestTimeKey =
      RegExp(r'^sudoku_best_time_(.+)_(easy|normal|hard|expert)$');

  // caro_best_time_{username}_{suffix} với suffix ∈ (easy|normal|hard|expert)
  final RegExp _bestCaroKey =
      RegExp(r'^caro_best_time_(.+)_(easy|normal|hard|expert)$');

  // caro_move_count_{username}_{suffix} với suffix ∈ (easy|normal|hard|expert)
  final RegExp _bestCaroMoveKey =
      RegExp(r'^caro_move_count_(.+)_(easy|normal|hard|expert)$');

  // 2048: hỗ trợ cả g2048_best_score_{username} và 2048_best_score_{username}
  final RegExp _best2048Key = RegExp(r'^(?:g)?2048_best_score_(.+)$');

  String _completedDateKey(String username, String diffLower, String game) =>
      '${game.toLowerCase()}_completed_date_${username}_$diffLower';

  Future<void> _loadLeaderboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    debugPrint('DEBUG keys: $allKeys');

    // Load Sudoku leaderboard
    for (final difficulty in _difficultiesUi) {
      final suffixes = _difficultyAliases[difficulty]!;
      final List<Map<String, dynamic>> scores = [];

      // Lọc đúng key cho tab hiện tại
      final sudokuKeys = allKeys.where((k) {
        if (!k.startsWith('sudoku_best_time_')) return false;
        return suffixes.any((suf) => k.endsWith('_$suf'));
      });

      debugPrint('DEBUG Sudoku [$difficulty] keys(${sudokuKeys.length}): $sudokuKeys');

      for (final key in sudokuKeys) {
        final m = _bestTimeKey.firstMatch(key);
        if (m == null) continue;

        final username    = m.group(1)!; // hỗ trợ username có dấu '_'
        final diffLower   = m.group(2)!; // easy|normal|hard|expert
        final bestSeconds = prefs.getInt(key);
        if (bestSeconds == null) continue;

        final completedIso =
            prefs.getString(_completedDateKey(username, diffLower, 'sudoku')) ??
            DateTime.now().toIso8601String();

        scores.add({
          'username': username,
          'time': _formatTime(bestSeconds),
          'completedAt': _formatDate(completedIso),
          'durationSeconds': bestSeconds, // sort theo thời gian
        });
      }

      // Sắp xếp: nhanh nhất đứng trên
      scores.sort((a, b) =>
          (a['durationSeconds'] as int).compareTo(b['durationSeconds'] as int));

      // (Tuỳ chọn) seed demo nếu trống
      if (scores.isEmpty) {
        if (difficulty == 'Easy') {
          scores.addAll([
            {'username': 'userA', 'time': '00:15', 'completedAt': 'Hôm nay', 'durationSeconds': 15},
          ]);
        } else if (difficulty == 'Normal') {
          scores.addAll([
            {'username': 'userB', 'time': '00:09', 'completedAt': 'Hôm nay', 'durationSeconds': 9},
          ]);
        }
      }

      _leaderboard['Sudoku']![difficulty] = scores;
    }

    // Load Caro leaderboard
    for (final difficulty in _difficultiesUi) {
      final suffixes = _difficultyAliases[difficulty]!;
      final List<Map<String, dynamic>> scores = [];

      // Lọc đúng key cho tab hiện tại
      final caroKeys = allKeys.where((k) {
        if (!k.startsWith('caro_best_time_')) return false;
        return suffixes.any((suf) => k.endsWith('_$suf'));
      });

      debugPrint('DEBUG Caro [$difficulty] keys(${caroKeys.length}): $caroKeys');

      for (final key in caroKeys) {
        final m = _bestCaroKey.firstMatch(key);
        if (m == null) continue;

        final username    = m.group(1)!; // hỗ trợ username có dấu '_'
        final diffLower   = m.group(2)!; // easy|normal|hard|expert
        final bestSeconds = prefs.getInt(key);
        if (bestSeconds == null) continue;

        // Lấy số lượt đi
        final moveKey = 'caro_move_count_${username}_$diffLower';
        final moveCount = prefs.getInt(moveKey) ?? 0;

        final completedIso =
            prefs.getString(_completedDateKey(username, diffLower, 'caro')) ??
            DateTime.now().toIso8601String();

        scores.add({
          'username': username,
          'time': _formatTime(bestSeconds),
          'completedAt': _formatDate(completedIso),
          'durationSeconds': bestSeconds, // sort theo thời gian
          'moveCount': moveCount, // số lượt đi
        });
      }

      // Sắp xếp: nhanh nhất đứng trên
      scores.sort((a, b) =>
          (a['durationSeconds'] as int).compareTo(b['durationSeconds'] as int));

      // (Tuỳ chọn) seed demo nếu trống
      if (scores.isEmpty) {
        if (difficulty == 'Easy') {
          scores.addAll([
            {'username': 'player1', 'time': '00:45', 'completedAt': 'Hôm nay', 'durationSeconds': 45, 'moveCount': 12},
          ]);
        } else if (difficulty == 'Normal') {
          scores.addAll([
            {'username': 'player2', 'time': '01:20', 'completedAt': 'Hôm nay', 'durationSeconds': 80, 'moveCount': 18},
          ]);
        }
      }

      _leaderboard['Caro']![difficulty] = scores;
    }

    // Load leaderboard cho 2048 (không có độ khó)
    final List<Map<String, dynamic>> g2048Scores = [];
    debugPrint('DEBUG 2048: Loading 2048 leaderboard data...');
    
    // Tìm tất cả key có format g2048_best_score_{username}
    final g2048Keys = allKeys.where((k) => k.startsWith('g2048_best_score_'));
    
    for (final key in g2048Keys) {
      final username = key.substring('g2048_best_score_'.length);
      final best = prefs.getInt(key);
      if (best == null) continue;
      
      debugPrint('DEBUG 2048: Found score for $username: $best');
      
      // Lấy ngày hoàn thành từ key mới
      final dateIso = prefs.getString('g2048_completed_date_$username') ??
          DateTime.now().toIso8601String();
      
      g2048Scores.add({
        'username': username,
        'score': best,
        'completedAt': _formatDate(dateIso),
        'scoreValue': best, // để sort theo điểm
      });
    }
    
    debugPrint('DEBUG 2048: Found ${g2048Scores.length} scores: $g2048Scores');
    
    // Sắp xếp giảm dần theo điểm (điểm cao nhất đứng đầu)
    g2048Scores.sort((a, b) => (b['scoreValue'] as int).compareTo(a['scoreValue'] as int));
    
    _leaderboard['2048']!['Easy'] = g2048Scores; // dùng slot "Easy" như "All"

    setState(() {});
  }


  /// Xoá toàn bộ dữ liệu leaderboard Sudoku (không đụng current user)
  Future<void> _clearAllLeaderboardData(SharedPreferences prefs) async {
    final keys = prefs.getKeys().where((k) =>
      k.startsWith('sudoku_best_time_') ||
      k.startsWith('sudoku_completed_date_'),
    );
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('DEBUG: cleared ${keys.length} keys.');
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      final now  = DateTime.now();
      final today     = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d         = DateTime(date.year, date.month, date.day);
      if (d == today) return 'Hôm nay';
      if (d == yesterday) return 'Hôm qua';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Hôm nay';
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    // muốn hiển thị mm:ss.ms thì lưu thêm mili giây và định dạng lại
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF57BCCE), Color(0xFFA8D3CA), Color(0xFFDADCB7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const SizedBox(width: 12),
                    const Text(
                      'Bảng Xếp Hạng',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Chọn game
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      for (final game in ['Sudoku', 'Caro', '2048'])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedGame = game;
                              _selectedDifficulty = 'Easy';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedGame == game
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                game,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _selectedGame == game
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Thanh tiêu đề/độ khó: Sudoku và Caro hiển thị mức, 2048 chỉ hiển thị HIGHSCORE
              if (_selectedGame == '2048')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'HIGHSCORE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Chọn độ khó (chỉ Easy/Normal/Hard/Expert)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4, runSpacing: 4,
                      children: [
                        for (final diff in _difficultiesUi)
                          GestureDetector(
                            onTap: () => setState(() => _selectedDifficulty = diff),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedDifficulty == diff
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                diff,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _selectedDifficulty == diff
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Nội dung leaderboard
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: _buildLeaderboardContent(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    final scores = _leaderboard[_selectedGame]?[_selectedDifficulty] ?? [];

    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text('Chưa có kết quả nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Hãy hoàn thành game để lập kỷ lục!',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        final rank = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: rank <= 3 ? Colors.amber[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: rank <= 3 ? Colors.amber[200]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: rank <= 3 ? Colors.amber : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(rank.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(score['username']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D3748)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Hoàn thành: ${score['completedAt'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedGame == 'Caro' && score['moveCount'] != null)
                      Text('Lượt đi: ${score['moveCount']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Time / Score column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _selectedGame == '2048' ? 'Điểm' : 'Thời gian',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedGame == '2048'
                        ? '${score['score'] ?? 0}'
                        : (score['time'] ?? '00:00'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11,
                      color: rank <= 3 ? Colors.amber[700] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}