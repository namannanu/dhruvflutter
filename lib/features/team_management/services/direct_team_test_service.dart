// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectTeamTestService {
  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  /// Test function to directly call the team invitation API
  static Future<Map<String, dynamic>> testTeamInvitation({
    required String authToken,
    required String email,
    required String businessId,
    String role = 'staff',
    String accessLevel = 'view_only',
  }) async {
    try {
      print('🔥 DIRECT API TEST - TEAM INVITATION');
      print('📧 Email: $email');
      print('🏢 Business ID: $businessId');
      print('👤 Role: $role');
      print('🔑 Access Level: $accessLevel');
      print('🎫 Auth Token: ${authToken.substring(authToken.length - 10)}');

      final url = Uri.parse('$baseUrl/team/grant-access');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final body = {
        'userEmail': email,
        'accessLevel': accessLevel,
        'role': role,
        'businessContext': {
          'businessId': businessId,
        },
        'permissions': <String, bool>{},
      };

      print('🌐 Request URL: $url');
      print('📦 Request Headers: $headers');
      print('📦 Request Body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body: ${response.body}');

      final statusCode = response.statusCode;

      if (statusCode == 200 || statusCode == 201) {
        final decoded = json.decode(response.body);
        final result = decoded is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded)
            : {
                'status': 'success',
                'data': decoded,
              };

        result['httpStatus'] = statusCode;

        print('✅ SUCCESS! Team invitation sent successfully!');
        print('✅ Response Data: $result');

        return result;
      }

      print('❌ FAILED! Status: $statusCode');
      print('❌ Error: ${response.body}');

      try {
        final errorData = json.decode(response.body);
        print('❌ Parsed Error: $errorData');
      } catch (e) {
        print('❌ Could not parse error response');
      }

      throw Exception(
        'Failed to send team invitation: $statusCode ${response.body}',
      );
    } catch (e, stackTrace) {
      print('💥 Exception occurred: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Test function to get current team members
  static Future<Map<String, dynamic>> getTeamMembers(String authToken) async {
    try {
      print('\n🔍 FETCHING TEAM MEMBERS');

      final url = Uri.parse('$baseUrl/team/my-team');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('🌐 Request URL: $url');
      print('📦 Request Headers: $headers');

      final response = await http.get(url, headers: headers);

      final statusCode = response.statusCode;
      print('📡 Team Response Status: $statusCode');
      print('📄 Team Response Body: ${response.body}');

      if (statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final result = Map<String, dynamic>.from(decoded);
          result['httpStatus'] = statusCode;

          print('✅ Team members fetched successfully!');
          print('✅ Team Data: $result');

          final teamList = result['data'] as List? ?? [];
          print('👥 Total team members: ${teamList.length}');

          for (int i = 0; i < teamList.length; i++) {
            final member = teamList[i] as Map<String, dynamic>? ?? {};
            print(
                '👤 Member ${i + 1}: ${member['userEmail']} - ${member['status']} - ${member['role']}');
          }

          return result;
        } else {
          throw const FormatException('Unexpected response structure');
        }
      } else {
        throw Exception(
          'Failed to fetch team members: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('💥 Exception in getTeamMembers: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Test function to check user access
  static Future<Map<String, dynamic>> checkUserAccess(String authToken) async {
    try {
      print('\n🔐 CHECKING USER ACCESS');

      final url = Uri.parse('$baseUrl/team/my-access');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('🌐 Request URL: $url');

      final response = await http.get(url, headers: headers);

      print('📡 Access Response Status: ${response.statusCode}');
      print('📄 Access Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final result = decoded is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded)
            : {'status': 'success', 'data': decoded};

        result['httpStatus'] = response.statusCode;

        print('✅ User access fetched successfully!');
        print('✅ Access Data: $result');
        return result;
      }

      print('❌ Failed to fetch user access: ${response.statusCode}');
      throw Exception(
        'Failed to fetch user access: ${response.statusCode} ${response.body}',
      );
    } catch (e, stackTrace) {
      print('💥 Exception in checkUserAccess: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update a specific team access record
  static Future<Map<String, dynamic>> updateTeamAccess({
    required String authToken,
    required String identifier,
    required Map<String, dynamic> updates,
  }) async {
    final filteredPayload = <String, dynamic>{
      for (final entry in updates.entries)
        if (entry.value != null &&
            (entry.value is! String || (entry.value as String).trim().isNotEmpty))
          entry.key: entry.value is String ? (entry.value as String).trim() : entry.value,
    };

    if (filteredPayload.isEmpty) {
      throw ArgumentError('At least one update field must be provided');
    }

    try {
      final encodedIdentifier = Uri.encodeComponent(identifier);

      print('\n✏️ UPDATING TEAM ACCESS ($identifier)');
      print('📦 Payload: $filteredPayload');

      final url = Uri.parse('$baseUrl/team/access/$encodedIdentifier');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(filteredPayload),
      );

      print('📡 Update Status: ${response.statusCode}');
      print('📄 Update Body: ${response.body}');

      dynamic decoded;
      if (response.body.isNotEmpty) {
        decoded = json.decode(response.body);
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = decoded is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded)
            : {'status': 'success', 'data': decoded};
        result['httpStatus'] = response.statusCode;
        result['responseHeaders'] = response.headers;
        result['rawBody'] = response.body;
        return result;
      }

      final errorMessage = decoded is Map<String, dynamic>
          ? decoded['message'] ?? decoded['error']
          : (response.body.isEmpty ? 'Unknown error' : response.body);
      throw Exception(
        'Failed to update team access (${response.statusCode}): $errorMessage',
      );
    } catch (e, stackTrace) {
      print('💥 Exception in updateTeamAccess: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Revoke (remove) a specific team access record
  static Future<Map<String, dynamic>> revokeTeamAccess({
    required String authToken,
    required String identifier,
    String? reason,
  }) async {
    final payload = <String, dynamic>{
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };

    try {
      final encodedIdentifier = Uri.encodeComponent(identifier);

      print('\n🗑️ REVOKING TEAM ACCESS ($identifier)');
      if (payload.isNotEmpty) {
        print('📦 Revoke payload: $payload');
      }

      final url = Uri.parse('$baseUrl/team/access/$encodedIdentifier');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http.delete(
        url,
        headers: headers,
        body: payload.isEmpty ? null : json.encode(payload),
      );

      print('📡 Revoke Status: ${response.statusCode}');
      print('📄 Revoke Body: ${response.body}');

      dynamic decoded;
      if (response.body.isNotEmpty) {
        decoded = json.decode(response.body);
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = decoded is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded)
            : {'status': 'success', 'data': decoded};
        result['httpStatus'] = response.statusCode;
        result['responseHeaders'] = response.headers;
        result['rawBody'] = response.body;
        return result;
      }

      final errorMessage = decoded is Map<String, dynamic>
          ? decoded['message'] ?? decoded['error']
          : (response.body.isEmpty ? 'Unknown error' : response.body);
      throw Exception(
        'Failed to revoke team access (${response.statusCode}): $errorMessage',
      );
    } catch (e, stackTrace) {
      print('💥 Exception in revokeTeamAccess: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
