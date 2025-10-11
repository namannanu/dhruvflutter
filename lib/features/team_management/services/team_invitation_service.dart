// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_token_manager.dart';

class TeamInvitationService {
  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  /// Get auth token from storage or parameter
  Future<String?> _getEffectiveAuthToken(String? providedToken) async {
    if (providedToken != null && providedToken.isNotEmpty) {
      return providedToken;
    }
    return await AuthTokenManager.instance.getAuthToken();
  }

  /// Invite a team member using direct HTTP calls
  Future<Map<String, dynamic>?> inviteTeamMember({
    required String userEmail,
    required String businessId,
    String accessLevel = 'view_only',
    String role = 'staff',
    Map<String, bool> permissions = const {},
    String? authToken,
  }) async {
    try {
      print('🚀 TEAM INVITATION REQUEST');
      print('📧 Email: $userEmail');
      print('🏢 Business ID: $businessId');
      print('🔑 Access Level: $accessLevel');
      print('👤 Role: $role');
      print('🛡️ Permissions: $permissions');

      // Use provided token or get from storage
      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return null;
      }

      final url = Uri.parse('$baseUrl/team/grant-access');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final requestBody = {
        'userEmail': userEmail,
        'accessLevel': accessLevel,
        'role': role,
        'businessContext': {
          'businessId': businessId,
        },
        'permissions': permissions,
      };

      print('📦 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Team invitation successful!');

        // Check if notification was sent
        final message = data['message'] as String? ?? '';
        if (message.toLowerCase().contains('notification')) {
          print('📧 Notification sent to user');
        } else {
          print('⚠️ User may not exist in system - no notification sent');
          print('💡 Invitation created but user needs to sign up first');
        }

        return data;
      } else {
        print('❌ Team invitation failed: ${response.statusCode}');
        print('❌ Error: ${response.body}');

        // Try to parse error message
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception('Invitation failed: $errorMessage');
        } catch (_) {
          throw Exception(
              'Invitation failed with status ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('💥 Exception in inviteTeamMember: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get the list of team members
  Future<List<Map<String, dynamic>>> getTeamMembers({String? authToken}) async {
    try {
      print('📋 FETCHING TEAM MEMBERS');

      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return [];
      }

      final url = Uri.parse('$baseUrl/team/my-team');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      print('📡 Team Response Status: ${response.statusCode}');
      print('📄 Team Response Body: ${response.body}');

      if (response.statusCode == 204) {
        return [];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Check if data is already a list or contains a list
        if (data['data'] is List) {
          final teamList = data['data'] as List<dynamic>;
          return teamList.cast<Map<String, dynamic>>();
        } else if (data['data'] is Map && data['data']['teamMembers'] is List) {
          // Handle nested structure
          final teamList = data['data']['teamMembers'] as List<dynamic>;
          return teamList.cast<Map<String, dynamic>>();
        } else if (data is List) {
          // Handle direct list response - this case shouldn't happen since we decoded as Map
          return (data as List).cast<Map<String, dynamic>>();
        } else {
          print('⚠️ Unexpected data structure: ${data.runtimeType}');
          print('📄 Data content: $data');
          return [];
        }
      } else {
        print('❌ Failed to fetch team members: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('💥 Exception in getTeamMembers: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get the user's access records (businesses where they have been granted access)
  Future<List<Map<String, dynamic>>> getMyAccess({String? authToken}) async {
    try {
      print('🔍 FETCHING MY ACCESS RECORDS');

      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return [];
      }

      final url = Uri.parse('$baseUrl/team/my-access');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      print('📡 My Access Response Status: ${response.statusCode}');
      print('📄 My Access Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['data'] is List) {
          final accessList = data['data'] as List<dynamic>;
          return accessList.cast<Map<String, dynamic>>();
        } else {
          print('⚠️ Unexpected data structure: ${data.runtimeType}');
          return [];
        }
      } else {
        print('❌ Failed to fetch my access: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('💥 Exception in getMyAccess: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Remove a team member
  Future<bool> removeTeamMember(String accessId, {String? authToken}) async {
    try {
      print('🗑️ REMOVING TEAM MEMBER: $accessId');

      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return false;
      }

      final url = Uri.parse('$baseUrl/team/access/$accessId');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(url, headers: headers);

      print('📡 Remove Response Status: ${response.statusCode}');
      print('📄 Remove Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Team member removed successfully!');
        return true;
      } else {
        print('❌ Failed to remove team member: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Exception in removeTeamMember: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Fetch team-related notifications (invites, updates)
  Future<List<Map<String, dynamic>>> getTeamNotifications({String? authToken}) async {
    try {
      print('🔔 FETCHING TEAM NOTIFICATIONS');

      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return [];
      }

      final url = Uri.parse('$baseUrl/team/notifications');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      print('📡 Notifications Response Status: ${response.statusCode}');
      print('📄 Notifications Response Body: ${response.body}');

      if (response.statusCode == 204) {
        return [];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List<dynamic>? ?? const [];
        return items.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('💥 Exception in getTeamNotifications: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Mark a team notification as read
  Future<bool> markNotificationRead(String notificationId, {String? authToken}) async {
    try {
      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return false;
      }

      final url = Uri.parse('$baseUrl/team/notifications/$notificationId/read');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.patch(url, headers: headers);

      print('📡 Mark Read Status: ${response.statusCode}');
      print('📄 Mark Read Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Notification marked as read');
        return true;
      } else {
        print('❌ Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Exception in markNotificationRead: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update team member access
  Future<Map<String, dynamic>?> updateTeamMemberAccess({
    required String accessId,
    String? accessLevel,
    String? role,
    Map<String, bool>? permissions,
    String? authToken,
  }) async {
    try {
      print('✏️ UPDATING TEAM MEMBER ACCESS: $accessId');

      final token = await _getEffectiveAuthToken(authToken);
      if (token == null) {
        print('❌ No auth token available');
        return null;
      }

      final requestBody = <String, dynamic>{};
      if (accessLevel != null) requestBody['accessLevel'] = accessLevel;
      if (role != null) requestBody['role'] = role;
      if (permissions != null) requestBody['permissions'] = permissions;

      print('📦 Update Body: ${json.encode(requestBody)}');

      final url = Uri.parse('$baseUrl/team/access/$accessId');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      print('📡 Update Response Status: ${response.statusCode}');
      print('📄 Update Response Body: ${response.body}');

      if (response.statusCode == 204) {
        return {}; // Return empty map instead of empty list
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Team member access updated successfully!');
        return data;
      } else {
        print('❌ Failed to update team member access: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('💥 Exception in updateTeamMemberAccess: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Set the auth token to use for API calls
  /// Call this method with your current user's token
  void setAuthToken(String token) {
    _authToken = token;
  }

  String? _authToken;

  String? getStoredAuthToken() {
    return _authToken;
  }
}
