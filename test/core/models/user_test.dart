import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talent/core/models/user.dart';

void main() {
  group('User serialization', () {
    test('stores userType consistently', () {
      final user = User(
        id: '1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        type: UserType.worker,
        roles: const [UserType.worker],
      );

      final jsonMap = user.toJson();

      expect(jsonMap['userType'], 'worker');
      expect(jsonMap['type'], 'worker');
      expect(jsonMap['roles'], ['worker']);
    });

    test('hydrates from stored payloads that used enum.toString()', () {
      final stored = jsonEncode({
        'id': '2',
        'firstName': 'John',
        'lastName': 'Smith',
        'email': 'john@example.com',
        'type': 'UserType.worker',
        'roles': ['UserType.worker', 'employer'],
      });

      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final user = User.fromJson(decoded);

      expect(user.type, UserType.worker);
      expect(user.roles.contains(UserType.worker), isTrue);
    });

    test('falls back to employer when type missing', () {
      final user = User.fromJson({
        'id': '3',
        'firstName': 'Alex',
        'lastName': 'Stone',
        'email': 'alex@example.com',
      });

      expect(user.type, UserType.employer);
      expect(user.roles, [UserType.employer]);
    });
  });
}
