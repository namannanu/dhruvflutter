// ignore_for_file: require_trailing_commas, avoid_print

import 'package:flutter/foundation.dart';

import '../../core/models/enums.dart' show ApplicationStatus;
import '../../core/models/job.dart';

// Export enums from core models for compatibility
export '../../core/models/enums.dart' show JobStatus, ApplicationStatus;
export '../../core/models/job.dart' show ShiftStatus, SwapRequestStatus;

@immutable
class JobHistory {
  const JobHistory({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.businessId,
    required this.type,
    required this.timestamp,
    required this.changes,
  });

  final String id;
  final String jobId;
  final String employerId;
  final String businessId;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> changes;

  factory JobHistory.fromJson(Map<String, dynamic> json) {
    return JobHistory(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      changes:
          (json['changes'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'employerId': employerId,
      'businessId': businessId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'changes': changes,
    };
  }

  @override
  String toString() {
    return '$type on ${timestamp.toLocal()} - $changes';
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
