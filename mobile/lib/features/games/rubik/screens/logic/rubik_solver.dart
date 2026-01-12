import 'dart:collection';
import '../models/rubik_cube.dart';

class SearchNode {
  final RubikCube cube;
  final List<MoveType> path;
  final int depth;
  int cost; // For A* algorithm

  SearchNode({
    required this.cube,
    required this.path,
    required this.depth,
    this.cost = 0,
  });

  SearchNode copy() {
    return SearchNode(
      cube: cube.copy(),
      path: List.from(path),
      depth: depth,
      cost: cost,
    );
  }
}

class RubikSolver {
  static const int maxDepth = 22; // Maximum depth for solutions up to 22 steps
  static const int maxNodesPerDepth = 100000; // Limit nodes per depth to prevent crash

  // Iterative Deepening Search
  static Future<List<MoveType>?> iterativeDeepening(
      RubikCube startCube,
      RubikCube goalCube,
      Function(String) onProgress,
      ) async {
    onProgress('Starting Iterative Deepening Search...');

    for (int depthLimit = 1; depthLimit <= maxDepth; depthLimit++) {
      onProgress('Searching at depth $depthLimit...');

      List<MoveType>? result = await depthLimitedSearch(
        startCube,
        goalCube,
        depthLimit,
        onProgress,
      );

      if (result != null) {
        onProgress('Solution found at depth $depthLimit!');
        return result;
      }
    }

    onProgress('No solution found within depth limit $maxDepth');
    return null;
  }

  // Depth Limited Search
  static Future<List<MoveType>?> depthLimitedSearch(
      RubikCube startCube,
      RubikCube goalCube,
      int depthLimit,
      Function(String) onProgress,
      ) async {
    Stack<SearchNode> stack = Stack<SearchNode>();
    Set<String> visited = <String>{};

    SearchNode startNode = SearchNode(
      cube: startCube,
      path: [],
      depth: 0,
    );

    stack.push(startNode);

    int nodesExplored = 0;

    while (stack.isNotEmpty) {
      SearchNode currentNode = stack.pop()!;
      nodesExplored++;

      if (nodesExplored % 1000 == 0) {
        onProgress('Explored $nodesExplored nodes at depth ${currentNode.depth}');
      }

      // Check if goal is reached
      if (currentNode.cube.equals(goalCube)) {
        onProgress('Goal reached! Explored $nodesExplored nodes');
        return currentNode.path;
      }

      // If depth limit not reached, expand children
      if (currentNode.depth < depthLimit) {
        List<SearchNode> children = _generateChildren(currentNode);

        for (SearchNode child in children) {
          String cubeString = _cubeToString(child.cube);
          if (!visited.contains(cubeString)) {
            visited.add(cubeString);
            stack.push(child);
          }
        }
      }

      // Prevent infinite loops by limiting nodes
      if (nodesExplored > maxNodesPerDepth) {
        onProgress('Search limit reached, trying next depth...');
        break;
      }
    }

    return null;
  }

  // A* Search Algorithm
  static Future<List<MoveType>?> aStarSearch(
      RubikCube startCube,
      RubikCube goalCube,
      Function(String) onProgress,
      ) async {
    onProgress('Starting A* Search...');

    PriorityQueue<SearchNode> openList = PriorityQueue<SearchNode>(
          (a, b) => a.cost.compareTo(b.cost),
    );
    Set<String> closedSet = <String>{};
    Map<String, int> openSet = <String, int>{};

    SearchNode startNode = SearchNode(
      cube: startCube,
      path: [],
      depth: 0,
      cost: startCube.heuristic(goalCube),
    );

    openList.add(startNode);
    openSet[_cubeToString(startCube)] = startNode.cost;

    int nodesExplored = 0;

    while (openList.isNotEmpty) {
      SearchNode currentNode = openList.removeFirst();
      String currentCubeString = _cubeToString(currentNode.cube);

      nodesExplored++;

      if (nodesExplored % 1000 == 0) {
        onProgress('A*: Explored $nodesExplored nodes, cost: ${currentNode.cost}');
      }

      // Check if goal is reached
      if (currentNode.cube.equals(goalCube)) {
        onProgress('A* Goal reached! Explored $nodesExplored nodes');
        return currentNode.path;
      }

      closedSet.add(currentCubeString);
      openSet.remove(currentCubeString);

      // Generate children
      List<SearchNode> children = _generateChildren(currentNode);

      for (SearchNode child in children) {
        String childCubeString = _cubeToString(child.cube);

        // Skip if already in closed set
        if (closedSet.contains(childCubeString)) {
          continue;
        }

        // Calculate cost: g(n) + h(n)
        int gCost = currentNode.depth + 1;
        int hCost = child.cube.heuristic(goalCube);
        int totalCost = gCost + hCost;

        child.cost = totalCost;

        // Check if this path is better than existing path to this state
        if (openSet.containsKey(childCubeString)) {
          if (totalCost >= openSet[childCubeString]!) {
            continue; // Skip this child
          }
        }

        openList.add(child);
        openSet[childCubeString] = totalCost;
      }

      // Prevent infinite loops
      if (nodesExplored > maxNodesPerDepth) {
        onProgress('A* Search limit reached');
        break;
      }
    }

    onProgress('A* No solution found');
    return null;
  }

  // Generate all possible child nodes from current node
  static List<SearchNode> _generateChildren(SearchNode parent) {
    List<SearchNode> children = [];

    for (MoveType move in MoveType.values) {
      RubikCube newCube = parent.cube.applyMove(move);
      List<MoveType> newPath = List.from(parent.path)..add(move);

      SearchNode child = SearchNode(
        cube: newCube,
        path: newPath,
        depth: parent.depth + 1,
      );

      children.add(child);
    }

    return children;
  }

  // Convert cube to string for hashing
  static String _cubeToString(RubikCube cube) {
    StringBuffer buffer = StringBuffer();
    for (int face = 0; face < 6; face++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          buffer.write(cube.cube[face][row][col]);
        }
      }
    }
    return buffer.toString();
  }

  // Get move name for display
  static String getMoveName(MoveType move) {
    switch (move) {
      case MoveType.leftClockwise:
        return 'Left Clockwise';
      case MoveType.leftAntiClockwise:
        return 'Left Anti-Clockwise';
      case MoveType.rightClockwise:
        return 'Right Clockwise';
      case MoveType.rightAntiClockwise:
        return 'Right Anti-Clockwise';
      case MoveType.upClockwise:
        return 'Up Clockwise';
      case MoveType.upAntiClockwise:
        return 'Up Anti-Clockwise';
      case MoveType.downClockwise:
        return 'Down Clockwise';
      case MoveType.downAntiClockwise:
        return 'Down Anti-Clockwise';
      case MoveType.frontClockwise:
        return 'Front Clockwise';
      case MoveType.frontAntiClockwise:
        return 'Front Anti-Clockwise';
      case MoveType.backClockwise:
        return 'Back Clockwise';
      case MoveType.backAntiClockwise:
        return 'Back Anti-Clockwise';
    }
  }

  // Get short move notation
  static String getMoveNotation(MoveType move) {
    switch (move) {
      case MoveType.leftClockwise:
        return 'L';
      case MoveType.leftAntiClockwise:
        return "L'";
      case MoveType.rightClockwise:
        return 'R';
      case MoveType.rightAntiClockwise:
        return "R'";
      case MoveType.upClockwise:
        return 'U';
      case MoveType.upAntiClockwise:
        return "U'";
      case MoveType.downClockwise:
        return 'D';
      case MoveType.downAntiClockwise:
        return "D'";
      case MoveType.frontClockwise:
        return 'F';
      case MoveType.frontAntiClockwise:
        return "F'";
      case MoveType.backClockwise:
        return 'B';
      case MoveType.backAntiClockwise:
        return "B'";
    }
  }
}

// Custom Stack implementation
class Stack<T> {
  final List<T> _items = [];

  void push(T item) {
    _items.add(item);
  }

  T? pop() {
    if (_items.isEmpty) return null;
    return _items.removeLast();
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}

// Custom Priority Queue implementation
class PriorityQueue<T> {
  final List<T> _items = [];
  final int Function(T, T) _compare;

  PriorityQueue(this._compare);

  void add(T item) {
    _items.add(item);
    _items.sort(_compare);
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}
