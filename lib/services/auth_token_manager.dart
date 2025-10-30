// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _businessDataKey = 'business_data';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';

  // In-memory cache for better performance
  String? _cachedToken;
  Map<String, dynamic>? _cachedUserData;
  List<Map<String, dynamic>>? _cachedBusinessData;
  DateTime? _cachedTokenExpiry;

  static AuthTokenManager? _instance;
  static AuthTokenManager get instance {
    _instance ??= AuthTokenManager();
    return _instance!;
  }

  // Store auth token and user data from login response with caching
  Future<void> storeLoginResponse(Map<String, dynamic> loginResponse) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Extract and cache token
      final token = loginResponse['token'] as String?;
      if (token != null) {
        await prefs.setString(_tokenKey, token);
        _cachedToken = token; // Cache in memory
        print('🔑 Token stored and cached: ${token.substring(0, 20)}...');
      }

      // Extract and store user data
      final data = loginResponse['data'] as Map<String, dynamic>?;
      if (data != null) {
        await prefs.setString(_userDataKey, jsonEncode(data));
        _cachedUserData = data; // Cache in memory
        print('👤 User data cached');

        // Handle token expiry if provided
        final tokenExpiry = data['tokenExpiry'] as int?;
        if (tokenExpiry != null) {
          final expiryDateTime =
              DateTime.fromMillisecondsSinceEpoch(tokenExpiry);
          await prefs.setInt(_tokenExpiryKey, tokenExpiry);
          _cachedTokenExpiry = expiryDateTime;
          print('⏰ Token expires: $expiryDateTime');
        }

        // Extract owned businesses for easy access
        final ownedBusinesses = data['ownedBusinesses'] as List<dynamic>?;
        if (ownedBusinesses != null && ownedBusinesses.isNotEmpty) {
          final businessList = ownedBusinesses.cast<Map<String, dynamic>>();
          await prefs.setString(_businessDataKey, jsonEncode(businessList));
          _cachedBusinessData = businessList; // Cache in memory
          print('🏢 Stored and cached ${ownedBusinesses.length} businesses');
        }

        // Also handle team businesses if available
        final teamBusinesses = data['teamBusinesses'] as List<dynamic>?;
        if (teamBusinesses != null && teamBusinesses.isNotEmpty) {
          print('👥 Found ${teamBusinesses.length} team businesses');
        }
      }

      print('✅ Login response stored successfully with caching');
    } catch (e) {
      print('❌ Error storing login response: $e');
      rethrow;
    }
  }

  // Get stored auth token with caching and expiry check
  Future<String?> getAuthToken() async {
    try {
      // Return cached token if available and not expired
      if (_cachedToken != null) {
        if (await _isTokenValid()) {
          print('🔑 Using cached token: ${_cachedToken!.substring(0, 20)}...');
          return _cachedToken;
        } else {
          print('⚠️ Cached token expired, clearing cache');
          await _clearExpiredToken();
          return null;
        }
      }

      // Load token from persistent storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null) {
        _cachedToken = token; // Cache for future use

        // Load expiry if not cached
        if (_cachedTokenExpiry == null) {
          final expiryTimestamp = prefs.getInt(_tokenExpiryKey);
          if (expiryTimestamp != null) {
            _cachedTokenExpiry =
                DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
          }
        }

        // Check if token is still valid
        if (await _isTokenValid()) {
          print('🔑 Retrieved and cached token: ${token.substring(0, 20)}...');
          return token;
        } else {
          print('⚠️ Stored token expired, clearing');
          await _clearExpiredToken();
          return null;
        }
      }

      print('❌ No token found in storage');
      return null;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  // Check if current token is still valid
  Future<bool> _isTokenValid() async {
    if (_cachedTokenExpiry != null) {
      final now = DateTime.now();
      final isValid = now.isBefore(_cachedTokenExpiry!);
      if (!isValid) {
        print('⏰ Token expired at $_cachedTokenExpiry');
      }
      return isValid;
    }

    // If no expiry info, assume token is valid
    // In production, you might want to validate with backend
    return true;
  }

  // Clear expired token from cache and storage
  Future<void> _clearExpiredToken() async {
    _cachedToken = null;
    _cachedTokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    print('🧹 Cleared expired token');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    // Return cached data if available
    if (_cachedUserData != null) {
      print('👤 Using cached user data');
      return _cachedUserData;
    }

    // Load from storage and cache
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      _cachedUserData = userData; // Cache for future use
      print('👤 Loaded and cached user data');
      return userData;
    }
    return null;
  }

  // Get business data
  Future<List<Map<String, dynamic>>?> getBusinessData() async {
    // Return cached data if available
    if (_cachedBusinessData != null) {
      print('🏢 Using cached business data');
      return _cachedBusinessData;
    }

    // Load from storage and cache
    final prefs = await SharedPreferences.getInstance();
    final businessDataString = prefs.getString(_businessDataKey);
    if (businessDataString != null) {
      final businessList = jsonDecode(businessDataString) as List<dynamic>;
      final typedBusinessList = businessList.cast<Map<String, dynamic>>();
      _cachedBusinessData = typedBusinessList; // Cache for future use
      print('🏢 Loaded and cached business data');
      return typedBusinessList;
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
    // Clear memory cache
    _cachedToken = null;
    _cachedUserData = null;
    _cachedBusinessData = null;
    _cachedTokenExpiry = null;

    // Clear persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_businessDataKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_refreshTokenKey);

    print('🧹 Cleared all auth data and cache');
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
    _cachedToken = token; // Also cache it
    print('🔑 Manual token stored and cached');
  }

  // Store the specific token from your login output with improved caching
  Future<void> storeYourToken() async {
    // Updated token from the new login response
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZTk5NDIxM2NiZTUzY2Y2OGY4MDhiMCIsInJvbGUiOiJlbXBsb3llciIsImlhdCI6MTc2MDE0MDgwNCwiZXhwIjoxNzYwNzQ1NjA0fQ.0P06vq3t4wlztYfdSlgNLY8PuWKg3Qy0Hgt1Tibup9g';

    // Store token with caching
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _cachedToken = token; // Cache in memory

    // Calculate and store token expiry (exp field * 1000 for milliseconds)
    const expiryTimestamp = 1760745604 * 1000; // Convert to milliseconds
    final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    await prefs.setInt(_tokenExpiryKey, expiryTimestamp);
    _cachedTokenExpiry = expiryDateTime;

    // Store the user data from login response with caching
    final userData = {
      'user': {
        '_id': '68e994213cbe53cf68f808b0',
        'email': 'y@y.com',
        'userType': 'employer',
        'firstName': 'yy',
        'lastName': 'uu',
        'fullName': 'yy uu',
        'id': '68e994213cbe53cf68f808b0'
      },
      'tokenExpiry': expiryTimestamp
    };

    await prefs.setString(_userDataKey, jsonEncode(userData));
    _cachedUserData = userData; // Cache in memory

    // Store business data with caching
    final businessData = [
      {
        'businessId': '68e8d6caaf91efc4cf7f223e',
        'businessName': 'WorkConnect Team Business',
        'industry': null,
        'createdAt': '2025-10-10T00:00:00.000Z'
      }
    ];

    await prefs.setString(_businessDataKey, jsonEncode(businessData));
    _cachedBusinessData = businessData; // Cache in memory

    print('🚀 Updated token and user data stored with caching!');
    print('📧 User: y@y.com (yy uu)');
    print('⏰ Token expires: $expiryDateTime');
    print('💾 All data cached in memory for fast access');
  }

  // Refresh token if needed (placeholder for future implementation)
  Future<String?> refreshToken() async {
    print('🔄 Token refresh not implemented yet');
    // This would typically make an API call to refresh the token
    // For now, return null to indicate refresh is not available
    return null;
  }

  // Force reload data from storage (clear cache)
  Future<void> reloadFromStorage() async {
    _cachedToken = null;
    _cachedUserData = null;
    _cachedBusinessData = null;
    _cachedTokenExpiry = null;
    print('🔄 Cache cleared, will reload from storage on next access');
  }

  // Get cache status for debugging
  Map<String, bool> getCacheStatus() {
    return {
      'tokenCached': _cachedToken != null,
      'userDataCached': _cachedUserData != null,
      'businessDataCached': _cachedBusinessData != null,
      'expiryTimeCached': _cachedTokenExpiry != null,
    };
  }
}
