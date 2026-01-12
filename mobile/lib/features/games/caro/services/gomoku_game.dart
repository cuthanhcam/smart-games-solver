import 'board.dart';
import 'node.dart';
import 'player.dart';
import 'a_star_search.dart';

class GomokuGame {
  Player currentPlayer = Player.O;
  Board board = Board();
  AStarSearch? search;
  String? messenger;

  GomokuGame() {
    search = AStarSearch(Node());
  }

  bool doClick(int r, int c) {
    if (board.winner != null) return false;
    
    if (board.numOfCelled == Board.MAX_COL * Board.MAX_ROW) {
      messenger = "Hết cờ đánh";
      return false;
    }

    List<int> tile = [0, 0];
    if (selectMove(r, c)) {
      swapPlayer();
      tile[0] = r;
      tile[1] = c;
    }

    // AI move
    if (currentPlayer == Player.O && board.winner == null) {
      search!.currentNode = Node();
      search!.currentNode!.state = List.generate(Board.MAX_ROW, (i) => 
          List.generate(Board.MAX_COL, (j) => board.state[i][j]));
      
      tile = search!.getTile();
      selectMove(tile[0], tile[1]);
      swapPlayer();
    }

    return true;
  }

  void newGame() {
    board = Board();
    List<List<int>> state = List.generate(Board.MAX_ROW, (i) => 
        List.generate(Board.MAX_COL, (j) => -1));
    
    state[6][6] = Player.O.value; // AI starts first
    currentPlayer = Player.O;
    swapPlayer(); // Switch to human player
    board.state = state;
  }

  bool selectMove(int r, int c) {
    return board.move(r, c, currentPlayer);
  }

  void swapPlayer() {
    board.numOfCelled++;
    currentPlayer = currentPlayer == Player.O ? Player.X : Player.O;
  }

  Player? getWinner() {
    return board.winner;
  }

  String? getMessenger() {
    return messenger;
  }
}
