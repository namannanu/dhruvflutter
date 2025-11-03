import 'package:flutter/material.dart';

import '../utils/image_url_optimizer.dart';
import 'enums.dart' show JobStatus, ApplicationStatus;
import 'metrics.dart';

enum ShiftStatus { assigned, swapRequested, swapPending, swapped }

enum SwapRequestStatus { pending, approved, rejected }

@immutable
class JobOvertime {
  const JobOvertime({
    this.allowed = false,
    this.rateMultiplier = 1.5,
  });

  final bool allowed;
  final double rateMultiplier;

  factory JobOvertime.fromJson(Map<String, dynamic> json) {
    return JobOvertime(
      allowed: json['allowed'] == true,
      rateMultiplier: _toDouble(json['rateMultiplier']) ?? 1.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'rateMultiplier': rateMultiplier,
      };
}

@immutable
class JobLocation {
  const JobLocation({
    this.address,
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.label,
    this.locationName,
    this.allowedRadiusMeters,
    String? location,
  });

  final String? address;
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? label;
  final String? locationName;
  final double? allowedRadiusMeters;

  String? get fullAddress {
    final parts = <String>[
      if ((line1 ?? address)?.trim().isNotEmpty == true)
        (line1 ?? address)!.trim(),
      if (city?.trim().isNotEmpty == true) city!.trim(),
      if (state?.trim().isNotEmpty == true) state!.trim(),
      if (postalCode?.trim().isNotEmpty == true) postalCode!.trim(),
    ];
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  String? get shortAddress {
    final parts = <String>[
      if (city?.trim().isNotEmpty == true) city!.trim(),
      if (state?.trim().isNotEmpty == true) state!.trim(),
    ];
    return parts.isNotEmpty ? parts.join(', ') : line1 ?? address;
  }

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      address: _toString(json['address']) ??
          _toString(json['formattedAddress']) ??
          _toString(json['line1']),
      line1: _toString(json['line1']) ?? _toString(json['address']),
      line2: _toString(json['line2']) ?? _toString(json['suite']),
      city: _toString(json['city']) ?? _toString(json['locality']),
      state: _toString(json['state']) ??
          _toString(json['region']) ??
          _toString(json['stateCode']),
      postalCode: _toString(json['postalCode']) ?? _toString(json['zip']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      label: _toString(json['label']) ?? _toString(json['name']),
      locationName: _toString(json['locationName']) ?? _toString(json['name']),
      allowedRadiusMeters: _toDouble(json['allowedRadius']) ??
          _toDouble(json['allowedRadiusMeters']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (address != null) 'address': address,
        if (line1 != null) 'line1': line1,
        if (line2 != null) 'line2': line2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postalCode': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (label != null) 'label': label,
        if (locationName != null) 'locationName': locationName,
        if (allowedRadiusMeters != null) 'allowedRadius': allowedRadiusMeters,
      };

  static JobLocation? fromDynamic(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return JobLocation.fromJson(map);
  }
}

@immutable
class JobMetrics {
  const JobMetrics({
    Metrics? metrics,
  }) : metrics = metrics ?? const Metrics();

  final Metrics metrics;

  factory JobMetrics.fromJson(Map<String, dynamic> json) {
    return JobMetrics(
      metrics: Metrics.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => metrics.toJson();

  JobMetrics copyWith({Metrics? metrics}) {
    return JobMetrics(
      metrics: metrics ?? this.metrics,
    );
  }
}

@immutable
class JobPosting {
  const JobPosting({
    required this.id,
    required this.title,
    required this.description,
    required this.employerId,
    required this.businessId,
    required this.hourlyRate,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.recurrence,
    required this.overtime,
    required this.urgency,
    required this.tags,
    required this.workDays,
    required this.isVerificationRequired,
    required this.status,
    required this.postedAt,
    this.isPublished = false,
    this.publishStatus = 'ready_to_publish',
    this.publishActionRequired = false,
    this.metrics = const JobMetrics(),
    this.distanceMiles,
    this.hasApplied = false,
    this.premiumRequired = false,
    this.locationSummary,
    this.location,
    this.applicantsCount = 0,
    this.businessName = '',
    this.businessAddress = '',
    this.employerName,
    this.employerEmail,
    this.businessLogoSmall,
    this.businessLogoMedium,
    this.employerAvatarSmall,
    this.employerAvatarMedium,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
    this.createdByTag,
  });

  final String id;
  final String title;
  final String description;
  final String employerId;
  final String businessId;
  final double hourlyRate;
  final DateTime scheduleStart;
  final DateTime scheduleEnd;
  final String recurrence;
  final JobOvertime overtime;
  final String urgency;
  final List<String> tags;
  final List<String> workDays;
  final bool isVerificationRequired;
  final JobStatus status;
  final DateTime postedAt;
  final bool isPublished;
  final String publishStatus;
  final bool publishActionRequired;
  final JobMetrics metrics;
  final double? distanceMiles;
  final bool hasApplied;
  final bool premiumRequired;
  final String? locationSummary;
  final JobLocation? location;
  final int applicantsCount;
  final String businessName;
  final String businessAddress;
  final String? employerName;
  final String? employerEmail;
  final String? businessLogoSmall;
  final String? businessLogoMedium;
  final String? employerAvatarSmall;
  final String? employerAvatarMedium;
  final String? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByTag;

  Duration get shiftDuration => scheduleEnd.difference(scheduleStart);

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    final businessData = _asMap(json['business']) ??
        _asMap(json['businessDetails']) ??
        const <String, dynamic>{};
    final employerData = _asMap(json['employer']) ??
        _asMap(json['employerDetails']) ??
        const <String, dynamic>{};
    final createdByData = _asMap(json['createdBy']) ??
        _asMap(json['createdByDetails']) ??
        const <String, dynamic>{};

    final location = JobLocation.fromDynamic(json['location']) ??
        JobLocation.fromDynamic(businessData['location']);
    final locationSummary =
        _firstNonEmpty([json['locationSummary'], location?.fullAddress]);

    final businessAddress = _firstNonEmpty([
          json['businessAddress'],
          location?.fullAddress,
          businessData['address'],
        ]) ??
        '';

    final String? originalBusinessLogo = _toString(businessData['logo']);
    final String? originalEmployerAvatar =
        _toString(employerData['profilePicture']);

    final overtimeData = _asMap(json['overtime']);
    final schedule = _asMap(json['schedule']);

    final scheduleStart = _firstDate(
      [
        schedule?['startDate'],
        json['scheduleStart'],
        json['startDate'],
        json['start'],
      ],
      fallback: DateTime.now(),
    );
    final scheduleEnd = _firstDate(
      [
        schedule?['endDate'],
        json['scheduleEnd'],
        json['endDate'],
        json['end'],
      ],
      fallback: scheduleStart.add(const Duration(hours: 4)),
    );

    final resolvedId = _toString(json['_id']) ?? _toString(json['id']) ?? '';

    return JobPosting(
      id: resolvedId.isNotEmpty ? resolvedId : (_toString(json['title']) ?? ''),
      title: _toString(json['title']) ?? '',
      description: _toString(json['description']) ?? '',
      employerId: _firstNonEmpty([
            json['employerId'],
            employerData['_id'],
            employerData['id'],
            json['employer'],
          ]) ??
          '',
      businessId: _firstNonEmpty([
            json['businessId'],
            businessData['_id'],
            businessData['id'],
            json['business'],
          ]) ??
          '',
      hourlyRate: _toDouble(json['hourlyRate']) ?? 0,
      scheduleStart: scheduleStart,
      scheduleEnd: scheduleEnd,
      recurrence: _firstNonEmpty([
            schedule?['recurrence'],
            json['recurrence'],
          ]) ??
          'one-time',
      overtime: overtimeData != null
          ? JobOvertime.fromJson(overtimeData)
          : const JobOvertime(),
      urgency: _toString(json['urgency']) ?? 'medium',
      tags: _stringList(json['tags']),
      workDays: _mergeStringLists(
        schedule?['workDays'],
        json['workDays'],
      ),
      isVerificationRequired: json['verificationRequired'] == true ||
          json['isVerificationRequired'] == true,
      status: JobStatus.fromString(_toString(json['status']) ?? 'active'),
      postedAt: _firstDate(
        [json['createdAt'], json['postedAt']],
        fallback: DateTime.now(),
      ),
      isPublished: json['isPublished'] == true,
      publishStatus: _toString(json['publishStatus']) ?? 'ready_to_publish',
      publishActionRequired: json['publishActionRequired'] == true,
      metrics: json['metrics'] is Map<String, dynamic>
          ? JobMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : const JobMetrics(),
      distanceMiles: _toDouble(json['distanceMiles']),
      hasApplied: json['hasApplied'] == true,
      premiumRequired: json['premiumRequired'] == true,
      locationSummary: locationSummary,
      location: location,
      applicantsCount: _toInt(json['applicantsCount']) ?? 0,
      businessName: _firstNonEmpty([
            json['businessName'],
            businessData['businessName'],
            businessData['name'],
          ]) ??
          '',
      businessAddress: businessAddress,
      employerName: _firstNonEmpty([
        _composeName(employerData),
        json['employerName'],
        employerData['name'],
      ]),
      employerEmail: _firstNonEmpty([
        json['employerEmail'],
        employerData['email'],
      ]),
      businessLogoSmall: _toString(businessData['logoSmall']) ??
          (originalBusinessLogo != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalBusinessLogo, ImageContext.companyLogoSmall)
              : null),
      businessLogoMedium: _toString(businessData['logoMedium']) ??
          (originalBusinessLogo != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalBusinessLogo, ImageContext.companyLogoLarge)
              : null),
      employerAvatarSmall: _toString(employerData['avatarSmall']) ??
          (originalEmployerAvatar != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalEmployerAvatar, ImageContext.employerAvatar)
              : null),
      employerAvatarMedium: _toString(employerData['avatarMedium']) ??
          (originalEmployerAvatar != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalEmployerAvatar, ImageContext.employerProfile)
              : null),
      createdById: _firstNonEmpty([
        json['createdById'],
        createdByData['_id'],
        createdByData['id'],
      ]),
      createdByName: _firstNonEmpty([
        json['createdByName'],
        _composeName(createdByData),
      ]),
      createdByEmail: _firstNonEmpty([
        json['createdByEmail'],
        createdByData['email'],
      ]),
      createdByTag: _toString(json['createdByTag']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'employerId': employerId,
      'businessId': businessId,
      'hourlyRate': hourlyRate,
      'scheduleStart': scheduleStart.toIso8601String(),
      'scheduleEnd': scheduleEnd.toIso8601String(),
      'recurrence': recurrence,
      'overtime': overtime.toJson(),
      'urgency': urgency,
      'tags': tags,
      'workDays': workDays,
      'isVerificationRequired': isVerificationRequired,
      'status': status.name,
      'postedAt': postedAt.toIso8601String(),
      'isPublished': isPublished,
      'publishStatus': publishStatus,
      'publishActionRequired': publishActionRequired,
      'metrics': metrics.toJson(),
      'distanceMiles': distanceMiles,
      'hasApplied': hasApplied,
      'premiumRequired': premiumRequired,
      'locationSummary': locationSummary,
      if (location != null) 'location': location!.toJson(),
      'applicantsCount': applicantsCount,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'employerName': employerName,
      'employerEmail': employerEmail,
      'businessLogoSmall': businessLogoSmall,
      'businessLogoMedium': businessLogoMedium,
      'employerAvatarSmall': employerAvatarSmall,
      'employerAvatarMedium': employerAvatarMedium,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'createdByTag': createdByTag,
    };
  }
}

@immutable
class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.workerName,
    required this.workerExperience,
    required this.workerSkills,
    required this.status,
    required this.submittedAt,
    this.note,
    this.employerName,
    this.employerEmail,
    this.businessId,
    this.businessName,
  });

  final String id;
  final String jobId;
  final String workerId;
  final String workerName;
  final String workerExperience;
  final List<String> workerSkills;
  final ApplicationStatus status;
  final DateTime submittedAt;
  final String? note;
  final String? employerName;
  final String? employerEmail;
  final String? businessId;
  final String? businessName;
}

@immutable
class Shift {
  const Shift({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.start,
    required this.end,
    required this.status,
    required this.canSwap,
    required this.isEligibleForSwap,
    this.locationSummary,
  });

  final String id;
  final String jobId;
  final String workerId;
  final DateTime start;
  final DateTime end;
  final ShiftStatus status;
  final bool canSwap;
  final bool isEligibleForSwap;
  final String? locationSummary;
}

@immutable
class SwapRequestMessage {
  const SwapRequestMessage({
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  final String senderId;
  final String body;
  final DateTime sentAt;
}

@immutable
class SwapRequest {
  const SwapRequest({
    required this.id,
    required this.shiftId,
    required this.requestorId,
    required this.targetWorkerId,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  final String id;
  final String shiftId;
  final String requestorId;
  final String targetWorkerId;
  final SwapRequestStatus status;
  final DateTime createdAt;
  final List<SwapRequestMessage> messages;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _toString(dynamic value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => _toString(item)).whereType<String>().toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

List<String> _mergeStringLists(dynamic first, dynamic second) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in [
    ..._stringList(first),
    ..._stringList(second),
  ]) {
    if (seen.add(value)) {
      result.add(value);
    }
  }
  return result;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, dynamic v) => MapEntry(key.toString(), v),
    );
  }
  return null;
}

String? _composeName(Map<String, dynamic>? data) {
  if (data == null) return null;
  final parts = <String>[
    if (_toString(data['firstName']) != null) _toString(data['firstName'])!,
    if (_toString(data['lastName']) != null) _toString(data['lastName'])!,
  ];
  if (parts.isEmpty) {
    return _toString(data['name']);
  }
  return parts.join(' ').trim();
}

String? _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final stringValue = _toString(value);
    if (stringValue != null && stringValue.isNotEmpty) {
      return stringValue;
    }
  }
  return null;
}

DateTime _firstDate(Iterable<dynamic> values, {required DateTime fallback}) {
  for (final value in values) {
    final stringValue = _toString(value);
    if (stringValue != null) {
      final parsed = DateTime.tryParse(stringValue);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}
