import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/admin_group_namjap_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/group_namjap/create_group_namjap_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminUser adminUser;

  setUpAll(() {
    registerFallbackValue(ListenSource.defaultSource);
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    adminUser = const AdminUser(
      email: 'admin@test.com',
      roles: ['group_admin'],
      groupId: 'gajanan_maharaj_seattle',
    );
  });

  Widget createWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setLocale(locale),
        ),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
        ChangeNotifierProvider(create: (_) => GroupSelectionProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text(settings.name ?? '')),
              body: Text('Navigated to: ${settings.name}'),
            ),
          );
        },
        home: child,
      ),
    );
  }

  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
  }

  void resetScreen(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  group('AdminGroupNamjapDashboard Coverage', () {
    testWidgets('shows error state when stream has error', (tester) async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(
        () => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.snapshots(
          includeMetadataChanges: any(named: 'includeMetadataChanges'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) => Stream.error(Exception('simulated error')));

      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapDashboard(
            adminUser: adminUser,
            firestore: mockFirestore,
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Error loading data'), findsOneWidget);
      expect(find.textContaining('simulated error'), findsOneWidget);
    });

    testWidgets('shows empty states for ongoing and completed events', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('No active group namjaps'), findsOneWidget);
      expect(find.textContaining('No completed group namjaps'), findsOneWidget);
    });

    testWidgets('navigates to settings and create screen', (tester) async {
      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Navigated to: ${Routes.settings}'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to create
      final createBtn = find.widgetWithText(
        ElevatedButton,
        'Create Group Namjap',
      );
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Navigated to: ${Routes.adminCreateGroupNamjap}'),
        findsOneWidget,
      );
    });

    testWidgets('shows upcoming events and limit ongoing to 5', (tester) async {
      setLargeScreen(tester);
      for (int i = 1; i <= 6; i++) {
        await firestore.collection('group_namjap_events').add({
          'name_en': 'Ongoing $i',
          'name_mr': 'चालू $i',
          'status': 'ongoing',
          'groupId': adminUser.groupId,
          'startDate': Timestamp.fromDate(DateTime.now()),
          'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7)),
          ),
          'targetCount': 1000,
          'totalCount': 0,
          'createdAt': Timestamp.now(),
        });
      }

      await firestore.collection('group_namjap_events').add({
        'name_en': 'Upcoming Event',
        'name_mr': 'पुढील कार्यक्रम',
        'status': 'upcoming',
        'groupId': adminUser.groupId,
        'startDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 37)),
        ),
        'targetCount': 2000,
        'totalCount': 0,
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Upcoming Group Namjaps'), findsOneWidget);
      expect(find.text('Upcoming Event'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsNWidgets(5));

      final viewAllBtn = find.widgetWithText(TextButton, 'View All');
      await tester.tap(viewAllBtn.last);
      await tester.pumpAndSettle();
      expect(
        find.text('Navigated to: ${Routes.adminGroupNamjapList}'),
        findsOneWidget,
      );
      resetScreen(tester);
    });

    testWidgets('navigates to list screens via View All', (tester) async {
      await firestore.collection('group_namjap_events').add({
        'name_en': 'Completed Event',
        'name_mr': 'पूर्ण कार्यक्रम',
        'sankalp_en': 'Sankalp EN',
        'sankalp_mr': 'Sankalp MR',
        'mantra': 'Mantra',
        'status': 'completed',
        'groupId': adminUser.groupId,
        'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2023, 1, 7)),
        'targetCount': 1000,
        'totalCount': 1000,
        'joinCode': 'COMP01',
        'timezone': 'America/Los_Angeles',
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      final viewAllBtn = find.widgetWithText(TextButton, 'View All');
      await tester.tap(viewAllBtn.first);
      await tester.pumpAndSettle();
      expect(
        find.text('Navigated to: ${Routes.adminGroupNamjapList}'),
        findsOneWidget,
      );
    });
  });

  group('AdminGroupNamjapListScreen Coverage', () {
    testWidgets('shows error state when stream has error', (tester) async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(
        () => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        () => mockCollection.where(any(), whereIn: any(named: 'whereIn')),
      ).thenReturn(mockQuery);

      when(
        () => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.where(any(), whereIn: any(named: 'whereIn')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.orderBy(any(), descending: any(named: 'descending')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.snapshots(
          includeMetadataChanges: any(named: 'includeMetadataChanges'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) => Stream.error(Exception('list error')));

      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapListScreen(
            status: 'ongoing',
            adminUser: adminUser,
            firestore: mockFirestore,
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('list error'), findsOneWidget);
    });

    testWidgets('upcoming status uses whereIn query', (tester) async {
      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapListScreen(
            status: 'upcoming',
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Upcoming Group Namjaps'), findsOneWidget);
    });

    testWidgets('shows events in Marathi', (tester) async {
      await firestore.collection('group_namjap_events').add({
        'name_en': 'Test Event',
        'name_mr': 'मराठी कार्यक्रम',
        'status': 'ongoing',
        'groupId': adminUser.groupId,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'targetCount': 1000,
        'totalCount': 0,
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        createWidget(
          AdminGroupNamjapListScreen(
            status: 'ongoing',
            adminUser: adminUser,
            firestore: firestore,
          ),
          locale: const Locale('mr'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('मराठी कार्यक्रम'), findsOneWidget);
    });
  });

  group('CreateGroupNamjapScreen Coverage', () {
    testWidgets('successful creation', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        createWidget(
          CreateGroupNamjapScreen(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Name (English)'),
        'New Event',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Name (Marathi)'),
        'नवीन कार्यक्रम',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sankalp (English)'),
        'Sankalp',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sankalp (Marathi)'),
        'Sankalp MR',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mantra'),
        'Mantra',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Count'),
        '5000',
      );

      // Helper to select a date
      Future<void> selectDate(String label) async {
        final btn = find.text(label);
        await tester.ensureVisible(btn);
        await tester.tap(btn);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        // Tapping the 'OK' button using a widget predicate
        final okButton = find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is TextButton &&
                ((w.child is Text &&
                        (w.child as Text).data?.toUpperCase() == 'OK') ||
                    (w.child is Text &&
                        (w.child as Text).data?.toUpperCase() == 'SAVE')),
          ),
        );
        await tester.tap(okButton.last);
        await tester.pumpAndSettle();
      }

      await selectDate('Start Date');
      await selectDate('End Date');

      final createBtn = find.widgetWithText(
        ElevatedButton,
        'Create Group Namjap',
      );
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);

      await tester.pumpAndSettle();

      // Verify data in Firestore
      final snapshot = await firestore.collection('group_namjap_events').get();
      expect(snapshot.docs.isNotEmpty, true);
      expect(
        snapshot.docs.any((doc) => doc.data()['name_en'] == 'New Event'),
        true,
      );

      resetScreen(tester);
    });

    testWidgets('exception during creation', (tester) async {
      setLargeScreen(tester); // Fix hit-test warning
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.set(any())).thenThrow(Exception('set error'));

      await tester.pumpWidget(
        createWidget(
          CreateGroupNamjapScreen(
            adminUser: adminUser,
            firestore: mockFirestore,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Name (English)'),
        'Error Event',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Event Name (Marathi)'),
        'नवीन कार्यक्रम',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sankalp (English)'),
        'Sankalp',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sankalp (Marathi)'),
        'Sankalp MR',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mantra'),
        'Mantra',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Count'),
        '5000',
      );

      // Select dates
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();
      final okBtn = find.widgetWithText(TextButton, 'OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.last);
      } else {
        await tester.tap(find.text('Ok').last);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('End Date'));
      await tester.pumpAndSettle();
      final okBtn2 = find.widgetWithText(TextButton, 'OK');
      if (okBtn2.evaluate().isNotEmpty) {
        await tester.tap(okBtn2.last);
      } else {
        await tester.tap(find.text('Ok').last);
      }
      await tester.pumpAndSettle();

      final createBtn = find.widgetWithText(
        ElevatedButton,
        'Create Group Namjap',
      );
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('set error'), findsOneWidget);
      resetScreen(tester);
    });
  });
}
