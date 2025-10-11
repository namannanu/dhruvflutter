import 'dart:async';
import 'package:flutter/material.dart';

/// A mixin that provides automatic refresh functionality to a StatefulWidget.
///
/// This mixin sets up a timer that periodically calls the `refreshData` method
/// which should be implemented by the class that uses this mixin.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  /// The timer that triggers the refresh
  Timer? _refreshTimer;

  /// Flag to track if a refresh is currently in progress
  bool _isRefreshing = false;

  /// The duration between auto-refreshes. Default is 60 seconds.
  Duration get refreshInterval => const Duration(seconds: 60);

  /// Override this method to implement the data refresh logic
  Future<void> refreshData();

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();

    // Initial refresh when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }

  /// Starts the auto-refresh timer
  void _startRefreshTimer() {
    _stopRefreshTimer(); // Ensure any existing timer is canceled
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      _triggerRefresh();
    });
  }

  /// Stops the auto-refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Triggers a refresh if one is not already in progress
  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    _isRefreshing = true;
    try {
      await refreshData();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Manually trigger a refresh from UI
  Future<void> manualRefresh() async {
    _stopRefreshTimer();
    await _triggerRefresh();
    _startRefreshTimer();
  }
}
