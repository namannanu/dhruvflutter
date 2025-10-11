// ignore_for_file: require_trailing_commas

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiAuthService implements AuthService {
  ApiAuthService({
    required this.dio,
    required this.preferences,
  }) {
    _loadUser();
  }

  final Dio dio;
  final SharedPreferences preferences;

  User? _currentUser;
  String? _authToken;
  final _authStateController = StreamController<bool>.broadcast();

  static const _userKey = 'user';
  static const _tokenKey = 'authToken';

  @override
  User? get currentUser => _currentUser;

  @override
  String? get authToken => _authToken;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  Future<void> _loadUser() async {
    final userJson = preferences.getString(_userKey);
    final token = preferences.getString(_tokenKey);

    if (userJson != null && token != null) {
      try {
        _currentUser =
            User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _authToken = token;
        _authStateController.add(true);
      } catch (e) {
        await _clearAuthData();
      }
    }
  }

  Future<void> _saveAuthData(User user, String token) async {
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
    await preferences.setString(_tokenKey, token);
    _currentUser = user;
    _authToken = token;
    _authStateController.add(true);
  }

  Future<void> _clearAuthData() async {
    await preferences.remove(_userKey);
    await preferences.remove(_tokenKey);
    _currentUser = null;
    _authToken = null;
    _authStateController.add(false);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      final token = response.data['token'] as String;
      await _saveAuthData(user, token);
      return user;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to login';
      throw Exception(message);
    }
  }

  @override
  Future<User> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    try {
      final response = await dio.post('/auth/signup', data: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
        'type': userType == UserType.worker ? 'worker' : 'employer',
      });

      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      final token = response.data['token'] as String;
      await _saveAuthData(user, token);
      return user;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Failed to signup';
      throw Exception(message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await dio.post('/auth/logout');
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      await _clearAuthData();
    }
  }

  @override
  void dispose() {
    _authStateController.close();
  }
}
