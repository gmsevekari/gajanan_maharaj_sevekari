import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_slots_screen.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAppConfigProvider extends Mock implements AppConfigProvider {}

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockAppConfigProvider appConfigProvider;

  setUpAll(() {
    registerFallbackValue(SignupStatus.published);
    registerFallbackValue(
      SignupEntry(
        id: 'dummy',
        slotId: 'dummy',
        name: 'dummy',
        joinedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();

    appConfigProvider = MockAppConfigProvider();
    final config = AppConfig(
      deities: const [],
      gajananMaharajGroups: [
        GajananMaharajGroup(
          id: 'gajanan_maharaj_seattle',
          nameEn: 'Seattle',
          nameMr: 'सिॲटल',
        ),
      ],
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

  Signup stubSignup(String id) {
    final now = DateTime.now();
    return Signup(
      id: id,
      titleEn: 'Signup',
      titleMr: '',
      groupId: 'gajanan_maharaj_seattle',
      createdAt: now,
      updatedAt: now,
      createdBy: 'admin@test.com',
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required String signupId,
    Locale locale = const Locale('en'),
  }) async {
    setLargeScreen(tester);
    addTearDown(() => resetScreen(tester));
    await tester.pumpWidget(
      createWidget(
        child: AdminSignupSlotsScreen(
          signupId: signupId,
          signup: stubSignup(signupId),
          firestore: firestore,
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdminSignupSlotsScreen', () {
    testWidgets('manually adds an entry to a slot via dialog', (tester) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Signup 1',
        'titleMr': 'शीट १',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      final slotRef = await signupRef.collection('slots').add({
        'labelEn': 'Morning Seva',
        'labelMr': 'सकाळची सेवा',
        'capacity': 3,
        'claimedCount': 0,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await pumpScreen(tester, signupId: signupRef.id);

      expect(find.text('Morning Seva').first, findsOneWidget);
      expect(find.text('Add Devotee'), findsOneWidget);

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      expect(find.text('Add Devotee Entry'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Ram Das',
      );
      await tester.enterText(
        find.byKey(const Key('entryPhoneField')),
        '5551234567',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Devotee added successfully'), findsOneWidget);
      // The slot now shows one more claimed (names are on the Entries screen).
      expect(find.text('1 of 3 claimed'), findsOneWidget);

      // Verify slot claimedCount incremented
      final slotDoc = await slotRef.get();
      expect(slotDoc.data()?['claimedCount'], 1);

      // The number is saved with the country code (the group's default).
      final entries = await signupRef.collection('entries').get();
      expect(entries.docs.single.data()['phone'], '+15551234567');
    });

    testWidgets('prefills the sign up group\'s default country code in the '
        'add dialog', (tester) async {
      final config = AppConfig(
        deities: const [],
        gajananMaharajGroups: [
          GajananMaharajGroup(
            id: 'gajanan_maharaj_seattle',
            nameEn: 'Seattle',
            nameMr: 'सिॲटल',
            defaultCountryCode: '+91',
          ),
        ],
        socialMediaLinks: const [],
        appName: const {},
        updateMessage: const {},
        latestVersion: '1.0.0',
        forceUpdate: 'false',
        playStoreUrl: '',
        appStoreUrl: '',
      );
      when(() => appConfigProvider.appConfig).thenReturn(config);
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Signup 1',
        'titleMr': 'शीट १',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
      await signupRef.collection('slots').add({
        'labelEn': 'Morning Seva',
        'labelMr': 'सकाळची सेवा',
        'capacity': 3,
        'claimedCount': 0,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await pumpScreen(tester, signupId: signupRef.id);
      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      final code = tester.widget<TextFormField>(
        find.byKey(const Key('entryCountryCodeField')),
      );
      expect(code.controller!.text, '+91');
    });

    testWidgets('shows slot full error when admin adds entry to full slot', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Full Signup',
        'titleMr': 'शीट',
        'descriptionEn': '',
        'descriptionMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      await signupRef.collection('slots').add({
        'labelEn': 'Slot 1',
        'labelMr': 'स्लॉट १',
        'capacity': 1,
        'claimedCount': 1, // already full!
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await pumpScreen(tester, signupId: signupRef.id);

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'New Devotee',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('This slot is already full'), findsOneWidget);
    });

    testWidgets(
      'shows error snackbar when adminAddEntry throws generic error',
      (tester) async {
        final now = DateTime.now();
        const signupId = 'fail_add_signup';
        const slotId = 'slot_1';
        final signup = Signup(
          id: signupId,
          titleEn: 'Fail Add Signup',
          titleMr: '',
          groupId: 'gajanan_maharaj_seattle',
          status: SignupStatus.published,
          requiresJoinCode: false,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        );
        final slot = SignupSlot(
          id: slotId,
          labelEn: 'Slot 1',
          labelMr: '',
          capacity: 5,
          sortOrder: 0,
          createdAt: now,
        );

        final mockService = MockSignupService();
        when(
          () => mockService.getSignupById(signupId),
        ).thenAnswer((_) => Stream.value(signup));
        when(
          () => mockService.getSlots(signupId),
        ).thenAnswer((_) => Stream.value([slot]));
        when(
          () => mockService.getAllEntries(signupId),
        ).thenAnswer((_) => Stream.value(const []));
        when(
          () => mockService.adminAddEntry(
            signupId: any(named: 'signupId'),
            slotId: any(named: 'slotId'),
            name: any(named: 'name'),
            phone: null,
            email: null,
            pledgeAmount: null,
            note: null,
          ),
        ).thenAnswer((_) async => {'success': false, 'error': 'generic_error'});

        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: AdminSignupSlotsScreen(
              signupId: signupId,
              signup: stubSignup(signupId),
              signupService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Devotee'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('entryNameField')),
          'Test Person',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to add devotee'), findsOneWidget);
      },
    );

    testWidgets('shows error snackbar when adminAddEntry throws exception', (
      tester,
    ) async {
      final now = DateTime.now();
      const signupId = 'fail_add_exc_signup';
      const slotId = 'slot_1';
      final signup = Signup(
        id: signupId,
        titleEn: 'Fail Add Signup',
        titleMr: '',
        groupId: 'gajanan_maharaj_seattle',
        status: SignupStatus.published,
        requiresJoinCode: false,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      );
      final slot = SignupSlot(
        id: slotId,
        labelEn: 'Slot 1',
        labelMr: '',
        capacity: 5,
        sortOrder: 0,
        createdAt: now,
      );

      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById(signupId),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots(signupId),
      ).thenAnswer((_) => Stream.value([slot]));
      when(
        () => mockService.getAllEntries(signupId),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.adminAddEntry(
          signupId: any(named: 'signupId'),
          slotId: any(named: 'slotId'),
          name: any(named: 'name'),
          phone: null,
          email: null,
          pledgeAmount: null,
          note: null,
        ),
      ).thenAnswer((_) => Future.error(Exception('Crash on add')));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupSlotsScreen(
            signupId: signupId,
            signup: stubSignup(signupId),
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'Test Person',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to add devotee'), findsOneWidget);
    });
  });

  group('AdminSignupSlotsScreen tabs', () {
    final past = DateTime(2020, 1, 10);
    final future = DateTime(2099, 3, 15);

    Future<DocumentReference<Map<String, dynamic>>> seedSignup() {
      final now = DateTime.now();
      return firestore.collection('signups').add({
        'titleEn': 'Signup',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });
    }

    Future<String> addSlot(
      DocumentReference<Map<String, dynamic>> signup,
      String label, {
      DateTime? date,
      int sortOrder = 0,
      int capacity = 3,
      int claimed = 0,
    }) async {
      final ref = await signup.collection('slots').add({
        'labelEn': label,
        'labelMr': '',
        'capacity': capacity,
        'claimedCount': claimed,
        'sortOrder': sortOrder,
        'startAt': date == null ? null : Timestamp.fromDate(date),
        'endAt': date == null
            ? null
            : Timestamp.fromDate(
                date.add(const Duration(hours: 23, minutes: 59)),
              ),
        'timezone': 'America/Los_Angeles',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      return ref.id;
    }

    Future<void> addEntry(
      DocumentReference<Map<String, dynamic>> signup,
      String slotId,
      String name,
    ) {
      return signup.collection('entries').add({
        'slotId': slotId,
        'name': name,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    TabController tabController(WidgetTester tester) =>
        tester.widget<TabBar>(find.byType(TabBar)).controller!;

    testWidgets('has Upcoming and Past tabs with visible labels', (
      tester,
    ) async {
      final signup = await seedSignup();
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      final theme = Theme.of(tester.element(find.byType(TabBar)));
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).labelColor,
        theme.colorScheme.onPrimary,
      );
    });

    testWidgets('does not switch tabs when the content is swiped', (
      tester,
    ) async {
      final signup = await seedSignup();
      await pumpScreen(tester, signupId: signup.id);

      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(tabController(tester).index, 0);
    });

    testWidgets('home and settings buttons are in the app bar', (tester) async {
      final signup = await seedSignup();
      await pumpScreen(tester, signupId: signup.id);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('shows a message on both tabs when there are no slots', (
      tester,
    ) async {
      final signup = await seedSignup();
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('No slots here'), findsOneWidget);
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('No slots here'), findsOneWidget);
    });

    testWidgets('lists future and undated slots as upcoming, past slots under '
        'Past', (tester) async {
      final signup = await seedSignup();
      await addSlot(signup, 'Future Week', date: future);
      await addSlot(signup, 'Undated Week');
      await addSlot(signup, 'Old Week', date: past);
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('Future Week'), findsOneWidget);
      expect(find.text('Undated Week'), findsOneWidget);
      expect(find.text('Old Week'), findsNothing);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Old Week'), findsOneWidget);
      expect(find.text('Future Week'), findsNothing);
    });

    testWidgets('shows how full each slot is, without listing entries', (
      tester,
    ) async {
      final signup = await seedSignup();
      final slotId = await addSlot(
        signup,
        'Week 1',
        date: future,
        capacity: 4,
        claimed: 1,
      );
      await addEntry(signup, slotId, 'Jane');
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('1 of 4 claimed'), findsOneWidget);
      expect(find.text('Jane'), findsNothing);
      expect(find.byTooltip('Edit Entry'), findsNothing);
    });

    testWidgets('can add a devotee to a past slot from the Past tab', (
      tester,
    ) async {
      final signup = await seedSignup();
      await addSlot(signup, 'Old Week', date: past);
      await pumpScreen(tester, signupId: signup.id);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Devotee'));
      await tester.pumpAndSettle();

      expect(find.text('Add Devotee Entry'), findsOneWidget);
    });
  });
}
