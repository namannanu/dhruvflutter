// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectTeamTestService {
  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  /// Test function to directly call the team invitation API
  static Future<void> testTeamInvitation({
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ SUCCESS! Team invitation sent successfully!');
        print('✅ Response Data: $data');

        // Test getting team members
        await getTeamMembers(authToken);
      } else {
        print('❌ FAILED! Status: ${response.statusCode}');
        print('❌ Error: ${response.body}');

        try {
          final errorData = json.decode(response.body);
          print('❌ Parsed Error: $errorData');
        } catch (e) {
          print('❌ Could not parse error response');
        }
      }
    } catch (e, stackTrace) {
      print('💥 Exception occurred: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }

  /// Test function to get current team members
  static Future<void> getTeamMembers(String authToken) async {
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

      print('📡 Team Response Status: ${response.statusCode}');
      print('📄 Team Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Team members fetched successfully!');
        print('✅ Team Data: $data');

        final teamList = data['data'] as List? ?? [];
        print('👥 Total team members: ${teamList.length}');

        for (int i = 0; i < teamList.length; i++) {
          final member = teamList[i];
          print(
              '👤 Member ${i + 1}: ${member['userEmail']} - ${member['status']} - ${member['role']}');
        }
      } else {
        print('❌ Failed to fetch team members: ${response.statusCode}');
        print('❌ Error: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 Exception in getTeamMembers: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }

  /// Test function to check user access
  static Future<void> checkUserAccess(String authToken) async {
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
        final data = json.decode(response.body);
        print('✅ User access fetched successfully!');
        print('✅ Access Data: $data');
      } else {
        print('❌ Failed to fetch user access: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('💥 Exception in checkUserAccess: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }
}
