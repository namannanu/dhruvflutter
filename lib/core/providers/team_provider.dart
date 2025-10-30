import 'package:flutter/material.dart';
import '../models/team_access.dart';
import '../services/team_service.dart';

class TeamProvider with ChangeNotifier {
  List<TeamAccess> _teamMembers = [];
  List<TeamAccess> _managedAccess = [];
  TeamAccessReport? _accessReport;
  bool _isLoading = false;
  String? _error;

  List<TeamAccess> get teamMembers => _teamMembers;
  List<TeamAccess> get managedAccess => _managedAccess;
  TeamAccessReport? get accessReport => _accessReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<TeamAccess> get activeTeamMembers =>
      _teamMembers.where((access) => access.isActive).toList();

  List<TeamAccess> get expiredTeamMembers =>
      _teamMembers.where((access) => access.isExpired).toList();

  int get totalTeamMembers => _teamMembers.length;
  int get activeTeamMembersCount => activeTeamMembers.length;

  /// Load team members managed by current user
  Future<void> loadTeamMembers(String currentUserId) async {
    _setLoading(true);
    try {
      _teamMembers = await TeamService.getMyTeamMembers(currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _teamMembers = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load access rights granted to current user
  Future<void> loadManagedAccess(String currentUserId) async {
    _setLoading(true);
    try {
      _managedAccess = await TeamService.getMyManagedAccess(currentUserId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _managedAccess = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Grant access to a team member
  Future<bool> grantAccess({
    required String currentUserId,
    String? userEmail,
    String? employeeId,
    String? managedUserId,
    String? managedUserEmail,
    String? targetUserId,
    String accessLevel = 'view_only',
    String? role,
    TeamPermissions? permissions,
    String? accessScope,
    Map<String, dynamic>? businessContext,
    Map<String, dynamic>? restrictions,
    DateTime? expiresAt,
    String? status,
    String? reason,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      final response = await TeamService.grantTeamAccess(
        currentUserId: currentUserId,
        userEmail: userEmail,
        employeeId: employeeId,
        managedUserId: managedUserId,
        managedUserEmail: managedUserEmail,
        targetUserId: targetUserId,
        accessLevel: accessLevel,
        role: role,
        permissions: permissions,
        accessScope: accessScope,
        businessContext: businessContext,
        restrictions: restrictions,
        expiresAt: expiresAt,
        status: status,
        reason: reason,
        notes: notes,
      );

      if (response.success) {
        // Reload team members
        await loadTeamMembers(currentUserId);
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update team member permissions
  Future<bool> updateAccess({
    String? currentUserId,
    required String identifier,
    String? accessLevel,
    String? role,
    TeamPermissions? permissions,
    String? status,
    Map<String, dynamic>? businessContext,
    DateTime? expiresAt,
    Map<String, dynamic>? restrictions,
    String? reason,
    String? notes,
  }) async {
    try {
      final response = await TeamService.updateTeamAccess(
        identifier: identifier,
        accessLevel: accessLevel,
        role: role,
        permissions: permissions,
        status: status,
        businessContext: businessContext,
        expiresAt: expiresAt,
        restrictions: restrictions,
        reason: reason,
        notes: notes,
      );

      if (response.success) {
        if (currentUserId != null && currentUserId.isNotEmpty) {
          await loadTeamMembers(currentUserId);
        } else {
          final index =
              _teamMembers.indexWhere((access) => access.id == identifier);
          if (index != -1 && response.data is Map<String, dynamic>) {
            _teamMembers[index] = TeamAccess.fromJson(
                response.data as Map<String, dynamic>);
          }
          notifyListeners();
        }
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Revoke team member access
  Future<bool> revokeAccess({
    required String identifier,
    String? reason,
  }) async {
    try {
      final response = await TeamService.revokeTeamAccess(
        identifier: identifier,
        reason: reason,
      );

      if (response.success) {
        // Remove from local list
        _teamMembers.removeWhere((access) => access.id == identifier);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if current user has access to another user by email
  Future<Map<String, dynamic>?> checkAccessByEmail({
    required String email,
    String? permission,
  }) async {
    try {
      return await TeamService.checkTeamAccessByEmail(
        email: email,
        permission: permission,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Search for users
  Future<List<TeamMember>> searchUsers(String query) async {
    try {
      return await TeamService.searchUsers(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get user profile by userId
  Future<TeamMember?> getUserProfile(String userId) async {
    try {
      return await TeamService.getUserProfile(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Load access report for a user
  Future<void> loadAccessReport(String userId) async {
    _setLoading(true);
    try {
      _accessReport = await TeamService.getAccessReport(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _accessReport = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user data by userId
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      return await TeamService.getUserData(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Validate user location
  Future<bool> validateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? businessId,
    String? workLocationId,
  }) async {
    try {
      return await TeamService.validateUserLocation(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        businessId: businessId,
        workLocationId: workLocationId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load all team data for current user
  Future<void> loadAllTeamData(String currentUserId) async {
    await Future.wait([
      loadTeamMembers(currentUserId),
      loadManagedAccess(currentUserId),
    ]);
  }

  /// Refresh all data
  Future<void> refresh(String currentUserId) async {
    await loadAllTeamData(currentUserId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Permission helpers
  bool hasPermission(String accessId, String permission) {
    final access = _teamMembers.firstWhere(
      (access) => access.id == accessId,
      orElse: () => throw Exception('Access not found'),
    );
    return access.permissions.hasPermission(permission);
  }

  bool canManageTeam(String accessId) {
    return hasPermission(accessId, 'manage_team');
  }

  bool canViewAnalytics(String accessId) {
    return hasPermission(accessId, 'view_analytics');
  }

  bool canManageAttendance(String accessId) {
    return hasPermission(accessId, 'manage_attendance');
  }

  bool canManagePayroll(String accessId) {
    return hasPermission(accessId, 'manage_payroll');
  }

  bool canManageSchedule(String accessId) {
    return hasPermission(accessId, 'manage_schedule');
  }

  bool canManageJobs(String accessId) {
    return hasPermission(accessId, 'manage_jobs');
  }

  bool canManageReports(String accessId) {
    return hasPermission(accessId, 'manage_reports');
  }

  bool canViewFullAccess(String accessId) {
    return hasPermission(accessId, 'full_access');
  }

  /// Team statistics
  Map<String, int> get teamStatistics {
    return {
      'total': totalTeamMembers,
      'active': activeTeamMembersCount,
      'expired': expiredTeamMembers.length,
    };
  }

  /// Get team members by role
  List<TeamAccess> getTeamMembersByRole(String role) {
    return _teamMembers.where((access) => access.role == role).toList();
  }

  /// Get team members by permission
  List<TeamAccess> getTeamMembersByPermission(String permission) {
    return _teamMembers
        .where((access) => access.permissions.hasPermission(permission))
        .toList();
  }
}
