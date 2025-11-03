// ignore_for_file: require_trailing_commas, strict_raw_type

import 'package:flutter/material.dart';

export 'worker_profile.dart';

enum TeamMemberRole { manager, supervisor, admin }

enum TeamPermission {
  postJobs,
  hireWorkers,
  manageSchedules,
  viewApplications,
  managePayments,
  viewAnalytics,
}

@immutable
enum UserType { worker, employer }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserType type;

  // Extra fields from backend
  final int freeJobsPosted;
  final int freeApplicationsUsed;
  final bool isPremium;
  final String? selectedBusinessId;
  final List<UserType> roles;
  final List<BusinessAssociation> ownedBusinesses;
  final List<BusinessAssociation> teamBusinesses;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.type,
    this.freeJobsPosted = 0,
    this.freeApplicationsUsed = 0,
    this.isPremium = false,
    this.selectedBusinessId,
    this.roles = const [],
    this.ownedBusinesses = const [],
    this.teamBusinesses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final parsedRoles = _parseRoles(json['roles']);
    final inferredType = _parseUserType(
          json['userType'] ??
              json['type'] ??
              (parsedRoles.isNotEmpty ? parsedRoles.first : null),
        ) ??
        UserType.employer;

    final roles =
        parsedRoles.isNotEmpty ? parsedRoles : <UserType>[inferredType];

    String? stringValue(dynamic value) {
      if (value == null) return null;
      final stringified = value.toString().trim();
      return stringified.isEmpty ? null : stringified;
    }

    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: stringValue(json['phone']) ?? stringValue(json['phoneNumber']),
      type: inferredType,
      freeJobsPosted: (json['freeJobsPosted'] as num?)?.toInt() ?? 0,
      freeApplicationsUsed:
          (json['freeApplicationsUsed'] as num?)?.toInt() ?? 0,
      isPremium: json['premium'] == true,
      selectedBusinessId: stringValue(json['selectedBusiness']) ??
          stringValue(json['selectedBusinessId']) ??
          stringValue(json['businessId']) ??
          stringValue(json['business']),
      roles: roles,
      ownedBusinesses: BusinessAssociation.parseList(
          json['ownedBusinesses'] as List<dynamic>?),
      teamBusinesses: BusinessAssociation.parseList(
          json['teamBusinesses'] as List<dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    final roleStrings = roles.map((role) => role.name).toList();
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'userType': type.name,
      'type': type.name,
      'freeJobsPosted': freeJobsPosted,
      'freeApplicationsUsed': freeApplicationsUsed,
      'isPremium': isPremium,
      'selectedBusiness': selectedBusinessId,
      'selectedBusinessId': selectedBusinessId,
      'roles': roleStrings,
      'ownedBusinesses': ownedBusinesses.map((b) => b.toJson()).toList(),
      'teamBusinesses': teamBusinesses.map((b) => b.toJson()).toList(),
    };
  }

  static UserType? _parseUserType(dynamic raw) {
    if (raw == null) return null;
    if (raw is UserType) return raw;
    final normalized = raw.toString().trim().toLowerCase();
    final sanitized =
        normalized.contains('.') ? normalized.split('.').last : normalized;
    switch (sanitized) {
      case 'worker':
        return UserType.worker;
      case 'employer':
        return UserType.employer;
    }
    return null;
  }

  static List<UserType> _parseRoles(dynamic raw) {
    if (raw is List) {
      final parsed = <UserType>[];
      for (final entry in raw) {
        final role = _parseUserType(entry);
        if (role != null && !parsed.contains(role)) {
          parsed.add(role);
        }
      }
      return parsed;
    }
    final role = _parseUserType(raw);
    return role == null ? <UserType>[] : <UserType>[role];
  }
}

@immutable
class BusinessAssociation {
  const BusinessAssociation({
    required this.businessId,
    required this.businessName,
    this.ownerEmail,
    this.grantedByEmail,
    this.role,
  });

  final String businessId;
  final String businessName;
  final String? ownerEmail;
  final String? grantedByEmail;
  final String? role;

  static List<BusinessAssociation> parseList(List<dynamic>? raw) {
    if (raw != null && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((entry) =>
              BusinessAssociation.fromJson(Map<String, dynamic>.from(entry)))
          .where((assoc) => assoc.businessId.isNotEmpty)
          .toList();
    }
    return const <BusinessAssociation>[];
  }

  factory BusinessAssociation.fromJson(Map<String, dynamic> json) {
    String s(dynamic value) => value?.toString() ?? '';

    String? resolveEmail(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        return map['email']?.toString() ??
            map['ownerEmail']?.toString() ??
            map['grantedByEmail']?.toString();
      }
      return value.toString();
    }

    final business = json['business'] is Map
        ? Map<String, dynamic>.from(json['business'] as Map)
        : null;
    final businessContext = json['businessContext'] is Map
        ? Map<String, dynamic>.from(json['businessContext'] as Map)
        : null;

    final businessId = s(json['businessId'] ??
        json['id'] ??
        businessContext?['businessId'] ??
        business?['id'] ??
        business?['_id']);

    return BusinessAssociation(
      businessId: businessId,
      businessName:
          s(json['businessName'] ?? json['name'] ?? business?['name']),
      ownerEmail: resolveEmail(
        json['owner'] ?? json['ownerEmail'] ?? business?['ownerEmail'],
      ),
      grantedByEmail: resolveEmail(
        json['grantedBy'] ?? json['grantedByEmail'] ?? json['invitedBy'],
      ),
      role: s(json['role']),
    );
  }

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'businessName': businessName,
        if (ownerEmail != null) 'ownerEmail': ownerEmail,
        if (grantedByEmail != null) 'grantedByEmail': grantedByEmail,
        if (role != null) 'role': role,
      };
}

@immutable
class EmployerProfile {
  const EmployerProfile({
    required this.id,
    required this.companyName,
    required this.description,
    required this.phone,
    required this.rating,
    required this.totalJobsPosted,
    required this.totalHires,
    required this.activeBusinesses,
    this.profilePicture,
    this.profilePictureSmall,
    this.profilePictureMedium,
    this.profilePictureLarge,
    this.companyLogo,
    this.companyLogoSmall,
    this.companyLogoMedium,
    this.companyLogoLarge,
  });

  final String id;
  final String companyName;
  final String description;
  final String phone;
  final double rating;
  final int totalJobsPosted;
  final int totalHires;
  final int activeBusinesses;
  final String? profilePicture;
  final String? profilePictureSmall;
  final String? profilePictureMedium;
  final String? profilePictureLarge;
  final String? companyLogo;
  final String? companyLogoSmall;
  final String? companyLogoMedium;
  final String? companyLogoLarge;

  EmployerProfile copyWith({
    String? companyName,
    String? description,
    String? phone,
    double? rating,
    int? totalJobsPosted,
    int? totalHires,
    int? activeBusinesses,
    String? profilePicture,
    String? profilePictureSmall,
    String? profilePictureMedium,
    String? profilePictureLarge,
    String? companyLogo,
    String? companyLogoSmall,
    String? companyLogoMedium,
    String? companyLogoLarge,
  }) {
    return EmployerProfile(
      id: id,
      companyName: companyName ?? this.companyName,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalJobsPosted: totalJobsPosted ?? this.totalJobsPosted,
      totalHires: totalHires ?? this.totalHires,
      activeBusinesses: activeBusinesses ?? this.activeBusinesses,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureSmall: profilePictureSmall ?? this.profilePictureSmall,
      profilePictureMedium: profilePictureMedium ?? this.profilePictureMedium,
      profilePictureLarge: profilePictureLarge ?? this.profilePictureLarge,
      companyLogo: companyLogo ?? this.companyLogo,
      companyLogoSmall: companyLogoSmall ?? this.companyLogoSmall,
      companyLogoMedium: companyLogoMedium ?? this.companyLogoMedium,
      companyLogoLarge: companyLogoLarge ?? this.companyLogoLarge,
    );
  }
}

@immutable
class BusinessLocation {
  const BusinessLocation({
    required this.id,
    required this.name,
    required this.address, // street
    required this.city,
    required this.state,
    required this.postalCode,
    this.description = '',
    this.phone = '',
    this.type = 'Location',
    this.isActive = true,
    this.jobCount = 0,
    this.hireCount = 0,
    this.latitude,
    this.longitude,
    this.allowedRadius,
    this.timezone,
    this.notes,
    this.logoUrl,
    this.logoSmall,
    this.logoMedium,
    this.logoLarge,
  });

  final String id;
  final String name;
  final String address; // street
  final String city;
  final String state;
  final String postalCode;
  final String description;
  final String phone;
  final String type;
  final bool isActive;
  final int jobCount;
  final int hireCount;
  final double? latitude;
  final double? longitude;
  final double? allowedRadius;
  final String? timezone;
  final String? notes;
  final String? logoUrl;
  final String? logoSmall;
  final String? logoMedium;
  final String? logoLarge;

  /// e.g. "123 Market St, San Francisco, CA 94105"
  String get fullAddress {
    final parts = <String>[
      address,
      if (city.isNotEmpty || state.isNotEmpty || postalCode.isNotEmpty)
        [city, state, postalCode].where((s) => s.isNotEmpty).join(', ')
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Factory to build from backend JSON
  factory BusinessLocation.fromJson(Map<String, dynamic> json) {
    final addr = (json['address'] is Map<String, dynamic>)
        ? json['address'] as Map<String, dynamic>
        : null;
    final loc = (json['location'] is Map<String, dynamic>)
        ? json['location'] as Map<String, dynamic>
        : null;

    String s(dynamic v) => v?.toString() ?? '';
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(s(v)) ?? 0;
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(s(v));
    }

    bool boolValue(dynamic v, {bool defaultValue = true}) {
      if (v is bool) return v;
      if (v == null) return defaultValue;
      final normalized = s(v).trim().toLowerCase();
      if (normalized.isEmpty) return defaultValue;
      if (['false', '0', 'no', 'inactive', 'off'].contains(normalized)) {
        return false;
      }
      if (['true', '1', 'yes', 'active', 'on'].contains(normalized)) {
        return true;
      }
      return defaultValue;
    }

    final logoData = _extractLogoUrls(json);

    return BusinessLocation(
      id: s(json['id'] ?? json['_id'] ?? ''),
      name: s(json['name'] ?? json['companyName'] ?? 'Business'),
      description: s(json['description']),
      address: s(
        json['street'] ??
            addr?['street'] ??
            addr?['address'] ??
            loc?['line1'] ??
            loc?['formattedAddress'],
      ),
      city: s(json['city'] ?? addr?['city'] ?? loc?['city']),
      state: s(json['state'] ?? addr?['state'] ?? loc?['state']),
      postalCode: s(
        json['postalCode'] ??
            addr?['postalCode'] ??
            addr?['zip'] ??
            loc?['postalCode'],
      ),
      phone: s(json['phone'] ?? json['contactPhone']),
      type: () {
        final rawType = s(json['type']);
        return rawType.isEmpty || rawType == 'null' ? 'Location' : rawType;
      }(),
      isActive: boolValue(json['isActive']),
      jobCount: asInt(json['jobCount']),
      hireCount: asInt(json['hireCount']),
      latitude: asDouble(loc?['latitude'] ?? json['latitude']),
      longitude: asDouble(loc?['longitude'] ?? json['longitude']),
      allowedRadius: asDouble(loc?['allowedRadius']),
      timezone: s(loc?['timezone']),
      notes: s(loc?['notes']),
      logoUrl: logoData['logoUrl'],
      logoSmall: logoData['logoSmall'],
      logoMedium: logoData['logoMedium'],
      logoLarge: logoData['logoLarge'],
    );
  }

  static Map<String, String?> _extractLogoUrls(Map<String, dynamic> json) {
    String? directUrl;
    final rawDirect = json['logoUrl'];
    if (rawDirect is String && rawDirect.trim().isNotEmpty) {
      directUrl = rawDirect.trim();
    }

    String? originalUrl;
    String? squareUrl;
    final dynamic logo = json['logo'];
    if (logo is Map) {
      final original = logo['original'];
      final square = logo['square'];
      if (original is Map && original['url'] is String) {
        originalUrl = original['url'].toString().trim();
      }
      if (square is Map && square['url'] is String) {
        squareUrl = square['url'].toString().trim();
      }
    }

    final resolved = directUrl ?? squareUrl ?? originalUrl;

    return {
      'logoUrl': resolved,
      'logoOriginalUrl': originalUrl,
      'logoSquareUrl': squareUrl,
    };
  }

  /// For sending to your API (matches your create payload)
  Map<String, dynamic> toJson() {
    final locationMap = <String, dynamic>{
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (allowedRadius != null) 'allowedRadius': allowedRadius,
      if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };

    return {
      'id': id,
      'name': name,
      'description': description,
      'address': {
        'street': address,
        'city': city,
        'state': state,
        'postalCode': postalCode,
      },
      'phone': phone,
      'type': type,
      'isActive': isActive,
      'jobCount': jobCount,
      'hireCount': hireCount,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (logoSmall != null && logoSmall!.isNotEmpty) 'logoSmall': logoSmall,
      if (logoMedium != null && logoMedium!.isNotEmpty)
        'logoMedium': logoMedium,
      if (logoLarge != null && logoLarge!.isNotEmpty) 'logoLarge': logoLarge,
      if (locationMap.isNotEmpty) 'location': locationMap,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class TeamMember {
  const TeamMember({
    required this.id,
    required this.user,
    required this.businessId,
    required this.role,
    required this.permissions,
    required this.isActive,
    this.invitedBy,
    this.invitedAt,
    this.joinedAt,
    this.lastActive,
  });

  final String id;
  final User user;
  final String businessId;
  final String role; // Changed to String to match backend
  final List<String> permissions; // Changed to List<String>
  final bool isActive;
  final String? invitedBy;
  final DateTime? invitedAt;
  final DateTime? joinedAt;
  final DateTime? lastActive;

  // Convenience getters for backwards compatibility
  String get name => '${user.firstName} ${user.lastName}'.trim();
  String get email => user.email;
  List<String> get assignedLocationIds =>
      [businessId]; // For backwards compatibility

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    String stringValue(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      final str = stringValue(value).toLowerCase();
      return str == 'true' || str == '1' || str == 'yes';
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map(stringValue).where((item) => item.isNotEmpty).toList();
      }
      return const <String>[];
    }

    DateTime? dateTimeValue(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(stringValue(value));
    }

    if (json.containsKey('userEmail') &&
        (json.containsKey('permissions') || json.containsKey('accessLevel'))) {
      String camelToLabel(String value) {
        final buffer = StringBuffer();
        for (var i = 0; i < value.length; i++) {
          final char = value[i];
          if (char.toUpperCase() == char && i > 0) {
            buffer.write(' ');
          }
          buffer.write(char);
        }
        return buffer.toString();
      }

      List<String> permissionNames(dynamic value) {
        if (value is Map<String, dynamic>) {
          final names = <String>[];
          value.forEach((key, flag) {
            if (flag == true) {
              names.add(camelToLabel(key));
            }
          });
          return names;
        }
        if (value is List) {
          return value
              .map((entry) => entry.toString())
              .where((entry) => entry.isNotEmpty)
              .toList();
        }
        return const <String>[];
      }

      User user;
      if (json['employee'] is Map) {
        final employee = Map<String, dynamic>.from(
            json['employee'] as Map<dynamic, dynamic>);
        employee['id'] = employee['_id'] ?? employee['id'] ?? '';
        employee['email'] = employee['email'] ?? json['userEmail'];
        employee['userType'] = employee['userType'] ?? 'worker';
        user = User.fromJson(employee);
      } else if (json['managedUser'] is Map) {
        final managed = Map<String, dynamic>.from(
            json['managedUser'] as Map<dynamic, dynamic>);
        managed['id'] = managed['_id'] ?? managed['id'] ?? '';
        managed['email'] = managed['email'] ?? json['userEmail'];
        managed['userType'] = managed['userType'] ?? 'worker';
        user = User.fromJson(managed);
      } else {
        user = User(
          id: json['userEmail']?.toString() ?? '',
          firstName: '',
          lastName: '',
          email: json['userEmail']?.toString() ?? '',
          type: UserType.worker,
        );
      }

      final businessContext =
          json['businessContext'] as Map<String, dynamic>? ?? const {};

      return TeamMember(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        user: user,
        businessId: businessContext['businessId']?.toString() ??
            json['businessId']?.toString() ??
            json['business']?.toString() ??
            '',
        role: json['role']?.toString() ??
            json['accessLevel']?.toString() ??
            'custom',
        permissions: permissionNames(json['permissions']),
        isActive: (json['status']?.toString().toLowerCase() ?? '') == 'active',
        invitedBy: json['grantedBy']?.toString(),
        invitedAt: dateTimeValue(json['createdAt']),
        joinedAt: dateTimeValue(json['updatedAt']),
        lastActive: dateTimeValue(json['lastUsedAt']),
      );
    }

    // Parse user data - handle both populated and non-populated formats
    User user;
    if (json['user'] is Map<String, dynamic>) {
      // User data is populated
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      // User data is not populated, create from team member fields
      user = User(
        id: stringValue(json['user'] ?? ''),
        firstName: stringValue(json['name']).split(' ').first,
        lastName: stringValue(json['name']).split(' ').skip(1).join(' '),
        email: stringValue(json['email']),
        type: UserType.employer,
        selectedBusinessId: stringValue(json['business'] ?? json['businessId']),
      );
    }

    return TeamMember(
      id: stringValue(json['id'] ?? json['_id']),
      user: user,
      businessId: stringValue(json['business'] ?? json['businessId']),
      role: stringValue(json['role']),
      permissions: stringList(json['permissions']),
      isActive: boolValue(json['active'] ??
          json['isActive']), // Handle both 'active' and 'isActive'
      invitedBy: stringValue(json['invitedBy']).isNotEmpty
          ? stringValue(json['invitedBy'])
          : null,
      invitedAt: dateTimeValue(json['invitedAt']),
      joinedAt: dateTimeValue(json['joinedAt']),
      lastActive: dateTimeValue(json['lastActive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'businessId': businessId,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'invitedBy': invitedBy,
      'invitedAt': invitedAt?.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}
