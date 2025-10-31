import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:talent/core/config/environment_config.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';

/// Lightweight client for Google Places Autocomplete & Details endpoints.
class GooglePlacesService {
  GooglePlacesService({
    String? apiKey,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 6),
  })  : _apiKey = apiKey ?? EnvironmentConfig.googlePlacesApiKey,
        _client = httpClient ?? http.Client(),
        _timeout = timeout {
    _log(
        'Initialized with API key: ${_apiKey.isNotEmpty ? '${_apiKey.substring(0, 6)}***' : 'EMPTY'} (configured=$isConfigured)');
  }

  final String _apiKey;
  final http.Client _client;
  final Duration _timeout;
  final Uuid _uuid = const Uuid();

  /// Autocomplete endpoint base
  static const _autocompletePath = '/maps/api/place/autocomplete/json';

  /// Details endpoint base
  static const _detailsPath = '/maps/api/place/details/json';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns a session token for grouping autocomplete+details requests.
  String newSessionToken() => _uuid.v4();

  Future<List<PlaceSuggestion>> fetchAutocomplete({
    required String input,
    String? sessionToken,
    double? latitude,
    double? longitude,
    int radiusMeters = 50000,
    String language = 'en',
    List<String>? types,
  }) async {
    if (input.trim().isEmpty) {
      return const <PlaceSuggestion>[];
    }

    _assertConfigured();

    final query = <String, String>{
      'input': input,
      'key': _apiKey,
      'language': language,
    };

    if (types != null && types.isNotEmpty) {
      query['types'] = types.join('|');
    } else {
      query['types'] = 'geocode|establishment';
    }

    if (sessionToken != null) {
      query['sessiontoken'] = sessionToken;
    }

    if (latitude != null && longitude != null) {
      query['location'] = '$latitude,$longitude';
      query['radius'] = radiusMeters.toString();
    }

    final uri = Uri.https('maps.googleapis.com', _autocompletePath, query);
    _log('Autocomplete request → $uri');
    debugPrint('🔍 GooglePlaces: Making autocomplete request to $uri');
    debugPrint('👉 Places request URL: $uri');
    debugPrint('🔍 GooglePlaces: Query parameters: $query');

    try {
      final response = await _client.get(uri).timeout(_timeout,
          onTimeout: () => throw const PlacesApiException(
              'Places autocomplete request timed out'));

      _log(
          'Autocomplete response status=${response.statusCode} body=${response.body}');
      debugPrint('🔍 GooglePlaces: Response status=${response.statusCode}');
      debugPrint('🔍 GooglePlaces: Response body=${response.body}');

      if (response.statusCode != 200) {
        throw PlacesApiException(
          'Places autocomplete failed with status code ${response.statusCode}: ${response.body}',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final status = payload['status']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        final errorMessage = payload['error_message']?.toString();
        throw PlacesApiException(
          _friendlyAutocompleteError(status, errorMessage),
          status: status,
        );
      }

      final predictions =
          (payload['predictions'] as List?) ?? const <dynamic>[];

      // Safe parsing of predictions to prevent NaN values
      final suggestions = <PlaceSuggestion>[];
      for (final prediction in predictions) {
        if (prediction is Map<String, dynamic>) {
          try {
            final suggestion = PlaceSuggestion.fromJson(prediction);
            // Only add valid suggestions
            if (suggestion.placeId.isNotEmpty &&
                suggestion.primaryText.isNotEmpty) {
              suggestions.add(suggestion);
            }
          } catch (e) {
            _log('Warning: Skipped invalid prediction: $e');
            // Continue processing other predictions
          }
        }
      }

      _log('Autocomplete success: ${suggestions.length} suggestion(s)');
      return suggestions;
    } catch (e) {
      _log('Autocomplete error: $e');

      // Handle CORS errors in web browsers
      if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        _log('Web CORS error detected - Google Places API blocked by browser');
        debugPrint(
            '🌐 Web CORS Error: Google Places API blocked by browser. Consider using a proxy server for production.');

        // Return empty list instead of crashing
        return const <PlaceSuggestion>[];
      }

      rethrow;
    }
  }

  Future<PlaceDetails> fetchPlaceDetails({
    required String placeId,
    String? sessionToken,
    String language = 'en',
  }) async {
    try {
      debugPrint('🌍 GooglePlaces: Starting fetchPlaceDetails for $placeId');
      _assertConfigured();

      final query = <String, String>{
        'place_id': placeId,
        'key': _apiKey,
        'language': language,
        'fields':
            'place_id,name,formatted_address,geometry,plus_code,types,address_component',
      };

      if (sessionToken != null) {
        query['sessiontoken'] = sessionToken;
      }

      final uri = Uri.https('maps.googleapis.com', _detailsPath, query);
      _log('Details request for placeId=$placeId → $uri');
      debugPrint('🌍 GooglePlaces: Making details request');

      try {
        final response = await _client.get(uri).timeout(_timeout,
            onTimeout: () => throw const PlacesApiException(
                'Places details request timed out'));

        debugPrint(
            '🌍 GooglePlaces: Details response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw PlacesApiException(
            'Places details failed with status code ${response.statusCode}',
          );
        }

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final status = payload['status']?.toString();
        debugPrint('🌍 GooglePlaces: Details API status: $status');

        if (status != 'OK') {
          final errorMessage = payload['error_message']?.toString();
          throw PlacesApiException(
            _friendlyDetailsError(status, errorMessage),
            status: status,
          );
        }

        debugPrint('🌍 GooglePlaces: Parsing place details JSON');
        PlaceDetails details;
        try {
          details = PlaceDetails.fromJson(payload);
          debugPrint('🌍 GooglePlaces: Place details parsed successfully');

          // Validate that coordinates are safe
          if (!details.hasValidCoordinates) {
            throw PlacesApiException(
              'Place details contain invalid coordinates: lat=${details.latitude}, lng=${details.longitude}',
            );
          }
        } catch (e) {
          _log('Failed to parse place details: $e');
          throw PlacesApiException('Failed to parse place details: $e');
        }

        _log(
            'Details success: ${details.placeId} (${details.name}) @ ${details.location}');
        debugPrint('🌍 GooglePlaces: fetchPlaceDetails completed successfully');
        return details;
      } catch (httpError) {
        debugPrint('🌍 GooglePlaces: HTTP/API error: $httpError');
        rethrow;
      }
    } catch (e) {
      // Handle CORS errors in web browsers
      if (kIsWeb && e.toString().contains('XMLHttpRequest')) {
        _log('Web CORS error detected - cannot fetch place details in browser');
        debugPrint(
            '🌐 Web CORS Error: Google Places API blocked by browser. Consider using a proxy server for production.');

        // Instead of returning mock data that could cause issues, throw a clear error
        throw const PlacesApiException(
          'Google Places API is blocked by browser CORS policy. This feature requires a backend proxy server for web deployment.',
          status: 'CORS_ERROR',
        );
      }

      // Re-throw other errors
      rethrow;
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('GooglePlacesService :: $message');
    }
  }

  String _friendlyAutocompleteError(String? status, String? errorMessage) {
    final normalizedStatus = status ?? 'UNKNOWN';
    final normalizedMessage = errorMessage?.trim();
    final decodedMessage = _decodeCommonGoogleError(normalizedMessage);

    if (normalizedStatus == 'REQUEST_DENIED') {
      if (normalizedMessage != null &&
          normalizedMessage.toLowerCase().contains('disabled use cases')) {
        return 'Google Places Autocomplete is disabled for this API key. Enable the "Place Autocomplete" use case in Google Cloud and ensure billing is active.';
      }
      return decodedMessage ??
          normalizedMessage ??
          'Places Autocomplete request was denied. Verify the API key has Places API access, the Autocomplete use case enabled, and that billing is configured.';
    }

    if (normalizedStatus == 'INVALID_REQUEST') {
      if (normalizedMessage != null &&
          normalizedMessage.toLowerCase().contains('decode')) {
        return 'Places Autocomplete request was rejected by Google. Double-check the API key configuration and restrictions (see GOOGLE_PLACES_API_SETUP.md).';
      }
      return decodedMessage ??
          normalizedMessage ??
          'Places Autocomplete returned INVALID_REQUEST. Verify request parameters and API key configuration.';
    }

    return decodedMessage ??
        normalizedMessage ??
        'Places autocomplete returned $normalizedStatus';
  }

  String _friendlyDetailsError(String? status, String? errorMessage) {
    final normalizedStatus = status ?? 'UNKNOWN';
    final normalizedMessage = errorMessage?.trim();
    final decodedMessage = _decodeCommonGoogleError(normalizedMessage);

    if (normalizedStatus == 'REQUEST_DENIED') {
      return decodedMessage ??
          normalizedMessage ??
          'Places details request was denied. Confirm the Places API is enabled for this key, billing is active, and the key restrictions match this app.';
    }

    if (normalizedStatus == 'INVALID_REQUEST' &&
        normalizedMessage != null &&
        normalizedMessage.toLowerCase().contains('decode')) {
      return 'Places details response was rejected by Google. Ensure the Places API use cases are enabled for this key.';
    }

    return decodedMessage ??
        normalizedMessage ??
        'Places details returned $normalizedStatus';
  }

  String? _decodeCommonGoogleError(String? message) {
    if (message == null) return null;
    final lower = message.toLowerCase();
    if (lower.contains("can't find or decode") ||
        lower.contains('failed to get or decode unavailable reasons')) {
      return 'Google rejected this request: enable the "Place Autocomplete" (and "Place Details") use cases for your API key, ensure billing is active, and verify the key restrictions match this app.';
    }
    return null;
  }

  void _assertConfigured() {
    if (!isConfigured) {
      throw const PlacesApiException(
        'Google Places API key missing. Provide via --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY or update EnvironmentConfig.',
      );
    }
  }

  @visibleForTesting
  void dispose() {
    _client.close();
  }
}
