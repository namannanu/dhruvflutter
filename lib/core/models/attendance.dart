import 'package:flutter/material.dart';
import 'package:talent/core/models/location.dart';

enum AttendanceStatus { scheduled, clockedIn, completed, missed }

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.workerId,
    required this.jobId,
    required this.businessId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.totalHours,
    required this.earnings,
    required this.isLate,
    this.clockIn,
    this.clockOut,
    this.locationSummary,
    this.jobTitle,
    this.hourlyRate,
    this.companyName,
    this.location,
    this.workerName,
    this.workerAvatarUrl,
    // Location tracking fields
    this.jobLocation,
    this.clockInLocation,
    this.clockOutLocation,
    this.locationValidated,
    this.locationValidationMessage,
  });

  final String id;
  final String workerId;
  final String jobId;
  final String businessId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final AttendanceStatus status;
  final double totalHours;
  final double earnings;
  final bool isLate;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String? locationSummary;
  final String? jobTitle;
  final double? hourlyRate;
  final String? companyName;
  final String? location;
  final String? workerName;
  final String? workerAvatarUrl;

  // Location tracking fields
  final JobLocation? jobLocation; // The designated job location
  final Location? clockInLocation; // Where the worker clocked in
  final Location? clockOutLocation; // Where the worker clocked out
  final bool? locationValidated; // Whether location validation passed
  final String? locationValidationMessage; // Validation result message

  Duration get scheduledDuration => scheduledEnd.difference(scheduledStart);

  /// Check if worker clocked in at valid location
  bool get isClockInLocationValid {
    if (jobLocation == null || clockInLocation == null) {
      return true; // No validation if no data
    }
    return jobLocation!.isValidAttendanceLocation(clockInLocation!);
  }

  /// Check if worker clocked out at valid location
  bool get isClockOutLocationValid {
    if (jobLocation == null || clockOutLocation == null) {
      return true; // No validation if no data
    }
    return jobLocation!.isValidAttendanceLocation(clockOutLocation!);
  }

  /// Get distance from job location for clock-in
  double? get clockInDistance {
    if (jobLocation == null || clockInLocation == null) return null;
    return jobLocation!.distanceTo(clockInLocation!);
  }

  /// Get distance from job location for clock-out
  double? get clockOutDistance {
    if (jobLocation == null || clockOutLocation == null) return null;
    return jobLocation!.distanceTo(clockOutLocation!);
  }

  /// Create AttendanceRecord from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      scheduledStart:
          DateTime.tryParse(json['scheduledStart'] as String? ?? '') ??
              DateTime.now(),
      scheduledEnd: DateTime.tryParse(json['scheduledEnd'] as String? ?? '') ??
          DateTime.now(),
      status: _parseStatus(json['status']),
      totalHours: _parseDouble(json['totalHours']) ?? 0.0,
      earnings: _parseDouble(json['earnings']) ?? 0.0,
      isLate: json['isLate'] as bool? ?? false,
      clockIn: json['clockIn'] != null
          ? DateTime.tryParse(json['clockIn'] as String)
          : null,
      clockOut: json['clockOut'] != null
          ? DateTime.tryParse(json['clockOut'] as String)
          : null,
      locationSummary: json['locationSummary'] as String?,
      jobTitle: json['jobTitle'] as String?,
      hourlyRate: _parseDouble(json['hourlyRate']),
      companyName: json['companyName'] as String?,
      location: json['location'] as String?,
      workerName: json['workerName'] as String?,
      workerAvatarUrl: json['workerAvatarUrl'] as String?,
      // Location tracking fields
      jobLocation: json['jobLocation'] != null
          ? JobLocation.fromJson(json['jobLocation'] as Map<String, dynamic>)
          : null,
      clockInLocation: json['clockInLocation'] != null
          ? Location.fromJson(json['clockInLocation'] as Map<String, dynamic>)
          : null,
      clockOutLocation: json['clockOutLocation'] != null
          ? Location.fromJson(json['clockOutLocation'] as Map<String, dynamic>)
          : null,
      locationValidated: json['locationValidated'] as bool?,
      locationValidationMessage: json['locationValidationMessage'] as String?,
    );
  }

  /// Convert AttendanceRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'jobId': jobId,
      'businessId': businessId,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      'status': status.name,
      'totalHours': totalHours,
      'earnings': earnings,
      'isLate': isLate,
      if (clockIn != null) 'clockIn': clockIn!.toIso8601String(),
      if (clockOut != null) 'clockOut': clockOut!.toIso8601String(),
      if (locationSummary != null) 'locationSummary': locationSummary,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (companyName != null) 'companyName': companyName,
      if (location != null) 'location': location,
      if (workerName != null) 'workerName': workerName,
      if (workerAvatarUrl != null) 'workerAvatarUrl': workerAvatarUrl,
      // Location tracking fields
      if (jobLocation != null) 'jobLocation': jobLocation!.toJson(),
      if (clockInLocation != null) 'clockInLocation': clockInLocation!.toJson(),
      if (clockOutLocation != null)
        'clockOutLocation': clockOutLocation!.toJson(),
      if (locationValidated != null) 'locationValidated': locationValidated,
      if (locationValidationMessage != null)
        'locationValidationMessage': locationValidationMessage,
    };
  }

  /// Create a copy with updated values
  AttendanceRecord copyWith({
    String? id,
    String? workerId,
    String? jobId,
    String? businessId,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    AttendanceStatus? status,
    double? totalHours,
    double? earnings,
    bool? isLate,
    DateTime? clockIn,
    DateTime? clockOut,
    String? locationSummary,
    String? jobTitle,
    double? hourlyRate,
    String? companyName,
    String? location,
    String? workerName,
    String? workerAvatarUrl,
    JobLocation? jobLocation,
    Location? clockInLocation,
    Location? clockOutLocation,
    bool? locationValidated,
    String? locationValidationMessage,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      jobId: jobId ?? this.jobId,
      businessId: businessId ?? this.businessId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      status: status ?? this.status,
      totalHours: totalHours ?? this.totalHours,
      earnings: earnings ?? this.earnings,
      isLate: isLate ?? this.isLate,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      locationSummary: locationSummary ?? this.locationSummary,
      jobTitle: jobTitle ?? this.jobTitle,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      workerName: workerName ?? this.workerName,
      workerAvatarUrl: workerAvatarUrl ?? this.workerAvatarUrl,
      jobLocation: jobLocation ?? this.jobLocation,
      clockInLocation: clockInLocation ?? this.clockInLocation,
      clockOutLocation: clockOutLocation ?? this.clockOutLocation,
      locationValidated: locationValidated ?? this.locationValidated,
      locationValidationMessage:
          locationValidationMessage ?? this.locationValidationMessage,
    );
  }

  /// Helper method to parse AttendanceStatus from string
  static AttendanceStatus _parseStatus(dynamic value) {
    if (value == null) return AttendanceStatus.scheduled;
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'scheduled':
        return AttendanceStatus.scheduled;
      case 'clocked-in':
      case 'clockedin':
      case 'clocked_in':
        return AttendanceStatus.clockedIn;
      case 'completed':
        return AttendanceStatus.completed;
      case 'missed':
        return AttendanceStatus.missed;
      default:
        return AttendanceStatus.scheduled;
    }
  }

  /// Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

@immutable
class AttendanceDashboardSummary {
  const AttendanceDashboardSummary({
    required this.totalWorkers,
    required this.completedShifts,
    required this.totalHours,
    required this.totalPayroll,
    required this.lateArrivals,
  });

  final int totalWorkers;
  final int completedShifts;
  final double totalHours;
  final double totalPayroll;
  final int lateArrivals;
}

@immutable
class AttendanceDashboard {
  const AttendanceDashboard({
    required this.date,
    required this.statusFilter,
    required this.records,
    required this.summary,
  });

  final DateTime date;
  final String statusFilter;
  final List<AttendanceRecord> records;
  final AttendanceDashboardSummary summary;

  AttendanceDashboard copyWith({
    DateTime? date,
    String? statusFilter,
    List<AttendanceRecord>? records,
    AttendanceDashboardSummary? summary,
  }) {
    return AttendanceDashboard(
      date: date ?? this.date,
      statusFilter: statusFilter ?? this.statusFilter,
      records: records ?? this.records,
      summary: summary ?? this.summary,
    );
  }
}

@immutable
class AttendanceScheduleDay {
  const AttendanceScheduleDay({
    required this.date,
    required this.records,
    this.totalHours = 0,
    this.totalEarnings = 0,
    this.scheduledCount = 0,
    this.completedCount = 0,
  });

  final DateTime date;
  final List<AttendanceRecord> records;
  final double totalHours;
  final double totalEarnings;
  final int scheduledCount;
  final int completedCount;
}

@immutable
class AttendanceSchedule {
  const AttendanceSchedule({
    required this.workerId,
    required this.statusFilter,
    required this.days,
    this.workerName,
    this.from,
    this.to,
    this.totalHours = 0,
    this.totalEarnings = 0,
    this.totalRecords = 0,
  });

  final String workerId;
  final String statusFilter;
  final List<AttendanceScheduleDay> days;
  final String? workerName;
  final DateTime? from;
  final DateTime? to;
  final double totalHours;
  final double totalEarnings;
  final int totalRecords;
}

@immutable
class WorkerWithSchedule {
  const WorkerWithSchedule({
    required this.workerId,
    required this.workerName,
    required this.jobId,
    required this.jobTitle,
    required this.hourlyRate,
    required this.schedules,
    this.workerEmail,
    this.workerPhone,
    this.businessName,
    this.hireDate,
    this.employmentStatus,
  });

  final String workerId;
  final String workerName;
  final String jobId;
  final String jobTitle;
  final double hourlyRate;
  final List<AttendanceRecord> schedules;
  final String? workerEmail;
  final String? workerPhone;
  final String? businessName;
  final DateTime? hireDate;
  final String? employmentStatus;

  // Helper methods
  List<AttendanceRecord> getSchedulesForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return schedules.where((schedule) {
      final scheduleDate = DateTime(schedule.scheduledStart.year,
          schedule.scheduledStart.month, schedule.scheduledStart.day);
      return scheduleDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<AttendanceRecord> getTodaysSchedules() {
    return getSchedulesForDate(DateTime.now());
  }

  List<AttendanceRecord> getUpcomingSchedules([int days = 7]) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return schedules
        .where((schedule) =>
            schedule.scheduledStart.isAfter(now) &&
            schedule.scheduledStart.isBefore(future))
        .toList();
  }
}
