import 'package:flutter/material.dart';
import '../repositories/leaderboard_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedGame = 'Sudoku';
  String _selectedDifficulty = 'Easy';
  bool _isLoading = false;
  String? _error;

  static const List<String> _difficultiesUi = [
    'Easy',
    'Normal',
    'Hard',
    'Expert'
  ];

  final Map<String, Map<String, List<Map<String, dynamic>>>> _leaderboard = {
    'Sudoku': {
      'Easy': [],
      'Normal': [],
      'Hard': [],
      'Expert': [],
    },
    'Caro': {
      'Easy': [],
      'Normal': [],
      'Hard': [],
      'Expert': [],
    },
    '2048': {
      'Easy': [],
      'Normal': [],
      'Hard': [],
      'Expert': [],
    },
  };

  late LeaderboardRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = LeaderboardRepository();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadSudokuLeaderboard(),
        _loadCaroLeaderboard(),
        _load2048Leaderboard(),
      ]);
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      setState(() {
        _error = 'Không thể tải bảng xếp hạng: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSudokuLeaderboard() async {
    try {
      final data = await _repository.getSudokuLeaderboard(limit: 100);

      for (final difficulty in _difficultiesUi) {
        final scores = data
            .where((item) {
              final gameData = item['game_data'] as Map<String, dynamic>?;
              final diff = gameData?['difficulty']?.toString().toLowerCase();
              if (difficulty == 'Normal') {
                return diff == 'normal' || diff == 'medium';
              }
              return diff == difficulty.toLowerCase();
            })
            .map((item) => {
                  'username': item['username']?.toString() ?? 'Unknown',
                  'time': _formatTime(item['time_seconds'] as int? ?? 0),
                  'completedAt': _formatDate(item['played_at']?.toString() ??
                      DateTime.now().toIso8601String()),
                  'durationSeconds': item['time_seconds'] as int? ?? 0,
                })
            .toList();

        scores.sort((a, b) => (a['durationSeconds'] as int)
            .compareTo(b['durationSeconds'] as int));
        _leaderboard['Sudoku']![difficulty] = scores;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading Sudoku leaderboard: $e');
      rethrow;
    }
  }

  Future<void> _loadCaroLeaderboard() async {
    try {
      final data = await _repository.getCaroLeaderboard(limit: 100);

      for (final difficulty in _difficultiesUi) {
        final scores = data
            .where((item) {
              final gameData = item['game_data'] as Map<String, dynamic>?;
              final diff = gameData?['difficulty']?.toString().toLowerCase();
              if (difficulty == 'Normal') {
                return diff == 'normal' || diff == 'medium';
              }
              return diff == difficulty.toLowerCase();
            })
            .map((item) => {
                  'username': item['username']?.toString() ?? 'Unknown',
                  'time': _formatTime(item['score'] as int? ?? 0),
                  'completedAt': _formatDate(item['played_at']?.toString() ??
                      DateTime.now().toIso8601String()),
                  'durationSeconds': item['score'] as int? ?? 0,
                  'moveCount': item['moveCount'] ?? 0,
                })
            .toList();

        scores.sort((a, b) => (a['durationSeconds'] as int)
            .compareTo(b['durationSeconds'] as int));
        _leaderboard['Caro']![difficulty] = scores;
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading Caro leaderboard: $e');
      rethrow;
    }
  }

  Future<void> _load2048Leaderboard() async {
    try {
      final data = await _repository.get2048Leaderboard(limit: 100);

      final scores = data
          .map((item) => {
                'username': item['username']?.toString() ?? 'Unknown',
                'score': item['score'] as int? ?? 0,
                'completedAt': _formatDate(item['played_at']?.toString() ??
                    DateTime.now().toIso8601String()),
                'scoreValue': item['score'] as int? ?? 0,
              })
          .toList();

      scores.sort(
          (a, b) => (b['scoreValue'] as int).compareTo(a['scoreValue'] as int));
      _leaderboard['2048']!['Easy'] = scores;

      setState(() {});
    } catch (e) {
      debugPrint('Error loading 2048 leaderboard: $e');
      rethrow;
    }
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final d = DateTime(date.year, date.month, date.day);
      if (d == today) return 'Hôm nay';
      if (d == yesterday) return 'Hôm qua';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Bảng Xếp Hạng',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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

              // Thanh tiêu đề/độ khó
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
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final diff in _difficultiesUi)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDifficulty = diff),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 64, color: Colors.red[400]),
                                const SizedBox(height: 20),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                      color: Colors.red[700], fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadLeaderboardData,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
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
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Chưa có kết quả',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy hoàn thành game để lập kỷ lục!',
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rank <= 3 ? Colors.amber : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score['username']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2D3748),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hoàn thành: ${score['completedAt'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedGame == 'Caro' &&
                        score['moveCount'] != null &&
                        score['moveCount'] != 0)
                      Text(
                        'Lượt đi: ${score['moveCount']}',
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
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
