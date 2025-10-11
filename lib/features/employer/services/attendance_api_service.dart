import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talent/core/models/attendance.dart';

class AttendanceApiService {
  final String baseUrl;
  final http.Client _client = http.Client();

  AttendanceApiService({required this.baseUrl});

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    String? authToken,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    late http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {'data': decoded};
      }
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get attendance dashboard data for employers
  /// Corresponds to backend: GET /attendance/management
  Future<Map<String, dynamic>> getAttendanceDashboard({
    required String authToken,
    DateTime? date,
    String? status,
    String? workerId,
    String? workerName,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
    String? employmentStatus,
    bool includeEmploymentDetails = false,
  }) async {
    final queryParams = <String, String>{};
    
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }
    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }
    if (workerId != null) {
      queryParams['workerId'] = workerId;
    }
    if (workerName != null) {
      queryParams['workerName'] = workerName;
    }
    if (businessId != null) {
      queryParams['businessId'] = businessId;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }
    if (employmentStatus != null) {
      queryParams['employmentStatus'] = employmentStatus;
    }
    if (includeEmploymentDetails) {
      queryParams['includeEmploymentDetails'] = 'true';
    }

    return await _makeRequest(
      'GET',
      '/attendance',
      authToken: authToken,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get attendance management view (for employers)
  /// Corresponds to backend: GET /attendance/management
  Future<Map<String, dynamic>> getManagementView({
    required String authToken,
    DateTime? date,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }
    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }

    return await _makeRequest(
      'GET',
      '/attendance/management',
      authToken: authToken,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Schedule attendance record (for employers)
  /// Corresponds to backend: POST /attendance
  Future<Map<String, dynamic>> scheduleAttendance({
    required String authToken,
    required String workerId,
    required String jobId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    double? hourlyRate,
    String? notes,
  }) async {
    final body = {
      'worker': workerId,
      'job': jobId,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (notes != null) 'notes': notes,
    };

    return await _makeRequest(
      'POST',
      '/attendance',
      authToken: authToken,
      body: body,
    );
  }

  /// Mark attendance as complete (for employers)
  /// Corresponds to backend: POST /attendance/{recordId}/mark-complete
  Future<Map<String, dynamic>> markComplete({
    required String authToken,
    required String recordId,
  }) async {
    return await _makeRequest(
      'POST',
      '/attendance/$recordId/mark-complete',
      authToken: authToken,
      body: {},
    );
  }

  /// Update attendance hours (for employers)
  /// Corresponds to backend: PATCH /attendance/{recordId}/hours
  Future<Map<String, dynamic>> updateHours({
    required String authToken,
    required String recordId,
    required double totalHours,
    double? hourlyRate,
  }) async {
    final body = {
      'totalHours': totalHours,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
    };

    return await _makeRequest(
      'PATCH',
      '/attendance/$recordId/hours',
      authToken: authToken,
      body: body,
    );
  }

  /// Search workers by name (for employers)
  /// Corresponds to backend: GET /attendance/search/workers
  Future<List<Map<String, dynamic>>> searchWorkersByName({
    required String authToken,
    required String name,
  }) async {
    final queryParams = {'name': name};

    final response = await _makeRequest(
      'GET',
      '/attendance/search/workers',
      authToken: authToken,
      queryParams: queryParams,
    );

    final data = response['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  /// Get worker employment timeline (for employers)
  /// Corresponds to backend: GET /attendance/timeline/worker/{workerId}
  Future<Map<String, dynamic>> getWorkerEmploymentTimeline({
    required String authToken,
    required String workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    return await _makeRequest(
      'GET',
      '/attendance/timeline/worker/$workerId',
      authToken: authToken,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get workers employed on a specific date (for employers)
  /// Corresponds to backend: GET /attendance/employed-on/{date}
  Future<List<Map<String, dynamic>>> getWorkersEmployedOnDate({
    required String authToken,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _makeRequest(
      'GET',
      '/attendance/employed-on/$dateStr',
      authToken: authToken,
    );

    final data = response['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  /// Clock in to attendance record (for workers)
  /// Corresponds to backend: POST /attendance/{recordId}/clock-in
  Future<Map<String, dynamic>> clockIn({
    required String authToken,
    required String recordId,
  }) async {
    return await _makeRequest(
      'POST',
      '/attendance/$recordId/clock-in',
      authToken: authToken,
      body: {},
    );
  }

  /// Clock out of attendance record (for workers)
  /// Corresponds to backend: POST /attendance/{recordId}/clock-out
  Future<Map<String, dynamic>> clockOut({
    required String authToken,
    required String recordId,
  }) async {
    return await _makeRequest(
      'POST',
      '/attendance/$recordId/clock-out',
      authToken: authToken,
      body: {},
    );
  }

  /// Update attendance record (for employers)
  /// Corresponds to backend: PATCH /attendance/{recordId}
  Future<Map<String, dynamic>> updateAttendance({
    required String authToken,
    required String recordId,
    AttendanceStatus? status,
    double? totalHours,
    double? earnings,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    
    if (status != null) {
      body['status'] = status.name.replaceAll('_', '-');
    }
    if (totalHours != null) {
      body['totalHours'] = totalHours;
    }
    if (earnings != null) {
      body['earnings'] = earnings;
    }
    if (notes != null) {
      body['notes'] = notes;
    }

    return await _makeRequest(
      'PATCH',
      '/attendance/$recordId',
      authToken: authToken,
      body: body,
    );
  }

  void dispose() {
    _client.close();
  }
}