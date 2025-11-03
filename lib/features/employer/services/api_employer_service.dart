import 'dart:convert';

import 'package:talent/core/models/analytics.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/employer/services/attendance_api_service.dart';
import 'package:talent/features/employer/services/employer_service.dart';

// ignore_for_file: avoid_print

class ApiEmployerService extends BaseApiService implements EmployerService {
  ApiEmployerService({
    required super.baseUrl,
    super.enableLogging,
  });

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  /// Get business_id from the current user's selectedBusinessId
  /// This eliminates the need to pass businessId as parameter for every API call
  String? get _currentUserBusinessId =>
      ServiceLocator.instance.currentUserBusinessId;

  AttendanceApiService get _attendanceApi => ServiceLocator.instance.attendance;

  String? _resolveBusinessId(String? businessId) {
    final candidate = (businessId ?? _currentUserBusinessId)?.trim();
    if (candidate == null || candidate.isEmpty) {
      return null;
    }
    return candidate;
  }

  Map<String, dynamic>? _mapOrNull(dynamic input) {
    if (input == null) return null;
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return Map<String, dynamic>.from(input);
    return null;
  }

  List<dynamic> _listOrEmpty(dynamic input) {
    if (input == null) return const [];
    if (input is List) return input;
    return const [];
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    return null;
  }

  String? _composeName(Map<String, dynamic>? data) {
    if (data == null) return null;

    final fullName = _string(data['name']) ?? _string(data['fullName']);
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final first = _string(data['firstName']) ?? _string(data['givenName']);
    final last = _string(data['lastName']) ?? _string(data['familyName']);

    final parts = <String>[];
    if (first != null && first.isNotEmpty) {
      parts.add(first);
    }
    if (last != null && last.isNotEmpty) {
      parts.add(last);
    }

    final combined = parts.join(' ').trim();
    if (combined.isNotEmpty) {
      return combined;
    }

    return null;
  }

  // Entity parsing methods
  EmployerProfile _parseEmployerProfile(Map<String, dynamic> json) {
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final companyName =
        _string(json['companyName']) ?? _string(json['name']) ?? '';
    final description = _string(json['description']) ?? '';
    final phone = _string(json['contactPhone']) ?? _string(json['phone']) ?? '';
    final rating = double.tryParse(_string(json['rating']) ?? '') ?? 0;
    final totalJobsPosted =
        int.tryParse(_string(json['totalJobsPosted']) ?? '') ?? 0;
    final totalHires = int.tryParse(_string(json['totalHires']) ?? '') ?? 0;
    final activeBusinesses =
        int.tryParse(_string(json['activeBusinesses']) ?? '') ?? 0;

    return EmployerProfile(
      id: id,
      companyName: companyName,
      description: description,
      phone: phone,
      rating: rating,
      totalJobsPosted: totalJobsPosted,
      totalHires: totalHires,
      activeBusinesses: activeBusinesses,
    );
  }

  JobPosting _parseJobPosting(dynamic value) {
    final json = _mapOrNull(value) ?? <String, dynamic>{};

    // Extract core fields
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final title = _string(json['title']) ?? 'Job';
    final description = _string(json['description']) ?? '';
    final hourlyRate = double.tryParse(_string(json['hourlyRate']) ?? '') ?? 0;
    final status = _parseJobStatus(_string(json['status']));
    final urgency = _string(json['urgency'])?.toLowerCase() ?? 'medium';

    // Parse dates
    final scheduleStart =
        DateTime.tryParse(_string(json['scheduleStart']) ?? '') ??
            DateTime.now();
    final scheduleEnd = DateTime.tryParse(_string(json['scheduleEnd']) ?? '') ??
        scheduleStart.add(const Duration(hours: 4));
    final postedAt = DateTime.tryParse(
            _string(json['postedAt']) ?? _string(json['createdAt']) ?? '') ??
        DateTime.now();

    // Parse entity details
    final employerMap = _mapOrNull(json['employer'] ?? json['employerDetails']);
    final businessMap = _mapOrNull(json['business'] ?? json['businessDetails']);
    final createdByMap =
        _mapOrNull(json['createdBy'] ?? json['createdByDetails']);

    final employerId = _string(json['employerId']) ??
        _string(employerMap?['id']) ??
        _string(employerMap?['_id']) ??
        '';

    final businessId = _string(json['businessId']) ??
        _string(businessMap?['id']) ??
        _string(businessMap?['_id']) ??
        '';

    // Parse arrays and lists
    final tags = _listOrEmpty(json['tags']).map((t) => t.toString()).toList();

    final workDays =
        _listOrEmpty(json['workDays']).map((d) => d.toString()).toList();

    // Parse entity details
    final businessName =
        _string(businessMap?['name']) ?? _string(json['businessName']) ?? '';

    final businessAddress = _string(businessMap?['address']) ??
        _string(businessMap?['formattedAddress']) ??
        _string(json['businessAddress']) ??
        '';

    // Parse optional entity fields
    final employerEmail =
        _string(employerMap?['email']) ?? _string(json['employerEmail']) ?? '';

    final employerName =
        _composeName(employerMap) ?? _string(json['employerName']) ?? '';

    // Parse flags and counts
    final isVerificationRequired = json['verificationRequired'] == true ||
        json['isVerificationRequired'] == true;
    final hasApplied = json['hasApplied'] == true;
    final premiumRequired = json['premiumRequired'] == true;
    final distanceMiles =
        double.tryParse(_string(json['distanceMiles']) ?? '') ?? 0;
    final locationSummary = _string(json['locationSummary']);
    final applicantsCount =
        int.tryParse(_string(json['applicantsCount']) ?? '') ?? 0;

    // Get media URLs
    final businessLogoSmall = _string(json['businessLogoSmall']) ??
        _string(businessMap?['logoSmall']);
    final businessLogoMedium = _string(json['businessLogoMedium']) ??
        _string(businessMap?['logoMedium']);

    // Parse created by info
    final createdById =
        _string(createdByMap?['id']) ?? _string(createdByMap?['_id']) ?? '';
    final createdByEmail = _string(createdByMap?['email']) ?? '';
    final createdByName = _composeName(createdByMap) ?? '';
    final createdByTag = _string(createdByMap?['tag']) ?? '';

    // Parse overtime settings
    final overtimeRate = double.tryParse(_string(json['overtimeRate']) ?? '') ??
        (hourlyRate * 1.5);
    final overtime = JobOvertime(
        allowed: overtimeRate > hourlyRate,
        rateMultiplier: overtimeRate / hourlyRate);

    return JobPosting(
        id: id.isEmpty ? title : id,
        title: title,
        description: description,
        employerId: employerId,
        businessId: businessId,
        hourlyRate: hourlyRate,
        scheduleStart: scheduleStart,
        scheduleEnd: scheduleEnd,
        recurrence: 'one-time',
        overtime: overtime,
        urgency: urgency,
        tags: tags,
        workDays: workDays,
        isVerificationRequired: isVerificationRequired,
        status: status,
        postedAt: postedAt,
        distanceMiles: distanceMiles,
        hasApplied: hasApplied,
        premiumRequired: premiumRequired,
        locationSummary: locationSummary,
        applicantsCount: applicantsCount,
        businessName: businessName,
        businessAddress: businessAddress,
        employerEmail: employerEmail,
        employerName: employerName,
        businessLogoSmall: businessLogoSmall,
        businessLogoMedium: businessLogoMedium,
        createdById: createdById,
        createdByEmail: createdByEmail,
        createdByName: createdByName,
        createdByTag: createdByTag);
  }

  JobStatus _parseJobStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'filled':
        return JobStatus.filled;
      case 'closed':
      case 'inactive':
      case 'cancelled':
        return JobStatus.closed;
      case 'active':
      case 'open':
      default:
        return JobStatus.active;
    }
  }

  BusinessLocation _parseBusinessLocation(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    return BusinessLocation.fromJson(json);
  }

  EmployerDashboardMetrics _parseEmployerMetrics(Map<String, dynamic> json) {
    final openJobs = int.tryParse(_string(json['openJobs']) ?? '') ?? 0;
    final totalApplicants =
        int.tryParse(_string(json['totalApplicants']) ?? '') ?? 0;
    final totalHires = int.tryParse(_string(json['totalHires']) ?? '') ?? 0;
    final avgResponseTime =
        double.tryParse(_string(json['averageResponseTimeHours']) ?? '') ?? 0;
    final freePostingsRemaining =
        int.tryParse(_string(json['freePostingsRemaining']) ?? '') ?? 0;
    final premiumActive =
        _string(json['premiumActive'])?.toLowerCase() == 'true';

    final summaries = <JobSummary>[];
    final rawSummaries = json['recentJobSummaries'] ?? json['recentJobs'];
    if (rawSummaries is List) {
      for (final entry in rawSummaries) {
        final map = _mapOrNull(entry);
        if (map == null) continue;
        summaries.add(
          JobSummary(
            jobId: _string(map['jobId']) ?? _string(map['id']) ?? '',
            title: _string(map['title']) ?? 'Job',
            status: _string(map['status']) ?? 'active',
            applicants: int.tryParse(_string(map['applicants']) ?? '') ?? 0,
            hires: int.tryParse(_string(map['hires']) ?? '') ?? 0,
            updatedAt: DateTime.tryParse(_string(map['updatedAt']) ?? '') ??
                DateTime.now(),
          ),
        );
      }
    }

    return EmployerDashboardMetrics(
      openJobs: openJobs,
      totalApplicants: totalApplicants,
      totalHires: totalHires,
      averageResponseTimeHours: avgResponseTime,
      freePostingsRemaining: freePostingsRemaining,
      premiumActive: premiumActive,
      recentJobSummaries: summaries,
    );
  }

  @override
  Future<List<Application>> fetchEmployerApplications({
    ApplicationStatus? status,
    int? limit,
    int? page,
    String? businessId,
  }) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    final queryParams = <String, String>{
      'limit': (limit ?? 20).toString(),
      'page': (page ?? 1).toString(),
    };

    if (status != null) {
      queryParams['status'] = status.toString().split('.').last;
    }

    if (resolvedBusinessId != null && resolvedBusinessId.isNotEmpty) {
      queryParams['businessId'] = resolvedBusinessId;
    }

    const endpoint = 'api/applications';
    final uri = resolveWithQuery(endpoint, query: queryParams);

    final requestHeaders = headers(
      authToken: _authToken,
      businessId: resolvedBusinessId,
    );

    final response = await client.get(
      uri,
      headers: requestHeaders,
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch employer applications: ${response.body}',
      );
    }

    final responseData = decodeJson(response);

    List<dynamic> extractApplications(dynamic source) {
      if (source is List) return source;
      if (source is Map<String, dynamic>) {
        for (final key in [
          'data',
          'applications',
          'items',
          'results',
          'records'
        ]) {
          final value = source[key];
          if (value is List) return value;
          if (value is Map<String, dynamic>) {
            final nested = extractApplications(value);
            if (nested.isNotEmpty) return nested;
          }
        }
      }
      return const [];
    }

    final applicationsData = extractApplications(responseData);

    return applicationsData
        .map((json) {
          final map =
              _mapOrNull(json) ?? (json is Map<String, dynamic> ? json : {});
          return _parseApplicationFromApi(map);
        })
        .where((app) => app != null)
        .cast<Application>()
        .toList();
  }

  @override
  Future<Application> updateEmployerApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? message,
    String? businessId,
  }) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = _resolveBusinessId(businessId);

    final body = {
      'status': status.toString().split('.').last,
      if (resolvedBusinessId != null) 'businessId': resolvedBusinessId,
    };

    if (message != null && message.isNotEmpty) {
      body['message'] = message;
    }

    final requestHeaders = headers(authToken: _authToken);
    if (resolvedBusinessId != null) {
      requestHeaders['x-business-id'] = resolvedBusinessId;
    }

    final response = await client.patch(
      resolve('employers/me/applications/$applicationId'),
      headers: requestHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update application status: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final applicationData = _mapOrNull(responseData['data']) ?? responseData;

    final application = _parseApplicationFromApi(applicationData);
    if (application == null) {
      throw ApiWorkConnectException(
        500,
        'Failed to parse updated application data',
      );
    }

    return application;
  }

  @override
  Future<Application> hireApplicant(String applicationId,
      {DateTime? startDate, String? businessId}) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = _resolveBusinessId(businessId);

    // Include startDate in the request body (defaulting to today)
    final body = {
      'startDate': (startDate ?? DateTime.now()).toIso8601String(),
      if (resolvedBusinessId != null) 'businessId': resolvedBusinessId,
    };

    final requestHeaders = headers(authToken: _authToken);
    if (resolvedBusinessId != null) {
      requestHeaders['x-business-id'] = resolvedBusinessId;
    }

    final response = await client.post(
      resolve('jobs/applications/$applicationId/hire'),
      headers: requestHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to hire applicant: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final applicationData = _mapOrNull(responseData['data']) ?? responseData;

    final application = _parseApplicationFromApi(applicationData);
    if (application == null) {
      throw ApiWorkConnectException(
        500,
        'Failed to parse hired application data',
      );
    }

    return application;
  }

  @override
  Future<AttendanceDashboard> fetchAttendanceDashboard({
    required DateTime date,
    String status = 'all',
  }) async {
    // This method should use the real attendance dashboard API that's already implemented in app_state.dart
    // For now, throw an exception to indicate it should use the app_state method instead
    throw Exception(
        'Use AppState.loadAttendanceDashboard() for real API integration');
  }

  @override
  Future<AttendanceRecord> scheduleAttendanceRecord({
    required String workerId,
    required String jobId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required double hourlyRate,
    String? notes,
  }) async {
    final body = {
      'worker': workerId,
      'job': jobId,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      'hourlyRate': hourlyRate,
    };

    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }

    final response = await client.post(
      resolve('attendance'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to schedule attendance record: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final attendanceData = _mapOrNull(responseData['data']) ?? responseData;

    return _parseAttendanceFromApi(attendanceData);
  }

  @override
  Future<AttendanceRecord> markAttendanceComplete(String attendanceId) async {
    final response = await client.post(
      resolve('attendance/$attendanceId/mark-complete'),
      headers: headers(authToken: _authToken),
      body: '{}',
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to mark attendance complete: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final attendanceData = _mapOrNull(responseData['data']) ?? responseData;

    return _parseAttendanceFromApi(attendanceData);
  }

  @override
  Future<AttendanceRecord> updateAttendanceHours({
    required String attendanceId,
    required double totalHours,
    double? hourlyRate,
  }) async {
    final body = {
      'totalHours': totalHours,
    };

    if (hourlyRate != null) {
      body['hourlyRate'] = hourlyRate;
    }

    final response = await client.patch(
      resolve('attendance/$attendanceId/hours'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update attendance hours: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final attendanceData = _mapOrNull(responseData['data']) ?? responseData;

    return _parseAttendanceFromApi(attendanceData);
  }

  // Helper method to parse application data from API response
  Application? _parseApplicationFromApi(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['_id']?.toString();
    if (id == null || id.isEmpty) return null;

    String? firstNonEmpty(Iterable<String?> values) {
      for (final value in values) {
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return null;
    }

    final worker = json['worker'];
    String workerName = 'Unknown Worker';
    String workerExperience = '';
    List<String> workerSkills = [];

    if (worker is Map<String, dynamic>) {
      final firstName = worker['firstName']?.toString() ?? '';
      final lastName = worker['lastName']?.toString() ?? '';
      workerName = '$firstName $lastName'.trim();
      if (workerName.isEmpty) {
        workerName = worker['email']?.toString() ?? 'Unknown Worker';
      }

      workerExperience = worker['experience']?.toString() ?? '';
      if (worker['skills'] is List) {
        workerSkills =
            (worker['skills'] as List).map((e) => e.toString()).toList();
      }
    }

    final job = json['job'];
    final jobData = _mapOrNull(job);
    String jobId = '';
    if (jobData != null) {
      jobId = jobData['id']?.toString() ?? jobData['_id']?.toString() ?? '';
    } else if (job is String) {
      jobId = job;
    }

    final employerData = _mapOrNull(json['employer']) ??
        _mapOrNull(json['employerDetails']) ??
        _mapOrNull(jobData?['employer']);
    final businessData = _mapOrNull(json['business']) ??
        _mapOrNull(json['businessDetails']) ??
        _mapOrNull(jobData?['business']);

    final employerEmail = firstNonEmpty([
      _string(json['employerEmail']),
      _string(employerData?['email']),
      _string(jobData?['employerEmail']),
    ]);

    final employerName = firstNonEmpty([
      _composeName(employerData),
      _string(json['employerName']),
      _string(jobData?['employerName']),
      _string(employerData?['name']),
      employerEmail,
    ]);

    final employerId = firstNonEmpty([
      _extractId(json['employer']),
      _string(json['employerId']),
      _string(employerData?['_id']),
      _string(employerData?['id']),
      _string(jobData?['employerId']),
    ]);

    final businessId = firstNonEmpty([
      _extractId(json['business']),
      _string(json['businessId']),
      _string(businessData?['_id']),
      _string(businessData?['id']),
      _string(jobData?['businessId']),
    ]);

    final businessName = firstNonEmpty([
      _string(json['businessName']),
      _string(businessData?['businessName']),
      _string(businessData?['name']),
      _string(jobData?['businessName']),
    ]);

    return Application(
      id: id,
      jobId: jobId,
      workerId: _extractId(json['worker']),
      workerName: workerName,
      workerExperience: workerExperience,
      workerSkills: workerSkills,
      status: _parseApplicationStatus(json['status']?.toString()),
      submittedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      note: json['message']?.toString() ?? json['note']?.toString(),
      employerId: employerId,
      employerEmail: employerEmail,
      employerName: employerName,
      businessId: businessId,
      businessName: businessName,
    );
  }

  // Helper method to parse attendance data from API response
  AttendanceRecord _parseAttendanceFromApi(Map<String, dynamic> json) {
    final id = _extractId(json['id'] ?? json['_id']);

    return AttendanceRecord(
      id: id,
      workerId: _extractId(json['worker']),
      jobId: _extractId(json['job']),
      businessId: _extractId(json['business']),
      scheduledStart:
          DateTime.tryParse(json['scheduledStart']?.toString() ?? '') ??
              DateTime.now(),
      scheduledEnd: DateTime.tryParse(json['scheduledEnd']?.toString() ?? '') ??
          DateTime.now(),
      clockIn: json['clockInAt'] != null
          ? DateTime.tryParse(json['clockInAt'].toString())
          : null,
      clockOut: json['clockOutAt'] != null
          ? DateTime.tryParse(json['clockOutAt'].toString())
          : null,
      status: _parseAttendanceStatus(json['status']?.toString()),
      totalHours: double.tryParse(json['totalHours']?.toString() ?? '') ?? 0.0,
      earnings: double.tryParse(json['earnings']?.toString() ?? '') ?? 0.0,
      isLate: json['isLate'] == true,
      workerName: json['workerNameSnapshot']?.toString() ?? 'Unknown Worker',
      jobTitle: json['jobTitleSnapshot']?.toString() ?? 'Unknown Job',
      locationSummary: json['locationSnapshot']?.toString(),
      hourlyRate: double.tryParse(json['hourlyRate']?.toString() ?? ''),
    );
  }

  String _extractId(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      final match = RegExp(r'[0-9a-fA-F]{24}').firstMatch(value);
      return match?.group(0) ?? value;
    }

    if (value is Map<String, dynamic>) {
      for (final key in const [
        '_id',
        'id',
        'user',
        'userId',
        'worker',
        'workerId',
        'job',
        'jobId',
        'business',
        'businessId',
        r'$oid',
      ]) {
        if (value.containsKey(key)) {
          final candidate = _extractId(value[key]);
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        final candidate = _extractId(entry.value);
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    return value.toString();
  }

  // Helper method to parse application status
  ApplicationStatus _parseApplicationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'hired':
        return ApplicationStatus.hired;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  // Helper method to parse attendance status
  AttendanceStatus _parseAttendanceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return AttendanceStatus.scheduled;
      case 'clocked-in':
        return AttendanceStatus.clockedIn;
      case 'completed':
        return AttendanceStatus.completed;
      case 'missed':
        return AttendanceStatus.missed;
      default:
        return AttendanceStatus.scheduled;
    }
  }

  @override
  Future<EmploymentRecord> updateEmploymentWorkLocation({
    required String workerId,
    required String employmentId,
    Map<String, dynamic>? location,
    bool clear = false,
  }) async {
    final endpoint =
        'api/employers/me/workers/$workerId/employment/$employmentId/work-location';

    final body = <String, dynamic>{};
    if (clear) {
      body['clear'] = true;
    } else if (location != null && location.isNotEmpty) {
      body['location'] = location;
    } else {
      throw ArgumentError('Either provide location data or set clear=true');
    }

    final response = await client.patch(
      resolve(endpoint),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );

    final json = decodeJson(response);
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return EmploymentRecord.fromJson(data);
  }

  @override
  Future<List<JobPaymentRecord>> fetchJobPaymentHistory({
    int? page,
    int? limit,
  }) async {
    final query = <String, String>{};
    if (page != null && page > 0) {
      query['page'] = page.toString();
    }
    if (limit != null && limit > 0) {
      query['limit'] = limit.toString();
    }

    final response = await client.get(
      resolveWithQuery(
        'api/payments/job-posting',
        query: query.isEmpty ? null : query,
      ),
      headers: headers(authToken: _authToken),
    );

    final decoded = decodeJson(response);
    final List<dynamic> items;
    if (decoded['data'] is List) {
      items = decoded['data'] as List<dynamic>;
    } else if (decoded['payments'] is List) {
      items = decoded['payments'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((entry) =>
            JobPaymentRecord.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  @override
  Future<EmployerProfile> fetchEmployerProfile(
    String employerId, {
    String? businessId,
  }) async {
    final resolvedBusinessId = _resolveBusinessId(businessId);
    final uri = resolveWithQuery(
      'api/employers/$employerId',
      query: resolvedBusinessId != null
          ? {'businessId': resolvedBusinessId}
          : null,
    );

    final response = await client.get(
      uri,
      headers: headers(authToken: _authToken),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch employer profile: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final profileData = _mapOrNull(responseData['data']) ?? responseData;
    return _parseEmployerProfile(profileData);
  }

  @override
  Future<EmployerDashboardMetrics> fetchEmployerDashboardMetrics(
    String employerId, {
    String? businessId,
  }) async {
    final resolvedBusinessId = _resolveBusinessId(businessId);
    final uri = resolveWithQuery(
      'api/employers/$employerId/dashboard',
      query: resolvedBusinessId != null
          ? {'businessId': resolvedBusinessId}
          : null,
    );

    final response = await client.get(
      uri,
      headers: headers(authToken: _authToken),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch employer metrics: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final metricsData = _mapOrNull(responseData['data']) ?? responseData;
    return _parseEmployerMetrics(metricsData);
  }

  @override
  Future<List<JobPosting>> fetchEmployerJobs(
    String employerId, {
    String? businessId,
  }) async {
    final resolvedBusinessId = _resolveBusinessId(businessId);
    final uri = resolveWithQuery(
      'api/employers/$employerId/jobs',
      query: resolvedBusinessId != null
          ? {'businessId': resolvedBusinessId}
          : null,
    );

    final response = await client.get(
      uri,
      headers: headers(authToken: _authToken),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch employer jobs: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final List<dynamic> jobsData;
    if (responseData['data'] is List) {
      jobsData = responseData['data'] as List<dynamic>;
    } else if (responseData['jobs'] is List) {
      jobsData = responseData['jobs'] as List<dynamic>;
    } else {
      jobsData = const [];
    }

    return jobsData.map((json) => _parseJobPosting(json)).toList();
  }

  @override
  Future<List<BusinessLocation>> fetchBusinessLocations(String ownerId) async {
    final uri = resolve('api/employers/$ownerId/businesses');

    final response = await client.get(
      uri,
      headers: headers(authToken: _authToken),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to fetch business locations: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final List<dynamic> businessData;
    if (responseData['data'] is List) {
      businessData = responseData['data'] as List<dynamic>;
    } else if (responseData['businesses'] is List) {
      businessData = responseData['businesses'] as List<dynamic>;
    } else {
      businessData = const [];
    }

    return businessData.map((json) => _parseBusinessLocation(json)).toList();
  }

  @override
  Future<void> updateEmployerProfile(
    String employerId, {
    String? companyName,
    String? description,
    String? phone,
    String? profilePicture,
    String? profilePictureSmall,
    String? profilePictureMedium,
    String? profilePictureLarge,
    String? companyLogo,
    String? companyLogoSmall,
    String? companyLogoMedium,
    String? companyLogoLarge,
  }) async {
    final body = <String, dynamic>{};

    if (companyName != null) body['companyName'] = companyName;
    if (description != null) body['description'] = description;
    if (phone != null) body['phone'] = phone;
    if (profilePicture != null) body['profilePicture'] = profilePicture;
    if (profilePictureSmall != null) {
      body['profilePictureSmall'] = profilePictureSmall;
    }
    if (profilePictureMedium != null) {
      body['profilePictureMedium'] = profilePictureMedium;
    }
    if (profilePictureLarge != null) {
      body['profilePictureLarge'] = profilePictureLarge;
    }
    if (companyLogo != null) body['companyLogo'] = companyLogo;
    if (companyLogoSmall != null) body['companyLogoSmall'] = companyLogoSmall;
    if (companyLogoMedium != null) {
      body['companyLogoMedium'] = companyLogoMedium;
    }
    if (companyLogoLarge != null) body['companyLogoLarge'] = companyLogoLarge;

    final response = await client.patch(
      resolve('api/employers/$employerId'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to update employer profile: ${response.body}',
      );
    }
  }

  @override
  Future<List<EmployerFeedback>> fetchEmployerFeedback({
    int? page,
    int? limit,
  }) async {
    final query = <String, String>{};
    if (page != null && page > 0) {
      query['page'] = page.toString();
    }
    if (limit != null && limit > 0) {
      query['limit'] = limit.toString();
    }

    final response = await client.get(
      resolveWithQuery(
        'api/feedback/employer',
        query: query.isEmpty ? null : query,
      ),
      headers: headers(authToken: _authToken),
    );

    final decoded = decodeJson(response);
    final List<dynamic> items;
    if (decoded['data'] is List) {
      items = decoded['data'] as List<dynamic>;
    } else if (decoded['feedback'] is List) {
      items = decoded['feedback'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((entry) =>
            EmployerFeedback.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
