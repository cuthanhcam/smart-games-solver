import 'dart:math';

enum MoveType {
  leftClockwise,
  leftAntiClockwise,
  rightClockwise,
  rightAntiClockwise,
  upClockwise,
  upAntiClockwise,
  downClockwise,
  downAntiClockwise,
  frontClockwise,
  frontAntiClockwise,
  backClockwise,
  backAntiClockwise,
}

class RubikCube {
  // 6 faces, each face has 3x3 squares
  // Face indices: 0=front, 1=back, 2=top, 3=bottom, 4=left, 5=right
  List<List<List<int>>> cube;
  
  RubikCube() : cube = List.generate(6, (_) => List.generate(3, (_) => List.generate(3, (_) => 0))) {
    // Initialize solved cube
    for (int face = 0; face < 6; face++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          cube[face][row][col] = face;
        }
      }
    }
  }

  RubikCube.fromList(List<List<List<int>>> cubeData) : cube = cubeData;

  // Copy constructor
  RubikCube copy() {
    List<List<List<int>>> newCube = List.generate(6, (i) => 
      List.generate(3, (j) => 
        List.generate(3, (k) => cube[i][j][k])));
    return RubikCube.fromList(newCube);
  }

  // Check if cube is solved
  bool isSolved() {
    for (int face = 0; face < 6; face++) {
      int faceColor = cube[face][0][0];
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (cube[face][row][col] != faceColor) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Compare with another cube
  bool equals(RubikCube other) {
    for (int face = 0; face < 6; face++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (cube[face][row][col] != other.cube[face][row][col]) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Heuristic function for A* - count matching squares
  int heuristic(RubikCube goal) {
    int matches = 0;
    for (int face = 0; face < 6; face++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (cube[face][row][col] == goal.cube[face][row][col]) {
            matches++;
          }
        }
      }
    }
    return 54 - matches; // Return number of mismatches
  }

  // Apply a move to the cube
  RubikCube applyMove(MoveType move) {
    RubikCube newCube = copy();
    
    switch (move) {
      case MoveType.leftClockwise:
        return newCube.leftClockwise();
      case MoveType.leftAntiClockwise:
        return newCube.leftAntiClockwise();
      case MoveType.rightClockwise:
        return newCube.rightClockwise();
      case MoveType.rightAntiClockwise:
        return newCube.rightAntiClockwise();
      case MoveType.upClockwise:
        return newCube.upClockwise();
      case MoveType.upAntiClockwise:
        return newCube.upAntiClockwise();
      case MoveType.downClockwise:
        return newCube.downClockwise();
      case MoveType.downAntiClockwise:
        return newCube.downAntiClockwise();
      case MoveType.frontClockwise:
        return newCube.frontClockwise();
      case MoveType.frontAntiClockwise:
        return newCube.frontAntiClockwise();
      case MoveType.backClockwise:
        return newCube.backClockwise();
      case MoveType.backAntiClockwise:
        return newCube.backAntiClockwise();
    }
  }

  // Rotate a face clockwise
  void rotateFaceClockwise(int face) {
    // Rotate the face itself
    int temp = cube[face][0][0];
    cube[face][0][0] = cube[face][2][0];
    cube[face][2][0] = cube[face][2][2];
    cube[face][2][2] = cube[face][0][2];
    cube[face][0][2] = temp;
    
    temp = cube[face][0][1];
    cube[face][0][1] = cube[face][1][0];
    cube[face][1][0] = cube[face][2][1];
    cube[face][2][1] = cube[face][1][2];
    cube[face][1][2] = temp;
  }

  // Rotate a face counter-clockwise
  void rotateFaceAntiClockwise(int face) {
    // Rotate the face itself
    int temp = cube[face][0][0];
    cube[face][0][0] = cube[face][0][2];
    cube[face][0][2] = cube[face][2][2];
    cube[face][2][2] = cube[face][2][0];
    cube[face][2][0] = temp;
    
    temp = cube[face][0][1];
    cube[face][0][1] = cube[face][1][2];
    cube[face][1][2] = cube[face][2][1];
    cube[face][2][1] = cube[face][1][0];
    cube[face][1][0] = temp;
  }

  // Left face clockwise
  RubikCube leftClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(4); // Left face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][i][0];
      newCube.cube[0][i][0] = newCube.cube[3][i][0];
      newCube.cube[3][i][0] = newCube.cube[5][i][0];
      newCube.cube[5][i][0] = newCube.cube[2][i][0];
      newCube.cube[2][i][0] = temp;
    }
    
    return newCube;
  }

  // Left face counter-clockwise
  RubikCube leftAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(4); // Left face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][i][0];
      newCube.cube[0][i][0] = newCube.cube[2][i][0];
      newCube.cube[2][i][0] = newCube.cube[5][i][0];
      newCube.cube[5][i][0] = newCube.cube[3][i][0];
      newCube.cube[3][i][0] = temp;
    }
    
    return newCube;
  }

  // Right face clockwise
  RubikCube rightClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(5); // Right face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][i][2];
      newCube.cube[0][i][2] = newCube.cube[2][i][2];
      newCube.cube[2][i][2] = newCube.cube[5][i][2];
      newCube.cube[5][i][2] = newCube.cube[3][i][2];
      newCube.cube[3][i][2] = temp;
    }
    
    return newCube;
  }

  // Right face counter-clockwise
  RubikCube rightAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(5); // Right face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][i][2];
      newCube.cube[0][i][2] = newCube.cube[3][i][2];
      newCube.cube[3][i][2] = newCube.cube[5][i][2];
      newCube.cube[5][i][2] = newCube.cube[2][i][2];
      newCube.cube[2][i][2] = temp;
    }
    
    return newCube;
  }

  // Up face clockwise
  RubikCube upClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(2); // Up face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][0][i];
      newCube.cube[0][0][i] = newCube.cube[4][0][i];
      newCube.cube[4][0][i] = newCube.cube[5][0][i];
      newCube.cube[5][0][i] = newCube.cube[1][0][i];
      newCube.cube[1][0][i] = temp;
    }
    
    return newCube;
  }

  // Up face counter-clockwise
  RubikCube upAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(2); // Up face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][0][i];
      newCube.cube[0][0][i] = newCube.cube[1][0][i];
      newCube.cube[1][0][i] = newCube.cube[5][0][i];
      newCube.cube[5][0][i] = newCube.cube[4][0][i];
      newCube.cube[4][0][i] = temp;
    }
    
    return newCube;
  }

  // Down face clockwise
  RubikCube downClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(3); // Down face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][2][i];
      newCube.cube[0][2][i] = newCube.cube[1][2][i];
      newCube.cube[1][2][i] = newCube.cube[5][2][i];
      newCube.cube[5][2][i] = newCube.cube[4][2][i];
      newCube.cube[4][2][i] = temp;
    }
    
    return newCube;
  }

  // Down face counter-clockwise
  RubikCube downAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(3); // Down face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[0][2][i];
      newCube.cube[0][2][i] = newCube.cube[4][2][i];
      newCube.cube[4][2][i] = newCube.cube[5][2][i];
      newCube.cube[5][2][i] = newCube.cube[1][2][i];
      newCube.cube[1][2][i] = temp;
    }
    
    return newCube;
  }

  // Front face clockwise
  RubikCube frontClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(0); // Front face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[2][2][i];
      newCube.cube[2][2][i] = newCube.cube[4][2-i][2];
      newCube.cube[4][2-i][2] = newCube.cube[3][0][2-i];
      newCube.cube[3][0][2-i] = newCube.cube[5][i][0];
      newCube.cube[5][i][0] = temp;
    }
    
    return newCube;
  }

  // Front face counter-clockwise
  RubikCube frontAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(0); // Front face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[2][2][i];
      newCube.cube[2][2][i] = newCube.cube[5][i][0];
      newCube.cube[5][i][0] = newCube.cube[3][0][2-i];
      newCube.cube[3][0][2-i] = newCube.cube[4][2-i][2];
      newCube.cube[4][2-i][2] = temp;
    }
    
    return newCube;
  }

  // Back face clockwise
  RubikCube backClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceClockwise(1); // Back face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[2][0][i];
      newCube.cube[2][0][i] = newCube.cube[5][i][2];
      newCube.cube[5][i][2] = newCube.cube[3][2][2-i];
      newCube.cube[3][2][2-i] = newCube.cube[4][2-i][0];
      newCube.cube[4][2-i][0] = temp;
    }
    
    return newCube;
  }

  // Back face counter-clockwise
  RubikCube backAntiClockwise() {
    RubikCube newCube = copy();
    newCube.rotateFaceAntiClockwise(1); // Back face
    
    // Rotate adjacent edges
    for (int i = 0; i < 3; i++) {
      int temp = newCube.cube[2][0][i];
      newCube.cube[2][0][i] = newCube.cube[4][2-i][0];
      newCube.cube[4][2-i][0] = newCube.cube[3][2][2-i];
      newCube.cube[3][2][2-i] = newCube.cube[5][i][2];
      newCube.cube[5][i][2] = temp;
    }
    
    return newCube;
  }

  // Scramble the cube
  void scramble() {
    Random random = Random();
    List<MoveType> moves = MoveType.values;
    
    for (int i = 0; i < 20; i++) {
      MoveType randomMove = moves[random.nextInt(moves.length)];
      RubikCube newCube = applyMove(randomMove);
      cube = newCube.cube;
    }
  }

  // Get all possible moves
  List<MoveType> getAllMoves() {
    return MoveType.values;
  }

  // Convert to string for debugging
  @override
  String toString() {
    String result = '';
    for (int face = 0; face < 6; face++) {
      result += 'Face $face:\n';
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          result += '${cube[face][row][col]} ';
        }
        result += '\n';
      }
      result += '\n';
    }
    return result;
  }
}
