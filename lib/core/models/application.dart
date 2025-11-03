import 'package:flutter/foundation.dart';
import 'package:talent/core/models/enums.dart';
import 'package:talent/core/models/job.dart';
import 'package:talent/core/models/user.dart';

/// Helper to convert dynamic value to trimmed non-empty string or null
String? _stringValue(dynamic value) {
  if (value == null) return null;
  final string = value.toString().trim();
  return string.isEmpty ? null : string;
}

/// Represents a job application in the system
Map<String, dynamic>? _mapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return null;
}

/// Parse a string value into an ApplicationStatus enum
/// Handles various status strings from backend and normalizes them
ApplicationStatus _parseApplicationStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'hired':
    case 'offer_accepted':
      return ApplicationStatus.hired;
    case 'accepted':
      return ApplicationStatus.accepted;
    case 'rejected':
    case 'declined':
      return ApplicationStatus.rejected;
    case 'withdrawn':
      return ApplicationStatus.cancelled;
    case 'completed':
      return ApplicationStatus.completed;
    case 'pending':
    case 'in_review':
    case 'in-review':
    case 'review':
    case 'new':
    default:
      return ApplicationStatus.pending;
  }
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

@immutable
class Application {
  final String id;
  final String workerId;
  final String jobId;
  final ApplicationStatus status;
  final String rawStatus;
  final String? message;
  final String? note;
  final DateTime createdAt;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final DateTime? hiredAt;
  final DateTime? rejectedAt;
  final DateTime? withdrawnAt;
  final JobPosting? job;
  final User? worker;
  final String workerName;
  final String workerExperience;
  final List<String> workerSkills;
  final String? employerId;
  final String? employerName;
  final String? employerEmail;
  final String? businessId;
  final String? businessName;
  final String? createdByTag;

  Application({
    required this.id,
    required this.workerId,
    required this.jobId,
    required this.status,
    String? rawStatus,
    this.message,
    this.note,
    DateTime? createdAt,
    DateTime? submittedAt,
    this.updatedAt,
    this.hiredAt,
    this.rejectedAt,
    this.withdrawnAt,
    this.job,
    this.worker,
    String? workerName,
    String? workerExperience,
    List<String>? workerSkills,
    this.employerId,
    this.employerName,
    this.employerEmail,
    this.businessId,
    this.businessName,
    this.createdByTag,
  })  : rawStatus = (rawStatus ?? status.name).toLowerCase(),
        createdAt = createdAt ??
            submittedAt ??
            DateTime.now(), // Fallback ensures a timestamp in edge cases
        submittedAt = submittedAt ?? createdAt ?? DateTime.now(),
        workerName =
            (workerName ?? '').trim().isEmpty ? 'Worker' : workerName!.trim(),
        workerExperience = workerExperience ?? '',
        workerSkills = List.unmodifiable(workerSkills ?? const []);

  factory Application.fromJson(Map<String, dynamic> json) {
    final workerMap = _mapOrNull(json['worker']);
    final jobMap = _mapOrNull(json['job']);
    final snapshotMap =
        _mapOrNull(json['snapshot']) ?? const <String, dynamic>{};
    final employerMap = _mapOrNull(json['employer']) ??
        _mapOrNull(jobMap?['employer']) ??
        _mapOrNull(snapshotMap['employer']);
    final businessMap = _mapOrNull(json['business']) ??
        _mapOrNull(jobMap?['business']) ??
        _mapOrNull(snapshotMap['business']);

    final idValue = json['_id'] ?? json['id'];
    final workerIdValue = workerMap?['_id'] ??
        workerMap?['id'] ??
        workerMap?['user'] ??
        workerMap?['userId'] ??
        workerMap?['workerId'] ??
        json['workerId'] ??
        json['worker'];
    final jobIdValue = jobMap?['\$oid'] ??
        jobMap?['_id'] ??
        jobMap?['id'] ??
        jobMap?['jobId'] ??
        json['jobId'] ??
        json['job'];

    // Handle MongoDB ObjectId format for direct job field
    dynamic finalJobIdValue = jobIdValue;
    if (json['job'] is Map<String, dynamic>) {
      final jobObjMap = json['job'] as Map<String, dynamic>;
      finalJobIdValue ??=
          jobObjMap['\$oid'] ?? jobObjMap['_id'] ?? jobObjMap['id'];
    }

    final createdAtRaw = json['createdAt'] ?? json['appliedAt'];
    final submittedAtRaw = json['submittedAt'] ?? json['appliedAt'];
    final updatedAtRaw = json['updatedAt'];
    final hiredAtRaw = json['hiredAt'];
    final rejectedAtRaw = json['rejectedAt'];
    final withdrawnAtRaw = json['withdrawnAt'];
    final statusRaw = (json['status'] ?? json['applicationStatus'])?.toString();

    final workerNameCandidates = <String?>[
      json['workerName']?.toString(),
      json['workerNameSnapshot']?.toString(),
      snapshotMap['name']?.toString(),
    ];

    if (workerMap != null) {
      final combinedName = [
        workerMap['firstName']?.toString() ?? '',
        workerMap['lastName']?.toString() ?? '',
      ].where((part) => part.trim().isNotEmpty).join(' ');
      if (combinedName.isNotEmpty) {
        workerNameCandidates.add(combinedName);
      }

      final legacyCombinedName = [
        workerMap['firstname']?.toString() ?? '',
        workerMap['lastname']?.toString() ?? '',
      ].where((part) => part.trim().isNotEmpty).join(' ');
      if (legacyCombinedName.isNotEmpty) {
        workerNameCandidates.add(legacyCombinedName);
      }

      workerNameCandidates.add(workerMap['email']?.toString());
    }

    final normalizedWorkerNames = workerNameCandidates
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();

    String workerName =
        normalizedWorkerNames.isNotEmpty ? normalizedWorkerNames.first : '';

    if (workerName.isEmpty) {
      workerName = snapshotMap['email']?.toString() ??
          workerMap?['email']?.toString() ??
          json['workerEmail']?.toString() ??
          'Worker';
    }

    final workerExperienceValue = json['workerExperience'] ??
        snapshotMap['experience'] ??
        workerMap?['experience'];

    final workerSkillsValue =
        json['workerSkills'] ?? snapshotMap['skills'] ?? workerMap?['skills'];

    final employerIdValue = _stringValue(json['employerId']) ??
        _stringValue(employerMap?['_id']) ??
        _stringValue(employerMap?['id']) ??
        _stringValue(jobMap?['employerId']) ??
        _stringValue(snapshotMap['employerId']);

    final employerEmailValue = _stringValue(json['employerEmail']) ??
        _stringValue(employerMap?['email']) ??
        _stringValue(jobMap?['employerEmail']) ??
        _stringValue(snapshotMap['employerEmail']);

    final employerNameCandidates = <String?>[
      _stringValue(json['employerName']),
      _stringValue(snapshotMap['employerName']),
      _stringValue(jobMap?['employerName']),
      _stringValue(employerMap?['name']),
    ];

    if (employerMap != null) {
      final firstName = _stringValue(employerMap['firstName']) ??
          _stringValue(employerMap['firstname']);
      final lastName = _stringValue(employerMap['lastName']) ??
          _stringValue(employerMap['lastname']);

      final combined = [
        if (firstName != null && firstName.isNotEmpty) firstName,
        if (lastName != null && lastName.isNotEmpty) lastName,
      ].join(' ');
      if (combined.isNotEmpty) {
        employerNameCandidates.add(combined);
      }

      final displayName = _stringValue(employerMap['displayName']);
      if (displayName != null && displayName.isNotEmpty) {
        employerNameCandidates.add(displayName);
      }
    }

    if (employerEmailValue != null && employerEmailValue.isNotEmpty) {
      employerNameCandidates.add(employerEmailValue);
    }

    String? employerNameValue;
    for (final candidate in employerNameCandidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        employerNameValue = trimmed;
        break;
      }
    }

    final businessIdValue = _stringValue(json['businessId']) ??
        _stringValue(businessMap?['_id']) ??
        _stringValue(businessMap?['id']) ??
        _stringValue(jobMap?['businessId']) ??
        _stringValue(snapshotMap['businessId']);

    final businessNameCandidates = <String?>[
      _stringValue(json['businessName']),
      _stringValue(snapshotMap['businessName']),
      _stringValue(businessMap?['businessName']),
      _stringValue(businessMap?['name']),
      _stringValue(jobMap?['businessName']),
    ];

    String? businessNameValue;
    for (final candidate in businessNameCandidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        businessNameValue = trimmed;
        break;
      }
    }

    final messageValue = json['message']?.toString();
    final noteValue = (json['note'] ??
            json['hiringNotes'] ??
            json['employerNote'] ??
            json['workerNote'])
        ?.toString();

    final jobPosting = jobMap != null ? JobPosting.fromJson(jobMap) : null;

    final resolvedEmployerId = employerIdValue ??
        (jobPosting != null && jobPosting.employerId.isNotEmpty
            ? jobPosting.employerId
            : null);
    final resolvedEmployerEmail =
        employerEmailValue ?? jobPosting?.employerEmail;
    final resolvedEmployerName = employerNameValue ?? jobPosting?.employerName;
    final jobBusinessId = jobPosting != null && jobPosting.businessId.isNotEmpty
        ? jobPosting.businessId
        : null;
    final resolvedBusinessId = businessIdValue ?? jobBusinessId;
    final jobBusinessName = jobPosting?.businessName;
    final resolvedBusinessName = businessNameValue ??
        (jobBusinessName != null && jobBusinessName.isNotEmpty
            ? jobBusinessName
            : null);

    return Application(
      id: idValue?.toString() ?? '',
      workerId: workerIdValue?.toString() ?? '',
      jobId: finalJobIdValue?.toString() ?? '',
      status: _parseApplicationStatus(statusRaw),
      rawStatus: statusRaw,
      message: messageValue,
      note: noteValue ?? messageValue,
      createdAt:
          DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now(),
      submittedAt: DateTime.tryParse(submittedAtRaw?.toString() ?? '') ??
          DateTime.tryParse(createdAtRaw?.toString() ?? ''),
      updatedAt: DateTime.tryParse(updatedAtRaw?.toString() ?? ''),
      hiredAt: DateTime.tryParse(hiredAtRaw?.toString() ?? ''),
      rejectedAt: DateTime.tryParse(rejectedAtRaw?.toString() ?? ''),
      withdrawnAt: DateTime.tryParse(withdrawnAtRaw?.toString() ?? ''),
      job: jobPosting,
      worker: workerMap != null ? User.fromJson(workerMap) : null,
      workerName: workerName,
      workerExperience: workerExperienceValue?.toString(),
      workerSkills: _parseStringList(workerSkillsValue),
      employerId: resolvedEmployerId,
      employerEmail: resolvedEmployerEmail,
      employerName: resolvedEmployerName,
      businessId: resolvedBusinessId,
      businessName: resolvedBusinessName,
      createdByTag: json['createdByTag']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker': workerId,
      'job': jobId,
      'status': rawStatus,
      'message': message,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'hiredAt': hiredAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'withdrawnAt': withdrawnAt?.toIso8601String(),
      'workerName': workerName,
      'workerExperience': workerExperience,
      'workerSkills': workerSkills,
      'createdByTag': createdByTag,
      'employerId': employerId,
      'employerName': employerName,
      'employerEmail': employerEmail,
      'businessId': businessId,
      'businessName': businessName,
      if (job != null) 'job': job!.toJson(),
      if (worker != null) 'worker': worker!.toJson(),
    };
  }

  Application copyWith({
    String? id,
    String? workerId,
    String? jobId,
    ApplicationStatus? status,
    String? rawStatus,
    String? message,
    String? note,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? hiredAt,
    DateTime? rejectedAt,
    DateTime? withdrawnAt,
    JobPosting? job,
    User? worker,
    String? workerName,
    String? workerExperience,
    List<String>? workerSkills,
    String? createdByTag,
    String? employerId,
    String? employerName,
    String? employerEmail,
    String? businessId,
    String? businessName,
  }) {
    return Application(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      message: message ?? this.message,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hiredAt: hiredAt ?? this.hiredAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      job: job ?? this.job,
      worker: worker ?? this.worker,
      workerName: workerName ?? this.workerName,
      workerExperience: workerExperience ?? this.workerExperience,
      workerSkills: workerSkills ?? this.workerSkills,
      createdByTag: createdByTag ?? this.createdByTag,
      employerId: employerId ?? this.employerId,
      employerName: employerName ?? this.employerName,
      employerEmail: employerEmail ?? this.employerEmail,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
    );
  }

  // Status check getters
  bool get isPending => status == ApplicationStatus.pending;
  bool get isHired => status == ApplicationStatus.hired;
  bool get isAccepted => status == ApplicationStatus.accepted;
  bool get isRejected => status == ApplicationStatus.rejected;
  bool get isCancelled => status == ApplicationStatus.cancelled;
  bool get isCompleted => status == ApplicationStatus.completed;
  bool get isWithdrawn => isCancelled && rawStatus.toLowerCase() == 'withdrawn';
  bool get isActive => isPending || isAccepted;

  String get statusDisplay {
    if (isWithdrawn) return 'Withdrawn';
    var label = 'Pending Review';
    switch (status) {
      case ApplicationStatus.pending:
        label = 'Pending Review';
        break;
      case ApplicationStatus.hired:
        label = 'Hired';
        break;
      case ApplicationStatus.rejected:
        label = 'Not Selected';
        break;
      case ApplicationStatus.accepted:
        label = 'Under Consideration';
        break;
      case ApplicationStatus.cancelled:
        label =
            rawStatus.toLowerCase() == 'withdrawn' ? 'Withdrawn' : 'Cancelled';
        break;
      case ApplicationStatus.completed:
        label = 'Completed';
        break;
    }
    return label;
  }

  String get statusColor {
    if (isWithdrawn) return '#9E9E9E'; // Grey
    var color = '#FFA500'; // Default orange for pending
    switch (status) {
      case ApplicationStatus.pending:
        color = '#FFA500'; // Orange
        break;
      case ApplicationStatus.hired:
        color = '#4CAF50'; // Green
        break;
      case ApplicationStatus.rejected:
        color = '#F44336'; // Red
        break;
      case ApplicationStatus.accepted:
        color = '#2196F3'; // Blue
        break;
      case ApplicationStatus.cancelled:
        color = '#9E9E9E'; // Grey
        break;
      case ApplicationStatus.completed:
        color = '#4CAF50'; // Green
        break;
    }
    return color;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Application && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Application(id: $id, workerId: $workerId, jobId: $jobId, status: $rawStatus)';
  }
}
