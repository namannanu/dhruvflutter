// ignore_for_file: require_trailing_commas, avoid_print

import 'dart:convert';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/job/services/job_service.dart';

class ApiJobService extends BaseApiService implements JobService {
  ApiJobService({
    required super.baseUrl,
    super.enableLogging,
  });

  /// Always fetch the latest token from ServiceLocator
  String? get _authToken => ServiceLocator.instance.authToken;

  @override
  Future<JobPosting> createJob({
    required String title,
    required String description,
    required double hourlyRate,
    required String businessId,
    required DateTime start,
    required DateTime end,
    List<String>? tags,
    String urgency = 'medium',
    bool verificationRequired = false,
    Map<String, dynamic>? location,
    bool hasOvertime = false,
    double? overtimeRate,
    String recurrence = 'one-time',
    List<String>? workDays,
  }) async {
    const endpoint = 'api/jobs';
    final normalizedWorkDays = (workDays ?? [])
        .map((day) => day.trim().toLowerCase())
        .where((day) => day.isNotEmpty)
        .toList();

    Map<String, dynamic>? normalizedLocation;
    if (location != null && location.isNotEmpty) {
      double? parseDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString());
      }

      final latitude = parseDouble(location['latitude']);
      final longitude = parseDouble(location['longitude']);
      final allowedRadius = parseDouble(location['allowedRadius']);

      normalizedLocation = {
        if (location['address'] != null)
          'address': location['address'].toString(),
        if (location['line1'] != null) 'line1': location['line1'].toString(),
        if (location['line2'] != null) 'line2': location['line2'].toString(),
        if (location['city'] != null) 'city': location['city'].toString(),
        if (location['state'] != null) 'state': location['state'].toString(),
        if (location['postalCode'] != null)
          'postalCode': location['postalCode'].toString(),
        if (location['country'] != null)
          'country': location['country'].toString(),
        if (location['formattedAddress'] != null)
          'formattedAddress': location['formattedAddress'].toString(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (allowedRadius != null) 'allowedRadius': allowedRadius,
        if (location['notes'] != null) 'notes': location['notes'].toString(),
      };
    }

    final startUtc = DateTime.utc(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );
    final endUtc = DateTime.utc(
      end.year,
      end.month,
      end.day,
      end.hour,
      end.minute,
    );

    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'hourlyRate': hourlyRate,
      'urgency': urgency,
      'tags': tags ?? const <String>[],
      'verificationRequired': verificationRequired,
      'business': businessId,
      'schedule': {
        'startDate': startUtc.toIso8601String(),
        'endDate': endUtc.toIso8601String(),
        'startTime':
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
        'endTime':
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
        'recurrence': recurrence,
        'workDays': normalizedWorkDays,
      },
      'hasOvertime': hasOvertime,
      if (overtimeRate != null) 'overtimeRate': overtimeRate,
      if (normalizedLocation != null) 'location': normalizedLocation,
    };

    final requestHeaders = headers(
      authToken: _authToken,
      businessId: businessId,
    );
    logApiCall('POST', endpoint, requestBody: payload, headers: requestHeaders);

    final response = await client.post(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    logApiCall(
      'POST',
      endpoint,
      requestBody: payload,
      headers: requestHeaders,
      response: response,
    );

    if (response.statusCode != 201) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to create job: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final jobData = _extractJobPayload(responseData);
    final fallbackData = _mapOrNull(responseData['data']) ??
        _mapOrNull(responseData['job']) ??
        _mapOrNull(responseData['result']) ??
        _mapOrNull(responseData['payload']);

    final jobJson = jobData ?? fallbackData ?? responseData;

    final jobJsonMap = _mapOrNull(jobJson) ?? const <String, dynamic>{};

    if (jobData == null && fallbackData == null && !_looksLikeJob(jobJsonMap)) {
      final availableKeys = responseData.keys.join(', ');
      logApiCall(
        'POST',
        endpoint,
        requestBody: payload,
        headers: requestHeaders,
        response: response,
        error: 'Job payload inferred from response keys: [$availableKeys]',
      );
      throw ApiWorkConnectException(
        500,
        'Invalid job data format (keys: [$availableKeys])',
      );
    }

    return _parseJobPosting(jobJsonMap);
  }

  @override
  Future<void> processJobPostingPayment({
    required String jobId,
    required double amount,
    required String currency,
    required String paymentMethodId,
  }) async {
    const endpoint = 'api/payments/job-posting';
    final payload = {
      'jobId': jobId,
      'amount': amount,
      'currency': currency,
      'paymentMethodId': paymentMethodId,
    };

    final requestHeaders = headers(authToken: _authToken);
    logApiCall('POST', endpoint, requestBody: payload, headers: requestHeaders);

    final response = await client.post(
      resolve(endpoint),
      headers: requestHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw ApiWorkConnectException(
        response.statusCode,
        'Failed to process payment: ${response.body}',
      );
    }
  }

  @override
  Future<List<Application>> fetchJobApplications(String jobId) async {
    final endpoint = 'api/jobs/$jobId/applications';
    final requestHeaders = headers(authToken: _authToken);

    final response = await client.get(
      resolve(endpoint),
      headers: requestHeaders,
    );

    final data = decodeJsonList(response);
    return data.map(_parseApplication).toList();
  }

  @override
  Future<Application> applyForJob({
    required String jobId,
    required String workerId,
    String? note,
  }) async {
    final endpoint = 'api/jobs/$jobId/applications';
    final payload = {
      if (note != null) 'message': note,
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
        'Failed to apply for job: ${response.body}',
      );
    }

    final responseData = decodeJson(response);
    final applicationData = _mapOrNull(responseData['data']) ?? responseData;

    return _parseApplication(applicationData);
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? note,
  }) async {
    final endpoint = 'api/applications/$applicationId';
    final payload = {
      'status': status.toString().split('.').last.toLowerCase(),
      if (note != null) 'note': note,
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
        'Failed to update application status: ${response.body}',
      );
    }
  }

  @override
  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    final endpoint = 'api/employers/me/jobs/$jobId/status';
    final payload = {
      'status': status.toString().split('.').last.toLowerCase(),
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
        'Failed to update job status: ${response.body}',
      );
    }
  }

  @override
  Future<JobPosting> updateJob({
    required String jobId,
    String? title,
    String? description,
    double? hourlyRate,
    DateTime? start,
    DateTime? end,
    List<String>? tags,
    String? urgency,
    bool? verificationRequired,
    bool? hasOvertime,
    double? overtimeRate,
    String? recurrence,
    List<String>? workDays,
  }) async {
    final endpoint = 'api/employers/me/jobs/$jobId';
    final payload = <String, dynamic>{};

    // Only add non-null values to the payload
    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;
    if (hourlyRate != null) payload['hourlyRate'] = hourlyRate;
    if (start != null) payload['scheduleStart'] = start.toIso8601String();
    if (end != null) payload['scheduleEnd'] = end.toIso8601String();
    if (tags != null) payload['tags'] = tags;
    if (urgency != null) payload['urgency'] = urgency;
    if (verificationRequired != null) {
      payload['verificationRequired'] = verificationRequired;
    }
    if (hasOvertime != null) payload['hasOvertime'] = hasOvertime;
    if (overtimeRate != null) payload['overtimeRate'] = overtimeRate;
    if (recurrence != null) payload['recurrence'] = recurrence;
    if (workDays != null) payload['workDays'] = workDays;

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
        'Failed to update job: ${response.body}',
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final jobData =
        responseData['data'] as Map<String, dynamic>? ?? responseData;
    return JobPosting.fromJson(jobData);
  }

  // Helper methods for parsing responses
  Map<String, dynamic>? _extractJobPayload(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }

    if (_looksLikeJob(json)) {
      return json;
    }

    const candidateKeys = [
      'job',
      'jobPosting',
      'jobPostingData',
      'jobPosted',
      'jobData',
      'jobDetails',
      'posting',
      'data',
      'result',
      'results',
      'payload',
      'response',
      'body',
      'content',
    ];

    for (final key in candidateKeys) {
      final value = json[key];

      final mapValue = _mapOrNull(value);
      if (mapValue != null) {
        final nested = _extractJobPayload(mapValue);
        if (nested != null) {
          return nested;
        }
      }

      if (value is List) {
        for (final item in value) {
          final itemMap = _mapOrNull(item);
          if (itemMap == null) {
            continue;
          }

          final nested = _extractJobPayload(itemMap);
          if (nested != null) {
            return nested;
          }
        }
      }
    }

    for (final entry in json.entries) {
      if (candidateKeys.contains(entry.key)) {
        continue;
      }

      final value = entry.value;
      final mapValue = _mapOrNull(value);
      if (mapValue != null) {
        final nested = _extractJobPayload(mapValue);
        if (nested != null) {
          return nested;
        }
      }

      if (value is List) {
        for (final item in value) {
          final itemMap = _mapOrNull(item);
          if (itemMap == null) {
            continue;
          }

          final nested = _extractJobPayload(itemMap);
          if (nested != null) {
            return nested;
          }
        }
      }
    }

    return null;
  }

  bool _looksLikeJob(Map<String, dynamic> json) {
    final hasTitle = json.containsKey('title') ||
        json.containsKey('jobTitle') ||
        json.containsKey('name');
    final hasHourlyRate = json.containsKey('hourlyRate') ||
        json.containsKey('rate') ||
        json.containsKey('payRate');
    final hasBusiness =
        json.containsKey('business') || json.containsKey('businessId');
    final hasSchedule = json.containsKey('schedule') ||
        json.containsKey('scheduleStart') ||
        json.containsKey('startDate') ||
        json.containsKey('start');

    if (hasTitle && hasHourlyRate) {
      return true;
    }

    if (hasTitle && (hasBusiness || hasSchedule)) {
      return true;
    }

    if (hasHourlyRate && (hasBusiness || hasSchedule)) {
      return true;
    }

    return false;
  }

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

  String _composeName(Map<String, dynamic>? json) {
    if (json == null) return '';
    // Prefer an explicit full name field if present
    final fullName = _string(json['name']) ?? _string(json['fullName']);
    if (fullName != null && fullName.isNotEmpty) return fullName;

    // Otherwise compose from first/last name variants
    final first = _string(json['firstName']) ?? _string(json['givenName']);
    final last = _string(json['lastName']) ?? _string(json['familyName']);

    final parts = <String>[];
    if (first != null && first.isNotEmpty) parts.add(first);
    if (last != null && last.isNotEmpty) parts.add(last);

    final composed = parts.join(' ');
    return composed.isNotEmpty ? composed : '';
  }

  // Entity parsing methods
  JobPosting _parseJobPosting(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    final employerDetails =
        _mapOrNull(json['employerDetails']) ?? _mapOrNull(json['employer']);
    final businessDetails =
        _mapOrNull(json['businessDetails']) ?? _mapOrNull(json['business']);
    final createdByDetails = _mapOrNull(json['createdByDetails']) ??
        (json['createdBy'] is Map ? _mapOrNull(json['createdBy']) : null);

    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final title = _string(json['title']) ?? '';
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

    final schedule = _mapOrNull(json['schedule']);
    final scheduleStart = DateTime.tryParse(_string(schedule?['startDate']) ??
            _string(json['scheduleStart']) ??
            _string(json['startDate']) ??
            _string(json['start']) ??
            '') ??
        DateTime.now();
    final scheduleEnd = DateTime.tryParse(_string(schedule?['endDate']) ??
            _string(json['scheduleEnd']) ??
            _string(json['endDate']) ??
            _string(json['end']) ??
            '') ??
        scheduleStart.add(const Duration(hours: 4));
    final recurrence = _string(schedule?['recurrence']) ??
        _string(json['recurrence']) ??
        'one-time';
    final workDays = _stringList(schedule?['workDays']) ??
        _stringList(json['workDays']) ??
        <String>[];

    final overtime = _mapOrNull(json['overtime']);
    final overtimeRate = double.tryParse(_string(overtime?['rateMultiplier']) ??
            _string(json['overtimeRate']) ??
            '') ??
        (hourlyRate * 1.5);

    final urgency = _string(json['urgency']) ?? 'medium';
    final tags = _stringList(json['tags']) ?? <String>[];
    final isVerificationRequired = json['verificationRequired'] == true ||
        json['isVerificationRequired'] == true;
    final status = _parseJobStatus(_string(json['status']));
    final postedAt = DateTime.tryParse(_string(json['createdAt']) ??
            _string(json['postedAt']) ??
            '') ??
        DateTime.now();
    final distanceMiles =
        double.tryParse(_string(json['distanceMiles']) ?? '') ?? 0;
    final hasApplied = json['hasApplied'] == true;
    final premiumRequired = json['premiumRequired'] == true;
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
      recurrence: recurrence,
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

  Application _parseApplication(dynamic value) {
    final json = _mapOrNull(value) ?? const <String, dynamic>{};
    try {
      return Application.fromJson(json);
    } catch (error, stackTrace) {
      print('DEBUG: Failed to parse application using fromJson: $error');
      print('DEBUG: Raw application payload: $json');
      print('DEBUG: StackTrace: $stackTrace');

      final worker = _mapOrNull(json['worker']);
      final snapshot = _mapOrNull(json['snapshot']);

      final id = _string(json['id']) ?? _string(json['_id']) ?? '';
      final jobId = _string(json['jobId']) ?? _string(json['job']) ?? '';
      final workerId = _string(json['workerId']) ??
          _string(worker?['id']) ??
          _string(worker?['_id']) ??
          _string(json['worker']) ??
          '';

      final workerName = _string(json['workerName']) ??
          _string(snapshot?['name']) ??
          [
            _string(worker?['firstName']) ?? '',
            _string(worker?['lastName']) ?? '',
          ].where((part) => part.isNotEmpty).join(' ');

      final workerExperience = _string(json['workerExperience']) ??
          _string(snapshot?['experience']) ??
          _string(worker?['experience']) ??
          '';

      final workerSkills = _stringList(snapshot?['skills']) ??
          _stringList(worker?['skills']) ??
          <String>[];

      final jobMap = _mapOrNull(json['job']);
      final employerMap =
          _mapOrNull(json['employer']) ?? _mapOrNull(jobMap?['employer']);
      final businessMap =
          _mapOrNull(json['business']) ?? _mapOrNull(jobMap?['business']);

      String? firstNonEmpty(Iterable<String?> values) {
        for (final value in values) {
          final trimmed = value?.trim();
          if (trimmed != null && trimmed.isNotEmpty) {
            return trimmed;
          }
        }
        return null;
      }

      final employerEmail = firstNonEmpty([
        _string(json['employerEmail']),
        _string(employerMap?['email']),
        _string(jobMap?['employerEmail']),
      ]);

      final employerName = firstNonEmpty([
        _composeName(employerMap),
        _string(json['employerName']),
        _string(jobMap?['employerName']),
        _string(employerMap?['name']),
        employerEmail,
      ]);

      final employerId = firstNonEmpty([
        _string(json['employerId']),
        _string(employerMap?['_id']),
        _string(employerMap?['id']),
        _string(jobMap?['employerId']),
      ]);

      final businessId = firstNonEmpty([
        _string(json['businessId']),
        _string(businessMap?['_id']),
        _string(businessMap?['id']),
        _string(jobMap?['businessId']),
      ]);

      final businessName = firstNonEmpty([
        _string(json['businessName']),
        _string(businessMap?['businessName']),
        _string(businessMap?['name']),
        _string(jobMap?['businessName']),
      ]);

      final statusString = _string(json['status']);
      final status = _parseApplicationStatus(statusString);
      final createdAt =
          DateTime.tryParse(_string(json['createdAt']) ?? '') ?? DateTime.now();
      final note = _string(json['note']) ?? _string(json['message']);
      final message = _string(json['message']);

      return Application(
        id: id.isEmpty ? workerId : id,
        jobId: jobId,
        workerId: workerId,
        status: status,
        rawStatus: statusString,
        createdAt: createdAt,
        submittedAt: createdAt,
        workerName: workerName,
        workerExperience: workerExperience,
        workerSkills: workerSkills,
        note: note,
        message: message,
        employerId: employerId,
        employerEmail: employerEmail,
        employerName: employerName,
        businessId: businessId,
        businessName: businessName,
      );
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
}
