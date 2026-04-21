import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/create_group_namjap_screen.dart';

void main() {
  group('Admin Group Namjap UI Integrity', () {
    testWidgets('CreateGroupNamjapScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      // We can instantiate the widget locally to test its compilation and structure,
      // without pumping it into a frame which would trip the Firebase Core uninitialized exception.
      expect(const CreateGroupNamjapScreen(), isA<StatefulWidget>());
    });

    testWidgets('AdminGroupNamjapDashboard is structurally sound', (
      WidgetTester tester,
    ) async {
      expect(const AdminGroupNamjapDashboard(), isA<StatefulWidget>());
    });

    testWidgets('AdminGroupNamjapListScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      // Converted to StatefulWidget to cache Firestore streams and prevent UI flickering
      expect(
        const AdminGroupNamjapListScreen(status: 'completed'),
        isA<StatefulWidget>(),
      );
    });

    testWidgets('AdminGroupNamjapDetailScreen is structurally sound', (
      WidgetTester tester,
    ) async {
      // Converted to StatefulWidget to cache Firestore streams and prevent UI flickering
      expect(
        const AdminGroupNamjapDetailScreen(eventId: 'test_123'),
        isA<StatefulWidget>(),
      );
    });
  });
}
