import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/create_group_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import '../../mocks.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late MockThemeProvider mockThemeProvider;
  late MockFontProvider mockFontProvider;
  late MockFestivalProvider mockFestivalProvider;
  late MockAppConfigProvider mockAppConfigProvider;

  final groupAdmin = AdminUser(
    email: 'admin@group.com',
    roles: ['group_admin'],
    groupId: 'test_group_123',
  );

  setUp(() {
    mockThemeProvider = MockThemeProvider();
    mockFontProvider = MockFontProvider();
    mockFestivalProvider = MockFestivalProvider();
    mockAppConfigProvider = MockAppConfigProvider();

    when(() => mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(() => mockThemeProvider.themePreset).thenReturn(ThemePreset.tulsi);
    when(() => mockThemeProvider.customColor).thenReturn(null);
    when(() => mockFestivalProvider.activeFestival).thenReturn(null);
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<FontProvider>.value(value: mockFontProvider),
        ChangeNotifierProvider<FestivalProvider>.value(
          value: mockFestivalProvider,
        ),
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: mockAppConfigProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('mr', '')],
        home: child,
      ),
    );
  }

  group('AdminGroupNamjapDashboard Filtering', () {
    testWidgets('shows only events for admin group', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('group_namjap_events').add({
        'groupId': 'test_group_123',
        'name_en': 'My Group Event',
        'status': 'ongoing',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'targetCount': 1000,
        'totalCount': 0,
        'joinCode': '123456',
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('group_namjap_events').add({
        'groupId': 'other_group',
        'name_en': 'Other Group Event',
        'status': 'ongoing',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        wrap(
          AdminGroupNamjapDashboard(
            adminUser: groupAdmin,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Group Event'), findsOneWidget);
      expect(find.text('Other Group Event'), findsNothing);
    });
  });

  group('CreateGroupNamjapScreen', () {
    testWidgets('submits form with correct groupId', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        wrap(
          CreateGroupNamjapScreen(
            adminUser: groupAdmin,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Event EN');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Event MR');
      await tester.enterText(find.byType(TextFormField).at(2), 'Sankalp EN');
      await tester.enterText(find.byType(TextFormField).at(3), 'Sankalp MR');
      await tester.enterText(find.byType(TextFormField).at(4), 'Mantra');
      await tester.enterText(find.byType(TextFormField).at(5), '50000');

      // Submit
      final buttonFinder = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Create Group Namjap'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify Firestore entry
      final snapshot = await fakeFirestore
          .collection('group_namjap_events')
          .get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['groupId'], 'test_group_123');
      expect(snapshot.docs.first.data()['name_en'], 'Test Event EN');
    });
  });

  group('AdminGroupNamjapListScreen Filtering', () {
    testWidgets('filters list by group', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('group_namjap_events').add({
        'groupId': 'test_group_123',
        'name_en': 'Target Event',
        'status': 'completed',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'targetCount': 1000,
        'totalCount': 0,
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        wrap(
          AdminGroupNamjapListScreen(
            status: 'completed',
            adminUser: groupAdmin,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Target Event'), findsOneWidget);
    });
  });

  group('AdminGroupNamjapDetailScreen Authorization', () {
    testWidgets('denies access to events from other groups', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final doc = await fakeFirestore.collection('group_namjap_events').add({
        'groupId': 'other_group',
        'name_en': 'Secret Event',
        'status': 'ongoing',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        wrap(
          AdminGroupNamjapDetailScreen(
            eventId: doc.id,
            adminUser: groupAdmin,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Access Denied'), findsOneWidget);
    });

    testWidgets('allows access and updates status', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final doc = await fakeFirestore.collection('group_namjap_events').add({
        'groupId': 'test_group_123',
        'name_en': 'Allowed Event',
        'status': 'upcoming',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'targetCount': 1000,
        'totalCount': 0,
        'joinCode': '123456',
        'sankalp_en': 'Test Sankalp',
        'sankalp_mr': 'Test Sankalp MR',
        'mantra': 'Test Mantra',
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        wrap(
          AdminGroupNamjapDetailScreen(
            eventId: doc.id,
            adminUser: groupAdmin,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Allowed Event'), findsAtLeastNWidgets(1));

      // Unlock status and change it
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pump();

      await tester.tap(find.text('Enrolling'));
      await tester.pumpAndSettle();

      // Verify Firestore update
      final updatedDoc = await fakeFirestore
          .collection('group_namjap_events')
          .doc(doc.id)
          .get();
      expect(updatedDoc.data()?['status'], 'enrolling');
    });
  });
}
