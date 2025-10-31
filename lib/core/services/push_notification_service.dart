import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talent/core/services/ios_notification_permissions.dart';
import 'package:talent/core/utils/platform_helper.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static PushNotificationService get instance => _instance;

  bool _initialized = false;
  String? _fcmToken;
  String? _baseUrl;
  String? _authToken;

  // Callback function to handle notification taps
  Function(Map<String, dynamic>)? onNotificationTap;
  Function(Map<String, dynamic>)? onNotificationReceived;

  /// Initialize push notification service
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
  }) async {
    if (_initialized) return;

    _baseUrl = baseUrl;
    _authToken = authToken;

    try {
      // Request notification permissions on iOS (only when not on web)
      if (PlatformHelper.isIOS) {
        final hasPermission =
            await IOSNotificationPermissions.requestNotificationPermissions();
        if (!hasPermission) {
          debugPrint('⚠️ iOS notification permissions not granted');
        }
      }

      // Generate a mock FCM token for now
      await _generateMockToken();

      // Send token to backend
      if (_authToken != null && _fcmToken != null) {
        await _sendTokenToBackend();
      }

      _initialized = true;
      debugPrint('🔔 Push Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Push Notification Service: $e');
    }
  }

  /// Generate a mock FCM token for development
  Future<void> _generateMockToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken = prefs.getString('mock_fcm_token');

      if (_fcmToken == null) {
        // Generate a unique mock token
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _fcmToken = 'mock_token_$timestamp';
        await prefs.setString('mock_fcm_token', _fcmToken!);
      }

      debugPrint('🎯 Mock FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Failed to generate mock FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend() async {
    if (_baseUrl == null || _authToken == null || _fcmToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'fcmToken': _fcmToken,
          'platform': PlatformHelper.platformName,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to backend successfully');
      } else {
        debugPrint(
            '❌ Failed to send FCM token to backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Update auth token
  void updateAuthToken(String? authToken) {
    _authToken = authToken;
    if (_authToken != null && _fcmToken != null) {
      _sendTokenToBackend();
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Simulate receiving a notification
  void simulateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    debugPrint('📨 Simulated notification: $title - $body');

    // Call callback if set
    if (onNotificationReceived != null && data != null) {
      onNotificationReceived!(data);
    }

    // Show pop-up notification for messages and other types
    _showLocalNotification(title: title, body: body, data: data);
  }

  /// Show a local pop-up notification
  void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    debugPrint('🔔 Showing pop-up notification: $title');

    // For messages specifically, show immediate pop-up
    if (data?['type'] == 'message' || data?['notificationType'] == 'message') {
      debugPrint('💬 Message notification pop-up: $title');
      // In a real implementation, this would show a system notification
      // For now, we'll trigger the callback
      if (onNotificationReceived != null) {
        onNotificationReceived!({
          'title': title,
          'body': body,
          'type': 'message',
          'showPopup': true,
          ...?data,
        });
      }
    }
  }

  /// Subscribe to notification topics
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('✅ Subscribed to topic: $topic (mock)');
  }

  /// Unsubscribe from notification topics
  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('✅ Unsubscribed from topic: $topic (mock)');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return true; // Mock implementation
  }

  /// Show test notification
  Future<void> showTestNotification() async {
    simulateNotification(
      title: 'Test Notification',
      body: 'This is a test notification from your app!',
      data: {'type': 'test'},
    );
  }
}

/// Notification data model
class AppPushNotification {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AppPushNotification({
    required this.title,
    required this.body,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppPushNotification.fromJson(Map<String, dynamic> json) {
    return AppPushNotification(
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? {}),
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
