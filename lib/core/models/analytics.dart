import 'package:flutter/material.dart';

@immutable
class EmployerDashboardMetrics {
  const EmployerDashboardMetrics({
    required this.openJobs,
    required this.totalApplicants,
    required this.totalHires,
    required this.averageResponseTimeHours,
    required this.freePostingsRemaining,
    required this.premiumActive,
    required this.recentJobSummaries,
  });

  final int openJobs;
  final int totalApplicants;
  final int totalHires;
  final double averageResponseTimeHours;
  final int freePostingsRemaining;
  final bool premiumActive;
  final List<JobSummary> recentJobSummaries;
}

@immutable
class JobSummary {
  const JobSummary({
    required this.jobId,
    required this.title,
    required this.status,
    required this.applicants,
    required this.hires,
    required this.updatedAt,
  });

  final String jobId;
  final String title;
  final String status;
  final int applicants;
  final int hires;
  final DateTime updatedAt;
}

@immutable
class AnalyticsTrendPoint {
  const AnalyticsTrendPoint({required this.label, required this.value});

  final String label;
  final double value;

  factory AnalyticsTrendPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrendPoint(
      label: json['label']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.applicationFunnel,
    required this.hireRate,
    required this.avgHourlyRate,
    required this.responseTimeTrend,
    required this.jobPerformanceTrend,
  });

  final Map<String, double> applicationFunnel;
  final double hireRate;
  final double avgHourlyRate;
  final List<AnalyticsTrendPoint> responseTimeTrend;
  final List<AnalyticsTrendPoint> jobPerformanceTrend;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] is Map
        ? json['analytics'] as Map<String, dynamic>
        : json;

    final funnel = <String, double>{};
    if (analytics['applicationFunnel'] is Map) {
      (analytics['applicationFunnel'] as Map).forEach((key, value) {
        if (value != null) {
          funnel[key.toString()] = (value as num).toDouble();
        }
      });
    }

    final hireRate = (analytics['hireRate'] as num?)?.toDouble() ?? 0.0;
    final avgHourlyRate =
        (analytics['avgHourlyRate'] as num?)?.toDouble() ?? 0.0;

    final responseTimeTrend = <AnalyticsTrendPoint>[];
    if (analytics['responseTimeTrend'] is List) {
      for (final entry in analytics['responseTimeTrend'] as List) {
        if (entry is Map) {
          final point =
              AnalyticsTrendPoint.fromJson(entry as Map<String, dynamic>);
          responseTimeTrend.add(point);
        }
      }
    }

    final jobPerformanceTrend = <AnalyticsTrendPoint>[];
    if (analytics['jobPerformanceTrend'] is List) {
      for (final entry in analytics['jobPerformanceTrend'] as List) {
        if (entry is Map) {
          final point =
              AnalyticsTrendPoint.fromJson(entry as Map<String, dynamic>);
          jobPerformanceTrend.add(point);
        }
      }
    }

    return AnalyticsSummary(
      applicationFunnel: funnel,
      hireRate: hireRate,
      avgHourlyRate: avgHourlyRate,
      responseTimeTrend: responseTimeTrend,
      jobPerformanceTrend: jobPerformanceTrend,
    );
  }
}
