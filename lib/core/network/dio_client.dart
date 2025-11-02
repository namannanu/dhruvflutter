import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/auth_token_manager.dart';

class DioClient {
  static Dio? _dio;
  static Future<Dio>? _initializing;
  static CacheOptions? _cacheOptions;
  static CacheStore? _cacheStore;

  static Future<Dio> instance() {
    if (_dio != null) {
      return Future<Dio>.value(_dio);
    }

    _initializing ??= _createInstance();
    return _initializing!;
  }

  static Future<Dio> _createInstance() async {
    if (_cacheStore == null) {
      if (kIsWeb) {
        _cacheStore = MemCacheStore();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        _cacheStore = HiveCacheStore('${directory.path}/dio_cache');
      }
    }
    _cacheOptions ??= CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request, // Use cache-first approach but still try network
      hitCacheOnErrorExcept: [401, 403], // Use cache on server errors (500, etc.)
      maxStale: const Duration(days: 7),
      priority: CachePriority.high, // Prioritize cache for faster responses
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
    );    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5), // Reduced for faster failure
        receiveTimeout: const Duration(seconds: 10), // Much shorter for faster UI
        sendTimeout: const Duration(seconds: 8), // Reduced
        headers: const {
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json',
        },
      ),
    )
      ..interceptors.add(DioCacheInterceptor(options: _cacheOptions!))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (requestOptions, handler) async {
            final token = await AuthTokenManager.instance.getAuthToken();
            if (token != null && token.isNotEmpty) {
              requestOptions.headers['Authorization'] = 'Bearer $token';
            }

            requestOptions.extra = {
              ...requestOptions.extra,
              ..._cacheOptions!.toExtra(),
            };

            if (kDebugMode) {
              print(
                  '🌐 [REQUEST] ${requestOptions.method} ${requestOptions.uri}');
            }

            handler.next(requestOptions);
          },
          onResponse: (response, handler) {
            if (kDebugMode) {
              print(
                  '✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
            }
            handler.next(response);
          },
          onError: (error, handler) {
            if (kDebugMode) {
              print(
                  '❌ [ERROR] ${error.response?.statusCode} ${error.requestOptions.uri} - ${error.message}');
            }
            handler.next(error);
          },
        ),
      );
    dio.interceptors.add(RetryOnTimeoutInterceptor(dio));

    _dio = dio;
    _initializing = null;
    return dio;
  }

  /// Reset the Dio instance (useful for logout or token refresh)
  static Future<void> reset() async {
    _dio?.close(force: true);
    _dio = null;
    _initializing = null;
  }
}

class RetryOnTimeoutInterceptor extends Interceptor {
  RetryOnTimeoutInterceptor(this._dio, {this.maxRetries = 1});

  final Dio _dio;
  final int maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    final currentRetries = (requestOptions.extra['retry_count'] as int?) ?? 0;
    if (currentRetries >= maxRetries) {
      handler.next(err);
      return;
    }

    try {
      requestOptions.extra['retry_count'] = currentRetries + 1;
      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }
}
