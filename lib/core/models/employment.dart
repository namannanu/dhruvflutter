import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:talent/core/models/location.dart';

@immutable
class EmploymentWorkLocation {
  const EmploymentWorkLocation({
    this.label,
    this.formattedAddress,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.allowedRadius,
    this.placeId,
    this.notes,
    this.timezone,
    this.setBy,
    this.setAt,
  });

  final String? label;
  final String? formattedAddress;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final double? allowedRadius;
  final String? placeId;
  final String? notes;
  final String? timezone;
  final String? setBy;
  final DateTime? setAt;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      !latitude!.isNaN &&
      !longitude!.isNaN;

  bool get hasValidCoordinates => hasCoordinates &&
      latitude! >= -90 && latitude! <= 90 &&
      longitude! >= -180 && longitude! <= 180;

  LatLng? get latLng =>
      hasValidCoordinates ? LatLng(latitude!, longitude!) : null;

  JobLocation? get toJobLocation => hasValidCoordinates
      ? JobLocation(
          latitude: latitude!,
          longitude: longitude!,
          address: formattedAddress ?? address,
          allowedRadius: allowedRadius ?? 150,
          name: label,
          description: notes,
        )
      : null;

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      if (formattedAddress != null) 'formattedAddress': formattedAddress,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postalCode': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (allowedRadius != null) 'allowedRadius': allowedRadius,
      if (placeId != null) 'placeId': placeId,
      if (notes != null) 'notes': notes,
      if (timezone != null) 'timezone': timezone,
      if (setBy != null) 'setBy': setBy,
      if (setAt != null) 'setAt': setAt!.toIso8601String(),
    };
  }

  factory EmploymentWorkLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmploymentWorkLocation();
    }

    return EmploymentWorkLocation(
      label: json['label']?.toString(),
      formattedAddress: json['formattedAddress']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      allowedRadius: (json['allowedRadius'] as num?)?.toDouble(),
      placeId: json['placeId']?.toString(),
      notes: json['notes']?.toString(),
      timezone: json['timezone']?.toString(),
      setBy: json['setBy']?.toString(),
      setAt: json['setAt'] != null
          ? DateTime.tryParse(json['setAt'].toString())
          : null,
    );
  }
}

double? _parseCoordinate(dynamic value) {
  if (value == null) return null;
  double? parsed;
  if (value is num) {
    parsed = value.toDouble();
  } else if (value is String) {
    parsed = double.tryParse(value);
  }

  if (parsed == null || parsed.isNaN || !parsed.isFinite) {
    return null;
  }

  if (parsed < -1000 || parsed > 1000) {
    return null;
  }

  return parsed;
}

@immutable
class EmploymentRecord {
  const EmploymentRecord({
    required this.id,
    required this.workerId,
    required this.employerId,
    required this.jobId,
    required this.businessId,
    required this.position,
    required this.hourlyRate,
    required this.employmentStatus,
    required this.hireDate,
    this.endDate,
    this.workLocation,
  });

  final String id;
  final String workerId;
  final String employerId;
  final String jobId;
  final String businessId;
  final String position;
  final double hourlyRate;
  final String employmentStatus;
  final DateTime hireDate;
  final DateTime? endDate;
  final EmploymentWorkLocation? workLocation;

  bool get isActive => employmentStatus == 'active';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker': workerId,
      'employer': employerId,
      'job': jobId,
      'business': businessId,
      'position': position,
      'hourlyRate': hourlyRate,
      'employmentStatus': employmentStatus,
      'hireDate': hireDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (workLocation != null) 'workLocationDetails': workLocation!.toJson(),
      if (workLocation?.label != null) 'workLocation': workLocation!.label,
    };
  }

  factory EmploymentRecord.fromJson(Map<String, dynamic> json) {
    String? stringValue(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return EmploymentRecord(
      id: stringValue(json['_id']) ?? stringValue(json['id']) ?? '',
      workerId: stringValue(json['worker']) ?? '',
      employerId: stringValue(json['employer']) ?? '',
      jobId: stringValue(json['job']) ?? '',
      businessId: stringValue(json['business']) ?? '',
      position: stringValue(json['position']) ?? 'Role',
      hourlyRate: parseDouble(json['hourlyRate']),
      employmentStatus: stringValue(json['employmentStatus']) ?? 'active',
      hireDate: parseDate(json['hireDate']),
      endDate: json['endDate'] != null ? parseDate(json['endDate']) : null,
      workLocation:
          EmploymentWorkLocation.fromJson(
              json['workLocationDetails'] as Map<String, dynamic>?),
    );
  }
}
