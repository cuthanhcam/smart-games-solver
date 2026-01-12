import 'package:flutter/material.dart';
import '../logic/rubik_types.dart';
import '../ui/rubik_palette.dart';
import 'rubik_solution_screen.dart';

/// Kociemba-style Color Picker for Rubik's Cube
class RubikColorPickerScreen extends StatefulWidget {
  const RubikColorPickerScreen({super.key});

  @override
  State<RubikColorPickerScreen> createState() => _RubikColorPickerScreenState();
}

class _RubikColorPickerScreenState extends State<RubikColorPickerScreen> {
  // Thứ tự hiển thị theo chuẩn Kociemba: URFDLB
  static const List<Face> displayOrder = [Face.U, Face.R, Face.F, Face.D, Face.L, Face.B];
  
  // 6 faces, each with 9 squares
  final Map<Face, List<RubikColor?>> _faces = {
    for (final f in Face.values) f: List<RubikColor?>.filled(9, null)
  };
  
  int _currentSquareIndex = 0; // Square to color next (0-53)
  Face _currentFace = Face.U; // Bắt đầu với mặt U (chuẩn Kociemba)
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _updateCurrentFace();
  }

  void _updateCurrentFace() {
    // Determine which face we're on dựa trên displayOrder
    int faceIndex = _currentSquareIndex ~/ 9;
    if (faceIndex < displayOrder.length) {
      _currentFace = displayOrder[faceIndex];
    }
  }

  int get _currentSquareInFace => _currentSquareIndex % 9;
  
  void _onColorSelected(RubikColor color) {
    if (_currentSquareIndex >= 54) {
      setState(() => _isFinished = true);
      return;
    }

    setState(() {
      final faceIndex = _currentSquareIndex ~/ 9;
      final squareInFace = _currentSquareIndex % 9;
      
      if (faceIndex < displayOrder.length) {
        final face = displayOrder[faceIndex];
        _faces[face]![squareInFace] = color;
        _currentSquareIndex++;
        
        // Check if all squares are filled
        if (_currentSquareIndex >= 54) {
          _isFinished = true;
        } else {
          _updateCurrentFace();
        }
      }
    });
  }

  void _onSquareTap(Face face, int squareIndex) {
    setState(() {
      _currentFace = face;
      _currentSquareIndex = displayOrder.indexOf(face) * 9 + squareIndex;
      
      // Check if all squares are filled
      bool allFilled = _faces.values.every((face) => 
        face.every((color) => color != null)
      );
      if (allFilled) {
        _isFinished = true;
      }
    });
  }

  void _clearFace(Face face) {
    setState(() {
      _faces[face] = List.filled(9, null);
    });
  }

  void _onSolve() {
    // Check if all faces are complete
    final allComplete = _faces.values.every((face) => 
      face.every((color) => color != null)
    );
    
    if (!allComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tô đủ tất cả 6 mặt')),
      );
      return;
    }

    // Convert to proper format
    final faces = _faces.map((key, value) => 
      MapEntry(key, value.cast<RubikColor>())
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RubikSolutionScreen(faces: faces),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Nhập màu Rubik'),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tiến độ: ${_faces.values.where((f) => f.every((c) => c != null)).length}/6 mặt',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _faces.values.where((f) => f.every((c) => c != null)).length / 6,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          
          // Net display (Kociemba origami-style) - Horizontal scroll
          Expanded(
            child: _buildNetDisplay(),
          ),
          
          // Color palette
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: _buildColorPalette(),
          ),
        ],
      ),
    );
  }

  Widget _buildNetDisplay() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: displayOrder.map((face) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.75, // 75% screen width
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildFaceGrid(
                face,
                _getFaceTitle(face),
                _getFaceColorHint(face),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _getFaceTitle(Face face) {
    switch (face) {
      case Face.U: return "Mặt Trên (U)";
      case Face.R: return "Mặt Phải (R)";
      case Face.F: return "Mặt Trước (F)";
      case Face.D: return "Mặt Dưới (D)";
      case Face.L: return "Mặt Trái (L)";
      case Face.B: return "Mặt Sau (B)";
    }
  }
  
  String _getFaceColorHint(Face face) {
    switch (face) {
      case Face.U: return "Trắng";
      case Face.R: return "Đỏ";
      case Face.F: return "Xanh lá";
      case Face.D: return "Vàng";
      case Face.L: return "Cam"; // Left = Orange
      case Face.B: return "Xanh dương"; // Back = Blue
    }
  }

  Widget _buildFaceGrid(Face face, String title, String colorHint) {
    final squares = _faces[face]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '($colorHint)',
                style: TextStyle(color: Colors.grey[400], fontSize: 9),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _clearFace(face),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.clear, size: 12),
                  SizedBox(width: 2),
                  Text('Xóa', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _currentFace == face ? Colors.purple.shade400 : Colors.grey[700]!,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 1,
              childAspectRatio: 1,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final color = squares[index];
              return GestureDetector(
                onTap: () => _onSquareTap(face, index),
                child: Container(
                  decoration: BoxDecoration(
                    color: color != null ? paletteColor[color] : Colors.grey[800],
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: color != null ? Colors.white.withOpacity(0.5) : Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  child: color == null
                      ? Icon(
                          Icons.add_circle_outline,
                          color: Colors.purple.shade300,
                          size: 12,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorPalette() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Chọn màu:',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        // 3x2 Grid layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.6,
          ),
          itemCount: RubikColor.values.length,
          itemBuilder: (context, index) {
            final color = RubikColor.values[index];
            return GestureDetector(
              onTap: () => _onColorSelected(color),
              child: Container(
                decoration: BoxDecoration(
                  color: paletteColor[color],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: paletteColor[color]!.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0.3,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getColorSymbol(color),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 0),
                      Text(
                        _getColorName(color),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isFinished ? _onSolve : null,
            icon: const Icon(Icons.build_circle, size: 16),
            label: const Text('Giải Cube', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFinished ? Colors.purple.shade600 : Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  String _getColorSymbol(RubikColor color) {
    // Hiển thị ký tự viết tắt
    switch (color) {
      case RubikColor.U: return 'U';
      case RubikColor.R: return 'R';
      case RubikColor.F: return 'F';
      case RubikColor.D: return 'D';
      case RubikColor.L: return 'L';
      case RubikColor.B: return 'B';
    }
  }

  String _getColorName(RubikColor color) {
    // Hiển thị tên màu vật lý
    switch (color) {
      case RubikColor.U: return 'Trắng';
      case RubikColor.R: return 'Đỏ';
      case RubikColor.F: return 'Xanh lá';
      case RubikColor.D: return 'Vàng';
      case RubikColor.L: return 'Cam';
      case RubikColor.B: return 'Xanh dương';
    }
  }
}

