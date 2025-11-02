// ignore_for_file: directives_ordering, require_trailing_commas

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_auth_service.dart';
import '../cache/cache_service.dart';
import '../repositories/worker_repository.dart';
import '../repositories/employer_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.authService,
  }) {
    _init();
  }

  final AuthService authService;
  bool _isLoading = false;
  String? _error;

  // Cache infrastructure (initialized lazily)
  CacheService? _cache;
  WorkerRepository? _workerRepo;
  EmployerRepository? _employerRepo;

  User? get currentUser => authService.currentUser;
  bool get isAuthenticated => authService.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    authService.authStateChanges.listen((_) {
      notifyListeners();
    });
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      _cache = await CacheService.open('auth_cache');
      _workerRepo = WorkerRepository(_cache!);
      _employerRepo = EmployerRepository(_cache!);
    } catch (e) {
      if (kDebugMode) print('Failed to initialize cache: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();

      // Warm caches in the background
      final user = authService.currentUser;
      if (user != null && _workerRepo != null && _employerRepo != null) {
        _warmCaches(user);
      }

      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Warm caches in the background without blocking UI
  void _warmCaches(User user) {
    if (user.type == UserType.worker) {
      _workerRepo?.refreshJobs(user.id);
      _workerRepo?.refreshApplications(user.id);
      _workerRepo?.refreshProfile(user.id);
      _workerRepo?.refreshAttendance(user.id);
      _workerRepo?.refreshMetrics(user.id);
      if (kDebugMode) print('🔥 Warming worker caches for ${user.email}');
    } else {
      _employerRepo?.refreshBusinesses();
      _employerRepo?.refreshJobs(user.id);
      _employerRepo?.refreshApplications(user.id);
      _employerRepo?.refreshMetrics(user.id);
      _employerRepo?.refreshProfile(user.id);
      if (kDebugMode) print('🔥 Warming employer caches for ${user.email}');
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
    final dio = Dio(BaseOptions());

    final prefs = await SharedPreferences.getInstance();
    final authService = ApiAuthService(dio: dio, preferences: prefs);

    return AuthProvider(authService: authService);
  }
}
