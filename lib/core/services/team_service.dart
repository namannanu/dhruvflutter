import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_access.dart';

class TeamService {
  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResponse> _handleResponse(http.Response response) async {
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        message: (data['message'] ?? 'Success') as String,
        data: data['data'],
      );
    } else {
      return ApiResponse(
        success: false,
        message: (data['message'] ?? 'Unknown error') as String,
        data: data,
        statusCode: response.statusCode,
      );
    }
  }

  /// Grant team access to a user with enhanced parameters
  static Future<ApiResponse> grantTeamAccess({
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
    final headers = await _getHeaders();

    final Map<String, dynamic> requestBody = {
      if (userEmail != null) 'userEmail': userEmail,
      if (employeeId != null) 'employeeId': employeeId,
      if (managedUserId != null) 'managedUserId': managedUserId,
      if (managedUserEmail != null) 'managedUserEmail': managedUserEmail,
      if (targetUserId != null) 'targetUserId': targetUserId,
      'accessLevel': accessLevel,
      if (role != null) 'role': role,
      if (permissions != null) 'permissions': permissions.toJson(),
      if (accessScope != null) 'accessScope': accessScope,
      if (businessContext != null) 'businessContext': businessContext,
      if (restrictions != null) 'restrictions': restrictions,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      if (status != null) 'status': status,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/team/grant-access'),
      headers: headers,
      body: json.encode(requestBody),
    );

    return await _handleResponse(response);
  }

  /// Get all team members managed by the current user
  static Future<List<TeamAccess>> getMyTeamMembers(String userId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/team/my-team'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      final List<dynamic> teamData = apiResponse.data as List<dynamic>;
      return teamData
          .map((e) => TeamAccess.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Get all access rights granted to the current user
  static Future<List<TeamAccess>> getMyManagedAccess(String userId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/team/my-access'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      final List<dynamic> accessData = apiResponse.data as List<dynamic>;
      return accessData
          .map((e) => TeamAccess.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Check access rights for a specific user by email
  static Future<Map<String, dynamic>> checkTeamAccessByEmail({
    required String email,
    String? permission,
  }) async {
    final headers = await _getHeaders();

    String endpoint = '$baseUrl/team/check-access/$email';
    if (permission != null) {
      endpoint += '?permission=$permission';
    }

    final response = await http.get(
      Uri.parse(endpoint),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      return apiResponse.data as Map<String, dynamic>;
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Update team access permissions
  static Future<ApiResponse> updateTeamAccess({
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
    final headers = await _getHeaders();
    final body = <String, dynamic>{};

    if (accessLevel != null) body['accessLevel'] = accessLevel;
    if (role != null) body['role'] = role;
    if (permissions != null) body['permissions'] = permissions.toJson();
    if (status != null) body['status'] = status;
    if (businessContext != null) body['businessContext'] = businessContext;
    if (expiresAt != null) body['expiresAt'] = expiresAt.toIso8601String();
    if (restrictions != null) body['restrictions'] = restrictions;
    if (reason != null) body['reason'] = reason;
    if (notes != null) body['notes'] = notes;

    final response = await http.patch(
      Uri.parse('$baseUrl/team/access/$identifier'),
      headers: headers,
      body: json.encode(body),
    );

    return await _handleResponse(response);
  }

  /// Revoke team access
  static Future<ApiResponse> revokeTeamAccess({
    required String identifier,
    String? reason,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;

    final response = await http.delete(
      Uri.parse('$baseUrl/team/access/$identifier'),
      headers: headers,
      body: json.encode(body),
    );

    return await _handleResponse(response);
  }

  /// Get access report for a user
  static Future<TeamAccessReport> getAccessReport(String userId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/team/report/$userId'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      return TeamAccessReport.fromJson(
          apiResponse.data as Map<String, dynamic>);
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Search for users by name, email, or phone
  static Future<List<TeamMember>> searchUsers(String query) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      final List<dynamic> userList =
          (apiResponse.data as Map<String, dynamic>)['users'] as List<dynamic>;
      return userList
          .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Get user profile by userId
  static Future<TeamMember?> getUserProfile(String userId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/users/profile/$userId'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      return TeamMember.fromJson(apiResponse.data as Map<String, dynamic>);
    } else if (apiResponse.statusCode == 404) {
      return null; // User not found
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Validate if a user is at the correct work location
  static Future<bool> validateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? businessId,
    String? workLocationId,
  }) async {
    final headers = await _getHeaders();
    final body = {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      if (businessId != null) 'businessId': businessId,
      if (workLocationId != null) 'workLocationId': workLocationId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/attendance/validate-location'),
      headers: headers,
      body: json.encode(body),
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      return (apiResponse.data as Map<String, dynamic>)['isValid'] as bool;
    } else {
      throw Exception(apiResponse.message);
    }
  }

  /// Get user data by userId (for team members with access)
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/users/data/$userId'),
      headers: headers,
    );

    final apiResponse = await _handleResponse(response);

    if (apiResponse.success) {
      return apiResponse.data as Map<String, dynamic>;
    } else if (apiResponse.statusCode == 404) {
      return null; // User not found
    } else {
      throw Exception(apiResponse.message);
    }
  }
}
