class SudokuPuzzle {
  /// 81 phần tử, 0 = trống. Givens là đề bài.
  final List<int> givens;
  /// 81 phần tử là nghiệm đúng hoàn chỉnh.
  final List<int> solution;
  final String difficulty; // Easy/Medium/Hard/Expert

  SudokuPuzzle({
    required this.givens,
    required this.solution,
    required this.difficulty,
  });

  SudokuPuzzle copyWith({List<int>? givens}) =>
      SudokuPuzzle(givens: givens ?? this.givens, solution: solution, difficulty: difficulty);
}

class SudokuBoardState {
  /// 81 phần tử, 0 = trống. Đây là trạng thái người chơi hiện tại.
  final List<int> cells;
  /// Lịch sử các bước để có thể undo
  final List<List<int>> history;
  /// Notes cho mỗi ô: Map<index, Set<int>> - các số có thể điền
  final Map<int, Set<int>> notes;

  SudokuBoardState(this.cells, {List<List<int>>? history, Map<int, Set<int>>? notes})
      : history = history ?? [List<int>.from(cells)],
        notes = notes ?? {} {
    assert(cells.length == 81);
  }

  SudokuBoardState setCell(int index, int value) {
    final next = List<int>.from(cells);
    next[index] = value;
    final newHistory = List<List<int>>.from(history);
    newHistory.add(List<int>.from(next));
    // Xóa notes khi điền số chính
    final newNotes = Map<int, Set<int>>.from(notes);
    newNotes.remove(index);
    return SudokuBoardState(next, history: newHistory, notes: newNotes);
  }

  SudokuBoardState toggleNote(int index, int number) {
    final newNotes = Map<int, Set<int>>.from(notes);
    if (!newNotes.containsKey(index)) {
      newNotes[index] = <int>{};
    }
    if (newNotes[index]!.contains(number)) {
      newNotes[index]!.remove(number);
      if (newNotes[index]!.isEmpty) {
        newNotes.remove(index);
      }
    } else {
      newNotes[index]!.add(number);
    }
    return SudokuBoardState(cells, history: history, notes: newNotes);
  }

  SudokuBoardState clearNotes(int index) {
    final newNotes = Map<int, Set<int>>.from(notes);
    newNotes.remove(index);
    return SudokuBoardState(cells, history: history, notes: newNotes);
  }

  SudokuBoardState undo() {
    if (history.length <= 1) return this; // Không thể undo nữa
    final newHistory = List<List<int>>.from(history);
    newHistory.removeLast();
    final previousState = newHistory.last;
    return SudokuBoardState(List<int>.from(previousState), history: newHistory, notes: notes);
  }

  bool canUndo() => history.length > 1;

  bool isComplete() => !cells.contains(0);
}
