enum CellState { empty, x, o }

enum GameMode { pvE, evE }

enum Difficulty { easy, normal, hard, expert }

enum Player { x, o }

class GameState {
  List<List<CellState>> board;
  Player currentPlayer;
  GameMode gameMode;
  Difficulty difficulty;
  bool gameOver;
  Player? winner;
  List<List<int>> winningLine;
  int moveCount;
  List<Map<String, dynamic>> moveHistory; // Track moves for undo functionality

  GameState({
    required this.board,
    this.currentPlayer = Player.x,
    this.gameMode = GameMode.pvE,
    this.difficulty = Difficulty.normal,
    this.gameOver = false,
    this.winner,
    this.winningLine = const [],
    this.moveCount = 0,
    List<Map<String, dynamic>>? moveHistory,
  }) : moveHistory = moveHistory ?? [];

  factory GameState.newGame({
    int size = 35,
    GameMode mode = GameMode.pvE,
    Difficulty difficulty = Difficulty.normal,
  }) {
    return GameState(
      board: List.generate(
        size,
        (_) => List.generate(size, (_) => CellState.empty),
      ),
      gameMode: mode,
      difficulty: difficulty,
    );
  }

  bool makeMove(int row, int col, Player player) {
    if (board[row][col] != CellState.empty || gameOver) return false;

    // Store move in history before making it
    moveHistory.add({
      'row': row,
      'col': col,
      'player': player,
      'previousState': player == Player.x ? CellState.empty : CellState.empty,
      'moveCount': moveCount,
      'currentPlayer': currentPlayer,
      'gameOver': gameOver,
      'winner': winner,
      'winningLine': List<List<int>>.from(winningLine),
    });

    board[row][col] = player == Player.x ? CellState.x : CellState.o;
    moveCount++;

    if (checkWin(row, col)) {
      gameOver = true;
      winner = player;
      return true;
    }

    if (moveCount == board.length * board.length) {
      gameOver = true;
      return true;
    }

    currentPlayer = player == Player.x ? Player.o : Player.x;
    return true;
  }

  bool checkWin(int row, int col) {
    final directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];

    final cellState = board[row][col];

    for (var dir in directions) {
      int count = 1;
      List<List<int>> line = [
        [row, col],
      ];

      for (int i = 1; i < 5; i++) {
        int r = row + dir[0] * i;
        int c = col + dir[1] * i;
        if (!isValidCell(r, c) || board[r][c] != cellState) break;
        count++;
        line.add([r, c]);
      }

      for (int i = 1; i < 5; i++) {
        int r = row - dir[0] * i;
        int c = col - dir[1] * i;
        if (!isValidCell(r, c) || board[r][c] != cellState) break;
        count++;
        line.insert(0, [r, c]);
      }

      if (count >= 5) {
        winningLine = line.take(5).toList();
        return true;
      }
    }

    return false;
  }

  /// Undo the last move
  bool undoMove() {
    if (moveHistory.isEmpty) return false;

    final lastMove = moveHistory.removeLast();
    final row = lastMove['row'] as int;
    final col = lastMove['col'] as int;

    // Restore the cell to empty
    board[row][col] = CellState.empty;

    // Restore game state
    moveCount = lastMove['moveCount'] as int;
    currentPlayer = lastMove['currentPlayer'] as Player;
    gameOver = lastMove['gameOver'] as bool;
    winner = lastMove['winner'] as Player?;
    winningLine = List<List<int>>.from(
      lastMove['winningLine'] as List<List<int>>,
    );

    return true;
  }

  bool isValidCell(int row, int col) {
    return row >= 0 && row < board.length && col >= 0 && col < board.length;
  }

  GameState copyWith({List<List<CellState>>? board, Player? currentPlayer}) {
    return GameState(
      board:
          board ?? this.board.map((row) => List<CellState>.from(row)).toList(),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gameMode: gameMode,
      difficulty: difficulty,
      gameOver: gameOver,
      winner: winner,
      winningLine: winningLine,
      moveCount: moveCount,
      moveHistory: List<Map<String, dynamic>>.from(moveHistory),
    );
  }

  /// Tạo bản sao của GameState
  static GameState copy(GameState original) {
    return GameState(
      board: original.board.map((row) => List<CellState>.from(row)).toList(),
      currentPlayer: original.currentPlayer,
      gameMode: original.gameMode,
      difficulty: original.difficulty,
      gameOver: original.gameOver,
      winner: original.winner,
      winningLine: List<List<int>>.from(original.winningLine),
      moveCount: original.moveCount,
      moveHistory: List<Map<String, dynamic>>.from(original.moveHistory),
    );
  }
}
