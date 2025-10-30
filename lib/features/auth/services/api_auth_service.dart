// ignore_for_file: directives_ordering, unused_field, annotate_overrides, unawaited_futures, require_trailing_commas

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/cache/worker_cache_repository.dart';
import 'package:talent/services/auth_token_manager.dart';

import 'api_service.dart';
import 'auth_service.dart';

class ApiAuthService implements AuthService {
  ApiAuthService({
    required this.baseUrl,
    this.initialAuthToken,
    this.enableLogging = false,
    WorkerCacheRepository? workerCache,
  }) : _workerCache = workerCache {
    _initCompleter = Completer<void>();
    _initialize();
  }

  final String baseUrl;
  final String? initialAuthToken;
  final bool enableLogging;

  late final ApiService _api;
  late final SharedPreferences _prefs;
  WorkerCacheRepository? _workerCache;

  User? _currentUser;
  String? _authToken;
  final _authStateController = StreamController<bool>.broadcast();
  bool _isInitialized = false;
  late final Completer<void> _initCompleter;

  WorkerProfile? _lastWorkerProfile;
  WorkerDashboardMetrics? _lastWorkerMetrics;

  static const _userKey = 'user';
  static const _tokenKey = 'authToken';

  Future<void> _initialize() async {
    _api = ApiService(baseUrl: baseUrl, enableLogging: enableLogging);
    _prefs = await SharedPreferences.getInstance();
    _workerCache ??= await WorkerCacheRepository.create();

    if (initialAuthToken != null) {
      _authToken = initialAuthToken;
      _api.addAuthToken(initialAuthToken!);
    } else {
      await _loadStoredAuth();
    }

    _lastWorkerProfile = _workerCache?.readProfile();
    _lastWorkerMetrics = _workerCache?.readMetrics();

    _isInitialized = true;
    _authStateController.add(_currentUser != null);
    _initCompleter.complete();
  }

  Future<void> ready() => _initCompleter.future;

  Future<void> _loadStoredAuth() async {
    try {
      final storedToken = _prefs.getString(_tokenKey);
      final userJson = _prefs.getString(_userKey);

      if (storedToken != null && userJson != null) {
        _authToken = storedToken;
        _api.addAuthToken(storedToken);
        _currentUser =
            User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _authStateController.add(true);

        try {
          final parsedUser = jsonDecode(userJson) as Map<String, dynamic>;
          await AuthTokenManager.instance.storeLoginResponse({
            'token': storedToken,
            'data': {
              'user': parsedUser,
              'ownedBusinesses': parsedUser['ownedBusinesses'],
              'teamBusinesses': parsedUser['teamBusinesses'],
            },
          });
        } catch (error) {
          debugPrint('Unable to sync token cache: $error');
        }
      }
    } catch (error) {
      debugPrint('Error loading stored auth: $error');
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  String? get authToken => _authToken;

  WorkerProfile? get cachedWorkerProfile =>
      _lastWorkerProfile ?? _workerCache?.readProfile();

  WorkerDashboardMetrics? get cachedWorkerMetrics =>
      _lastWorkerMetrics ?? _workerCache?.readMetrics();

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  @override
  bool get isInitializing => !_isInitialized;

  @override
  Future<User> login({
    required String email,
    required String password,
    String? type,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email,
        'password': password,
        if (type != null) 'type': type,
      };

      final response = await _api.post(
        '/auth/login',
        data: payload,
      );

      final responseData = response.data;
      final userData = responseData['data']?['user'] as Map<String, dynamic>? ??
          responseData['user'] as Map<String, dynamic>?;
      final token = responseData['token'] as String? ??
          responseData['data']?['token'] as String?;
      final authData = responseData['data'] as Map<String, dynamic>?;
      final workerProfileJson =
          responseData['data']?['workerProfile'] as Map<String, dynamic>?;
      final metricsJson =
          responseData['data']?['metrics'] as Map<String, dynamic>?;

      if (userData == null || token == null) {
        throw Exception('Invalid response format from server');
      }

      final requestedType = _parseUserType(type);
      final apiType = _parseUserType(userData['userType']);
      final resolvedType = requestedType ?? apiType ?? UserType.employer;
      final roleSet = <UserType>{
        if (apiType != null) apiType,
        if (requestedType != null) requestedType,
      };
      final selectedBusinessId =
          _resolveSelectedBusinessId(userData, authData);
      final ownedBusinesses = BusinessAssociation.parseList(
        (authData?['ownedBusinesses'] ?? userData['ownedBusinesses']) as List<dynamic>?,
      );
      final teamBusinesses = BusinessAssociation.parseList(
        (authData?['teamBusinesses'] ?? userData['teamBusinesses']) as List<dynamic>?,
      );

      final user = User(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        firstName: userData['firstName']?.toString() ?? '',
        lastName: userData['lastName']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        type: resolvedType,
        freeJobsPosted: (userData['freeJobsPosted'] as num?)?.toInt() ?? 0,
        freeApplicationsUsed:
            (userData['freeApplicationsUsed'] as num?)?.toInt() ?? 0,
        isPremium: userData['premium'] == true,
        selectedBusinessId: selectedBusinessId,
        roles: roleSet.isNotEmpty ? roleSet.toList() : <UserType>[resolvedType],
        ownedBusinesses: ownedBusinesses,
        teamBusinesses: teamBusinesses,
      );

      await _storeAuthPayload(
        user: user,
        token: token,
        rawAuthData: authData,
        workerProfileJson: workerProfileJson,
        metricsJson: metricsJson,
      );
      return user;
    } catch (error) {
      throw Exception('Login failed: ${error.toString()}');
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
      final response = await _api.post(
        '/auth/signup',
        data: {
          'firstName': firstname,
          'lastName': lastname,
          'email': email,
          'password': password,
          'userType': userType == UserType.worker ? 'worker' : 'employer',
        },
      );

      final responseData = response.data;
      final userData = responseData['data']?['user'] as Map<String, dynamic>? ??
          responseData['user'] as Map<String, dynamic>?;
      final token = responseData['token'] as String? ??
          responseData['data']?['token'] as String?;
      final authData = responseData['data'] as Map<String, dynamic>?;
      final workerProfileJson =
          responseData['data']?['workerProfile'] as Map<String, dynamic>?;
      final metricsJson =
          responseData['data']?['metrics'] as Map<String, dynamic>?;

      if (userData == null || token == null) {
        throw Exception('Invalid response format from server');
      }

      final requestedType = userType;
      final apiType = _parseUserType(userData['userType']);
      final resolvedType = requestedType;
      final roleSet = <UserType>{
        if (apiType != null) apiType,
        requestedType,
      };
      final selectedBusinessId =
          _resolveSelectedBusinessId(userData, authData);
      final ownedBusinesses = BusinessAssociation.parseList(
        (authData?['ownedBusinesses'] as List<dynamic>?) ??
            (userData['ownedBusinesses'] as List<dynamic>?),
      );
      final teamBusinesses = BusinessAssociation.parseList(
        (authData?['teamBusinesses'] as List<dynamic>?) ??
            (userData['teamBusinesses'] as List<dynamic>?),
      );

      final user = User(
        id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
        firstName: userData['firstName']?.toString() ?? '',
        lastName: userData['lastName']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        type: resolvedType,
        freeJobsPosted: (userData['freeJobsPosted'] as num?)?.toInt() ?? 0,
        freeApplicationsUsed:
            (userData['freeApplicationsUsed'] as num?)?.toInt() ?? 0,
        isPremium: userData['premium'] == true,
        selectedBusinessId: selectedBusinessId,
        roles: roleSet.toList(),
        ownedBusinesses: ownedBusinesses,
        teamBusinesses: teamBusinesses,
      );

      await _storeAuthPayload(
        user: user,
        token: token,
        rawAuthData: authData,
        workerProfileJson: workerProfileJson,
        metricsJson: metricsJson,
      );
      return user;
    } catch (error) {
      throw Exception('Signup failed: ${error.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await _api.post('/auth/logout');
      }
    } catch (error) {
      debugPrint('Error during logout: $error');
    } finally {
      _currentUser = null;
      _authToken = null;
      _lastWorkerProfile = null;
      _lastWorkerMetrics = null;
      _api.removeAuthToken();

      await _prefs.remove(_userKey);
      await _prefs.remove(_tokenKey);
      await _workerCache?.clearWorkerData();
      await AuthTokenManager.instance.clearAll();

      _authStateController.add(false);
    }
  }

  @override
  void dispose() {
    _authStateController.close();
  }

  Future<void> _storeAuthPayload({
    required User user,
    required String token,
    Map<String, dynamic>? rawAuthData,
    Map<String, dynamic>? workerProfileJson,
    Map<String, dynamic>? metricsJson,
  }) async {
    _currentUser = user;
    _authToken = token;
    _api.addAuthToken(token);

    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await _prefs.setString(_tokenKey, token);

    WorkerProfile? profile;
    if (workerProfileJson != null) {
      try {
        profile = WorkerProfile.fromJson(workerProfileJson);
        _lastWorkerProfile = profile;
        await _workerCache?.writeProfile(profile);
      } catch (error) {
        debugPrint('Failed to parse worker profile: $error');
      }
    }

    WorkerDashboardMetrics? metrics;
    if (metricsJson != null) {
      try {
        metrics = WorkerDashboardMetrics.fromJson(metricsJson);
      } catch (error) {
        debugPrint('Failed to parse worker metrics from auth payload: $error');
      }
    }

    metrics ??= _deriveMetrics(user, profile);

    if (metrics != null) {
      _lastWorkerMetrics = metrics;
      await _workerCache?.writeMetrics(metrics);
    }

    _authStateController.add(true);

    try {
      final ownedBusinesses = rawAuthData?['ownedBusinesses'] as List<dynamic>? ??
          user.ownedBusinesses.map((b) => b.toJson()).toList();
      final teamBusinesses = rawAuthData?['teamBusinesses'] as List<dynamic>? ??
          user.teamBusinesses.map((b) => b.toJson()).toList();

      await AuthTokenManager.instance.storeLoginResponse({
        'token': token,
        'data': {
          'user': user.toJson(),
          'ownedBusinesses': ownedBusinesses,
          'teamBusinesses': teamBusinesses,
          if (rawAuthData?['tokenExpiry'] != null)
            'tokenExpiry': rawAuthData?['tokenExpiry'],
        },
      });
    } catch (error, stackTrace) {
      debugPrint('AuthTokenManager.storeLoginResponse failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  WorkerDashboardMetrics? _deriveMetrics(
    User user,
    WorkerProfile? profile,
  ) {
    if (profile == null) {
      return WorkerDashboardMetrics(
        availableJobs: 0,
        activeApplications: 0,
        upcomingShifts: 0,
        completedHours: 0,
        earningsThisWeek: 0,
        freeApplicationsRemaining: (3 - user.freeApplicationsUsed).clamp(0, 3),
        isPremium: user.isPremium,
      );
    }

    return WorkerDashboardMetrics(
      availableJobs: 0,
      activeApplications: 0,
      upcomingShifts: 0,
      completedHours: 0,
      earningsThisWeek: profile.weeklyEarnings,
      freeApplicationsRemaining: (3 - user.freeApplicationsUsed).clamp(0, 3),
      isPremium: user.isPremium,
    );
  }

  String? _resolveSelectedBusinessId(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? authPayload,
  ) {
    String? pick(dynamic value) {
      if (value == null) return null;
      final stringified = value.toString().trim();
      return stringified.isEmpty ? null : stringified;
    }

    String? candidate = pick(userData?['selectedBusiness']);
    candidate ??= pick(userData?['selectedBusinessId']);
    candidate ??= pick(userData?['business']);
    candidate ??= pick(userData?['businessId']);

    candidate ??= pick(authPayload?['selectedBusiness']);
    candidate ??= pick(authPayload?['selectedBusinessId']);
    candidate ??= pick(authPayload?['business']);
    candidate ??= pick(authPayload?['businessId']);

    if (candidate != null) {
      return candidate;
    }

    candidate = _extractBusinessIdFromCollection(authPayload?['ownedBusinesses']);
    candidate ??= _extractBusinessIdFromCollection(authPayload?['teamBusinesses']);
    candidate ??= _extractBusinessId(authPayload?['employerProfile']);

    return candidate;
  }

  String? _extractBusinessIdFromCollection(dynamic raw) {
    if (raw == null) return null;

    if (raw is List) {
      for (final entry in raw) {
        final id = _extractBusinessId(entry);
        if (id != null) {
          return id;
        }
      }
      return null;
    }

    if (raw is Map<String, dynamic>) {
      return _extractBusinessId(raw);
    }

    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return null;
  }

  String? _extractBusinessId(dynamic entry) {
    if (entry == null) return null;

    if (entry is String) {
      final trimmed = entry.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }

    if (entry is Map<String, dynamic>) {
      const directKeys = ['businessId', 'selectedBusiness', 'selectedBusinessId', 'id', '_id'];
      for (final key in directKeys) {
        final value = entry[key];
        if (value != null) {
          final candidate = value.toString().trim();
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }

      final nestedBusiness = entry['business'];
      if (nestedBusiness is String) {
        final trimmed = nestedBusiness.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }

      if (nestedBusiness is Map<String, dynamic>) {
        const nestedKeys = ['id', '_id', 'businessId', 'selectedBusiness'];
        for (final key in nestedKeys) {
          final value = nestedBusiness[key];
          if (value != null) {
            final candidate = value.toString().trim();
            if (candidate.isNotEmpty) {
              return candidate;
            }
          }
        }
      }
    }

    return null;
  }

  UserType? _parseUserType(dynamic raw) {
    if (raw == null) return null;
    if (raw is UserType) return raw;
    final normalized = raw.toString().trim().toLowerCase();
    switch (normalized) {
      case 'worker':
        return UserType.worker;
      case 'employer':
        return UserType.employer;
    }
    return null;
  }
}
