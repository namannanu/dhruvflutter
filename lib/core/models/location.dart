import 'dart:math';

import 'package:flutter/foundation.dart';

enum LocationPermissionStatus { granted, denied, permanentlyDenied, restricted }

@immutable
class Location {
  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    this.timestamp,
    this.altitude,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy; // Accuracy in meters
  final DateTime? timestamp;
  final double? altitude; // Altitude in meters
  final double? heading; // Direction in degrees
  final double? speed; // Speed in m/s

  /// Calculate distance to another location using Haversine formula
  /// Returns distance in meters
  double distanceTo(Location other) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = latitude * (pi / 180);
    final double lat2Rad = other.latitude * (pi / 180);
    final double deltaLatRad = (other.latitude - latitude) * (pi / 180);
    final double deltaLngRad = (other.longitude - longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Check if this location is within a certain radius of another location
  bool isWithinRadius(Location target, double radiusInMeters) {
    return distanceTo(target) <= radiusInMeters;
  }

  /// Create Location from JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      address: json['address'] as String?,
      accuracy: _parseDouble(json['accuracy']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      altitude: _parseDouble(json['altitude']),
      heading: _parseDouble(json['heading']),
      speed: _parseDouble(json['speed']),
    );
  }

  /// Convert Location to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (accuracy != null) 'accuracy': accuracy,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (altitude != null) 'altitude': altitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    };
  }

  /// Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Create a copy with updated values
  Location copyWith({
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    DateTime? timestamp,
    double? altitude,
    double? heading,
    double? speed,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
    );
  }

  /// Get formatted coordinates string
  String get coordinatesString => '$latitude, $longitude';

  /// Get location accuracy description
  String get accuracyDescription {
    if (accuracy == null) return 'Unknown accuracy';
    if (accuracy! <= 5) {
      return 'Very high accuracy (±${accuracy!.toStringAsFixed(1)}m)';
    }
    if (accuracy! <= 10) {
      return 'High accuracy (±${accuracy!.toStringAsFixed(1)}m)';
    }
    if (accuracy! <= 50) {
      return 'Good accuracy (±${accuracy!.toStringAsFixed(1)}m)';
    }
    return 'Low accuracy (±${accuracy!.toStringAsFixed(1)}m)';
  }

  /// Check if location has sufficient accuracy for attendance tracking
  bool get hasGoodAccuracy => accuracy != null && accuracy! <= 50;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp &&
        other.altitude == altitude &&
        other.heading == heading &&
        other.speed == speed;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      address,
      accuracy,
      timestamp,
      altitude,
      heading,
      speed,
    );
  }

  @override
  String toString() {
    return 'Location(lat: $latitude, lng: $longitude${address != null ? ', address: $address' : ''})';
  }
}

@immutable
class JobLocation extends Location {
  const JobLocation({
    required super.latitude,
    required super.longitude,
    super.address,
    super.accuracy,
    super.timestamp,
    super.altitude,
    super.heading,
    super.speed,
    required this.allowedRadius,
    this.name,
    this.description,
    this.isActive = true,
  });

  final double
      allowedRadius; // Radius in meters within which workers can clock in/out
  final String? name; // Location name (e.g., "Main Office", "Warehouse A")
  final String? description; // Additional description
  final bool
      isActive; // Whether this location is currently active for attendance

  /// Check if a worker's location is valid for attendance at this job location
  bool isValidAttendanceLocation(Location workerLocation) {
    if (!isActive) return false;
    return workerLocation.isWithinRadius(this, allowedRadius);
  }

  /// Get validation result with detailed information
  LocationValidationResult validateAttendanceLocation(Location workerLocation) {
    if (!isActive) {
      return LocationValidationResult(
        isValid: false,
        distance: distanceTo(workerLocation),
        allowedRadius: allowedRadius,
        reason: 'Job location is not active for attendance tracking',
      );
    }

    final distance = distanceTo(workerLocation);
    final isValid = distance <= allowedRadius;

    return LocationValidationResult(
      isValid: isValid,
      distance: distance,
      allowedRadius: allowedRadius,
      reason: isValid
          ? 'Location is valid for attendance'
          : 'Worker is ${distance.toStringAsFixed(1)}m away from job location (max allowed: ${allowedRadius.toStringAsFixed(1)}m)',
    );
  }

  /// Create JobLocation from JSON
  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      latitude: Location._parseDouble(json['latitude']) ?? 0.0,
      longitude: Location._parseDouble(json['longitude']) ?? 0.0,
      address: json['address'] as String?,
      accuracy: Location._parseDouble(json['accuracy']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      altitude: Location._parseDouble(json['altitude']),
      heading: Location._parseDouble(json['heading']),
      speed: Location._parseDouble(json['speed']),
      allowedRadius: Location._parseDouble(json['allowedRadius']) ?? 100.0,
      name: json['name'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert JobLocation to JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'allowedRadius': allowedRadius,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
    });
    return json;
  }

  @override
  JobLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    DateTime? timestamp,
    double? altitude,
    double? heading,
    double? speed,
    double? allowedRadius,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return JobLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      allowedRadius: allowedRadius ?? this.allowedRadius,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'JobLocation(${super.toString()}, radius: ${allowedRadius}m${name != null ? ', name: $name' : ''})';
  }
}

@immutable
class LocationValidationResult {
  const LocationValidationResult({
    required this.isValid,
    required this.distance,
    required this.allowedRadius,
    required this.reason,
  });

  final bool isValid;
  final double distance; // Distance in meters
  final double allowedRadius; // Allowed radius in meters
  final String reason;

  String get distanceDescription {
    if (distance < 1) {
      return '${(distance * 100).toStringAsFixed(0)}cm';
    } else if (distance < 1000) {
      return '${distance.toStringAsFixed(1)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)}km';
    }
  }

  @override
  String toString() {
    return 'LocationValidationResult(isValid: $isValid, distance: $distanceDescription, reason: $reason)';
  }
}
