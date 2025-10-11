// ignore_for_file: directives_ordering, avoid_print

import 'package:flutter/foundation.dart';
import 'package:talent/core/models/jwt_payload.dart';
import 'package:talent/core/models/user.dart';
import 'package:talent/features/auth/services/api_auth_service.dart';
import 'package:talent/features/business/services/api_business_service.dart';
import 'package:talent/features/employer/services/api_employer_service.dart';
import 'package:talent/features/job/services/api_job_service.dart';
import 'package:talent/features/messaging/services/api_messaging_service.dart';
import 'package:talent/features/shift/services/api_shift_service.dart';
import 'package:talent/features/worker/services/api_worker_service.dart';

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

  late final ApiAuthService auth;
  late final ApiWorkerService worker;
  late final ApiEmployerService employer;
  late final ApiBusinessService business;
  late final ApiJobService job;
  late final ApiShiftService shift;
  late final ApiMessagingService messaging;

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
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    debugPrint('🔑 updateAuthToken called with: $_authToken');
    _initializeServices(); // rebuild services with the latest token
    _refreshCachedBusinessId();
  }

  void updateCurrentUser(User? user) {
    _currentUser = user;
    debugPrint('👤 updateCurrentUser called with: ${user?.email}');
    _refreshCachedBusinessId();
  }

  // Getters for ApiBusinessService, authToken, and currentUser
  String? get authToken => _authToken;
  User? get currentUser => _currentUser;
  String? get currentUserBusinessId {
    final direct = _normalizeBusinessId(
      _currentUser?.selectedBusinessId ??
          auth.currentUser?.selectedBusinessId,
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
      _currentUser?.selectedBusinessId ??
          auth.currentUser?.selectedBusinessId,
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
