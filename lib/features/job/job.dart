// ignore_for_file: require_trailing_commas, avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/safe_num.dart';

enum JobStatus { active, filled, closed }

enum ApplicationStatus { pending, hired, rejected }

enum ShiftStatus { assigned, swapRequested, swapPending, swapped }

enum SwapRequestStatus { pending, approved, rejected }

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
    required this.overtimeRate,
    required this.urgency,
    required this.tags,
    required this.workDays,
    required this.isVerificationRequired,
    required this.status,
    required this.postedAt,
    this.distanceMiles,
    this.hasApplied = false,
    this.premiumRequired = false,
    this.locationSummary,
    this.applicantsCount = 0,
    this.businessName = '',
    this.businessLogoUrl,
    this.businessLogoOriginalUrl,
    this.businessLogoSquareUrl,
    this.employerEmail,
    this.employerName,
    this.createdById,
    this.createdByTag,
    this.createdByEmail,
    this.createdByName,
    this.isPublished = false,
    this.publishStatus = 'payment_required',
    this.publishActionRequired = false,
    this.publishedAt,
    this.publishedById,
    this.publishedByName,
    this.publishedByEmail,
    required this.businessAddress,
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
  final double overtimeRate;
  final String urgency;
  final List<String> tags;
  final List<String> workDays;
  final bool isVerificationRequired;
  final JobStatus status;
  final DateTime postedAt;
  final double? distanceMiles;
  final bool hasApplied;
  final bool premiumRequired;
  final String? locationSummary;

  final int applicantsCount;
  final String businessName;
  final String businessAddress;
  final String? businessLogoUrl;
  final String? businessLogoOriginalUrl;
  final String? businessLogoSquareUrl;
  final String? employerEmail;
  final String? employerName;
  final String? createdById;
  final String? createdByTag;
  final String? createdByEmail;
  final String? createdByName;
  final bool isPublished;
  final String publishStatus;
  final bool publishActionRequired;
  final DateTime? publishedAt;
  final String? publishedById;
  final String? publishedByName;
  final String? publishedByEmail;

  Duration get shiftDuration => scheduleEnd.difference(scheduleStart);

  /// ✅ Safe JSON parsing
  factory JobPosting.fromJson(Map<String, dynamic> json) {
    // Optimized parsing without verbose debug logging for better performance
    
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(
            value.map((key, val) => MapEntry(key.toString(), val)));
      }
      return null;
    }

    String? parseLocationAddress(Map<String, dynamic>? location) {
      if (location == null) return null;

      String? clean(dynamic value) {
        if (value == null) return null;
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
      }

      final formatted = clean(location['formattedAddress']);
      if (formatted != null) {
        return formatted;
      }

      final label = clean(location['label']) ?? clean(location['name']);
      if (label != null) {
        return label;
      }

      final addressObj = location['address'] is Map
          ? Map<String, dynamic>.from(location['address'] as Map)
          : null;

      final line1 = clean(location['line1']) ??
          clean(location['street']) ??
          clean(location['address']) ??
          clean(addressObj?['line1']) ??
          clean(addressObj?['street']) ??
          clean(addressObj?['address1']);
      final line2 = clean(location['line2']) ??
          clean(location['street2']) ??
          clean(addressObj?['line2']) ??
          clean(addressObj?['street2']) ??
          clean(addressObj?['address2']);

      final parts = <String>[];
      if (line1 != null) {
        parts.add(line1);
      }
      if (line2 != null) {
        parts.add(line2);
      }

      final city = clean(location['city']) ?? clean(addressObj?['city']);
      final state = clean(location['state']) ?? clean(addressObj?['state']);
      final postal = clean(location['postalCode']) ??
          clean(location['zip']) ??
          clean(addressObj?['postalCode']) ??
          clean(addressObj?['zip']);
      final cityStateParts = <String>[];
      if (city != null) {
        cityStateParts.add(city);
      }
      if (state != null) {
        cityStateParts.add(state);
      }
      if (cityStateParts.isNotEmpty) {
        final cityState = cityStateParts.join(', ');
        parts.add(postal != null ? '$cityState $postal' : cityState);
      } else if (postal != null) {
        parts.add(postal);
      }

      final joined = parts
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .join(', ');
      return joined.isNotEmpty ? joined : null;
    }

    String? combineName(Map<String, dynamic>? data) {
      if (data == null) return null;
      final first = data['firstName']?.toString().trim() ??
          data['givenName']?.toString().trim();
      final last = data['lastName']?.toString().trim() ??
          data['familyName']?.toString().trim();
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
      final fallback = data['name']?.toString().trim();
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
      return null;
    }

    final employerDetails =
        asMap(json['employerDetails']) ?? asMap(json['employer']);
    final businessDetails =
        asMap(json['businessDetails']) ?? asMap(json['business']);
    final createdByDetails = asMap(json['createdByDetails']) ??
        (json['createdBy'] is Map ? asMap(json['createdBy']) : null);
    final publishedByDetails =
        asMap(json['publishedByDetails']) ?? asMap(json['publishedBy']);
    String? resolvePublishedById() {
      if (publishedByDetails != null) {
        final details = publishedByDetails;
        final detailsId =
            details['_id']?.toString() ?? details['id']?.toString();
        if (detailsId != null && detailsId.isNotEmpty) {
          return detailsId;
        }
      }

      final rawPublishedBy = json['publishedBy'];
      if (rawPublishedBy is Map) {
        final rawId = rawPublishedBy['_id']?.toString() ??
            rawPublishedBy['id']?.toString();
        if (rawId != null && rawId.isNotEmpty) {
          return rawId;
        }
      } else if (rawPublishedBy != null) {
        final rawId = rawPublishedBy.toString();
        if (rawId.isNotEmpty) {
          return rawId;
        }
      }

      final explicitId = json['publishedById']?.toString();
      if (explicitId != null && explicitId.isNotEmpty) {
        return explicitId;
      }

      return null;
    }

    final employerId = (json['employerId']?.toString() ??
            employerDetails?['_id']?.toString() ??
            employerDetails?['id']?.toString()) ??
        '';
    final businessId = (json['businessId']?.toString() ??
            businessDetails?['_id']?.toString() ??
            businessDetails?['id']?.toString()) ??
        '';
    final businessName = json['businessName']?.toString() ??
        businessDetails?['businessName']?.toString() ??
        businessDetails?['name']?.toString() ??
        '';
    final businessAddress = json['businessAddress']?.toString() ??
        parseLocationAddress(asMap(json['location'])) ??
        parseLocationAddress(asMap(businessDetails?['location'])) ??
        businessDetails?['address']?.toString() ??
        '';
    String? businessLogoUrl = json['businessLogoUrl']?.toString();
    String? businessLogoOriginalUrl;
    String? businessLogoSquareUrl;
    final businessLogoDetails =
        asMap(json['businessLogo']) ?? asMap(businessDetails?['logo']);

    if (businessLogoDetails != null) {
      final square = businessLogoDetails['square'];
      final original = businessLogoDetails['original'];

      if (square is Map && square['url'] is String) {
        businessLogoSquareUrl = square['url'].toString().trim();
      }
      if (original is Map && original['url'] is String) {
        businessLogoOriginalUrl = original['url'].toString().trim();
      }
    }
    final directBusinessLogo = businessDetails?['logoUrl'];
    if ((businessLogoUrl == null || businessLogoUrl.isEmpty) &&
        directBusinessLogo is String &&
        directBusinessLogo.trim().isNotEmpty) {
      businessLogoUrl = directBusinessLogo.trim();
    }
    businessLogoUrl ??= businessLogoSquareUrl ?? businessLogoOriginalUrl;
    final employerEmail = employerDetails?['email']?.toString() ??
        json['employerEmail']?.toString();
    final employerName = combineName(employerDetails);
    final createdByEmail = createdByDetails?['email']?.toString() ??
        json['createdByEmail']?.toString();
    final createdByName = combineName(createdByDetails);
    final createdById = json['createdById']?.toString() ??
        createdByDetails?['_id']?.toString() ??
        createdByDetails?['id']?.toString();
    final createdByTag = json['createdByTag']?.toString();
    final publishedById = resolvePublishedById();
    final publishedByEmail = publishedByDetails?['email']?.toString() ??
        json['publishedByEmail']?.toString();
    final publishedByName = combineName(publishedByDetails);
    final publishStatus = json['publishStatus']?.toString() ??
        (json['isPublished'] == true ? 'published' : 'payment_required');

    final scheduleMap = asMap(json['schedule']);
    final scheduleStart = DateTime.tryParse(
          scheduleMap?['startDate']?.toString() ??
              json['scheduleStart']?.toString() ??
              json['startDate']?.toString() ??
              json['start']?.toString() ??
              '',
        ) ??
        DateTime.now();
    final scheduleEnd = DateTime.tryParse(
          scheduleMap?['endDate']?.toString() ??
              json['scheduleEnd']?.toString() ??
              json['endDate']?.toString() ??
              json['end']?.toString() ??
              '',
        ) ??
        scheduleStart;
    final recurrence = scheduleMap?['recurrence']?.toString() ??
        json['recurrence']?.toString() ??
        'one-time';

    return JobPosting(
      id: (json['_id']?.toString() ?? json['id']?.toString()) ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      employerId: employerId,
      businessId: businessId,
      hourlyRate: SafeNum.toSafeDouble(json['hourlyRate']),
      scheduleStart: scheduleStart,
      scheduleEnd: scheduleEnd,
      recurrence: recurrence,
      overtimeRate: SafeNum.toSafeDouble(
        json['overtimeRate'] ?? scheduleMap?['overtimeRate'],
      ),
      urgency: json['urgency']?.toString() ?? 'medium',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workDays:
          (json['workDays'] as List?)?.map((e) => e.toString()).toList() ??
              (scheduleMap?['workDays'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      isVerificationRequired:
          (json['isVerificationRequired'] ?? json['verificationRequired']) ==
              true,
      status: _parseStatus(json['status']),
      postedAt: DateTime.tryParse(json['postedAt']?.toString() ?? '') ??
          DateTime.now(),
      distanceMiles: SafeNum.toSafeDouble(json['distanceMiles']),
      hasApplied: json['hasApplied'] == true,
      premiumRequired: json['premiumRequired'] == true,
      locationSummary: json['locationSummary']?.toString(),
      applicantsCount: (() {
        try {
          return SafeNum.toSafeInt(json['applicantsCount']);
        } catch (e) {
          // Simplified error handling for better performance
          return 0;
        }
      })(),
      businessName: businessName,
      businessLogoUrl: (businessLogoUrl != null && businessLogoUrl.isNotEmpty)
          ? businessLogoUrl
          : null,
      businessLogoOriginalUrl: businessLogoOriginalUrl,
      businessLogoSquareUrl: businessLogoSquareUrl,
      employerEmail: employerEmail,
      employerName: employerName,
      createdById: createdById,
      createdByTag: createdByTag,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
      isPublished: json['isPublished'] == true,
      publishStatus: publishStatus,
      publishActionRequired: json['publishActionRequired'] == true,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      publishedById: publishedById,
      publishedByName: publishedByName,
      publishedByEmail: publishedByEmail,
      businessAddress: businessAddress,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'employerId': employerId,
      'businessId': businessId,
      'hourlyRate': hourlyRate,
      'scheduleStart': scheduleStart.toIso8601String(),
      'scheduleEnd': scheduleEnd.toIso8601String(),
      'recurrence': recurrence,
      'overtimeRate': overtimeRate,
      'urgency': urgency,
      'tags': tags,
      'workDays': workDays,
      'isVerificationRequired': isVerificationRequired,
      'status': status.name,
      'postedAt': postedAt.toIso8601String(),
      'distanceMiles': distanceMiles,
      'hasApplied': hasApplied,
      'premiumRequired': premiumRequired,
      'locationSummary': locationSummary,
      'applicantsCount': applicantsCount,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessLogoUrl': businessLogoUrl,
      if (businessLogoOriginalUrl != null)
        'businessLogoOriginalUrl': businessLogoOriginalUrl,
      if (businessLogoSquareUrl != null)
        'businessLogoSquareUrl': businessLogoSquareUrl,
    };
    if (employerEmail != null && employerEmail!.isNotEmpty) {
      map['employerEmail'] = employerEmail;
    }
    if (employerName != null && employerName!.isNotEmpty) {
      map['employerName'] = employerName;
    }
    if (createdById != null && createdById!.isNotEmpty) {
      map['createdById'] = createdById;
    }
    if (createdByTag != null && createdByTag!.isNotEmpty) {
      map['createdByTag'] = createdByTag;
    }
    if (createdByEmail != null && createdByEmail!.isNotEmpty) {
      map['createdByEmail'] = createdByEmail;
    }
    if (createdByName != null && createdByName!.isNotEmpty) {
      map['createdByName'] = createdByName;
    }
    map['isPublished'] = isPublished;
    map['publishStatus'] = publishStatus;
    map['publishActionRequired'] = publishActionRequired;
    if (publishedAt != null) {
      map['publishedAt'] = publishedAt!.toIso8601String();
    }
    if (publishedById != null && publishedById!.isNotEmpty) {
      map['publishedBy'] = publishedById;
      map['publishedById'] = publishedById;
    }
    if (publishedByName != null && publishedByName!.isNotEmpty) {
      map['publishedByName'] = publishedByName;
    }
    if (publishedByEmail != null && publishedByEmail!.isNotEmpty) {
      map['publishedByEmail'] = publishedByEmail;
    }
    return map;
  }

  static JobStatus _parseStatus(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'open':
          return JobStatus.active;
        case 'closed':
          return JobStatus.closed;
        case 'filled':
          return JobStatus.filled;
      }
    }
    return JobStatus.active; // fallback
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
