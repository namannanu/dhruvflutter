// ignore_for_file: deprecated_member_use

// ignore_for_file: deprecated_member_use

// ignore_for_file: deprecated_member_use

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:talent/core/models/place.dart';
import 'package:talent/core/services/google_places_service.dart';

class WorkLocationPickerResult {
  const WorkLocationPickerResult({
    required this.place,
    required this.allowedRadius,
    this.notes,
  });

  final PlaceDetails place;
  final double allowedRadius;
  final String? notes;
}

Future<WorkLocationPickerResult?> showWorkLocationPicker(
  BuildContext context, {
  PlaceDetails? initialPlace,
  double initialRadiusMeters = 150,
  String? initialNotes,
}) {
  return showModalBottomSheet<WorkLocationPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _WorkLocationPickerSheet(
      initialPlace: initialPlace,
      initialRadiusMeters: initialRadiusMeters,
      initialNotes: initialNotes,
    ),
  );
}

class _WorkLocationPickerSheet extends StatefulWidget {
  const _WorkLocationPickerSheet({
    this.initialPlace,
    this.initialRadiusMeters = 150,
    this.initialNotes,
  });

  final PlaceDetails? initialPlace;
  final double initialRadiusMeters;
  final String? initialNotes;

  @override
  State<_WorkLocationPickerSheet> createState() =>
      _WorkLocationPickerSheetState();
}

class _WorkLocationPickerSheetState extends State<_WorkLocationPickerSheet> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _placesService = GooglePlacesService();
  final ValueNotifier<bool> _isFetchingDetails = ValueNotifier(false);

  GoogleMapController? _mapController;
  PlaceDetails? _selectedPlace;
  double _radiusMeters = 150;
  String? _sessionToken;
  String? _lastAutocompleteError;
  List<PlaceSuggestion> _suggestions = [];

  static const _minRadius = 10.0;
  static const _maxRadius = 5000.0;

  // Safe division helper to prevent NaN values
  int _safeDivisions(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return 10;
    return value.toInt().clamp(1, 1000);
  }

  @override
  void initState() {
    super.initState();
    _radiusMeters = widget.initialRadiusMeters.clamp(_minRadius, _maxRadius);
    _selectedPlace = widget.initialPlace;
    _notesController.text = widget.initialNotes ?? '';
    _sessionToken = _placesService.newSessionToken();
    _log(
        'Session started token=$_sessionToken radius=$_radiusMeters place=${_selectedPlace?.placeId ?? 'none'}');

    if (widget.initialPlace != null) {
      _searchController.text = widget.initialPlace!.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToSelected();
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _notesController.dispose();
    _isFetchingDetails.dispose();
    super.dispose();
  }

  Future<void> _animateToSelected() async {
    final place = _selectedPlace;
    if (place == null || _mapController == null) return;
    if (!place.hasValidCoordinates) {
      _log(
          'Skipping camera animation: invalid coordinates for ${place.placeId}');
      return;
    }
    _log('Animating camera to ${place.placeId} at radius=$_radiusMeters');
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: place.location,
          zoom: _zoomForRadius(_radiusMeters),
        ),
      ),
    );
  }

  double _zoomForRadius(double radius) {
    // Rough approximation: zoom out as radius increases
    if (radius <= 50) return 16.5;
    if (radius <= 100) return 16;
    if (radius <= 250) return 15;
    if (radius <= 500) return 14;
    if (radius <= 1000) return 13;
    if (radius <= 2000) return 12;
    if (radius <= 5000) return 11;
    return 10;
  }

  Future<void> _handleSuggestionSelected(PlaceSuggestion suggestion) async {
    _log(
        'Suggestion selected: ${suggestion.placeId} :: ${suggestion.primaryText}');
    setState(() => _searchController.text = suggestion.primaryText);
    _isFetchingDetails.value = true;
    try {
      final details = await _placesService.fetchPlaceDetails(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      );
      if (!details.hasValidCoordinates) {
        _log(
            'Details missing coordinates: ${details.placeId} lat=${details.latitude} lng=${details.longitude}');
        _showSnackBar(
          'Google did not return map coordinates for this place. Try another result.',
          color: Colors.orange,
        );
        return;
      }
      _log('Details loaded: ${details.placeId}');
      setState(() {
        _selectedPlace = details;
      });
      await _animateToSelected();
    } catch (error) {
      _log('Details error: $error');

      // Check if this is a NOT_FOUND error (expired Place ID)
      if (error is PlacesApiException && error.status == 'NOT_FOUND') {
        _log('Place ID expired, trying fallback approach...');
        await _handleExpiredPlaceId(suggestion);
        return;
      }

      _showSnackBar(
        error is PlacesApiException
            ? error.message
            : 'Failed to load place details: $error',
        color: Colors.red,
      );
    } finally {
      _isFetchingDetails.value = false;
    }
  }

  Future<void> _handleExpiredPlaceId(PlaceSuggestion suggestion) async {
    try {
      // Fallback: Search for the same location to get a fresh Place ID
      _log('Searching for fresh Place ID for: ${suggestion.description}');
      final freshSuggestions = await _placesService.fetchAutocomplete(
        input: suggestion.description ?? suggestion.primaryText,
        sessionToken: _sessionToken,
      );

      if (freshSuggestions.isNotEmpty) {
        final freshSuggestion = freshSuggestions.first;
        _log('Found fresh suggestion: ${freshSuggestion.placeId}');

        // Try the details request with the fresh Place ID
        final details = await _placesService.fetchPlaceDetails(
          placeId: freshSuggestion.placeId,
          sessionToken: _sessionToken,
        );

        if (details.hasValidCoordinates) {
          _log('Fresh details loaded successfully');
          setState(() {
            _selectedPlace = details;
          });
          await _animateToSelected();
          return;
        }
      }

      // If we still can't get details, show a helpful message
      _showSnackBar(
        'This location could not be loaded. The Google Places service may have outdated information for this address. Please try selecting a different location or try again later.',
        color: Colors.orange,
      );
    } catch (fallbackError) {
      _log('Fallback approach also failed: $fallbackError');
      _showSnackBar(
        'Unable to load this location. Please try selecting a different location.',
        color: Colors.red,
      );
    }
  }

  void _submit() {
    final place = _selectedPlace;
    if (place == null) {
      _log('Submit blocked: no place selected');
      _showSnackBar('Select a location first', color: Colors.orange);
      return;
    }

    if (!place.hasValidCoordinates) {
      _log('Submit blocked: invalid coordinates for ${place.placeId}');
      _showSnackBar(
        'Selected place is missing coordinates. Please choose another location.',
        color: Colors.orange,
      );
      return;
    }

    _log(
        'Submitting place=${place.placeId} radius=$_radiusMeters notes=${_notesController.text.trim()}');
    Navigator.of(context).pop(
      WorkLocationPickerResult(
        place: place,
        allowedRadius: _radiusMeters,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assign Work Location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_placesService.isConfigured)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Google Places API key not configured. Update EnvironmentConfig or pass --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY.',
                style: TextStyle(color: Colors.orange),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search for a location',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) async {
                    debugPrint(
                        '🔍 TextField: onChanged called with value="$value"');
                    if (value.trim().isNotEmpty) {
                      debugPrint('🔍 Manual: Triggering fetch for "$value"');
                      try {
                        final suggestions = await _fetchSuggestions(value);
                        debugPrint(
                            '🔍 Manual: Got ${suggestions.length} suggestions');
                        setState(() {
                          _suggestions = suggestions;
                        });
                      } catch (e) {
                        debugPrint('🔍 Manual: Error fetching suggestions: $e');
                        setState(() {
                          _suggestions = [];
                        });
                      }
                    } else {
                      setState(() {
                        _suggestions = [];
                      });
                    }
                  },
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(suggestion.primaryText),
                          subtitle: suggestion.secondaryText != null
                              ? Text(suggestion.secondaryText!)
                              : (suggestion.description != null
                                  ? Text(suggestion.description!)
                                  : null),
                          onTap: () {
                            debugPrint(
                                '🔍 Manual: Selected "${suggestion.primaryText}"');
                            _handleSuggestionSelected(suggestion);
                            setState(() {
                              _suggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _isFetchingDetails,
            builder: (context, fetching, child) {
              if (fetching) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_selectedPlace == null) {
                return Container(
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Select a location to preview'),
                );
              }

              final place = _selectedPlace!;
              if (!place.hasValidCoordinates) {
                return Container(
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                      'Selected place is missing map coordinates. Please choose another location.'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: place.location,
                          zoom: _zoomForRadius(_radiusMeters),
                        ),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected-place'),
                            position: place.location,
                          ),
                        },
                        circles: {
                          Circle(
                            circleId: const CircleId('radius'),
                            center: place.location,
                            radius: _radiusMeters,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.12),
                            strokeColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                            strokeWidth: 1,
                          )
                        },
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          _log('GoogleMap created; controller ready');
                          await _animateToSelected();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pin_drop),
                    title: Text(place.name),
                    subtitle: Text(place.formattedAddress),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allowed radius: ${_radiusMeters.toStringAsFixed(0)} m',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    tooltip: 'Reset radius to default (150m)',
                    onPressed: () => setState(() => _radiusMeters = 150),
                    icon: const Icon(Icons.refresh),
                  )
                ],
              ),
              Slider(
                min: _minRadius,
                max: _maxRadius,
                divisions: _safeDivisions(_maxRadius - _minRadius),
                value: _radiusMeters,
                label: '${_radiusMeters.toStringAsFixed(0)} m',
                onChanged: (value) {
                  _log('Radius changed from $_radiusMeters to $value');
                  setState(() => _radiusMeters = value);
                  unawaited(_animateToSelected());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes for worker (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Location'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('WorkLocationPicker :: $message');
  }
}

extension on _WorkLocationPickerSheetState {
  Future<List<PlaceSuggestion>> _fetchSuggestions(String pattern) async {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) {
      return const <PlaceSuggestion>[];
    }

    _log('Autocomplete query="$trimmed" token=$_sessionToken');
    debugPrint('🔍 WorkLocationPicker: Fetching suggestions for "$trimmed"');
    try {
      final results = await _placesService.fetchAutocomplete(
        input: trimmed,
        sessionToken: _sessionToken,
      );
      _lastAutocompleteError = null;
      debugPrint('🔍 WorkLocationPicker: Got ${results.length} suggestions');
      for (int i = 0; i < results.length && i < 3; i++) {
        debugPrint(
            '🔍 WorkLocationPicker: [$i] ${results[i].primaryText} - ${results[i].description}');
      }
      return results;
    } catch (error) {
      final message = error is PlacesApiException ? error.message : '$error';
      _log('Autocomplete error for "$trimmed": $message');
      debugPrint('🔍 WorkLocationPicker: Error fetching suggestions: $message');
      _handleAutocompleteError(message);
      return const <PlaceSuggestion>[];
    }
  }

  void _handleAutocompleteError(String message) {
    if (message == _lastAutocompleteError) {
      return;
    }
    _lastAutocompleteError = message;
    _showSnackBar(message, color: Colors.red);
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
