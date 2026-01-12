import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:exif/exif.dart';
import 'rubik_types.dart';

class ColorAnalyzer {
  /// Màu Rubik chuẩn (theo quy ước quốc tế)
  static const Map<RubikColor, Color> _standardColors = {
    RubikColor.U: Color(0xFFF2F2F2), // trắng (White)
    RubikColor.R: Color(0xFFCA0C00), // đỏ (Red)
    RubikColor.F: Color(0xFF00912F), // xanh lá (Green)
    RubikColor.D: Color(0xFFDFC100), // vàng (Yellow)
    RubikColor.L: Color(0xFFC65205), // cam (Orange) - Left face
    RubikColor.B: Color(0xFF012798), // xanh dương (Blue) - Back face
  };

  /// Phân tích 9 ô Rubik từ ảnh chụp với thuật toán kỹ lưỡng
  static Future<List<RubikColor>> analyzeFaceColors(String imagePath) async {
    try {
      debugPrint('🔍 Bắt đầu phân tích màu từ: $imagePath');
      
      final file = File(imagePath);
      if (!await file.exists()) throw Exception('File ảnh không tồn tại');
      final bytes = await file.readAsBytes();
      debugPrint('📁 Đã đọc ${bytes.length} bytes từ file ảnh');

      // Đọc EXIF xoay ảnh
      final exif = await readExifFromBytes(bytes);
      final orientation = exif['Image Orientation']?.printable ?? '';
      debugPrint('🔄 EXIF Orientation: $orientation');

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      ui.Image img = frame.image;
      debugPrint('🖼️ Ảnh đã decode: ${img.width}x${img.height}');

      // Xoay ảnh đúng chiều
      if (orientation.contains('90')) {
        img = await _rotate(img, 90);
        debugPrint('🔄 Đã xoay ảnh 90°');
      }
      if (orientation.contains('180')) {
        img = await _rotate(img, 180);
        debugPrint('🔄 Đã xoay ảnh 180°');
      }
      if (orientation.contains('270')) {
        img = await _rotate(img, 270);
        debugPrint('🔄 Đã xoay ảnh 270°');
      }

      final List<RubikColor> colors = [];
      final double cellW = img.width / 3;
      final double cellH = img.height / 3;
      debugPrint('📐 Kích thước ô: ${cellW.toStringAsFixed(1)}x${cellH.toStringAsFixed(1)}');

      // 🔹 Thu thập màu cho tất cả 9 ô với phân tích kỹ lưỡng
      final List<Color> cellColors = [];
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          // Tính toán vùng của ô hiện tại
          final double startX = c * cellW;
          final double endX = (c + 1) * cellW;
          final double startY = r * cellH;
          final double endY = (r + 1) * cellH;
          
          // Lấy màu từ toàn bộ ô với radius tối ưu
          final double centerX = (startX + endX) / 2;
          final double centerY = (startY + endY) / 2;
          final int radius = (cellW * 0.45).round(); // Lấy 90% diện tích ô để chính xác hơn
          
          debugPrint('🎯 Phân tích Cell ($r,$c): center=(${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)}), radius=$radius');
          final avg = await _avgColor(img, centerX, centerY, radius);
          final hsv = HSVColor.fromColor(avg);
          debugPrint('🎨 Cell ($r,$c) màu gốc: RGB(${avg.red}, ${avg.green}, ${avg.blue}) HSV(${hsv.hue.toStringAsFixed(1)}, ${hsv.saturation.toStringAsFixed(2)}, ${hsv.value.toStringAsFixed(2)})');
          cellColors.add(avg);
        }
      }

      // 🔹 Adaptive Hue Correction: Dùng ô giữa (index 4) làm chuẩn
      final centerColor = cellColors[4];
      final centerHsv = HSVColor.fromColor(centerColor);
      debugPrint('🎯 Center HSV (ô giữa): H=${centerHsv.hue.toStringAsFixed(1)}, S=${centerHsv.saturation.toStringAsFixed(2)}, V=${centerHsv.value.toStringAsFixed(2)}');

      // Hiệu chỉnh hue cho các ô khác dựa trên ô giữa với độ chính xác cao
      final List<Color> correctedColors = [];
      for (int i = 0; i < 9; i++) {
        if (i == 4) {
          // Ô giữa giữ nguyên
          correctedColors.add(cellColors[i]);
          debugPrint('🎯 Cell $i (giữa): Giữ nguyên màu gốc');
        } else {
          // Hiệu chỉnh hue cho các ô khác với thuật toán kỹ lưỡng
          final hsv = HSVColor.fromColor(cellColors[i]);
          final hueDiff = _hueDiff(hsv.hue, centerHsv.hue);
          
          debugPrint('🔍 Cell $i: Hue gốc=${hsv.hue.toStringAsFixed(1)}, Center=${centerHsv.hue.toStringAsFixed(1)}, Diff=${hueDiff.toStringAsFixed(1)}°');
          
          if (hueDiff > 15) { // Giảm ngưỡng từ 20° xuống 15° để hiệu chỉnh kỹ hơn
            // Nếu lệch hue > 15°, giảm chênh lệch 40% (tăng từ 30%)
            final correctedHue = centerHsv.hue + (hsv.hue - centerHsv.hue) * 0.6;
            final correctedColor = hsv.withHue(correctedHue).toColor();
            correctedColors.add(correctedColor);
            debugPrint('🔧 Cell $i: Hiệu chỉnh H=${hsv.hue.toStringAsFixed(1)}° → ${correctedHue.toStringAsFixed(1)}°');
          } else {
            correctedColors.add(cellColors[i]);
            debugPrint('✅ Cell $i: Hue ổn định, không cần hiệu chỉnh');
          }
        }
      }

      // 🔹 Phân loại màu với thuật toán kỹ lưỡng và logging chi tiết
      debugPrint('🏷️ Bắt đầu phân loại màu cho 9 ô:');
      for (int i = 0; i < 9; i++) {
        final rubikColor = _classifyColor(correctedColors[i]);
        final hsv = HSVColor.fromColor(correctedColors[i]);
        final rgb = correctedColors[i];
        debugPrint('🧩 Cell $i: RGB(${rgb.red}, ${rgb.green}, ${rgb.blue}) HSV(${hsv.hue.toStringAsFixed(1)}, ${hsv.saturation.toStringAsFixed(2)}, ${hsv.value.toStringAsFixed(2)}) => $rubikColor');
        colors.add(rubikColor);
      }
      
      debugPrint('✅ Hoàn thành phân tích màu: ${colors.map((c) => c.name).join(', ')}');

      return colors;
    } catch (e) {
      debugPrint('❌ Lỗi phân tích màu: $e');
      return List.filled(9, RubikColor.U);
    }
  }

  /// Tính trung bình màu quanh (x, y) với thuật toán kỹ lưỡng
  static Future<Color> _avgColor(ui.Image img, double cx, double cy, int radius) async {
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return Colors.grey;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final width = img.width;

    // 🔹 Thu thập tất cả pixel trong vùng với phân tích kỹ lưỡng
    final List<double> values = [];
    final List<Color> samples = [];
    int totalPixels = 0;
    int validPixels = 0;

    for (int y = (cy - radius).round(); y < (cy + radius).round(); y++) {
      for (int x = (cx - radius).round(); x < (cx + radius).round(); x++) {
        totalPixels++;
        if (x >= 0 && x < width && y >= 0 && y < img.height) {
          final i = (y * width + x) * 4;
          if (i + 2 < pixels.length) {
            final rr = pixels[i];
            final gg = pixels[i + 1];
            final bb = pixels[i + 2];
            final hsv = HSVColor.fromColor(Color.fromRGBO(rr, gg, bb, 1));

            // ⚙️ Lọc pixel với tiêu chí nghiêm ngặt hơn
            if (hsv.value > 0.1 && hsv.value < 0.95 && hsv.saturation > 0.1) {
              values.add(hsv.value);
              samples.add(Color.fromRGBO(rr, gg, bb, 1));
              validPixels++;
            }
          }
        }
      }
    }

    if (samples.isEmpty) {
      debugPrint('⚠️ Không có pixel hợp lệ trong vùng (${totalPixels} pixel)');
      return Colors.grey;
    }

    debugPrint('📊 Vùng phân tích: ${totalPixels} pixel tổng, ${validPixels} pixel hợp lệ (${(validPixels/totalPixels*100).toStringAsFixed(1)}%)');

    // 🔹 Outlier rejection với tỷ lệ động
    values.sort();
    final double outlierRatio = 0.1; // Giảm từ 15% xuống 10% để giữ nhiều pixel hơn
    final int start = (values.length * outlierRatio).round();
    final int end = (values.length * (1 - outlierRatio)).round();
    final double vMin = values[start];
    final double vMax = values[end];

    debugPrint('🔍 Outlier rejection: Giữ ${(1-2*outlierRatio)*100}% pixel trong khoảng V=[${vMin.toStringAsFixed(2)}, ${vMax.toStringAsFixed(2)}]');

    int r = 0, g = 0, b = 0, count = 0;
    for (final c in samples) {
      final hsv = HSVColor.fromColor(c);
      if (hsv.value >= vMin && hsv.value <= vMax) {
        r += c.red; 
        g += c.green; 
        b += c.blue; 
        count++;
      }
    }

    if (count == 0) {
      debugPrint('⚠️ Không có pixel nào sau outlier rejection');
      return Colors.grey;
    }

    // 🔹 Chuẩn hóa độ sáng với thuật toán cải tiến
    var color = Color.fromRGBO((r / count).round(), (g / count).round(), (b / count).round(), 1);
    final hsv = HSVColor.fromColor(color);
    final originalV = hsv.value;

    // Chuẩn hóa độ sáng với phạm vi rộng hơn
    final adjV = (hsv.value < 0.25)
        ? 0.25 + hsv.value * 1.5  // Tăng hệ số từ 1.2 lên 1.5
        : (hsv.value > 0.85)
            ? 0.85  // Giảm từ 0.8 lên 0.85
            : hsv.value;
    
    color = hsv.withValue(adjV).toColor();
    
    debugPrint('🎨 Màu trung bình: RGB(${color.red}, ${color.green}, ${color.blue}) HSV(${hsv.hue.toStringAsFixed(1)}, ${hsv.saturation.toStringAsFixed(2)}, ${originalV.toStringAsFixed(2)}→${adjV.toStringAsFixed(2)})');

    return color;
  }

  /// Phân loại màu bằng HSV + lọc sáng
  static RubikColor _classifyColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    final h = hsv.hue;
    final s = hsv.saturation;
    final v = hsv.value;

    // ⚪ Trắng
    if (s < 0.2 && v > 0.75) return RubikColor.U;

    // 🟡 Vàng
    if (h >= 35 && h <= 65 && s > 0.4 && v > 0.5) return RubikColor.D;

    // 🔴 Đỏ
    if ((h >= 0 && h <= 15) || (h >= 345 && h <= 360)) return RubikColor.R;

    // 🟠 Cam
    if (h >= 16 && h <= 34 && s > 0.5) return RubikColor.B;

    // 🟢 Xanh lá
    if (h >= 70 && h <= 150 && s > 0.4) return RubikColor.F;

    // 🔵 Xanh dương
    if (h >= 180 && h <= 260 && s > 0.4) return RubikColor.L;

    // Nếu không rõ, tìm màu gần nhất theo khoảng cách hue
    double bestDist = double.infinity;
    RubikColor best = RubikColor.U;
    for (final e in _standardColors.entries) {
      final std = HSVColor.fromColor(e.value);
      final dist = _hueDiff(h, std.hue) * 1.0 +
          (s - std.saturation).abs() * 100 +
          (v - std.value).abs() * 100;
      if (dist < bestDist) {
        bestDist = dist;
        best = e.key;
      }
    }
    return best;
  }

  /// Khoảng cách hue (0–360)
  static double _hueDiff(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  /// Xoay ảnh (fix orientation)
  static Future<ui.Image> _rotate(ui.Image img, double deg) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (deg == 90) {
      canvas.translate(img.height.toDouble(), 0);
      canvas.rotate(math.pi / 2);
    } else if (deg == 180) {
      canvas.translate(img.width.toDouble(), img.height.toDouble());
      canvas.rotate(math.pi);
    } else if (deg == 270) {
      canvas.translate(0, img.width.toDouble());
      canvas.rotate(-math.pi / 2);
    }

    canvas.drawImage(img, Offset.zero, Paint());
    final pic = recorder.endRecording();
    final w = (deg == 90 || deg == 270) ? img.height : img.width;
    final h = (deg == 90 || deg == 270) ? img.width : img.height;
    return await pic.toImage(w, h);
  }

  /// Kiểm tra đủ 9 ô mỗi màu
  static bool validateColorCounts(Map<Face, List<RubikColor>> faces) {
    final count = <RubikColor, int>{};
    for (final f in faces.values) {
      for (final c in f) {
        count[c] = (count[c] ?? 0) + 1;
      }
    }
    return RubikColor.values.every((c) => (count[c] ?? 0) == 9);
  }

  /// Phân tích màu từ ảnh asset (fallback khi camera lỗi)
  static Future<List<RubikColor>> analyzeAssetFace(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final colors = <RubikColor>[];
      final cellW = image.width / 3;
      final cellH = image.height / 3;

      // 🔹 Thu thập màu cho tất cả 9 ô (lấy từ TOÀN BỘ diện tích ô)
      final List<Color> cellColors = [];
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          // Tính toán vùng của ô hiện tại
          final double startX = c * cellW;
          final double endX = (c + 1) * cellW;
          final double startY = r * cellH;
          final double endY = (r + 1) * cellH;
          
          // Lấy màu từ toàn bộ ô (radius = 40% kích thước ô)
          final double centerX = (startX + endX) / 2;
          final double centerY = (startY + endY) / 2;
          final int radius = (cellW * 0.45).round(); // Lấy 90% diện tích ô để chính xác hơn
          
          debugPrint('🎯 Asset Cell ($r,$c): center=(${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)}), radius=$radius');
          final avg = await _avgColor(image, centerX, centerY, radius);
          cellColors.add(avg);
        }
      }

      // 🔹 Adaptive Hue Correction: Dùng ô giữa (index 4) làm chuẩn
      final centerColor = cellColors[4];
      final centerHsv = HSVColor.fromColor(centerColor);
      debugPrint('🎯 Asset Center HSV: H=${centerHsv.hue.toStringAsFixed(1)}, S=${centerHsv.saturation.toStringAsFixed(2)}, V=${centerHsv.value.toStringAsFixed(2)}');

      // Hiệu chỉnh hue cho các ô khác dựa trên ô giữa
      final List<Color> correctedColors = [];
      for (int i = 0; i < 9; i++) {
        if (i == 4) {
          // Ô giữa giữ nguyên
          correctedColors.add(cellColors[i]);
        } else {
          // Hiệu chỉnh hue cho các ô khác
          final hsv = HSVColor.fromColor(cellColors[i]);
          final hueDiff = _hueDiff(hsv.hue, centerHsv.hue);
          
          if (hueDiff > 20) {
            // Nếu lệch hue > 20°, giảm chênh lệch 30%
            final correctedHue = centerHsv.hue + (hsv.hue - centerHsv.hue) * 0.7;
            correctedColors.add(hsv.withHue(correctedHue).toColor());
            debugPrint('🔧 Asset Corrected cell $i: H=${hsv.hue.toStringAsFixed(1)} → ${correctedHue.toStringAsFixed(1)}');
          } else {
            correctedColors.add(cellColors[i]);
          }
        }
      }

      // 🔹 Phân loại màu với HSV logging
      for (int i = 0; i < 9; i++) {
        final rubikColor = _classifyColor(correctedColors[i]);
        final hsv = HSVColor.fromColor(correctedColors[i]);
        debugPrint('🧩 Asset Cell $i: HSV(${hsv.hue.toStringAsFixed(1)}, ${hsv.saturation.toStringAsFixed(2)}, ${hsv.value.toStringAsFixed(2)}) => $rubikColor');
        colors.add(rubikColor);
      }

      return colors;
    } catch (e) {
      debugPrint('❌ Lỗi đọc ảnh asset: $e');
      return List.filled(9, RubikColor.U);
    }
  }

  /// Getter để truy cập màu chuẩn từ bên ngoài
  static Map<RubikColor, Color> get standardColors => _standardColors;
}