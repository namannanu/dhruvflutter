// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:talent/core/services/locator/service_locator.dart';

class HttpService {
  final String baseUrl = 'https://dhruvbackend.vercel.app';
  static const Duration _timeout = Duration(seconds: 30);

  String get publicBaseUrl => baseUrl;

  String? get _authToken {
    final token = ServiceLocator.instance.authToken;
    developer.log(
      '🔑 Auth Token Status',
      name: 'API',
      error: {'present': token != null},
    );
    return token;
  }

  Map<String, String> buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Map<String, String> get _headers => buildHeaders();

  Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }

    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final finalUri = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;
      final requestHeaders = headers != null
          ? buildHeaders(extraHeaders: headers)
          : _headers;

      developer.log(
        '🌐 Making GET request',
        name: 'API',
        error: {
          'url': finalUri.toString(),
          'hasAuth': requestHeaders.containsKey('Authorization'),
        },
      );

      final response = await http
          .get(finalUri, headers: requestHeaders)
          .timeout(_timeout);

      developer.log(
        '📥 Received response',
        name: 'API',
        error: {'status': response.statusCode, 'length': response.body.length},
      );

      return response;
    } catch (e, stack) {
      developer.log(
        '❌ Request failed',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = headers != null
          ? buildHeaders(extraHeaders: headers)
          : _headers;

      developer.log(
        '🌐 Making POST request',
        name: 'API',
        error: {
          'url': uri.toString(),
          'hasAuth': requestHeaders.containsKey('Authorization'),
          'bodyLength': body?.toString().length ?? 0,
        },
      );

      final response = await http
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      developer.log(
        '📥 Received response',
        name: 'API',
        error: {'status': response.statusCode, 'length': response.body.length},
      );

      return response;
    } catch (e, stack) {
      developer.log(
        '❌ Request failed',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = headers != null
          ? buildHeaders(extraHeaders: headers)
          : _headers;

      developer.log(
        '🌐 Making PATCH request',
        name: 'API',
        error: {
          'url': uri.toString(),
          'hasAuth': requestHeaders.containsKey('Authorization'),
          'bodyLength': body?.toString().length ?? 0,
        },
      );

      final response = await http
          .patch(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      developer.log(
        '📥 Received response',
        name: 'API',
        error: {'status': response.statusCode, 'length': response.body.length},
      );

      return response;
    } catch (e, stack) {
      developer.log(
        '❌ Request failed',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
