import 'package:talent/core/models/models.dart';

abstract class WorkerService {
  /// Fetch a worker's profile
  Future<WorkerProfile> fetchWorkerProfile(String workerId);

  /// Update worker profile details
  Future<WorkerProfile> updateWorkerProfile({
    required String workerId,
    String? firstName,
    String? lastName,
    String? bio,
    List<String>? skills,
    String? experience,
    List<String>? languages,
    String? phone,
    List<Map<String, dynamic>>? availability,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    double? preferredRadiusMiles,
  });

  /// Fetch jobs available to a worker
  ///
  /// [status] defaults to `active` to limit results to jobs the worker can act on.
  /// Passing `'all'` (case-insensitive) skips the status filter. When [fallbackToAll]
  /// is `true`, the implementation may refetch without the filter if the filtered
  /// call fails or returns no data.
  Future<List<JobPosting>> fetchWorkerJobs(
    String workerId, {
    String status = 'active',
    bool fallbackToAll = true,
  });

  /// Fetch a specific job by ID
  Future<JobPosting?> fetchJobById(String jobId);

  /// Fetch a worker's job applications
  Future<List<Application>> fetchWorkerApplications(String workerId);

  /// Submit a new job application for the authenticated worker
  Future<Application> submitJobApplication({
    required String workerId,
    required String jobId,
    String? message,
  });

  /// Withdraw an existing job application for the authenticated worker
  Future<Application> withdrawApplication({
    required String applicationId,
    String? message,
  });

  /// Fetch a worker's attendance records
  Future<List<AttendanceRecord>> fetchWorkerAttendance(String workerId);

  /// Fetch a worker's attendance schedule grouped by date
  Future<AttendanceSchedule> fetchWorkerAttendanceSchedule({
    required String workerId,
    String status = 'all',
    DateTime? from,
    DateTime? to,
    String? jobId,
    String? businessId,
  });

  /// Fetch a worker's scheduled shifts
  Future<List<Shift>> fetchWorkerShifts(String workerId);

  /// Fetch shift swap requests for a worker
  Future<List<SwapRequest>> fetchSwapRequests(String workerId);

  /// Fetch dashboard metrics for a worker
  Future<WorkerDashboardMetrics> fetchWorkerDashboardMetrics(String workerId);

  /// Fetch employment history for the worker
  Future<List<EmploymentRecord>> fetchEmploymentHistory(String workerId);

  Future<AttendanceRecord> clockIn(
    String recordId, {
    required Location location,
  });

  Future<AttendanceRecord> clockOut(
    String recordId, {
    required Location location,
    double? hourlyRate,
  });
  Future<AttendanceRecord> updateAttendance(
      String recordId, Map<String, dynamic> body);

  Future<SwapRequest> requestSwap({
    required String shiftId,
    required String toWorkerId,
    String? message,
  });

  Future<SwapRequest> respondSwap({
    required String swapId,
    required String status,
    String? message,
  });

  /// Submit feedback for an employer
  Future<EmployerFeedback> submitEmployerFeedback({
    required String workerId,
    required String employerId,
    required int rating,
    String? comment,
    String? jobId,
  });

  /// Fetch submitted feedback by the worker
  Future<List<EmployerFeedback>> fetchWorkerFeedback(String workerId);
}
