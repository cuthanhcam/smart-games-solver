import 'board.dart';
import 'player.dart';

class Node {
  late List<List<int>> state;
  late int h;
  Node? parent;

  Node() {
    state = List.generate(Board.MAX_ROW, (i) => 
        List.generate(Board.MAX_COL, (j) => -1));
    h = 0;
  }

  Node.fromParent(Node parentNode, Node newNode) {
    parent = parentNode;
    state = List.generate(Board.MAX_ROW, (i) => 
        List.generate(Board.MAX_COL, (j) => newNode.state[i][j]));
    h = newNode.h;
  }

  Node.copy(Node node) {
    state = List.generate(Board.MAX_ROW, (i) => 
        List.generate(Board.MAX_COL, (j) => node.state[i][j]));
    h = node.h;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Node) return false;
    Node node = other;
    for (int i = 0; i < Board.MAX_ROW; i++) {
      for (int j = 0; j < Board.MAX_COL; j++) {
        if (state[i][j] != node.state[i][j]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    int result = 0;
    for (int i = 0; i < Board.MAX_ROW; i++) {
      for (int j = 0; j < Board.MAX_COL; j++) {
        result = result * 31 + state[i][j];
      }
    }
    return result;
  }

  @override
  String toString() {
    StringBuffer output = StringBuffer();
    output.writeln(h);
    for (int i = 0; i < Board.MAX_ROW; i++) {
      for (int j = 0; j < Board.MAX_COL; j++) {
        output.write(state[i][j]);
      }
      output.writeln();
    }
    return output.toString();
  }
}
