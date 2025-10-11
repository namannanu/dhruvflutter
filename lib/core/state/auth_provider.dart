// ignore_for_file: directives_ordering, require_trailing_commas

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.authService,
  }) {
    _init();
  }

  final AuthService authService;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => authService.currentUser;
  bool get isAuthenticated => authService.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.signup(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        userType: userType,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authService.logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    authService.dispose();
    super.dispose();
  }

  static Future<AuthProvider> create() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://api.talentapp.com', // Replace with your API URL
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final prefs = await SharedPreferences.getInstance();
    final authService = ApiAuthService(dio: dio, preferences: prefs);

    return AuthProvider(authService: authService);
  }
}
