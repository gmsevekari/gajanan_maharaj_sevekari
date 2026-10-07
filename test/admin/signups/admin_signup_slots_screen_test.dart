import 'dart:async';

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
      expect(entries.docs.single.data()['phone'], '15551234567');
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

    group('adding a slot', () {
      final soon = DateTime.now().add(const Duration(days: 5));

      Future<void> fillAndSave(
        WidgetTester tester, {
        String label = 'New Slot',
      }) async {
        await tester.enterText(find.byKey(const Key('slotLabelEn_0')), label);
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '4');
        await tester.tap(find.byKey(const Key('slotStartDate_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }

      testWidgets('offers Add Slot even when there are no slots yet, on both '
          'tabs', (tester) async {
        final signup = await seedSignup();
        await pumpScreen(tester, signupId: signup.id);

        expect(find.text('Add Slot'), findsOneWidget);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('Add Slot'), findsOneWidget);
      });

      testWidgets('hides Add Slot while the slots are still loading', (
        tester,
      ) async {
        const signupId = 'loading_signup';
        final mock = MockSignupService();
        when(
          () => mock.getSlots(signupId),
        ).thenAnswer((_) => StreamController<List<SignupSlot>>().stream);
        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: AdminSignupSlotsScreen(
              signupId: signupId,
              signup: stubSignup(signupId),
              signupService: mock,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Add Slot'), findsNothing);
      });

      testWidgets('adds the slot to the list and confirms', (tester) async {
        final signup = await seedSignup();
        await pumpScreen(tester, signupId: signup.id);

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        expect(find.text('Select Date'), findsWidgets);
        await fillAndSave(tester, label: 'Brand New');

        expect(find.text('Slot added successfully'), findsOneWidget);
        expect(find.text('Brand New'), findsOneWidget);
        expect(find.text('0 of 4 claimed'), findsOneWidget);
      });

      testWidgets('puts the new slot after every existing one, past or '
          'upcoming', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Old', date: DateTime(2020, 1, 10), sortOrder: 4);
        await addSlot(signup, 'Next', date: soon, sortOrder: 1);
        await pumpScreen(tester, signupId: signup.id);

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await fillAndSave(tester);

        final added = (await signup.collection('slots').get()).docs.firstWhere(
          (d) => d.data()['labelEn'] == 'New Slot',
        );
        expect(added.data()['sortOrder'], 5);
      });

      testWidgets('starts the first slot in the group\'s default zone', (
        tester,
      ) async {
        final signup = await seedSignup();
        await pumpScreen(tester, signupId: signup.id);

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();

        expect(find.text('Seattle (Pacific Time)'), findsOneWidget);
      });

      testWidgets('starts a later slot in the zone of the last one', (
        tester,
      ) async {
        final signup = await seedSignup();
        final ref = await signup.collection('slots').add({
          'labelEn': 'Indian slot',
          'labelMr': '',
          'capacity': 3,
          'claimedCount': 0,
          'sortOrder': 0,
          'startAt': Timestamp.fromDate(soon),
          'endAt': Timestamp.fromDate(soon.add(const Duration(hours: 5))),
          'timezone': 'Asia/Kolkata',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        expect(ref.id, isNotEmpty);
        await pumpScreen(tester, signupId: signup.id);

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();

        expect(find.text('India (IST)'), findsOneWidget);
      });

      testWidgets('shows no confirmation when adding is abandoned', (
        tester,
      ) async {
        final signup = await seedSignup();
        await pumpScreen(tester, signupId: signup.id);

        await tester.tap(find.text('Add Slot'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Slot added successfully'), findsNothing);
        expect((await signup.collection('slots').get()).docs, isEmpty);
      });

      testWidgets('keeps the last card clear of the button', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Only', date: soon);
        await pumpScreen(tester, signupId: signup.id);

        final list = tester.widget<ListView>(find.byType(ListView).first);
        expect((list.padding! as EdgeInsets).bottom, greaterThanOrEqualTo(80));
      });
    });

    group('deleting a slot', () {
      final soon = DateTime.now().add(const Duration(days: 5));
      final earlier = DateTime.now().subtract(const Duration(days: 5));

      Future<void> tapDeleteOn(WidgetTester tester, String label) async {
        final card = find.ancestor(
          of: find.text(label),
          matching: find.byType(Card),
        );
        final del = find.descendant(of: card, matching: find.text('Delete'));
        await tester.ensureVisible(del);
        await tester.tap(del);
        await tester.pumpAndSettle();
      }

      testWidgets('asks first, naming the slot, then removes it', (
        tester,
      ) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon);
        await addSlot(signup, 'Slot B', date: soon, sortOrder: 1);
        await pumpScreen(tester, signupId: signup.id);

        await tapDeleteOn(tester, 'Slot A');
        expect(find.text('Delete this slot?'), findsOneWidget);
        expect(
          find.text('"Slot A" will be removed. This can\'t be undone.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Slot deleted'), findsOneWidget);
        expect(find.text('Slot A'), findsNothing);
        expect(find.text('Slot B'), findsOneWidget);
        final left = (await signup.collection('slots').get()).docs;
        expect(left.map((d) => d.data()['labelEn']), ['Slot B']);
      });

      testWidgets('keeps the slot when the admin says No', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon);
        await pumpScreen(tester, signupId: signup.id);

        await tapDeleteOn(tester, 'Slot A');
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(find.text('Slot deleted'), findsNothing);
        expect(find.text('Slot A'), findsOneWidget);
        expect((await signup.collection('slots').get()).docs, hasLength(1));
      });

      testWidgets('explains instead of deleting when people have signed up', (
        tester,
      ) async {
        final signup = await seedSignup();
        final slotId = await addSlot(signup, 'Slot A', date: soon, claimed: 2);
        await addEntry(signup, slotId, 'Jane');
        await addEntry(signup, slotId, 'Amit');
        await pumpScreen(tester, signupId: signup.id);

        await tapDeleteOn(tester, 'Slot A');

        expect(find.text("Can't delete this slot"), findsOneWidget);
        expect(
          find.text(
            '2 sign-ups are on this slot. Remove their entries first, then '
            'delete the slot.',
          ),
          findsOneWidget,
        );
        expect(find.text('Delete this slot?'), findsNothing);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Slot A'), findsOneWidget);
        expect((await signup.collection('slots').get()).docs, hasLength(1));
        expect((await signup.collection('entries').get()).docs, hasLength(2));
      });

      testWidgets('works on the Past tab too', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Old Slot', date: earlier);
        await pumpScreen(tester, signupId: signup.id);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();

        await tapDeleteOn(tester, 'Old Slot');
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Old Slot'), findsNothing);
        expect(find.text('Slot deleted'), findsOneWidget);
      });

      testWidgets('explains with the live count when someone signed up after '
          'the page loaded', (tester) async {
        final now = DateTime.now();
        const signupId = 'race_signup';
        final slot = SignupSlot(
          id: 'slot_1',
          labelEn: 'Slot A',
          labelMr: '',
          startAt: soon,
          endAt: soon.add(const Duration(hours: 23)),
          capacity: 5,
          sortOrder: 0,
          createdAt: now,
        );
        final mock = MockSignupService();
        when(
          () => mock.getSlots(signupId),
        ).thenAnswer((_) => Stream.value([slot]));
        when(
          () => mock.deleteSlot(signupId, 'slot_1'),
        ).thenThrow(SlotHasClaimedEntriesException('slot_1', 3));
        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            child: AdminSignupSlotsScreen(
              signupId: signupId,
              signup: stubSignup(signupId),
              signupService: mock,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tapDeleteOn(tester, 'Slot A');
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text("Can't delete this slot"), findsOneWidget);
        expect(
          find.textContaining('3 sign-ups are on this slot'),
          findsOneWidget,
        );
        expect(find.text('Slot deleted'), findsNothing);
      });

      testWidgets('says plainly when deleting fails', (tester) async {
        final now = DateTime.now();
        const signupId = 'fail_signup';
        final slot = SignupSlot(
          id: 'slot_1',
          labelEn: 'Slot A',
          labelMr: '',
          startAt: soon,
          endAt: soon.add(const Duration(hours: 23)),
          capacity: 5,
          sortOrder: 0,
          createdAt: now,
        );
        final mock = MockSignupService();
        when(
          () => mock.getSlots(signupId),
        ).thenAnswer((_) => Stream.value([slot]));
        when(
          () => mock.deleteSlot(signupId, 'slot_1'),
        ).thenThrow(Exception('permission-denied: secret'));
        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));
        await tester.pumpWidget(
          createWidget(
            child: AdminSignupSlotsScreen(
              signupId: signupId,
              signup: stubSignup(signupId),
              signupService: mock,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tapDeleteOn(tester, 'Slot A');
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to delete slot'), findsOneWidget);
        expect(find.textContaining('secret'), findsNothing);
        expect(find.text('Slot A'), findsOneWidget);
      });
    });

    group('editing a slot', () {
      final soon = DateTime.now().add(const Duration(days: 5));
      final earlier = DateTime.now().subtract(const Duration(days: 5));

      Future<void> tapEditOn(WidgetTester tester, String label) async {
        final card = find.ancestor(
          of: find.text(label),
          matching: find.byType(Card),
        );
        final edit = find.descendant(of: card, matching: find.text('Edit'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
      }

      testWidgets('every slot card has an Edit button', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon);
        await addSlot(signup, 'Slot B', date: soon, sortOrder: 1);
        await pumpScreen(tester, signupId: signup.id);

        expect(find.text('Edit'), findsNWidgets(2));
      });

      testWidgets('opens that slot on the Edit Slot screen', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon);
        await addSlot(signup, 'Slot B', date: soon, sortOrder: 1);
        await pumpScreen(tester, signupId: signup.id);

        await tapEditOn(tester, 'Slot B');

        expect(find.text('Edit Slot'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('slotLabelEn_0')))
              .controller!
              .text,
          'Slot B',
        );
      });

      testWidgets('saving shows the change on the card, and confirms', (
        tester,
      ) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon, capacity: 3);
        await pumpScreen(tester, signupId: signup.id);
        expect(find.text('0 of 3 claimed'), findsOneWidget);

        await tapEditOn(tester, 'Slot A');
        await tester.enterText(
          find.byKey(const Key('slotLabelEn_0')),
          'Renamed',
        );
        await tester.enterText(find.byKey(const Key('slotCapacity_0')), '8');
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Slot'), findsNothing);
        expect(find.text('Slot updated successfully'), findsOneWidget);
        expect(find.text('Renamed'), findsOneWidget);
        expect(find.text('Slot A'), findsNothing);
        expect(find.text('0 of 8 claimed'), findsOneWidget);
      });

      testWidgets('shows no confirmation when the edit is abandoned', (
        tester,
      ) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Slot A', date: soon);
        await pumpScreen(tester, signupId: signup.id);

        await tapEditOn(tester, 'Slot A');
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('Edit Slot'), findsNothing);
        expect(find.text('Slot updated successfully'), findsNothing);
        expect(find.text('Slot A'), findsOneWidget);
      });

      testWidgets('works on the Past tab too', (tester) async {
        final signup = await seedSignup();
        await addSlot(signup, 'Old Slot', date: earlier);
        await pumpScreen(tester, signupId: signup.id);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();

        await tapEditOn(tester, 'Old Slot');
        await tester.enterText(find.byKey(const Key('slotLabelEn_0')), 'Fixed');
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Fixed'), findsOneWidget);
        expect(find.text('Slot updated successfully'), findsOneWidget);
      });

      testWidgets('keeps the entries and the claimed count', (tester) async {
        final signup = await seedSignup();
        final slotId = await addSlot(
          signup,
          'Slot A',
          date: soon,
          capacity: 5,
          claimed: 2,
        );
        await addEntry(signup, slotId, 'Jane');
        await addEntry(signup, slotId, 'Amit');
        await pumpScreen(tester, signupId: signup.id);

        await tapEditOn(tester, 'Slot A');
        await tester.enterText(
          find.byKey(const Key('slotLabelEn_0')),
          'Renamed',
        );
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('2 of 5 claimed'), findsOneWidget);
        final slot = await signup.collection('slots').doc(slotId).get();
        expect(slot.data()!['claimedCount'], 2);
        expect((await signup.collection('entries').get()).docs, hasLength(2));
      });
    });

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

    group('which tab a slot is on follows its end', () {
      final now = DateTime.now();

      Future<void> addTimed(
        DocumentReference<Map<String, dynamic>> signup, {
        DateTime? startAt,
        DateTime? endAt,
      }) async {
        await signup.collection('slots').add({
          'labelEn': 'Timed Week',
          'labelMr': '',
          'capacity': 3,
          'claimedCount': 0,
          'sortOrder': 0,
          'startAt': startAt == null ? null : Timestamp.fromDate(startAt),
          'endAt': endAt == null ? null : Timestamp.fromDate(endAt),
          'timezone': 'America/Los_Angeles',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      Future<void> expectOnUpcoming(WidgetTester tester) async {
        expect(find.text('Timed Week'), findsOneWidget);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('Timed Week'), findsNothing);
      }

      testWidgets('a slot that started earlier today but ends later is '
          'upcoming', (tester) async {
        final signup = await seedSignup();
        await addTimed(
          signup,
          startAt: now.subtract(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 5)),
        );
        await pumpScreen(tester, signupId: signup.id);

        await expectOnUpcoming(tester);
      });

      testWidgets('a multi-day slot that is in progress is upcoming', (
        tester,
      ) async {
        final signup = await seedSignup();
        await addTimed(
          signup,
          startAt: now.subtract(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 2)),
        );
        await pumpScreen(tester, signupId: signup.id);

        await expectOnUpcoming(tester);
      });

      testWidgets('a slot with a start but no end is upcoming', (tester) async {
        final signup = await seedSignup();
        await addTimed(signup, startAt: now.subtract(const Duration(days: 10)));
        await pumpScreen(tester, signupId: signup.id);

        await expectOnUpcoming(tester);
      });

      testWidgets('a slot that ended earlier today is past', (tester) async {
        final signup = await seedSignup();
        await addTimed(
          signup,
          startAt: now.subtract(const Duration(hours: 5)),
          endAt: now.subtract(const Duration(hours: 1)),
        );
        await pumpScreen(tester, signupId: signup.id);

        expect(find.text('Timed Week'), findsNothing);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('Timed Week'), findsOneWidget);
      });
    });
  });
}
