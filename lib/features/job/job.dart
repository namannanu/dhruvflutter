// ignore_for_file: require_trailing_commas

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

  Duration get shiftDuration => scheduleEnd.difference(scheduleStart);

  /// ✅ Safe JSON parsing
  factory JobPosting.fromJson(Map<String, dynamic> json) {
    return JobPosting(
      id: (json['_id']?.toString() ?? json['id']?.toString()) ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      hourlyRate: SafeNum.toSafeDouble(json['hourlyRate']),
      scheduleStart: DateTime.tryParse(json['scheduleStart']?.toString() ??
              json['start']?.toString() ??
              '') ??
          DateTime.now(),
      scheduleEnd: DateTime.tryParse(json['scheduleEnd']?.toString() ??
              json['end']?.toString() ??
              '') ??
          DateTime.now(),
      recurrence: json['recurrence']?.toString() ?? 'one-time',
      overtimeRate: SafeNum.toSafeDouble(json['overtimeRate']),
      urgency: json['urgency']?.toString() ?? 'medium',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workDays:
          (json['workDays'] as List?)?.map((e) => e.toString()).toList() ?? [],
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
      applicantsCount: SafeNum.toSafeInt(json['applicantsCount']),
      businessName: json['businessName']?.toString() ?? '',
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
    };
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
