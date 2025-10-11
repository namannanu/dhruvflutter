import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lightweight view model representing a suggestion returned by Google Places
@immutable
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
    this.description,
  });

  final String placeId;
  final String primaryText;
  final String? secondaryText;
  final String? description;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;

    return PlaceSuggestion(
      placeId: json['place_id']?.toString() ?? '',
      primaryText: structured?['main_text']?.toString() ??
          json['description']?.toString() ??
          '',
      secondaryText: structured?['secondary_text']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

@immutable
class PlaceAddressComponent {
  const PlaceAddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  final String longName;
  final String shortName;
  final List<String> types;

  bool hasType(String type) => types.contains(type);
}

/// Full place details response used to store job/report locations.
@immutable
class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.plusCode,
    this.types = const <String>[],
    this.addressComponents = const <PlaceAddressComponent>[],
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;
  final String? plusCode;
  final List<String> types;
  final List<PlaceAddressComponent> addressComponents;

  double get latitude => location.latitude;
  double get longitude => location.longitude;

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        !latitude.isNaN &&
        !longitude.isNaN &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String? _componentLong(List<String> componentTypes) {
    for (final type in componentTypes) {
      final match = addressComponents.firstWhere(
        (component) => component.hasType(type),
        orElse: () =>
            const PlaceAddressComponent(longName: '', shortName: '', types: []),
      );
      if (match.longName.isNotEmpty) {
        return match.longName;
      }
    }
    return null;
  }

  String? _componentShort(List<String> componentTypes) {
    for (final type in componentTypes) {
      final match = addressComponents.firstWhere(
        (component) => component.hasType(type),
        orElse: () =>
            const PlaceAddressComponent(longName: '', shortName: '', types: []),
      );
      if (match.shortName.isNotEmpty) {
        return match.shortName;
      }
    }
    return null;
  }

  String? get streetNumber => _componentLong(const ['street_number']);
  String? get route => _componentLong(const ['route']);
  String? get streetAddress {
    final number = streetNumber;
    final street = route;
    if (number == null && street == null) return null;
    if (number == null) return street;
    if (street == null) return number;
    return '$number $street';
  }

  String? get city => _componentLong(const [
        'locality',
        'sublocality',
        'administrative_area_level_2',
      ]);
  String? get state => _componentLong(const ['administrative_area_level_1']);
  String? get stateShort =>
      _componentShort(const ['administrative_area_level_1']);
  String? get postalCode => _componentLong(const ['postal_code']);
  String? get country => _componentLong(const ['country']);

  Map<String, dynamic> toWorkLocationPayload({
    double? allowedRadius,
    String? notes,
    String? timezone,
  }) {
    final address = streetAddress ?? formattedAddress;
    return {
      'label': name,
      'formattedAddress': formattedAddress,
      'address': address,
      'city': city,
      'state': stateShort ?? state,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      if (allowedRadius != null) 'allowedRadius': allowedRadius,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    };
  }

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result = json['result'] is Map<String, dynamic>
        ? json['result'] as Map<String, dynamic>
        : json;
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final latitude = _safeCoordinate(location?['lat']);
    final longitude = _safeCoordinate(location?['lng']);
    final components = (result['address_components'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(
              (component) => PlaceAddressComponent(
                longName: component['long_name']?.toString() ?? '',
                shortName: component['short_name']?.toString() ?? '',
                types: (component['types'] as List?)
                        ?.map((e) => e.toString())
                        .toList(growable: false) ??
                    const <String>[],
              ),
            )
            .where((component) => component.longName.isNotEmpty)
            .toList(growable: false) ??
        const <PlaceAddressComponent>[];

    return PlaceDetails(
      placeId: result['place_id']?.toString() ?? '',
      name: result['name']?.toString() ??
          result['vicinity']?.toString() ??
          result['formatted_address']?.toString() ??
          'Selected location',
      formattedAddress: result['formatted_address']?.toString() ??
          result['name']?.toString() ??
          '',
      location: LatLng(
        latitude,
        longitude,
      ),
      plusCode: result['plus_code'] is Map
          ? (result['plus_code'] as Map)['global_code']?.toString()
          : null,
      types: (result['types'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      addressComponents: components,
    );
  }
}

double _safeCoordinate(dynamic value) {
  if (value == null) return 0;
  double? parsed;
  if (value is num) {
    parsed = value.toDouble();
  } else if (value is String) {
    parsed = double.tryParse(value);
  }

  if (parsed == null || parsed.isNaN || !parsed.isFinite) {
    return 0;
  }

  if (parsed < -1000 || parsed > 1000) {
    return 0;
  }

  return parsed;
}

class PlacesApiException implements Exception {
  const PlacesApiException(this.message, {this.status});

  final String message;
  final String? status;

  @override
  String toString() =>
      'PlacesApiException(status: ${status ?? 'unknown'}, message: $message)';
}
