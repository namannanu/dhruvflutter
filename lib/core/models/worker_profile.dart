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
    this.isPremium = false,
    this.premiumExpiresAt,
    this.profilePicture,
    this.profilePictureSmall,
    this.profilePictureMedium,
    this.portfolioImages = const [],
    this.portfolioThumbnails = const [],
    this.portfolioPreviews = const [],
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
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  // Profile picture fields
  final String? profilePicture;
  final String? profilePictureSmall;
  final String? profilePictureMedium;
  final List<String> portfolioImages;
  final List<String> portfolioThumbnails;
  final List<String> portfolioPreviews;

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
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? profilePicture,
    String? profilePictureSmall,
    String? profilePictureMedium,
    List<String>? portfolioImages,
    List<String>? portfolioThumbnails,
    List<String>? portfolioPreviews,
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
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureSmall: profilePictureSmall ?? this.profilePictureSmall,
      profilePictureMedium: profilePictureMedium ?? this.profilePictureMedium,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      portfolioThumbnails: portfolioThumbnails ?? this.portfolioThumbnails,
      portfolioPreviews: portfolioPreviews ?? this.portfolioPreviews,
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
      isPremium: boolValue(payload['isPremium']),
      premiumExpiresAt: payload['premiumExpiresAt'] != null
          ? DateTime.tryParse(payload['premiumExpiresAt'].toString())
          : null,
      profilePicture: _extractProfilePicture(payload),
      profilePictureSmall: _extractProfilePictureSmall(payload),
      profilePictureMedium: _extractProfilePictureMedium(payload),
      portfolioImages: _extractPortfolioImages(payload),
      portfolioThumbnails: _extractPortfolioThumbnails(payload),
      portfolioPreviews: _extractPortfolioPreviews(payload),
    );
  }

  // Helper methods to extract optimized profile picture URLs
  static String? _extractProfilePicture(Map<String, dynamic> payload) {
    // Try profilePicture first
    if (payload['profilePicture'] != null &&
        payload['profilePicture'].toString().trim().isNotEmpty) {
      return payload['profilePicture'].toString().trim();
    }
    return null;
  }

  static String? _extractProfilePictureSmall(Map<String, dynamic> payload) {
    if (payload['profilePictureSmall'] != null) {
      return payload['profilePictureSmall'].toString().trim();
    }
    return null;
  }

  static String? _extractProfilePictureMedium(Map<String, dynamic> payload) {
    if (payload['profilePictureMedium'] != null) {
      return payload['profilePictureMedium'].toString().trim();
    }
    return null;
  }

  static List<String> _extractPortfolioImages(Map<String, dynamic> payload) {
    final images = payload['portfolioImages'];
    if (images is List) {
      return images.whereType<String>().map((e) => e.trim()).toList();
    }
    return [];
  }

  static List<String> _extractPortfolioThumbnails(
      Map<String, dynamic> payload) {
    final thumbnails = payload['portfolioThumbnails'];
    if (thumbnails is List) {
      return thumbnails.whereType<String>().map((e) => e.trim()).toList();
    }
    return [];
  }

  static List<String> _extractPortfolioPreviews(Map<String, dynamic> payload) {
    final previews = payload['portfolioPreviews'];
    if (previews is List) {
      return previews.whereType<String>().map((e) => e.trim()).toList();
    }
    return [];
  }

  // Helper method to extract original profile picture URL
  static String? _extractProfilePictureOriginalUrl(
      Map<String, dynamic> payload) {
    final profilePicture = payload['profilePicture'];
    if (profilePicture is Map<String, dynamic>) {
      final original = profilePicture['original'];
      if (original is Map<String, dynamic> && original['url'] != null) {
        return original['url'].toString().trim();
      }
    }
    return null;
  }

  // Helper method to extract square profile picture URL
  static String? _extractProfilePictureSquareUrl(Map<String, dynamic> payload) {
    final profilePicture = payload['profilePicture'];
    if (profilePicture is Map<String, dynamic>) {
      final square = profilePicture['square'];
      if (square is Map<String, dynamic> && square['url'] != null) {
        return square['url'].toString().trim();
      }
    }
    return null;
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
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (profilePictureSmall != null)
        'profilePictureSmall': profilePictureSmall,
      if (profilePictureMedium != null)
        'profilePictureMedium': profilePictureMedium,
      'portfolioImages': portfolioImages,
      'portfolioThumbnails': portfolioThumbnails,
      'portfolioPreviews': portfolioPreviews,
    };
  }
}
