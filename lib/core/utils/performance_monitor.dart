import 'package:flutter/foundation.dart';

/// Performance monitor to track slow operations
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
    if (kDebugMode) print('⏱️ Started timing: $operation');
  }
  
  static void endTiming(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operation);
    
    if (kDebugMode) {
      final emoji = duration.inMilliseconds > 1000 ? '🐌' : 
                   duration.inMilliseconds > 500 ? '⚠️' : '✅';
      print('$emoji $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  static void logSlowOperation(String operation, int milliseconds) {
    if (kDebugMode && milliseconds > 500) {
      if (kDebugMode) {
        print('🐌 Slow operation detected: $operation took ${milliseconds}ms');
      }
    }
  }
}