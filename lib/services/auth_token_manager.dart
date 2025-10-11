// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _businessDataKey = 'business_data';

  static AuthTokenManager? _instance;
  static AuthTokenManager get instance {
    _instance ??= AuthTokenManager();
    return _instance!;
  }

  // Store auth token and user data from login response
  Future<void> storeLoginResponse(Map<String, dynamic> loginResponse) async {
    final prefs = await SharedPreferences.getInstance();

    // Extract token
    final token = loginResponse['token'] as String?;
    if (token != null) {
      await prefs.setString(_tokenKey, token);
      print('🔑 Token stored: ${token.substring(0, 20)}...');
    }

    // Extract and store user data
    final data = loginResponse['data'] as Map<String, dynamic>?;
    if (data != null) {
      await prefs.setString(_userDataKey, jsonEncode(data));

      // Extract owned businesses for easy access
      final ownedBusinesses = data['ownedBusinesses'] as List<dynamic>?;
      if (ownedBusinesses != null && ownedBusinesses.isNotEmpty) {
        await prefs.setString(_businessDataKey, jsonEncode(ownedBusinesses));
        print('🏢 Stored ${ownedBusinesses.length} businesses');
      }
    }
  }

  // Get stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      print('🔑 Retrieved token: ${token.substring(0, 20)}...');
    }
    return token;
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Get business data
  Future<List<Map<String, dynamic>>?> getBusinessData() async {
    final prefs = await SharedPreferences.getInstance();
    final businessDataString = prefs.getString(_businessDataKey);
    if (businessDataString != null) {
      final businessList = jsonDecode(businessDataString) as List<dynamic>;
      return businessList.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Get first business ID (most common use case)
  Future<String?> getFirstBusinessId() async {
    final businesses = await getBusinessData();
    if (businesses != null && businesses.isNotEmpty) {
      final businessId = businesses.first['businessId'] as String?;
      print('🏢 Using business ID: $businessId');
      return businessId;
    }
    return null;
  }

  // Clear all stored data (for logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_businessDataKey);
    print('🧹 Cleared all auth data');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null;
  }

  // Get user info for display
  Future<Map<String, String>> getUserInfo() async {
    final userData = await getUserData();
    if (userData != null) {
      final user = userData['user'] as Map<String, dynamic>?;
      if (user != null) {
        return {
          'email': user['email'] as String? ?? '',
          'fullName': user['fullName'] as String? ?? '',
          'userType': user['userType'] as String? ?? '',
        };
      }
    }
    return {};
  }

  // Manual token storage (for testing or manual input)
  Future<void> setManualToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('🔑 Manual token stored');
  }

  // Store the specific token from your login output
  Future<void> storeYourToken() async {
    // Updated token from the new login response
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZTk5NDIxM2NiZTUzY2Y2OGY4MDhiMCIsInJvbGUiOiJlbXBsb3llciIsImlhdCI6MTc2MDE0MDgwNCwiZXhwIjoxNzYwNzQ1NjA0fQ.0P06vq3t4wlztYfdSlgNLY8PuWKg3Qy0Hgt1Tibup9g';

    await setManualToken(token);

    // Store the user data from login response
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _userDataKey,
        jsonEncode({
          'user': {
            '_id': '68e994213cbe53cf68f808b0',
            'email': 'y@y.com',
            'userType': 'employer',
            'firstName': 'yy',
            'lastName': 'uu',
            'fullName': 'yy uu',
            'id': '68e994213cbe53cf68f808b0'
          }
        }));

    // Since teamBusinesses is empty but the user has access to business p@,
    // we need to store some business data for the team management to work
    // For now, let's use a placeholder business since the API isn't returning teamBusinesses
    await prefs.setString(
        _businessDataKey,
        jsonEncode([
          {
            'businessId': 'placeholder-business-id',
            'businessName': 'Team Business',
            'industry': null,
            'createdAt': '2025-10-11T00:00:00.000Z'
          }
        ]));

    print('🚀 Updated token and user data stored!');
    print('📧 User: y@y.com (yy uu)');
    print('⚠️ Note: teamBusinesses was empty in login response');
  }
}
