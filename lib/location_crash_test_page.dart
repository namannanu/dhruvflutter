import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationCrashTestPage extends StatefulWidget {
  const LocationCrashTestPage({super.key});

  @override
  State<LocationCrashTestPage> createState() => _LocationCrashTestPageState();
}

class _LocationCrashTestPageState extends State<LocationCrashTestPage> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Crash Test'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _testProblemCoordinates,
            child: const Text('Test 1 Utama Coordinates'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                debugPrint('Map controller initialized');
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(3.139, 101.687), // Kuala Lumpur
                zoom: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testProblemCoordinates() async {
    debugPrint('🧪 Testing problematic coordinates...');

    try {
      // 1 Utama Shopping Centre coordinates
      const problemLat = 3.1502;
      const problemLng = 101.6144;

      debugPrint('Creating LatLng($problemLat, $problemLng)');
      const problemLocation = LatLng(problemLat, problemLng);
      debugPrint('✅ LatLng created successfully: $problemLocation');

      if (_mapController == null) {
        debugPrint('❌ Map controller is null');
        return;
      }

      debugPrint('Creating CameraPosition...');
      const cameraPosition = CameraPosition(
        target: problemLocation,
        zoom: 15.0,
      );
      debugPrint('✅ CameraPosition created');

      debugPrint('Creating CameraUpdate...');
      final cameraUpdate = CameraUpdate.newCameraPosition(cameraPosition);
      debugPrint('✅ CameraUpdate created');

      debugPrint('Animating camera...');
      await _mapController!.animateCamera(cameraUpdate);
      debugPrint('✅ Camera animation completed successfully!');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Camera animation succeeded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('❌ Error during coordinate test: $error');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
