// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:talent/core/services/base/base_api_service.dart';

class EnhancedApiService extends BaseApiService {
  static const Duration _requestTimeout = Duration(seconds: 30);
  final Map<String, _CacheEntry> _cache = {};
  Timer? _cacheCleanupTimer;

  EnhancedApiService({
    required super.baseUrl,
    super.enableLogging = true,
  }) {
    _initializeService();
  }

  void _initializeService() {
    developer.log('🚀 Initializing Enhanced API Service', name: 'API');
    _setupCacheCleanup();
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanCache(),
    );
  }

  void _cleanCache() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => entry.isExpired(now));
  }

  @override
  Future<http.Response> get(
    dynamic endpoint, {
    Map<String, String>? headers,
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    final String endpointStr = endpoint.toString();
    final cacheKey = '$endpointStr${headers.toString()}';

    if (useCache) {
      final cachedResponse = _cache[cacheKey]?.data as http.Response?;
      if (cachedResponse != null &&
          !_cache[cacheKey]!.isExpired(DateTime.now())) {
        developer.log('📦 Returning cached response for $endpoint',
            name: 'API');
        return cachedResponse;
      }
    }

    return _safeApiCall('GET $endpoint', () async {
      final response = await super.get(endpoint, headers: headers);

      if (useCache && _isSuccessful(response)) {
        _cache[cacheKey] = _CacheEntry(
          response,
          cacheDuration ?? const Duration(minutes: 5),
        );
      }

      return response;
    });
  }

  @override
  Future<http.Response> post(
    dynamic endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _safeApiCall('POST $endpoint', () async {
      return super.post(endpoint, body: body, headers: headers);
    });
  }

  Future<T> _safeApiCall<T>(
      String operation, Future<T> Function() apiCall) async {
    try {
      developer.log('🌐 Starting $operation', name: 'API');

      final result = await apiCall().timeout(_requestTimeout);

      developer.log('✅ Completed $operation', name: 'API');
      return result;
    } on TimeoutException {
      developer.log('⏰ $operation timed out', name: 'API');
      throw ApiWorkConnectException(408, 'Request timed out');
    } on SocketException catch (e) {
      developer.log('🔌 Network error in $operation', name: 'API', error: e);
      throw ApiWorkConnectException(0, 'Network error: ${e.message}');
    } on HttpException catch (e) {
      developer.log('🌐 HTTP error in $operation', name: 'API', error: e);
      throw ApiWorkConnectException(0, 'HTTP error: ${e.message}');
    } catch (e, stack) {
      developer.log(
        '❌ Error in $operation',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  bool _isSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  @override
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _cache.clear();
    super.dispose();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration duration)
      : expiresAt = DateTime.now().add(duration);

  bool isExpired(DateTime now) => now.isAfter(expiresAt);
}
