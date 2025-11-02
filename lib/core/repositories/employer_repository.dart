import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../cache/cache_keys.dart';
import '../cache/cache_service.dart';
import '../models/models.dart';
import '../network/circuit_breaker.dart';
import '../network/dio_client.dart';

typedef Json = Map<String, dynamic>;

class EmployerRepository {
  EmployerRepository(this._cache);
  final CacheService _cache;

  static const String baseUrl = 'https://dhruvbackend.vercel.app/api';

  // TTLs: tune per your UX - Applications change more frequently
  static const Duration ttlFast =
      Duration(minutes: 15); // Increased for better dashboard persistence
  static const Duration ttlMedium = Duration(minutes: 30);
  static const Duration ttlSlow = Duration(hours: 4);

  /// Businesses - Offline-first with instant response
  Future<List<BusinessLocation>> getBusinessesSWR() async {
    // Always serve cache first for instant UI
    final cached = _cache.getJson<List>(CacheKeys.businesses);
    if (cached != null) {
      final cachedData = compute(_decodeBusinesses, jsonEncode(cached));
      
      // Start background refresh
      _refreshBusinessesInBackground();
      
      return cachedData;
    }

    // If no cache, try network with short timeout
    try {
      final fresh = await _fetchBusinessesFromNetwork()
          .timeout(const Duration(seconds: 3));
      await _cache.putJson(
          CacheKeys.businesses, fresh.map((b) => b.toJson()).toList(),
          ttl: ttlSlow);
      return fresh;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to fetch businesses, returning empty list: $e');
      return <BusinessLocation>[];
    }
  }

  void _refreshBusinessesInBackground() {
    Future.delayed(Duration.zero, () async {
      const endpoint = 'businesses';
      
      if (!CircuitBreaker.shouldAllowRequest(endpoint)) {
        if (kDebugMode) print('🚫 Circuit breaker blocking businesses request');
        return;
      }
      
      try {
        final fresh = await _fetchBusinessesFromNetwork()
            .timeout(const Duration(seconds: 8));
        await _cache.putJson(
            CacheKeys.businesses, fresh.map((b) => b.toJson()).toList(),
            ttl: ttlSlow);
        CircuitBreaker.recordSuccess(endpoint);
        if (kDebugMode) print('✅ Background refresh successful for businesses');
      } catch (e) {
        CircuitBreaker.recordFailure(endpoint);
        if (kDebugMode) print('⚠️ Background refresh failed, keeping cached data: $e');
      }
    });
  }

  Future<void> refreshBusinesses() async {
    try {
      final fresh = await _fetchBusinessesFromNetwork();
      await _cache.putJson(
          CacheKeys.businesses, fresh.map((b) => b.toJson()).toList(),
          ttl: ttlSlow);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh businesses: $e');
    }
  }

  Future<List<BusinessLocation>> _fetchBusinessesFromNetwork() async {
    try {
      final dio = await DioClient.instance();
      final res = await dio.get('$baseUrl/businesses');
      final data = res.data;
      final list = (data is List) ? data : (data['data'] as List? ?? []);
      return compute(_decodeBusinesses, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Businesses API Error: $e');
        print('   Endpoint: $baseUrl/businesses');
      }
      
      // Return empty list instead of crashing
      return <BusinessLocation>[];
    }
  }

  /// Employer Jobs - Offline-first with instant response  
  Future<List<JobPosting>> getJobsSWR(String userId) async {
    final cached = _cache.getJson<List>(CacheKeys.employerJobs(userId));
    if (cached != null) {
      final cachedData = compute(_decodeJobs, jsonEncode(cached));
      
      // Start background refresh
      _refreshJobsInBackground(userId);
      
      return cachedData;
    }

    try {
      final fresh = await _fetchJobsFromNetwork(userId)
          .timeout(const Duration(seconds: 5));
      await _cache.putJson(
          CacheKeys.employerJobs(userId), fresh.map((j) => j.toJson()).toList(),
          ttl: ttlFast);
      return fresh;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to fetch jobs, returning empty list: $e');
      return <JobPosting>[];
    }
  }

  void _refreshJobsInBackground(String userId) {
    Future.delayed(Duration.zero, () async {
      try {
        final fresh = await _fetchJobsFromNetwork(userId)
            .timeout(const Duration(seconds: 10));
        await _cache.putJson(
            CacheKeys.employerJobs(userId), fresh.map((j) => j.toJson()).toList(),
            ttl: ttlFast);
        if (kDebugMode) print('✅ Background refresh successful for jobs');
      } catch (e) {
        if (kDebugMode) print('⚠️ Background refresh failed, keeping cached data: $e');
      }
    });
  }

  Future<void> refreshJobs(String userId) async {
    try {
      final fresh = await _fetchJobsFromNetwork(userId);
      await _cache.putJson(
          CacheKeys.employerJobs(userId), fresh.map((j) => j.toJson()).toList(),
          ttl: ttlFast);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh jobs: $e');
    }
  }

  Future<List<JobPosting>> _fetchJobsFromNetwork(String userId) async {
    try {
      final dio = await DioClient.instance();
      final res = await dio.get('$baseUrl/jobs/user/$userId');
      final data = res.data;
      
      // The API returns categorized jobs, we want posted jobs for employers
      if (data is Map && data['data'] != null) {
        final jobData = data['data'];
        final postedJobs = jobData['jobs']?['postedJobs'] as List? ?? [];
        return compute(_decodeJobs, jsonEncode(postedJobs));
      }
      
      // Fallback for direct list response
      final list = (data is List) ? data : (data['data'] as List? ?? []);
      return compute(_decodeJobs, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Jobs API Error: $e');
        print('   User ID: $userId');
        print('   Endpoint: $baseUrl/jobs/user/$userId');
      }
      
      // Return empty list instead of crashing
      return <JobPosting>[];
    }
  }

  /// Employer Applications - Offline-first with error handling
  Future<List<Application>> getApplicationsSWR(String userId) async {
    // Always try cache first for instant response
    final cached = _cache.getJson<List>(CacheKeys.employerApplications(userId));
    if (cached != null) {
      // Serve cache immediately for instant UI response
      final cachedData = compute(_decodeApplications, jsonEncode(cached));
      
      // Start background refresh without blocking UI
      _refreshApplicationsInBackground(userId);
      
      return cachedData;
    }

    // If no cache, try network with timeout
    try {
      final fresh = await _fetchApplicationsFromNetwork(userId)
          .timeout(const Duration(seconds: 5)); // Short timeout
      await _cache.putJson(CacheKeys.employerApplications(userId),
          fresh.map((a) => a.toJson()).toList(),
          ttl: ttlFast);
      return fresh;
    } catch (e) {
      if (kDebugMode) print('❌ Failed to fetch applications, returning empty list: $e');
      // Return empty list instead of crashing
      return <Application>[];
    }
  }

  // Background refresh that doesn't block UI
  void _refreshApplicationsInBackground(String userId) {
    Future.delayed(Duration.zero, () async {
      final endpoint = 'applications/user/$userId';
      
      // Check circuit breaker before making request
      if (!CircuitBreaker.shouldAllowRequest(endpoint)) {
        if (kDebugMode) print('🚫 Circuit breaker blocking applications request');
        return;
      }
      
      try {
        final fresh = await _fetchApplicationsFromNetwork(userId)
            .timeout(const Duration(seconds: 8));
        await _cache.putJson(CacheKeys.employerApplications(userId),
            fresh.map((a) => a.toJson()).toList(),
            ttl: ttlFast);
        CircuitBreaker.recordSuccess(endpoint);
        if (kDebugMode) print('✅ Background refresh successful for applications');
      } catch (e) {
        CircuitBreaker.recordFailure(endpoint);
        if (kDebugMode) print('⚠️ Background refresh failed, keeping cached data: $e');
      }
    });
  }

  Future<void> refreshApplications(String userId) async {
    try {
      final fresh = await _fetchApplicationsFromNetwork(userId);
      await _cache.putJson(CacheKeys.employerApplications(userId),
          fresh.map((a) => a.toJson()).toList(),
          ttl: ttlFast);
    } catch (e) {
      if (kDebugMode) print('Failed to refresh applications: $e');
    }
  }

  Future<List<Application>> _fetchApplicationsFromNetwork(String userId) async {
    try {
      final dio = await DioClient.instance();
      final res = await dio.get('$baseUrl/applications/user/$userId');
      final data = res.data;
      
      // The API returns categorized applications, we want employer applications
      if (data is Map && data['data'] != null) {
        final appData = data['data'];
        final employerApps = appData['applications']?['employerApplications'] as List? ?? [];
        return compute(_decodeApplications, jsonEncode(employerApps));
      }
      
      // Fallback for direct list response
      final list = (data is List) ? data : (data['data'] as List? ?? []);
      return compute(_decodeApplications, jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Applications API Error: $e');
        print('   User ID: $userId');
        print('   Endpoint: $baseUrl/applications/user/$userId');
      }
      
      // Return empty list instead of crashing
      return <Application>[];
    }
  }

  /// Employer Profile - Simple Map storage for now
  Future<Map<String, dynamic>?> getProfileSWR(String userId) async {
    final cached =
        _cache.getJson<Map<String, dynamic>>(CacheKeys.employerProfile(userId));
    if (cached != null) {
      return cached;
    }

    final fresh = await _fetchProfileFromNetwork(userId);
    if (fresh != null) {
      await _cache.putJson(CacheKeys.employerProfile(userId), fresh,
          ttl: ttlSlow);
    }
    return fresh;
  }

  Future<void> refreshProfile(String userId) async {
    try {
      final fresh = await _fetchProfileFromNetwork(userId);
      if (fresh != null) {
        await _cache.putJson(CacheKeys.employerProfile(userId), fresh,
            ttl: ttlSlow);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to refresh profile: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileFromNetwork(String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/users/id/$userId/all-data');
    final data = res.data;
    
    if (data is Map && data['data'] != null) {
      final userData = data['data'] as Map<String, dynamic>;
      return {
        'user': userData['user'],
        'profile': userData['profile']
      };
    }
    
    return null;
  }

  /// Employer Metrics - Simple Map storage for now
  Future<Map<String, dynamic>?> getMetricsSWR(String userId) async {
    final cached =
        _cache.getJson<Map<String, dynamic>>(CacheKeys.employerMetrics(userId));
    if (cached != null) {
      return cached;
    }

    final fresh = await _fetchMetricsFromNetwork(userId);
    if (fresh != null) {
      await _cache.putJson(CacheKeys.employerMetrics(userId), fresh,
          ttl: ttlMedium);
    }
    return fresh;
  }

  Future<void> refreshMetrics(String userId) async {
    try {
      final fresh = await _fetchMetricsFromNetwork(userId);
      if (fresh != null) {
        await _cache.putJson(CacheKeys.employerMetrics(userId), fresh,
            ttl: ttlMedium);
      }
    } catch (e) {
      if (kDebugMode) print('Failed to refresh metrics: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchMetricsFromNetwork(String userId) async {
    final dio = await DioClient.instance();
    final res = await dio.get('$baseUrl/users/id/$userId/all-data');
    final data = res.data;
    
    if (data is Map && data['data'] != null) {
      final userData = data['data'] as Map<String, dynamic>;
      
      // Create metrics from the available data
      final profile = userData['profile'] as Map<String, dynamic>?;
      final applications = userData['applications'] as Map<String, dynamic>?;
      final jobs = userData['jobs'] as Map<String, dynamic>?;
      
      return {
        'totalJobsPosted': profile?['totalJobsPosted'] ?? 0,
        'totalHires': profile?['totalHires'] ?? 0,
        'totalApplications': applications?['total'] ?? 0,
        'employerApplications': applications?['employerApplications']?.length ?? 0,
        'postedJobs': jobs?['postedJobs']?.length ?? 0,
        'rating': profile?['rating'] ?? 0.0,
      };
    }
    
    return null;
  }

  /// Clear all employer cache
  Future<void> clearCache(String userId) async {
    await Future.wait([
      _cache.remove(CacheKeys.businesses),
      _cache.remove(CacheKeys.employerJobs(userId)),
      _cache.remove(CacheKeys.employerApplications(userId)),
      _cache.remove(CacheKeys.employerProfile(userId)),
      _cache.remove(CacheKeys.employerMetrics(userId)),
    ]);
  }
}

// === Isolate parsers (zero jank) ===
List<BusinessLocation> _decodeBusinesses(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(BusinessLocation.fromJson).toList();
}

List<JobPosting> _decodeJobs(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(JobPosting.fromJson).toList();
}

List<Application> _decodeApplications(String jsonStr) {
  final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
  return list.map(Application.fromJson).toList();
}
