import 'package:talent/core/models/models.dart';

abstract class EmployerService {
  /// Fetch an employer's profile
  Future<EmployerProfile> fetchEmployerProfile(
    String employerId, {
    String? businessId,
  });

  /// Fetch dashboard metrics for an employer
  Future<EmployerDashboardMetrics> fetchEmployerDashboardMetrics(
    String employerId, {
    String? businessId,
  });

  /// Fetch all jobs posted by an employer
  Future<List<JobPosting>> fetchEmployerJobs(
    String employerId, {
    String? businessId,
  });

  /// Fetch business locations owned by this employer
  Future<List<BusinessLocation>> fetchBusinessLocations(String ownerId);

  /// Fetch applications submitted to the employer's jobs
  Future<List<Application>> fetchEmployerApplications({
    ApplicationStatus? status,
    int? limit,
    int? page,
    String? businessId,
  });

  /// Update the status of an application (e.g. reject, move to hired)
  Future<Application> updateEmployerApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? message,
    String? businessId,
  });

  /// Hire an applicant using the dedicated endpoint
  Future<Application> hireApplicant(String applicationId,
      {DateTime? startDate, String? businessId});

  /// Attendance management endpoints
  Future<AttendanceDashboard> fetchAttendanceDashboard({
    required DateTime date,
    String status = 'all',
  });

  Future<AttendanceRecord> scheduleAttendanceRecord({
    required String workerId,
    required String jobId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required double hourlyRate,
    String? notes,
  });

  Future<AttendanceRecord> markAttendanceComplete(String attendanceId);

  Future<AttendanceRecord> updateAttendanceHours({
    required String attendanceId,
    required double totalHours,
    double? hourlyRate,
  });

  Future<EmploymentRecord> updateEmploymentWorkLocation({
    required String workerId,
    required String employmentId,
    Map<String, dynamic>? location,
    bool clear,
  });
}
