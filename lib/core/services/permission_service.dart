// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';

/// Centralized service for handling permission-based access control
/// This version uses AppState cached data instead of making API calls
class PermissionService {
  final BuildContext? _context;

  PermissionService({BuildContext? context}) : _context = context;

  /// Static instance for use without context
  static PermissionService? _instance;

  static PermissionService get instance {
    _instance ??= PermissionService._internal();
    return _instance!;
  }

  PermissionService._internal() : _context = null;

  /// All available permissions in the system
  static const Map<String, String> allPermissions = {
    // Business Management
    'create_business': 'Create Business',
    'edit_business': 'Edit Business',
    'delete_business': 'Delete Business',
    'view_business_analytics': 'View Business Analytics',

    // Job Management
    'create_jobs': 'Create Jobs',
    'edit_jobs': 'Edit Jobs',
    'delete_jobs': 'Delete Jobs',
    'view_jobs': 'View Jobs',
    'post_jobs': 'Post Jobs',

    // Worker & Application Management
    'hire_workers': 'Hire Workers',
    'fire_workers': 'Fire Workers',
    'view_applications': 'View Applications',
    'manage_applications': 'Manage Applications',
    'approve_applications': 'Approve Applications',
    'reject_applications': 'Reject Applications',

    // Schedule & Attendance Management
    'create_schedules': 'Create Schedules',
    'edit_schedules': 'Edit Schedules',
    'delete_schedules': 'Delete Schedules',
    'manage_schedules': 'Manage Schedules',
    'view_attendance': 'View Attendance',
    'manage_attendance': 'Manage Attendance',
    'approve_attendance': 'Approve Attendance',

    // Payment & Financial Management
    'view_payments': 'View Payments',
    'manage_payments': 'Manage Payments',
    'process_payments': 'Process Payments',
    'view_financial_reports': 'View Financial Reports',

    // Team Management
    'invite_team_members': 'Invite Team Members',
    'edit_team_members': 'Edit Team Members',
    'view_team_members': 'View Team Members',
    'manage_team_members': 'Manage Team Members',
    'remove_team_members': 'Remove Team Members',
    'manage_permissions': 'Manage Permissions',

    // Analytics & Reporting
    'view_analytics': 'View Analytics',
    'view_reports': 'View Reports',
    'export_data': 'Export Data',

    // System Administration
    'manage_settings': 'Manage Settings',
    'view_audit_logs': 'View Audit Logs',
    'manage_integrations': 'Manage Integrations',
  };

  /// Get current user's permissions (uses AppState cache)
  List<String> getCurrentUserPermissions() {
    if (_context == null) {
      return [];
    }

    try {
      final appState = _context.read<AppState>();
      final user = appState.currentUser;

      if (user == null) {
        print('⚠️ PermissionService: No current user');
        return [];
      }

      // Try to get permissions from AppState cached team member data
      final permissions = appState.getCurrentUserPermissions();
      if (permissions.isNotEmpty) {
        return permissions;
      }

      // If no cached team member data, trigger load but return fallback permissions
      final businessId = user.selectedBusinessId;
      if (businessId != null && businessId.isNotEmpty) {
        Future.microtask(() => appState.loadCurrentUserTeamMemberInfo());
      }

      // Fallback: basic permissions for employers while data loads
      if (user.type == UserType.employer) {
        return [
          'view_jobs',
          'create_jobs',
          'edit_jobs',
          'post_jobs',
          'view_applications',
          'manage_applications',
          'view_team_members',
          'view_analytics'
        ];
      }

      return [];
    } catch (error) {
      return [];
    }
  }

  /// Get current user's role
  String getCurrentUserRole() {
    if (_context == null) return '';

    try {
      final appState = _context.read<AppState>();
      final teamMember = appState.currentUserTeamMember;

      if (teamMember != null) {
        return teamMember.role;
      }

      // Fallback to user type
      final user = appState.currentUser;
      return user?.type.name ?? '';
    } catch (error) {
      return '';
    }
  }

  /// Check if current user has a specific permission
  bool hasPermission(String permission) {
    return getCurrentUserPermissions().contains(permission);
  }

  /// Check if current user has any of the specified permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if current user has all of the specified permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Convenience methods for common permission checks
  bool get canCreateBusiness => hasPermission('create_business');
  bool get canEditBusiness => hasPermission('edit_business');
  bool get canDeleteBusiness => hasPermission('delete_business');

  bool get canCreateJobs => hasPermission('create_jobs');
  bool get canEditJobs => hasPermission('edit_jobs');
  bool get canDeleteJobs => hasPermission('delete_jobs');
  bool get canPostJobs => hasPermission('post_jobs');

  bool get canViewApplications => hasPermission('view_applications');
  bool get canManageApplications => hasPermission('manage_applications');
  bool get canApproveApplications => hasPermission('approve_applications');
  bool get canRejectApplications => hasPermission('reject_applications');

  bool get canViewAttendance => hasPermission('view_attendance');
  bool get canManageAttendance => hasPermission('manage_attendance');
  bool get canApproveAttendance => hasPermission('approve_attendance');

  bool get canViewPayments => hasPermission('view_payments');
  bool get canManagePayments => hasPermission('manage_payments');
  bool get canProcessPayments => hasPermission('process_payments');

  bool get canInviteTeamMembers => hasPermission('invite_team_members');
  bool get canEditTeamMembers => hasPermission('edit_team_members');
  bool get canViewTeamMembers => hasPermission('view_team_members');
  bool get canManageTeamMembers => hasPermission('manage_team_members');
  bool get canRemoveTeamMembers => hasPermission('remove_team_members');
  bool get canManagePermissions => hasPermission('manage_permissions');

  bool get canViewAnalytics => hasPermission('view_analytics');
  bool get canViewReports => hasPermission('view_reports');
  bool get canExportData => hasPermission('export_data');

  /// Refresh permissions by triggering AppState to reload team member data
  Future<void> refreshPermissions() async {
    if (_context == null) return;

    try {
      final appState = _context.read<AppState>();
      await appState.loadCurrentUserTeamMemberInfo();
    } catch (error) {
      // Silently ignore errors when loading team member info
      // This prevents crashes if the user is not part of any team
    }
  }

  /// Check permission for API endpoint
  bool canAccessEndpoint(String method, String endpoint) {
    // Map API endpoints to required permissions
    final Map<String, List<String>> apiPermissions = {
      // Business endpoints
      'POST:/api/businesses': ['create_business'],
      'PUT:/api/businesses': ['edit_business'],
      'DELETE:/api/businesses': ['delete_business'],

      // Job endpoints
      'POST:/api/jobs': ['create_jobs'],
      'PUT:/api/jobs': ['edit_jobs'],
      'DELETE:/api/jobs': ['delete_jobs'],

      // Application endpoints
      'GET:/api/applications': ['view_applications'],
      'PUT:/api/applications': ['manage_applications'],
      'POST:/api/applications/approve': ['approve_applications'],
      'POST:/api/applications/reject': ['reject_applications'],

      // Attendance endpoints
      'GET:/api/attendance': ['view_attendance'],
      'PUT:/api/attendance': ['manage_attendance'],
      'POST:/api/attendance/approve': ['approve_attendance'],

      // Team endpoints
      'POST:/api/team/invite': ['invite_team_members'],
      'PUT:/api/team': ['edit_team_members'],
      'DELETE:/api/team': ['remove_team_members'],

      // Payment endpoints
      'GET:/api/payments': ['view_payments'],
      'PUT:/api/payments': ['manage_payments'],
      'POST:/api/payments/process': ['process_payments'],
    };

    final key = '$method:$endpoint';
    final requiredPermissions = apiPermissions[key];

    if (requiredPermissions == null) {
      // If no specific permissions required, allow access
      return true;
    }

    return hasAnyPermission(requiredPermissions);
  }
}
