import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talent/app.dart'; // Import WorkConnectApp
import 'package:talent/core/utils/nan_guard.dart';

void main() {
  runZonedGuarded(() async {
    developer.log('🚀 App starting up...', name: 'App');

    // Add specific error handling for iOS memory issues
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Flutter Error: ${details.exception}',
        name: 'FlutterCrash',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Check for memory protection errors
      if (details.exception.toString().contains('memory protection')) {
        developer.log(
          '⚠️ iOS Memory Protection Error detected',
          name: 'iOSMemory',
          error: details.exception,
          stackTrace: details.stack,
        );
      }
    };

    WidgetsFlutterBinding.ensureInitialized();
    developer.log('✅ Flutter binding initialized', name: 'App');

    // Initialize NaN guards to prevent CoreGraphics warnings
    initializeNaNGuards();
    developer.log('✅ NaN guards initialized', name: 'App');

    if (kDebugMode) {
      // Use developer.log for structured logging
      FlutterError.onError = (FlutterErrorDetails details) {
        developer.log(
          details.exceptionAsString(),
          name: 'FlutterError',
          stackTrace: details.stack,
        );
      };
    }

    runApp(const WorkConnectApp());
  }, (error, stack) {
    developer.log(
      'Unhandled error',
      name: 'App',
      error: error,
      stackTrace: stack,
    );
  });
}
