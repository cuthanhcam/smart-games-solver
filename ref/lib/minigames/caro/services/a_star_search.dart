import 'base_searching.dart';
import 'board.dart';
import 'node.dart';
import 'player.dart';

class AStarSearch extends BaseSearching {
  static const List<int> DEFEND_SCORE_ARRAY = [
    0, 3, 36, 324, 2916, 26244, 236196, 2125764, 19131876
  ];

  static const List<int> ATTACK_SCORE_ARRAY = [
    0, 9, 63, 441, 3087, 21609, 151263, 1058841, 7441887
  ];

  AStarSearch(Node node) {
    currentNode = node;
  }

  @override
  List<Node> getSuccessors(Node nodeGet, Player player) {
    List<Node> output = [];
    for (int i = 0; i < Board.MAX_ROW; i++) {
      for (int j = 0; j < Board.MAX_COL; j++) {
        if (nodeGet.state[i][j] != -1) continue;
        
        Node newNode = Node.fromParent(nodeGet, selectCell(nodeGet, i, j, player));
        newNode.h = getHeuristic(newNode, player);
        output.add(newNode);
      }
    }
    return output;
  }

  Node selectCell(Node nodeGet, int x, int y, Player player) {
    Node output = Node.copy(nodeGet);
    output.state[x][y] = player.value;
    return output;
  }

  List<int> getTile() {
    int score = 0;
    int noLineAbleWins = 0;
    List<int> tile = [0, 0];

    for (int i = 0; i < Board.MAX_COL; i++) {
      for (int j = 0; j < Board.MAX_ROW; j++) {
        int attackScore = 0;
        int defendScore = 0;

        if (attackScoreHorizontal(i, j) != 0) {
          noLineAbleWins++;
          attackScore += attackScoreHorizontal(i, j);
        }
        if (attackScoreVertical(i, j) != 0) {
          noLineAbleWins++;
          attackScore += attackScoreVertical(i, j);
        }
        if (attackScorePrimaryDiagonal(i, j) != 0) {
          noLineAbleWins++;
          attackScore += attackScorePrimaryDiagonal(i, j);
        }
        if (attackScoreSecondaryDiagonal(i, j) != 0) {
          noLineAbleWins++;
          attackScore += attackScoreSecondaryDiagonal(i, j);
        }

        defendScore += defendScoreHorizontal(i, j);
        defendScore += defendScoreVertical(i, j);
        defendScore += defendScorePrimaryDiagonal(i, j);
        defendScore += defendScoreSecondaryDiagonal(i, j);

        if (defendScore <= attackScore) {
          if (score <= attackScore && currentNode!.state[i][j] == -1) {
            if (attackScore < ATTACK_SCORE_ARRAY[noLineAbleWins]) {
              attackScore = ATTACK_SCORE_ARRAY[noLineAbleWins];
            }
            if (score < attackScore) {
              score = attackScore;
              tile[0] = i;
              tile[1] = j;
            }
          }
        } else {
          if (score <= defendScore && currentNode!.state[i][j] == -1) {
            if (score < defendScore) {
              score = defendScore;
              tile[0] = i;
              tile[1] = j;
            }
          }
        }
        noLineAbleWins = 0;
      }
    }

    return tile;
  }

  @override
  int getHeuristic(Node node, Player player) {
    return 0; // Simplified for this implementation
  }

  // Attack scoring methods
  int attackScoreHorizontal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreAttack = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && col + count < Board.MAX_COL - 1; count++) {
      int x = currentNode!.state[row][col + count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && col - count > -1; count++) {
      int x = currentNode!.state[row][col - count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    if (iSoQuanDich == 2) return 0; // bi chan 2 dau
    iScoreAttack += ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreAttack -= ATTACK_SCORE_ARRAY[iSoQuanDich];
    iScoreTemp += iScoreAttack;

    return iScoreTemp;
  }

  int attackScoreVertical(int row, int col) {
    int iScoreTemp = 0;
    int iScoreAttack = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && row + count < Board.MAX_ROW - 1; count++) {
      int x = currentNode!.state[row + count][col];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row - count > 0; count++) {
      int x = currentNode!.state[row - count][col];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    if (iSoQuanDich == 2) return 0; // bi chan 2 dau
    iScoreAttack += ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreAttack -= ATTACK_SCORE_ARRAY[iSoQuanDich];
    iScoreTemp += iScoreAttack;

    return iScoreTemp;
  }

  int attackScorePrimaryDiagonal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreAttack = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && row + count < Board.MAX_ROW - 1 && col + count < Board.MAX_COL - 1; count++) {
      int x = currentNode!.state[row + count][col + count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row - count > 0 && col - count > -1; count++) {
      int x = currentNode!.state[row - count][col - count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    if (iSoQuanDich == 2) return 0; // bi chan 2 dau
    iScoreAttack += ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreAttack -= ATTACK_SCORE_ARRAY[iSoQuanDich];
    iScoreTemp += iScoreAttack;

    return iScoreTemp;
  }

  int attackScoreSecondaryDiagonal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreAttack = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && col + count < Board.MAX_COL && row - count > -1; count++) {
      int x = currentNode!.state[row - count][col + count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row + count > 0 && row + count < Board.MAX_ROW && col - count > -1; count++) {
      int x = currentNode!.state[row + count][col - count];
      if (x == Player.O.value) iSoQuanTa++;
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
        break;
      }
      if (x == -1) break;
    }

    if (iSoQuanDich == 2) return 0; // bi chan 2 dau
    iScoreAttack += ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreAttack -= ATTACK_SCORE_ARRAY[iSoQuanDich];
    iScoreTemp += iScoreAttack;

    return iScoreTemp;
  }

  // Defend scoring methods
  int defendScoreHorizontal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreDefend = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && col + count < Board.MAX_COL - 1; count++) {
      int x = currentNode!.state[row][col + count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && col - count > -1; count++) {
      int x = currentNode!.state[row][col - count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    if (iSoQuanTa == 2) return 0;
    if (iSoQuanDich >= 0) // bi chan 2 dau
      iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa] * 2;
    iScoreDefend += DEFEND_SCORE_ARRAY[iSoQuanDich];
    iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreTemp += iScoreDefend;

    return iScoreTemp;
  }

  int defendScoreVertical(int row, int col) {
    int iScoreTemp = 0;
    int iScoreDefend = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && row + count < Board.MAX_ROW; count++) {
      int x = currentNode!.state[row + count][col];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row - count > -1; count++) {
      int x = currentNode!.state[row - count][col];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    if (iSoQuanTa == 2) return 0;
    if (iSoQuanDich >= 0) // bi chan 2 dau
      iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa] * 2;
    iScoreDefend += DEFEND_SCORE_ARRAY[iSoQuanDich];
    iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreTemp += iScoreDefend;

    return iScoreTemp;
  }

  int defendScorePrimaryDiagonal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreDefend = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && row + count < Board.MAX_ROW && col + count < Board.MAX_COL; count++) {
      int x = currentNode!.state[row + count][col + count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row - count > 0 && col - count > -1; count++) {
      int x = currentNode!.state[row - count][col - count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    if (iSoQuanTa == 2) return 0;
    if (iSoQuanDich >= 0) // bi chan 2 dau
      iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa] * 2;
    iScoreDefend += DEFEND_SCORE_ARRAY[iSoQuanDich];
    iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreTemp += iScoreDefend;

    return iScoreTemp;
  }

  int defendScoreSecondaryDiagonal(int row, int col) {
    int iScoreTemp = 0;
    int iScoreDefend = 0;
    int iSoQuanTa = 0;
    int iSoQuanDich = 0;

    for (int count = 1; count < 6 && col + count < Board.MAX_COL && row - count > -1 && col + count < Board.MAX_COL - 1; count++) {
      int x = currentNode!.state[row - count][col + count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    for (int count = 1; count < 6 && row + count < Board.MAX_ROW && col - count > -1; count++) {
      int x = currentNode!.state[row + count][col - count];
      if (x == Player.O.value) {
        iSoQuanTa++;
        break;
      }
      if (x != Player.O.value && x != -1) {
        iSoQuanDich++;
        iScoreTemp -= 9;
      }
      if (x == -1) break;
    }

    if (iSoQuanTa == 2) return 0;
    if (iSoQuanDich >= 0) // bi chan 2 dau
      iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa] * 2;
    iScoreDefend += DEFEND_SCORE_ARRAY[iSoQuanDich];
    iScoreDefend -= ATTACK_SCORE_ARRAY[iSoQuanTa];
    iScoreTemp += iScoreDefend;

    return iScoreTemp;
  }
}
