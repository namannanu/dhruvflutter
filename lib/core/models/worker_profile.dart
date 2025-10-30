import 'package:flutter/foundation.dart';

@immutable
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.skills,
    required this.rating,
    required this.experience,
    required this.languages,
    required this.availability,
    required this.isVerified,
    required this.completedJobs,
    required this.bio,
    required this.weeklyEarnings,
    required this.totalEarnings,
    required this.notificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.preferredRadiusMiles,
    this.minimumPay,
    this.maxTravelDistance,
    this.availableForFullTime = false,
    this.availableForPartTime = true,
    this.availableForTemporary = true,
    this.weekAvailability = 'All week',
    this.isVisible,
    this.locationEnabled,
    this.shareWorkHistory,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final List<String> skills;
  final double rating;
  final String experience;
  final List<String> languages;
  final List<Map<String, dynamic>> availability;
  final bool isVerified;
  final int completedJobs;
  final String bio;
  final double weeklyEarnings;
  final double totalEarnings;
  final bool notificationsEnabled;
  final bool emailNotificationsEnabled;
  final double preferredRadiusMiles;
  final double? minimumPay;
  final double? maxTravelDistance;
  final bool availableForFullTime;
  final bool availableForPartTime;
  final bool availableForTemporary;
  final String weekAvailability;
  final bool? isVisible;
  final bool? locationEnabled;
  final bool? shareWorkHistory;

  WorkerProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    List<String>? skills,
    double? rating,
    String? experience,
    List<String>? languages,
    List<Map<String, dynamic>>? availability,
    bool? isVerified,
    int? completedJobs,
    String? bio,
    double? weeklyEarnings,
    double? totalEarnings,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    double? preferredRadiusMiles,
    double? minimumPay,
    double? maxTravelDistance,
    bool? availableForFullTime,
    bool? availableForPartTime,
    bool? availableForTemporary,
    String? weekAvailability,
    bool? isVisible,
    bool? locationEnabled,
    bool? shareWorkHistory,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
      isVerified: isVerified ?? this.isVerified,
      completedJobs: completedJobs ?? this.completedJobs,
      bio: bio ?? this.bio,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      preferredRadiusMiles: preferredRadiusMiles ?? this.preferredRadiusMiles,
      minimumPay: minimumPay ?? this.minimumPay,
      maxTravelDistance: maxTravelDistance ?? this.maxTravelDistance,
      availableForFullTime: availableForFullTime ?? this.availableForFullTime,
      availableForPartTime: availableForPartTime ?? this.availableForPartTime,
      availableForTemporary:
          availableForTemporary ?? this.availableForTemporary,
      weekAvailability: weekAvailability ?? this.weekAvailability,
      isVisible: isVisible ?? this.isVisible,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      shareWorkHistory: shareWorkHistory ?? this.shareWorkHistory,
    );
  }

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> unwrap(Map<String, dynamic> input) {
      Map<String, dynamic>? asMap(dynamic value) {
        if (value is Map<String, dynamic>) {
          return Map<String, dynamic>.from(value);
        }
        if (value is Map) {
          return value.map((key, value) => MapEntry('$key', value));
        }
        return null;
      }

      Map<String, dynamic>? payload;

      final data = asMap(input['data']);
      if (data != null) {
        payload = asMap(data['profile']) ?? asMap(data['worker']) ?? data;
        final user = asMap(data['user']);
        if (user != null) {
          payload = {
            ...user,
            ...payload,
          };
        }
      }

      payload ??= asMap(input['profile']) ?? asMap(input['worker']);

      if (payload != null) {
        final user = asMap(input['user']);
        if (user != null) {
          payload = {
            ...user,
            ...payload,
          };
        }
        return payload;
      }

      return input;
    }

    String stringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is num || value is bool) return value.toString();
      return value.toString();
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      final normalized = stringValue(value).toLowerCase();
      if (normalized.isEmpty) return false;
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'available' ||
          normalized == 'enabled';
    }

    double doubleValue(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(stringValue(value)) ?? 0;
    }

    int intValue(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(stringValue(value)) ?? 0;
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map(stringValue).where((item) => item.isNotEmpty).toList();
      }
      return const <String>[];
    }

    List<Map<String, dynamic>> availabilityList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      return const <Map<String, dynamic>>[];
    }

    double? nullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    bool? nullableBool(dynamic value) {
      if (value == null) return null;
      return boolValue(value);
    }

    final payload = unwrap(Map<String, dynamic>.from(json));

    return WorkerProfile(
      id: stringValue(payload['id'] ?? payload['_id']),
      firstName: stringValue(payload['firstName']),
      lastName: stringValue(payload['lastName']),
      email: stringValue(payload['email']),
      phone: stringValue(payload['phone'] ?? payload['phoneNumber']),
      skills: stringList(payload['skills']),
      rating: doubleValue(payload['rating']),
      experience: stringValue(payload['experience']),
      languages: stringList(payload['languages']),
      availability: availabilityList(payload['availability']),
      isVerified: boolValue(
        payload['isVerified'] ?? (payload['verificationStatus'] == 'verified'),
      ),
      completedJobs: intValue(payload['completedJobs']),
      bio: stringValue(payload['bio']),
      weeklyEarnings: doubleValue(payload['weeklyEarnings']),
      totalEarnings: doubleValue(payload['totalEarnings']),
      notificationsEnabled: boolValue(payload['notificationsEnabled']),
      emailNotificationsEnabled:
          boolValue(payload['emailNotificationsEnabled'] ?? true),
      preferredRadiusMiles: doubleValue(payload['preferredRadiusMiles']).abs(),
      minimumPay: nullableDouble(payload['minimumPay']),
      maxTravelDistance: nullableDouble(payload['maxTravelDistance']),
      availableForFullTime: boolValue(
        payload['availableForFullTime'] ?? payload['fullTime'],
      ),
      availableForPartTime: payload['availableForPartTime'] == null
          ? true
          : boolValue(payload['availableForPartTime']),
      availableForTemporary: payload['availableForTemporary'] == null
          ? true
          : boolValue(payload['availableForTemporary']),
      weekAvailability: stringValue(payload['weekAvailability'] ?? 'All week'),
      isVisible: nullableBool(payload['isVisible']),
      locationEnabled: nullableBool(payload['locationEnabled']),
      shareWorkHistory: nullableBool(payload['shareWorkHistory']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'skills': skills,
      'rating': rating,
      'experience': experience,
      'languages': languages,
      'availability': availability,
      'isVerified': isVerified,
      'completedJobs': completedJobs,
      'bio': bio,
      'weeklyEarnings': weeklyEarnings,
      'totalEarnings': totalEarnings,
      'notificationsEnabled': notificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'preferredRadiusMiles': preferredRadiusMiles,
      'minimumPay': minimumPay,
      'maxTravelDistance': maxTravelDistance,
      'availableForFullTime': availableForFullTime,
      'availableForPartTime': availableForPartTime,
      'availableForTemporary': availableForTemporary,
      'weekAvailability': weekAvailability,
      'isVisible': isVisible,
      'locationEnabled': locationEnabled,
      'shareWorkHistory': shareWorkHistory,
    };
  }
}
