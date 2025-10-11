// ignore_for_file: avoid_print, prefer_single_quotes

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:talent/core/models/models.dart';
import 'package:talent/core/services/business_access_context.dart';
import 'package:talent/core/services/locator/service_locator.dart';
import 'package:talent/core/services/user_permissions_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._service);

  final ServiceLocator _service;
  final UserPermissionsService _userPermissionsService =
      UserPermissionsService();

  bool _isBusy = false;
  User? _currentUser;
  UserType? _activeRole;
  Timer? _notificationRefreshTimer;

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
  TeamMember? _currentUserTeamMember;
  List<String> _currentUserPermissions = <String>[];
  String? _currentUserPermissionsBusinessId;
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
  List<Conversation> get conversations => _conversations;
  List<Application> get selectedJobApplications => _selectedJobApplications;
  ServiceLocator get service => _service;
  TeamMember? get currentUserTeamMember => _currentUserTeamMember;
  List<String> get currentUserPermissions =>
      List.unmodifiable(_currentUserPermissions);
  bool get isLoadingCurrentUserTeamMember => _isLoadingCurrentUserTeamMember;

  List<String> getCurrentUserPermissions() => currentUserPermissions;

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

  // Attendance management getters
  DateTime get attendanceSelectedDate => _attendanceSelectedDate;
  String get attendanceStatusFilter => _attendanceStatusFilter;
  AttendanceDashboard? get attendanceDashboard => _attendanceDashboard;
  AttendanceDashboardSummary? get attendanceSummary => _attendanceSummary;
  bool get isAttendanceBusy => _isAttendanceBusy;
  Map<String, AttendanceSchedule> get workerAttendanceSchedules =>
      _workerAttendanceSchedules;

  // ================== Authentication ==================
  Future<void> login({
    required String email,
    required String password,
    UserType? type,
  }) async {
    _setBusy(true);
    try {
      _currentUser = await _service.auth.login(
        email: email,
        password: password,
      );
      _activeRole = _currentUser?.type;
      _service.updateAuthToken(_service.auth.authToken);
      _service.updateCurrentUser(_currentUser);
      print('🔑 Stored Auth Token: ${_service.auth.authToken}');

      // Create temporary profile data to prevent loading screen from getting stuck
      if (_currentUser != null && _activeRole == UserType.worker) {
        // Create a basic worker profile with current user data
        _workerProfile = WorkerProfile(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          email: _currentUser!.email,
          phone: '',
          skills: const [],
          experience: '',
          bio: 'Loading profile data...',
          rating: 0.0,
          completedJobs: 0,
          totalEarnings: 0.0,
          languages: const [],
          availability: const [],
          isVerified: false,
          weeklyEarnings: 0.0,
          preferredRadiusMiles: 10.0,
          notificationsEnabled: true,
        );

        // Create basic metrics
        _workerMetrics = const WorkerDashboardMetrics(
          availableJobs: 0,
          activeApplications: 0,
          upcomingShifts: 0,
          completedHours: 0,
          earningsThisWeek: 0.0,
          freeApplicationsRemaining: 3,
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

      if (businessId == null || businessId.isEmpty) {
        businessId = _currentUserPermissionsBusinessId;
      }

      if ((businessId == null || businessId.isEmpty) &&
          _currentUserTeamMember?.businessId.isNotEmpty == true) {
        businessId = _currentUserTeamMember!.businessId;
      }

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

  // ================== Public ==================
  Future<void> refreshActiveRole() async {
    if (_currentUser == null || _activeRole == null) return;

    _setBusy(true);
    try {
      // Fetch data based on active role
      if (_activeRole == UserType.worker) {
        try {
          // For now, just use the placeholder data created during login
          // This ensures the dashboard will not be stuck in loading state

          // In a real implementation, you would fetch actual data from your API:
          // _workerProfile = await fetchWorkerProfile(_currentUser!.id);
          // _workerMetrics = await fetchWorkerMetrics(_currentUser!.id);
          // _workerJobs = await fetchAvailableJobs();

          // Fetch worker applications from API
          try {
            if (_service.authToken == null) {
              print('❌ Cannot fetch applications: No auth token available');
              _workerApplications = [];
            } else {
              print('🔍 Auth token available, fetching applications...');
              _workerApplications =
                  await _service.worker.fetchWorkerApplications('me');
              print(
                  '✅ Loaded ${_workerApplications.length} worker applications');
            }
          } catch (e) {
            print('❌ Error fetching worker applications: $e');
            _workerApplications = []; // Fallback to empty list
          }

          // _workerShifts = await fetchWorkerShifts(_currentUser!.id);

          // For demo purposes, simulate some data:
          _workerProfile ??= WorkerProfile(
            id: _currentUser!.id,
            firstName: _currentUser!.firstName,
            lastName: _currentUser!.lastName,
            email: _currentUser!.email,
            phone: '',
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
            freeApplicationsRemaining: 3,
            isPremium: false,
          );

          // Load actual jobs from API with fallback to mock data
          try {
            _workerJobs =
                await _service.worker.fetchWorkerJobs(_currentUser!.id);
            print(
                'Loaded ${_workerJobs.length} worker jobs in refreshActiveRole');
          } catch (e) {
            print('Error loading worker jobs in refreshActiveRole: $e');
            // Keep empty list if API call fails (fallback is handled in the service)
            _workerJobs = [];
          }
        } catch (e) {
          print('Error fetching worker data: $e');
          // We already have placeholder data from login, so we can continue
        }
      } else if (_activeRole == UserType.employer) {
        try {
          // Create a basic employer profile with current user data if it doesn't exist
          _employerProfile ??= EmployerProfile(
            id: _currentUser!.id,
            companyName: '${_currentUser!.firstName} ${_currentUser!.lastName}',
            description: 'Welcome to your employer dashboard!',
            phone: '(555) 123-4567',
            rating: 4.8,
            totalJobsPosted: 5,
            totalHires: 10,
            activeBusinesses: 1,
          );

          // Create basic employer metrics if they don't exist
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

          // Simulate loading business locations if empty
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

          // Make actual API calls to fetch real data
          try {
            _employerProfile =
                await _service.employer.fetchEmployerProfile(_currentUser!.id);
          } catch (e) {
            print('Error fetching employer profile: $e');
            // Keep using placeholder data if the API call fails
          }

          try {
            _employerMetrics = await _service.employer
                .fetchEmployerDashboardMetrics(_currentUser!.id);
          } catch (e) {
            print('Error fetching employer metrics: $e');
            // Keep using placeholder data if the API call fails
          }

          try {
            // Fetch businesses using the business service
            _businesses = await _service.business.fetchBusinesses();
          } catch (e) {
            print('Error fetching businesses: $e');
            // Keep using placeholder data if the API call fails
          }

          try {
            _employerJobs =
                await _service.employer.fetchEmployerJobs(_currentUser!.id);
          } catch (e) {
            print('Error fetching employer jobs: $e');
            // Keep using placeholder data if the API call fails
          }

          await loadCurrentUserTeamMemberInfo(forceRefresh: true);
        } catch (e) {
          print('Error fetching employer data: $e');
        }
      }

      // Fetch shared data
      try {
        await loadNotifications();
        await loadConversations();
      } catch (e) {
        print('Error fetching shared data: $e');
      }

      // Start periodic notification refresh
      _startNotificationRefresh();
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  /// Start periodic notification refresh every 60 seconds
  void _startNotificationRefresh() {
    _stopNotificationRefresh(); // Stop any existing timer

    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (timer) {
        if (_currentUser != null) {
          loadNotifications();
        } else {
          _stopNotificationRefresh();
        }
      },
    );
  }

  /// Stop notification refresh timer
  void _stopNotificationRefresh() {
    _notificationRefreshTimer?.cancel();
    _notificationRefreshTimer = null;
  }

  @override
  void dispose() {
    _stopNotificationRefresh();
    super.dispose();
  }

  void forceRefresh() => notifyListeners();

  Future<void> loadCurrentUserTeamMemberInfo(
      {bool forceRefresh = false}) async {
    final user = _currentUser;
    if (user == null) {
      _currentUserTeamMember = null;
      _currentUserPermissions = <String>[];
      _currentUserPermissionsBusinessId = null;
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

    final shouldRefresh = forceRefresh ||
        _currentUserPermissionsBusinessId != businessId ||
        _currentUserPermissions.isEmpty;

    if (!shouldRefresh) {
      return;
    }

    if (_isLoadingCurrentUserTeamMember) {
      return;
    }

    _isLoadingCurrentUserTeamMember = true;
    notifyListeners();

    try {
      final teamMember =
          await _userPermissionsService.getUserTeamMemberInfo(businessId);
      _currentUserTeamMember = teamMember;

      if (teamMember != null) {
        final index =
            _teamMembers.indexWhere((member) => member.id == teamMember.id);
        if (index != -1) {
          _teamMembers[index] = teamMember;
        } else {
          _teamMembers.add(teamMember);
        }
      }

      var permissions = teamMember?.permissions ?? <String>[];
      if (permissions.isEmpty) {
        permissions =
            await _userPermissionsService.getUserPermissions(businessId);
      }

      _currentUserPermissions = permissions;
      _currentUserPermissionsBusinessId = businessId;
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
  }) async {
    _setBusy(true);
    try {
      final business = await _service.business.createBusiness(
        name: name,
        description: description,
        street: address,
        city: city,
        state: state,
        postalCode: postalCode,
        phone: phone,
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
  }) async {
    _setBusy(true);
    try {
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
    required String locationDescription,
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
      final location = <String, dynamic>{
        if (locationDescription.isNotEmpty)
          'formattedAddress': locationDescription,
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
        hasOvertime: hasOvertime ?? false,
        overtimeRate: overtimeRate,
        recurrence: recurrence ?? 'one-time',
        workDays: workDays,
      );

      _employerJobs = [..._employerJobs, job];
      notifyListeners();
      return job;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  }) async {
    _setBusy(true);
    try {
      print('🔄 Updating job status via API: $jobId to $status');

      // TODO: Replace with actual API call to update job status
      // Example: PATCH /jobs/{jobId} with { "status": "closed" }
      final uri = Uri.parse('https://dhruvbackend.vercel.app/api/jobs/$jobId');

      final body = {
        'status': status.name,
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
            overtimeRate: job.overtimeRate,
            urgency: job.urgency,
            tags: job.tags,
            workDays: job.workDays,
            isVerificationRequired: job.isVerificationRequired,
            status: status, // Updated status
            postedAt: job.postedAt,
            businessName: job.businessName,
            locationSummary: job.locationSummary,
            applicantsCount: job.applicantsCount,
            distanceMiles: job.distanceMiles,
            hasApplied: job.hasApplied,
            premiumRequired: job.premiumRequired,
          );
        }

        notifyListeners();
      } else {
        print(
            '⚠️ Update job status API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update job status: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error updating job status: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> processJobPostingPayment({
    required String jobId,
    required double amount,
    String? currency,
    String? paymentMethodId,
  }) async {
    _setBusy(true);
    try {
      // Mark job as paid in the list (using a new property or tag)
      // This is a simplified implementation
      print('Processing payment for job: $jobId');
      print('Amount: $amount ${currency ?? 'USD'}');
      print('Payment method: ${paymentMethodId ?? 'default'}');

      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  // ================== Attendance Methods ==================
  Future<void> loadAttendanceDashboard({
    DateTime? date,
    String? status,
  }) async {
    _isAttendanceBusy = true;
    notifyListeners();

    try {
      final targetDate = date ?? _attendanceSelectedDate;
      final targetFilter = status ?? _attendanceStatusFilter;

      _attendanceSelectedDate = targetDate;
      _attendanceStatusFilter = targetFilter;

      // TODO: Replace with actual API call to /attendance/management
      // Example: GET /attendance/management?date=2024-10-01&status=all
      // This should call your backend endpoint and populate real data
      print(
          'Loading attendance dashboard for date: ${targetDate.toIso8601String().split('T')[0]}, status: $targetFilter');

      // For now, create enhanced mock data that matches your backend structure
      final mockRecords = <AttendanceRecord>[
        AttendanceRecord(
          id: 'att_1',
          workerId: 'worker_1',
          jobId: 'job_1',
          businessId: 'business_1',
          scheduledStart: targetDate.copyWith(hour: 9, minute: 0),
          scheduledEnd: targetDate.copyWith(hour: 17, minute: 0),
          status: AttendanceStatus.completed,
          totalHours: 8.0,
          earnings: 120.0,
          isLate: false,
          clockIn: targetDate.copyWith(hour: 8, minute: 55),
          clockOut: targetDate.copyWith(hour: 17, minute: 5),
          workerName: 'John Doe',
          jobTitle: 'Customer Service',
          hourlyRate: 15.0,
          locationSummary: 'Downtown Office',
        ),
        AttendanceRecord(
          id: 'att_2',
          workerId: 'worker_2',
          jobId: 'job_2',
          businessId: 'business_1',
          scheduledStart: targetDate.copyWith(hour: 10, minute: 0),
          scheduledEnd: targetDate.copyWith(hour: 18, minute: 0),
          status: AttendanceStatus.clockedIn,
          totalHours: 0.0,
          earnings: 0.0,
          isLate: true,
          clockIn: targetDate.copyWith(hour: 10, minute: 15),
          workerName: 'Jane Smith',
          jobTitle: 'Sales Associate',
          hourlyRate: 16.0,
          locationSummary: 'Mall Store',
        ),
      ];

      final mockSummary = AttendanceDashboardSummary(
        totalWorkers: mockRecords.length,
        completedShifts: mockRecords
            .where((r) => r.status == AttendanceStatus.completed)
            .length,
        totalHours: mockRecords.fold<double>(0, (sum, r) => sum + r.totalHours),
        totalPayroll: mockRecords.fold<double>(0, (sum, r) => sum + r.earnings),
        lateArrivals: mockRecords.where((r) => r.isLate).length,
      );

      _attendanceDashboard = AttendanceDashboard(
        date: targetDate,
        statusFilter: targetFilter,
        records: mockRecords,
        summary: mockSummary,
      );

      _attendanceSummary = mockSummary;
    } catch (error) {
      print('Error loading attendance dashboard: $error');
    } finally {
      _isAttendanceBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkerAttendanceSchedule({
    required String workerId,
    String? status,
  }) async {
    if (workerId.isEmpty) return;

    _workerScheduleLoading[workerId] = true;
    notifyListeners();

    try {
      final targetFilter = status ?? 'all';

      // TODO: Replace with actual API call
      // For now, create mock data
      final mockDays = <AttendanceScheduleDay>[
        AttendanceScheduleDay(
          date: DateTime.now(),
          records: [
            AttendanceRecord(
              id: 'att_1',
              workerId: 'worker_1',
              jobId: 'job_1',
              businessId: 'business_1',
              scheduledStart: DateTime.now().copyWith(hour: 9, minute: 0),
              scheduledEnd: DateTime.now().copyWith(hour: 17, minute: 0),
              status: AttendanceStatus.scheduled,
              totalHours: 8.0,
              earnings: 120.0,
              isLate: false,
            ),
          ],
          totalHours: 8.0,
          totalEarnings: 120.0,
          scheduledCount: 1,
          completedCount: 0,
        ),
      ];

      final schedule = AttendanceSchedule(
        workerId: workerId,
        statusFilter: targetFilter,
        days: mockDays,
        workerName: 'John Doe',
        totalHours: 8.0,
        totalEarnings: 120.0,
        totalRecords: 1,
      );

      _workerAttendanceSchedules[workerId] = schedule;
    } catch (error) {
      print('Error loading worker schedule: $error');
    } finally {
      _workerScheduleLoading[workerId] = false;
      notifyListeners();
    }
  }

  Future<void> markEmployerAttendanceComplete(String recordId) async {
    _setBusy(true);
    try {
      // TODO: Replace with actual API call
      print('Marking attendance record complete: $recordId');

      // Update local data if needed
      if (_attendanceDashboard != null) {
        final updatedRecords = _attendanceDashboard!.records.map((record) {
          if (record.id == recordId) {
            return AttendanceRecord(
              id: record.id,
              workerId: record.workerId,
              jobId: record.jobId,
              businessId: record.businessId,
              scheduledStart: record.scheduledStart,
              scheduledEnd: record.scheduledEnd,
              status: AttendanceStatus.completed,
              totalHours: record.totalHours,
              earnings: record.earnings,
              isLate: record.isLate,
              clockIn: record.clockIn,
              clockOut: record.clockOut ?? DateTime.now(),
              locationSummary: record.locationSummary,
              jobTitle: record.jobTitle,
              hourlyRate: record.hourlyRate,
              companyName: record.companyName,
              location: record.location,
              workerName: record.workerName,
              workerAvatarUrl: record.workerAvatarUrl,
            );
          }
          return record;
        }).toList();

        _attendanceDashboard =
            _attendanceDashboard!.copyWith(records: updatedRecords);
      }

      notifyListeners();
    } catch (error) {
      print('Error marking attendance complete: $error');
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
      // TODO: Replace with actual API call
      print(
          'Updating attendance hours for record: $attendanceId, hours: $totalHours');

      // Update local data if needed
      if (_attendanceDashboard != null) {
        final updatedRecords = _attendanceDashboard!.records.map((record) {
          if (record.id == attendanceId) {
            final rate = hourlyRate ?? record.hourlyRate ?? 15.0;
            return AttendanceRecord(
              id: record.id,
              workerId: record.workerId,
              jobId: record.jobId,
              businessId: record.businessId,
              scheduledStart: record.scheduledStart,
              scheduledEnd: record.scheduledEnd,
              status: record.status,
              totalHours: totalHours,
              earnings: totalHours * rate,
              isLate: record.isLate,
              clockIn: record.clockIn,
              clockOut: record.clockOut,
              locationSummary: record.locationSummary,
              jobTitle: record.jobTitle,
              hourlyRate: record.hourlyRate,
              companyName: record.companyName,
              location: record.location,
              workerName: record.workerName,
              workerAvatarUrl: record.workerAvatarUrl,
            );
          }
          return record;
        }).toList();

        _attendanceDashboard =
            _attendanceDashboard!.copyWith(records: updatedRecords);
      }

      notifyListeners();
    } catch (error) {
      print('Error updating attendance hours: $error');
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
    _setBusy(true);
    try {
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

      final applications = await _service.employer.fetchEmployerApplications(
        status: status,
        businessId: resolvedBusinessId,
      );

      _employerApplications = applications;
      notifyListeners();
    } catch (error) {
      debugPrint('❌ AppState: failed to refresh employer applications: $error');
      rethrow;
    } finally {
      _setBusy(false);
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
          _employerApplications[index] = Application(
            id: application.id,
            jobId: application.jobId,
            workerId: application.workerId,
            workerName: application.workerName,
            workerExperience: application.workerExperience,
            workerSkills: application.workerSkills,
            status: ApplicationStatus.hired,
            submittedAt: application.submittedAt,
            note: application.note,
          );
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
          _employerApplications[index] = Application(
            id: application.id,
            jobId: application.jobId,
            workerId: application.workerId,
            workerName: application.workerName,
            workerExperience: application.workerExperience,
            workerSkills: application.workerSkills,
            status: status,
            submittedAt: application.submittedAt,
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

  // ================== Worker Methods ==================

  // Worker Attendance Methods
  Future<void> refreshWorkerAttendance() async {
    if (_currentUser?.type != UserType.worker) return;

    _setBusy(true);
    try {
      // TODO: Replace with actual API call
      print('Refreshing worker attendance data');

      // For now, just trigger a rebuild with existing data
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
      // TODO: Replace with actual API call
      print('Clocking in worker attendance: $recordId');

      // Find and update the attendance record
      final recordIndex = _workerAttendance.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        final record = _workerAttendance[recordIndex];
        final updatedRecord = AttendanceRecord(
          id: record.id,
          workerId: record.workerId,
          jobId: record.jobId,
          businessId: record.businessId,
          scheduledStart: record.scheduledStart,
          scheduledEnd: record.scheduledEnd,
          status: AttendanceStatus.clockedIn,
          totalHours: record.totalHours,
          earnings: record.earnings,
          isLate: record.isLate,
          clockIn: DateTime.now(),
          clockOut: record.clockOut,
          locationSummary: record.locationSummary,
          jobTitle: record.jobTitle,
          hourlyRate: record.hourlyRate,
          companyName: record.companyName,
          location: record.location,
          workerName: record.workerName,
          workerAvatarUrl: record.workerAvatarUrl,
        );

        _workerAttendance[recordIndex] = updatedRecord;
        notifyListeners();
        return updatedRecord;
      } else {
        throw Exception('Attendance record not found');
      }
    } catch (error) {
      print('Error clocking in worker attendance: $error');
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
      // TODO: Replace with actual API call
      print('Clocking out worker attendance: $recordId');

      // Find and update the attendance record
      final recordIndex = _workerAttendance.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        final record = _workerAttendance[recordIndex];
        final clockOut = DateTime.now();

        // Calculate total hours and earnings if clock in exists
        double totalHours = record.totalHours;
        double earnings = record.earnings;
        if (record.clockIn != null) {
          totalHours = clockOut.difference(record.clockIn!).inMinutes / 60.0;
          earnings = totalHours * hourlyRate;
        }

        final updatedRecord = AttendanceRecord(
          id: record.id,
          workerId: record.workerId,
          jobId: record.jobId,
          businessId: record.businessId,
          scheduledStart: record.scheduledStart,
          scheduledEnd: record.scheduledEnd,
          status: AttendanceStatus.completed,
          totalHours: totalHours,
          earnings: earnings,
          isLate: record.isLate,
          clockIn: record.clockIn,
          clockOut: clockOut,
          locationSummary: record.locationSummary,
          jobTitle: record.jobTitle,
          hourlyRate: hourlyRate,
          companyName: record.companyName,
          location: record.location,
          workerName: record.workerName,
          workerAvatarUrl: record.workerAvatarUrl,
        );

        _workerAttendance[recordIndex] = updatedRecord;
        notifyListeners();
        return updatedRecord;
      } else {
        throw Exception('Attendance record not found');
      }
    } catch (error) {
      print('Error clocking out worker attendance: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  // Worker Job Methods
  Future<void> loadWorkerJobs(String workerId) async {
    _setBusy(true);
    try {
      print('Loading worker jobs for: $workerId');

      // Fetch available jobs from the API
      _workerJobs = await _service.worker.fetchWorkerJobs(workerId);
      print('Loaded ${_workerJobs.length} worker jobs');

      notifyListeners();
    } catch (error) {
      print('Error loading worker jobs: $error');
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> submitWorkerApplication({
    required String jobId,
    String? message,
  }) async {
    if (_currentUser?.type != UserType.worker) {
      throw Exception('Only workers can submit applications');
    }

    _setBusy(true);
    try {
      print('Submitting worker application for job: $jobId');
      if (message != null) {
        print('Application message: $message');
      }

      // Use the actual API service to submit the application
      final application = await service.worker.submitJobApplication(
        workerId: _currentUser!.id,
        jobId: jobId,
        message: message,
      );

      // Add the new application to our local list
      _workerApplications.add(application);

      // Update the job's application count if we have it locally
      final jobIndex = _workerJobs.indexWhere((job) => job.id == jobId);
      if (jobIndex != -1) {
        final updatedJob = JobPosting(
          id: _workerJobs[jobIndex].id,
          title: _workerJobs[jobIndex].title,
          description: _workerJobs[jobIndex].description,
          employerId: _workerJobs[jobIndex].employerId,
          businessId: _workerJobs[jobIndex].businessId,
          hourlyRate: _workerJobs[jobIndex].hourlyRate,
          scheduleStart: _workerJobs[jobIndex].scheduleStart,
          scheduleEnd: _workerJobs[jobIndex].scheduleEnd,
          recurrence: _workerJobs[jobIndex].recurrence,
          overtimeRate: _workerJobs[jobIndex].overtimeRate,
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
      loadNotifications();

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
  }) async {
    if (_workerProfile == null) return;

    _setBusy(true);
    try {
      // Update the worker profile with new values
      _workerProfile = WorkerProfile(
        id: _workerProfile!.id,
        firstName: firstName ?? _workerProfile!.firstName,
        lastName: lastName ?? _workerProfile!.lastName,
        email: _workerProfile!.email,
        phone: phone ?? _workerProfile!.phone,
        skills: skills ?? _workerProfile!.skills,
        experience: experience ?? _workerProfile!.experience,
        bio: bio ?? _workerProfile!.bio,
        rating: _workerProfile!.rating,
        completedJobs: _workerProfile!.completedJobs,
        totalEarnings: _workerProfile!.totalEarnings,
        languages: languages ?? _workerProfile!.languages,
        availability: availability ?? _workerProfile!.availability,
        isVerified: _workerProfile!.isVerified,
        weeklyEarnings: _workerProfile!.weeklyEarnings,
        preferredRadiusMiles: _workerProfile!.preferredRadiusMiles,
        notificationsEnabled:
            notificationsEnabled ?? _workerProfile!.notificationsEnabled,
      );

      notifyListeners();
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
      // TODO: Replace with actual API call
      print('Withdrawing worker application: $applicationId');
      if (message != null) {
        print('Withdrawal message: $message');
      }

      // Update the application status in the local list
      final index =
          _workerApplications.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        final application = _workerApplications[index];
        _workerApplications[index] = Application(
          id: application.id,
          jobId: application.jobId,
          workerId: application.workerId,
          workerName: application.workerName,
          workerExperience: application.workerExperience,
          workerSkills: application.workerSkills,
          status: ApplicationStatus
              .rejected, // Withdrawn applications are marked as rejected
          submittedAt: application.submittedAt,
          note: message ?? application.note,
        );
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
    _currentUserPermissions = <String>[];
    _currentUserPermissionsBusinessId = null;
    _isLoadingCurrentUserTeamMember = false;
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
        final data = json.decode(response.body);
        return JobPosting.fromJson(data['job'] as Map<String, dynamic>);
      } else {
        print('Failed to fetch job details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching job details: $e');
      return null;
    }
  }

  Future<bool> scheduleAttendanceForWorker({
    required String workerId,
    required String jobId,
    required DateTime startDate,
    required String location,
    required double hoursScheduled,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://dhruvbackend.vercel.app/api/attendance/schedule'),
        headers: {
          'Content-Type': 'application/json',
          if (_service.authToken != null)
            'Authorization': 'Bearer ${_service.authToken}',
        },
        body: json.encode({
          'workerId': workerId,
          'jobId': jobId,
          'startDate': startDate.toIso8601String(),
          'location': location,
          'hoursScheduled': hoursScheduled,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        print('Attendance scheduled successfully');
        // Refresh relevant data if needed
        notifyListeners();
        return true;
      } else {
        print('Failed to schedule attendance: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error scheduling attendance: $e');
      return false;
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
}
