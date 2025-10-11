// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:talent/core/models/location.dart';

/// Service for handling geolocation functionality
class LocationService {
  static LocationService? _instance;
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  LocationService._();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('⚠️ LocationService: Error checking service status: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return _convertPermission(permission);
    } catch (e) {
      print('⚠️ LocationService: Error checking permissions: $e');
      return LocationPermissionStatus.denied;
    }
  }

  /// Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      print('🔐 LocationService: Requesting location permission...');
      final permission = await Geolocator.requestPermission();
      return _convertPermission(permission);
    } catch (e) {
      print('❌ LocationService: Error requesting permission: $e');
      return LocationPermissionStatus.denied;
    }
  }

  /// Get current location
  Future<Location?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
    double? desiredAccuracy,
  }) async {
    try {
      print('📍 LocationService: Getting current location...');

      // Check if location service is enabled
      if (!await isLocationServiceEnabled()) {
        throw const LocationException('Location services are disabled');
      }

      // Check permission
      final permission = await checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        final requested = await requestPermission();
        if (requested != LocationPermissionStatus.granted &&
            requested != LocationPermissionStatus.whileInUse) {
          throw const LocationException('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _convertAccuracy(desiredAccuracy),
        timeLimit: timeout,
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
      );
    } on LocationServiceDisabledException {
      throw const LocationException('Location services are disabled');
    } on PermissionDeniedException {
      throw const LocationException('Location permission denied');
    } on TimeoutException {
      throw const LocationException('Location request timed out');
    } on PlatformException catch (e) {
      print('❌ LocationService: Platform error: $e');
      throw LocationException('Failed to get location: ${e.message}');
    } catch (e) {
      print('❌ LocationService: Error getting location: $e');
      rethrow;
    }
  }

  /// Get location with high accuracy for attendance tracking
  Future<Location?> getHighAccuracyLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return getCurrentLocation(
      timeout: timeout,
      desiredAccuracy: 5.0, // 5 meter accuracy
    );
  }

  /// Validate if current location is within allowed radius of job location
  Future<LocationValidationResult> validateCurrentLocationForJob(
    JobLocation jobLocation,
  ) async {
    try {
      final currentLocation = await getHighAccuracyLocation();

      if (currentLocation == null) {
        return const LocationValidationResult(
          isValid: false,
          distance: 0,
          allowedRadius: 0,
          reason: 'Unable to determine current location',
        );
      }

      return jobLocation.validateAttendanceLocation(currentLocation);
    } catch (e) {
      return LocationValidationResult(
        isValid: false,
        distance: 0,
        allowedRadius: jobLocation.allowedRadius,
        reason: 'Location error: $e',
      );
    }
  }

  /// Start location stream for real-time tracking
  Stream<Location> getLocationStream({
    Duration interval = const Duration(seconds: 5),
    double? distanceFilter,
  }) {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter?.round() ?? 0,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => Location(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              timestamp: position.timestamp,
              altitude: position.altitude,
              heading: position.heading,
              speed: position.speed,
            ));
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      print('❌ LocationService: Error opening settings: $e');
    }
  }

  /// Open app-specific location settings
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      print('❌ LocationService: Error opening app settings: $e');
    }
  }

  /// Convert Geolocator permission to our permission enum
  LocationPermissionStatus _convertPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  /// Convert accuracy value to LocationAccuracy enum
  LocationAccuracy _convertAccuracy(double? accuracy) {
    if (accuracy == null) return LocationAccuracy.high;

    if (accuracy <= 5) return LocationAccuracy.best;
    if (accuracy <= 10) return LocationAccuracy.high;
    if (accuracy <= 50) return LocationAccuracy.medium;
    return LocationAccuracy.low;
  }
}

/// Location permission status enum
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  granted,
}

/// Location service exception
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
