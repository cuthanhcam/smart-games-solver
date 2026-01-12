import 'package:flutter/material.dart';

typedef OnCellTap = void Function(int index);
typedef OnNumberTap = void Function(int number);

class SudokuBoard extends StatelessWidget {
  final List<int> givens;   // 81 phần tử – đề bài (ô !=0 là cố định)
  final List<int> current;  // 81 phần tử – trạng thái hiện tại
  final int? selected;      // index ô đang chọn
  final Map<int, Set<int>> notes; // Notes cho mỗi ô
  final bool noteMode;      // Chế độ note hiện tại
  final Set<int> highlightedCells; // Các ô cần highlight khi chọn sai
  final Set<int> selectedAreaCells; // Các ô trong vùng được chọn (3x3 + hàng + cột)
  final OnCellTap onCellTap;
  final OnNumberTap onNumberTap;
  final VoidCallback onErase;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onToggleNote;
  final bool canUndo;
  final String level;
  final Function(String?) onLevelChanged;
  final VoidCallback onNewGame;

  const SudokuBoard({
    super.key,
    required this.givens,
    required this.current,
    required this.selected,
    required this.notes,
    required this.noteMode,
    required this.highlightedCells,
    required this.selectedAreaCells,
    required this.onCellTap,
    required this.onNumberTap,
    required this.onErase,
    required this.onUndo,
    required this.onHint,
    required this.onToggleNote,
    required this.level,
    required this.onLevelChanged,
    required this.onNewGame,
    this.canUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            itemCount: 81,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemBuilder: (context, i) {
              final fixed = givens[i] != 0;
              final value = current[i];
              final sel = i == selected;
              final highlighted = highlightedCells.contains(i);
              final inSelectedArea = selectedAreaCells.contains(i);
              final thick = BorderSide(color: const Color(0xFF777777), width: 1.2); // Mau vien

              BorderSide thin(Color c, [double w = 0.4]) => BorderSide(color: const Color(0xFF777777), width: w); // Mau vien mong
              final c = Colors.white;

              // Xác định màu nền ô
              Color cellColor;
              if (sel) {
                cellColor = const Color(0x902196F3); // O duoc chon
              } else if (highlighted) {
                cellColor = const Color(0x90FF6B6B); // O highlìght
              } else if (inSelectedArea) {
                cellColor = const Color(0x352196F3); // O trong vung duoc chon
              } else {
                cellColor = const Color(0xFFFFFFFF); // Mau O
              }

              return InkWell(
                onTap: () => onCellTap(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: Border(
                      top:    (i ~/ 9) % 3 == 0 ? thick : thin(c),
                      left:   (i % 9) % 3 == 0 ? thick : thin(c),
                      right:  (i % 9) == 8 ? thick : thin(c),
                      bottom: (i ~/ 9) == 8 ? thick : thin(c),
                    ),
                  ),
                  child: value == 0
                      ? _buildNotes(i)
                      : Center(
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: fixed ? FontWeight.w800 : FontWeight.w600,
                        color: fixed ? const Color(0xFF777777) : const Color(0xFFF7CA25), // Mau chu
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _NumberPad(onTap: onNumberTap, onErase: onErase),
        const SizedBox(height: 8),
        _ControlButtons(
          onUndo: onUndo,
          onErase: onErase,
          onHint: onHint,
          onToggleNote: onToggleNote,
          noteMode: noteMode,
          canUndo: canUndo,
        ),
        const SizedBox(height: 8),
        // Difficulty selection and New Game button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Difficulty dropdown
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFE4ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF777777),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: level,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: const Color(0xFFBFE4ED),
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF777777),
                      size: 16,
                    ),
                    onChanged: onLevelChanged,
                    items: <String>['Easy', 'Medium', 'Hard', 'Expert']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // New Game button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onNewGame,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('New game', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57BCCE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(int index) {
    final cellNotes = notes[index] ?? <int>{};
    if (cellNotes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: 9,
        itemBuilder: (context, i) {
          final number = i + 1;
          final hasNote = cellNotes.contains(number);
          return Center(
            child: Text(
              hasNote ? number.toString() : '',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final OnNumberTap onTap;
  final VoidCallback onErase;
  const _NumberPad({required this.onTap, required this.onErase});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int n = 1; n <= 9; n++)
          Flexible(
            child: _buildNumberButton(n),
          ),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    return GestureDetector(
      onTap: () => onTap(number),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Light blue background
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2), // Dark blue text
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final VoidCallback onToggleNote;
  final bool noteMode;
  final bool canUndo;

  const _ControlButtons({
    required this.onUndo,
    required this.onErase,
    required this.onHint,
    required this.onToggleNote,
    required this.noteMode,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton('Undo', Icons.undo, onUndo, enabled: canUndo),
        _buildControlButton('Erase', Icons.auto_fix_high, onErase),
        _buildControlButton('Note', Icons.edit, onToggleNote, enabled: true, active: noteMode),
        _buildControlButton('Hint', Icons.lightbulb_outline, onHint),
      ],
    );
  }

  Widget _buildControlButton(String label, IconData icon, VoidCallback onPressed, {bool enabled = true, bool active = false}) {
    final isActive = enabled && active;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF57BCCE) : (enabled ? Colors.white : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? const Color(0xFF57BCCE) : (enabled ? Colors.grey[300]! : Colors.grey[200]!)
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                icon,
                size: 22,
                color: isActive ? Colors.white : (enabled ? Colors.grey[600] : Colors.grey[400])
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : (enabled ? Colors.grey[600] : Colors.grey[400]),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

