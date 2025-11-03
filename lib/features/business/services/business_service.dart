import 'package:talent/core/models/analytics.dart';
import 'package:talent/core/models/models.dart' hide TeamMember;
import 'package:talent/core/models/team_access.dart';

abstract class BusinessService {
  Future<BusinessLocation> createBusiness({
    required String name,
    required String description,
    required String street,
    required String city,
    required String state,
    required String postalCode,
    String? phone,
    String? logoUrl,
    String? logoSmall,
    String? logoMedium,
    String? logoLarge,
    // Google Places API location data
    double? latitude,
    double? longitude,
    String? placeId,
    String? formattedAddress,
    double? allowedRadius,
    String? locationName,
    String? locationNotes,
  });

  Future<void> updateBusiness(
    String? businessId, {
    String? name,
    String? description,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    bool? isActive,
    String? logoUrl,
    String? logoSmall,
    String? logoMedium,
    String? logoLarge,
    double? allowedRadius,
  });

  /// Delete a business location
  Future<void> deleteBusiness(String? businessId);

  /// Get budget overview for a business
  Future<BudgetOverview> fetchBudget(String? businessId);

  /// Get team members for a business
  Future<List<TeamMember>> fetchTeamMembers(String? businessId);

  /// Get analytics summary for a business
  Future<AnalyticsSummary> fetchAnalyticsSummary(String? businessId);

  /// Get attendance records for a business
  Future<List<AttendanceRecord>> fetchBusinessAttendance(String? businessId);

  /// ✅ Fetch all businesses for the logged-in employer
  Future<List<BusinessLocation>> fetchBusinesses();

  /// ✅ Fetch a single business by ID
  Future<BusinessLocation?> fetchBusinessById(String? businessId);
}
