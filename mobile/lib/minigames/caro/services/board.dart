import 'player.dart';

class Board {
  static const int MAX_COL = 35;
  static const int MAX_ROW = 35;
  static const int MAX_SCORE = 5;
  
  late List<List<int>> state;
  Player? winner;
  int numOfCelled = 1;

  Board() {
    state = List.generate(MAX_ROW, (i) => List.generate(MAX_COL, (j) => -1));
  }

  bool move(int r, int c, Player player) {
    if (state[r][c] != -1) return false;
    
    state[r][c] = player.value;
    
    if (isWinner(player, r, c)) {
      winner = player;
    }
    
    return true;
  }

  bool isWinner(Player player, int r, int c) {
    return checkHorizontal(player, r) ||
           checkVertical(player, c) ||
           checkPrimaryDiagonal(player, r, c) ||
           checkSecondaryDiagonal(player, r, c);
  }

  bool checkHorizontal(Player player, int r) {
    int count = 0;
    bool onlyDetained = false;
    bool bothDetained = false;

    for (int col = 0; col < MAX_COL; col++) {
      if (state[r][col] != player.value && state[r][col] != -1) {
        if (count < MAX_SCORE) {
          onlyDetained = true;
          count = 0;
        }
        if (count >= MAX_SCORE && onlyDetained) {
          bothDetained = true;
          count = 0;
        }
      } else if (state[r][col] == -1) {
        if (count == MAX_SCORE && !bothDetained) return true;
        onlyDetained = false;
        bothDetained = false;
        count = 0;
      }
      if (state[r][col] == player.value) {
        count++;
      }
    }
    
    return count == MAX_SCORE && !bothDetained;
  }

  bool checkVertical(Player player, int c) {
    int count = 0;
    bool onlyDetained = false;
    bool bothDetained = false;

    for (int row = 0; row < MAX_ROW; row++) {
      if (state[row][c] != player.value && state[row][c] != -1) {
        if (count < MAX_SCORE) {
          onlyDetained = true;
          count = 0;
        }
        if (count >= MAX_SCORE && onlyDetained) {
          bothDetained = true;
          count = 0;
        }
      } else if (state[row][c] == -1) {
        if (count == MAX_SCORE && !bothDetained) return true;
        onlyDetained = false;
        bothDetained = false;
        count = 0;
      }
      if (state[row][c] == player.value) {
        count++;
      }
    }
    
    return count == MAX_SCORE && !bothDetained;
  }

  bool checkPrimaryDiagonal(Player player, int r, int c) {
    int count = 0;
    bool onlyDetained = false;
    bool bothDetained = false;
    
    int row = r > c ? r - c : 0;
    int col = c > r ? c - r : 0;

    while (row < MAX_ROW && col < MAX_COL) {
      if (state[row][col] != player.value && state[row][col] != -1) {
        if (count < MAX_SCORE) {
          onlyDetained = true;
          count = 0;
        }
        if (count >= MAX_SCORE && onlyDetained) {
          bothDetained = true;
          count = 0;
        }
      } else if (state[row][col] == -1) {
        if (count == MAX_SCORE && !bothDetained) return true;
        onlyDetained = false;
        bothDetained = false;
        count = 0;
      }
      if (state[row][col] == player.value) {
        count++;
      }
      row++;
      col++;
    }
    
    return count == MAX_SCORE && !bothDetained;
  }

  bool checkSecondaryDiagonal(Player player, int r, int c) {
    int count = 0;
    bool onlyDetained = false;
    bool bothDetained = false;
    
    int row, col;
    if (c + r < MAX_COL) {
      col = 0;
      row = r + c;
    } else {
      row = MAX_ROW - 1;
      col = c - (MAX_ROW - 1 - r);
    }

    while (row > 0 && col < MAX_COL) {
      if (state[row][col] != player.value && state[row][col] != -1) {
        if (count < MAX_SCORE) {
          onlyDetained = true;
          count = 0;
        }
        if (count >= MAX_SCORE && onlyDetained) {
          bothDetained = true;
          count = 0;
        }
      } else if (state[row][col] == -1) {
        if (count == MAX_SCORE && !bothDetained) return true;
        onlyDetained = false;
        bothDetained = false;
        count = 0;
      }
      if (state[row][col] == player.value) {
        count++;
      }
      row--;
      col++;
    }
    
    return count == MAX_SCORE && !bothDetained;
  }
}
