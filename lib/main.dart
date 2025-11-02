import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talent/app.dart'; // Import WorkConnectApp
import 'package:talent/core/utils/nan_guard.dart';
import 'package:talent/core/utils/performance_monitor.dart';

void main() {
  runZonedGuarded(() async {
    PerformanceMonitor.startTiming('App Startup');
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

    // Initialize Hive for caching
    PerformanceMonitor.startTiming('Hive Init');
    await Hive.initFlutter();
    PerformanceMonitor.endTiming('Hive Init');
    developer.log('✅ Hive cache initialized', name: 'App');

    // Initialize NaN guards to prevent CoreGraphics warnings
    initializeNaNGuards();
    developer.log('✅ NaN guards initialized', name: 'App');

    PerformanceMonitor.endTiming('App Startup');
    PerformanceMonitor.startTiming('App Widget Build');

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
