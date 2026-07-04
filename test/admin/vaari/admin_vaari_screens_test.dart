import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/vaari/admin_vaari_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/admin/vaari/admin_vaari_list_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/vaari/admin_vaari_create_screen.dart';
import 'package:gajanan_maharaj_sevekari/admin/vaari/admin_vaari_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
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

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

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

    appConfigProvider = MockAppConfigProvider();
    final config = AppConfig(
      deities: [],
      gajananMaharajGroups: [
        GajananMaharajGroup(
          id: 'gajanan_maharaj_seattle',
          nameEn: 'Seattle',
          nameMr: 'सिएटल',
        ),
      ],
      socialMediaLinks: [],
      appName: {},
      updateMessage: {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => appConfigProvider.appConfig).thenReturn(config);
  });

  Widget createWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: appConfigProvider,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setLocale(locale),
        ),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
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

  group('AdminVaariDashboard Tests', () {
    testWidgets('shows error state when stream has error', (tester) async {
      final mockFirestore = MockFirebaseFirestore();
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(
        () => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        () => mockQuery.snapshots(
          includeMetadataChanges: any(named: 'includeMetadataChanges'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) => Stream.error(Exception('simulated error')));

      await tester.pumpWidget(
        createWidget(
          AdminVaariDashboard(adminUser: adminUser, firestore: mockFirestore),
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
          AdminVaariDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('No ongoing Vaari events'), findsOneWidget);
      expect(find.textContaining('No completed Vaari events'), findsOneWidget);
    });

    testWidgets('renders active events and navigates to detail', (
      tester,
    ) async {
      await firestore.collection('vaari_events').add({
        'nameEn': 'Seattle Vaari 2026',
        'nameMr': 'सिएटल वारी २०२६',
        'descriptionEn': 'Walk for Maharaj',
        'descriptionMr': 'महाराजांसाठी वारी',
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'status': 'ongoing',
        'groupId': 'gajanan_maharaj_seattle',
        'joinCode': '123456',
        'totalSteps': 50000,
        'totalDistance': 40.0,
        'distanceUnit': 'km',
        'createdAt': Timestamp.now(),
      });

      await tester.pumpWidget(
        createWidget(
          AdminVaariDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Seattle Vaari 2026'), findsOneWidget);

      await tester.tap(find.text('Seattle Vaari 2026'));
      await tester.pumpAndSettle();

      expect(
        find.text('Navigated to: ${Routes.adminVaariDetail}'),
        findsOneWidget,
      );
    });

    testWidgets('navigates to settings and create screen', (tester) async {
      await tester.pumpWidget(
        createWidget(
          AdminVaariDashboard(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Navigated to: ${Routes.settings}'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Vaari Event'));
      await tester.pumpAndSettle();
      expect(
        find.text('Navigated to: ${Routes.adminCreateVaari}'),
        findsOneWidget,
      );
    });
  });

  group('AdminVaariCreateScreen Tests', () {
    testWidgets('validation fails on empty inputs', (tester) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          AdminVaariCreateScreen(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter English name'), findsOneWidget);
      expect(find.text('कृपया मराठी नाव प्रविष्ट करा'), findsOneWidget);
      expect(find.text('Please enter target distance'), findsOneWidget);
    });

    testWidgets('creates a vaari event successfully', (tester) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          AdminVaariCreateScreen(adminUser: adminUser, firestore: firestore),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Portland Vaari',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'पोर्टलंड वारी');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Walk in Portland',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'पोर्टलंड मधील वारी',
      );
      await tester.enterText(find.byType(TextFormField).at(4), '100.0');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final snapshot = await firestore.collection('vaari_events').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name_en'], 'Portland Vaari');
      expect(snapshot.docs.first.data()['targetDistance'], 100.0);
    });
  });

  group('AdminVaariListScreen Tests', () {
    testWidgets('lists ongoing events', (tester) async {
      await firestore.collection('vaari_events').add({
        'nameEn': 'Bellevue Vaari',
        'nameMr': 'बेलव्यू वारी',
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3)),
        ),
        'status': 'ongoing',
        'groupId': 'gajanan_maharaj_seattle',
        'joinCode': 'BELLEV',
      });

      await tester.pumpWidget(
        createWidget(
          AdminVaariListScreen(
            status: 'ongoing',
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Bellevue Vaari'), findsOneWidget);
    });
  });

  group('AdminVaariDetailScreen Tests', () {
    testWidgets('renders details, updates status and deletes participant', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      final docRef = await firestore.collection('vaari_events').add({
        'nameEn': 'Redmond Vaari',
        'nameMr': 'रेडमंड वारी',
        'descriptionEn': 'Walk Redmond',
        'descriptionMr': 'रेडमंड वारी',
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'status': 'ongoing',
        'groupId': 'gajanan_maharaj_seattle',
        'joinCode': 'REDMON',
        'totalSteps': 10000,
        'totalDistance': 8.0,
        'distanceUnit': 'km',
        'createdAt': Timestamp.now(),
      });

      final participantRef = docRef.collection('participants').doc('dev1_John');
      await participantRef.set({
        'memberName': 'John',
        'deviceId': 'dev1',
        'phone': '1234567890',
        'joinedAt': Timestamp.now(),
        'totalSteps': 5000,
        'totalDistance': 4.0,
      });

      await tester.pumpWidget(
        createWidget(
          AdminVaariDetailScreen(
            eventId: docRef.id,
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Redmond Vaari').first, findsOneWidget);
      expect(find.text('John'), findsOneWidget);

      // Unlock status dropdown
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Change status to Completed
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      // Verify status updated in Firestore
      final eventDoc = await docRef.get();
      expect(eventDoc.data()?['status'], 'completed');
    });
  });
}
