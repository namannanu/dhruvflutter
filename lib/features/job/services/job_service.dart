import 'package:talent/core/models/models.dart';

abstract class JobService {
  Future<JobPosting> createJob({
    required String title,
    required String description,
    required double hourlyRate,
    required String businessId,
    required DateTime start,
    required DateTime end,
    List<String>? tags,
    String urgency = 'medium',
    bool verificationRequired = false,
    Map<String, dynamic>? location,
    JobOvertime? overtime,
    String recurrence = 'one-time',
    List<String>? workDays,
    bool autoPublish = true,
  });

  Future<void> processJobPostingPayment({
    required String jobId,
    required double amount,
    required String currency,
    required String paymentMethodId,
  });

  Future<List<Application>> fetchJobApplications(String jobId);

  Future<Application> applyForJob({
    required String jobId,
    required String workerId,
    String? note,
  });

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
    String? note,
  });

  Future<void> updateJobStatus({
    required String jobId,
    required JobStatus status,
  });

  Future<JobPosting> updateJob({
    required String jobId,
    String? title,
    String? description,
    double? hourlyRate,
    DateTime? start,
    DateTime? end,
    List<String>? tags,
    String? urgency,
    bool? verificationRequired,
    bool? hasOvertime,
    double? overtimeRate,
    String? recurrence,
    List<String>? workDays,
  });
}
