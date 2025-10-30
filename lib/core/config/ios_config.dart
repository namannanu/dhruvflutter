import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ignore: camel_case_types
class iOSConfig {
  static Future<void> configure() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      // Set up error handling channel
      const errorChannel = MethodChannel('com.talent/error_handling');
      errorChannel.setMethodCallHandler((call) async {
        if (call.method == 'reportError') {
          final error = call.arguments['error'] as String?;
          final stackTrace = call.arguments['stackTrace'] as String?;

          debugPrint('🔴 iOS Native Error: $error');
          debugPrint('📍 Stack trace: $stackTrace');
        }
        return null;
      });

      // Configure iOS-specific settings
      await SystemChannels.platform.invokeMethod('configureIOSApp', {
        'enableBackgroundNetworking': true,
        'networkTimeout': 30000, // 30 seconds
        'maxConcurrentOperations': 4,
        'enableNetworkResilience': true,
      });

      debugPrint('✅ iOS configuration completed successfully');
    } catch (e, stack) {
      debugPrint('❌ Failed to configure iOS settings: $e');
      debugPrint(stack.toString());
    }
  }
}
