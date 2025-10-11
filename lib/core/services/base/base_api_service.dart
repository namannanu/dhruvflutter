// ignore_for_file: require_trailing_commas

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class ApiWorkConnectException implements Exception {
  ApiWorkConnectException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiWorkConnectException($statusCode): $message';
}

abstract class BaseApiService {
  final Uri _baseUri;
  final http.Client _client;
  final bool _enableLogging;

  // Constants
  final int _maxLogBodyLength = 2000;
  static const String _loggerName = 'API';

  BaseApiService({
    required String baseUrl,
    bool enableLogging = false,
  })  : _baseUri = Uri.parse(baseUrl),
        _client = http.Client(),
        _enableLogging = enableLogging {
    if (_enableLogging) {
      developer.log(
        'Initializing API Service',
        name: _loggerName,
        error: {
          'baseUrl': baseUrl,
          'logging': enableLogging,
        },
      );
    }
  }

  /// Build request headers with optional auth token
  Map<String, String> headers({String? authToken, String? businessId}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authToken != null && authToken.isNotEmpty) {
      map['Authorization'] = 'Bearer $authToken';
    }

    if (businessId != null && businessId.isNotEmpty) {
      map['x-business-id'] = businessId;
    }

    return map;
  }

  /// Resolve a relative endpoint into a full URL
  Uri resolve(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return _baseUri;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }

    final cleanedPath =
        trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    final baseSegments =
        _baseUri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final pathSegments =
        cleanedPath.split('/').where((segment) => segment.isNotEmpty).toList();

    var overlap = 0;
    final maxOverlap =
        baseSegments.length < pathSegments.length
            ? baseSegments.length
            : pathSegments.length;

    while (overlap < maxOverlap &&
        baseSegments[overlap] == pathSegments[overlap]) {
      overlap++;
    }

    final mergedSegments = <String>[
      ...baseSegments,
      ...pathSegments.sublist(overlap),
    ];

    return _baseUri.replace(pathSegments: mergedSegments);
  }

  /// Resolve with query parameters.
  Uri resolveWithQuery(String path, {Map<String, dynamic>? query}) {
    final uri = resolve(path);
    if (query == null || query.isEmpty) {
      return uri;
    }

    final queryParameters = <String, String>{
      ...uri.queryParameters,
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };

    return uri.replace(queryParameters: queryParameters);
  }

  /// Decode JSON response into Map
  Map<String, dynamic> decodeJson(http.Response response) {
    logApiCall('DECODE', response.request?.url.path ?? '', response: response);
    _ensureSuccess(response);
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'data': decoded};
    throw ApiWorkConnectException(
      response.statusCode,
      'Unexpected response type: ${decoded.runtimeType}',
    );
  }

  /// Decode JSON response into List
  List<dynamic> decodeJsonList(http.Response response) {
    logApiCall('DECODE', response.request?.url.path ?? '', response: response);
    _ensureSuccess(response);
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);

    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      const keys = ['data', 'result', 'items', 'records', 'list'];
      for (final key in keys) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }

    throw ApiWorkConnectException(
      response.statusCode,
      'Unexpected list response type: ${decoded.runtimeType}',
    );
  }

  /// Ensure status code is 2xx
  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiWorkConnectException(response.statusCode, response.body);
  }

  /// Debug logging
  void logApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? requestBody,
    Map<String, String>? headers,
    http.Response? response,
    Object? error,
  }) {
    if (!_enableLogging) return;

    final url = resolve(endpoint);
    final Map<String, dynamic> logData = {
      'method': method,
      'url': url.toString(),
      if (headers != null) 'headers': headers,
      if (requestBody != null)
        'requestBody': _truncateLog(jsonEncode(requestBody)),
    };

    if (response != null) {
      logData['statusCode'] = response.statusCode;
      logData['responseHeaders'] = response.headers;
      try {
        if (response.body.isNotEmpty) {
          logData['responseBody'] = _truncateLog(response.body);
        }
      } catch (e) {
        logData['responseError'] = e.toString();
      }
    }

    if (error != null) {
      logData['error'] = error.toString();
    }

    String emoji;
    if (error != null) {
      emoji = '❌';
    } else if (response?.statusCode != null) {
      emoji = (response!.statusCode >= 200 && response.statusCode < 300)
          ? '✅'
          : '⚠️';
    } else {
      emoji = '➡️';
    }

    developer.log(
      '$emoji $method ${url.path}${response != null ? ' (${response.statusCode})' : ''}',
      name: _loggerName,
      error: logData,
    );
  }

  /// Truncate long logs to avoid spamming
  String _truncateLog(String text) {
    if (text.length <= _maxLogBodyLength) return text;
    return '${text.substring(0, _maxLogBodyLength)}... (truncated)';
  }

  /// HTTP client getter
  http.Client get client => _client;
}
