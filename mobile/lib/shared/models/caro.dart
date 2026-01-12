// Caro (Gomoku) Models
// Models for Caro game state and responses

class CaroGame {
  final int? gameId;
  final List<List<int>> board;
  final int boardSize;
  final int winLength;
  final String currentPlayer; // 'X' or 'O'
  final String mode; // 'pvp' or 'ai'
  final String status; // 'playing', 'won', 'draw'
  final String? winner;
  final List<CaroPosition>? winningLine;
  final String? message;

  CaroGame({
    this.gameId,
    required this.board,
    this.boardSize = 15,
    this.winLength = 5,
    this.currentPlayer = 'X',
    this.mode = 'pvp',
    this.status = 'playing',
    this.winner,
    this.winningLine,
    this.message,
  });

  CaroGame copyWith({
    int? gameId,
    List<List<int>>? board,
    int? boardSize,
    int? winLength,
    String? currentPlayer,
    String? mode,
    String? status,
    String? winner,
    List<CaroPosition>? winningLine,
    String? message,
  }) {
    return CaroGame(
      gameId: gameId ?? this.gameId,
      board: board ?? this.board,
      boardSize: boardSize ?? this.boardSize,
      winLength: winLength ?? this.winLength,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      winningLine: winningLine ?? this.winningLine,
      message: message ?? this.message,
    );
  }

  factory CaroGame.fromJson(Map<String, dynamic> json) {
    List<List<int>> board = (json['board'] as List)
        .map((row) => (row as List).map((cell) => cell as int).toList())
        .toList();

    List<CaroPosition>? winningLine;
    if (json['winning_line'] != null) {
      winningLine = (json['winning_line'] as List)
          .map((pos) => CaroPosition.fromJson(pos as Map<String, dynamic>))
          .toList();
    }

    return CaroGame(
      gameId: json['game_id'] as int?,
      board: board,
      boardSize: json['board_size'] as int? ?? board.length,
      winLength: json['win_length'] as int? ?? 5,
      currentPlayer: json['current_player'] as String? ?? 'X',
      mode: json['mode'] as String? ?? 'pvp',
      status: json['status'] as String? ?? 'playing',
      winner: json['winner'] as String?,
      winningLine: winningLine,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'board': board,
      'board_size': boardSize,
      'win_length': winLength,
      'current_player': currentPlayer,
      'mode': mode,
      'status': status,
      'winner': winner,
      'winning_line': winningLine?.map((pos) => pos.toJson()).toList(),
      'message': message,
    };
  }

  bool isEmpty(int row, int col) {
    return board[row][col] == 0;
  }

  bool isValidMove(int row, int col) {
    return row >= 0 &&
        row < boardSize &&
        col >= 0 &&
        col < boardSize &&
        isEmpty(row, col);
  }
}

class CaroPosition {
  final int row;
  final int col;

  CaroPosition({required this.row, required this.col});

  factory CaroPosition.fromJson(Map<String, dynamic> json) {
    return CaroPosition(row: json['row'] as int, col: json['col'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'row': row, 'col': col};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaroPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class CaroMoveRequest {
  final int? gameId;
  final List<List<int>> board;
  final int row;
  final int col;
  final String player;

  CaroMoveRequest({
    this.gameId,
    required this.board,
    required this.row,
    required this.col,
    required this.player,
  });

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'board': board,
      'row': row,
      'col': col,
      'player': player,
    };
  }
}
