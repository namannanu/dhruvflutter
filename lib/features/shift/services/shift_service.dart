import 'package:talent/core/models/models.dart';

abstract class ShiftService {
  /// Fetch shift swap requests for a worker
  Future<List<SwapRequest>> fetchSwapRequests(String workerId);

  /// Create a new shift swap request
  Future<SwapRequest> createSwapRequest({
    required String shiftId,
    required String fromWorkerId,
    required String toWorkerId,
    String? message,
  });

  /// Update a shift swap request status
  Future<void> updateSwapRequestStatus({
    required String swapRequestId,
    required SwapRequestStatus status,
    String? message,
  });

  /// Create an attendance record for a shift
  Future<AttendanceRecord> createAttendanceRecord({
    required String shiftId,
    required String workerId,
    required String businessId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    String? locationSummary,
  });

  /// Update an attendance record
  Future<void> updateAttendanceRecord({
    required String attendanceId,
    DateTime? clockIn,
    DateTime? clockOut,
    AttendanceStatus? status,
    double? totalHours,
    double? earnings,
    bool? isLate,
  });
}
