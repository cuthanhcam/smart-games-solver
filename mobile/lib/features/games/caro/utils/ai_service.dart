import 'game_state.dart';
import '../services/caro_ai_adapter.dart';
import 'dart:math';

class AIService {
  static final CaroAIAdapter _aiAdapter = CaroAIAdapter();

  /// Lấy nước đi tốt nhất từ AI
  static List<int> getBestMove(GameState gameState) {
    try {
      // Kiểm tra nếu AI có thể thắng ngay
      List<int> winningMove = _aiAdapter.getBestMove(gameState);
      if (winningMove[0] != -1 && winningMove[1] != -1) {
        return winningMove;
      }

      // Kiểm tra nếu cần phòng thủ (chặn đối thủ thắng)
      List<int> defensiveMove = _aiAdapter.getDefensiveMove(gameState);
      if (defensiveMove[0] != -1 && defensiveMove[1] != -1) {
        return defensiveMove;
      }

      // Sử dụng AI để tìm nước đi tốt nhất
      return _aiAdapter.getBestMove(gameState);
    } catch (e) {
      // Fallback: random move
      return _getRandomMove(gameState);
    }
  }

  /// Lấy nước đi tốt nhất với độ khó
  static List<int> getBestMoveWithDifficulty(
    GameState gameState,
    Difficulty difficulty,
  ) {
    return getBestMoveWithDifficultyForPlayer(
      gameState,
      difficulty,
      gameState.currentPlayer,
    );
  }

  /// Lấy nước đi tốt nhất với độ khó cho player cụ thể (hỗ trợ AI vs AI)
  static List<int> getBestMoveWithDifficultyForPlayer(
    GameState gameState,
    Difficulty difficulty,
    Player player,
  ) {
    try {
      // Nếu là lượt đầu tiên của AI
      if (gameState.moveCount == 1) {
        // Trong AI vs AI mode, bắt đầu từ giữa bảng
        if (gameState.gameMode == GameMode.evE) {
          return _getCenterMove(gameState);
        }
        // Trong PvE mode, đánh gần vị trí người chơi đã đánh
        return _getNearbyMove(gameState);
      }

      List<int> move;

      // Tạo chiến lược khác nhau cho AI vs AI
      if (gameState.gameMode == GameMode.evE) {
        // AI vs AI mode - sử dụng Expert AI
        print('AI vs AI mode - using Expert AI');
        if (player == Player.x) {
          move = _getAggressiveMove(gameState, Difficulty.expert);
        } else {
          move = _getDefensiveMove(gameState, Difficulty.expert);
        }
      } else {
        // PvE mode - AI chơi với người
        switch (difficulty) {
          case Difficulty.easy:
            // 30% random, 70% best move (vẫn có thể thắng/chặn)
            if (Random().nextDouble() < 0.3) {
              move = _getRandomMove(gameState);
            } else {
              move = _aiAdapter.getBestMove(gameState);
            }
            break;
          case Difficulty.normal:
            // Prioritize winning, then defending, then best move
            if (_aiAdapter.canWinNext(gameState)) {
              move = _aiAdapter.getBestMove(gameState); // AI's winning move
            } else {
              List<int> defensiveMove = _aiAdapter.getDefensiveMove(gameState);
              if (defensiveMove[0] != -1) {
                move = defensiveMove;
              } else {
                move = _aiAdapter.getBestMove(
                  gameState,
                ); // Always use best move
              }
            }
            break;
          case Difficulty.hard:
            // Prioritize winning, then defending, then best move (more aggressive)
            if (_aiAdapter.canWinNext(gameState)) {
              move = _aiAdapter.getBestMove(gameState);
            } else {
              List<int> defensiveMove = _aiAdapter.getDefensiveMove(gameState);
              if (defensiveMove[0] != -1) {
                move = defensiveMove;
              } else {
                move = _aiAdapter.getBestMove(
                  gameState,
                ); // Always use best move
              }
            }
            break;
          case Difficulty.expert:
            // Always best move
            move = _aiAdapter.getBestMove(gameState);
            break;
        }
      }

      // Validate move before returning
      if (move[0] >= 0 &&
          move[0] < gameState.board.length &&
          move[1] >= 0 &&
          move[1] < gameState.board[0].length &&
          gameState.board[move[0]][move[1]] == CellState.empty) {
        return move;
      } else {
        // Fallback to random move if AI returned invalid move
        return _getRandomMove(gameState);
      }
    } catch (e) {
      print('AI Error: $e');
      return _getRandomMove(gameState);
    }
  }

  /// Lấy gợi ý từ AI
  static List<int> getHint(GameState gameState) {
    return _aiAdapter.getHint(gameState);
  }

  /// Chiến lược tấn công mạnh cho AI X trong AI vs AI
  static List<int> _getAggressiveMove(
    GameState gameState,
    Difficulty difficulty,
  ) {
    try {
      print('AI X (Aggressive) - Finding move...');

      // Sử dụng Gomoku Expert AI cho AI X (tấn công)
      print('AI X - Using Gomoku Expert AI (Aggressive)');
      return _aiAdapter.getBestMoveForPlayer(gameState, Player.x);
    } catch (e) {
      print('AI X Error: $e');
      return _getRandomMove(gameState);
    }
  }

  /// Chiến lược phòng thủ và phản công cho AI O trong AI vs AI
  static List<int> _getDefensiveMove(
    GameState gameState,
    Difficulty difficulty,
  ) {
    try {
      print('AI O (Defensive) - Finding move...');

      // Sử dụng Gomoku Expert AI cho AI O (phòng thủ)
      print('AI O - Using Gomoku Expert AI (Defensive)');
      return _aiAdapter.getBestMoveForPlayer(gameState, Player.o);
    } catch (e) {
      print('AI O Error: $e');
      return _getRandomMove(gameState);
    }
  }

  /// Fallback: random move
  static List<int> _getRandomMove(GameState gameState) {
    List<List<int>> emptyCells = [];

    for (int row = 0; row < gameState.board.length; row++) {
      for (int col = 0; col < gameState.board[row].length; col++) {
        if (gameState.board[row][col] == CellState.empty) {
          emptyCells.add([row, col]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      emptyCells.shuffle();
      return emptyCells.first;
    }

    return [-1, -1];
  }

  /// Lấy nước đi ở giữa bảng (cho AI vs AI)
  static List<int> _getCenterMove(GameState gameState) {
    int centerRow = gameState.board.length ~/ 2;
    int centerCol = gameState.board[0].length ~/ 2;

    // Kiểm tra nếu ô giữa trống
    if (gameState.board[centerRow][centerCol] == CellState.empty) {
      print('AI starting from center: [$centerRow, $centerCol]');
      return [centerRow, centerCol];
    }

    // Nếu ô giữa đã có quân, tìm ô gần nhất
    for (int radius = 1; radius <= 3; radius++) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          int row = centerRow + dr;
          int col = centerCol + dc;

          if (row >= 0 &&
              row < gameState.board.length &&
              col >= 0 &&
              col < gameState.board[0].length &&
              gameState.board[row][col] == CellState.empty) {
            print('AI starting near center: [$row, $col]');
            return [row, col];
          }
        }
      }
    }

    // Fallback: random move
    return _getRandomMove(gameState);
  }

  /// Lấy nước đi gần vị trí người chơi đã đánh
  static List<int> _getNearbyMove(GameState gameState) {
    // Tìm vị trí người chơi đã đánh (X)
    List<int> playerPosition = [-1, -1];
    for (int row = 0; row < gameState.board.length; row++) {
      for (int col = 0; col < gameState.board[row].length; col++) {
        if (gameState.board[row][col] == CellState.x) {
          playerPosition = [row, col];
          break;
        }
      }
      if (playerPosition[0] != -1) break;
    }

    // Nếu không tìm thấy vị trí người chơi, đánh random
    if (playerPosition[0] == -1) {
      return _getRandomMove(gameState);
    }

    // Tìm các vị trí gần vị trí người chơi
    List<List<int>> nearbyMoves = [];
    int playerRow = playerPosition[0];
    int playerCol = playerPosition[1];

    // Kiểm tra các vị trí xung quanh (trong phạm vi 2 ô)
    for (int row = playerRow - 2; row <= playerRow + 2; row++) {
      for (int col = playerCol - 2; col <= playerCol + 2; col++) {
        if (row >= 0 &&
            row < gameState.board.length &&
            col >= 0 &&
            col < gameState.board[row].length &&
            gameState.board[row][col] == CellState.empty) {
          nearbyMoves.add([row, col]);
        }
      }
    }

    // Nếu có vị trí gần, chọn ngẫu nhiên một vị trí
    if (nearbyMoves.isNotEmpty) {
      nearbyMoves.shuffle();
      return nearbyMoves.first;
    }

    // Fallback: đánh random
    return _getRandomMove(gameState);
  }
}
