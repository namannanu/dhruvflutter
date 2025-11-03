import 'package:flutter/foundation.dart';
import 'enums.dart' show JobStatus;

@immutable
class EmployerProfile {
  const EmployerProfile({
    required this.id,
    required this.companyName,
    required this.description,
    required this.phone,
    required this.rating,
    required this.totalJobsPosted,
    required this.totalHires,
    required this.activeBusinesses,
    String? profilePictureMedium,
    String? profilePictureLarge,
    String? companyLogo,
    String? companyLogoSmall,
    String? companyLogoMedium,
    String? companyLogoLarge,
  });

  final String id;
  final String companyName;
  final String description;
  final String phone;
  final double rating;
  final int totalJobsPosted;
  final int totalHires;
  final int activeBusinesses;

  factory EmployerProfile.fromJson(Map<String, dynamic> json) {
    return EmployerProfile(
      id: json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobsPosted: json['totalJobsPosted'] as int? ?? 0,
      totalHires: json['totalHires'] as int? ?? 0,
      activeBusinesses: json['activeBusinesses'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'description': description,
      'phone': phone,
      'rating': rating,
      'totalJobsPosted': totalJobsPosted,
      'totalHires': totalHires,
      'activeBusinesses': activeBusinesses,
    };
  }
}

@immutable
class EmployerDashboardMetrics {
  const EmployerDashboardMetrics({
    required this.openJobs,
    required this.totalApplicants,
    required this.totalHires,
    required this.averageResponseTimeHours,
    required this.freePostingsRemaining,
    required this.premiumActive,
    this.recentJobSummaries = const [],
  });

  final int openJobs;
  final int totalApplicants;
  final int totalHires;
  final double averageResponseTimeHours;
  final int freePostingsRemaining;
  final bool premiumActive;
  final List<JobSummary> recentJobSummaries;

  factory EmployerDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return EmployerDashboardMetrics(
      openJobs: json['openJobs'] as int? ?? 0,
      totalApplicants: json['totalApplicants'] as int? ?? 0,
      totalHires: json['totalHires'] as int? ?? 0,
      averageResponseTimeHours:
          (json['averageResponseTimeHours'] as num?)?.toDouble() ?? 0.0,
      freePostingsRemaining: json['freePostingsRemaining'] as int? ?? 0,
      premiumActive: json['premiumActive'] as bool? ?? false,
      recentJobSummaries: (json['recentJobSummaries'] as List?)
              ?.map((e) => JobSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openJobs': openJobs,
      'totalApplicants': totalApplicants,
      'totalHires': totalHires,
      'averageResponseTimeHours': averageResponseTimeHours,
      'freePostingsRemaining': freePostingsRemaining,
      'premiumActive': premiumActive,
      'recentJobSummaries':
          recentJobSummaries.map((summary) => summary.toJson()).toList(),
    };
  }
}

@immutable
class JobSummary {
  const JobSummary({
    required this.jobId,
    required this.title,
    required this.applicants,
    required this.hires,
    required this.status,
    required this.updatedAt,
  });

  final String jobId;
  final String title;
  final int applicants;
  final int hires;
  final JobStatus status;
  final DateTime updatedAt;

  factory JobSummary.fromJson(Map<String, dynamic> json) {
    return JobSummary(
      jobId: json['jobId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      applicants:
          json['applicants'] as int? ?? json['applicantCount'] as int? ?? 0,
      hires: json['hires'] as int? ?? json['hireCount'] as int? ?? 0,
      status: _parseJobStatus(json['status'] as String?),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'title': title,
      'applicants': applicants,
      'hires': hires,
      'status': status.toString().split('.').last,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static JobStatus _parseJobStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return JobStatus.active;
      case 'filled':
        return JobStatus.filled;
      case 'closed':
        return JobStatus.closed;
      default:
        return JobStatus.closed;
    }
  }
}
