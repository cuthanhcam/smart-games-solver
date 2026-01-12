import 'node.dart';
import 'player.dart';

abstract class BaseSearching {
  Node? currentNode;
  static const int MAX_DEPTH = 2;

  int getHeuristic(Node node, Player player);
  List<Node> getSuccessors(Node nodeGet, Player player);

  static bool checkRepeats(Node n) {
    bool checkRepeats = false;
    Node checkNode = n;
    while (n.parent != null && !checkRepeats) {
      if (n.parent == checkNode) {
        checkRepeats = true;
      }
      n = n.parent!;
    }
    return checkRepeats;
  }
}
