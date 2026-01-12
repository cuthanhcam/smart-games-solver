import 'dart:math';

enum Dir { up, down, left, right }

class Board2048 {
  final int size;
  late List<List<int>> grid;
  int score = 0;
  int bestScore = 0; // Thêm thuộc tính bestScore
  bool won = false;
  bool get isGameOver => !_canMove();

  final Random _rnd;

  // Undo functionality
  List<List<List<int>>> _history = [];
  List<int> _scoreHistory = [];

  // Swap functionality
  int _swapUses = 2;
  int get swapUses => _swapUses;

  // Delete functionality
  int _deleteUses = 2;
  int get deleteUses => _deleteUses;

  Board2048({this.size = 4, Random? rnd}) : _rnd = rnd ?? Random() {
    reset();
  }

  void reset() {
    score = 0;
    won = false;
    _swapUses = 2; // Reset swap uses
    _deleteUses = 2; // Reset delete uses
    _history.clear();
    _scoreHistory.clear();
    grid = List.generate(size, (_) => List.filled(size, 0));
    _spawn(); _spawn();
  }

  List<Point<int>> _empties() {
    final e = <Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) e.add(Point(r, c));
      }
    }
    return e;
  }

  void _spawn() {
    final e = _empties();
    if (e.isEmpty) return;
    final p = e[_rnd.nextInt(e.length)];
    grid[p.x][p.y] = _rnd.nextDouble() < 0.9 ? 2 : 4;
  }

  bool move(Dir d) {
    // Save current state for undo
    _saveState();

    bool moved = false;
    int gained = 0;

    // duyệt theo chiều đúng
    List<List<int>> lines() {
      final out = <List<int>>[];
      if (d == Dir.left || d == Dir.right) {
        for (var r = 0; r < size; r++) {
          final row = List<int>.from(grid[r]);
          out.add(d == Dir.left ? row : row.reversed.toList());
        }
      } else {
        for (var c = 0; c < size; c++) {
          final col = [for (var r = 0; r < size; r++) grid[r][c]];
          out.add(d == Dir.up ? col : col.reversed.toList());
        }
      }
      return out;
    }

    List<List<int>> merged = [];
    for (final line in lines()) {
      final res = _slideMergeLine(line);
      merged.add(res.$1);
      if (res.$2) moved = true;
      gained += res.$3;
    }

    // ghi ngược lại vào grid
    if (d == Dir.left || d == Dir.right) {
      for (var r = 0; r < size; r++) {
        final line = d == Dir.left ? merged[r] : merged[r].reversed.toList();
        if (!_listEq(grid[r], line)) {
          grid[r] = line;
        }
      }
    } else {
      for (var c = 0; c < size; c++) {
        final src = merged[c];
        for (var r = 0; r < size; r++) {
          final v = d == Dir.up ? src[r] : src.reversed.toList()[r];
          if (grid[r][c] != v) {
            grid[r][c] = v;
          }
        }
      }
    }

    if (moved) {
      score += gained;
      // Cập nhật bestScore nếu điểm hiện tại vượt qua điểm cao nhất
      if (score > bestScore) {
        bestScore = score;
      }
      if (_contains2048()) won = true;
      _spawn();

      // Check for bonus uses after spawning
      _checkBonusUses();
    }
    return moved;
  }

  // Kết quả 1 dòng: (lineSau, moved?, gainedScore)
  (List<int>, bool, int) _slideMergeLine(List<int> line) {
    final filtered = line.where((v) => v != 0).toList();
    final out = <int>[];
    int gained = 0;
    int i = 0;
    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        final m = filtered[i] * 2;
        out.add(m);
        gained += m;
        i += 2;
      } else {
        out.add(filtered[i]);
        i += 1;
      }
    }
    while (out.length < size) out.add(0);
    final moved = !_listEq(line, out);
    return (out, moved, gained);
  }

  bool _canMove() {
    if (_empties().isNotEmpty) return true;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = grid[r][c];
        if (r + 1 < size && grid[r + 1][c] == v) return true;
        if (c + 1 < size && grid[r][c + 1] == v) return true;
      }
    }
    return false;
  }

  bool _contains2048() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] >= 2048) return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toMap() => {
    'size': size,
    'score': score,
    'won': won,
    'grid': [for (var r = 0; r < size; r++) [...grid[r]]],
  };

  static Board2048 fromMap(Map<String, dynamic> m) {
    final b = Board2048(size: m['size'] as int);
    b.score = m['score'] as int;
    b.won = m['won'] as bool;
    final g = (m['grid'] as List).map((row) => List<int>.from(row)).toList();
    b.grid = g.cast<List<int>>();
    return b;
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Undo functionality
  void _saveState() {
    _history.add([for (var r = 0; r < size; r++) [...grid[r]]]);
    _scoreHistory.add(score);
    // Keep only last 10 states to prevent memory issues
    if (_history.length > 10) {
      _history.removeAt(0);
      _scoreHistory.removeAt(0);
    }
  }

  bool undo() {
    if (_history.isEmpty) return false;

    grid = _history.removeLast();
    score = _scoreHistory.removeLast();
    return true;
  }

  // Swap functionality
  bool swapTiles(Point<int> pos1, Point<int> pos2) {
    if (_swapUses <= 0) return false;
    if (pos1.x < 0 || pos1.x >= size || pos1.y < 0 || pos1.y >= size) return false;
    if (pos2.x < 0 || pos2.x >= size || pos2.y < 0 || pos2.y >= size) return false;
    if (pos1 == pos2) return false;

    final temp = grid[pos1.x][pos1.y];
    grid[pos1.x][pos1.y] = grid[pos2.x][pos2.y];
    grid[pos2.x][pos2.y] = temp;

    _swapUses--;
    return true;
  }

  // Delete functionality
  bool deleteTile(Point<int> pos) {
    if (pos.x < 0 || pos.x >= size || pos.y < 0 || pos.y >= size) return false;
    if (grid[pos.x][pos.y] == 0) return false;
    if (_deleteUses <= 0) return false;

    // Check if there's at least one 256 tile
    bool has256 = false;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 256) {
          has256 = true;
          break;
        }
      }
      if (has256) break;
    }

    if (!has256) return false;

    grid[pos.x][pos.y] = 0;
    _deleteUses--;
    return true;
  }

  // Helper method to get all non-empty positions
  List<Point<int>> getNonEmptyPositions() {
    final positions = <Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] != 0) {
          positions.add(Point(r, c));
        }
      }
    }
    return positions;
  }

  // Check for bonus uses when getting special tiles
  void _checkBonusUses() {
    bool has128 = false;
    bool has256 = false;

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 128) has128 = true;
        if (grid[r][c] == 256) has256 = true;
      }
    }

    // Add swap use if 128 tile exists and not at max
    if (has128 && _swapUses < 2) {
      _swapUses++;
    }

    // Add delete use if 256 tile exists and not at max
    if (has256 && _deleteUses < 2) {
      _deleteUses++;
    }
  }
}

