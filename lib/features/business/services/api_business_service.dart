// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/business/services/business_service.dart';

class ApiBusinessService extends BaseApiService implements BusinessService {
  ApiBusinessService({
    required super.baseUrl,
    super.enableLogging,
  });

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  /// Get business_id from the current user's selectedBusinessId
  /// This eliminates the need to pass businessId as parameter for every API call
  String? get _currentUserBusinessId =>
      ServiceLocator.instance.currentUserBusinessId;

  @override
  Future<BusinessLocation> createBusiness({
    required String name,
    required String description,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    required String phone,
  }) async {
    const endpoint = 'api/businesses';
    final body = {
      'name': name,
      'description': description,
      'address': {
        'street': street,
        'city': city,
        'state': state,
        'zip': postalCode,
      },
      'phone': phone,
    };

    // Build headers with Authorization token
    final requestHeaders = headers(authToken: _authToken);
    debugPrint('🟢 Using auth token inside ApiBusinessService: $_authToken');

    logApiCall('POST', endpoint, requestBody: body, headers: requestHeaders);

    // ✅ Correct endpoint (no ?create=true)
    final response = await client.post(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(body),
    );

    logApiCall(
      'POST',
      endpoint,
      requestBody: body,
      headers: requestHeaders,
      response: response,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = 'Failed to create business: ${response.body}';
      logApiCall(
        'POST',
        endpoint,
        requestBody: body,
        headers: requestHeaders,
        response: response,
        error: error,
      );
      throw ApiWorkConnectException(response.statusCode, error);
    }

    final responseData = decodeJson(response);
    final businessData = _mapOrNull(responseData['data']);
    if (businessData == null) {
      const error = 'Invalid business data format';
      logApiCall(
        'POST',
        endpoint,
        requestBody: body,
        headers: requestHeaders,
        response: response,
        error: error,
      );
      throw ApiWorkConnectException(500, error);
    }

    return _parseBusinessLocation(businessData);
  }

  @override
  Future<void> updateBusiness(
    String? businessId, {
    String? name,
    String? description,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    bool? isActive,
  }) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    final endpoint = '/businesses/$resolvedBusinessId';
    final addressUpdates = {
      if (street != null) 'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'zip': postalCode,
    };

    final updates = {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (addressUpdates.isNotEmpty) 'address': addressUpdates,
      if (phone != null) 'phone': phone,
      if (isActive != null) 'isActive': isActive,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall(
      'PATCH',
      endpoint,
      requestBody: updates,
      headers: requestHeaders,
    );

    final response = await client.patch(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(updates),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update business: ${response.body}',
      );
    }
  }

  @override
  Future<void> deleteBusiness(String? businessId) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    final endpoint = 'api/businesses/$resolvedBusinessId';
    final requestHeaders = headers(authToken: _authToken);

    logApiCall('DELETE', endpoint, headers: requestHeaders);

    final response = await client.delete(
      resolve(endpoint),
      headers: requestHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to delete business: ${response.body}',
      );
    }
  }

  @override
  Future<BudgetOverview> fetchBudget(String? businessId) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    final endpoint = '/businesses/$resolvedBusinessId/budget';
    final requestHeaders = headers(authToken: _authToken);

    logApiCall('GET', endpoint, headers: requestHeaders);

    final response = await client.get(
      resolve(endpoint),
      headers: requestHeaders,
    );

    final data = decodeJson(response);
    if (data is! Map<String, dynamic>) {
      throw ApiWorkConnectException(500, 'Invalid budget data format');
    }

    return _parseBudget(data);
  }

  @override
  Future<List<TeamMember>> fetchTeamMembers(String? businessId) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    try {
      final response = await client.get(
        resolveWithQuery(
          '/team-members',
          query: {'businessId': resolvedBusinessId},
        ),
        headers: headers(authToken: _authToken),
      );
      final data = decodeJsonList(response);
      return data.map(_parseTeamMember).toList();
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode != 404 &&
          error.statusCode != 405 &&
          error.statusCode != 501) {
        rethrow;
      }
      try {
        final response = await client.get(
          resolve('/businesses/$businessId/team-members'),
          headers: headers(authToken: _authToken),
        );
        final legacy = decodeJsonList(response);
        return legacy.map(_parseTeamMember).toList();
      } on ApiWorkConnectException catch (legacyError) {
        if (legacyError.statusCode == 404) {
          return const <TeamMember>[];
        }
        rethrow;
      }
    }
  }

  @override
  Future<AnalyticsSummary> fetchAnalyticsSummary(String? businessId) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    Map<String, dynamic> json;
    try {
      final response = await client.get(
        resolveWithQuery(
          '/analytics/summary',
          query: {'businessId': resolvedBusinessId},
        ),
        headers: headers(authToken: _authToken),
      );
      json = decodeJson(response);
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode != 404 &&
          error.statusCode != 405 &&
          error.statusCode != 501) {
        rethrow;
      }
      final response = await client.get(
        resolveWithQuery(
          '/employers/me/analytics',
          query: {'businessId': businessId},
        ),
        headers: headers(authToken: _authToken),
      );
      json = decodeJson(response);
    }
    return _parseAnalyticsSummary(json);
  }

  @override
  Future<List<AttendanceRecord>> fetchBusinessAttendance(
    String? businessId,
  ) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    final response = await client.get(
      resolveWithQuery(
        '/attendance',
        query: {'businessId': resolvedBusinessId},
      ),
      headers: headers(authToken: _authToken),
    );
    final data = decodeJsonList(response);
    return data.map(_parseAttendanceRecord).toList();
  }

  // Helper methods for parsing responses
  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    return null;
  }

  List<String>? _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  // Entity parsing methods
  BusinessLocation _parseBusinessLocation(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final name = _string(json['name']) ?? 'Business';
    final address = _string(json['address']) ??
        _string(json['street']) ??
        _string(_mapOrNull(json['address'])?['street']) ??
        '';
    final city = _string(json['city']) ??
        _string(_mapOrNull(json['address'])?['city']) ??
        '';
    final state = _string(json['state']) ??
        _string(_mapOrNull(json['address'])?['state']) ??
        '';
    final postalCode = _string(json['postalCode']) ??
        _string(_mapOrNull(json['address'])?['postalCode']) ??
        '';
    final phone = _string(json['contactPhone']) ?? '';
    final type = _string(json['type']) ?? 'Location';
    final isActive = _string(json['isActive'])?.toLowerCase() == 'true';
    final jobCount = int.tryParse(_string(json['jobCount']) ?? '') ?? 0;
    final hireCount = int.tryParse(_string(json['hireCount']) ?? '') ?? 0;
    final description = _string(json['description']) ?? '';

    return BusinessLocation(
      id: id.isEmpty ? name : id,
      name: name,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      phone: phone,
      type: type,
      isActive: isActive,
      jobCount: jobCount,
      hireCount: hireCount,
      description: description,
    );
  }

  TeamMember _parseTeamMember(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final name = _string(json['name']) ?? '';
    final email = _string(json['email']) ?? '';
    final firstName = _string(json['firstName']) ?? '';
    final lastName = _string(json['lastName']) ?? '';
    final roleString = _string(json['role']) ?? 'supervisor';
    final assignedLocationIds = _stringList(json['assignedLocationIds']) ?? [];
    final permissionStrings = _stringList(json['permissions']) ?? [];
    final isActive = _string(json['isActive'])?.toLowerCase() == 'true';

    // Create User object
    final user = User(
      id: id,
      firstName: firstName.isNotEmpty ? firstName : name,
      lastName: lastName,
      email: email,
      type: UserType.employer, // Default to employer for team members
    );

    return TeamMember(
      id: id.isEmpty ? email : id,
      user: user,
      businessId:
          assignedLocationIds.isNotEmpty ? assignedLocationIds.first : '',
      role: roleString,
      permissions: permissionStrings,
      isActive: isActive,
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
    final clockIn = DateTime.tryParse(_string(json['clockIn']) ?? '') ??
        DateTime.tryParse(_string(json['clockInAt']) ?? '');
    final clockOut = DateTime.tryParse(_string(json['clockOut']) ?? '') ??
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
    final jobTitle = _string(json['jobTitle']) ?? _string(jobJson?['title']);
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
          '${_string(workerJson?['firstName']) ?? ''} ${_string(workerJson?['lastName']) ?? ''}'
              .trim(),
      workerAvatarUrl:
          _string(json['workerAvatar']) ?? _string(workerJson?['avatarUrl']),
    );
  }

  BudgetOverview _parseBudget(Map<String, dynamic> json) {
    final budget = _mapOrNull(json['budget']) ?? json;
    final month =
        DateTime.tryParse(_string(budget['month']) ?? '') ?? DateTime.now();
    final totalBudget =
        double.tryParse(_string(budget['monthlyBudget']) ?? '') ??
            double.tryParse(_string(budget['totalBudget']) ?? '') ??
            0;
    final totalSpend =
        double.tryParse(_string(budget['totalSpend']) ?? '') ?? 0;
    final projectedSpend =
        double.tryParse(_string(budget['projectedSpend']) ?? '') ?? totalSpend;

    final categories = <BudgetCategory>[];
    final rawCategories = budget['categories'];
    if (rawCategories is List) {
      for (final entry in rawCategories) {
        final map = _mapOrNull(entry);
        if (map == null) continue;
        categories.add(
          BudgetCategory(
            id: _string(map['id']) ?? _string(map['_id']) ?? '',
            name: _string(map['name']) ?? 'Category',
            allocated: double.tryParse(_string(map['allocated']) ?? '') ?? 0,
            actual: double.tryParse(_string(map['actual']) ?? '') ?? 0,
            alertLevel: double.tryParse(_string(map['alertLevel']) ?? '') ?? 0,
          ),
        );
      }
    }

    final alerts = <BudgetAlert>[];
    final rawAlerts = budget['alerts'];
    if (rawAlerts is List) {
      for (final entry in rawAlerts) {
        final map = _mapOrNull(entry);
        if (map == null) continue;
        alerts.add(
          BudgetAlert(
            id: _string(map['id']) ?? _string(map['_id']) ?? '',
            categoryId: _string(map['categoryId']) ?? '',
            message: _string(map['message']) ?? '',
            severity: _string(map['severity']) ?? 'low',
            createdAt: DateTime.tryParse(_string(map['createdAt']) ?? '') ??
                DateTime.now(),
          ),
        );
      }
    }

    return BudgetOverview(
      month: DateTime(month.year, month.month, 1),
      totalBudget: totalBudget,
      totalSpend: totalSpend,
      projectedSpend: projectedSpend,
      categories: categories,
      alerts: alerts,
    );
  }

  AnalyticsSummary _parseAnalyticsSummary(Map<String, dynamic> json) {
    final analytics = _mapOrNull(json['analytics']) ?? json;
    final funnel = <String, double>{};
    final rawFunnel = analytics['applicationFunnel'];
    if (rawFunnel is Map) {
      rawFunnel.forEach((key, value) {
        final amount = double.tryParse(_string(value) ?? '');
        if (amount != null) {
          funnel[key.toString()] = amount;
        }
      });
    }

    final hireRate = double.tryParse(_string(analytics['hireRate']) ?? '') ?? 0;
    final avgHourlyRate =
        double.tryParse(_string(analytics['avgHourlyRate']) ?? '') ?? 0;

    final responseTrend = <AnalyticsTrendPoint>[];
    final rawResponseTrend = analytics['responseTimeTrend'];
    if (rawResponseTrend is List) {
      for (final entry in rawResponseTrend) {
        final map = _mapOrNull(entry);
        if (map == null) continue;
        final label = _string(map['label']) ?? '';
        final value = double.tryParse(_string(map['value']) ?? '');
        if (value != null) {
          responseTrend.add(AnalyticsTrendPoint(label: label, value: value));
        }
      }
    }

    final performanceTrend = <AnalyticsTrendPoint>[];
    final rawPerformanceTrend = analytics['jobPerformanceTrend'];
    if (rawPerformanceTrend is List) {
      for (final entry in rawPerformanceTrend) {
        final map = _mapOrNull(entry);
        if (map == null) continue;
        final label = _string(map['label']) ?? '';
        final value = double.tryParse(_string(map['value']) ?? '');
        if (value != null) {
          performanceTrend.add(AnalyticsTrendPoint(label: label, value: value));
        }
      }
    }

    return AnalyticsSummary(
      applicationFunnel: funnel,
      hireRate: hireRate,
      avgHourlyRate: avgHourlyRate,
      responseTimeTrend: responseTrend,
      jobPerformanceTrend: performanceTrend,
    );
  }

  @override
  Future<BusinessLocation?> fetchBusinessById(String? businessId) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      throw ApiWorkConnectException(400, 'Business ID is required');
    }

    final endpoint = 'api/businesses/$resolvedBusinessId';
    final requestHeaders = headers(authToken: _authToken);

    logApiCall('GET', endpoint, headers: requestHeaders);

    final response =
        await client.get(resolve(endpoint), headers: requestHeaders);

    if (response.statusCode == 404) return null;

    final data = decodeJson(response);

    // Try to extract business data using different possible formats
    final businessData = _mapOrNull(data['data']) ??
        _mapOrNull(data['business']) ??
        _mapOrNull(data) ??
        <String, dynamic>{};

    return _parseBusinessLocation(businessData);
  }

  @override
  Future<List<BusinessLocation>> fetchBusinesses() async {
    const endpoint = 'api/businesses';
    final requestHeaders = headers(authToken: _authToken);

    logApiCall('GET', endpoint, headers: requestHeaders);

    final response =
        await client.get(resolve(endpoint), headers: requestHeaders);

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch businesses: ${response.body}',
      );
    }

    final data = decodeJsonList(response);
    return data.map(_parseBusinessLocation).toList();
  }
}
