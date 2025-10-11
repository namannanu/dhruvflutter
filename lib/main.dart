import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talent/app.dart'; // Import WorkConnectApp
import 'package:talent/core/utils/nan_guard.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize NaN guards to prevent CoreGraphics warnings
    initializeNaNGuards();

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
