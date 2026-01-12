import 'dart:math';

class _Rnd {
  final _r = Random();
  T pick<T>(List<T> a) => a[_r.nextInt(a.length)];
  void shuffle<T>(List<T> a) => a.shuffle(_r);
}

class SudokuGenerator {
  final _rnd = _Rnd();

  /// Tạo nghiệm hoàn chỉnh 9x9 (backtracking + trộn ngẫu nhiên)
  List<int> generateSolution() {
    final board = List<int>.filled(81, 0);
    _fill(board, 0);
    return board;
  }

  bool _fill(List<int> b, int idx) {
    if (idx == 81) return true;
    final r = idx ~/ 9, c = idx % 9;
    final nums = List<int>.generate(9, (i) => i + 1);
    _rnd.shuffle(nums);
    for (final n in nums) {
      if (_canPut(b, r, c, n)) {
        b[idx] = n;
        if (_fill(b, idx + 1)) return true;
        b[idx] = 0;
      }
    }
    return false;
  }

  bool _canPut(List<int> b, int r, int c, int n) {
    for (int i = 0; i < 9; i++) {
      if (b[r * 9 + i] == n) return false;
      if (b[i * 9 + c] == n) return false;
    }
    final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
    for (int dr = 0; dr < 3; dr++) {
      for (int dc = 0; dc < 3; dc++) {
        if (b[(br + dr) * 9 + (bc + dc)] == n) return false;
      }
    }
    return true;
  }

  /// Kiểm tra nghiệm duy nhất (tối đa 2 nghiệm là đủ để kết luận).
  bool hasUniqueSolution(List<int> givens) {
    int solutions = 0;
    final b = List<int>.from(givens);
    bool dfs(int idx) {
      while (idx < 81 && b[idx] != 0) idx++;
      if (idx == 81) {
        solutions++;
        return solutions == 1;
      }
      final r = idx ~/ 9, c = idx % 9;
      for (int n = 1; n <= 9; n++) {
        if (_canPut(b, r, c, n)) {
          b[idx] = n;
          if (!dfs(idx + 1)) {
            b[idx] = 0;
            if (solutions > 1) return false;
            continue;
          }
          b[idx] = 0;
          if (solutions > 1) return false;
        }
      }
      return solutions <= 1;
    }

    dfs(0);
    return solutions == 1;
  }

  /// Sinh đề từ solution bằng cách xóa ô (đào lỗ) nhưng vẫn unique.
  List<int> makePuzzleFromSolution(List<int> solution, {required String level}) {
    final targetHoles = _holesFor(level);
    final givens = List<int>.from(solution);
    final indices = List<int>.generate(81, (i) => i)..shuffle(Random());

    int holes = 0;
    for (final idx in indices) {
      final keep = givens[idx];
      givens[idx] = 0;
      if (hasUniqueSolution(givens)) {
        holes++;
        if (holes >= targetHoles) break;
      } else {
        givens[idx] = keep; // không unique → khôi phục
      }
    }
    return givens;
  }

  int _holesFor(String level) {
    switch (level) {
      case 'Easy': return 40;   // 41–49 ô trống
      case 'Medium': return 50; // 50–54
      case 'Hard': return 55;   // 55–58
      case 'Expert': return 58; // 58–60+
      default: return 50;
    }
  }
}
