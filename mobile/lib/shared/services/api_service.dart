import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// Base API Service
/// Handles HTTP requests to backend API with authentication

class ApiService {
  static String? _accessToken;

  static void setAccessToken(String? token) {
    _accessToken = token;
  }

  static String? get accessToken => _accessToken;

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Handle HTTP response and throw errors if needed
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['detail'] ?? error['message'] ?? 'Unknown error',
      );
    }
  }

  /// GET request
  static Future<dynamic> get(
    String url, {
    bool includeAuth = true,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParameters);
      final response = await http
          .get(uri, headers: _getHeaders(includeAuth: includeAuth))
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  static Future<dynamic> post(
    String url, {
    required dynamic body,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _getHeaders(includeAuth: includeAuth),
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  static Future<dynamic> put(
    String url, {
    required dynamic body,
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _getHeaders(includeAuth: includeAuth),
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  static Future<dynamic> delete(String url, {bool includeAuth = true}) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _getHeaders(includeAuth: includeAuth),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors consistently
  static Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    return ApiException(statusCode: 0, message: error.toString());
  }
}

/// API Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}
