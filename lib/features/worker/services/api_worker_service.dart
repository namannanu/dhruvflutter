// ignore_for_file: unnecessary_type_check, avoid_print, unrelated_type_equality_checks
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/cache/worker_cache_repository.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/worker/services/worker_service.dart';

class ApiWorkerService extends BaseApiService implements WorkerService {
  ApiWorkerService({
    required super.baseUrl,
    super.enableLogging,
    WorkerCacheRepository? cache,
  }) : _cache = cache;

  final WorkerCacheRepository? _cache;

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  /// Get business_id from the current user's selectedBusinessId
  /// This eliminates the need to pass businessId as parameter for every API call
  String? get _currentUserBusinessId =>
      ServiceLocator.instance.currentUserBusinessId;

  @override
  Future<WorkerProfile> fetchWorkerProfile(String workerId) async {
    final endpoint = workerId == 'me' ? '/workers/me' : '/workers/$workerId';

    final response = await get(
      endpoint,
      headers: headers(authToken: _authToken),
    );

    final json = decodeJson(response);
    final payload = _extractProfilePayload(json);
    final profile = WorkerProfile.fromJson(payload);
    await _cache?.writeProfile(profile);
    return profile;
  }

  @override
  Future<WorkerProfile> updateWorkerProfile({
    required String workerId,
    String? firstName,
    String? lastName,
    String? bio,
    List<String>? skills,
    String? experience,
    List<String>? languages,
    String? phone,
    List<Map<String, dynamic>>? availability,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    double? preferredRadiusMiles,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (bio != null) body['bio'] = bio;
    if (skills != null) body['skills'] = skills;
    if (experience != null) body['experience'] = experience;
    if (languages != null) body['languages'] = languages;
    if (phone != null) body['phone'] = phone;
    if (notificationsEnabled != null) {
      body['notificationsEnabled'] = notificationsEnabled;
    }
    if (emailNotificationsEnabled != null) {
      body['emailNotificationsEnabled'] = emailNotificationsEnabled;
    }
    if (preferredRadiusMiles != null) {
      body['preferredRadiusMiles'] = preferredRadiusMiles;
    }

    if (availability != null) {
      body['availability'] = availability
          .map(_normalizeAvailabilityDay)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    final response = await client.patch(
      resolveWithQuery('/workers/me'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );

    final json = decodeJson(response);
    final payload = _extractProfilePayload(json);
    final profile = WorkerProfile.fromJson(payload);
    await _cache?.writeProfile(profile);
    return profile;
  }

  @override
  Future<List<EmploymentRecord>> fetchEmploymentHistory(
    String workerId,
  ) async {
    final endpoint = workerId == 'me'
        ? '/workers/me/employment/history'
        : '/workers/$workerId/employment/history';

    final response = await get(
      endpoint,
      headers: headers(authToken: _authToken),
    );

    final decoded = decodeJson(response);
    final records = _listOrEmpty(
      decoded['data'] ?? decoded['employmentHistory'],
    );

    return records
        .whereType<Map>()
        .map(
          (entry) => EmploymentRecord.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  Map<String, dynamic>? _normalizeAvailabilityDay(Map<String, dynamic> day) {
    final dayName = day['day']?.toString();
    if (dayName == null) {
      return null;
    }

    final normalizedDay = dayName.toLowerCase();
    const allowedDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    if (!allowedDays.contains(normalizedDay)) {
      return null;
    }

    final isAvailableRaw =
        day['isAvailable'] ?? day['available'] ?? day['active'];
    final isAvailable = _coerceBool(isAvailableRaw);

    final slotsRaw = day['timeSlots'];
    final slots = <Map<String, String>>[];
    if (slotsRaw is List) {
      for (final slot in slotsRaw) {
        if (slot is Map) {
          final start = slot['startTime']?.toString();
          final end = slot['endTime']?.toString();
          if (_isValidTime(start) && _isValidTime(end)) {
            slots.add({'startTime': start!, 'endTime': end!});
          }
        }
      }
    }

    return <String, dynamic>{
      'day': normalizedDay,
      'isAvailable': isAvailable,
      'timeSlots': slots,
    };
  }

  bool _coerceBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'available';
    }
    return false;
  }

  bool _isValidTime(String? value) {
    if (value == null) return false;
    return RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
  }

  Map<String, dynamic> _extractProfilePayload(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      return null;
    }

    Map<String, dynamic>? candidate;

    final data = asMap(json['data']);
    if (data != null) {
      candidate = asMap(data['profile']) ?? asMap(data['worker']);
      if (candidate != null) {
        final user = asMap(data['user']);
        if (user != null) {
          candidate = <String, dynamic>{
            ...candidate,
            'email': candidate['email'] ?? user['email'],
            'firstName': candidate['firstName'] ?? user['firstName'],
            'lastName': candidate['lastName'] ?? user['lastName'],
            'phone': candidate['phone'] ?? user['phone'],
            'id': candidate['id'] ??
                candidate['_id'] ??
                user['id'] ??
                user['_id'],
          };
        }
        return candidate;
      }
    }

    candidate = asMap(json['profile']) ?? asMap(json['worker']);
    if (candidate != null) {
      return candidate;
    }

    throw ApiWorkConnectException(
      500,
      'Unexpected worker profile response structure: $json',
    );
  }

  @override
  Future<List<JobPosting>> fetchWorkerJobs(
    String workerId, {
    String status = 'active',
    bool fallbackToAll = true,
  }) async {
    // Enhanced debug logging
    print('🔍 DEBUG: fetchWorkerJobs called with:');
    print('   - workerId: $workerId');
    print('   - status: $status');
    print('   - fallbackToAll: $fallbackToAll');
    print('   - authToken available: ${_authToken != null}');
    print('   - currentUserBusinessId: $_currentUserBusinessId');

    if (_authToken == null) {
      print('❌ ERROR: No auth token available - worker cannot fetch jobs');
      throw ApiWorkConnectException(
          401, 'Authentication required: No auth token available');
    }

    final query = _buildWorkerJobQuery(status);
    final filterLabel = query == null ? 'all' : 'status=$status';
    List<dynamic> data = const [];

    try {
      data = await _fetchWorkerJobsPayload(
        query: query,
        debugLabel: filterLabel,
      );
    } on ApiWorkConnectException catch (error) {
      print('❌ DEBUG: API error fetching jobs ($filterLabel): $error');
      print('   - Status Code: ${error.statusCode}');
      print('   - Message: ${error.message}');

      if (fallbackToAll && query != null) {
        print('🔄 DEBUG: Attempting fallback to fetch all jobs...');
        try {
          data = await _fetchWorkerJobsPayload(
            query: null,
            debugLabel: 'all (fallback)',
          );
        } on ApiWorkConnectException catch (fallbackError) {
          print('❌ DEBUG: Fallback jobs API error: $fallbackError');
          if (_isNotFoundOrUnauthorized(fallbackError.statusCode)) {
            print('🔍 DEBUG: Returning empty list due to auth/not found error');
            return const <JobPosting>[];
          }
          rethrow;
        } catch (fallbackError) {
          print(
              '❌ DEBUG: Unexpected error during fallback fetch: $fallbackError');
          rethrow;
        }
      } else {
        if (_isNotFoundOrUnauthorized(error.statusCode)) {
          print(
              '🔍 DEBUG: Jobs API returned ${error.statusCode}, returning empty list');
          return const <JobPosting>[];
        }
        rethrow;
      }
    } catch (error) {
      print('❌ DEBUG: Unexpected error fetching jobs ($filterLabel): $error');
      rethrow;
    }

    if (data.isEmpty && fallbackToAll && query != null) {
      print(
          'DEBUG: No jobs found for filter ($filterLabel), attempting fallback to all jobs');
      try {
        data = await _fetchWorkerJobsPayload(
          query: null,
          debugLabel: 'all (empty fallback)',
        );
      } on ApiWorkConnectException catch (fallbackError) {
        print('DEBUG: Fallback jobs API error: $fallbackError');
        if (_isNotFoundOrUnauthorized(fallbackError.statusCode)) {
          return const <JobPosting>[];
        }
        rethrow;
      } catch (fallbackError) {
        print('DEBUG: Unexpected error during fallback fetch: $fallbackError');
        rethrow;
      }
    }

    if (data.isEmpty) {
      print('DEBUG: No job data found from API, returning empty list');
      return const <JobPosting>[];
    }

    final parsedJobs = data.map(_parseJobPosting).toList();
    final publishedJobs = parsedJobs
        .where((job) => job.isPublished || job.publishStatus == 'published')
        .toList();

    print(
        'DEBUG: Successfully parsed ${parsedJobs.length} jobs (filter: $filterLabel)');
    if (publishedJobs.length != parsedJobs.length) {
      print(
          'DEBUG: Filtered out ${parsedJobs.length - publishedJobs.length} unpublished jobs for worker view');
    }

    return publishedJobs;
  }

  /// Fetch a specific job by ID (useful for getting employer info from applications)
  @override
  Future<JobPosting?> fetchJobById(String jobId) async {
    try {
      print('DEBUG: Fetching specific job with ID: $jobId');

      final response = await client.get(
        resolve('/jobs/$jobId'),
        headers: headers(authToken: _authToken),
      );

      print('DEBUG: Job by ID API response status: ${response.statusCode}');
      print('DEBUG: Job by ID API response body: ${response.body}');

      final decoded = decodeJson(response);
      final jobData = decoded['data'] ?? decoded;

      if (jobData == null) {
        print('DEBUG: No job data found for ID: $jobId');
        return null;
      }

      final job = _parseJobPosting(jobData);
      print(
          'DEBUG: Successfully fetched job: ${job.title}, employer: ${job.employerId}');
      return job;
    } on ApiWorkConnectException catch (error) {
      print('DEBUG: API error fetching job by ID: $error');
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (error) {
      print('DEBUG: Unexpected error fetching job by ID: $error');
      return null;
    }
  }

  @override
  Future<List<Application>> fetchWorkerApplications(String workerId) async {
    final endpoint = workerId == 'me'
        ? '/workers/me/applications'
        : '/workers/$workerId/applications';

    print('🔍 Fetching worker applications from endpoint: $endpoint');
    print('🔍 Auth token available: ${_authToken != null ? "YES" : "NO"}');
    if (_authToken != null) {
      print(
          '🔍 Auth token preview: ${_authToken!.substring(0, _authToken!.length > 20 ? 20 : _authToken!.length)}...');
    }

    try {
      final requestHeaders = headers(authToken: _authToken);
      print('🔍 Request headers: ${requestHeaders.keys.toList()}');

      final response = await client.get(
        resolve(endpoint),
        headers: requestHeaders,
      );

      print('🔍 API Response status: ${response.statusCode}');
      final decoded = decodeJson(response);
      print('🔍 Decoded response keys: ${decoded.keys.toList()}');

      final container = _mapOrNull(decoded['data']) ?? decoded;

      List<dynamic> data = _listOrEmpty(container['applications']);
      if (data.isEmpty) {
        data = _listOrEmpty(container['data']);
      }
      if (data.isEmpty) {
        data = _listOrEmpty(decoded['data']);
      }
      if (data.isEmpty && container != decoded) {
        data = _listOrEmpty(container.values.firstWhere(
          (value) => value is List,
          orElse: () => const [],
        ));
      }

      print('🔍 Found ${data.length} applications in response');
      final applications = data.map(_parseApplication).toList();
      print('🔍 Successfully parsed ${applications.length} applications');
      return applications;
    } on ApiWorkConnectException catch (error) {
      print(
          '❌ API error fetching applications: ${error.statusCode} - ${error.message}');
      if (_shouldUseLegacyApplicationsEndpoint(error.statusCode)) {
        print('🔄 Trying legacy applications endpoint...');
        return _fetchWorkerApplicationsLegacy(workerId);
      }
      rethrow;
    } catch (e) {
      print('❌ Unexpected error fetching applications: $e');
      rethrow;
    }
  }

  @override
  Future<EmployerFeedback> submitEmployerFeedback({
    required String workerId,
    required String employerId,
    required int rating,
    String? comment,
    String? jobId,
  }) async {
    final _ = workerId;
    final payload = <String, dynamic>{
      'employerId': employerId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
      if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
    };

    final response = await client.post(
      resolve('/feedback'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(payload),
    );

    final decoded = decodeJson(response);
    final data = _mapOrNull(decoded['data']) ?? decoded;
    return EmployerFeedback.fromJson(data);
  }

  @override
  Future<List<EmployerFeedback>> fetchWorkerFeedback(String workerId) async {
    final _ = workerId;
    final response = await client.get(
      resolve('/feedback/worker'),
      headers: headers(authToken: _authToken),
    );

    final decoded = decodeJson(response);
    final data = _listOrEmpty(decoded['data']);
    return data
        .whereType<Map>()
        .map((entry) =>
            EmployerFeedback.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  @override
  Future<Application> submitJobApplication({
    required String workerId,
    required String jobId,
    String? message,
  }) async {
    final trimmedMessage = message?.trim();
    final payload = <String, dynamic>{
      'jobId': jobId,
      if (trimmedMessage != null && trimmedMessage.isNotEmpty)
        'message': trimmedMessage,
    };

    try {
      final response = await client.post(
        resolve('/workers/me/applications'),
        headers: headers(authToken: _authToken),
        body: jsonEncode(payload),
      );

      return _parseApplicationResponse(response);
    } on ApiWorkConnectException catch (error) {
      if (!_shouldUseLegacyApplicationsEndpoint(error.statusCode)) {
        rethrow;
      }
    }

    return _submitJobApplicationLegacy(
      workerId: workerId,
      jobId: jobId,
      message: trimmedMessage,
    );
  }

  @override
  Future<Application> withdrawApplication({
    required String applicationId,
    String? message,
  }) async {
    final trimmedMessage = message?.trim();
    final payload = <String, dynamic>{
      if (trimmedMessage != null && trimmedMessage.isNotEmpty)
        'message': trimmedMessage,
    };

    try {
      final response = await client.patch(
        resolve('/workers/me/applications/$applicationId/withdraw'),
        headers: headers(authToken: _authToken),
        body: payload.isEmpty ? null : jsonEncode(payload),
      );

      return _parseApplicationResponse(response);
    } on ApiWorkConnectException catch (error) {
      if (_shouldUseLegacyApplicationsEndpoint(error.statusCode)) {
        return _withdrawApplicationLegacy(
          applicationId: applicationId,
          message: trimmedMessage,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<AttendanceRecord>> fetchWorkerAttendance(String workerId) async {
    try {
      final response = await client.get(
        resolve('api/workers/$workerId/attendance'),
        headers: headers(authToken: _authToken),
      );
      final data = decodeJsonList(response);
      return data.map(_parseAttendanceRecord).toList();
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode != 404 &&
          error.statusCode != 405 &&
          error.statusCode != 501) {
        rethrow;
      }
      try {
        final response = await client.get(
          resolveWithQuery(
            '/attendance',
            query: {'workerId': workerId},
          ),
          headers: headers(authToken: _authToken),
        );
        final fallback = decodeJsonList(response);
        return fallback.map(_parseAttendanceRecord).toList();
      } on ApiWorkConnectException catch (fallbackError) {
        if (fallbackError.statusCode == 404) {
          return const <AttendanceRecord>[];
        }
        rethrow;
      }
    }
  }

  @override
  Future<AttendanceSchedule> fetchWorkerAttendanceSchedule({
    required String workerId,
    String status = 'all',
    DateTime? from,
    DateTime? to,
    String? jobId,
    String? businessId,
  }) async {
    // Auto-extract business_id from current user if not provided
    final resolvedBusinessId = businessId ?? _currentUserBusinessId;

    final query = <String, dynamic>{
      if (status.isNotEmpty) 'status': status,
      if (from != null) 'from': DateFormat('yyyy-MM-dd').format(from),
      if (to != null) 'to': DateFormat('yyyy-MM-dd').format(to),
      if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
      if (resolvedBusinessId != null && resolvedBusinessId.isNotEmpty)
        'businessId': resolvedBusinessId,
    };

    try {
      final response = await client.get(
        resolveWithQuery(
          '/workers/$workerId/attendance/schedule',
          query: query.isEmpty ? null : query,
        ),
        headers: headers(authToken: _authToken),
      );

      final json = decodeJson(response);
      final statusFilter = _normalizeScheduleStatus(
        _string(json['status']) ?? _string(json['statusFilter']) ?? status,
      );
      final fromDate =
          _parseDate(_string(json['from']) ?? _string(json['start']));
      final toDate = _parseDate(_string(json['to']) ?? _string(json['end']));
      final scheduleRaw = _list(json['schedule']) ??
          _list(json['data']) ??
          _list(json['records']) ??
          const <dynamic>[];

      final days = <AttendanceScheduleDay>[];
      var totalHours = double.tryParse(_string(json['totalHours']) ?? '') ?? 0;
      var totalEarnings =
          double.tryParse(_string(json['totalEarnings']) ?? '') ?? 0;
      var totalRecords = int.tryParse(_string(json['totalRecords']) ?? '') ?? 0;

      for (final entry in scheduleRaw) {
        final day = _parseScheduleDay(entry);
        if (day != null) {
          days.add(day);
        }
      }

      days.sort((a, b) => a.date.compareTo(b.date));

      if (totalHours == 0 || totalHours.isNaN) {
        totalHours = days.fold<double>(
          0,
          (value, element) => value + element.totalHours,
        );
      }
      if (totalEarnings == 0 || totalEarnings.isNaN) {
        totalEarnings = days.fold<double>(
          0,
          (value, element) => value + element.totalEarnings,
        );
      }
      if (totalRecords == 0) {
        totalRecords = days.fold<int>(
          0,
          (value, element) => value + element.records.length,
        );
      }

      final workerName = _string(json['workerName']) ??
          _string(_mapOrNull(json['worker'])?['name']) ??
          (days.isNotEmpty
              ? days
                  .expand((day) => day.records)
                  .map((record) => record.workerName)
                  .firstWhere(
                    (name) => name != null && name.trim().isNotEmpty,
                    orElse: () => null,
                  )
              : null);

      return AttendanceSchedule(
        workerId: workerId,
        workerName: workerName,
        statusFilter: statusFilter,
        days: days,
        from: fromDate,
        to: toDate,
        totalHours: totalHours,
        totalEarnings: totalEarnings,
        totalRecords: totalRecords,
      );
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode != 404 && error.statusCode != 405) {
        rethrow;
      }

      final records = await fetchWorkerAttendance(workerId);
      return _buildScheduleFromRecords(
        workerId: workerId,
        status: status,
        records: records,
      );
    }
  }

  @override
  Future<List<Shift>> fetchWorkerShifts(String workerId) async {
    try {
      final response = await client.get(
        resolve('api/workers/$workerId/shifts'),
        headers: headers(authToken: _authToken),
      );
      final json = decodeJson(response);
      final shifts = _listOrEmpty(json['shifts']);
      return shifts.map(_parseShift).toList();
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode == 404) {
        return const <Shift>[];
      }
      rethrow;
    }
  }

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
  Future<WorkerDashboardMetrics> fetchWorkerDashboardMetrics(
    String workerId,
  ) async {
    Map<String, dynamic>? metricsJson;
    final endpoint = workerId == 'me'
        ? '/workers/me/dashboard'
        : '/workers/$workerId/dashboard';
    final requestHeaders = headers(authToken: _authToken);
    try {
      final response = await client.get(
        resolveWithQuery(
          endpoint,
          query: const {
            'include': 'freeTier,premium,counts',
          },
        ),
        headers: requestHeaders,
      );
      final json = decodeJson(response);
      metricsJson =
          _mapOrNull(json['metrics']) ?? _mapOrNull(json['data']) ?? json;
      final metrics = _parseWorkerDashboardMetrics(metricsJson);
      await _cache?.writeMetrics(metrics);
      return metrics;
    } on ApiWorkConnectException catch (error) {
      if (error.statusCode != 404 &&
          error.statusCode != 405 &&
          error.statusCode != 501) {
        debugPrint('⚠️ Worker metrics fetch failed ($endpoint): $error');
        rethrow;
      }
      debugPrint('ℹ️ Worker metrics fallback used ($endpoint): $error');
    } catch (error, stackTrace) {
      debugPrint('⚠️ Worker metrics unexpected error: $error');
      debugPrint(stackTrace.toString());
    }
    final fallback = await _computeWorkerMetricsFallback(workerId);
    await _cache?.writeMetrics(fallback);
    return fallback;
  }

  // Private helper methods
  Future<WorkerDashboardMetrics> _computeWorkerMetricsFallback(
    String workerId,
  ) async {
    final jobs = await fetchWorkerJobs(workerId);
    final applications = await fetchWorkerApplications(workerId);
    final attendance = await fetchWorkerAttendance(workerId);
    final shifts = await fetchWorkerShifts(workerId);

    final availableJobs =
        jobs.where((job) => job.status == JobStatus.active).length;
    final activeApplications =
        applications.where((app) => app.status == 'pending').length;
    final upcomingShifts =
        shifts.where((shift) => shift.start.isAfter(DateTime.now())).length;
    final completedAttendance = attendance
        .where((record) => record.status == AttendanceStatus.completed)
        .toList();
    final completedHours = completedAttendance.fold<double>(
      0,
      (sum, record) => sum + record.totalHours,
    );
    final now = DateTime.now();
    final earningsThisWeek = completedAttendance.where((record) {
      final start = record.scheduledStart;
      final diff = now.difference(start).inDays;
      return diff <= 7 && diff >= 0;
    }).fold<double>(0, (sum, record) => sum + record.earnings);

    return WorkerDashboardMetrics(
      availableJobs: availableJobs,
      activeApplications: activeApplications,
      upcomingShifts: upcomingShifts,
      completedHours: completedHours,
      earningsThisWeek: earningsThisWeek,
      freeApplicationsRemaining: 3,
      isPremium: false,
    );
  }

  Future<List<Application>> _fetchWorkerApplicationsLegacy(
    String workerId,
  ) async {
    List<dynamic> data = const <dynamic>[];
    try {
      final response = await client.get(
        resolve('api/workers/$workerId/applications'),
        headers: headers(authToken: _authToken),
      );
      data = decodeJsonList(response);
    } on ApiWorkConnectException catch (error) {
      if (!_shouldUseLegacyApplicationsEndpoint(error.statusCode)) {
        rethrow;
      }
    }

    if (data.isEmpty) {
      try {
        final response = await client.get(
          resolve('api/applications/me'),
          headers: headers(authToken: _authToken),
        );
        data = decodeJsonList(response);
      } on ApiWorkConnectException catch (error) {
        if (error.statusCode != 404) {
          rethrow;
        }
      }
    }

    if (data.isEmpty) {
      try {
        final response = await client.get(
          resolveWithQuery(
            '/applications',
            query: {'workerId': workerId},
          ),
          headers: headers(authToken: _authToken),
        );
        data = decodeJsonList(response);
      } on ApiWorkConnectException catch (fallbackError) {
        if (fallbackError.statusCode == 404) {
          return const <Application>[];
        }
        rethrow;
      }
    }

    return data.map(_parseApplication).toList();
  }

  Future<Application> _submitJobApplicationLegacy({
    required String workerId,
    required String jobId,
    String? message,
  }) async {
    final payload = <String, dynamic>{
      'jobId': jobId,
      'workerId': workerId,
      if (message != null && message.isNotEmpty) 'note': message,
    };

    final response = await client.post(
      resolve('api/applications'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(payload),
    );

    return _parseApplicationResponse(response);
  }

  Future<Application> _withdrawApplicationLegacy({
    required String applicationId,
    String? message,
  }) async {
    final payload = <String, dynamic>{
      'status': 'withdrawn',
      if (message != null && message.isNotEmpty) 'note': message,
    };

    final response = await client.patch(
      resolve('api/applications/$applicationId'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(payload),
    );

    return _parseApplicationResponse(response);
  }

  Application _parseApplicationResponse(http.Response response) {
    final decoded = decodeJson(response);
    final Map<String, dynamic> container = _mapOrNull(decoded['data']) ??
        (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});

    Map<String, dynamic>? applicationJson =
        _mapOrNull(container['application']) ??
            _mapOrNull(decoded['application']) ??
            _mapOrNull(container['data']);

    if (applicationJson == null) {
      for (final value in container.values) {
        applicationJson = _mapOrNull(value);
        if (applicationJson != null) {
          break;
        }
      }
    }

    applicationJson ??= _mapOrNull(decoded['data']);

    if (applicationJson == null) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Invalid application response structure: ${response.body}',
      );
    }

    return _parseApplication(applicationJson);
  }

  bool _shouldUseLegacyApplicationsEndpoint(int? statusCode) {
    if (statusCode == null) {
      return false;
    }
    return statusCode == 404 || statusCode == 405 || statusCode == 501;
  }

  Map<String, dynamic>? _buildWorkerJobQuery(String status) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) {
      return {'status': 'active'};
    }
    if (trimmed.toLowerCase() == 'all') {
      return null;
    }
    return {'status': trimmed};
  }

  Future<List<dynamic>> _fetchWorkerJobsPayload({
    Map<String, dynamic>? query,
    required String debugLabel,
  }) async {
    final effectiveQuery = query == null || query.isEmpty ? null : query;
    final endpoint = '/jobs';

    print(
        '🔍 DEBUG: Worker fetching jobs ($debugLabel) with query: $effectiveQuery');
    print('🔍 DEBUG: Auth token available: ${_authToken != null}');
    print('🔍 DEBUG: Auth token length: ${_authToken?.length ?? 0}');

    final response = await get(
      resolveWithQuery(endpoint, query: effectiveQuery),
      headers: headers(authToken: _authToken),
    );

    print(
        '📊 DEBUG: Worker jobs API response status [$debugLabel]: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ DEBUG: Non-200 response [$debugLabel]: ${response.body}');
    } else {
      print('✅ DEBUG: Successful API response [$debugLabel]');
      print(
          '🔍 DEBUG: Response body preview [$debugLabel]: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
    }

    final decoded = decodeJson(response);
    final data = _listOrEmpty(decoded['data']);

    if (data.isEmpty && decoded.containsKey('results')) {
      final results = decoded['results'];
      print(
          '⚠️ DEBUG: API returned $results results but data array is empty [$debugLabel]');
    }

    print('📈 DEBUG: Parsed job data count [$debugLabel]: ${data.length}');
    print(
        '🗂️ DEBUG: Full API response structure [$debugLabel]: ${decoded.keys.toList()}');

    return data;
  }

  bool _isNotFoundOrUnauthorized(int? statusCode) {
    if (statusCode == null) {
      return false;
    }
    return statusCode == 404 || statusCode == 401;
  }

  // Helper methods for parsing JSON responses
  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> _buildLocationPayload(Location location) {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      if (location.accuracy != null) 'accuracy': location.accuracy,
      if (location.altitude != null) 'altitude': location.altitude,
      if (location.heading != null) 'heading': location.heading,
      if (location.speed != null) 'speed': location.speed,
      if (location.address != null) 'address': location.address,
      if (location.timestamp != null)
        'timestamp': location.timestamp!.toIso8601String(),
    };
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

  List<dynamic>? _list(dynamic value) {
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
    return null;
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'true' : 'false';
    return null;
  }

  JobPosting _parseJobPosting(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';

    try {
      // Debug logging to see raw job data
      print('DEBUG: Parsing job with ID: $id');

      final title = _string(json['title']) ?? 'Job';
      final description = _string(json['description']) ?? '';

      // Enhanced employer ID parsing - check multiple possible formats
      String employerId = '';
      if (json['employerId'] != null) {
        employerId = _string(json['employerId']) ?? '';
      } else if (json['employer'] != null) {
        final employer = json['employer'];
        if (employer is String) {
          employerId = employer;
        } else if (employer is Map<String, dynamic>) {
          // If employer is populated, get the ID
          employerId =
              _string(employer['id']) ?? _string(employer['_id']) ?? '';
        }
      }

      // Enhanced business ID parsing
      String businessId = '';
      if (json['businessId'] != null) {
        businessId = _string(json['businessId']) ?? '';
      } else if (json['business'] != null) {
        final business = json['business'];
        if (business is String) {
          businessId = business;
        } else if (business is Map<String, dynamic>) {
          businessId =
              _string(business['id']) ?? _string(business['_id']) ?? '';
        }
      }

      final hourlyRate =
          double.tryParse(_string(json['hourlyRate']) ?? '') ?? 0;
      final overtimeRate =
          double.tryParse(_string(json['overtimeRate']) ?? '') ??
              (hourlyRate * 1.5);
      final urgency = _string(json['urgency']) ?? 'medium';
      final tags = json['tags'] is List
          ? (json['tags'] as List).map((t) => t.toString()).toList()
          : <String>[];
      final workDays = json['workDays'] is List
          ? (json['workDays'] as List).map((d) => d.toString()).toList()
          : <String>[];
      final isVerificationRequired =
          _string(json['verificationRequired'])?.toLowerCase() == 'true';
      final scheduleStart =
          DateTime.tryParse(_string(json['startDate']) ?? '') ?? DateTime.now();
      final scheduleEnd = DateTime.tryParse(_string(json['endDate']) ?? '') ??
          scheduleStart.add(const Duration(hours: 4));
      final status = _parseJobStatus(_string(json['status']));
      final postedAt =
          DateTime.tryParse(_string(json['createdAt']) ?? '') ?? DateTime.now();
      final distanceMiles =
          double.tryParse(_string(json['distanceMiles']) ?? '') ?? 0;
      final hasApplied = _string(json['hasApplied'])?.toLowerCase() == 'true';
      final premiumRequired =
          _string(json['premiumRequired'])?.toLowerCase() == 'true';
      final locationSummary = _string(json['locationSummary']);

      // Safe parsing of applicantsCount with detailed error handling
      int applicantsCount = 0;
      try {
        final applicantsCountRaw = json['applicantsCount'];
        applicantsCount = int.tryParse(_string(applicantsCountRaw) ?? '') ?? 0;
      } catch (e) {
        applicantsCount = 0;
      }

      // Parse business-related fields with safe handling
      final businessName = _string(json['businessName']) ??
          _string(json['businessDetails']?['name']) ??
          '';
      final businessLogoUrl = _string(json['businessLogoUrl']) ??
          _string(json['businessDetails']?['logoUrl']);
      final businessLogoOriginalUrl =
          _string(json['businessLogoOriginalUrl']) ??
              _string(json['businessDetails']?['logo']?['original']?['url']);
      final businessLogoSquareUrl = _string(json['businessLogoSquareUrl']) ??
          _string(json['businessDetails']?['logo']?['square']?['url']);

      // Parse publish status fields
      final isPublished = json['isPublished'] as bool? ??
          true; // Default to true for published jobs
      final publishStatus =
          _string(json['publishStatus']) ?? 'published'; // Default to published

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
        businessLogoUrl: businessLogoUrl,
        businessLogoOriginalUrl: businessLogoOriginalUrl,
        businessLogoSquareUrl: businessLogoSquareUrl,
        isPublished: isPublished,
        publishStatus: publishStatus,
      );
    } catch (e, stackTrace) {
      print('ERROR: Failed to parse job posting: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Raw JSON: $json');
      rethrow;
    }
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

  ApplicationStatus _parseApplicationStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'hired':
      case 'accepted':
      case 'offer_accepted':
        return ApplicationStatus.hired;
      case 'rejected':
      case 'declined':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.rejected;
      case 'pending':
      case 'in_review':
      case 'in-review':
      case 'review':
      default:
        return ApplicationStatus.pending;
    }
  }

  Application _parseApplication(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};

    // Debug logging for application parsing
    print('DEBUG: Parsing application with ID: ${json['_id'] ?? json['id']}');
    print('DEBUG: Raw job field: ${json['job']}');
    print('DEBUG: Raw jobId field: ${json['jobId']}');

    try {
      final app = Application.fromJson(json);
      print(
          'DEBUG: Successfully parsed using Application.fromJson, jobId: ${app.jobId}');
      return app;
    } catch (error) {
      print(
          'DEBUG: Error parsing application with Application.fromJson: $error');
      print('DEBUG: Falling back to manual parsing');

      final workerMap = _mapOrNull(json['worker']);
      final snapshot = _mapOrNull(json['snapshot']);

      final id = _string(json['_id']) ?? _string(json['id']) ?? '';
      final workerId =
          _string(json['worker']) ?? _string(json['workerId']) ?? '';

      // Enhanced job ID parsing - handle ObjectId references and MongoDB formats
      String jobId = '';
      final jobField = json['job'];
      final jobIdField = json['jobId'];

      // Try to extract job ID from various formats
      if (jobField != null) {
        if (jobField is String) {
          jobId = jobField;
        } else if (jobField is Map<String, dynamic>) {
          // Handle ObjectId reference format: {"$oid": "..."}
          jobId = _string(jobField['\$oid']) ??
              _string(jobField['_id']) ??
              _string(jobField['id']) ??
              '';
        }
      }

      if (jobId.isEmpty && jobIdField != null) {
        if (jobIdField is String) {
          jobId = jobIdField;
        } else if (jobIdField is Map<String, dynamic>) {
          // Handle ObjectId reference format: {"$oid": "..."}
          jobId = _string(jobIdField['\$oid']) ??
              _string(jobIdField['_id']) ??
              _string(jobIdField['id']) ??
              '';
        }
      }

      print('DEBUG: Manual parsing - final job ID: $jobId');

      final statusString = _string(json['status']) ?? 'pending';
      final message = _string(json['message']) ?? _string(json['note']);
      final createdAt =
          DateTime.tryParse(_string(json['createdAt']) ?? '') ?? DateTime.now();

      final workerName = _string(json['workerName']) ??
          _string(snapshot?['name']) ??
          [
            _string(workerMap?['firstName']) ?? '',
            _string(workerMap?['lastName']) ?? '',
          ].where((part) => part.isNotEmpty).join(' ');

      final workerExperience = _string(json['workerExperience']) ??
          _string(snapshot?['experience']) ??
          _string(workerMap?['experience']);

      final skillsSource = snapshot?['skills'] ?? workerMap?['skills'];
      final workerSkills = _listOrEmpty(skillsSource)
          .map((skill) => _string(skill)?.trim() ?? '')
          .where((skill) => skill.isNotEmpty)
          .toList();

      return Application(
        id: id,
        workerId: workerId,
        jobId: jobId,
        status: _parseApplicationStatus(statusString),
        rawStatus: statusString,
        message: message,
        createdAt: createdAt,
        submittedAt: createdAt,
        workerName: workerName,
        workerExperience: workerExperience,
        workerSkills: workerSkills,
      );
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

  AttendanceScheduleDay? _parseScheduleDay(dynamic value) {
    final json = _mapOrNull(value);
    List<dynamic> rawRecords = const <dynamic>[];
    if (json == null) {
      if (value is List) {
        rawRecords = value;
      } else if (value != null) {
        rawRecords = [value];
      }
    } else {
      rawRecords = _list(json['records']) ??
          _list(json['entries']) ??
          _list(json['attendance']) ??
          _list(json['items']) ??
          _list(json['shifts']) ??
          const <dynamic>[];
      if (rawRecords.isEmpty) {
        final single = _mapOrNull(json['record']);
        if (single != null) {
          rawRecords = [single];
        }
      }
    }

    if (rawRecords.isEmpty) {
      return null;
    }

    final records = rawRecords.map(_parseAttendanceRecord).toList();

    final summaryJson = json == null ? null : _mapOrNull(json['summary']);
    final dateString = json == null
        ? null
        : _string(json['date']) ??
            _string(json['day']) ??
            _string(json['scheduledDate']) ??
            _string(json['dateKey']);
    DateTime? date = _parseDate(dateString);
    if (date == null && records.isNotEmpty) {
      final first = records.first.scheduledStart;
      date = DateTime(first.year, first.month, first.day);
    }
    date ??= DateTime.now();

    final totalHours = double.tryParse(_string(json?['totalHours']) ?? '') ??
        double.tryParse(_string(summaryJson?['totalHours']) ?? '') ??
        records.fold<double>(0, (value, record) => value + record.totalHours);

    final totalEarnings =
        double.tryParse(_string(json?['totalEarnings']) ?? '') ??
            double.tryParse(_string(summaryJson?['totalEarnings']) ?? '') ??
            records.fold<double>(0, (value, record) => value + record.earnings);

    final scheduledCount = int.tryParse(
          _string(json?['scheduledCount']) ??
              _string(summaryJson?['scheduled']) ??
              _string(summaryJson?['scheduledCount']) ??
              '',
        ) ??
        records
            .where((record) => record.status == AttendanceStatus.scheduled)
            .length;

    final completedCount = int.tryParse(
          _string(json?['completedCount']) ??
              _string(summaryJson?['completed']) ??
              _string(summaryJson?['completedCount']) ??
              '',
        ) ??
        records
            .where((record) => record.status == AttendanceStatus.completed)
            .length;

    return AttendanceScheduleDay(
      date: date,
      records: records,
      totalHours: totalHours,
      totalEarnings: totalEarnings,
      scheduledCount: scheduledCount,
      completedCount: completedCount,
    );
  }

  AttendanceSchedule _buildScheduleFromRecords({
    required String workerId,
    required String status,
    required List<AttendanceRecord> records,
  }) {
    final grouped = <DateTime, List<AttendanceRecord>>{};
    for (final record in records) {
      final key = DateTime(
        record.scheduledStart.year,
        record.scheduledStart.month,
        record.scheduledStart.day,
      );
      grouped.putIfAbsent(key, () => <AttendanceRecord>[]).add(record);
    }

    final days = grouped.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
      final dayHours =
          sorted.fold<double>(0, (value, record) => value + record.totalHours);
      final dayEarnings = sorted.fold<double>(
        0,
        (value, record) => value + record.earnings,
      );
      final scheduledCount = sorted
          .where((record) => record.status == AttendanceStatus.scheduled)
          .length;
      final completedCount = sorted
          .where((record) => record.status == AttendanceStatus.completed)
          .length;

      return AttendanceScheduleDay(
        date: entry.key,
        records: sorted,
        totalHours: dayHours,
        totalEarnings: dayEarnings,
        scheduledCount: scheduledCount,
        completedCount: completedCount,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final workerName = records.map((record) => record.workerName).firstWhere(
          (name) => name != null && name.trim().isNotEmpty,
          orElse: () => null,
        );

    final totalHours = days.fold<double>(
      0,
      (value, element) => value + element.totalHours,
    );
    final totalEarnings = days.fold<double>(
      0,
      (value, element) => value + element.totalEarnings,
    );

    return AttendanceSchedule(
      workerId: workerId,
      workerName: workerName,
      statusFilter: _normalizeScheduleStatus(status),
      days: days,
      totalHours: totalHours,
      totalEarnings: totalEarnings,
      totalRecords: records.length,
    );
  }

  String _normalizeScheduleStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'scheduled':
      case 'pending':
        return 'scheduled';
      case 'clocked-in':
      case 'clockedin':
      case 'clocked_in':
      case 'in-progress':
      case 'inprogress':
      case 'in_progress':
        return 'clocked-in';
      case 'completed':
      case 'complete':
      case 'success':
      case 'successful':
      case 'finished':
      case 'done':
        return 'completed';
      case 'missed':
      case 'no-show':
      case 'noshow':
      case 'absent':
        return 'missed';
      case 'all':
      case null:
      case '':
        return 'all';
      default:
        return 'all';
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return null;
  }

  Shift _parseShift(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final jobId = _string(json['jobId']) ?? _string(json['job']) ?? '';
    final workerId = _string(json['workerId']) ?? _string(json['worker']) ?? '';
    final start =
        DateTime.tryParse(_string(json['start']) ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(_string(json['end']) ?? '') ??
        start.add(const Duration(hours: 4));
    final status = _parseShiftStatus(_string(json['status']));
    final canSwap = _string(json['canSwap'])?.toLowerCase() == 'true';
    final isEligibleForSwap =
        _string(json['isEligibleForSwap'])?.toLowerCase() == 'true';
    final locationSummary = _string(json['locationSummary']);

    return Shift(
      id: id.isEmpty ? jobId : id,
      jobId: jobId,
      workerId: workerId,
      start: start,
      end: end,
      status: status,
      canSwap: canSwap,
      isEligibleForSwap: isEligibleForSwap,
      locationSummary: locationSummary,
    );
  }

  ShiftStatus _parseShiftStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'swap_requested':
      case 'swaprequested':
        return ShiftStatus.swapRequested;
      case 'swap_pending':
      case 'swappending':
        return ShiftStatus.swapPending;
      case 'swapped':
        return ShiftStatus.swapped;
      case 'assigned':
      default:
        return ShiftStatus.assigned;
    }
  }

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

  WorkerDashboardMetrics _parseWorkerDashboardMetrics(
    Map<String, dynamic>? json,
  ) {
    final metrics = _mapOrNull(json) ?? const <String, dynamic>{};
    final profile = _mapOrNull(metrics['profile']);
    final counts = _mapOrNull(metrics['counts']);
    final applications = _mapOrNull(metrics['applications']);
    final byStatus = _mapOrNull(applications?['byStatus']);
    final freeTier = _mapOrNull(metrics['freeTier']);
    final premium = _mapOrNull(metrics['premium']);

    int? asInt(dynamic value) {
      final stringValue = _string(value);
      if (stringValue == null || stringValue.isEmpty) return null;
      return int.tryParse(stringValue);
    }

    double? asDouble(dynamic value) {
      final stringValue = _string(value);
      if (stringValue == null || stringValue.isEmpty) return null;
      return double.tryParse(stringValue);
    }

    bool? asBool(dynamic value) {
      if (value is bool) return value;
      final stringValue = _string(value)?.toLowerCase();
      if (stringValue == null) return null;
      if (stringValue == 'true' || stringValue == '1' || stringValue == 'yes') {
        return true;
      }
      if (stringValue == 'false' || stringValue == '0' || stringValue == 'no') {
        return false;
      }
      return null;
    }

    int? deriveRemaining(int? limitValue, int? usedValue) {
      if (limitValue == null || usedValue == null) return null;
      final remaining = limitValue - usedValue;
      if (remaining < 0) return 0;
      if (remaining > limitValue) return limitValue;
      return remaining;
    }

    final availableJobs = asInt(metrics['availableJobs']) ??
        asInt(counts?['availableJobs']) ??
        asInt(counts?['totalJobs']) ??
        0;
    final pendingApplications =
        asInt(byStatus?['pending']) ?? asInt(applications?['pending']);
    final activeApplications = asInt(metrics['activeApplications']) ??
        pendingApplications ??
        asInt(applications?['total']) ??
        0;
    final upcomingShifts = asInt(metrics['upcomingShifts']) ??
        asInt(counts?['upcomingShifts']) ??
        asInt(counts?['weeklyShifts']) ??
        asInt(counts?['monthlyShifts']) ??
        0;
    final completedHours = asDouble(metrics['completedHours']) ??
        asDouble(profile?['completedHours']) ??
        asInt(counts?['totalAttendance'])?.toDouble() ??
        0;
    final earningsThisWeek = asDouble(metrics['earningsThisWeek']) ??
        asDouble(profile?['weeklyEarnings']) ??
        0;
    final limit = asInt(freeTier?['jobApplicationsLimit']);
    final used = asInt(freeTier?['jobApplicationsUsed']);
    final derivedRemaining = deriveRemaining(limit, used);
    final freeApplicationsRemaining =
        asInt(metrics['freeApplicationsRemaining']) ??
            asInt(freeTier?['remainingApplications']) ??
            derivedRemaining ??
            3;
    final isPremium =
        asBool(metrics['isPremium']) ?? asBool(premium?['isActive']) ?? false;

    return WorkerDashboardMetrics(
      availableJobs: availableJobs,
      activeApplications: activeApplications,
      upcomingShifts: upcomingShifts,
      completedHours: completedHours,
      earningsThisWeek: earningsThisWeek,
      freeApplicationsRemaining: freeApplicationsRemaining,
      isPremium: isPremium,
    );
  }

  @override
  Future<AttendanceRecord> clockIn(
    String recordId, {
    required Location location,
  }) async {
    final payload = _buildLocationPayload(location);
    if (kDebugMode) {
      print(
        '🕒 [WorkerClockIn] POST /attendance/$recordId/clock-in payload: ${jsonEncode(payload)}',
      );
    }
    final response = await client.post(
      resolve('/attendance/$recordId/clock-in'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(payload),
    );
    if (kDebugMode) {
      print(
        '🕒 [WorkerClockIn] response ${response.statusCode}: ${response.body}',
      );
    }
    final json = decodeJson(response);
    final responsePayload =
        _mapOrNull(json['attendance']) ?? _mapOrNull(json['data']) ?? json;
    return _parseAttendanceRecord(responsePayload);
  }

  @override
  Future<AttendanceRecord> clockOut(
    String recordId, {
    required Location location,
    double? hourlyRate,
  }) async {
    final body = _buildLocationPayload(location);
    if (hourlyRate != null) {
      body['hourlyRate'] = hourlyRate;
    }
    if (kDebugMode) {
      print(
        '🕒 [WorkerClockOut] POST /attendance/$recordId/clock-out payload: ${jsonEncode(body)}',
      );
    }

    final response = await client.post(
      resolve('/attendance/$recordId/clock-out'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );
    if (kDebugMode) {
      print(
        '🕒 [WorkerClockOut] response ${response.statusCode}: ${response.body}',
      );
    }
    final json = decodeJson(response);
    final responsePayload =
        _mapOrNull(json['attendance']) ?? _mapOrNull(json['data']) ?? json;
    return _parseAttendanceRecord(responsePayload);
  }

  @override
  Future<AttendanceRecord> updateAttendance(
    String recordId,
    Map<String, dynamic> body,
  ) async {
    final response = await client.patch(
      resolve('/attendance/$recordId'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );
    final json = decodeJson(response);
    final responsePayload =
        _mapOrNull(json['attendance']) ?? _mapOrNull(json['data']) ?? json;
    return _parseAttendanceRecord(responsePayload);
  }

  @override
  Future<SwapRequest> requestSwap({
    required String shiftId,
    required String toWorkerId,
    String? message,
  }) async {
    final body = {
      'shiftId': shiftId,
      'toWorkerId': toWorkerId,
      if (message != null) 'message': message,
    };

    final response = await client.post(
      resolve('/shift-swaps'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );
    final json = decodeJson(response);
    return _parseSwapRequest(json['swapRequest'] ?? json);
  }

  @override
  Future<SwapRequest> respondSwap({
    required String swapId,
    required String status, // "approved" | "rejected"
    String? message,
  }) async {
    final body = {
      'status': status,
      if (message != null) 'message': message,
    };

    final response = await client.patch(
      resolve('/shift-swaps/$swapId'),
      headers: headers(authToken: _authToken),
      body: jsonEncode(body),
    );
    final json = decodeJson(response);
    return _parseSwapRequest(json['swapRequest'] ?? json);
  }
}
