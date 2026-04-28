import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

void main() {
  group('AdminUser', () {
    test('fromFirestore should correctly parse data', () {
      final data = {
        'roles': ['admin', 'coordinator'],
        'typoNotificationsEnabled': true,
        'groupId': 'group_1',
      };
      final email = 'test@example.com';

      final user = AdminUser.fromFirestore(data, email);

      expect(user.email, email);
      expect(user.roles, ['admin', 'coordinator']);
      expect(user.typoNotificationsEnabled, true);
      expect(user.groupId, 'group_1');
    });

    test('fromFirestore should handle missing fields', () {
      final user = AdminUser.fromFirestore({}, 'test@test.com');
      expect(user.roles, []);
      expect(user.typoNotificationsEnabled, false);
      expect(user.groupId, isNull);
    });

    test('hasRole should respect super_admin', () {
      final superAdmin = AdminUser(email: 'a@b.com', roles: ['super_admin']);
      expect(superAdmin.hasRole('any_role'), true);

      final normalAdmin = AdminUser(email: 'c@d.com', roles: ['admin']);
      expect(normalAdmin.hasRole('admin'), true);
      expect(normalAdmin.hasRole('coordinator'), false);
    });

    test('hasAnyRole should check if user has at least one required role', () {
      final user = AdminUser(email: 'a@b.com', roles: ['coordinator']);
      expect(user.hasAnyRole(['admin', 'coordinator']), true);
      expect(user.hasAnyRole(['admin']), false);
    });
  });
}
