import '../../features/job/job.dart';
import 'user.dart';

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

Map<String, dynamic>? _mapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return null;
}

/// Represents a job application in the system
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

    final idValue = json['_id'] ?? json['id'];
    final workerIdValue = workerMap?['_id'] ??
        workerMap?['id'] ??
        workerMap?['user'] ??
        workerMap?['userId'] ??
        workerMap?['workerId'] ??
        json['workerId'] ??
        json['worker'];
    final jobIdValue = jobMap?['_id'] ??
        jobMap?['id'] ??
        jobMap?['jobId'] ??
        json['jobId'] ??
        json['job'];

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

    final messageValue = json['message']?.toString();
    final noteValue = (json['note'] ??
            json['hiringNotes'] ??
            json['employerNote'] ??
            json['workerNote'])
        ?.toString();

    return Application(
      id: idValue?.toString() ?? '',
      workerId: workerIdValue?.toString() ?? '',
      jobId: jobIdValue?.toString() ?? '',
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
      job: jobMap != null ? JobPosting.fromJson(jobMap) : null,
      worker: workerMap != null ? User.fromJson(workerMap) : null,
      workerName: workerName,
      workerExperience: workerExperienceValue?.toString(),
      workerSkills: _parseStringList(workerSkillsValue),
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
    );
  }

  bool get isPending => status == ApplicationStatus.pending;
  bool get isHired => status == ApplicationStatus.hired;
  bool get isRejected =>
      status == ApplicationStatus.rejected && rawStatus != 'withdrawn';
  bool get isWithdrawn => rawStatus == 'withdrawn';

  String get statusDisplay {
    if (isWithdrawn) return 'Withdrawn';
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  String get statusColor {
    if (isWithdrawn) return '#9E9E9E';
    switch (status) {
      case ApplicationStatus.pending:
        return '#FFA500';
      case ApplicationStatus.hired:
        return '#4CAF50';
      case ApplicationStatus.rejected:
        return '#F44336';
    }
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
