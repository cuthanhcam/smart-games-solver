import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class RubikApiService {
  // Tự động chọn baseUrl dựa trên platform
  static String _baseUrl = '';
  
  static String get baseUrl {
    if (_baseUrl.isEmpty) {
      _initializeBaseUrl();
    }
    return _baseUrl;
  }
  
  static void _initializeBaseUrl() {
    // Nếu chạy trên web, dùng localhost
    if (kIsWeb) {
      _baseUrl = 'http://localhost:5000';
      return;
    }
    
    try {
      // Dùng IP cố định cho tất cả platform
      // _baseUrl = 'http://192.168.1.229:5000';
      _baseUrl = 'http://192.168.1.60:5000';
      
      if (Platform.isAndroid) {
        debugPrint('etected Android platform, using 192.168.1.229:5000');
        debugPrint('⚠Nếu dùng emulator, có thể cần đổi sang 10.0.2.2:5000');
      } else if (Platform.isIOS) {
        debugPrint('Detected iOS platform, using 192.168.1.229:5000');
      } else {
        debugPrint('Detected desktop platform, using 192.168.1.229:5000');
      }
    } catch (e) {
      _baseUrl = 'http://192.168.1.229:5000';
      debugPrint('⚠️ Could not detect platform, using fallback: $_baseUrl');
    }
  }
  
  /// Gửi trạng thái cube và nhận giải pháp từ API Kociemba
  static Future<String?> getSolution(String cubeState) async {
    try {
      debugPrint('Sending cube state to API: $cubeState');
      debugPrint('Sending to: $baseUrl/solve');
      
      final requestBody = jsonEncode({'state': cubeState});
      debugPrint('Request body: $requestBody');
      
      final startTime = DateTime.now();
      debugPrint('Starting API request at ${startTime.toIso8601String()}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/solve'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 300), // Tăng timeout lên 5 phút cho cube phức tạp
        onTimeout: () {
          final elapsed = DateTime.now().difference(startTime);
          debugPrint('⏰ Request timeout after ${elapsed.inSeconds} seconds');
          throw Exception('Request timeout - Server không phản hồi sau ${elapsed.inSeconds} giây');
        },
      );
      
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('Request completed in ${elapsed.inSeconds} seconds');
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Kiểm tra format response
        if (data['solution'] != null) {
          return data['solution'] as String?;
        } else if (data['moves'] != null) {
          // Một số API có thể dùng key 'moves' thay vì 'solution'
          return data['moves'] as String?;
        } else {
          throw Exception('Invalid API response format: ${data.keys}');
        }
      } else {
        final errorMsg = response.body;
        throw Exception('API error ${response.statusCode}: $errorMsg');
      }
    } catch (e) {
      debugPrint('Error details: $e');
      
      // Phân loại lỗi để hiển thị thông báo phù hợp
      if (e.toString().contains('Failed host lookup') || e.toString().contains('Network is unreachable')) {
        String additionalInfo = '';
        try {
          if (Platform.isAndroid) {
            additionalInfo = '\n\n📱 Bạn đang chạy trên Android\n- Nếu dùng emulator: API đang kết nối đến 10.0.2.2:5000\n- Nếu dùng thiết bị thật: Cần đổi IP trong code về IP máy PC';
          }
        } catch (_) {}
        
        throw Exception('Không thể kết nối đến server tại $baseUrl\n\nKiểm tra:\n1. Server Flask đang chạy (python app.py)\n2. Điện thoại và PC cùng mạng Wi-Fi\n3. Firewall không chặn port 5000\n4. Thử mở: http://$baseUrl/health$additionalInfo');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Server không phản hồi sau 5 phút.\n\nCó thể:\n- Cube quá phức tạp\n- Server đang xử lý lâu\n- Kết nối mạng chậm\n\nThử giải cube đơn giản hơn hoặc kiểm tra server.');
      } else {
        throw Exception('Lỗi: $e');
      }
    }
  }
  
  /// Kiểm tra kết nối API
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timeout'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

