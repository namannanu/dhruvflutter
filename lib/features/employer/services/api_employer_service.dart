import 'dart:convert';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/employer/services/employer_service.dart';

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

  String? _resolveBusinessId(String? businessId) {
    final candidate = (businessId ?? _currentUserBusinessId)?.trim();
    if (candidate == null || candidate.isEmpty) {
      return null;
    }
    return candidate;
  }

  @override
  Future<EmployerProfile> fetchEmployerProfile(
    String employerId, {
    String? businessId,
  }) async {
    try {
      final resolvedBusinessId = _resolveBusinessId(businessId);
      final requestHeaders = headers(
        authToken: _authToken,
        businessId: resolvedBusinessId,
      );

      final uri = resolvedBusinessId != null
          ? resolveWithQuery(
              'api/employers/$employerId',
              query: {'businessId': resolvedBusinessId},
            )
          : resolve('api/employers/$employerId');

      final response = await client.get(
        uri,
        headers: requestHeaders,
      );
      final json = decodeJson(response);
      final employerJson = _mapOrNull(json['employer']) ?? json;
      return _parseEmployerProfile(employerJson);
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 403) {
        final resolvedBusinessId = _resolveBusinessId(businessId);
        final requestHeaders = headers(
          authToken: _authToken,
          businessId: resolvedBusinessId,
        );
        final response = await client.get(
          resolve('api/employers/me'),
          headers: requestHeaders,
        );
        final fallback = decodeJson(response);
        final employerJson = _mapOrNull(fallback['employer']) ?? fallback;
        return _parseEmployerProfile(employerJson);
      }
      rethrow;
    }
  }

  @override
  Future<EmployerDashboardMetrics> fetchEmployerDashboardMetrics(
    String employerId, {
    String? businessId,
  }) async {
    final resolvedBusinessId = _resolveBusinessId(businessId);
    final requestHeaders = headers(
      authToken: _authToken,
      businessId: resolvedBusinessId,
    );

    final uri = resolvedBusinessId != null
        ? resolveWithQuery(
            'api/employers/$employerId/dashboard',
            query: {'businessId': resolvedBusinessId},
          )
        : resolve('api/employers/$employerId/dashboard');

    final response = await client.get(
      uri,
      headers: requestHeaders,
    );

    final json = decodeJson(response);
    final metrics =
        _mapOrNull(json['metrics']) ?? _mapOrNull(json['dashboard']) ?? json;

    return _parseEmployerMetrics(metrics);
  }

  @override
  Future<List<JobPosting>> fetchEmployerJobs(
    String employerId, {
    String? businessId,
  }) async {
    final trimmedBusinessId = businessId?.trim();
    final resolvedBusinessId =
        (trimmedBusinessId != null && trimmedBusinessId.isNotEmpty)
            ? trimmedBusinessId
            : null;

    final query = <String, dynamic>{'employerId': employerId};
    if (resolvedBusinessId != null) {
      query['businessId'] = resolvedBusinessId;
    }

    final requestHeaders = headers(
      authToken: _authToken,
      businessId: resolvedBusinessId,
    );

    final response = await client.get(
      resolveWithQuery(
        '/jobs',
        query: query,
      ),
      headers: requestHeaders,
    );
    final data = decodeJsonList(response);
    return data.map(_parseJobPosting).toList();
  }

  @override
  Future<List<BusinessLocation>> fetchBusinessLocations(String ownerId) async {
    final response = await client.get(
      resolveWithQuery(
        '/businesses',
        query: {'ownerId': ownerId},
      ),
      headers: headers(authToken: _authToken),
    );
    final data = decodeJsonList(response);
    return data.map(_parseBusinessLocation).toList();
  }

  // Helper methods for parsing responses
  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
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

  String? _composeName(Map<String, dynamic>? data) {
    if (data == null) return null;
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
    final fallback = _string(data['name']);
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
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
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final employerDetails =
        _mapOrNull(json['employerDetails']) ?? _mapOrNull(json['employer']);
    final businessDetails =
        _mapOrNull(json['businessDetails']) ?? _mapOrNull(json['business']);
    final createdByDetails = _mapOrNull(json['createdByDetails']) ??
        (json['createdBy'] is Map ? _mapOrNull(json['createdBy']) : null);

    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final title = _string(json['title']) ?? 'Job';
    final description = _string(json['description']) ?? '';

    final employerId = _string(json['employerId']) ??
        _string(employerDetails?['_id']) ??
        _string(employerDetails?['id']) ??
        _string(json['employer']) ??
        '';
    final employerEmail =
        _string(employerDetails?['email']) ?? _string(json['employerEmail']);
    final employerName = _composeName(employerDetails);

    final businessId = _string(json['businessId']) ??
        _string(businessDetails?['_id']) ??
        _string(businessDetails?['id']) ??
        _string(json['business']) ??
        '';
    final businessName = _string(json['businessName']) ??
        _string(businessDetails?['businessName']) ??
        _string(businessDetails?['name']) ??
        '';

    final createdById = _string(json['createdById']) ??
        _string(createdByDetails?['_id']) ??
        _string(createdByDetails?['id']);
    final createdByEmail =
        _string(createdByDetails?['email']) ?? _string(json['createdByEmail']);
    final createdByName = _composeName(createdByDetails);
    final createdByTag = _string(json['createdByTag']);

    final hourlyRate = double.tryParse(_string(json['hourlyRate']) ?? '') ?? 0;
    final overtimeRate = double.tryParse(_string(json['overtimeRate']) ?? '') ??
        (hourlyRate * 1.5);
    final urgency = _string(json['urgency']) ?? 'medium';
    final tags = _stringList(json['tags']) ?? <String>[];
    final workDays = _stringList(json['workDays']) ?? <String>[];
    final isVerificationRequired =
        _string(json['verificationRequired'])?.toLowerCase() == 'true' ||
            json['verificationRequired'] == true;
    final scheduleStart = DateTime.tryParse(_string(json['startDate']) ??
            _string(json['scheduleStart']) ??
            '') ??
        DateTime.now();
    final scheduleEnd = DateTime.tryParse(
            _string(json['endDate']) ?? _string(json['scheduleEnd']) ?? '') ??
        scheduleStart.add(const Duration(hours: 4));
    final status = _parseJobStatus(_string(json['status']));
    final postedAt = DateTime.tryParse(
            _string(json['createdAt']) ?? _string(json['postedAt']) ?? '') ??
        DateTime.now();
    final distanceMiles =
        double.tryParse(_string(json['distanceMiles']) ?? '') ?? 0;
    final hasApplied = _string(json['hasApplied'])?.toLowerCase() == 'true' ||
        json['hasApplied'] == true;
    final premiumRequired =
        _string(json['premiumRequired'])?.toLowerCase() == 'true' ||
            json['premiumRequired'] == true;
    final locationSummary = _string(json['locationSummary']);
    final applicantsCount =
        int.tryParse(_string(json['applicantsCount']) ?? '') ?? 0;

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
      overtimeRate: overtimeRate,
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
      employerEmail: employerEmail,
      employerName: employerName,
      createdById: createdById,
      createdByTag: createdByTag,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
    );
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
