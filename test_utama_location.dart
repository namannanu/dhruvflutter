import 'lib/core/services/google_places_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Test script to verify the "1 Utama Shopping Centre" location parsing
void main() async {
  print('🧪 Testing location that causes crash...');

  try {
    // Test creating LatLng with coordinates known to be problematic
    print('Testing LatLng creation...');

    // 1 Utama Shopping Centre coordinates (approximate)
    const lat = 3.1502;
    const lng = 101.6144;

    print('Creating LatLng($lat, $lng)...');
    final location = LatLng(lat, lng);
    print('✅ LatLng created: $location');

    // Test the specific Place ID that's causing issues
    const problemPlaceId =
        'ChIJL-Qvn9JOzDERBLmeTTrrgf0'; // 1 Utama Shopping Centre

    print('Testing place details for place ID: $problemPlaceId');
    final placesService = GooglePlacesService();

    final details = await placesService.fetchPlaceDetails(
      placeId: problemPlaceId,
    );

    print('✅ Successfully loaded place details:');
    print('   - Place ID: ${details.placeId}');
    print('   - Name: ${details.name}');
    print('   - Address: ${details.formattedAddress}');
    print('   - Coordinates: ${details.latitude}, ${details.longitude}');
    print('   - Valid coordinates: ${details.hasValidCoordinates}');
  } catch (e, stackTrace) {
    print('❌ Error occurred: $e');
    print('Stack trace: $stackTrace');
  }

  print('🎉 Test completed without app crash!');
}
