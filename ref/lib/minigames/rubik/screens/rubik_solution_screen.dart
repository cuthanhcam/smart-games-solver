import 'package:flutter/material.dart';
import '../logic/rubik_types.dart';
import '../models/rubik_cube.dart';
import '../services/rubik_api_service.dart';

/// Convert faces to Kociemba cube state format (54-character string)
/// Format: URFDLB face order, each face 9 colors (top-left to bottom-right)
String convertFacesToKociembaState(Map<Face, List<RubikColor>> faces) {
  // Kociemba expects: URFDLB (Up, Right, Front, Down, Left, Back)
  // Each face: 9 colors from top-left to bottom-right
  final faceOrder = [Face.U, Face.R, Face.F, Face.D, Face.L, Face.B];
  final colorMap = {
    RubikColor.U: 'U', // White
    RubikColor.R: 'R', // Red
    RubikColor.F: 'F', // Green
    RubikColor.D: 'D', // Yellow
    RubikColor.L: 'L', // Blue
    RubikColor.B: 'B', // Orange
  };
  
  final buffer = StringBuffer();
  for (final face in faceOrder) {
    final colors = faces[face]!;
    for (final color in colors) {
      buffer.write(colorMap[color]!);
    }
  }
  
  return buffer.toString(); // 54 characters total
}

class RubikSolutionScreen extends StatefulWidget {
  final Map<Face, List<RubikColor>> faces;
  const RubikSolutionScreen({super.key, required this.faces});

  @override
  State<RubikSolutionScreen> createState() => _RubikSolutionScreenState();
}

class _RubikSolutionScreenState extends State<RubikSolutionScreen> {
  List<String>? solution;
  String? error;
  bool isLoading = true;
  int? optimalMoves;

  @override
  void initState() {
    super.initState();
    _solve();
  }

  Future<void> _solve() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Convert faces to Kociemba cube state
      final cubeState = convertFacesToKociembaState(widget.faces);
      debugPrint('🔍 Cube state: $cubeState');
      debugPrint('🔍 Cube state length: ${cubeState.length}');
      
      // Log first few characters to verify format
      if (cubeState.length >= 9) {
        debugPrint('🔍 First 9 chars (Face U): ${cubeState.substring(0, 9)}');
      }
      
      // Try API first
      String? solutionString;
      try {
        solutionString = await RubikApiService.getSolution(cubeState);
        debugPrint('✅ Got solution from API: $solutionString');
      } catch (apiError) {
        debugPrint('⚠️ API failed: $apiError');
        setState(() {
          error = apiError.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
        return;
      }
      
      if (solutionString != null && solutionString.isNotEmpty) {
        // Parse solution string (format: "U R F D L B ...")
        final moves = solutionString.split(' ').where((m) => m.isNotEmpty).toList();
        
        debugPrint('✅ Found solution with ${moves.length} moves');
        
        setState(() {
          solution = moves;
          optimalMoves = moves.length;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Không thể tìm ra giải pháp. Vui lòng kiểm tra kết nối hoặc thử lại.';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error solving rubik: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        error = 'Lỗi khi giải rubik: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Kết quả giải Rubik'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: error != null
            ? _errorView(error!)
            : isLoading
            ? _loadingView()
            : _solutionView(),
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 20),
          Text(
            'Đang tính toán giải pháp tối ưu...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          if (optimalMoves != null) ...[
            const SizedBox(height: 10),
            Text(
              'Ước tính: $optimalMoves bước',
              style: TextStyle(
                color: Colors.purple.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _solutionView() {
    if (solution == null || solution!.isEmpty) {
      return _errorView('Không thể tìm ra giải pháp');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với thông tin giải pháp
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.purple.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giải pháp tối ưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${solution!.length} bước',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (optimalMoves != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tối ưu: $optimalMoves',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Moves list
        Text(
          'Chuỗi bước giải:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Moves chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: solution!.asMap().entries.map((entry) {
            final index = entry.key;
            final move = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade100.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.purple.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    move,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 20),
        
        // Detailed steps
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: solution!.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade600,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  solution![i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _getMoveDescription(solution![i]),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _solve,
                icon: const Icon(Icons.refresh),
                label: const Text('Giải lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple.shade300,
                  side: BorderSide(color: Colors.purple.shade300),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Hoàn thành'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMoveDescription(String move) {
    switch (move) {
      case 'R': return 'Xoay mặt phải theo chiều kim đồng hồ';
      case 'R\'': return 'Xoay mặt phải ngược chiều kim đồng hồ';
      case 'R2': return 'Xoay mặt phải 180°';
      case 'L': return 'Xoay mặt trái theo chiều kim đồng hồ';
      case 'L\'': return 'Xoay mặt trái ngược chiều kim đồng hồ';
      case 'L2': return 'Xoay mặt trái 180°';
      case 'U': return 'Xoay mặt trên theo chiều kim đồng hồ';
      case 'U\'': return 'Xoay mặt trên ngược chiều kim đồng hồ';
      case 'U2': return 'Xoay mặt trên 180°';
      case 'D': return 'Xoay mặt dưới theo chiều kim đồng hồ';
      case 'D\'': return 'Xoay mặt dưới ngược chiều kim đồng hồ';
      case 'D2': return 'Xoay mặt dưới 180°';
      case 'F': return 'Xoay mặt trước theo chiều kim đồng hồ';
      case 'F\'': return 'Xoay mặt trước ngược chiều kim đồng hồ';
      case 'F2': return 'Xoay mặt trước 180°';
      case 'B': return 'Xoay mặt sau theo chiều kim đồng hồ';
      case 'B\'': return 'Xoay mặt sau ngược chiều kim đồng hồ';
      case 'B2': return 'Xoay mặt sau 180°';
      default: return 'Thực hiện bước $move';
    }
  }

  Widget _errorView(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.shade400,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'Không thể giải cube',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _solve,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
