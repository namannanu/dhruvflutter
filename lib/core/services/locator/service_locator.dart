// ignore_for_file: directives_ordering, avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:talent/core/models/jwt_payload.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/features/auth/services/api_auth_service.dart';
import 'package:talent/features/business/services/api_business_service.dart';
import 'package:talent/features/employer/services/api_employer_service.dart';
import 'package:talent/features/employer/services/attendance_api_service.dart';
import 'package:talent/features/job/services/api_job_service.dart';
import 'package:talent/features/messaging/services/api_messaging_service.dart';
import 'package:talent/features/shift/services/api_shift_service.dart';
import 'package:talent/features/worker/services/api_worker_service.dart';
import 'package:talent/features/worker/services/api_worker_preferences_service.dart';
import 'package:talent/services/auth_token_manager.dart';

import '../cache/worker_cache_repository.dart';

class ServiceLocator {
  // 🔑 Singleton instance
  static ServiceLocator? _instance;
  static ServiceLocator get instance {
    if (_instance == null) {
      throw Exception(
          'ServiceLocator not initialized! Call ServiceLocator.create() first.');
    }
    return _instance!;
  }

  // Factory initializer
  static Future<ServiceLocator> create({
    required String baseUrl,
    String? authToken,
    bool enableLogging = false,
  }) async {
    final workerCache = await WorkerCacheRepository.create();
    _instance = ServiceLocator(
      baseUrl: baseUrl,
      authToken: authToken,
      enableLogging: enableLogging,
      workerCache: workerCache,
    );
    return _instance!;
  }

  ServiceLocator({
    required String baseUrl,
    String? authToken,
    bool enableLogging = false,
    required this.workerCache,
  })  : _baseUrl = baseUrl,
        _authToken = authToken,
        _enableLogging = enableLogging {
    _initializeServices();
  }

  final String _baseUrl;
  String? _authToken;
  User? _currentUser;
  final bool _enableLogging;
  final WorkerCacheRepository workerCache;
  String? _cachedBusinessId;

  // Expose configuration
  String get apiUrl => _baseUrl;

  // Expose auth token for services
  Future<String?> getAuthToken() async {
    return _authToken;
  }

  late ApiAuthService auth;
  late ApiWorkerService worker;
  late ApiWorkerPreferencesService workerPreferences;
  late ApiEmployerService employer;
  late ApiBusinessService business;
  late ApiJobService job;
  late ApiShiftService shift;
  late ApiMessagingService messaging;
  late AttendanceApiService attendance;

  void _initializeServices() {
    auth = ApiAuthService(
      baseUrl: _baseUrl,
      initialAuthToken: _authToken,
      enableLogging: _enableLogging,
      workerCache: workerCache,
    );

    worker = ApiWorkerService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
      cache: workerCache,
    );

    workerPreferences = ApiWorkerPreferencesService(this);

    employer = ApiEmployerService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
    );

    business = ApiBusinessService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
    );

    job = ApiJobService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
    );

    shift = ApiShiftService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
    );

    messaging = ApiMessagingService(
      baseUrl: _baseUrl,
      enableLogging: _enableLogging,
    );

    attendance = AttendanceApiService(
      baseUrl: _baseUrl,
    );
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    debugPrint('🔑 updateAuthToken called with: $_authToken');
    _initializeServices(); // rebuild services with the latest token
    _refreshCachedBusinessId();
    if (token != null && token.isNotEmpty) {
      unawaited(AuthTokenManager.instance.setManualToken(token));
    }
  }

  void updateCurrentUser(User? user) {
    _currentUser = user;
    debugPrint('👤 updateCurrentUser called with: ${user?.email}');
    _refreshCachedBusinessId();
    if (user != null && _authToken != null && _authToken!.isNotEmpty) {
      final map = {
        'user': user.toJson(),
        'ownedBusinesses': user.ownedBusinesses.map((b) => b.toJson()).toList(),
        'teamBusinesses': user.teamBusinesses.map((b) => b.toJson()).toList(),
      };
      AuthTokenManager.instance.storeLoginResponse({
        'token': _authToken,
        'data': map,
      }).catchError((error) {
        debugPrint('Failed to sync user cache: $error');
      });
    }
  }

  // Getters for ApiBusinessService, authToken, and currentUser
  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  String? get currentUserBusinessId {
    final direct = _normalizeBusinessId(
      _currentUser?.selectedBusinessId ?? auth.currentUser?.selectedBusinessId,
    );
    if (direct != null) {
      _cachedBusinessId = direct;
      return direct;
    }

    if (_cachedBusinessId != null && _cachedBusinessId!.isNotEmpty) {
      return _cachedBusinessId;
    }

    final tokenBusiness = _extractBusinessIdFromToken();
    if (tokenBusiness != null) {
      _cachedBusinessId = tokenBusiness;
      return tokenBusiness;
    }

    return null;
  }

  void _refreshCachedBusinessId() {
    final fromUser = _normalizeBusinessId(
      _currentUser?.selectedBusinessId ?? auth.currentUser?.selectedBusinessId,
    );

    final tokenBusiness = _extractBusinessIdFromToken();

    _cachedBusinessId = fromUser ?? tokenBusiness ?? _cachedBusinessId;
  }

  String? _extractBusinessIdFromToken() {
    final payload = JwtPayload.tryParse(_authToken);
    if (payload == null) return null;

    final possibleKeys = <String>[
      'selectedBusiness',
      'selectedBusinessId',
      'businessId',
      'business',
    ];

    for (final key in possibleKeys) {
      final candidate = _normalizeBusinessId(payload[key]);
      if (candidate != null) {
        return candidate;
      }
    }

    return null;
  }

  String? _normalizeBusinessId(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is User) {
      return _normalizeBusinessId(value.selectedBusinessId);
    }

    if (value is Map<String, dynamic>) {
      const keys = [
        'businessId',
        'selectedBusiness',
        'selectedBusinessId',
        'id',
        '_id',
      ];

      for (final key in keys) {
        final nested = _normalizeBusinessId(value[key]);
        if (nested != null) {
          return nested;
        }
      }
    }

    if (value is Iterable) {
      for (final entry in value) {
        final nested = _normalizeBusinessId(entry);
        if (nested != null) return nested;
      }
    }

    return null;
  }
}
