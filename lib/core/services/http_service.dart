// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talent/core/services/locator/service_locator.dart';

class HttpService {
  final String baseUrl = 'https://dhruvbackend.vercel.app';

  // Public getter for debugging
  String get publicBaseUrl => baseUrl;

  String? get _authToken {
    final token = ServiceLocator.instance.authToken;
    print(
        'HttpService: Auth token: ${token != null ? "***${token.substring(token.length - 8)}" : "null"}');
    return token;
  }

  /// Exposed so callers can add custom headers while preserving auth.
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

    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$cleanEndpoint');
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParams, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);
    final finalUri =
        queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

    final requestHeaders = headers != null
        ? buildHeaders(extraHeaders: headers)
        : _headers;

    print('HTTP GET: $finalUri');
    print('Auth token present: ${_authToken != null}');
    print('Headers: $requestHeaders');

    final response = await http.get(finalUri, headers: requestHeaders);

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');

    return response;
  }

  Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);

    final requestHeaders = headers != null
        ? buildHeaders(extraHeaders: headers)
        : _headers;

    return await http.post(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);

    final requestHeaders = headers != null
        ? buildHeaders(extraHeaders: headers)
        : _headers;

    return await http.patch(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);

    final requestHeaders = headers != null
        ? buildHeaders(extraHeaders: headers)
        : _headers;

    return await http.put(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);

    final requestHeaders = headers != null
        ? buildHeaders(extraHeaders: headers)
        : _headers;

    return await http.delete(
      uri,
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
