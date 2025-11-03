// ignore_for_file: avoid_print, prefer_single_quotes

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:talent/core/cache/cache_service.dart';
import 'package:talent/core/config/environment_config.dart';
import 'package:talent/core/config/payment_config.dart';
import 'package:talent/core/models/analytics.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/repositories/employer_repository.dart';
import 'package:talent/core/repositories/worker_repository.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/business_access_context.dart';
import 'package:talent/core/services/image_optimization_service.dart';
import 'package:talent/core/services/location_service.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/core/services/push_notification_service.dart';
import 'package:talent/services/auth_token_manager.dart';

part 'payment_extensions.dart';

class AppState extends ChangeNotifier {
  AppState(this._service) {
    _init();
  }

  final ServiceLocator _service;

  // Cache and repositories
  late CacheService _cache;
  late WorkerRepository _workerRepo;
  late EmployerRepository _employerRepo;

  bool _isBusy = false;
  User? _currentUser;
  UserType? _activeRole;
  Timer? _notificationRefreshTimer;
  Map<ApplicationStatus, List<Application>>? _statusFilterCache;

  // Worker state
  WorkerProfile? _workerProfile;
  WorkerDashboardMetrics? _workerMetrics;
  List<JobPosting> _workerJobs = [];
  List<Application> _workerApplications = [];
  List<AttendanceRecord> _workerAttendance = [];
  List<Shift> _workerShifts = [];
  List<SwapRequest> _swapRequests = [];

  // Employer state
  EmployerProfile? _employerProfile;
  EmployerDashboardMetrics? _employerMetrics;
  List<JobPosting> _employerJobs = [];
  List<BusinessLocation> _businesses = [];
  final List<TeamMember> _teamMembers = [];
  BudgetOverview? _budgetOverview;
  AnalyticsSummary? _analyticsSummary;
  final List<AttendanceRecord> _employerAttendance = [];
  List<Application> _employerApplications = [];
  String? _employerApplicationsError;
  TeamMember? _currentUserTeamMember;
  bool _isLoadingCurrentUserTeamMember = false;

  // Attendance management state
  DateTime _attendanceSelectedDate = DateTime.now();
  String _attendanceStatusFilter = 'all';
  AttendanceDashboard? _attendanceDashboard;
  AttendanceDashboardSummary? _attendanceSummary;
  bool _isAttendanceBusy = false;
  final Map<String, AttendanceSchedule> _workerAttendanceSchedules = {};
  final Map<String, bool> _workerScheduleLoading = {};

  // Shared state
  List<AppNotification> _notifications = [];
  List<Conversation> _conversations = [];
  final List<Application> _selectedJobApplications = [];
  List<JobPaymentRecord> _jobPayments = [];
  bool _isLoadingJobPayments = false;
  List<EmployerFeedback> _employerFeedback = [];
  bool _isLoadingEmployerFeedback = false;
  List<EmploymentRecord> _workerEmploymentHistory = [];
  bool _isLoadingEmploymentHistory = false;
  List<EmployerFeedback> _workerFeedback = [];
  bool _isLoadingWorkerFeedback = false;
  late Razorpay _razorpay;
  Completer<void>? _paymentCompleter;
  _PendingJobPayment? _pendingJobPayment;

  // ================== Initialization ==================

  Future<void> publishJob(String jobId) async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();

    try {
      // Call backend to publish job
      final updatedJob = await _employerRepo.publishJob(jobId);

      // Update the job in the local list
      final index = _employerJobs.indexWhere((job) => job.id == jobId);
      if (index >= 0) {
        _employerJobs[index] = updatedJob;
        notifyListeners();
      }
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _init() async {
    _cache = await CacheService.open('thrill_cache');
    _workerRepo = WorkerRepository(_cache);
    _employerRepo = EmployerRepository(_cache);
    await _checkStoredAuthentication(); // Continue with existing flow
  }

  /// Automatically check for stored authentication when app starts
  Future<void> _checkStoredAuthentication() async {
    if (kDebugMode) print('🔍 Checking for stored authentication...');

    try {
      // Check if there's a stored token directly from AuthTokenManager
      final token = await AuthTokenManager.instance.getAuthToken();

      if (token == null || token.isEmpty) {
        if (kDebugMode) print('❌ No stored auth token found');
        return;
      }

      if (kDebugMode) {
        print('🔑 Found stored token, attempting to restore session...');
      }
      _setBusy(true);

      // Import AuthTokenManager to get stored user data
      final authManager = AuthTokenManager.instance;
      final userData = await authManager.getUserData();

      if (userData != null && userData['user'] != null) {
        final userMap = userData['user'] as Map<String, dynamic>;

        // Create User object from stored data
        _currentUser = User(
          id: userMap['_id']?.toString() ?? userMap['id']?.toString() ?? '',
          firstName: userMap['firstName']?.toString() ?? '',
          lastName: userMap['lastName']?.toString() ?? '',
          email: userMap['email']?.toString() ?? '',
          phone: userMap['phone']?.toString(),
          type: userMap['userType']?.toString() == 'worker'
              ? UserType.worker
              : UserType.employer,
          isPremium: userMap['isPremium'] == true,
          freeJobsPosted: (userMap['freeJobsPosted'] as num?)?.toInt() ?? 0,
          freeApplicationsUsed:
              (userMap['freeApplicationsUsed'] as num?)?.toInt() ?? 0,
          selectedBusinessId: userMap['selectedBusinessId']?.toString(),
          roles: [], // Will be loaded by refreshActiveRole
          ownedBusinesses: [], // Will be loaded by refreshActiveRole
          teamBusinesses: [], // Will be loaded by refreshActiveRole
        );

        _activeRole = _currentUser!.type;

        if (kDebugMode) {
          print('✅ Successfully restored session for: ${_currentUser!.email}');
          print('🎭 Active role: ${_currentUser!.type}');
        }

        // Update service with token
        _service.updateAuthToken(token);

        // Hydrate from cache immediately (no spinners)
        await _hydrateFromCache();
        notifyListeners();

        // Kick background refresh (don't block UI)
        unawaited(_refreshInBackground());
      } else {
        if (kDebugMode) print('❌ No valid stored user data found');
        // Clear invalid token
        await authManager.clearAll();
      }
    } catch (error) {
      if (kDebugMode) print('❌ Error restoring stored authentication: $error');
      // Clear invalid token on error
      try {
        final authManager = AuthTokenManager.instance;
        await authManager.clearAll();
      } catch (logoutError) {
        if (kDebugMode) print('❌ Error clearing invalid token: $logoutError');
      }
    } finally {
      _setBusy(false);
    }
  }

  // ================== Worker Preferences Methods ==================
  Future<void> updateWorkerPreferences({
    double? minimumPay,
    double? maxTravelDistance,
    bool? availableForFullTime,
    bool? availableForPartTime,
    bool? availableForTemporary,
    String? weekAvailability,
  }) async {
    if (_workerProfile == null) return;

    final workerId = _workerProfile!.id.isNotEmpty
        ? _workerProfile!.id
        : (_currentUser?.id ?? '');

    if (workerId.isEmpty) {
      debugPrint('⚠️ Cannot update worker profile: missing workerId');
      return;
    }

    _setBusy(true);
    try {
      final updatedProfile = await _service.worker.updateWorkerProfile(
        workerId: workerId,
        minimumPay: minimumPay,
        maxTravelDistance: maxTravelDistance,
        availableForFullTime: availableForFullTime,
        availableForPartTime: availableForPartTime,
        availableForTemporary: availableForTemporary,
        weekAvailability: weekAvailability,
      );
      _workerProfile = updatedProfile;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updatePrivacySettings({
    bool? isVisible,
    bool? locationEnabled,
    bool? shareWorkHistory,
  }) async {
    if (_workerProfile == null) return;

    final workerId = _workerProfile!.id.isNotEmpty
        ? _workerProfile!.id
        : (_currentUser?.id ?? '');

    if (workerId.isEmpty) {
      debugPrint('⚠️ Cannot update worker profile: missing workerId');
      return;
    }

    _setBusy(true);
    try {
      final updatedProfile = await _service.worker.updateWorkerProfile(
        workerId: workerId,
        isVisible: isVisible,
        locationEnabled: locationEnabled,
        shareWorkHistory: shareWorkHistory,
      );
      _workerProfile = updatedProfile;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateWorkerNotificationSettings({
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    if (_workerProfile == null) return;

    final workerId = _workerProfile!.id.isNotEmpty
        ? _workerProfile!.id
        : (_currentUser?.id ?? '');

    if (workerId.isEmpty) {
      debugPrint('⚠️ Cannot update worker profile: missing workerId');
      return;
    }

    _setBusy(true);
    try {
      final updatedProfile = await _service.worker.updateWorkerProfile(
        workerId: workerId,
        notificationsEnabled: pushEnabled,
        emailNotificationsEnabled: emailEnabled,
      );
      _workerProfile = updatedProfile;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteAccount() async {
    _setBusy(true);
    try {
      final token = await _service.getAuthToken();
      final response = await http.delete(
        Uri.parse('${_service.apiUrl}/workers/me'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete account: ${response.statusCode} ${response.body}',
        );
      }

      await _service.auth.logout();
      _stopNotificationRefresh();
      _currentUser = null;
      _activeRole = null;
      _resetState();
    } finally {
      _setBusy(false);
    }
  }

  // ================== Getters ==================
  bool get isBusy => _isBusy;
  User? get currentUser => _currentUser;
  UserType? get activeRole => _activeRole;
  bool get hasValidSession => _currentUser != null && _activeRole != null;

  WorkerProfile? get workerProfile => _workerProfile;
  WorkerDashboardMetrics? get workerMetrics => _workerMetrics;
  List<JobPosting> get workerJobs => _workerJobs;
  List<Application> get workerApplications => _workerApplications;
  List<AttendanceRecord> get workerAttendance => _workerAttendance;
  List<Shift> get workerShifts => _workerShifts;
  List<SwapRequest> get swapRequests => _swapRequests;

  List<AppNotification> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  EmployerProfile? get employerProfile => _employerProfile;
  EmployerDashboardMetrics? get employerMetrics => _employerMetrics;
  List<JobPosting> get employerJobs => _employerJobs;
  List<BusinessLocation> get businesses => _businesses;
  List<TeamMember> get teamMembers => _teamMembers;
  BudgetOverview? get budgetOverview => _budgetOverview;
  AnalyticsSummary? get analyticsSummary => _analyticsSummary;
  List<AttendanceRecord> get employerAttendance => _employerAttendance;
  List<Application> get employerApplications => _employerApplications;
  String? get employerApplicationsError => _employerApplicationsError;
  List<Conversation> get conversations => _conversations;
  List<Application> get selectedJobApplications => _selectedJobApplications;
  ServiceLocator get service => _service;
  TeamMember? get currentUserTeamMember => _currentUserTeamMember;

  /// Get applications filtered by status without triggering network requests
  /// Optimized for performance with memoization of common status groups
  List<Application> getApplicationsByStatus(ApplicationStatus? status) {
    if (status == null) return _employerApplications;

    // Use cached results for common status queries
    _statusFilterCache ??= <ApplicationStatus, List<Application>>{};
    return _statusFilterCache!.putIfAbsent(
      status,
      () => _employerApplications.where((app) => app.status == status).toList(),
    );
  }

  /// Get applications filtered by multiple statuses
  List<Application> getApplicationsByStatuses(
      List<ApplicationStatus> statuses) {
    if (statuses.isEmpty) return _employerApplications;
    return _employerApplications
        .where((app) => statuses.contains(app.status))
        .toList();
  }

  /// Get applications that are in an active state (pending or accepted)
  List<Application> get activeApplications => getApplicationsByStatuses([
        ApplicationStatus.pending,
        ApplicationStatus.accepted,
      ]);

  /// Get applications that are in a completed state (hired or completed)
  List<Application> get completedApplications => getApplicationsByStatuses([
        ApplicationStatus.hired,
        ApplicationStatus.completed,
      ]);

  /// Get applications that are in a terminated state (rejected or cancelled)
  List<Application> get terminatedApplications => getApplicationsByStatuses([
        ApplicationStatus.rejected,
        ApplicationStatus.cancelled,
      ]);

  /// Quick access to cached applications with optimized status filtering
  Future<List<Application>> getCachedApplications({
    ApplicationStatus? status,
    List<ApplicationStatus>? statuses,
  }) async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      final cached = await _employerRepo.getApplicationsSWR(user.id);

      if (statuses != null && statuses.isNotEmpty) {
        return cached.where((app) => statuses.contains(app.status)).toList();
      }

      if (status != null) {
        return cached.where((app) => app.status == status).toList();
      }

      return cached;
    } catch (e) {
      if (kDebugMode) print('Failed to get cached applications: $e');
      return _employerApplications;
    }
  }

  /// Clear the status filter cache when applications are updated
  void _clearStatusFilterCache() {
    _statusFilterCache?.clear();
    _statusFilterCache = null;
  }

  /// Prefetch applications for better performance when navigating to application screens
  Future<void> prefetchApplications() async {
    final user = _currentUser;
    if (user == null || _activeRole != UserType.employer) return;

    try {
      // Trigger background refresh without blocking UI
      unawaited(_employerRepo.refreshApplications(user.id));
      if (kDebugMode) {
        print('🚀 Applications prefetched for better performance');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Failed to prefetch applications: $e');
    }
  }

  /// Get application counts by status for dashboard/summary views
  Map<ApplicationStatus, int> getApplicationCounts() {
    final counts = <ApplicationStatus, int>{};
    for (final app in _employerApplications) {
      counts[app.status] = (counts[app.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get total application count for quick display
  int get totalApplicationCount => _employerApplications.length;

  /// Get counts of active applications (pending or accepted)
  int get activeApplicationCount => activeApplications.length;

  /// Get counts of completed applications (hired or completed)
  int get completedApplicationCount => completedApplications.length;

  /// Get counts of terminated applications (rejected or cancelled)
  int get terminatedApplicationCount => terminatedApplications.length;

  /// Check if there are any applications in the given status
  bool hasApplicationsInStatus(ApplicationStatus status) =>
      getApplicationsByStatus(status).isNotEmpty;

  /// Get the most recent application for a specific job
  Application? getLatestApplicationForJob(String jobId) {
    final applications = _employerApplications
        .where((app) => app.jobId == jobId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return applications.isNotEmpty ? applications.first : null;
  }

  /// Update status for multiple applications at once
  Future<void> updateApplicationStatuses({
    required List<String> applicationIds,
    required ApplicationStatus newStatus,
  }) async {
    if (applicationIds.isEmpty) return;

    _setBusy(true);
    try {
      for (final id in applicationIds) {
        await _service.employer.updateEmployerApplicationStatus(
          applicationId: id,
          status: newStatus,
        );
      }

      // Update local state
      _employerApplications = _employerApplications.map((app) {
        if (applicationIds.contains(app.id)) {
          return app.copyWith(status: newStatus);
        }
        return app;
      }).toList();

      _clearStatusFilterCache();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  bool get isLoadingCurrentUserTeamMember => _isLoadingCurrentUserTeamMember;
  List<JobPaymentRecord> get jobPayments => List.unmodifiable(_jobPayments);
  bool get isLoadingJobPayments => _isLoadingJobPayments;
  List<EmployerFeedback> get employerFeedback =>
      List.unmodifiable(_employerFeedback);
  bool get isLoadingEmployerFeedback => _isLoadingEmployerFeedback;
  List<EmploymentRecord> get workerEmploymentHistory =>
      List.unmodifiable(_workerEmploymentHistory);
  bool get isLoadingEmploymentHistory => _isLoadingEmploymentHistory;
  List<EmployerFeedback> get workerFeedback =>
      List.unmodifiable(_workerFeedback);
  bool get isLoadingWorkerFeedback => _isLoadingWorkerFeedback;

  String? _extractObjectId(String? value) {
    if (value == null) return null;
    final match = RegExp(r'[0-9a-fA-F]{24}').firstMatch(value);
    return match?.group(0);
  }

  BusinessAccessInfo? ownershipAccessInfo(String? businessId) {
    final user = _currentUser;
    final id = businessId?.trim();
    if (user == null || id == null || id.isEmpty) return null;

    final owned = _findAssociation(user.ownedBusinesses, id);
    if (owned != null) {
      return BusinessAccessInfo(
        ownerName: 'Owner',
        ownerEmail: _currentUser?.email ?? '',
        businessName: null,
      );
    }

    final team = _findAssociation(user.teamBusinesses, id);
    if (team != null) {
      final email = (team.grantedByEmail?.trim().isNotEmpty == true)
          ? team.grantedByEmail!.trim()
          : (team.ownerEmail?.trim().isNotEmpty == true)
              ? team.ownerEmail!.trim()
              : 'Team Access';
      return BusinessAccessInfo(
        ownerName: email,
        ownerEmail: email,
        businessName: null,
      );
    }

    return null;
  }

  BusinessAccessInfo? jobAccessInfo(JobPosting job) {
    final directLabel = _resolveJobOwnerLabel(job);
    if (directLabel != null) {
      final email = directLabel.toLowerCase() == 'owner'
          ? (_currentUser?.email ?? '')
          : job.createdByEmail?.isNotEmpty == true
              ? job.createdByEmail!
              : job.employerEmail?.isNotEmpty == true
                  ? job.employerEmail!
                  : (_currentUser?.email ?? '');
      return BusinessAccessInfo(
        ownerName: directLabel,
        ownerEmail: email,
        businessName: null,
      );
    }

    final fallback = ownershipAccessInfo(job.businessId);
    if (fallback == null) {
      return null;
    }

    final normalizedLabel =
        _normalizeOwnerLabel(fallback.ownerName, fallback.ownerEmail);
    final normalizedEmail = fallback.ownerEmail.trim().contains('@')
        ? fallback.ownerEmail.trim()
        : (_currentUser?.email ?? fallback.ownerEmail);

    return BusinessAccessInfo(
      ownerName: normalizedLabel,
      ownerEmail: normalizedEmail,
      businessName: fallback.businessName,
    );
  }

  String? _resolveJobOwnerLabel(JobPosting job) {
    final currentEmail = _currentUser?.email.trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      return null;
    }

    final tagCandidates = <String?>[
      job.createdByTag?.trim(),
      job.createdByName?.trim(),
    ];

    for (final candidate in tagCandidates) {
      if (candidate == null || candidate.isEmpty) {
        continue;
      }
      if (candidate.toLowerCase() == 'owner') {
        return 'Owner';
      }
      if (candidate.contains('@')) {
        return candidate;
      }
    }

    final emailCandidates = <String?>[
      job.createdByEmail?.trim(),
      job.employerEmail?.trim(),
    ];

    for (final email in emailCandidates) {
      if (email == null || email.isEmpty) {
        continue;
      }
      if (email.toLowerCase() == currentEmail.toLowerCase()) {
        return 'Owner';
      }
      if (email.contains('@')) {
        return email;
      }
    }

    return null;
  }

  String _normalizeOwnerLabel(String label, String email) {
    final trimmedLabel = label.trim();
    final trimmedEmail = email.trim();
    if (trimmedLabel.isEmpty || trimmedLabel.toLowerCase() == 'owner') {
      return 'Owner';
    }
    if (trimmedLabel.contains('@')) {
      return trimmedLabel;
    }
    if (trimmedEmail.contains('@')) {
      return trimmedEmail;
    }
    return trimmedLabel;
  }

  Future<WorkerProfile?> fetchWorkerProfileSnapshot(String workerId) async {
    final normalized = _extractObjectId(workerId);
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    try {
      return await _service.worker.fetchWorkerProfile(normalized);
    } catch (error, stackTrace) {
      debugPrint('Failed to load worker profile for $normalized: $error');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  // Attendance management getters
  DateTime get attendanceSelectedDate => _attendanceSelectedDate;
  String get attendanceStatusFilter => _attendanceStatusFilter;
  AttendanceDashboard? get attendanceDashboard => _attendanceDashboard;
  AttendanceDashboardSummary? get attendanceSummary => _attendanceSummary;
  bool get isAttendanceBusy => _isAttendanceBusy;
  Map<String, AttendanceSchedule> get workerAttendanceSchedules =>
      _workerAttendanceSchedules;

  // ================== Authentication ==================
  Future<String> login({
    required String email,
    required String password,
    UserType? type,
  }) async {
    _setBusy(true);
    try {
      print('🔄 Starting ultra-fast login process...');
      final (user, message) = await _service.auth.login(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _activeRole = _currentUser?.type;
        _service.updateAuthToken(_service.auth.authToken);
        _service.updateCurrentUser(_currentUser);

        print('✅ Ultra-fast login completed for: ${user.email}');

        // Initialize push notifications after successful login
        unawaited(_initializePushNotifications());

        // Hydrate immediately from cache for instant UI
        unawaited(_hydrateFromCache());

        // Load full business data in background for employers if needed
        if (user.type == UserType.employer) {
          print('🔄 Loading business data in background...');
          unawaited(_loadBusinessDataInBackground());
        }

        // Trigger background refresh without blocking login
        unawaited(_refreshInBackground());

        // Notify listeners immediately for instant UI update
        notifyListeners();
      }

      return message;
    } finally {
      _setBusy(false);
    }
  }

  /// Load full business data in background for better login performance
  /// This loads comprehensive business information while keeping initial login fast
  Future<void> _loadBusinessDataInBackground() async {
    try {
      // Don't set busy state to avoid blocking UI
      print('📊 Fetching business data...');
      final businessData = await _service.auth.loadUserBusinesses();

      if (_currentUser != null) {
        // Update user with business data
        final updatedUser = User(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          type: _currentUser!.type,
          freeJobsPosted: _currentUser!.freeJobsPosted,
          freeApplicationsUsed: _currentUser!.freeApplicationsUsed,
          isPremium: _currentUser!.isPremium,
          selectedBusinessId: _currentUser!.selectedBusinessId,
          roles: _currentUser!.roles,
          ownedBusinesses: businessData['ownedBusinesses'] ?? [],
          teamBusinesses: businessData['teamBusinesses'] ?? [],
        );

        _currentUser = updatedUser;
        _service.updateCurrentUser(_currentUser);

        print('✅ Business data loaded successfully');
        print(
            '📊 Owned businesses: ${businessData['ownedBusinesses']?.length ?? 0}');
        print(
            '📊 Team businesses: ${businessData['teamBusinesses']?.length ?? 0}');

        // Trigger UI update
        notifyListeners();
      }
    } catch (error) {
      print('⚠️ Failed to load business data in background: $error');
      // Don't throw error to prevent disrupting the login flow
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _service.auth.logout();
      _stopNotificationRefresh(); // Stop notification refresh on logout
      _currentUser = null;
      _activeRole = null;
      _resetState();
    } finally {
      _setBusy(false);
    }
  }

  // ================== Messaging ==================
  Future<void> loadNotifications() async {
    final user = _currentUser;
    if (user == null) return;

    String? businessId;
    if (user.type == UserType.employer) {
      businessId = user.selectedBusinessId;

      if ((businessId == null || businessId.isEmpty) &&
          _currentUserTeamMember != null) {
        businessId = _currentUserTeamMember!.businessId;
      }

      if ((businessId == null || businessId.isEmpty) &&
          _businesses.isNotEmpty) {
        businessId = _businesses.first.id;
      }
    }

    try {
      final newNotifications = await _service.messaging.fetchNotifications(
        user.id,
        businessId: businessId,
      );

      // Check for new message notifications
      final messageNotifications = newNotifications
          .where((n) =>
              n.type == NotificationType.message &&
              !_notifications.any((existing) => existing.id == n.id))
          .toList();

      // Trigger pop-up for new message notifications
      for (final messageNotification in messageNotifications) {
        _showMessageNotificationPopup({
          'title': messageNotification.title,
          'body': messageNotification.message,
          'type': 'message',
          'notificationType': 'message',
          'showPopup': true,
          'senderName': messageNotification.data['senderName'],
          'conversationId': messageNotification.data['conversationId'],
          'messageId': messageNotification.data['messageId'],
        });
      }

      _notifications = newNotifications;
    } catch (error) {
      print('Error loading notifications: $error');
    }
    notifyListeners();
  }

  Future<void> loadConversations() async {
    if (_currentUser == null) return;
    _conversations =
        await _service.messaging.fetchConversations(_currentUser!.id);
    notifyListeners();
  }

  /// Mark specific notifications as read
  Future<void> markNotificationsAsRead({List<String>? notificationIds}) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _service.messaging.markNotificationsAsRead(
        userId: user.id,
        notificationIds: notificationIds,
      );

      // Update local state - mark as read
      if (notificationIds != null && notificationIds.isNotEmpty) {
        _notifications = _notifications.map((notification) {
          if (notificationIds.contains(notification.id)) {
            return AppNotification(
              id: notification.id,
              userId: notification.userId,
              type: notification.type,
              priority: notification.priority,
              title: notification.title,
              message: notification.message,
              createdAt: notification.createdAt,
              actionUrl: notification.actionUrl,
              isRead: true,
              data: notification.data,
            );
          }
          return notification;
        }).toList();
      } else {
        // Mark all as read
        _notifications = _notifications.map((notification) {
          return AppNotification(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            priority: notification.priority,
            title: notification.title,
            message: notification.message,
            createdAt: notification.createdAt,
            actionUrl: notification.actionUrl,
            isRead: true,
            data: notification.data,
          );
        }).toList();
      }

      notifyListeners();
    } catch (error) {
      print('Error marking notifications as read: $error');
    }
  }

  /// Get count of unread notifications
  int get unreadNotificationCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  /// Mark messages in a conversation as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _service.messaging.markMessagesAsRead(
        conversationId: conversationId,
        userId: user.id,
      );

      // Update local conversation state to reset unread count
      _conversations = _conversations.map((conversation) {
        if (conversation.id == conversationId) {
          return Conversation(
            id: conversation.id,
            participantIds: conversation.participantIds,
            jobId: conversation.jobId,
            title: conversation.title,
            lastMessagePreview: conversation.lastMessagePreview,
            unreadCount: 0, // Reset unread count
            updatedAt: conversation.updatedAt,
          );
        }
        return conversation;
      }).toList();

      notifyListeners();
    } catch (error) {
      print('Error marking messages as read: $error');
    }
  }

  // ================== Push Notifications ==================
  Future<void> _initializePushNotifications() async {
    try {
      print('🔄 Initializing push notifications...');

      // Add timeout to prevent hanging during initialization
      await PushNotificationService.instance
          .initialize(
        baseUrl: _service.apiUrl,
        authToken: _service.auth.authToken,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Push notification initialization timed out');
          throw TimeoutException('Push notification initialization timed out',
              const Duration(seconds: 30));
        },
      );

      // Set up notification callbacks
      PushNotificationService.instance.onNotificationReceived =
          _handleNotificationReceived;
      PushNotificationService.instance.onNotificationTap =
          _handleNotificationTap;

      print('✅ Push notifications initialized successfully');
    } on TimeoutException catch (e) {
      print('⏰ Push notification initialization timed out: $e');
      // Continue app initialization even if push notifications fail
    } catch (e) {
      print('❌ Failed to initialize push notifications: $e');
      // Continue app initialization even if push notifications fail
    }
  }

  void _handleNotificationReceived(Map<String, dynamic> data) {
    print('📨 Notification received: $data');

    // Refresh notifications to show the new one
    loadNotifications();

    // Handle message notifications specifically with pop-ups
    final type = data['type'] as String? ?? data['notificationType'] as String?;
    if (type == 'message' && data['showPopup'] == true) {
      _showMessageNotificationPopup(data);
    }

    // Show a brief indication that a notification was received
    notifyListeners();
  }

  void _showMessageNotificationPopup(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'New Message';
    final body = data['body'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? 'Someone';

    // Store the notification for showing when context is available
    _pendingMessageNotification = {
      'title': title,
      'body': body,
      'senderName': senderName,
      'conversationId': data['conversationId'],
      'messageId': data['messageId'],
    };

    notifyListeners(); // This will trigger UI updates that can show the popup
  }

  Map<String, dynamic>? _pendingMessageNotification;
  Map<String, dynamic>? get pendingMessageNotification =>
      _pendingMessageNotification;

  void clearPendingMessageNotification() {
    _pendingMessageNotification = null;
    notifyListeners();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('👆 Notification tapped: $data');

    // Handle different notification types
    final type = data['type'] as String?;
    switch (type) {
      case 'attendance':
        // Navigate to attendance screen
        break;
      case 'team_invite':
      case 'team_update':
        // Navigate to team management screen
        break;
      case 'application':
        // Navigate to applications screen
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await PushNotificationService.instance.showTestNotification();
    } catch (e) {
      print('❌ Failed to send test notification: $e');
    }
  }

  Future<void> switchRole(UserType newRole) async {
    if (_currentUser == null || newRole == _activeRole) return;
    _activeRole = newRole;
    notifyListeners();
  }

  // ================== Authentication ==================
  Future<void> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required UserType type,
    String? phone,
  }) async {
    _setBusy(true);
    try {
      _currentUser = await _service.auth.signup(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        userType: type,
      );
      _activeRole = _currentUser?.type;
      _service.updateAuthToken(_service.auth.authToken);
      _service.updateCurrentUser(_currentUser);

      await refreshActiveRole();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _loadWorkerDashboardData() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final workerId = user.id;
    final resolvedWorkerId = _extractObjectId(workerId) ?? workerId;
    // Load critical worker data in order so the UI can update quickly.
    try {
      _workerJobs = await _service.worker.fetchWorkerJobs(workerId);
      debugPrint(
          '✅ Loaded ${_workerJobs.length} worker jobs during refreshActiveRole');
    } catch (error, stackTrace) {
      debugPrint('❌ Error loading worker jobs in refreshActiveRole: $error');
      debugPrint(stackTrace.toString());
      _workerJobs = [];
    }

    notifyListeners();

    try {
      _workerApplications =
          await _service.worker.fetchWorkerApplications(workerId);
    } catch (error, stackTrace) {
      debugPrint(
          '❌ Error loading worker applications in refreshActiveRole: $error');
      debugPrint(stackTrace.toString());
      _workerApplications = [];
    }

    notifyListeners();

    // Load the rest of the worker dashboard data in the background so it
    // doesn't block the UI. Each background task updates state when done.
    final backgroundTasks = <Future<void>>[
      () async {
        try {
          _workerMetrics =
              await _service.worker.fetchWorkerDashboardMetrics('me');
        } catch (error, stackTrace) {
          debugPrint('Error fetching worker dashboard metrics: $error');
          debugPrint(stackTrace.toString());
        } finally {
          notifyListeners();
        }
      }(),
      () async {
        try {
          _workerAttendance =
              await _service.worker.fetchWorkerAttendance(resolvedWorkerId);
        } catch (error, stackTrace) {
          debugPrint(
              '❌ Error loading worker attendance records in refreshActiveRole: $error');
          debugPrint(stackTrace.toString());
        } finally {
          notifyListeners();
        }
      }(),
      () async {
        final wasLoading = _isLoadingEmploymentHistory;
        if (!wasLoading) {
          _isLoadingEmploymentHistory = true;
        }
        try {
          _workerEmploymentHistory =
              await _service.worker.fetchEmploymentHistory('me');
        } catch (error, stackTrace) {
          debugPrint('Error loading employment history: $error');
          debugPrint(stackTrace.toString());
        } finally {
          if (!wasLoading) {
            _isLoadingEmploymentHistory = false;
          }
          notifyListeners();
        }
      }(),
      () async {
        final wasLoading = _isLoadingWorkerFeedback;
        if (!wasLoading) {
          _isLoadingWorkerFeedback = true;
        }
        try {
          _workerFeedback = await _service.worker.fetchWorkerFeedback('me');
        } catch (error, stackTrace) {
          debugPrint('Error loading worker feedback: $error');
          debugPrint(stackTrace.toString());
        } finally {
          if (!wasLoading) {
            _isLoadingWorkerFeedback = false;
          }
          notifyListeners();
        }
      }(),
    ];

    unawaited(Future.wait(backgroundTasks));

    _workerProfile ??= WorkerProfile(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: '',
      emailNotificationsEnabled: true,
      skills: const ['Customer Service', 'Food Service'],
      experience: '2 years',
      bio: 'Experienced worker ready for new opportunities',
      rating: 4.5,
      completedJobs: 15,
      totalEarnings: 2500.0,
      languages: const ['English', 'Spanish'],
      availability: const [],
      isVerified: false,
      weeklyEarnings: 350.0,
      preferredRadiusMiles: 10.0,
      notificationsEnabled: true,
    );

    _workerMetrics ??= const WorkerDashboardMetrics(
      availableJobs: 8,
      activeApplications: 2,
      upcomingShifts: 3,
      completedHours: 120,
      earningsThisWeek: 450.0,
      freeApplicationsRemaining: 2,
      isPremium: false,
    );
  }

  Future<void> _loadEmployerDashboardData() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final userId = user.id;

    // Use cache-first approach for faster loading
    final futures = <Future<void>>[
      () async {
        try {
          // Use cached data from repository
          _businesses = await _employerRepo.getBusinessesSWR();
        } catch (error) {
          debugPrint('Error fetching businesses: $error');
        }
      }(),
      () async {
        try {
          // Use cached data from repository
          _employerJobs = await _employerRepo.getJobsSWR(userId);
        } catch (error) {
          debugPrint('Error fetching employer jobs: $error');
        }
      }(),
      () async {
        try {
          // Use cached data from repository for applications
          _employerApplications =
              await _employerRepo.getApplicationsSWR(userId);
        } catch (error) {
          debugPrint('Error fetching employer applications: $error');
        }
      }(),
      // Load profile and metrics in background (less critical for initial UI)
      () async {
        try {
          _employerProfile =
              await _service.employer.fetchEmployerProfile(userId);
        } catch (error) {
          debugPrint('Error fetching employer profile: $error');
        }
      }(),
      () async {
        try {
          final metrics =
              await _service.employer.fetchEmployerDashboardMetrics(userId);
          _employerMetrics = metrics as EmployerDashboardMetrics?;
        } catch (error) {
          debugPrint('Error fetching employer metrics: $error');
        }
      }(),
    ];

    // Wait for cache-based data first (fast)
    await Future.wait(futures.take(3));

    // Load remaining data in background
    unawaited(Future.wait(futures.skip(3)));

    _employerProfile ??= EmployerProfile(
      id: user.id,
      companyName: '${user.firstName} ${user.lastName}',
      description: 'Welcome to your employer dashboard!',
      phone: '(555) 123-4567',
      rating: 4.8,
      totalJobsPosted: 5,
      totalHires: 10,
      activeBusinesses: 1,
    );

    _employerMetrics ??= EmployerDashboardMetrics(
      openJobs: 3,
      totalApplicants: 15,
      totalHires: 8,
      averageResponseTimeHours: 2.5,
      freePostingsRemaining: 2,
      premiumActive: false,
      recentJobSummaries: [
        JobSummary(
          jobId: 'job_1',
          title: 'Frontend Developer',
          status: 'Active',
          applicants: 5,
          hires: 2,
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        JobSummary(
          jobId: 'job_2',
          title: 'UI/UX Designer',
          status: 'Active',
          applicants: 8,
          hires: 3,
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    if (_businesses.isEmpty) {
      _businesses = [
        const BusinessLocation(
          id: 'business_1',
          name: 'Headquarters',
          description: 'Main office location',
          address: '123 Main Street',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94105',
          phone: '(415) 555-1234',
        ),
      ];
    }
  }

  // ================== Cache Hydration Methods ==================

  Future<void> _hydrateFromCache() async {
    final user = _currentUser;
    if (user == null || _activeRole == null) return;

    if (kDebugMode) print('🚀 Hydrating UI from cache...');

    try {
      if (_activeRole == UserType.worker) {
        // Worker hydration - prioritize jobs and applications
        final criticalFutures = await Future.wait([
          _workerRepo.getJobsSWR(user.id),
          _workerRepo.getApplicationsSWR(user.id),
        ]);

        _workerJobs = criticalFutures[0] as List<JobPosting>;
        _workerApplications = criticalFutures[1] as List<Application>;

        // Notify early for faster UI updates
        notifyListeners();

        // Load remaining data in background
        unawaited(Future.wait([
          _workerRepo.getAttendanceSWR(user.id),
          _workerRepo.getProfileSWR(user.id),
          _workerRepo.getMetricsSWR(user.id),
        ]).then((remainingFutures) {
          _workerAttendance = remainingFutures[0] as List<AttendanceRecord>;
          _workerProfile = remainingFutures[1] as WorkerProfile?;
          _workerMetrics = remainingFutures[2] as WorkerDashboardMetrics?;
          notifyListeners();
        }));

        if (kDebugMode) {
          print(
              '✅ Worker critical cache hydrated: ${_workerJobs.length} jobs, ${_workerApplications.length} applications');
        }
      } else if (_activeRole == UserType.employer) {
        // Employer hydration - run in parallel to avoid blocking
        final futures = await Future.wait([
          _employerRepo.getBusinessesSWR(),
          _employerRepo.getJobsSWR(user.id),
          _employerRepo.getApplicationsSWR(user.id),
        ]);

        _businesses = futures[0] as List<BusinessLocation>;
        _employerJobs = futures[1] as List<JobPosting>;
        _employerApplications = futures[2] as List<Application>;

        if (kDebugMode) {
          print(
              '✅ Employer cache hydrated: ${_businesses.length} businesses, ${_employerJobs.length} jobs');
        }
      }
    } catch (error) {
      if (kDebugMode) print('⚠️ Cache hydration error (non-critical): $error');
      // Don't throw - cache errors shouldn't block the UI
    }

    // notifications can also be cached (optional)
  }

  Future<void> _refreshInBackground() async {
    final user = _currentUser;
    if (user == null || _activeRole == null) return;

    if (kDebugMode) print('🔄 Refreshing data in background...');

    try {
      if (_activeRole == UserType.worker) {
        // Phase 1: Load critical data first for faster UI
        await Future.wait([
          _workerRepo.refreshJobs(user.id),
          _workerRepo.refreshApplications(user.id),
        ]);

        // Pull critical data into memory immediately
        _workerJobs = await _workerRepo.getJobsSWR(user.id);
        _workerApplications = await _workerRepo.getApplicationsSWR(user.id);

        // Notify listeners early for faster UI updates
        notifyListeners();

        // Phase 2: Load remaining data in background
        unawaited(Future.wait([
          _workerRepo.refreshAttendance(user.id),
          _workerRepo.refreshProfile(user.id),
          _workerRepo.refreshMetrics(user.id),
        ]).then((_) async {
          _workerAttendance = await _workerRepo.getAttendanceSWR(user.id);
          _workerProfile = await _workerRepo.getProfileSWR(user.id);
          _workerMetrics = await _workerRepo.getMetricsSWR(user.id);
          notifyListeners();
        }));

        if (kDebugMode) {
          print(
              '✅ Worker priority refresh completed: ${_workerJobs.length} jobs, ${_workerApplications.length} applications');
        }
      } else if (_activeRole == UserType.employer) {
        await Future.wait([
          _employerRepo.refreshBusinesses(),
          _employerRepo.refreshJobs(user.id),
          _employerRepo.refreshApplications(user.id),
        ]);

        _businesses = await _employerRepo.getBusinessesSWR();
        _employerJobs = await _employerRepo.getJobsSWR(user.id);
        _employerApplications = await _employerRepo.getApplicationsSWR(user.id);

        if (kDebugMode) print('✅ Employer background refresh completed');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Background refresh failed: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Fast initialization for instant UI updates after login
  Future<void> fastInit() async {
    if (_currentUser == null || _activeRole == null) return;

    // Hydrate from cache immediately
    await _hydrateFromCache();
    notifyListeners();

    // Start background data refresh without blocking
    unawaited(_refreshInBackground());

    // Start notification service
    _startNotificationRefresh();
  }

  // ================== Public ==================

  /// Ultra-fast dashboard load - cache first, minimal API calls
  Future<void> quickDashboardLoad() async {
    if (_currentUser == null || _activeRole == null) return;

    try {
      // Try cache hydration with very short timeout
      await _hydrateFromCache().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          if (kDebugMode) print('⚠️ Quick dashboard cache timed out');
        },
      );
      notifyListeners();

      // Only load essential data if we have nothing
      if (_activeRole == UserType.worker &&
          (_workerProfile == null || _workerJobs.isEmpty)) {
        // Just get the absolute minimum for dashboard
        unawaited(_loadMinimalWorkerData());
      }
    } catch (error) {
      if (kDebugMode) print('⚠️ Quick dashboard load error: $error');
    }
  }

  Future<void> _loadMinimalWorkerData() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      // Load only profile and metrics for dashboard - skip heavy jobs/applications
      final futures = [
        () async {
          _workerProfile ??= await _service.worker.fetchWorkerProfile('me');
        }(),
        () async {
          _workerMetrics ??=
              await _service.worker.fetchWorkerDashboardMetrics('me');
        }(),
      ];

      await Future.wait(futures);
      notifyListeners();

      // Load everything else in background
      unawaited(_refreshInBackground());
    } catch (error) {
      if (kDebugMode) print('⚠️ Minimal worker data load error: $error');
    }
  }

  /// Lightweight refresh that prioritizes cache for instant UI
  /// Get all applications for a specific job
  List<Application> getApplicationsForJob(String jobId) {
    return _employerApplications.where((app) => app.jobId == jobId).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  /// Get applications grouped by status
  Map<ApplicationStatus, List<Application>> getApplicationsGroupedByStatus() {
    final grouped = <ApplicationStatus, List<Application>>{};
    for (final status in ApplicationStatus.values) {
      grouped[status] = getApplicationsByStatus(status);
    }
    return grouped;
  }

  /// Get application statistics for a specific job
  Map<String, dynamic> getJobApplicationStats(String jobId) {
    final jobApplications = getApplicationsForJob(jobId);
    return {
      'total': jobApplications.length,
      'pending': jobApplications.where((app) => app.isPending).length,
      'accepted': jobApplications.where((app) => app.isAccepted).length,
      'hired': jobApplications.where((app) => app.isHired).length,
      'rejected': jobApplications.where((app) => app.isRejected).length,
      'cancelled': jobApplications.where((app) => app.isCancelled).length,
      'completed': jobApplications.where((app) => app.isCompleted).length,
      'withdrawn': jobApplications.where((app) => app.isWithdrawn).length,
    };
  }

  Future<void> lightRefreshActiveRole() async {
    if (_currentUser == null || _activeRole == null) return;

    try {
      // Always try cache first for instant display with timeout
      await _hydrateFromCache().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) print('⚠️ Cache hydration timed out, continuing...');
        },
      );
      notifyListeners();

      // Only do full refresh if we don't have basic data
      final hasBasicData = _activeRole == UserType.worker
          ? (_workerProfile != null && _workerJobs.isNotEmpty)
          : (_employerProfile != null && _employerJobs.isNotEmpty);

      if (!hasBasicData) {
        // Do minimal refresh in background without setting busy state
        unawaited(_refreshInBackground());
      }
    } catch (error) {
      if (kDebugMode) print('⚠️ Light refresh error: $error');
      // Don't throw - errors shouldn't block the UI
    }
  }

  Future<void> refreshActiveRole() async {
    if (_currentUser == null || _activeRole == null) return;

    // Use cache hydration for instant UI update
    await _hydrateFromCache();
    notifyListeners();

    // Set busy only for initial load if no cached data
    final hasData =
        (_activeRole == UserType.worker && _workerJobs.isNotEmpty) ||
            (_activeRole == UserType.employer && _employerJobs.isNotEmpty);

    if (!hasData) {
      _setBusy(true);
    }

    try {
      if (_activeRole == UserType.worker) {
        if (!hasData) {
          await _loadWorkerDashboardData();
        } else {
          // Load in background if we have cached data
          unawaited(_loadWorkerDashboardData());
        }
      } else if (_activeRole == UserType.employer) {
        if (!hasData) {
          await _loadEmployerDashboardData();
          await loadCurrentUserTeamMemberInfo(forceRefresh: true);
        } else {
          // Load in background if we have cached data
          unawaited(Future.wait([
            _loadEmployerDashboardData(),
            loadCurrentUserTeamMemberInfo(forceRefresh: true),
          ]));
        }
      }

      // Always load notifications and conversations in background
      unawaited(Future.wait([
        loadNotifications().catchError((error, stackTrace) {
          debugPrint('Error loading notifications during refresh: $error');
          debugPrint(stackTrace.toString());
          return null;
        }),
        loadConversations().catchError((error, stackTrace) {
          debugPrint('Error loading conversations during refresh: $error');
          debugPrint(stackTrace.toString());
          return null;
        }),
      ]));

      _startNotificationRefresh();
    } finally {
      if (!hasData) {
        _setBusy(false);
      }
    }
  }

  Future<void> loadWorkerAttendanceRecords({String? workerId}) async {
    final resolvedId =
        _extractObjectId(workerId ?? _currentUser?.id) ?? (workerId ?? 'me');
    if (resolvedId.isEmpty) {
      debugPrint('⚠️ loadWorkerAttendanceRecords skipped: no worker id');
      return;
    }

    try {
      final records = await _service.worker.fetchWorkerAttendance(resolvedId);
      _workerAttendance = records;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Error loading worker attendance records: $error');
      debugPrint(stackTrace.toString());
    }
  }

  void _upsertWorkerAttendanceRecord(AttendanceRecord record) {
    final index = _workerAttendance.indexWhere((item) => item.id == record.id);
    if (index >= 0) {
      _workerAttendance[index] = record;
    } else {
      _workerAttendance = [..._workerAttendance, record];
    }
    notifyListeners();
  }

  /// Start periodic notification refresh - more frequent for workers
  void _startNotificationRefresh() {
    _stopNotificationRefresh(); // Stop any existing timer

    // Prefer push (PushNotificationService) when available.
    // If falling back to polling: 60–120s with jitter to reduce server & battery.
    final base = _currentUser?.type == UserType.worker ? 60 : 120;
    final jitter = DateTime.now().millisecond % 15; // 0-14
    final interval = Duration(seconds: base + jitter);

    _notificationRefreshTimer = Timer.periodic(
      interval,
      (timer) {
        if (_currentUser != null) {
          loadNotifications();
        } else {
          _stopNotificationRefresh();
        }
      },
    );

    if (kDebugMode) {
      print(
          '🔔 Notification refresh started with ${interval.inSeconds}s interval for ${_currentUser?.type}');
    }
  }

  /// Force immediate notification refresh for all connected clients
  Future<void> _forceNotificationRefresh() async {
    try {
      print('🔄 Forcing immediate notification refresh...');
      await loadNotifications();
      print('✅ Notification refresh completed');
    } catch (error) {
      print('❌ Error during forced notification refresh: $error');
    }
  }

  /// Stop notification refresh timer
  void _stopNotificationRefresh() {
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = null;
  }

  @override
  void dispose() {
    _stopNotificationRefresh();
    try {
      _razorpay.clear();
    } catch (_) {
      // Ignore dispose errors
    }
    _clearPendingPayment();
    super.dispose();
  }

  void forceRefresh() => notifyListeners();

  Future<void> loadCurrentUserTeamMemberInfo(
      {bool forceRefresh = false}) async {
    final user = _currentUser;
    if (user == null) {
      _currentUserTeamMember = null;
      notifyListeners();
      return;
    }

    final selectedId = user.selectedBusinessId;
    final fallbackBusinessId =
        _businesses.isNotEmpty ? _businesses.first.id : null;
    final businessId = (selectedId != null && selectedId.isNotEmpty)
        ? selectedId
        : fallbackBusinessId;

    if (businessId == null || businessId.isEmpty) {
      print('AppState: No businessId available for team member lookup');
      return;
    }

    if (_isLoadingCurrentUserTeamMember) {
      return;
    }

    _isLoadingCurrentUserTeamMember = true;
    notifyListeners();

    try {
      // Simply load team member info without permissions
      // Permission checks are being removed per user request
      _currentUserTeamMember = null; // Simplified for now
    } catch (error) {
      print('AppState: Error loading team member info: $error');
    } finally {
      _isLoadingCurrentUserTeamMember = false;
      notifyListeners();
    }
  }

  // ================== Employer Methods ==================
  Future<void> selectJob(String jobId) async {
    _setBusy(true);
    try {
      // Simulate fetching job applications
      _selectedJobApplications.clear();
      // In a real implementation you would do something like:
      // final applications = await _service.job.fetchJobApplications(jobId);
      // _selectedJobApplications.addAll(applications);
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> addBusiness({
    required String name,
    required String description,
    required String address,
    required String city,
    required String state,
    required String postalCode,
    required String phone,
    String? email,
    String? website,
    String? logoUrl,
    // Google Places API location data
    double? latitude,
    double? longitude,
    String? placeId,
    String? formattedAddress,
    double? allowedRadius,
    String? locationName,
    String? locationNotes,
  }) async {
    _setBusy(true);
    try {
      final normalizedLogoUrl =
          (logoUrl == null || logoUrl.trim().isEmpty) ? null : logoUrl.trim();
      final optimizedLogoUrl =
          ImageOptimizationService.optimizeDataUrl(normalizedLogoUrl);

      final business = await _service.business.createBusiness(
        name: name,
        description: description,
        street: address,
        city: city,
        state: state,
        postalCode: postalCode,
        phone: phone,
        logoUrl: optimizedLogoUrl,
        // Pass Google Places API location data
        latitude: latitude,
        longitude: longitude,
        placeId: placeId,
        formattedAddress: formattedAddress,
        allowedRadius: allowedRadius,
        locationName: locationName,
        locationNotes: locationNotes,
      );

      _businesses = [..._businesses, business];
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateBusiness(
    String businessId, {
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    bool? isActive,
    String? logoUrl,
    double? allowedRadius,
  }) async {
    _setBusy(true);
    try {
      final normalizedLogoUrl =
          (logoUrl == null || logoUrl.trim().isEmpty) ? null : logoUrl.trim();
      final optimizedLogoUrl =
          ImageOptimizationService.optimizeDataUrl(normalizedLogoUrl);

      await _service.business.updateBusiness(
        businessId,
        name: name,
        description: description,
        street: address,
        city: city,
        state: state,
        postalCode: postalCode,
        phone: phone,
        isActive: isActive,
        logoUrl: optimizedLogoUrl,
        allowedRadius: allowedRadius,
      );

      // update local cache
      final index = _businesses.indexWhere((b) => b.id == businessId);
      if (index != -1) {
        final current = _businesses[index];
        final updated = BusinessLocation(
          id: current.id,
          name: name ?? current.name,
          description: description ?? current.description,
          address: address ?? current.address,
          city: city ?? current.city,
          state: state ?? current.state,
          postalCode: postalCode ?? current.postalCode,
          phone: phone ?? current.phone,
          isActive: isActive ?? current.isActive,
          logoUrl: optimizedLogoUrl ?? current.logoUrl,
          type: current.type,
          jobCount: current.jobCount,
          hireCount: current.hireCount,
          latitude: current.latitude,
          longitude: current.longitude,
          allowedRadius: allowedRadius ?? current.allowedRadius,
          timezone: current.timezone,
          notes: current.notes,
        );
        _businesses[index] = updated;
      }

      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  // inside AppState
  Future<void> deleteBusiness(String businessId) async {
    await _service.business.deleteBusiness(businessId);

    // remove from local state after successful delete
    _businesses.removeWhere((b) => b.id == businessId);
    notifyListeners();
  }

  Future<JobPosting> createEmployerJob({
    required String title,
    required String description,
    required double hourlyRate,
    required BusinessLocation business,
    required DateTime start,
    required DateTime end,
    List<String>? tags,
    String? urgency,
    bool? verificationRequired,
    bool? hasOvertime,
    double? overtimeRate,
    String? recurrence,
    List<String>? workDays,
  }) async {
    _setBusy(true);
    try {
      debugPrint(
          '📡 AppState: creating job via API for business ${business.id}');
      debugPrint('🏠 AppState DEBUG: business.address: "${business.address}"');

      final location = <String, dynamic>{
        if (business.address.isNotEmpty) 'line1': business.address,
        if (business.name.isNotEmpty) 'name': business.name,
        if (business.address.isNotEmpty) 'address': business.address,
        if (business.city.isNotEmpty) 'city': business.city,
        if (business.state.isNotEmpty) 'state': business.state,
        if (business.postalCode.isNotEmpty) 'postalCode': business.postalCode,
        if (business.description.isNotEmpty) 'notes': business.description,
        if (business.latitude != null) 'latitude': business.latitude,
        if (business.longitude != null) 'longitude': business.longitude,
        if (business.allowedRadius != null)
          'allowedRadius': business.allowedRadius,
        if (business.timezone != null && business.timezone!.isNotEmpty)
          'timezone': business.timezone,
      };

      debugPrint('🏠 AppState DEBUG: Final location object: $location');

      final job = await _service.job.createJob(
        title: title,
        description: description,
        hourlyRate: hourlyRate,
        businessId: business.id,
        start: start,
        end: end,
        tags: tags,
        urgency: urgency ?? 'medium',
        verificationRequired: verificationRequired ?? false,
        location: location.isEmpty ? null : location,
        overtime: JobOvertime(
          allowed: hasOvertime ?? false,
          rateMultiplier: (overtimeRate ?? 1.5) / 100.0,
        ),
        recurrence: recurrence ?? 'one-time',
        workDays: workDays,
      );

      _employerJobs = [..._employerJobs, job];

      if (_currentUser != null &&
          !_currentUser!.isPremium &&
          !job.premiumRequired) {
        final updatedUser = User(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          type: _currentUser!.type,
          freeJobsPosted: _currentUser!.freeJobsPosted + 1,
          freeApplicationsUsed: _currentUser!.freeApplicationsUsed,
          isPremium: _currentUser!.isPremium,
          selectedBusinessId: _currentUser!.selectedBusinessId,
          roles: _currentUser!.roles,
          ownedBusinesses: _currentUser!.ownedBusinesses,
          teamBusinesses: _currentUser!.teamBusinesses,
        );
        _currentUser = updatedUser;
        _service.updateCurrentUser(_currentUser);
      }

      notifyListeners();
      return job;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> loadJobPaymentHistory({bool forceRefresh = false}) async {
    if (_isLoadingJobPayments) {
      return;
    }
    if (!forceRefresh && _jobPayments.isNotEmpty) {
      return;
    }

    _isLoadingJobPayments = true;
    notifyListeners();
    try {
      final records =
          await _service.employer.fetchJobPaymentHistory(limit: 100);
      _jobPayments = records;
    } catch (error, stackTrace) {
      debugPrint('Error loading job payment history: $error');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoadingJobPayments = false;
      notifyListeners();
    }
  }

  Future<void> loadEmployerFeedback({bool forceRefresh = false}) async {
    if (_activeRole != UserType.employer) {
      return;
    }
    if (_isLoadingEmployerFeedback) {
      return;
    }
    if (!forceRefresh && _employerFeedback.isNotEmpty) {
      return;
    }

    _isLoadingEmployerFeedback = true;
    notifyListeners();
    try {
      final feedback =
          await _service.employer.fetchEmployerFeedback(limit: 100);
      _employerFeedback = feedback;
    } catch (error, stackTrace) {
      debugPrint('Error loading employer feedback: $error');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoadingEmployerFeedback = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkerEmploymentHistory({bool forceRefresh = false}) async {
    if (_activeRole != UserType.worker) {
      return;
    }
    if (_isLoadingEmploymentHistory) {
      return;
    }
    if (!forceRefresh && _workerEmploymentHistory.isNotEmpty) {
      return;
    }

    _isLoadingEmploymentHistory = true;
    notifyListeners();
    try {
      final history = await _service.worker.fetchEmploymentHistory('me');
      _workerEmploymentHistory = history;
    } catch (error, stackTrace) {
      debugPrint('Error loading employment history: $error');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoadingEmploymentHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkerFeedback({bool forceRefresh = false}) async {
    if (_activeRole != UserType.worker) {
      return;
    }
    if (_isLoadingWorkerFeedback) {
      return;
    }
    if (!forceRefresh && _workerFeedback.isNotEmpty) {
      return;
    }

    _isLoadingWorkerFeedback = true;
    notifyListeners();
    try {
      final feedback = await _service.worker.fetchWorkerFeedback('me');
      _workerFeedback = feedback;
    } catch (error, stackTrace) {
      debugPrint('Error loading worker feedback: $error');
      debugPrint(stackTrace.toString());
    } finally {
      _isLoadingWorkerFeedback = false;
      notifyListeners();
    }
  }

  Future<EmployerFeedback?> submitEmployerFeedback({
    required String employerId,
    required int rating,
    String? comment,
    String? jobId,
  }) async {
    if (_activeRole != UserType.worker) {
      throw Exception('Only workers can submit feedback');
    }

    try {
      final feedback = await _service.worker.submitEmployerFeedback(
        workerId: 'me',
        employerId: employerId,
        rating: rating,
        comment: comment,
        jobId: jobId,
      );

      final index = _workerFeedback.indexWhere((item) =>
          item.employerId == feedback.employerId &&
          item.jobId == feedback.jobId);

      if (index >= 0) {
        _workerFeedback[index] = feedback;
      } else {
        _workerFeedback = [feedback, ..._workerFeedback];
      }

      notifyListeners();

      // If the worker is viewing an employer profile for the same employer,
      // refresh cached employer feedback so the new review appears immediately.
      if (_employerFeedback.any((item) =>
          item.employerId == feedback.employerId &&
          item.workerId == feedback.workerId)) {
        await loadEmployerFeedback(forceRefresh: true);
      }

      return feedback;
    } catch (error, stackTrace) {
      debugPrint('Error submitting employer feedback: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    _setBusy(true);
    try {
      print('🔄 Updating job status via API: $jobId to $status');

      await _service.job.updateJobStatus(
        jobId: jobId,
        status: status,
      );

      print('✓ Job status updated successfully');

      // Update the job status in the local list
      final index = _employerJobs.indexWhere((job) => job.id == jobId);
      if (index != -1) {
        final job = _employerJobs[index];
        _employerJobs[index] = JobPosting(
          id: job.id,
          title: job.title,
          description: job.description,
          employerId: job.employerId,
          businessId: job.businessId,
          hourlyRate: job.hourlyRate,
          scheduleStart: job.scheduleStart,
          scheduleEnd: job.scheduleEnd,
          recurrence: job.recurrence,
          overtime: job.overtime,
          urgency: job.urgency,
          tags: job.tags,
          workDays: job.workDays,
          isVerificationRequired: job.isVerificationRequired,
          status: status,
          postedAt: job.postedAt,
          isPublished: job.isPublished,
          publishStatus: job.publishStatus,
          publishActionRequired: job.publishActionRequired,
          distanceMiles: job.distanceMiles,
          hasApplied: job.hasApplied,
          premiumRequired: job.premiumRequired,
          locationSummary: job.locationSummary,
          location: job.location,
          applicantsCount: job.applicantsCount,
          businessName: job.businessName,
          businessAddress: job.businessAddress,
          employerName: job.employerName,
          employerEmail: job.employerEmail,
          businessLogoSmall: job.businessLogoSmall,
          businessLogoMedium: job.businessLogoMedium,
          employerAvatarSmall: job.employerAvatarSmall,
          employerAvatarMedium: job.employerAvatarMedium,
          metrics: job.metrics,
        );
      }

      notifyListeners();
    } catch (error) {
      print('❌ Error updating job status: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  void _ensureRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final pending = _pendingJobPayment;
    final completer = _paymentCompleter;
    if (pending == null || completer == null) {
      debugPrint('⚠️ Received Razorpay success without a pending payment.');
      return;
    }

    final orderId = (response.orderId?.trim().isNotEmpty ?? false)
        ? response.orderId!.trim()
        : pending.orderId;
    if (orderId.isEmpty) {
      final error = Exception('Missing Razorpay order information.');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      _clearPendingPayment();
      return;
    }

    final paymentId =
        response.paymentId ?? pending.paymentMethodHint ?? 'razorpay';
    final signature = response.signature?.trim();
    if (signature == null || signature.isEmpty) {
      final error = Exception('Missing Razorpay payment signature.');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      _clearPendingPayment();
      return;
    }

    final verifyFuture = verifyJobPostingPayment(
      jobId: pending.jobId,
      amount: pending.amount,
      currency: pending.currency,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      publishAfterPayment: true,
    );

    verifyFuture.then((_) {
      _markJobPaymentComplete(pending.jobId);
      _promoteCurrentUserToPremium();
      notifyListeners();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).catchError(
      (Object error, StackTrace stackTrace) {
        debugPrint('❌ Failed to record Razorpay payment: $error');
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    ).whenComplete(_clearPendingPayment);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final completer = _paymentCompleter;
    final rawMessage = response.message;
    final parsedMessage = (rawMessage == null || rawMessage.trim().isEmpty)
        ? 'Payment cancelled'
        : rawMessage.trim();

    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        Exception('Payment failed (${response.code}): $parsedMessage'),
      );
    }
    _clearPendingPayment();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('ℹ️ External wallet selected: ${response.walletName}');
  }

  void _clearPendingPayment() {
    _paymentCompleter = null;
    _pendingJobPayment = null;
  }

  Future<void> processJobPostingPayment({
    required String jobId,
    required double amount,
    String? currency,
    String? paymentMethodId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (_paymentCompleter != null) {
      throw StateError('Another payment is already in progress.');
    }

    final keyId = EnvironmentConfig.razorpayKeyId;
    if (keyId == null || keyId.isEmpty) {
      throw StateError(
        'Razorpay key is not configured. Provide RAZORPAY_KEY_ID via --dart-define or update EnvironmentConfig.',
      );
    }

    final selectedCurrency = (currency ?? 'INR').toUpperCase();
    final user = _currentUser;
    final contact = user?.phone ?? '';
    final nameParts = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final customerName =
        nameParts.isEmpty ? (user?.email ?? 'Employer') : nameParts;

    try {
      _setBusy(true);
      _ensureRazorpay();

      final orderId = await createRazorpayOrder(
        amount: amount,
        currency: selectedCurrency,
        jobId: jobId,
      );

      final completer = Completer<void>();
      _paymentCompleter = completer;
      _pendingJobPayment = _PendingJobPayment(
        jobId: jobId,
        amount: amount,
        currency: selectedCurrency,
        orderId: orderId,
        paymentMethodHint: paymentMethodId,
      );

      final options = {
        'key': keyId,
        'amount': (amount * 100).round(),
        'currency': selectedCurrency,
        'name': 'Dhruv Talent',
        'order_id': orderId,
        'description': 'Job posting payment',
        'timeout': PaymentConfig.paymentTimeoutSeconds,
        'prefill': {
          'contact': contact,
          'email': user?.email ?? '',
          'name': customerName,
        },
        'notes': {
          'jobId': jobId,
        },
      };

      try {
        _razorpay.open(options);
      } catch (error) {
        _clearPendingPayment();
        rethrow;
      }
      await completer.future;
      await refreshActiveRole();
    } on PlatformException catch (error) {
      _clearPendingPayment();
      throw Exception('Failed to launch payment: ${error.message}');
    } catch (error) {
      if (_pendingJobPayment != null) {
        _clearPendingPayment();
      }
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  AttendanceStatus _attendanceStatusFromString(dynamic value) {
    final normalized = value?.toString().toLowerCase();
    switch (normalized) {
      case 'clocked-in':
      case 'clockedin':
      case 'clocked_in':
        return AttendanceStatus.clockedIn;
      case 'completed':
        return AttendanceStatus.completed;
      case 'missed':
        return AttendanceStatus.missed;
      case 'scheduled':
      default:
        return AttendanceStatus.scheduled;
    }
  }

  String _attendanceStatusToFilter(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.clockedIn:
        return 'clocked-in';
      case AttendanceStatus.completed:
        return 'completed';
      case AttendanceStatus.missed:
        return 'missed';
      case AttendanceStatus.scheduled:
        return 'scheduled';
    }
  }

  bool _statusMatchesFilter(AttendanceStatus status, String filter) {
    if (filter == 'all') {
      return true;
    }
    return _attendanceStatusToFilter(status) == filter;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  DateTime? _combineDateAndTime(String? date, String? time) {
    if (date == null || date.isEmpty) {
      return null;
    }
    final base = DateTime.tryParse(date);
    if (base == null) {
      return null;
    }
    if (time == null || time.isEmpty) {
      return base;
    }
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  AttendanceRecord? _mapManagementRecord(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final dateStr = json['date']?.toString();
    final scheduledStart =
        _combineDateAndTime(dateStr, json['scheduledStart']?.toString()) ??
            DateTime.now();
    final scheduledEnd =
        _combineDateAndTime(dateStr, json['scheduledEnd']?.toString()) ??
            scheduledStart;
    final clockIn = _combineDateAndTime(dateStr, json['clockIn']?.toString());
    final clockOut = _combineDateAndTime(dateStr, json['clockOut']?.toString());

    return AttendanceRecord(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      businessId:
          json['businessId']?.toString() ?? json['business']?.toString() ?? '',
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: _attendanceStatusFromString(json['status']),
      totalHours: _asDouble(json['totalHours'] ?? json['hoursWorked']),
      earnings: _asDouble(json['earnings']),
      isLate: _asBool(json['isLate']),
      clockIn: clockIn,
      clockOut: clockOut,
      locationSummary: json['location']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      hourlyRate: _asDouble(json['hourlyRate']),
      workerName: json['workerName']?.toString(),
    );
  }

  AttendanceRecord _mapTimelineRecord(
    Map<String, dynamic> json,
    String workerId,
    String? workerName,
  ) {
    final dateStr = json['date']?.toString();
    final scheduledStart =
        _combineDateAndTime(dateStr, json['scheduledStart']?.toString()) ??
            DateTime.now();
    final scheduledEnd =
        _combineDateAndTime(dateStr, json['scheduledEnd']?.toString()) ??
            scheduledStart;
    final clockIn = _combineDateAndTime(dateStr, json['clockIn']?.toString());
    final clockOut = _combineDateAndTime(dateStr, json['clockOut']?.toString());

    String jobId = '';
    String? jobTitle;
    double? hourlyRate;
    final job = json['job'];
    if (job is Map<String, dynamic>) {
      jobId = job['id']?.toString() ?? job['_id']?.toString() ?? '';
      jobTitle = job['title']?.toString();
      hourlyRate = _asDouble(job['hourlyRate']);
      if (hourlyRate == 0.0) {
        hourlyRate = null;
      }
    } else if (job is String) {
      jobId = job;
    }

    String businessId = '';
    String? companyName;
    final business = json['business'];
    if (business is Map<String, dynamic>) {
      businessId =
          business['id']?.toString() ?? business['_id']?.toString() ?? '';
      companyName = business['name']?.toString();
    } else if (business is String) {
      businessId = business;
    }

    return AttendanceRecord(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      workerId: workerId,
      jobId: jobId,
      businessId: businessId,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: _attendanceStatusFromString(json['status']),
      totalHours: _asDouble(json['hoursWorked'] ?? json['totalHours']),
      earnings: _asDouble(json['earnings']),
      isLate: _asBool(json['isLate']),
      clockIn: clockIn,
      clockOut: clockOut,
      locationSummary: json['location']?.toString(),
      jobTitle: jobTitle ?? json['jobTitle']?.toString(),
      hourlyRate: hourlyRate ?? _asDouble(json['hourlyRate']),
      companyName: companyName,
      workerName: workerName,
    );
  }

  AttendanceDashboardSummary _buildAttendanceSummary(
    List<AttendanceRecord> records,
  ) {
    final completed = records
        .where((record) => record.status == AttendanceStatus.completed)
        .length;
    final totalHours =
        records.fold<double>(0, (sum, record) => sum + record.totalHours);
    final totalPayroll =
        records.fold<double>(0, (sum, record) => sum + record.earnings);
    final lateArrivals = records.where((record) => record.isLate).length;

    return AttendanceDashboardSummary(
      totalWorkers: records.length,
      completedShifts: completed,
      totalHours: totalHours,
      totalPayroll: totalPayroll,
      lateArrivals: lateArrivals,
    );
  }

  void _upsertAttendanceRecord(AttendanceRecord record) {
    if (_attendanceDashboard == null) {
      return;
    }

    final recordDate = DateTime(
      record.scheduledStart.year,
      record.scheduledStart.month,
      record.scheduledStart.day,
    );
    final selectedDate = DateTime(
      _attendanceSelectedDate.year,
      _attendanceSelectedDate.month,
      _attendanceSelectedDate.day,
    );

    if (recordDate != selectedDate) {
      return;
    }

    if (!_statusMatchesFilter(record.status, _attendanceStatusFilter)) {
      return;
    }

    final records = [..._attendanceDashboard!.records];
    final index = records.indexWhere((item) => item.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
      records.sort(
        (a, b) => a.scheduledStart.compareTo(b.scheduledStart),
      );
    }

    final summary = _buildAttendanceSummary(records);
    _attendanceDashboard = _attendanceDashboard!.copyWith(
      records: records,
      summary: summary,
    );
    _attendanceSummary = summary;
  }

  Future<void> _refreshWorkerScheduleIfCached(String workerId) async {
    final cacheKey = _extractObjectId(workerId) ?? workerId;
    final cached = _workerAttendanceSchedules[cacheKey];
    if (cached == null) {
      return;
    }
    unawaited(
      loadWorkerAttendanceSchedule(
        workerId: cacheKey,
        status: cached.statusFilter,
      ),
    );
  }

  // ================== Attendance Methods ==================
  Future<void> loadAttendanceDashboard({
    DateTime? date,
    String? status,
  }) async {
    _isAttendanceBusy = true;
    notifyListeners();

    final targetDate = date ?? _attendanceSelectedDate;
    final targetFilter = (status ?? _attendanceStatusFilter).toLowerCase();

    try {
      final token = _service.authToken;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required to load attendance data');
      }

      _attendanceSelectedDate = targetDate;
      _attendanceStatusFilter = targetFilter;

      final response = await _service.attendance.getManagementView(
        authToken: token,
        date: targetDate,
        status: targetFilter == 'all' ? null : targetFilter,
      );

      final payload = (response['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final recordsRaw = payload['records'] as List<dynamic>? ?? const [];

      final parsedRecords = recordsRaw
          .whereType<Map<String, dynamic>>()
          .map(_mapManagementRecord)
          .whereType<AttendanceRecord>()
          .where(
            (record) => _statusMatchesFilter(record.status, targetFilter),
          )
          .toList()
        ..sort(
          (a, b) => a.scheduledStart.compareTo(b.scheduledStart),
        );

      final summaryMap = (payload['summary'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      final summary = AttendanceDashboardSummary(
        totalWorkers: _asInt(summaryMap['totalWorkers']),
        completedShifts: _asInt(summaryMap['completedShifts']),
        totalHours: _asDouble(summaryMap['totalHours']),
        totalPayroll: _asDouble(summaryMap['totalPayroll']),
        lateArrivals: _asInt(summaryMap['lateArrivals']),
      );

      _attendanceDashboard = AttendanceDashboard(
        date: targetDate,
        statusFilter: targetFilter,
        records: parsedRecords,
        summary: summary,
      );
      _attendanceSummary = summary;
    } catch (error, stackTrace) {
      debugPrint('Error loading attendance dashboard: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _isAttendanceBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkerAttendanceSchedule({
    required String workerId,
    String? status,
  }) async {
    final normalizedWorkerId = _extractObjectId(workerId) ?? workerId;
    if (normalizedWorkerId.isEmpty) return;

    _workerScheduleLoading[normalizedWorkerId] = true;
    notifyListeners();

    final targetFilter = (status ?? 'all').toLowerCase();

    try {
      final token = _service.authToken;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required to load worker schedule');
      }

      final response = await _service.attendance.getWorkerEmploymentTimeline(
        authToken: token,
        workerId: normalizedWorkerId,
      );

      final data = (response['data'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final workerInfo = data['worker'] as Map<String, dynamic>?;
      final workerName = workerInfo?['name']?.toString();

      final recordsRaw =
          data['attendanceRecords'] as List<dynamic>? ?? const [];
      final parsedRecords = recordsRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => _mapTimelineRecord(json, workerId, workerName))
          .where(
            (record) => _statusMatchesFilter(record.status, targetFilter),
          )
          .toList()
        ..sort(
          (a, b) => a.scheduledStart.compareTo(b.scheduledStart),
        );

      final grouped = <DateTime, List<AttendanceRecord>>{};
      for (final record in parsedRecords) {
        final key = DateTime(
          record.scheduledStart.year,
          record.scheduledStart.month,
          record.scheduledStart.day,
        );
        grouped.putIfAbsent(key, () => []).add(record);
      }

      final days = grouped.entries.map((entry) {
        final records = entry.value;
        final totalHours =
            records.fold<double>(0, (sum, record) => sum + record.totalHours);
        final totalEarnings =
            records.fold<double>(0, (sum, record) => sum + record.earnings);
        final completedCount = records
            .where((record) => record.status == AttendanceStatus.completed)
            .length;

        return AttendanceScheduleDay(
          date: entry.key,
          records: records,
          totalHours: totalHours,
          totalEarnings: totalEarnings,
          scheduledCount: records.length,
          completedCount: completedCount,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final summary = (data['summary'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      final schedule = AttendanceSchedule(
        workerId: normalizedWorkerId,
        statusFilter: targetFilter,
        days: days,
        workerName: workerName,
        from: days.isNotEmpty ? days.first.date : null,
        to: days.isNotEmpty ? days.last.date : null,
        totalHours: summary.isNotEmpty
            ? _asDouble(summary['totalHoursWorked'])
            : parsedRecords.fold<double>(
                0, (sum, record) => sum + record.totalHours),
        totalEarnings: summary.isNotEmpty
            ? _asDouble(summary['totalEarnings'])
            : parsedRecords.fold<double>(
                0, (sum, record) => sum + record.earnings),
        totalRecords: summary.isNotEmpty
            ? _asInt(summary['totalAttendanceRecords'])
            : parsedRecords.length,
      );

      _workerAttendanceSchedules[normalizedWorkerId] = schedule;
    } catch (error, stackTrace) {
      debugPrint(
          'Error loading worker schedule for $normalizedWorkerId: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _workerScheduleLoading[normalizedWorkerId] = false;
      notifyListeners();
    }
  }

  Future<void> markEmployerAttendanceComplete(String recordId) async {
    _setBusy(true);
    try {
      final updated = await _service.employer.markAttendanceComplete(recordId);
      _upsertAttendanceRecord(updated);
      await _refreshWorkerScheduleIfCached(updated.workerId);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Error marking attendance complete: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateEmployerAttendanceHours({
    required String attendanceId,
    required double totalHours,
    double? hourlyRate,
  }) async {
    _setBusy(true);
    try {
      final updated = await _service.employer.updateAttendanceHours(
        attendanceId: attendanceId,
        totalHours: totalHours,
        hourlyRate: hourlyRate,
      );
      _upsertAttendanceRecord(updated);
      await _refreshWorkerScheduleIfCached(updated.workerId);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Error updating attendance hours: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  AttendanceSchedule? workerAttendanceSchedule(String workerId) {
    return _workerAttendanceSchedules[workerId];
  }

  bool isWorkerScheduleLoading(String workerId) {
    return _workerScheduleLoading[workerId] ?? false;
  }

  Future<void> refreshEmployerApplications({
    ApplicationStatus? status,
    String? businessId,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final resolvedBusinessId = businessId ??
        _service.currentUserBusinessId ??
        (_businesses.isNotEmpty ? _businesses.first.id : null);

    debugPrint(
      '📡 AppState: refreshing employer applications (status=${status?.name ?? 'all'}, business=$resolvedBusinessId)',
    );

    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      debugPrint('⚠️ AppState: no business ID available for applications');
      _employerApplications = const [];
      notifyListeners();
      return;
    }

    try {
      // Use cache-first approach for better performance
      final cachedApplications =
          await _employerRepo.getApplicationsSWR(user.id);

      // Apply status filter if specified
      if (status != null) {
        _employerApplications =
            cachedApplications.where((app) => app.status == status).toList();
      } else {
        _employerApplications = cachedApplications;
      }

      _employerApplicationsError = null;
      notifyListeners();

      // Refresh in background without blocking UI
      unawaited(_employerRepo.refreshApplications(user.id).then((_) async {
        final freshApplications =
            await _employerRepo.getApplicationsSWR(user.id);

        // Apply status filter if specified
        if (status != null) {
          _employerApplications =
              freshApplications.where((app) => app.status == status).toList();
        } else {
          _employerApplications = freshApplications;
        }

        notifyListeners();
      }).catchError((error) {
        debugPrint('❌ Background refresh failed for applications: $error');
      }));
    } catch (error) {
      debugPrint('❌ AppState: failed to refresh employer applications: $error');

      String message =
          'We could not load applications right now. Please try again shortly.';

      if (error is TimeoutException) {
        message =
            'Our servers are taking longer than usual. Still loading applications…';
      } else if (error is SocketException) {
        message =
            'You appear to be offline. Check your connection and try again.';
      } else if (error is DioException &&
          (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout)) {
        message =
            'The connection timed out before we could load applications. Retrying shortly…';
      } else if (error is DioException &&
          error.type == DioExceptionType.connectionError) {
        message =
            'We could not reach the server. Please check your connection and try again.';
      }

      _employerApplicationsError = message;
      notifyListeners();
    }
  }

  Future<void> hireEmployerApplication(String applicationId,
      {DateTime? startDate}) async {
    _setBusy(true);
    try {
      print('👤 Hiring application via API: $applicationId');

      final uri = Uri.parse(
          'https://dhruvbackend.vercel.app/api/applications/$applicationId');

      final requestBody = <String, dynamic>{'status': 'hired'};
      if (startDate != null) {
        requestBody['startDate'] = startDate.toIso8601String();
      }

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Application hired successfully');

        // Update the application status in the local list
        final index =
            _employerApplications.indexWhere((app) => app.id == applicationId);
        if (index != -1) {
          final application = _employerApplications[index];
          _employerApplications[index] =
              application.copyWith(status: ApplicationStatus.hired);

          // Trigger notification to worker about being hired
          unawaited(_sendHireNotification(application));

          // Force immediate notification refresh for all users
          unawaited(_forceNotificationRefresh());
        }

        notifyListeners();
      } else {
        print(
            '⚠️ Hire application API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to hire application: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error hiring application: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateEmployerApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? note,
  }) async {
    _setBusy(true);
    try {
      print(
          '🔄 Updating application status via API: $applicationId to ${status.name}');

      final uri = Uri.parse(
          'https://dhruvbackend.vercel.app/api/applications/$applicationId');

      final body = {
        'status': status.name,
        if (note != null) 'message': note,
      };

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Application status updated successfully');

        // Update the application status in the local list
        final index =
            _employerApplications.indexWhere((app) => app.id == applicationId);
        if (index != -1) {
          final application = _employerApplications[index];
          _employerApplications[index] = application.copyWith(
            status: status,
            note: note ?? application.note,
          );
        }

        notifyListeners();
      } else {
        print(
            '⚠️ Update application status API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to update application status: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error updating application status: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  /// Send hire notification to worker
  Future<void> _sendHireNotification(Application application) async {
    try {
      print('📧 Sending hire notification to worker: ${application.workerId}');

      // Create notification payload
      final notificationData = {
        'type': 'hire',
        'recipientId': application.workerId,
        'title': 'Congratulations! You\'ve been hired',
        'message': 'Your application has been accepted. Welcome to the team!',
        'applicationId': application.id,
        'jobId': application.jobId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send notification to backend
      final uri =
          Uri.parse('https://dhruvbackend.vercel.app/api/notifications');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode(notificationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Hire notification sent successfully');
      } else {
        print(
            '⚠️ Failed to send hire notification: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('❌ Error sending hire notification: $error');
      // Don't rethrow - notification failure shouldn't break the hiring process
    }
  }

  // ================== Worker Methods ==================

  // Worker Attendance Methods
  Future<void> refreshWorkerAttendance() async {
    if (_currentUser?.type != UserType.worker) return;

    _setBusy(true);
    try {
      final workerId =
          _extractObjectId(_currentUser?.id) ?? (_currentUser?.id ?? 'me');
      final records = await _service.worker.fetchWorkerAttendance(workerId);
      _workerAttendance = records;
      notifyListeners();
    } catch (error) {
      print('Error refreshing worker attendance: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<AttendanceRecord> clockInWorkerAttendance(String recordId) async {
    _setBusy(true);
    try {
      final location = await LocationService.instance.getHighAccuracyLocation();
      if (location == null) {
        throw const LocationException(
          'Unable to determine your current location. Please enable location services and try again.',
        );
      }

      final updatedRecord = await _service.worker.clockIn(
        recordId,
        location: location,
      );

      _upsertWorkerAttendanceRecord(updatedRecord);
      return updatedRecord;
    } on LocationException catch (error) {
      debugPrint('Location error while clocking in: ${error.message}');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Error clocking in worker attendance: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<AttendanceRecord> clockOutWorkerAttendance(
    String recordId, {
    required double hourlyRate,
  }) async {
    _setBusy(true);
    try {
      final location = await LocationService.instance.getHighAccuracyLocation();
      if (location == null) {
        throw const LocationException(
          'Unable to determine your current location. Please enable location services and try again.',
        );
      }

      final updatedRecord = await _service.worker.clockOut(
        recordId,
        location: location,
        hourlyRate: hourlyRate,
      );

      _upsertWorkerAttendanceRecord(updatedRecord);
      return updatedRecord;
    } on LocationException catch (error) {
      debugPrint('Location error while clocking out: ${error.message}');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Error clocking out worker attendance: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  // Worker Job Methods
  Future<void> loadWorkerJobs(String workerId) async {
    _setBusy(true);
    try {
      print('🔍 Loading worker jobs for: $workerId');
      print('🔍 Current user: ${_currentUser?.email}');
      print('🔍 User type: ${_currentUser?.type}');
      print('🔍 Auth token available: ${_service.authToken != null}');

      // Debug authentication state
      await _debugAuthenticationState();

      // Fetch available jobs from the API
      _workerJobs = await _service.worker.fetchWorkerJobs(workerId);
      print('✅ Loaded ${_workerJobs.length} worker jobs');

      notifyListeners();
    } catch (error) {
      print('❌ Error loading worker jobs: $error');

      // Provide more specific error feedback
      if (error.toString().contains('Authentication required') ||
          error.toString().contains('401')) {
        print('❌ Authentication issue: User might need to log in again');
      } else if (error.toString().contains('404')) {
        print('❌ Jobs API endpoint not found - check API configuration');
      } else if (error.toString().contains('timeout') ||
          error.toString().contains('SocketException')) {
        print('❌ Network issue: Check internet connection');
      }

      // Set empty jobs list instead of rethrowing to prevent app crashes
      _workerJobs = [];
      notifyListeners();
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> loadWorkerApplications(String workerId) async {
    _setBusy(true);
    try {
      print('🔍 Loading worker applications for: $workerId');
      print('🔍 Current user: ${_currentUser?.email}');
      print('🔍 User type: ${_currentUser?.type}');
      print('🔍 Auth token available: ${_service.authToken != null}');

      if (_service.authToken == null) {
        print('❌ Cannot fetch applications: No auth token available');
        _workerApplications = [];
        notifyListeners();
        return;
      }

      // Fetch worker applications from the API
      _workerApplications =
          await _service.worker.fetchWorkerApplications(workerId);
      print('✅ Loaded ${_workerApplications.length} worker applications');

      notifyListeners();
    } catch (error) {
      print('❌ Error loading worker applications: $error');

      // Provide more specific error feedback
      if (error.toString().contains('Authentication required') ||
          error.toString().contains('401')) {
        print('❌ Authentication issue: User might need to log in again');
      } else if (error.toString().contains('404')) {
        print(
            '❌ Applications API endpoint not found - check API configuration');
      } else if (error.toString().contains('timeout') ||
          error.toString().contains('SocketException')) {
        print('❌ Network issue: Check internet connection');
      }

      // Set empty applications list instead of rethrowing to prevent app crashes
      _workerApplications = [];
      notifyListeners();
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _debugAuthenticationState() async {
    try {
      print('🔍 === AUTHENTICATION DEBUG ===');
      print(
          '🔍 ServiceLocator authToken: ${_service.authToken?.substring(0, 20)}...');
      print('🔍 ServiceLocator currentUser: ${_service.currentUser?.email}');
      print('🔍 AppState currentUser: ${_currentUser?.email}');
      print('🔍 User type: ${_currentUser?.type}');
      print('🔍 User role: ${_currentUser?.roles}');
      print('🔍 ===========================');
    } catch (e) {
      print('❌ Error in debug authentication: $e');
    }
  }

  /// Debug method to test job fetching functionality
  Future<Map<String, dynamic>> debugJobFetching() async {
    final result = <String, dynamic>{
      'success': false,
      'error': null,
      'jobCount': 0,
      'authToken': _service.authToken != null,
      'currentUser': _currentUser?.email,
      'userType': _currentUser?.type.toString(),
    };

    try {
      if (_currentUser == null) {
        result['error'] = 'No current user';
        return result;
      }

      if (_service.authToken == null) {
        result['error'] = 'No auth token';
        return result;
      }

      final jobs = await _service.worker.fetchWorkerJobs(_currentUser!.id);
      result['success'] = true;
      result['jobCount'] = jobs.length;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<void> submitWorkerApplication({
    required String jobId,
    String? message,
  }) async {
    final user = _currentUser;
    if (user?.type != UserType.worker) {
      throw Exception('Only workers can submit applications');
    }

    if (!canApplyToJob()) {
      throw ApiWorkConnectException(
        402,
        'Free application limit reached. Upgrade to continue applying to jobs.',
      );
    }

    _setBusy(true);
    try {
      print('Submitting worker application for job: $jobId');
      if (message != null) {
        print('Application message: $message');
      }

      // Use the actual API service to submit the application
      final application = await service.worker.submitJobApplication(
        workerId: user!.id,
        jobId: jobId,
        message: message,
      );

      // Add the new application to our local list
      _workerApplications.add(application);

      final isPremiumWorker =
          user.isPremium || (workerProfile?.isPremium ?? false);

      if (!isPremiumWorker) {
        final updatedFreeApplicationsUsed = user.freeApplicationsUsed + 1;
        _currentUser = User(
          id: user.id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          type: user.type,
          freeJobsPosted: user.freeJobsPosted,
          freeApplicationsUsed: updatedFreeApplicationsUsed,
          isPremium: user.isPremium,
          selectedBusinessId: user.selectedBusinessId,
          roles: List<UserType>.from(user.roles),
          ownedBusinesses: List<BusinessAssociation>.from(user.ownedBusinesses),
          teamBusinesses: List<BusinessAssociation>.from(user.teamBusinesses),
        );
        _service.updateCurrentUser(_currentUser);

        if (_workerMetrics != null) {
          final metrics = _workerMetrics!;
          final remaining = _freeApplicationQuota - updatedFreeApplicationsUsed;
          final normalizedRemaining = remaining > 0 ? remaining : 0;
          _workerMetrics = WorkerDashboardMetrics(
            availableJobs: metrics.availableJobs,
            activeApplications: metrics.activeApplications,
            upcomingShifts: metrics.upcomingShifts,
            completedHours: metrics.completedHours,
            earningsThisWeek: metrics.earningsThisWeek,
            freeApplicationsRemaining: normalizedRemaining,
            isPremium: metrics.isPremium,
          );
        }
      } else if (_workerMetrics != null) {
        final metrics = _workerMetrics!;
        _workerMetrics = WorkerDashboardMetrics(
          availableJobs: metrics.availableJobs,
          activeApplications: metrics.activeApplications,
          upcomingShifts: metrics.upcomingShifts,
          completedHours: metrics.completedHours,
          earningsThisWeek: metrics.earningsThisWeek,
          freeApplicationsRemaining: -1,
          isPremium: true,
        );
      }

      // Update the job's application count if we have it locally
      final jobIndex = _workerJobs.indexWhere((job) => job.id == jobId);
      if (jobIndex != -1) {
        final updatedJob = JobPosting(
          id: _workerJobs[jobIndex].id,
          title: _workerJobs[jobIndex].title,
          description: _workerJobs[jobIndex].description,
          employerId: _workerJobs[jobIndex].employerId,
          businessId: _workerJobs[jobIndex].businessId,
          businessAddress: _workerJobs[jobIndex].businessAddress,
          location: _workerJobs[jobIndex].location,
          hourlyRate: _workerJobs[jobIndex].hourlyRate,
          scheduleStart: _workerJobs[jobIndex].scheduleStart,
          scheduleEnd: _workerJobs[jobIndex].scheduleEnd,
          recurrence: _workerJobs[jobIndex].recurrence,
          overtime: _workerJobs[jobIndex].overtime,
          urgency: _workerJobs[jobIndex].urgency,
          tags: _workerJobs[jobIndex].tags,
          workDays: _workerJobs[jobIndex].workDays,
          isVerificationRequired: _workerJobs[jobIndex].isVerificationRequired,
          status: _workerJobs[jobIndex].status,
          postedAt: _workerJobs[jobIndex].postedAt,
          distanceMiles: _workerJobs[jobIndex].distanceMiles,
          hasApplied: true, // Mark as applied
          premiumRequired: _workerJobs[jobIndex].premiumRequired,
          locationSummary: _workerJobs[jobIndex].locationSummary,
          applicantsCount:
              _workerJobs[jobIndex].applicantsCount + 1, // Increment count
          businessName: _workerJobs[jobIndex].businessName,
        );
        _workerJobs[jobIndex] = updatedJob;
      }

      // Refresh notifications after submitting application
      await loadNotifications();

      notifyListeners();
    } catch (error) {
      print('Error submitting worker application: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateWorkerProfile({
    String? firstName,
    String? lastName,
    String? phone,
    List<String>? skills,
    String? experience,
    String? bio,
    List<String>? languages,
    List<Map<String, dynamic>>? availability,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    double? minimumPay,
    double? maxTravelDistance,
    bool? availableForFullTime,
    bool? availableForPartTime,
    bool? availableForTemporary,
    String? weekAvailability,
    bool? isVisible,
    bool? locationEnabled,
    bool? shareWorkHistory,
    double? preferredRadiusMiles,
    String? profilePictureUrl,
  }) async {
    if (_workerProfile == null) return;

    final workerId = _workerProfile!.id.isNotEmpty
        ? _workerProfile!.id
        : (_currentUser?.id ?? '');

    if (workerId.isEmpty) {
      debugPrint('⚠️ Cannot update worker profile: missing workerId');
      return;
    }

    _setBusy(true);
    try {
      final updatedProfile = await _service.worker.updateWorkerProfile(
        workerId: workerId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        bio: bio,
        skills: skills,
        experience: experience,
        languages: languages,
        availability: availability,
        notificationsEnabled: notificationsEnabled,
        emailNotificationsEnabled: emailNotificationsEnabled,
        minimumPay: minimumPay,
        maxTravelDistance: maxTravelDistance,
        profilePictureUrl: profilePictureUrl,
        availableForFullTime: availableForFullTime,
        availableForPartTime: availableForPartTime,
        availableForTemporary: availableForTemporary,
        weekAvailability: weekAvailability,
        isVisible: isVisible,
        locationEnabled: locationEnabled,
        shareWorkHistory: shareWorkHistory,
        preferredRadiusMiles: preferredRadiusMiles,
      );

      _workerProfile = updatedProfile;

      if (_currentUser != null &&
          (firstName != null || lastName != null || phone != null)) {
        final updatedFirstName = firstName ?? _currentUser!.firstName;
        final updatedLastName = lastName ?? _currentUser!.lastName;
        final updatedPhone = phone ?? _currentUser!.phone;

        _currentUser = User(
          id: _currentUser!.id,
          firstName: updatedFirstName,
          lastName: updatedLastName,
          email: _currentUser!.email,
          phone: updatedPhone,
          type: _currentUser!.type,
          freeJobsPosted: _currentUser!.freeJobsPosted,
          freeApplicationsUsed: _currentUser!.freeApplicationsUsed,
          isPremium: _currentUser!.isPremium,
          selectedBusinessId: _currentUser!.selectedBusinessId,
          roles: _currentUser!.roles,
          ownedBusinesses: _currentUser!.ownedBusinesses,
          teamBusinesses: _currentUser!.teamBusinesses,
        );
        _service.updateCurrentUser(_currentUser);
      }

      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Error updating worker profile: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> withdrawWorkerApplication({
    required String applicationId,
    String? message,
  }) async {
    _setBusy(true);
    try {
      final trimmedMessage = message?.trim();
      final application = await service.worker.withdrawApplication(
        applicationId: applicationId,
        message: (trimmedMessage != null && trimmedMessage.isNotEmpty)
            ? trimmedMessage
            : null,
      );

      final index =
          _workerApplications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _workerApplications[index] = application;
      } else {
        _workerApplications.add(application);
      }

      notifyListeners();
    } catch (error) {
      print('Error withdrawing worker application: $error');
    } finally {
      _setBusy(false);
    }
  }

  // Enhanced API Integration Methods
  Future<List<Map<String, dynamic>>> searchWorkersByName({
    required String query,
    bool includeSchedule = true,
  }) async {
    try {
      print('🔍 Searching workers by name: $query');

      // Use the actual API endpoint from the documentation
      final queryParams = {
        'name': query,
        'includeSchedule': includeSchedule.toString(),
      };

      final uri = Uri.parse(
              'https://dhruvbackend.vercel.app/api/attendance/search/workers')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both direct array and wrapped response
        final results = data is List
            ? data
            : (data['data'] as List? ?? data['results'] as List? ?? []);
        return List<Map<String, dynamic>>.from(
            results.map((item) => item as Map<String, dynamic>));
      } else {
        print(
            '⚠️ Worker search API error: ${response.statusCode} - ${response.body}');
        // Return empty results on API error
        return [];
      }
    } catch (e) {
      print('❌ Worker search error: $e');
      // Return empty results on error
      return [];
    }
  }

  Future<Map<String, dynamic>> getWorkerEmploymentTimeline({
    required String workerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 Getting employment timeline for worker: $workerId');

      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().substring(0, 10);
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().substring(0, 10);
      }

      final uri = Uri.parse(
              'https://dhruvbackend.vercel.app/api/attendance/timeline/worker/$workerId')
          .replace(
              queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic>
            ? data
            : (data['data'] as Map<String, dynamic>? ?? {});
      } else {
        print(
            '⚠️ Worker timeline API error: ${response.statusCode} - ${response.body}');
        // Return empty timeline on API error
        return {
          'worker': {'id': workerId, 'name': 'Unknown Worker'},
          'employmentHistory': [],
          'attendanceRecords': [],
          'summary': {
            'totalEmployments': 0,
            'activeEmployments': 0,
            'totalAttendanceRecords': 0,
            'totalHoursWorked': 0.0,
            'totalEarnings': 0.0,
          }
        };
      }
    } catch (e) {
      print('❌ Worker timeline error: $e');
      // Return empty timeline on error
      return {
        'worker': {'id': workerId, 'name': 'Unknown Worker'},
        'employmentHistory': [],
        'attendanceRecords': [],
        'summary': {
          'totalEmployments': 0,
          'activeEmployments': 0,
          'totalAttendanceRecords': 0,
          'totalHoursWorked': 0.0,
          'totalEarnings': 0.0,
        }
      };
    }
  }

  Future<void> markAttendanceCompleteWithAPI(String recordId) async {
    try {
      print('✅ Marking attendance complete via API: $recordId');

      final uri = Uri.parse(
          'https://dhruvbackend.vercel.app/api/attendance/$recordId/mark-complete');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Attendance marked complete successfully');
        // Update local state after successful API call
        await markEmployerAttendanceComplete(recordId);
      } else {
        print(
            '⚠️ Mark complete API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to mark attendance complete: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Mark complete error: $e');
      throw Exception('Failed to mark attendance complete: $e');
    }
  }

  Future<void> updateAttendanceHoursWithAPI({
    required String recordId,
    required double totalHours,
    double? hourlyRate,
  }) async {
    try {
      print(
          '⏱️ Updating attendance hours via API: $recordId, hours: $totalHours');

      final uri = Uri.parse(
          'https://dhruvbackend.vercel.app/api/attendance/$recordId/hours');

      final body = {
        'totalHours': totalHours,
        if (hourlyRate != null) 'hourlyRate': hourlyRate,
      };

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Attendance hours updated successfully');
        // Update local state after successful API call
        await updateEmployerAttendanceHours(
          attendanceId: recordId,
          totalHours: totalHours,
          hourlyRate: hourlyRate,
        );
      } else {
        print(
            '⚠️ Update hours API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to update attendance hours: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Update hours error: $e');
      throw Exception('Failed to update attendance hours: $e');
    }
  }

  // ================== Helpers ==================
  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    developer.log('🔄 AppState busy state changing: $_isBusy -> $value',
        name: 'AppState');
    _isBusy = value;
    notifyListeners();
  }

  void _resetState() {
    // Worker state
    _workerProfile = null;
    _workerMetrics = null;
    _workerJobs = [];
    _workerApplications = [];
    _workerAttendance = [];
    _workerShifts = [];
    _swapRequests = [];

    // Employer state
    _employerProfile = null;
    _employerMetrics = null;
    _employerJobs = [];
    _businesses = [];
    // No need to reset team members as it's final

    // Shared state
    _notifications = [];
    _conversations = [];
    _currentUserTeamMember = null;
    _isLoadingCurrentUserTeamMember = false;
    _jobPayments = [];
    _isLoadingJobPayments = false;
    _employerFeedback = [];
    _isLoadingEmployerFeedback = false;
    _workerEmploymentHistory = [];
    _isLoadingEmploymentHistory = false;
    _workerFeedback = [];
    _isLoadingWorkerFeedback = false;
    notifyListeners();
  }

  // ================== Missing Methods ==================

  Future<JobPosting?> fetchJobDetails(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('https://dhruvbackend.vercel.app/api/jobs/$jobId'),
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final payload = json.decode(response.body);
        final rawJob = payload['data'] ?? payload['job'];

        if (rawJob is Map<String, dynamic>) {
          return JobPosting.fromJson(rawJob);
        }

        print('Unexpected job payload shape: ${response.body}');
        return null;
      } else {
        print('Failed to fetch job details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching job details: $e');
      return null;
    }
  }

  Future<void> scheduleAttendanceForWorker({
    required String workerId,
    required String jobId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required double hourlyRate,
    String? notes,
  }) async {
    final normalizedWorkerId = _extractObjectId(workerId) ?? workerId;
    final normalizedJobId = _extractObjectId(jobId) ?? jobId;

    if (normalizedWorkerId.isEmpty || normalizedJobId.isEmpty) {
      throw ArgumentError(
        'Invalid identifiers for scheduling attendance '
        '(workerId: $workerId, jobId: $jobId)',
      );
    }

    _setBusy(true);
    try {
      final record = await _service.employer.scheduleAttendanceRecord(
        workerId: normalizedWorkerId,
        jobId: normalizedJobId,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        hourlyRate: hourlyRate,
        notes: notes,
      );

      _upsertAttendanceRecord(record);
      await _refreshWorkerScheduleIfCached(normalizedWorkerId);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Error scheduling attendance: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateWorkerEmploymentLocation({
    required String workerId,
    required String businessId,
    required String location,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(
            'https://dhruvbackend.vercel.app/api/workers/$workerId/employment'),
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode({
          'businessId': businessId,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        print('Worker employment location updated successfully');
        // Refresh team members if needed
        notifyListeners();
        return true;
      } else {
        print(
            'Failed to update worker employment location: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating worker employment location: $e');
      return false;
    }
  }

  BusinessAssociation? _findAssociation(
    List<BusinessAssociation> associations,
    String businessId,
  ) {
    for (final association in associations) {
      if (association.businessId == businessId) {
        return association;
      }
    }
    return null;
  }

  void _markJobPaymentComplete(String jobId) {
    final index = _employerJobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      return;
    }

    final job = _employerJobs[index];
    final updated = JobPosting(
      id: job.id,
      title: job.title,
      description: job.description,
      employerId: job.employerId,
      businessId: job.businessId,
      hourlyRate: job.hourlyRate,
      scheduleStart: job.scheduleStart,
      scheduleEnd: job.scheduleEnd,
      recurrence: job.recurrence,
      overtime: job.overtime,
      urgency: job.urgency,
      tags: List<String>.from(job.tags),
      workDays: List<String>.from(job.workDays),
      isVerificationRequired: job.isVerificationRequired,
      status: JobStatus.active,
      postedAt: job.postedAt,
      isPublished: job.isPublished,
      publishStatus: job.publishStatus,
      publishActionRequired: job.publishActionRequired,
      distanceMiles: job.distanceMiles,
      hasApplied: job.hasApplied,
      premiumRequired: false,
      locationSummary: job.locationSummary,
      location: job.location,
      applicantsCount: job.applicantsCount,
      businessName: job.businessName,
      businessAddress: job.businessAddress,
      employerName: job.employerName,
      employerEmail: job.employerEmail,
      businessLogoSmall: job.businessLogoSmall,
      businessLogoMedium: job.businessLogoMedium,
      employerAvatarSmall: job.employerAvatarSmall,
      employerAvatarMedium: job.employerAvatarMedium,
      metrics: job.metrics,
    );

    final updatedJobs = List<JobPosting>.from(_employerJobs);
    updatedJobs[index] = updated;
    _employerJobs = updatedJobs;
  }

  void _promoteCurrentUserToPremium() {
    final user = _currentUser;
    if (user == null || user.isPremium) {
      return;
    }

    _currentUser = User(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      type: user.type,
      freeJobsPosted: user.freeJobsPosted,
      freeApplicationsUsed: user.freeApplicationsUsed,
      isPremium: true,
      selectedBusinessId: user.selectedBusinessId,
      roles: List<UserType>.from(user.roles),
      ownedBusinesses: List<BusinessAssociation>.from(user.ownedBusinesses),
      teamBusinesses: List<BusinessAssociation>.from(user.teamBusinesses),
    );

    _service.updateCurrentUser(_currentUser);
  }
}

class _PendingJobPayment {
  const _PendingJobPayment({
    required this.jobId,
    required this.amount,
    required this.currency,
    required this.orderId,
    this.paymentMethodHint,
  });

  final String jobId;
  final double amount;
  final String currency;
  final String orderId;
  final String? paymentMethodHint;
}
