import 'package:flutter/foundation.dart';
import 'package:talent/core/services/base/base_api_service.dart';
import 'package:talent/core/services/enhanced_api_service.dart';

class ApiServiceFactory {
  static BaseApiService create({
    required String baseUrl,
    bool enableLogging = false,
  }) {
    // Use enhanced service for iOS to handle platform-specific issues
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('📱 Using Enhanced API Service for iOS');
      return EnhancedApiService(
        baseUrl: baseUrl,
        enableLogging: enableLogging,
      );
    }

    // Use base service for other platforms
    return BaseApiService(
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );
  }
}
