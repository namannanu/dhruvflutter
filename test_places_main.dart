import 'package:flutter/material.dart';
import 'lib/core/services/google_places_service.dart';
import 'lib/core/models/place.dart';

void main() {
  runApp(const PlaceDetailsTestApp());
}

class PlaceDetailsTestApp extends StatelessWidget {
  const PlaceDetailsTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Place Details Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PlaceDetailsTestPage(),
    );
  }
}

class PlaceDetailsTestPage extends StatefulWidget {
  const PlaceDetailsTestPage({super.key});

  @override
  State<PlaceDetailsTestPage> createState() => _PlaceDetailsTestPageState();
}

class _PlaceDetailsTestPageState extends State<PlaceDetailsTestPage> {
  final _placesService = GooglePlacesService();
  PlaceDetails? _placeDetails;
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testProblemPlaceId() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing place ID...';
      _placeDetails = null;
    });

    try {
      debugPrint('🧪 Testing problematic place ID...');

      // The exact Place ID that's causing the crash
      const problemPlaceId =
          'ChIJL-Qvn9JOzDERBLmeTTrrgf0'; // 1 Utama Shopping Centre

      debugPrint('Fetching details for place ID: $problemPlaceId');
      final details = await _placesService.fetchPlaceDetails(
        placeId: problemPlaceId,
      );

      debugPrint('✅ Place details loaded successfully');
      debugPrint('   - Place ID: ${details.placeId}');
      debugPrint('   - Name: ${details.name}');
      debugPrint('   - Address: ${details.formattedAddress}');
      debugPrint('   - Coordinates: ${details.latitude}, ${details.longitude}');
      debugPrint('   - Valid coordinates: ${details.hasValidCoordinates}');

      setState(() {
        _placeDetails = details;
        _status = '✅ Place details loaded successfully!';
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('❌ Error loading place details: $error');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _status = '❌ Error: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testProblemPlaceId,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test 1 Utama Place ID'),
            ),
            const SizedBox(height: 16),
            Text(
              'Status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_placeDetails != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Place Details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Place ID: ${_placeDetails!.placeId}'),
              Text('Name: ${_placeDetails!.name}'),
              Text('Address: ${_placeDetails!.formattedAddress}'),
              Text('Latitude: ${_placeDetails!.latitude}'),
              Text('Longitude: ${_placeDetails!.longitude}'),
              Text('Valid Coordinates: ${_placeDetails!.hasValidCoordinates}'),
            ],
          ],
        ),
      ),
    );
  }
}
