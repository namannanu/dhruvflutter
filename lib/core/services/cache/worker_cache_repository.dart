import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:talent/core/utils/performance_monitor.dart';

import '../../models/models.dart';

class WorkerCacheRepository {
  WorkerCacheRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'cache.worker.profile';
  static const _metricsKey = 'cache.worker.metrics';

  static Future<WorkerCacheRepository> create() async {
    PerformanceMonitor.startTiming('SharedPreferences Init');
    final prefs = await SharedPreferences.getInstance();
    PerformanceMonitor.endTiming('SharedPreferences Init');
    return WorkerCacheRepository._(prefs);
  }

  WorkerProfile? readProfile() {
    final jsonString = _prefs.getString(_profileKey);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkerProfile.fromJson(map);
    } catch (_) {
      _prefs.remove(_profileKey);
      return null;
    }
  }

  Future<void> writeProfile(WorkerProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  WorkerDashboardMetrics? readMetrics() {
    final jsonString = _prefs.getString(_metricsKey);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkerDashboardMetrics.fromJson(map);
    } catch (_) {
      _prefs.remove(_metricsKey);
      return null;
    }
  }

  Future<void> writeMetrics(WorkerDashboardMetrics metrics) async {
    await _prefs.setString(_metricsKey, jsonEncode(metrics.toJson()));
  }

  Future<void> clearWorkerData() async {
    await Future.wait([
      _prefs.remove(_profileKey),
      _prefs.remove(_metricsKey),
    ]);
  }
}
