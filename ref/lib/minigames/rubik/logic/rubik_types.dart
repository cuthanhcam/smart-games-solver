enum Face { U, R, F, D, L, B }
enum RubikColor { U, R, F, D, L, B }

const faceOrder = [Face.U, Face.R, Face.F, Face.D, Face.L, Face.B];

const faceName = {
  Face.U: 'Up',
  Face.R: 'Right',
  Face.F: 'Front',
  Face.D: 'Down',
  Face.L: 'Left',
  Face.B: 'Back',
};

const faceShort = {
  Face.U: 'U',
  Face.R: 'R',
  Face.F: 'F',
  Face.D: 'D',
  Face.L: 'L',
  Face.B: 'B',
};

RubikColor defaultCenterColor(Face f) {
  switch (f) {
    case Face.U: return RubikColor.U;
    case Face.R: return RubikColor.R;
    case Face.F: return RubikColor.F;
    case Face.D: return RubikColor.D;
    case Face.L: return RubikColor.L;
    case Face.B: return RubikColor.B;
  }
}

const colorChar = {
  RubikColor.U: 'U',
  RubikColor.R: 'R',
  RubikColor.F: 'F',
  RubikColor.D: 'D',
  RubikColor.L: 'L',
  RubikColor.B: 'B',
};

String facesToFacelets(Map<Face, List<RubikColor>> faces) {
  final buf = StringBuffer();
  for (final f in faceOrder) {
    final list = faces[f]!;
    if (list.length != 9) {
      throw 'Mặt $f chưa đủ 9 sticker';
    }
    for (final c in list) {
      buf.write(colorChar[c]);
    }
  }
  return buf.toString(); // 54 ký tự theo URFDLB
}

class ScanState {
  Face current = Face.U;
  final Map<Face, List<RubikColor>> faces = {
    for (final f in faceOrder) f: <RubikColor>[]
  };

  bool get isComplete => faces.values.every((l) => l.length == 9);
  void clearFace(Face f) => faces[f] = <RubikColor>[];

  bool basicValidCounts() {
    final count = {for (final c in RubikColor.values) c: 0};
    for (final l in faces.values) {
      if (l.length != 9) return false;
      for (final c in l) { count[c] = (count[c] ?? 0) + 1; }
    }
    return count.values.every((n) => n == 9);
  }
}