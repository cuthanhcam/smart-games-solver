import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/user.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/services/api_service.dart';

/// Authentication Service
/// Handles user registration, login, logout, and token management

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _currentUser != null && ApiService.accessToken != null;

  /// Initialize auth state from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);

      if (token != null && userData != null) {
        ApiService.setAccessToken(token);
        _currentUser = User.fromJson(
          Map<String, dynamic>.from(jsonDecode(userData)),
        );
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await logout(); // Clear invalid data
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.register,
        body: {'username': username, 'email': email, 'password': password},
        includeAuth: false,
      );

      final authResponse = AuthResponse.fromJson(response);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.login,
        body: {'username_or_email': username, 'password': password},
        includeAuth: false,
      );

      final authResponse = AuthResponse.fromJson(response);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      if (isAuthenticated) {
        await ApiService.post(ApiConfig.logout, body: {});
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      await _clearAuthData();
    }
  }

  /// Get current user info from server
  Future<User> getCurrentUser() async {
    try {
      final response = await ApiService.get(ApiConfig.currentUser);
      _currentUser = User.fromJson(response);
      await _saveUserData(_currentUser!);
      return _currentUser!;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Save authentication data to storage
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authResponse.accessToken);
    await prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));

    ApiService.setAccessToken(authResponse.accessToken);
    _currentUser = authResponse.user;
  }

  /// Save user data to storage
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _currentUser = user;
  }

  /// Clear authentication data from storage
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    ApiService.setAccessToken(null);
    _currentUser = null;
  }

  /// Handle authentication errors
  Exception _handleAuthError(dynamic error) {
    if (error is ApiException) {
      if (error.isUnauthorized) {
        _clearAuthData(); // Clear invalid auth data
        return Exception('Invalid credentials');
      }
      return Exception(error.message);
    }
    return Exception('Authentication failed: $error');
  }
}

/// Global auth service instance
final authService = AuthService();
