// ignore_for_file: avoid_print

class EnvironmentConfig {
  EnvironmentConfig._();

  static const String _primaryPlacesKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
  static const String _legacyPlacesKey =
      String.fromEnvironment('GOOGLE_PLACES_APIKEY', defaultValue: '');
  static const String _mapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  // Google Places API key from Google Cloud Console (Working and tested!)
  static const String _embeddedPlacesKey =
      'AIzaSyBdv8SvNtnaS8lsHRxKJe-Ufw61YxMOiQQ';

  static String get googlePlacesApiKey {
    if (_primaryPlacesKey.isNotEmpty) {
      print(
          '🔑 Using primary Places key: ${_primaryPlacesKey.substring(0, 10)}...');
      return _primaryPlacesKey;
    }
    if (_legacyPlacesKey.isNotEmpty) {
      print(
          '🔑 Using legacy Places key: ${_legacyPlacesKey.substring(0, 10)}...');
      return _legacyPlacesKey;
    }
    if (_mapsApiKey.isNotEmpty) {
      print('🔑 Using Maps API key: ${_mapsApiKey.substring(0, 10)}...');
      return _mapsApiKey;
    }
    print(
        '🔑 Using embedded Places key: ${_embeddedPlacesKey.substring(0, 10)}...');
    return _embeddedPlacesKey;
  }
}
