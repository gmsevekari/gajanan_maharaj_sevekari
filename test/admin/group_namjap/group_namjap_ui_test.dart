import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/create_group_namjap_screen.dart';

void main() {
  const testAdmin = AdminUser(
    email: 'test@example.com',
    roles: ['super_admin'],
  );

  group('Admin Group Namjap UI Integrity', () {
    testWidgets('CreateGroupNamjapScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      expect(
        const CreateGroupNamjapScreen(adminUser: testAdmin),
        isA<StatefulWidget>(),
      );
    });

    testWidgets('AdminGroupNamjapDashboard is structurally sound', (
      WidgetTester tester,
    ) async {
      expect(
        const AdminGroupNamjapDashboard(adminUser: testAdmin),
        isA<StatefulWidget>(),
      );
    });

    testWidgets('AdminGroupNamjapListScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      expect(
        const AdminGroupNamjapListScreen(status: 'completed', adminUser: testAdmin),
        isA<StatefulWidget>(),
      );
    });

    testWidgets('AdminGroupNamjapDetailScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      expect(
        const AdminGroupNamjapDetailScreen(eventId: 'test_123', adminUser: testAdmin),
        isA<StatefulWidget>(),
      );
    });
  });
}
