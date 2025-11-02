// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

/// Circuit breaker to prevent repeated failed API calls
class CircuitBreaker {
  static final Map<String, CircuitBreakerState> _states = {};
  
  static const int failureThreshold = 3;
  static const Duration timeoutDuration = Duration(minutes: 2);
  
  static bool shouldAllowRequest(String endpoint) {
    final state = _states[endpoint];
    if (state == null) return true;
    
    // If circuit is open (too many failures), check if timeout has passed
    if (state.isOpen) {
      if (DateTime.now().difference(state.lastFailureTime) > timeoutDuration) {
        // Reset circuit to half-open state
        _states[endpoint] = CircuitBreakerState(
          failureCount: 0,
          isOpen: false,
          lastFailureTime: DateTime.now(),
        );
        if (kDebugMode) print('🔄 Circuit breaker RESET for $endpoint');
        return true;
      }
      if (kDebugMode) print('🚫 Circuit breaker OPEN for $endpoint - blocking request');
      return false;
    }
    
    return true;
  }
  
  static void recordSuccess(String endpoint) {
    _states[endpoint] = CircuitBreakerState(
      failureCount: 0,
      isOpen: false,
      lastFailureTime: DateTime.now(),
    );
  }
  
  static void recordFailure(String endpoint) {
    final state = _states[endpoint] ?? CircuitBreakerState(
      failureCount: 0,
      isOpen: false,
      lastFailureTime: DateTime.now(),
    );
    
    final newFailureCount = state.failureCount + 1;
    final shouldOpen = newFailureCount >= failureThreshold;
    
    _states[endpoint] = CircuitBreakerState(
      failureCount: newFailureCount,
      isOpen: shouldOpen,
      lastFailureTime: DateTime.now(),
    );
    
    if (shouldOpen && kDebugMode) {
      print('⚡ Circuit breaker OPENED for $endpoint after $newFailureCount failures');
    }
  }
  
  static void reset() {
    _states.clear();
    if (kDebugMode) print('🔄 All circuit breakers reset');
  }
}

class CircuitBreakerState {
  final int failureCount;
  final bool isOpen;
  final DateTime lastFailureTime;
  
  CircuitBreakerState({
    required this.failureCount,
    required this.isOpen,
    required this.lastFailureTime,
  });
}