import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../cache/cache_keys.dart';
import '../cache/cache_service.dart';
import '../models/models.dart';
import '../network/dio_client.dart';

typedef Json = Map<String, dynamic>;

class WorkerRepository {
  WorkerRepository(this._cache);
  final CacheService _cache;

  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  // TTLs: tune per your UX
  static const Duration ttlFast = Duration(minutes: 15);
  static const Duration ttlMedium = Duration(minutes: 30);
  static const Duration ttlSlow = Duration(hours: 4);

  /// Jobs - frequently changing data, shorter TTL
  Future<List<JobPosting>> getJobsSWR(String userId) async {
    // 1) Serve cache immediately if available
    final cached = _cache.getJson<List>(CacheKeys.workerJobs(userId));
    if (cached != null) {
      // decode in background isolate if big
      return compute(_decodeJobs, jsonEncode(cached));
    }

    // 2) No cache: fetch network and store
    final fresh = await _fetchJobsFromNetwork();
    await _cache.putJson(
        CacheKeys.workerJobs(userId), fresh.map((j) => j.toJson()).toList(),
        ttl: ttlFast);
    return fresh;
  }

  /// Trigger a background refresh (call after painting cached UI)
  Future<void> refreshJobs(String userId) async {
    try {
      final fresh = await _fetchJobsFromNetwork();
      await _cache.putJson(
          CacheKeys.workerJobs(userId), fresh.map((j) => j.toJson()).toList(),
          ttl: ttlFast);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh jobs: $e');
    }
  }

  Future<List<JobPosting>> _fetchJobsFromNetwork() async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/jobs/worker/available');
    final data = res.data;
    final list = (data is List) ? data : (data['data'] as List? ?? []);
    return compute(_decodeJobs, jsonEncode(list));
  }

  /// Applications - user actions reflect quickly
  Future<List<Application>> getApplicationsSWR(String userId) async {
    final cached = _cache.getJson<List>(CacheKeys.workerApps(userId));
    if (cached != null) {
      return compute(_decodeApplications, jsonEncode(cached));
    }

    final fresh = await _fetchApplicationsFromNetwork(userId);
    await _cache.putJson(
        CacheKeys.workerApps(userId), fresh.map((a) => a.toJson()).toList(),
        ttl: ttlFast);
    return fresh;
  }

  Future<void> refreshApplications(String userId) async {
    try {
      final fresh = await _fetchApplicationsFromNetwork(userId);
      await _cache.putJson(
          CacheKeys.workerApps(userId), fresh.map((a) => a.toJson()).toList(),
          ttl: ttlFast);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh applications: $e');
    }
  }

  Future<List<Application>> _fetchApplicationsFromNetwork(String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/applications/worker/$userId');
    final data = res.data;
    final list = (data is List) ? data : (data['data'] as List? ?? []);
    return compute(_decodeApplications, jsonEncode(list));
  }

  /// Attendance - less volatile, longer TTL
  Future<List<AttendanceRecord>> getAttendanceSWR(String userId) async {
    final cached = _cache.getJson<List>(CacheKeys.workerAttendance(userId));
    if (cached != null) {
      return compute(_decodeAttendance, jsonEncode(cached));
    }

    final fresh = await _fetchAttendanceFromNetwork(userId);
    await _cache.putJson(CacheKeys.workerAttendance(userId),
        fresh.map((a) => a.toJson()).toList(),
        ttl: ttlMedium);
    return fresh;
  }

  Future<void> refreshAttendance(String userId) async {
    try {
      final fresh = await _fetchAttendanceFromNetwork(userId);
      await _cache.putJson(CacheKeys.workerAttendance(userId),
          fresh.map((a) => a.toJson()).toList(),
          ttl: ttlMedium);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh attendance: $e');
    }
  }

  Future<List<AttendanceRecord>> _fetchAttendanceFromNetwork(
      String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/attendance/worker/$userId');
    final data = res.data;
    final list = (data is List) ? data : (data['data'] as List? ?? []);
    return compute(_decodeAttendance, jsonEncode(list));
  }

  /// Worker Profile
  Future<WorkerProfile?> getProfileSWR(String userId) async {
    final cached =
        _cache.getJson<Map<String, dynamic>>(CacheKeys.workerProfile(userId));
    if (cached != null) {
      return WorkerProfile.fromJson(cached);
    }

    final fresh = await _fetchProfileFromNetwork(userId);
    if (fresh != null) {
      await _cache.putJson(CacheKeys.workerProfile(userId), fresh.toJson(),
          ttl: ttlSlow);
    }
    return fresh;
  }

  Future<void> refreshProfile(String userId) async {
    try {
      final fresh = await _fetchProfileFromNetwork(userId);
      if (fresh != null) {
        await _cache.putJson(CacheKeys.workerProfile(userId), fresh.toJson(),
            ttl: ttlSlow);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to refresh profile: $e');
    }
  }

  Future<WorkerProfile?> _fetchProfileFromNetwork(String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/workers/$userId/profile');
    final data = res.data;
    if (data == null) return null;
    final jsonData = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    return WorkerProfile.fromJson(jsonData);
  }

  /// Worker Metrics
  Future<WorkerDashboardMetrics?> getMetricsSWR(String userId) async {
    final cached =
        _cache.getJson<Map<String, dynamic>>(CacheKeys.workerMetrics(userId));
    if (cached != null) {
      return WorkerDashboardMetrics.fromJson(cached);
    }

    final fresh = await _fetchMetricsFromNetwork(userId);
    if (fresh != null) {
      await _cache.putJson(CacheKeys.workerMetrics(userId), fresh.toJson(),
          ttl: ttlFast);
    }
    return fresh;
  }

  Future<void> refreshMetrics(String userId) async {
    try {
      final fresh = await _fetchMetricsFromNetwork(userId);
      if (fresh != null) {
        await _cache.putJson(CacheKeys.workerMetrics(userId), fresh.toJson(),
            ttl: ttlFast);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to refresh metrics: $e');
    }
  }

  Future<WorkerDashboardMetrics?> _fetchMetricsFromNetwork(
      String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/workers/$userId/metrics');
    final data = res.data;
    if (data == null) return null;
    final jsonData = data is Map<String, dynamic>
        ? data
        : (data['data'] as Map<String, dynamic>);
    return WorkerDashboardMetrics.fromJson(jsonData);
  }

  /// Clear all worker cache
  Future<void> clearCache(String userId) async {
    await Future.wait([
      _cache.remove(CacheKeys.workerJobs(userId)),
      _cache.remove(CacheKeys.workerApps(userId)),
      _cache.remove(CacheKeys.workerAttendance(userId)),
      _cache.remove(CacheKeys.workerProfile(userId)),
      _cache.remove(CacheKeys.workerMetrics(userId)),
    ]);
  }
}

// === Isolate parsers (zero jank) ===
List<JobPosting> _decodeJobs(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(JobPosting.fromJson).toList();
}

List<Application> _decodeApplications(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(Application.fromJson).toList();
}

List<AttendanceRecord> _decodeAttendance(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(AttendanceRecord.fromJson).toList();
}
