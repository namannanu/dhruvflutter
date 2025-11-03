import 'package:talent/core/models/user.dart';

class BusinessContext {
  final String? businessId;
  final bool allBusinesses;
  final bool canCreateNewBusiness;
  final bool canGrantAccessToOthers;

  BusinessContext({
    this.businessId,
    required this.allBusinesses,
    required this.canCreateNewBusiness,
    required this.canGrantAccessToOthers,
  });

  factory BusinessContext.fromJson(Map<String, dynamic> json) {
    return BusinessContext(
      businessId: json['businessId'] as String?,
      allBusinesses: (json['allBusinesses'] ?? false) as bool,
      canCreateNewBusiness: (json['canCreateNewBusiness'] ?? false) as bool,
      canGrantAccessToOthers: (json['canGrantAccessToOthers'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'allBusinesses': allBusinesses,
      'canCreateNewBusiness': canCreateNewBusiness,
      'canGrantAccessToOthers': canGrantAccessToOthers,
    };
  }
}

class AccessRestrictions {
  final DateTime? startDate;
  final DateTime? endDate;

  AccessRestrictions({
    this.startDate,
    this.endDate,
  });

  factory AccessRestrictions.fromJson(Map<String, dynamic> json) {
    return AccessRestrictions(
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

class TeamAccess {
  final String id;
  final String? managedUserId;
  final String? targetUserId;
  final String? userEmail;
  final String? employeeId;
  final String accessLevel;
  final String accessScope;
  final String role;
  final TeamPermissions permissions;
  final BusinessContext? businessContext;
  final AccessRestrictions? restrictions;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final String? reason;
  final String? notes;
  final TeamMember? grantedByUser;
  final TeamMember? managedUser;
  final TeamMember? employee;

  TeamAccess({
    required this.id,
    this.managedUserId,
    this.targetUserId,
    this.userEmail,
    this.employeeId,
    required this.accessLevel,
    required this.accessScope,
    required this.role,
    required this.permissions,
    this.businessContext,
    this.restrictions,
    this.expiresAt,
    this.revokedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.reason,
    this.notes,
    this.grantedByUser,
    this.managedUser,
    this.employee,
  });

  factory TeamAccess.fromJson(Map<String, dynamic> json) {
    return TeamAccess(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      managedUserId: json['managedUserId'] as String?,
      targetUserId: json['targetUserId'] as String?,
      userEmail: json['userEmail'] as String?,
      employeeId: json['employeeId'] as String?,
      accessLevel: (json['accessLevel'] ?? 'view_only') as String,
      accessScope: (json['accessScope'] ?? 'user_specific') as String,
      role: (json['role'] ?? 'custom') as String,
      permissions: TeamPermissions.fromJson(
          (json['permissions'] ?? {}) as Map<String, dynamic>),
      businessContext: json['businessContext'] != null
          ? BusinessContext.fromJson(
              json['businessContext'] as Map<String, dynamic>)
          : null,
      restrictions: json['restrictions'] != null
          ? AccessRestrictions.fromJson(
              json['restrictions'] as Map<String, dynamic>)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
      status: (json['status'] ?? 'active') as String,
      createdAt: DateTime.parse(
          (json['createdAt'] ?? DateTime.now().toIso8601String()) as String),
      updatedAt: DateTime.parse(
          (json['updatedAt'] ?? DateTime.now().toIso8601String()) as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      grantedByUser: json['grantedByUser'] != null
          ? TeamMember.fromJson(json['grantedByUser'] as Map<String, dynamic>)
          : null,
      managedUser: json['managedUser'] != null
          ? TeamMember.fromJson(json['managedUser'] as Map<String, dynamic>)
          : null,
      employee: json['employee'] != null
          ? TeamMember.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'managedUserId': managedUserId,
      'targetUserId': targetUserId,
      'userEmail': userEmail,
      'employeeId': employeeId,
      'accessLevel': accessLevel,
      'accessScope': accessScope,
      'role': role,
      'permissions': permissions.toJson(),
      'businessContext': businessContext?.toJson(),
      'restrictions': restrictions?.toJson(),
      'expiresAt': expiresAt?.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'reason': reason,
      'notes': notes,
      'grantedByUser': grantedByUser?.toJson(),
      'managedUser': managedUser?.toJson(),
      'employee': employee?.toJson(),
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == 'active' && !isExpired;

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'staff':
        return 'Staff Member';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active':
        return isExpired ? 'Expired' : 'Active';
      case 'revoked':
        return 'Revoked';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

class TeamPermissions {
  // Business permissions
  final bool canCreateBusiness;
  final bool canEditBusiness;
  final bool canDeleteBusiness;
  final bool canViewBusiness;

  // Job permissions
  final bool canCreateJobs;
  final bool canEditJobs;
  final bool canDeleteJobs;
  final bool canViewJobs;

  // Application permissions
  final bool canViewApplications;
  final bool canManageApplications;

  // Shift permissions
  final bool canCreateShifts;
  final bool canEditShifts;
  final bool canDeleteShifts;
  final bool canViewShifts;

  // Worker permissions
  final bool canViewWorkers;
  final bool canManageWorkers;
  final bool canHireWorkers;
  final bool canFireWorkers;

  // Team permissions
  final bool canViewTeam;
  final bool canManageTeam;
  final bool canGrantAccess;

  // Attendance permissions
  final bool canCreateAttendance;
  final bool canEditAttendance;
  final bool canViewAttendance;
  final bool canManageAttendance;

  // Employment permissions
  final bool canViewEmployment;
  final bool canManageEmployment;

  // Payment permissions
  final bool canViewPayments;
  final bool canManagePayments;
  final bool canProcessPayments;

  // Budget permissions
  final bool canViewBudgets;
  final bool canManageBudgets;

  // Analytics & Reports permissions
  final bool canViewAnalytics;
  final bool canViewReports;
  final bool canExportData;

  TeamPermissions({
    this.canCreateBusiness = false,
    this.canEditBusiness = false,
    this.canDeleteBusiness = false,
    this.canViewBusiness = false,
    this.canCreateJobs = false,
    this.canEditJobs = false,
    this.canDeleteJobs = false,
    this.canViewJobs = false,
    this.canViewApplications = false,
    this.canManageApplications = false,
    this.canCreateShifts = false,
    this.canEditShifts = false,
    this.canDeleteShifts = false,
    this.canViewShifts = false,
    this.canViewWorkers = false,
    this.canManageWorkers = false,
    this.canHireWorkers = false,
    this.canFireWorkers = false,
    this.canViewTeam = false,
    this.canManageTeam = false,
    this.canGrantAccess = false,
    this.canCreateAttendance = false,
    this.canEditAttendance = false,
    this.canViewAttendance = false,
    this.canManageAttendance = false,
    this.canViewEmployment = false,
    this.canManageEmployment = false,
    this.canViewPayments = false,
    this.canManagePayments = false,
    this.canProcessPayments = false,
    this.canViewBudgets = false,
    this.canManageBudgets = false,
    this.canViewAnalytics = false,
    this.canViewReports = false,
    this.canExportData = false,
  });

  factory TeamPermissions.fromJson(Map<String, dynamic> json) {
    return TeamPermissions(
      canCreateBusiness: json['canCreateBusiness'] as bool? ?? false,
      canEditBusiness: json['canEditBusiness'] as bool? ?? false,
      canDeleteBusiness: json['canDeleteBusiness'] as bool? ?? false,
      canViewBusiness: json['canViewBusiness'] as bool? ?? false,
      canCreateJobs: json['canCreateJobs'] as bool? ?? false,
      canEditJobs: json['canEditJobs'] as bool? ?? false,
      canDeleteJobs: json['canDeleteJobs'] as bool? ?? false,
      canViewJobs: json['canViewJobs'] as bool? ?? false,
      canViewApplications: json['canViewApplications'] as bool? ?? false,
      canManageApplications: json['canManageApplications'] as bool? ?? false,
      canCreateShifts: json['canCreateShifts'] as bool? ?? false,
      canEditShifts: json['canEditShifts'] as bool? ?? false,
      canDeleteShifts: json['canDeleteShifts'] as bool? ?? false,
      canViewShifts: json['canViewShifts'] as bool? ?? false,
      canViewWorkers: json['canViewWorkers'] as bool? ?? false,
      canManageWorkers: json['canManageWorkers'] as bool? ?? false,
      canHireWorkers: json['canHireWorkers'] as bool? ?? false,
      canFireWorkers: json['canFireWorkers'] as bool? ?? false,
      canViewTeam: json['canViewTeam'] as bool? ?? false,
      canManageTeam: json['canManageTeam'] as bool? ?? false,
      canGrantAccess: json['canGrantAccess'] as bool? ?? false,
      canCreateAttendance: json['canCreateAttendance'] as bool? ?? false,
      canEditAttendance: json['canEditAttendance'] as bool? ?? false,
      canViewAttendance: json['canViewAttendance'] as bool? ?? false,
      canManageAttendance: json['canManageAttendance'] as bool? ?? false,
      canViewEmployment: json['canViewEmployment'] as bool? ?? false,
      canManageEmployment: json['canManageEmployment'] as bool? ?? false,
      canViewPayments: json['canViewPayments'] as bool? ?? false,
      canManagePayments: json['canManagePayments'] as bool? ?? false,
      canProcessPayments: json['canProcessPayments'] as bool? ?? false,
      canViewBudgets: json['canViewBudgets'] as bool? ?? false,
      canManageBudgets: json['canManageBudgets'] as bool? ?? false,
      canViewAnalytics: json['canViewAnalytics'] as bool? ?? false,
      canViewReports: json['canViewReports'] as bool? ?? false,
      canExportData: json['canExportData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canCreateBusiness': canCreateBusiness,
      'canEditBusiness': canEditBusiness,
      'canDeleteBusiness': canDeleteBusiness,
      'canViewBusiness': canViewBusiness,
      'canCreateJobs': canCreateJobs,
      'canEditJobs': canEditJobs,
      'canDeleteJobs': canDeleteJobs,
      'canViewJobs': canViewJobs,
      'canViewApplications': canViewApplications,
      'canManageApplications': canManageApplications,
      'canCreateShifts': canCreateShifts,
      'canEditShifts': canEditShifts,
      'canDeleteShifts': canDeleteShifts,
      'canViewShifts': canViewShifts,
      'canViewWorkers': canViewWorkers,
      'canManageWorkers': canManageWorkers,
      'canHireWorkers': canHireWorkers,
      'canFireWorkers': canFireWorkers,
      'canViewTeam': canViewTeam,
      'canManageTeam': canManageTeam,
      'canGrantAccess': canGrantAccess,
      'canCreateAttendance': canCreateAttendance,
      'canEditAttendance': canEditAttendance,
      'canViewAttendance': canViewAttendance,
      'canManageAttendance': canManageAttendance,
      'canViewEmployment': canViewEmployment,
      'canManageEmployment': canManageEmployment,
      'canViewPayments': canViewPayments,
      'canManagePayments': canManagePayments,
      'canProcessPayments': canProcessPayments,
      'canViewBudgets': canViewBudgets,
      'canManageBudgets': canManageBudgets,
      'canViewAnalytics': canViewAnalytics,
      'canViewReports': canViewReports,
      'canExportData': canExportData,
    };
  }

  // Predefined role permissions based on backend access levels
  static TeamPermissions fullAccess() => TeamPermissions(
        canCreateBusiness: true,
        canEditBusiness: true,
        canDeleteBusiness: true,
        canViewBusiness: true,
        canCreateJobs: true,
        canEditJobs: true,
        canDeleteJobs: true,
        canViewJobs: true,
        canViewApplications: true,
        canManageApplications: true,
        canCreateShifts: true,
        canEditShifts: true,
        canDeleteShifts: true,
        canViewShifts: true,
        canViewWorkers: true,
        canManageWorkers: true,
        canHireWorkers: true,
        canFireWorkers: true,
        canViewTeam: true,
        canManageTeam: true,
        canGrantAccess: true,
        canCreateAttendance: true,
        canEditAttendance: true,
        canViewAttendance: true,
        canManageAttendance: true,
        canViewEmployment: true,
        canManageEmployment: true,
        canViewPayments: true,
        canManagePayments: true,
        canProcessPayments: true,
        canViewBudgets: true,
        canManageBudgets: true,
        canViewAnalytics: true,
        canViewReports: true,
        canExportData: true,
      );

  static TeamPermissions manageOperations() => TeamPermissions(
        canViewBusiness: true,
        canEditBusiness: true,
        canCreateJobs: true,
        canEditJobs: true,
        canViewJobs: true,
        canViewApplications: true,
        canManageApplications: true,
        canCreateAttendance: true,
        canEditAttendance: true,
        canViewAttendance: true,
        canManageAttendance: true,
        canViewWorkers: true,
        canManageWorkers: true,
        canHireWorkers: true,
        canFireWorkers: true,
        canViewTeam: true,
        canManageTeam: true,
        canViewPayments: true,
        canViewBudgets: true,
        canViewEmployment: true,
        canManageEmployment: true,
        canViewAnalytics: true,
        canViewReports: true,
      );

  static TeamPermissions viewOnly() => TeamPermissions(
        canViewBusiness: true,
        canViewJobs: true,
        canViewApplications: true,
        canViewAttendance: true,
        canViewWorkers: true,
        canViewTeam: true,
        canViewEmployment: true,
        canViewAnalytics: true,
        canViewReports: true,
      );

  /// Check if a specific permission is enabled
  bool hasPermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'create_jobs':
      case 'cancreatedjobs':
        return canCreateJobs;
      case 'edit_jobs':
      case 'caneditjobs':
        return canEditJobs;
      case 'delete_jobs':
      case 'candeletejobs':
        return canDeleteJobs;
      case 'view_jobs':
      case 'canviewjobs':
        return canViewJobs;
      case 'hire_workers':
      case 'canhireworkers':
        return canHireWorkers;
      case 'view_applications':
      case 'canviewapplications':
        return canViewApplications;
      case 'manage_applications':
      case 'canmanageapplications':
        return canManageApplications;
      case 'create_attendance':
      case 'cancreateattendance':
        return canCreateAttendance;
      case 'view_attendance':
      case 'canviewattendance':
        return canViewAttendance;
      case 'edit_attendance':
      case 'caneditattendance':
        return canEditAttendance;
      case 'manage_employment':
      case 'canmanageemployment':
        return canManageEmployment;
      case 'view_employment':
      case 'canviewemployment':
        return canViewEmployment;
      case 'view_payments':
      case 'canviewpayments':
        return canViewPayments;
      case 'process_payments':
      case 'canprocesspayments':
        return canProcessPayments;
      case 'manage_team':
      case 'canmanageteam':
        return canManageTeam;
      case 'view_team_reports':
      case 'canviewteamreports':
        return canViewReports;
      case 'full_access':
        return canManageTeam && canProcessPayments && canDeleteJobs;
      default:
        return false;
    }
  }

  List<String> get enabledPermissions {
    final List<String> permissions = [];

    if (canCreateJobs) permissions.add('Create Jobs');
    if (canEditJobs) permissions.add('Edit Jobs');
    if (canDeleteJobs) permissions.add('Delete Jobs');
    if (canViewJobs) permissions.add('View Jobs');
    if (canHireWorkers) permissions.add('Hire Workers');
    if (canViewApplications) permissions.add('View Applications');
    if (canManageApplications) permissions.add('Manage Applications');
    if (canCreateAttendance) permissions.add('Create Attendance');
    if (canViewAttendance) permissions.add('View Attendance');
    if (canEditAttendance) permissions.add('Edit Attendance');
    if (canManageEmployment) permissions.add('Manage Employment');
    if (canViewEmployment) permissions.add('View Employment');
    if (canViewPayments) permissions.add('View Payments');
    if (canProcessPayments) permissions.add('Process Payments');
    if (canManageTeam) permissions.add('Manage Team');
    if (canViewReports) permissions.add('View Reports');

    return permissions;
  }
}

class TeamMember {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;

  TeamMember({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.avatar, required String id, required User user, required String businessId, required String role, required bool isActive, required List<String> permissions,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?, id: '', user: User.fromJson(json['user'] as Map<String, dynamic>), businessId: '', role: '', isActive: false, permissions: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
    };
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class TeamAccessReport {
  final String userId;
  final int totalAccessesGranted;
  final int activeAccesses;
  final int expiredAccesses;
  final int revokedAccesses;
  final DateTime? lastGrantedAt;
  final DateTime? lastAccessedAt;
  final List<TeamAccess> recentActivities;

  TeamAccessReport({
    required this.userId,
    required this.totalAccessesGranted,
    required this.activeAccesses,
    required this.expiredAccesses,
    required this.revokedAccesses,
    this.lastGrantedAt,
    this.lastAccessedAt,
    required this.recentActivities,
  });

  factory TeamAccessReport.fromJson(Map<String, dynamic> json) {
    return TeamAccessReport(
      userId: json['userId'] as String? ?? '',
      totalAccessesGranted: json['totalAccessesGranted'] as int? ?? 0,
      activeAccesses: json['activeAccesses'] as int? ?? 0,
      expiredAccesses: json['expiredAccesses'] as int? ?? 0,
      revokedAccesses: json['revokedAccesses'] as int? ?? 0,
      lastGrantedAt: json['lastGrantedAt'] != null
          ? DateTime.parse(json['lastGrantedAt'] as String)
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      recentActivities: (json['recentActivities'] as List<dynamic>?)
              ?.map((e) => TeamAccess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalAccessesGranted': totalAccessesGranted,
      'activeAccesses': activeAccesses,
      'expiredAccesses': expiredAccesses,
      'revokedAccesses': revokedAccesses,
      'lastGrantedAt': lastGrantedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'recentActivities': recentActivities.map((e) => e.toJson()).toList(),
    };
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'],
      statusCode: json['statusCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }
}
