import 'package:flutter/material.dart';

@immutable
class WorkerDashboardMetrics {
  const WorkerDashboardMetrics({
    required this.availableJobs,
    required this.activeApplications,
    required this.upcomingShifts,
    required this.completedHours,
    required this.earningsThisWeek,
    required this.freeApplicationsRemaining,
    required this.isPremium,
  });

  final int availableJobs;
  final int activeApplications;
  final int upcomingShifts;
  final double completedHours;
  final double earningsThisWeek;
  final int freeApplicationsRemaining;
  final bool isPremium;

  factory WorkerDashboardMetrics.fromJson(Map<String, dynamic> json) {
    double doubleValue(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int intValue(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      if (value is num) return value != 0;
      return false;
    }

    return WorkerDashboardMetrics(
      availableJobs: intValue(json['availableJobs']),
      activeApplications: intValue(json['activeApplications']),
      upcomingShifts: intValue(json['upcomingShifts']),
      completedHours: doubleValue(json['completedHours']),
      earningsThisWeek: doubleValue(json['earningsThisWeek']),
      freeApplicationsRemaining:
          intValue(json['freeApplicationsRemaining'] ?? json['freeAppsLeft']),
      isPremium: boolValue(json['isPremium'] ?? json['premium']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'availableJobs': availableJobs,
      'activeApplications': activeApplications,
      'upcomingShifts': upcomingShifts,
      'completedHours': completedHours,
      'earningsThisWeek': earningsThisWeek,
      'freeApplicationsRemaining': freeApplicationsRemaining,
      'isPremium': isPremium,
    };
  }
}
