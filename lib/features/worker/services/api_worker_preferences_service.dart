// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talent/core/models/worker_profile.dart';
import 'package:talent/core/services/locator/service_locator.dart';

class ApiWorkerPreferencesService {
  final ServiceLocator _locator;
  final http.Client _client;

  ApiWorkerPreferencesService(this._locator) : _client = http.Client();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _locator.getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<WorkerProfile> updatePreferences({
    double? minimumPay,
    double? maxTravelDistance,
    bool? availableForFullTime,
    bool? availableForPartTime,
    bool? availableForTemporary,
    String? weekAvailability,
  }) async {
    final response = await _client.patch(
      Uri.parse('${_locator.apiUrl}/workers/me'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        if (minimumPay != null) 'minimumPay': minimumPay,
        if (maxTravelDistance != null) 'maxTravelDistance': maxTravelDistance,
        if (availableForFullTime != null)
          'availableForFullTime': availableForFullTime,
        if (availableForPartTime != null)
          'availableForPartTime': availableForPartTime,
        if (availableForTemporary != null)
          'availableForTemporary': availableForTemporary,
        if (weekAvailability != null) 'weekAvailability': weekAvailability,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update preferences: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    print('Worker preferences update response: $data');

    // Extract profile data from the response structure
    final responseData = data['data'] as Map<String, dynamic>?;
    final profileData = (responseData?['profile'] ?? responseData ?? data)
        as Map<String, dynamic>;

    return WorkerProfile.fromJson(profileData);
  }

  Future<WorkerProfile> updatePrivacySettings({
    bool? isVisible,
    bool? locationEnabled,
    bool? shareWorkHistory,
  }) async {
    final response = await _client.patch(
      Uri.parse('${_locator.apiUrl}/workers/me'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        if (isVisible != null) 'isVisible': isVisible,
        if (locationEnabled != null) 'locationEnabled': locationEnabled,
        if (shareWorkHistory != null) 'shareWorkHistory': shareWorkHistory,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update privacy settings: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract profile data from the response structure
    final responseData = data['data'] as Map<String, dynamic>?;
    final profileData = (responseData?['profile'] ?? responseData ?? data)
        as Map<String, dynamic>;

    return WorkerProfile.fromJson(profileData);
  }

  Future<void> deleteAccount() async {
    final response = await _client.delete(
      Uri.parse('${_locator.apiUrl}/workers/me'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
