import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

void main() {
  group('AdminUser Roles Data Mapping', () {
    test('should identify namjap_coordinator role correctly', () {
      final userWithRole = AdminUser.fromFirestore(
        {'roles': ['namjap_coordinator']},
        'test@test.com',
      );

      final userWithoutRole = AdminUser.fromFirestore(
        {'roles': ['temple_admin']},
        'test2@test.com',
      );

      expect(userWithRole.hasRole('namjap_coordinator'), isTrue);
      expect(userWithoutRole.hasRole('namjap_coordinator'), isFalse);
    });

    test('super_admin should override and provide true for any role Check', () {
      final superAdmin = AdminUser.fromFirestore(
        {'roles': ['super_admin']},
        'boss@test.com',
      );

      expect(superAdmin.hasRole('namjap_coordinator'), isTrue);
    });
  });
}
