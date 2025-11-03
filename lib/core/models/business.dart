import 'package:flutter/foundation.dart';
import '../utils/image_url_optimizer.dart';

@immutable
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    this.latitude,
    this.longitude,
    required this.formattedAddress,
    required this.isActive,
    this.logo,
    this.logoSmall,
    this.logoMedium,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final String formattedAddress;
  final bool isActive;
  final String? logo; // Original logo URL
  final String? logoSmall; // Optimized for lists
  final String? logoMedium; // Optimized for details

  String get displayAddress =>
      formattedAddress.isNotEmpty ? formattedAddress : address;
  bool get hasCoordinates => latitude != null && longitude != null;

  factory Business.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final String? originalLogo = json['logo']?.toString();

    return Business(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      latitude: (location['coordinates'] as List?)?.length == 2
          ? (location['coordinates'][1] as num?)?.toDouble()
          : null,
      longitude: (location['coordinates'] as List?)?.length == 2
          ? (location['coordinates'][0] as num?)?.toDouble()
          : null,
      formattedAddress: json['formattedAddress']?.toString() ?? '',
      isActive: json['isActive'] == true,
      logo: originalLogo,
      // Use provided optimized URLs or generate them
      logoSmall: json['logoSmall']?.toString() ??
          (originalLogo != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalLogo, ImageContext.companyLogoSmall)
              : null),
      logoMedium: json['logoMedium']?.toString() ??
          (originalLogo != null
              ? ImageUrlOptimizer.optimizeUrl(
                  originalLogo, ImageContext.companyLogoLarge)
              : null),
    );
  }

  Business copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    bool? isActive,
    String? logo,
    String? logoSmall,
    String? logoMedium,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      isActive: isActive ?? this.isActive,
      logo: logo ?? this.logo,
      logoSmall: logoSmall ?? this.logoSmall,
      logoMedium: logoMedium ?? this.logoMedium,
    );
  }
}

@immutable
class BusinessLocation {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final bool isActive;
  final int jobCount;
  final int hireCount;
  final String type;
  final double allowedRadius;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? notes;
  final String? logoUrl;
  final String? businessName;
  final String? businessAddress;

  const BusinessLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone,
    required this.isActive,
    required this.jobCount,
    required this.hireCount,
    required this.type,
    required this.allowedRadius,
    this.latitude,
    this.longitude,
    this.timezone,
    this.notes,
    this.logoUrl,
    this.businessName,
    this.businessAddress,
  });

  factory BusinessLocation.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> businessData =
        json['business'] as Map<String, dynamic>? ?? {};
    final dynamic locationData = json['location'];
    final double? lat;
    final double? lng;

    if (locationData is Map<String, dynamic> &&
        locationData['coordinates'] is List &&
        (locationData['coordinates'] as List).length == 2) {
      lng = (locationData['coordinates'][0] as num?)?.toDouble();
      lat = (locationData['coordinates'][1] as num?)?.toDouble();
    } else {
      lat = (json['latitude'] as num?)?.toDouble();
      lng = (json['longitude'] as num?)?.toDouble();
    }

    return BusinessLocation(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ??
          locationData?['address'] as String? ??
          '',
      city: json['city'] as String? ?? locationData?['city'] as String? ?? '',
      state:
          json['state'] as String? ?? locationData?['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ??
          locationData?['postalCode'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      jobCount: json['jobCount'] as int? ?? 0,
      hireCount: json['hireCount'] as int? ?? 0,
      type: json['type'] as String? ?? 'business',
      allowedRadius: (json['allowedRadius'] as num?)?.toDouble() ?? 5.0,
      latitude: lat,
      longitude: lng,
      timezone: json['timezone'] as String?,
      notes: json['notes'] as String?,
      logoUrl: json['logoUrl'] as String?,
      businessName: businessData['name'] as String?,
      businessAddress: businessData['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'phone': phone,
      'isActive': isActive,
      'jobCount': jobCount,
      'hireCount': hireCount,
      'type': type,
      'allowedRadius': allowedRadius,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timezone != null) 'timezone': timezone,
      if (notes != null) 'notes': notes,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (businessName != null) 'businessName': businessName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      'location': {
        if (latitude != null && longitude != null)
          'coordinates': [longitude, latitude],
        'address': address,
        'city': city,
        'state': state,
        'postalCode': postalCode,
      },
    };
  }
}
