import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'rubik_types.dart';

class ColorCalibration {
  static const _prefsKey = 'rubik_calibration';

  /// Lưu HSV trung bình của từng màu (sau khi người dùng calibrate)
  static Future<void> saveCalibration(Map<RubikColor, HSVColor> hsvMap) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = {
      for (final e in hsvMap.entries)
        e.key.name: {
          'h': e.value.hue,
          's': e.value.saturation,
          'v': e.value.value,
        }
    };
    await prefs.setString(_prefsKey, jsonEncode(jsonMap));
  }

  /// Đọc HSV đã lưu, hoặc null nếu chưa calibrate
  static Future<Map<RubikColor, HSVColor>?> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str == null) return null;
    final map = jsonDecode(str) as Map<String, dynamic>;
    return map.map((k, v) {
      final c = RubikColor.values.firstWhere((x) => x.name == k);
      return MapEntry(
        c,
        HSVColor.fromAHSV(1, v['h'] * 1.0, v['s'] * 1.0, v['v'] * 1.0),
      );
    });
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
