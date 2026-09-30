import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_sheets_dashboard.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminUser adminUser;
  late MockAppConfigProvider appConfigProvider;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    adminUser = const AdminUser(
      email: 'admin@test.com',
      roles: ['group_admin'],
      groupId: 'gajanan_maharaj_seattle',
    );

    appConfigProvider = MockAppConfigProvider();
    final config = AppConfig(
      deities: const [],
      gajananMaharajGroups: const [],
      socialMediaLinks: const [],
      appName: const {},
      updateMessage: const {},
      latestVersion: '1.0.0',
      forceUpdate: 'false',
      playStoreUrl: '',
      appStoreUrl: '',
    );
    when(() => appConfigProvider.appConfig).thenReturn(config);
  });

  Widget createWidget({
    required Widget child,
    Map<String, WidgetBuilder>? routes,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppConfigProvider>.value(
          value: appConfigProvider,
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
        routes: routes ?? {},
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

  Future<void> pumpDashboard(
    WidgetTester tester, {
    AdminUser? user,
    Map<String, WidgetBuilder>? routes,
    Locale locale = const Locale('en'),
  }) async {
    setLargeScreen(tester);
    addTearDown(() => resetScreen(tester));
    await tester.pumpWidget(
      createWidget(
        child: AdminSignupSheetsDashboard(
          adminUser: user ?? adminUser,
          firestore: firestore,
        ),
        routes: routes,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seedSheets() async {
    final now = DateTime.now();
    // Sheet 1: draft with join code
    await firestore.collection('signup_sheets').add({
      'titleEn': 'Prasad Seva Draft',
      'titleMr': 'प्रसाद सेवा मसुदा',
      'descriptionEn': 'Help cook Prasad',
      'descriptionMr': 'प्रसाद बनवण्यासाठी मदत',
      'groupId': 'gajanan_maharaj_seattle',
      'status': SignupSheetStatus.draft.name,
      'requiresJoinCode': true,
      'joinCode': 'ABC123',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      'createdBy': 'admin@test.com',
    });

    // Sheet 2: published without join code
    await firestore.collection('signup_sheets').add({
      'titleEn': 'Saree Seva Published',
      'titleMr': 'साडी सेवा प्रकाशित',
      'descriptionEn': 'Navaratri saree sponsorship',
      'descriptionMr': 'नवरात्री साडी सेवा',
      'groupId': 'gajanan_maharaj_seattle',
      'status': SignupSheetStatus.published.name,
      'requiresJoinCode': false,
      'joinCode': null,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      'createdBy': 'admin@test.com',
    });

    // Sheet 3: closed
    await firestore.collection('signup_sheets').add({
      'titleEn': 'Annakut Closed',
      'titleMr': 'अन्नकूट बंद',
      'descriptionEn': 'Past event',
      'descriptionMr': 'गेलेला कार्यक्रम',
      'groupId': 'gajanan_maharaj_seattle',
      'status': SignupSheetStatus.closed.name,
      'requiresJoinCode': false,
      'joinCode': null,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'createdBy': 'admin@test.com',
    });

    // Sheet for different group (should not be listed)
    await firestore.collection('signup_sheets').add({
      'titleEn': 'Other Group Sheet',
      'titleMr': 'दुसरा गट',
      'descriptionEn': 'Other group',
      'descriptionMr': 'दुसरा गट',
      'groupId': 'other_group',
      'status': SignupSheetStatus.published.name,
      'requiresJoinCode': false,
      'joinCode': null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': 'admin@test.com',
    });
  }

  group('AdminSignupSheetsDashboard', () {
    testWidgets(
      'renders app bar, filter chips, and empty state when no sheets exist',
      (tester) async {
        await pumpDashboard(tester);

        expect(find.text('Sign-Up Sheets'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Draft'), findsOneWidget);
        expect(find.text('Published'), findsOneWidget);
        expect(find.text('Closed'), findsOneWidget);
        expect(find.text('No sign-up sheets found'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets('shows warning when admin has no groupId', (tester) async {
      await pumpDashboard(
        tester,
        user: const AdminUser(
          email: 'admin@test.com',
          roles: ['group_admin'],
          groupId: null,
        ),
      );

      expect(find.text('No group assigned to admin'), findsOneWidget);
    });

    testWidgets(
      'lists scoped sheets with status badges and join code indicators',
      (tester) async {
        await seedSheets();
        await pumpDashboard(tester);

        expect(find.text('Prasad Seva Draft'), findsOneWidget);
        expect(find.text('Saree Seva Published'), findsOneWidget);
        expect(find.text('Annakut Closed'), findsOneWidget);
        expect(find.text('Other Group Sheet'), findsNothing);

        // Status badges
        expect(find.text('Draft'), findsNWidgets(2)); // 1 chip + 1 badge
        expect(find.text('Published'), findsNWidgets(2)); // 1 chip + 1 badge
        expect(find.text('Closed'), findsNWidgets(2)); // 1 chip + 1 badge

        // Join code badge on Sheet 1
        expect(find.text('Join Code: ABC123'), findsOneWidget);
      },
    );

    testWidgets('renders Marathi titles and badges when in Marathi locale', (
      tester,
    ) async {
      await seedSheets();
      await pumpDashboard(tester, locale: const Locale('mr'));

      expect(find.text('साइन-अप शीट्स'), findsOneWidget);
      expect(find.text('प्रसाद सेवा मसुदा'), findsOneWidget);
      expect(find.text('साडी सेवा प्रकाशित'), findsOneWidget);
      expect(find.text('अन्नकूट बंद'), findsOneWidget);
      expect(find.text('सर्व'), findsOneWidget);
      expect(find.text('मसुदा'), findsNWidgets(2)); // chip + badge
      expect(find.text('प्रकाशित'), findsNWidgets(2)); // chip + badge
      expect(find.text('बंद'), findsNWidgets(2)); // chip + badge
    });

    testWidgets('filter chips filter sheets by status', (tester) async {
      await seedSheets();
      await pumpDashboard(tester);

      // Filter by Draft
      await tester.tap(find.widgetWithText(ChoiceChip, 'Draft'));
      await tester.pumpAndSettle();

      expect(find.text('Prasad Seva Draft'), findsOneWidget);
      expect(find.text('Saree Seva Published'), findsNothing);
      expect(find.text('Annakut Closed'), findsNothing);

      // Filter by Published
      await tester.tap(find.widgetWithText(ChoiceChip, 'Published'));
      await tester.pumpAndSettle();

      expect(find.text('Prasad Seva Draft'), findsNothing);
      expect(find.text('Saree Seva Published'), findsOneWidget);
      expect(find.text('Annakut Closed'), findsNothing);

      // Filter by Closed
      await tester.tap(find.widgetWithText(ChoiceChip, 'Closed'));
      await tester.pumpAndSettle();

      expect(find.text('Prasad Seva Draft'), findsNothing);
      expect(find.text('Saree Seva Published'), findsNothing);
      expect(find.text('Annakut Closed'), findsOneWidget);

      // Back to All
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Prasad Seva Draft'), findsOneWidget);
      expect(find.text('Saree Seva Published'), findsOneWidget);
      expect(find.text('Annakut Closed'), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to adminCreateSignupSheet route', (
      tester,
    ) async {
      var navigatedToCreate = false;
      await pumpDashboard(
        tester,
        routes: {
          Routes.adminCreateSignupSheet: (context) {
            navigatedToCreate = true;
            return const Scaffold(body: Text('Create Screen Mock'));
          },
        },
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(navigatedToCreate, isTrue);
      expect(find.text('Create Screen Mock'), findsOneWidget);
    });

    testWidgets(
      'tapping a sheet card navigates to adminSignupSheetDetail route with arguments',
      (tester) async {
        await seedSheets();
        Map<String, dynamic>? receivedArgs;
        await pumpDashboard(
          tester,
          routes: {
            Routes.adminSignupSheetDetail: (context) {
              receivedArgs =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              return const Scaffold(body: Text('Detail Screen Mock'));
            },
          },
        );

        await tester.tap(find.text('Prasad Seva Draft'));
        await tester.pumpAndSettle();

        expect(find.text('Detail Screen Mock'), findsOneWidget);
        expect(receivedArgs, isNotNull);
        expect(receivedArgs!['sheetId'], isNotNull);
        expect(receivedArgs!['adminUser'], equals(adminUser));
      },
    );

    testWidgets('tapping home icon pops until first route', (tester) async {
      await pumpDashboard(tester);

      expect(find.byType(IconButton), findsWidgets);
      // Tap home icon
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .first,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('tapping settings icon navigates to settings route', (
      tester,
    ) async {
      var navigatedToSettings = false;
      await pumpDashboard(
        tester,
        routes: {
          Routes.settings: (context) {
            navigatedToSettings = true;
            return const Scaffold(body: Text('Settings Mock'));
          },
        },
      );

      // The second icon button in app bar is settings
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .at(1),
      );
      await tester.pumpAndSettle();

      expect(navigatedToSettings, isTrue);
    });

    testWidgets('renders error view when sheets stream has error', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      final mockService = MockSignupService();
      when(
        () => mockService.getAllSheets(any()),
      ).thenAnswer((_) => Stream<List<SignupSheet>>.error('Test error'));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupSheetsDashboard(
            adminUser: adminUser,
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to load sign-up sheets. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('didUpdateWidget re-subscribes when groupId changes', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupSheetsDashboard(
            adminUser: adminUser,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Update with new adminUser groupId
      const newAdmin = AdminUser(
        email: 'admin@test.com',
        roles: ['group_admin'],
        groupId: 'gajanan_maharaj_pune',
      );

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupSheetsDashboard(
            adminUser: newAdmin,
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign-Up Sheets'), findsOneWidget);
    });
  });
}
