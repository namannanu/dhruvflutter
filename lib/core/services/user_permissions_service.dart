// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:talent/core/models/user.dart';
import 'package:talent/core/services/http_service.dart';

class UserPermissionsService {
  final HttpService _httpService = HttpService();

  /// Get current user's permissions for a specific business
  Future<List<String>> getUserPermissions(String businessId) async {
    try {

      final response = await _httpService.get('/api/auth/permissions',
          queryParams: {'businessId': businessId});


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final permissions = data['permissions'] as List?;

        if (permissions != null) {
          final permissionList = permissions.map((p) => p.toString()).toList();
          return permissionList;
        }

        print('UserPermissionsService: No permissions found in response');
        return <String>[];
      } else {
        return <String>[];
      }
    } catch (error) {
      return <String>[];
    }
  }

  /// Get current user's team member info for a specific business
  Future<TeamMember?> getUserTeamMemberInfo(String businessId) async {
    try {
      final response = await _httpService.get('/api/team/my-access');
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessList = _extractList(data);

      for (final entry in accessList) {
        if (entry is! Map<String, dynamic>) continue;
        final context =
            entry['businessContext'] as Map<String, dynamic>? ?? const {};
        final entryBusinessId =
            (context['businessId'] ?? entry['businessId'])?.toString();

        if (entryBusinessId == businessId) {
          return TeamMember.fromJson(entry);
        }
      }

      return null;
    } catch (error) {
      print('UserPermissionsService: failed to load team member info: $error');
      return null;
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> wrapper) {
    for (final key in ['data', 'items', 'records', 'results', 'access']) {
      final value = wrapper[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }
}
