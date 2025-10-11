// ignore_for_file: strict_raw_type, directives_ordering, require_trailing_commas, use_super_parameters

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'https://dhruvbackend.vercel.app/api'; // API base URL
  final Dio _dio;

  ApiService({required String baseUrl, required bool enableLogging}) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout =
        const Duration(seconds: 15); // Increased from 5 seconds
    _dio.options.receiveTimeout =
        const Duration(seconds: 15); // Increased from 3 seconds

    // Add interceptors for logging, auth token, etc.
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  void addAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Exception _handleError(DioException error) {
    debugPrint('API Error: ${error.type} - ${error.message}');
    if (error.response != null) {
      debugPrint('Response data: ${error.response?.data}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            'Connection timed out. Please check your internet connection and try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ??
            error.response?.data['error'] ??
            'Server error (Status code: $statusCode)';

        if (statusCode == 401) {
          return UnauthorizedException(message.toString());
        }
        return ApiException(message.toString());
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
      case DioExceptionType.connectionError:
        return ApiException(
            'No internet connection. Please check your network and try again.');
      default:
        return ApiException('Something went wrong. Please try again later.');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message);
}
