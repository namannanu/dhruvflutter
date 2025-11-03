import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../models/team_access.dart';

/// Service to determine business access context for UI tags
class BusinessAccessContext {
  static const BusinessAccessContext _instance =
      BusinessAccessContext._internal();
  factory BusinessAccessContext() => _instance;
  const BusinessAccessContext._internal();

  /// Determines if the current user is managing data on behalf of another business owner
  /// Returns BusinessAccessInfo with owner name if shared access, null if self-owned
  BusinessAccessInfo? getAccessContext({
    required String? employerEmail,
    required String? employerName,
    required String? businessName,
    required String currentUserEmail,
    required List<TeamAccess> teamAccesses,
  }) {
    // If no employer info available, assume self-owned
    if (employerEmail == null || employerEmail.isEmpty) {
      return null;
    }

    // If current user is the employer, it's self-owned
    if (employerEmail.toLowerCase() == currentUserEmail.toLowerCase()) {
      return null;
    }

    // Check if user has team access to this business
    final hasAccess = teamAccesses.any((access) =>
        access.grantedByUser?.email.toLowerCase() ==
        employerEmail.toLowerCase());

    if (hasAccess) {
      return BusinessAccessInfo(
        ownerName: employerName ?? 'Business Owner',
        ownerEmail: employerEmail,
        businessName: businessName,
      );
    }

    return null;
  }

  /// Get access context for a job posting
  BusinessAccessInfo? getJobAccessContext({
    required JobPosting job,
    required String currentUserEmail,
    required List<TeamAccess> teamAccesses,
  }) {
    return getAccessContext(
      employerEmail: job.employerEmail,
      employerName: job.employerName,
      businessName: job.businessName.isNotEmpty ? job.businessName : null,
      currentUserEmail: currentUserEmail,
      teamAccesses: teamAccesses,
    );
  }

  /// Get access context for an application
  BusinessAccessInfo? getApplicationAccessContext({
    required Application application,
    required String currentUserEmail,
    required List<TeamAccess> teamAccesses,
  }) {
    return getAccessContext(
      employerEmail: application.employerEmail,
      employerName: application.employerName,
      businessName: application.businessName,
      currentUserEmail: currentUserEmail,
      teamAccesses: teamAccesses,
    );
  }

  /// Get access context for a shift/attendance record
  BusinessAccessInfo? getShiftAccessContext({
    required Shift shift,
    required JobPosting? job,
    required String currentUserEmail,
    required List<TeamAccess> teamAccesses,
  }) {
    // If we have the associated job, use its information
    if (job != null) {
      return getAccessContext(
        employerEmail: job.employerEmail,
        employerName: job.employerName,
        businessName: job.businessName,
        currentUserEmail: currentUserEmail,
        teamAccesses: teamAccesses,
      );
    }

    // Otherwise, we can't determine access context without employer info
    return null;
  }
}

/// Information about business access context
@immutable
class BusinessAccessInfo {
  const BusinessAccessInfo({
    required this.ownerName,
    required this.ownerEmail,
    this.businessName,
  });

  final String ownerName;
  final String ownerEmail;
  final String? businessName;

  /// Get display text for the access tag
  String get displayText {
    // Prefer business name if available, otherwise use owner name
    if (businessName != null && businessName!.isNotEmpty) {
      return businessName!;
    }
    return ownerName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessAccessInfo &&
        other.ownerName == ownerName &&
        other.ownerEmail == ownerEmail &&
        other.businessName == businessName;
  }

  @override
  int get hashCode => Object.hash(ownerName, ownerEmail, businessName);

  @override
  String toString() =>
      'BusinessAccessInfo(ownerName: $ownerName, ownerEmail: $ownerEmail, businessName: $businessName)';
}
