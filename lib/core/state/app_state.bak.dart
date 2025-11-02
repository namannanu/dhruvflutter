// ignore_for_file: avoid_print, prefer_single_quotes

import 'package:flutter/foundation.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/locator/service_locator.dart';

class AppState extends ChangeNotifier {
  AppState(this._service);

  final ServiceLocator _service;

  bool _isBusy = false;
  User? _currentUser;
  UserType? _activeRole;

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

  // Shared state
  List<AppNotification> _notifications = [];
  List<Conversation> _conversations = [];
  final List<Application> _selectedJobApplications = [];

  // ================== Getters ==================
  bool get isBusy => _isBusy;
  User? get currentUser => _currentUser;
  UserType? get activeRole => _activeRole;

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
  List<Conversation> get conversations => _conversations;
  List<Application> get selectedJobApplications => _selectedJobApplications;

  // ================== Authentication ==================
  Future<void> login({
    required String email,
    required String password,
    required UserType type,
  }) async {
    _setBusy(true);
    try {
      _currentUser = (await _service.auth.login(
        email: email,
        password: password,
      )) as User?;
      _activeRole = _currentUser?.type;
      _service.updateAuthToken(_service.auth.authToken);

      // Create temporary profile data to prevent loading screen from getting stuck
      if (_currentUser != null && _activeRole == UserType.worker) {
        // Create a basic worker profile with current user data
        _workerProfile = WorkerProfile(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          email: _currentUser!.email,
          phone: '',
          skills: const <String>[],
          experience: '',
          bio: 'Loading profile data...',
          rating: 0.0,
          completedJobs: 0,
          weeklyEarnings: 0.0,
          totalEarnings: 0.0,
          languages: const <String>[],
          isVerified: false,
          notificationsEnabled: true,
          preferredRadiusMiles: 10.0,
          availability: const [],
          emailNotificationsEnabled: true,
        );

        // Create basic metrics
        _workerMetrics = const WorkerDashboardMetrics(
          availableJobs: 0,
          activeApplications: 0,
          upcomingShifts: 0,
          completedHours: 0,
          earningsThisWeek: 0.0,
          freeApplicationsRemaining: 2,
          isPremium: false,
        );
      }

      // Refresh data immediately after login
      await refreshActiveRole();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _service.auth.logout();
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
          _businesses.isNotEmpty) {
        businessId = _businesses.first.id;
      }
    }

    try {
      _notifications = await _service.messaging.fetchNotifications(
        user.id,
        businessId: businessId,
      );
    } catch (_) {
      _notifications = [];
    }
    notifyListeners();
  }

  Future<void> loadConversations() async {
    if (_currentUser == null) return;
    _conversations =
        await _service.messaging.fetchConversations(_currentUser!.id);
    notifyListeners();
  }

  Future<void> switchRole(UserType newRole) async {
    if (_currentUser == null || newRole == _activeRole) return;
    _activeRole = newRole;
    notifyListeners();
  }

  // ================== Public ==================
  Future<void> refreshActiveRole() async {
    // This method is called to refresh data for the active role
    // Add implementation specific to your app here
    notifyListeners();
  }

  void forceRefresh() => notifyListeners();

  // ================== Helpers ==================
  void _setBusy(bool value) {
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
    notifyListeners();
  }
}
