import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class IOSNotificationPermissions {
  static const MethodChannel _channel =
      MethodChannel('ios_notification_permissions');

  /// Request notification permissions on iOS
  static Future<bool> requestNotificationPermissions() async {
    if (!Platform.isIOS) return true;

    try {
      final dynamic result =
          await _channel.invokeMethod('requestNotificationPermissions');
      final bool granted = result == true || result == 1;
      debugPrint('🔔 iOS notification permissions result: $granted');
      return granted;
    } on PlatformException catch (e) {
      debugPrint(
          '❌ Failed to request iOS notification permissions: ${e.message}');
      return false;
    }
  }

  /// Check current notification permission status
  static Future<bool> checkNotificationPermissions() async {
    if (!Platform.isIOS) return true;

    try {
      final dynamic result =
          await _channel.invokeMethod('checkNotificationPermissions');
      final bool granted = result == true || result == 1;
      debugPrint('🔔 iOS notification permissions status: $granted');
      return granted;
    } on PlatformException catch (e) {
      debugPrint(
          '❌ Failed to check iOS notification permissions: ${e.message}');
      return false;
    }
  }

  /// Open iOS settings for notifications
  static Future<void> openNotificationSettings() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to open iOS notification settings: ${e.message}');
    }
  }
}
