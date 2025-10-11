// ignore_for_file: require_trailing_commas

import 'dart:convert';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/shift/services/shift_service.dart';

class ApiShiftService extends BaseApiService implements ShiftService {

  ApiShiftService({
    required super.baseUrl,
    super.enableLogging,
  });

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  @override
  Future<List<SwapRequest>> fetchSwapRequests(String workerId) async {
    try {
      final response = await client.get(
        resolveWithQuery(
          '/shift-swaps',
          query: {'workerId': workerId},
        ),
        headers: headers(authToken: _authToken),
      );

      final json = decodeJson(response);
      final data = _listOrEmpty(json['swapRequests'] ?? json['data']);
      if (data.isEmpty) {
        return const [];
      }
      return data.map(_parseSwapRequest).toList();
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<SwapRequest> createSwapRequest({
    required String shiftId,
    required String fromWorkerId,
    required String toWorkerId,
    String? message,
  }) async {
    const endpoint = '/shift-swaps';
    final payload = {
      'shiftId': shiftId,
      'fromWorkerId': fromWorkerId,
      'toWorkerId': toWorkerId,
      if (message != null) 'message': message,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall('POST', endpoint, requestBody: payload, headers: requestHeaders);

    final response = await client.post(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to create swap request: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final swapData = _mapOrNull(responseData['swapRequest']);
    if (swapData == null) {
      throw ApiWorkConnectException(500, 'Invalid swap request data format');
    }

    return _parseSwapRequest(swapData);
  }

  @override
  Future<void> updateSwapRequestStatus({
    required String swapRequestId,
    required SwapRequestStatus status,
    String? message,
  }) async {
    final endpoint = '/shift-swaps/$swapRequestId';
    final payload = {
      'status': status.toString().split('.').last.toLowerCase(),
      if (message != null) 'message': message,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall('PATCH', endpoint,
        requestBody: payload, headers: requestHeaders);

    final response = await client.patch(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update swap request status: ${response.body}',
      );
    }
  }

  @override
  Future<AttendanceRecord> createAttendanceRecord({
    required String shiftId,
    required String workerId,
    required String businessId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    String? locationSummary,
  }) async {
    const endpoint = '/attendance';
    final payload = {
      'shiftId': shiftId,
      'workerId': workerId,
      'businessId': businessId,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      if (locationSummary != null) 'locationSummary': locationSummary,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall('POST', endpoint, requestBody: payload, headers: requestHeaders);

    final response = await client.post(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to create attendance record: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final attendanceData = _mapOrNull(responseData['attendance']);
    if (attendanceData == null) {
      throw ApiWorkConnectException(500, 'Invalid attendance data format');
    }

    return _parseAttendanceRecord(attendanceData);
  }

  @override
  Future<void> updateAttendanceRecord({
    required String attendanceId,
    DateTime? clockIn,
    DateTime? clockOut,
    AttendanceStatus? status,
    double? totalHours,
    double? earnings,
    bool? isLate,
  }) async {
    final endpoint = '/attendance/$attendanceId';
    final payload = {
      if (clockIn != null) 'clockIn': clockIn.toIso8601String(),
      if (clockOut != null) 'clockOut': clockOut.toIso8601String(),
      if (status != null)
        'status': status.toString().split('.').last.toLowerCase(),
      if (totalHours != null) 'totalHours': totalHours,
      if (earnings != null) 'earnings': earnings,
      if (isLate != null) 'isLate': isLate,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall('PATCH', endpoint,
        requestBody: payload, headers: requestHeaders);

    final response = await client.patch(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update attendance record: ${response.body}',
      );
    }
  }

  // Helper methods for parsing responses
  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  List<dynamic> _listOrEmpty(dynamic value) {
    if (value is List) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      for (final nested in value.values) {
        if (nested is List) {
          return nested;
        }
      }
    }
    return const [];
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    return null;
  }

  // Entity parsing methods
  SwapRequest _parseSwapRequest(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final shiftId = _string(json['shiftId']) ?? '';
    final requestorId =
        _string(json['requestorId']) ?? _string(json['fromWorkerId']) ?? '';
    final targetWorkerId =
        _string(json['targetWorkerId']) ?? _string(json['toWorkerId']) ?? '';
    final status = _parseSwapRequestStatus(_string(json['status']));
    final createdAt =
        DateTime.tryParse(_string(json['createdAt']) ?? '') ?? DateTime.now();
    final messages = <SwapRequestMessage>[];
    final rawMessages = json['messages'];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        final messageMap = _mapOrNull(item);
        if (messageMap == null) continue;
        messages.add(
          SwapRequestMessage(
            senderId: _string(messageMap['senderId']) ?? '',
            body: _string(messageMap['body']) ?? '',
            sentAt: DateTime.tryParse(_string(messageMap['sentAt']) ?? '') ??
                createdAt,
          ),
        );
      }
    }

    return SwapRequest(
      id: id.isEmpty ? shiftId : id,
      shiftId: shiftId,
      requestorId: requestorId,
      targetWorkerId: targetWorkerId,
      status: status,
      createdAt: createdAt,
      messages: messages,
    );
  }

  SwapRequestStatus _parseSwapRequestStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return SwapRequestStatus.approved;
      case 'rejected':
        return SwapRequestStatus.rejected;
      case 'pending':
      case 'pending_approval':
      default:
        return SwapRequestStatus.pending;
    }
  }

  AttendanceRecord _parseAttendanceRecord(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final workerId = _string(json['workerId']) ?? _string(json['worker']) ?? '';
    final jobId = _string(json['jobId']) ?? _string(json['job']) ?? '';
    final businessId = _string(json['businessId']) ?? _string(json['business']);
    final scheduledStart =
        DateTime.tryParse(_string(json['scheduledStart']) ?? '') ??
            DateTime.now();
    final scheduledEnd =
        DateTime.tryParse(_string(json['scheduledEnd']) ?? '') ??
            scheduledStart.add(const Duration(hours: 4));
    final status = _parseAttendanceStatus(_string(json['status']));
    final totalHours = double.tryParse(_string(json['totalHours']) ?? '') ?? 0;
    final earnings = double.tryParse(_string(json['earnings']) ?? '') ?? 0;
    final isLate = _string(json['isLate'])?.toLowerCase() == 'true';
    final clockIn =
        DateTime.tryParse(_string(json['clockIn']) ?? '') ??
            DateTime.tryParse(_string(json['clockInAt']) ?? '');
    final clockOut =
        DateTime.tryParse(_string(json['clockOut']) ?? '') ??
            DateTime.tryParse(_string(json['clockOutAt']) ?? '');
    final workerJson =
        _mapOrNull(json['worker']) ?? _mapOrNull(json['workerDetails']);
    final jobJson = _mapOrNull(json['job']) ?? _mapOrNull(json['jobDetails']);
    final locationJson = _mapOrNull(json['location']);
    final businessJson =
        _mapOrNull(json['business']) ?? _mapOrNull(jobJson?['business']);
    final locationSummary = _string(json['locationSummary']) ??
        _string(jobJson?['locationSummary']) ??
        _string(locationJson?['summary']);
    final jobTitle =
        _string(json['jobTitle']) ?? _string(jobJson?['title']);
    final hourlyRate = double.tryParse(_string(json['hourlyRate']) ?? '') ??
        double.tryParse(_string(jobJson?['hourlyRate']) ?? '');
    final companyName = _string(json['company']) ??
        _string(json['businessName']) ??
        _string(businessJson?['name']);
    final location = _string(json['location']) ??
        _string(locationJson?['address']) ??
        _string(jobJson?['locationSummary']) ??
        _string(businessJson?['address']);

    return AttendanceRecord(
      id: id.isEmpty ? jobId : id,
      workerId: workerId,
      jobId: jobId,
      businessId: businessId ?? '',
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: status,
      totalHours: totalHours,
      earnings: earnings,
      isLate: isLate,
      clockIn: clockIn,
      clockOut: clockOut,
      locationSummary: locationSummary,
      jobTitle: jobTitle,
      hourlyRate: hourlyRate,
      companyName: companyName,
      location: location,
      workerName: _string(json['workerName']) ??
          _string(workerJson?['name']) ??
          '${_string(workerJson?['firstName']) ?? ''} ${_string(workerJson?['lastName']) ?? ''}'.trim(),
      workerAvatarUrl:
          _string(json['workerAvatar']) ?? _string(workerJson?['avatarUrl']),
    );
  }

  AttendanceStatus _parseAttendanceStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'clocked_in':
      case 'clockedin':
        return AttendanceStatus.clockedIn;
      case 'completed':
        return AttendanceStatus.completed;
      case 'missed':
        return AttendanceStatus.missed;
      case 'scheduled':
      default:
        return AttendanceStatus.scheduled;
    }
  }
}
