import 'package:flutter/foundation.dart';

/// Platform detection utility that works across all Flutter platforms
class PlatformHelper {
  /// Check if running on iOS (mobile only, not web)
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Check if running on Android (mobile only, not web)
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on desktop platforms
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Check if running on mobile platforms
  static bool get isMobile => isIOS || isAndroid;

  /// Get platform name as string
  static String get platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// Check if platform supports push notifications
  static bool get supportsPushNotifications => isMobile;

  /// Check if platform supports background execution
  static bool get supportsBackgroundExecution => isMobile;
}
