import 'package:flutter/material.dart';
import 'gomoku_game.dart';
import 'board.dart';
import 'player.dart' as gomoku_player;
import 'node.dart' as gomoku_node;
import '../utils/game_state.dart';

/// Adapter để tích hợp AI Gomoku vào game Caro hiện tại
class CaroAIAdapter {
  late GomokuGame _gomokuGame;
  
  CaroAIAdapter() {
    _gomokuGame = GomokuGame();
  }

  /// Chuyển đổi từ GameState sang Board state của Gomoku
  void _syncGameStateToGomoku(GameState gameState) {
    // Reset board
    _gomokuGame.board = Board();
    
    // Copy trạng thái từ GameState sang Gomoku Board
    for (int row = 0; row < gameState.board.length && row < Board.MAX_ROW; row++) {
      for (int col = 0; col < gameState.board[row].length && col < Board.MAX_COL; col++) {
        if (gameState.board[row][col] != CellState.empty) {
          // Chuyển đổi CellState sang Player enum
          gomoku_player.Player player = gameState.board[row][col] == CellState.x 
              ? gomoku_player.Player.X 
              : gomoku_player.Player.O;
          
          _gomokuGame.board.state[row][col] = player.value;
          _gomokuGame.board.numOfCelled++;
        }
      }
    }
    
    // Set current player
    _gomokuGame.currentPlayer = gameState.currentPlayer == Player.x 
        ? gomoku_player.Player.X 
        : gomoku_player.Player.O;
  }

  /// Lấy nước đi tốt nhất từ AI
  List<int> getBestMove(GameState gameState) {
    return getBestMoveForPlayer(gameState, gameState.currentPlayer);
  }

  /// Lấy nước đi tốt nhất từ AI cho player cụ thể
  List<int> getBestMoveForPlayer(GameState gameState, Player player) {
    try {
      // Sync game state
      _syncGameStateToGomoku(gameState);
      
      // Update AI's current node with current board state
      _gomokuGame.search!.currentNode = gomoku_node.Node();
      _gomokuGame.search!.currentNode!.state = List.generate(
        Board.MAX_ROW, 
        (i) => List.generate(Board.MAX_COL, (j) => _gomokuGame.board.state[i][j])
      );
      
      // Set current player for AI based on the actual player
      _gomokuGame.currentPlayer = player == Player.x 
          ? gomoku_player.Player.X 
          : gomoku_player.Player.O;
      
      // Get best move from AI
      List<int> bestMove = _gomokuGame.search!.getTile();
      
      // Ensure move is within bounds and cell is empty
      if (bestMove[0] >= 0 && bestMove[0] < gameState.board.length &&
          bestMove[1] >= 0 && bestMove[1] < gameState.board[0].length &&
          gameState.board[bestMove[0]][bestMove[1]] == CellState.empty) {
        return bestMove;
      }
      
      // Fallback: find first empty cell
      for (int row = 0; row < gameState.board.length; row++) {
        for (int col = 0; col < gameState.board[row].length; col++) {
          if (gameState.board[row][col] == CellState.empty) {
            return [row, col];
          }
        }
      }
      
      return [-1, -1]; // No valid move
    } catch (e) {
      debugPrint('AI Error: $e');
      // Fallback: random move
      return _getRandomMove(gameState);
    }
  }

  /// Lấy gợi ý từ AI
  List<int> getHint(GameState gameState) {
    return getBestMove(gameState);
  }

  /// Kiểm tra xem AI có thể thắng trong lượt tiếp theo không
  bool canWinNext(GameState gameState) {
    try {
      _syncGameStateToGomoku(gameState);
      // Kiểm tra tất cả các ô trống để xem có thể thắng không
      for (int row = 0; row < gameState.board.length; row++) {
        for (int col = 0; col < gameState.board[row].length; col++) {
          if (gameState.board[row][col] == CellState.empty) {
            // Tạo game state tạm thời để kiểm tra
            GameState tempState = GameState.copy(gameState);
            if (tempState.makeMove(row, col, gameState.currentPlayer)) {
              if (tempState.gameOver && tempState.winner == gameState.currentPlayer) {
                return true;
              }
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('canWinNext Error: $e');
      return false;
    }
  }

  /// Lấy nước đi phòng thủ tốt nhất
  List<int> getDefensiveMove(GameState gameState) {
    try {
      _syncGameStateToGomoku(gameState);
      
      // Tìm nước đi để chặn đối thủ thắng
      Player opponent = gameState.currentPlayer == Player.x ? Player.o : Player.x;
      
      for (int row = 0; row < gameState.board.length; row++) {
        for (int col = 0; col < gameState.board[row].length; col++) {
          if (gameState.board[row][col] == CellState.empty) {
            // Tạo game state tạm thời để kiểm tra
            GameState tempState = GameState.copy(gameState);
            if (tempState.makeMove(row, col, opponent)) {
              if (tempState.gameOver && tempState.winner == opponent) {
                // Đây là nước đi cần chặn
                return [row, col];
              }
            }
          }
        }
      }
      
      // Nếu không có nước đi cần chặn, trả về nước đi tốt nhất
      return getBestMove(gameState);
    } catch (e) {
      debugPrint('getDefensiveMove Error: $e');
      return getBestMove(gameState);
    }
  }

  /// Fallback: random move
  List<int> _getRandomMove(GameState gameState) {
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

}
