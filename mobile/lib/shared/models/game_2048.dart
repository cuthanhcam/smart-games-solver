// Game 2048 Models
// Models for 2048 game state and responses

class Game2048State {
  final int? gameId;
  final List<List<int>> grid;
  final int score;
  final bool gameOver;
  final bool won;
  final bool canMove;
  final int moves;
  final String? message;

  Game2048State({
    this.gameId,
    required this.grid,
    required this.score,
    this.gameOver = false,
    this.won = false,
    this.canMove = true,
    this.moves = 0,
    this.message,
  });

  Game2048State copyWith({
    int? gameId,
    List<List<int>>? grid,
    int? score,
    bool? gameOver,
    bool? won,
    bool? canMove,
    int? moves,
    String? message,
  }) {
    return Game2048State(
      gameId: gameId ?? this.gameId,
      grid: grid ?? this.grid,
      score: score ?? this.score,
      gameOver: gameOver ?? this.gameOver,
      won: won ?? this.won,
      canMove: canMove ?? this.canMove,
      moves: moves ?? this.moves,
      message: message ?? this.message,
    );
  }

  factory Game2048State.fromJson(Map<String, dynamic> json) {
    return Game2048State(
      gameId: json['game_id'] as int?,
      grid: (json['grid'] as List)
          .map((row) => (row as List).map((cell) => cell as int).toList())
          .toList(),
      score: json['score'] as int,
      gameOver: json['game_over'] as bool? ?? false,
      won: json['won'] as bool? ?? false,
      canMove: json['can_move'] as bool? ?? true,
      moves: json['moves'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'grid': grid,
      'score': score,
      'game_over': gameOver,
      'won': won,
      'can_move': canMove,
      'moves': moves,
      'message': message,
    };
  }
}

class Game2048MoveRequest {
  final int? gameId;
  final List<List<int>> grid;
  final int score;
  final String direction;

  Game2048MoveRequest({
    this.gameId,
    required this.grid,
    required this.score,
    required this.direction,
  });

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'grid': grid,
      'score': score,
      'direction': direction,
    };
  }
}
