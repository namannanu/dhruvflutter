import 'package:talent/core/models/analytics.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/features/employer/services/attendance_api_service.dart';
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

  AttendanceApiService get _attendanceApi => ServiceLocator.instance.attendance;

  String? _resolveBusinessId(String? businessId) {
    final candidate = (businessId ?? _currentUserBusinessId)?.trim();
    if (candidate == null || candidate.isEmpty) {
      return null;
    }
    return candidate;
  }

  Map<String, dynamic> _mapOrEmpty(dynamic input) {
    if (input == null) return {};
    if (input is Map<String, dynamic>) return input;
    return Map<String, dynamic>.from(input as Map);
  }

  List<dynamic> _listOrEmpty(dynamic input) {
    if (input == null) return [];
    if (input is List) return input;
    return [];
  }

  String? _string(dynamic value) => value?.toString();

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String && value.isNotEmpty) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final stringValue = value.toString();
    if (stringValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(stringValue);
  }

  DateTime? _combineDateAndTime(String? date, dynamic time) {
    final timeDate = _parseDateTime(time);
    if (timeDate != null) {
      return timeDate;
    }
    if (date == null || date.isEmpty) {
      return null;
    }
    final base = DateTime.tryParse(date);
    if (base == null) {
      return null;
    }
    final timeString = time?.toString();
    if (timeString == null || timeString.isEmpty) {
      return base;
    }
    final parts = timeString.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  AttendanceStatus _attendanceStatusFromString(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'clocked-in':
      case 'clockedin':
      case 'clocked_in':
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

  String _attendanceStatusToFilter(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.clockedIn:
        return 'clocked-in';
      case AttendanceStatus.completed:
        return 'completed';
      case AttendanceStatus.missed:
        return 'missed';
      case AttendanceStatus.scheduled:
        return 'scheduled';
    }
  }

  bool _statusMatchesFilter(AttendanceStatus status, String filter) {
    if (filter == 'all') {
      return true;
    }
    return _attendanceStatusToFilter(status) == filter;
  }

  String _normalizeStatusFilter(String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case '':
      case 'all':
        return 'all';
      case 'clockedin':
      case 'clocked_in':
      case 'clocked-in':
        return 'clocked-in';
      case 'completed':
        return 'completed';
      case 'missed':
        return 'missed';
      case 'scheduled':
        return 'scheduled';
      default:
        return normalized;
    }
  }

  AttendanceRecord? _mapManagementAttendanceRecord(
    Map<String, dynamic>? json,
    DateTime fallbackDate,
  ) {
    if (json == null) {
      return null;
    }

    final dateStr = _string(json['date']);
    final scheduledStart =
        _parseDateTime(json['scheduledStart']) ??
            _combineDateAndTime(dateStr, json['scheduledStart']) ??
            DateTime(
              fallbackDate.year,
              fallbackDate.month,
              fallbackDate.day,
            );
    final scheduledEnd =
        _parseDateTime(json['scheduledEnd']) ??
            _combineDateAndTime(dateStr, json['scheduledEnd']) ??
            scheduledStart;
    final clockIn = _parseDateTime(json['clockIn']) ??
        _combineDateAndTime(dateStr, json['clockIn']);
    final clockOut = _parseDateTime(json['clockOut']) ??
        _combineDateAndTime(dateStr, json['clockOut']);

    final locationSummary =
        _string(json['locationSummary']) ?? _string(json['location']);
    final workerAvatar =
        _string(json['workerAvatarUrl']) ?? _string(json['workerAvatar']);

    return AttendanceRecord(
      id: _string(json['id']) ?? _string(json['_id']) ?? '',
      workerId: _string(json['workerId']) ?? '',
      jobId: _string(json['jobId']) ?? '',
      businessId:
          _string(json['businessId']) ?? _string(json['business']) ?? '',
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: _attendanceStatusFromString(json['status']),
      totalHours: _asDouble(json['totalHours'] ?? json['hoursWorked']),
      earnings: _asDouble(json['earnings']),
      isLate: _asBool(json['isLate']),
      clockIn: clockIn,
      clockOut: clockOut,
      locationSummary: locationSummary,
      jobTitle: _string(json['jobTitle']),
      hourlyRate: _asDoubleOrNull(json['hourlyRate']),
      companyName: _string(json['companyName']),
      location: _string(json['location']),
      workerName: _string(json['workerName']),
      workerAvatarUrl: workerAvatar,
    );
  }

  @override
  Map<String, String> headers({String? authToken, String? businessId}) {
    return super.headers(
      authToken: authToken ?? _authToken,
      businessId: businessId ?? _resolveBusinessId(null),
    );
  }

  JobPosting _parseJobPosting(dynamic value) {
    final json = _mapOrEmpty(value);
    final employerDetails =
        _mapOrEmpty(json['employerDetails'] ?? json['employer']);
    final businessDetails =
        _mapOrEmpty(json['businessDetails'] ?? json['business']);
    final createdByDetails =
        _mapOrEmpty(json['createdByDetails'] ?? json['createdBy']);

    final id = _string(json['id']) ?? _string(json['_id']) ?? '';
    final title = _string(json['title']) ?? '';
    final description = _string(json['description']) ?? '';

    final employerId = _string(employerDetails['id']) ??
        _string(employerDetails['_id']) ??
        _string(json['employerId']) ??
        '';

    final businessId = _string(businessDetails['id']) ??
        _string(businessDetails['_id']) ??
        _string(json['businessId']) ??
        '';

    final businessName = _string(businessDetails['name']) ??
        _string(businessDetails['businessName']) ??
        _string(json['businessName']) ??
        '';

    final businessAddress = _string(businessDetails['address']) ??
        _string(businessDetails['businessAddress']) ??
        _string(json['businessAddress']) ??
        '';

    final employerEmail = _string(employerDetails['email']) ??
        _string(json['employerEmail']) ??
        '';
    final employerName =
        _string(employerDetails['name']) ?? _string(json['employerName']) ?? '';

    final createdById = _string(createdByDetails['id']) ??
        _string(createdByDetails['_id']) ??
        _string(json['createdById']) ??
        '';
    final createdByEmail = _string(createdByDetails['email']) ??
        _string(json['createdByEmail']) ??
        '';
    final createdByName = _string(createdByDetails['name']) ??
        _string(json['createdByName']) ??
        '';
    final createdByTag =
        _string(createdByDetails['tag']) ?? _string(json['createdByTag']) ?? '';

    final hourlyRate = double.tryParse(_string(json['hourlyRate']) ?? '') ?? 0;
    final overtimeRate = double.tryParse(_string(json['overtimeRate']) ?? '') ??
        hourlyRate * 1.5;
    final overtime = JobOvertime(
      allowed: overtimeRate > hourlyRate,
      rateMultiplier: overtimeRate / hourlyRate,
    );

    final urgency = _string(json['urgency']) ?? 'medium';
    final tags = _listOrEmpty(json['tags']).map((t) => t.toString()).toList();
    final workDays =
        _listOrEmpty(json['workDays']).map((d) => d.toString()).toList();

    final scheduleStart = DateTime.tryParse(
          _string(json['scheduleStart']) ?? _string(json['startDate']) ?? '',
        ) ??
        DateTime.now();

    final scheduleEnd = DateTime.tryParse(
          _string(json['scheduleEnd']) ?? _string(json['endDate']) ?? '',
        ) ??
        scheduleStart.add(const Duration(hours: 4));

    final isVerificationRequired = json['verificationRequired'] == true ||
        json['isVerificationRequired'] == true;
    final statusStr = _string(json['status']) ?? 'draft';
    final jobStatus = JobStatus.values.firstWhere(
      (s) =>
          s.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => JobStatus.draft,
    );

    final postedAt = DateTime.tryParse(
          _string(json['postedAt']) ?? _string(json['createdAt']) ?? '',
        ) ??
        DateTime.now();

    final distanceMiles =
        double.tryParse(_string(json['distanceMiles']) ?? '') ?? 0;
    final hasApplied = json['hasApplied'] == true;
    final premiumRequired = json['premiumRequired'] == true;
    final locationSummary = _string(json['locationSummary']) ?? '';
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
      overtime: overtime,
      urgency: urgency,
      tags: tags,
      workDays: workDays,
      isVerificationRequired: isVerificationRequired,
      status: jobStatus,
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
      createdById: createdById,
      createdByTag: createdByTag,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
    );
  }

  @override
  Future<AttendanceDashboard> fetchAttendanceDashboard(
      {required DateTime date, String status = 'all'}) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required to fetch attendance data');
    }

    final normalizedStatus = _normalizeStatusFilter(status);

    final response = await _attendanceApi.getManagementView(
      authToken: token,
      date: date,
      status: normalizedStatus == 'all' ? null : normalizedStatus,
    );

    final payload = _mapOrEmpty(response['data']);
    final recordsRaw = _listOrEmpty(payload['records']);

    final records = recordsRaw
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapManagementAttendanceRecord(item, date))
        .whereType<AttendanceRecord>()
        .where(
          (record) => _statusMatchesFilter(record.status, normalizedStatus),
        )
        .toList()
      ..sort(
        (a, b) => a.scheduledStart.compareTo(b.scheduledStart),
      );

    final summaryMap = _mapOrEmpty(payload['summary']);
    final summary = AttendanceDashboardSummary(
      totalWorkers: summaryMap.containsKey('totalWorkers')
          ? _asInt(summaryMap['totalWorkers'])
          : records.length,
      completedShifts: summaryMap.containsKey('completedShifts')
          ? _asInt(summaryMap['completedShifts'])
          : records
              .where((record) => record.status == AttendanceStatus.completed)
              .length,
      totalHours: summaryMap.containsKey('totalHours')
          ? _asDouble(summaryMap['totalHours'])
          : records.fold<double>(
              0,
              (sum, record) => sum + record.totalHours,
            ),
      totalPayroll: summaryMap.containsKey('totalPayroll')
          ? _asDouble(summaryMap['totalPayroll'])
          : records.fold<double>(
              0,
              (sum, record) => sum + record.earnings,
            ),
      lateArrivals: summaryMap.containsKey('lateArrivals')
          ? _asInt(summaryMap['lateArrivals'])
          : records.where((record) => record.isLate).length,
    );

    return AttendanceDashboard(
      date: date,
      statusFilter: normalizedStatus,
      records: records,
      summary: summary,
    );
  }

  @override
  Future<List<BusinessLocation>> fetchBusinessLocations(String ownerId) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required to fetch business locations');
    }

    final response = await get(
      'api/employers/$ownerId/businesses',
      headers: headers(authToken: token),
    );

    final payload = decodeJson(response);
    var businesses = _listOrEmpty(payload['data']);
    if (businesses.isEmpty) {
      businesses = _listOrEmpty(payload['businesses']);
    }

    return businesses
        .whereType<Map<String, dynamic>>()
        .map(BusinessLocation.fromJson)
        .toList();
  }

  @override
  Future<List<Application>> fetchEmployerApplications(
      {ApplicationStatus? status,
      int? limit,
      int? page,
      String? businessId}) async {
    final token = _authToken;
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required to fetch applications');
    }

    final resolvedBusinessId = _resolveBusinessId(businessId);
    final query = <String, dynamic>{
      'limit': (limit ?? 20).toString(),
      'page': (page ?? 1).toString(),
    };

    if (status != null) {
      query['status'] = status.name;
    }

    if (resolvedBusinessId != null && resolvedBusinessId.isNotEmpty) {
      query['businessId'] = resolvedBusinessId;
    }

    final uri = resolveWithQuery('api/applications', query: query);
    final response = await get(
      uri,
      headers: headers(authToken: token, businessId: resolvedBusinessId),
    );

    final payload = decodeJson(response);

    List<dynamic> extractApplications(dynamic source) {
      if (source is List) return source;
      final map = _mapOrEmpty(source);
      if (map.isEmpty) return const [];

      const preferredKeys = [
        'data',
        'applications',
        'items',
        'results',
        'records',
      ];

      for (final key in preferredKeys) {
        final candidate = extractApplications(map[key]);
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      for (final value in map.values) {
        final candidate = extractApplications(value);
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      return const [];
    }

    final rawApplications = extractApplications(payload);
    final applications = <Application>[];

    for (final entry in rawApplications) {
      final map = _mapOrEmpty(entry);
      if (map.isEmpty) continue;
      try {
        applications.add(Application.fromJson(map));
      } catch (_) {
        continue;
      }
    }

    return applications;
  }

  @override
  Future<EmployerDashboardMetrics> fetchEmployerDashboardMetrics(
      String employerId,
      {String? businessId}) {
    // TODO: implement fetchEmployerDashboardMetrics according to backend API
    throw UnimplementedError();
  }

  @override
  Future<List<EmployerFeedback>> fetchEmployerFeedback(
      {int? page, int? limit}) {
    // TODO: implement fetchEmployerFeedback according to backend API
    throw UnimplementedError();
  }

  @override
  Future<List<JobPosting>> fetchEmployerJobs(String employerId,
      {String? businessId}) {
    // TODO: implement fetchEmployerJobs according to backend API
    throw UnimplementedError();
  }

  @override
  Future<EmployerProfile> fetchEmployerProfile(String employerId,
      {String? businessId}) {
    // TODO: implement fetchEmployerProfile according to backend API
    throw UnimplementedError();
  }

  @override
  Future<List<JobPaymentRecord>> fetchJobPaymentHistory(
      {int? page, int? limit}) {
    // TODO: implement fetchJobPaymentHistory according to backend API
    throw UnimplementedError();
  }

  @override
  Future<Application> hireApplicant(String applicationId,
      {DateTime? startDate, String? businessId}) {
    // TODO: implement hireApplicant according to backend API
    throw UnimplementedError();
  }

  @override
  Future<AttendanceRecord> markAttendanceComplete(String attendanceId) {
    // TODO: implement markAttendanceComplete according to backend API
    throw UnimplementedError();
  }

  @override
  Future<AttendanceRecord> scheduleAttendanceRecord(
      {required String workerId,
      required String jobId,
      required DateTime scheduledStart,
      required DateTime scheduledEnd,
      required double hourlyRate,
      String? notes}) {
    // TODO: implement scheduleAttendanceRecord according to backend API
    throw UnimplementedError();
  }

  @override
  Future<AttendanceRecord> updateAttendanceHours(
      {required String attendanceId,
      required double totalHours,
      double? hourlyRate}) {
    // TODO: implement updateAttendanceHours according to backend API
    throw UnimplementedError();
  }

  @override
  Future<Application> updateEmployerApplicationStatus(
      {required String applicationId,
      required ApplicationStatus status,
      String? message,
      String? businessId}) {
    // TODO: implement updateEmployerApplicationStatus according to backend API
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmployerProfile(String employerId,
      {String? companyName,
      String? description,
      String? phone,
      String? profilePicture,
      String? profilePictureSmall,
      String? profilePictureMedium,
      String? profilePictureLarge,
      String? companyLogo,
      String? companyLogoSmall,
      String? companyLogoMedium,
      String? companyLogoLarge}) {
    // TODO: implement updateEmployerProfile according to backend API
    throw UnimplementedError();
  }

  @override
  Future<EmploymentRecord> updateEmploymentWorkLocation({
    required String workerId,
    required String employmentId,
    Map<String, dynamic>? location,
    bool clear = false}) {
    // TODO: implement updateEmploymentWorkLocation according to backend API
    throw UnimplementedError();
  }

  // Rest of the class implementation...
}
