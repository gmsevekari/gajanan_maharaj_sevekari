import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/admin_signup_entries_screen.dart';
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
        child: AdminSignupEntriesScreen(
          signupId: signupId,
          signup: stubSignup(signupId),
          firestore: firestore,
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdminSignupEntriesScreen', () {
    testWidgets('edits and removes an entry', (tester) async {
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
        'claimedCount': 1,
        'sortOrder': 0,
        'createdAt': Timestamp.fromDate(now),
      });

      await signupRef.collection('entries').add({
        'slotId': slotRef.id,
        'name': 'Old Name',
        'phone': '1112223333',
        'joinedAt': Timestamp.fromDate(now),
      });

      await pumpScreen(tester, signupId: signupRef.id);

      expect(find.text('Old Name'), findsOneWidget);

      // Tap Edit
      await tester.tap(find.byTooltip('Edit Entry'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('entryNameField')),
        'New Name',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Entry updated successfully'), findsOneWidget);
      expect(find.text('New Name'), findsOneWidget);

      // Tap Remove
      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Entry removed successfully'), findsOneWidget);
      expect(find.text('New Name'), findsNothing);

      // Verify slot claimedCount decremented to 0
      final slotDoc = await slotRef.get();
      expect(slotDoc.data()?['claimedCount'], 0);
    });

    testWidgets('cancels remove entry dialog when No is clicked', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupRef = await firestore.collection('signups').add({
        'titleEn': 'Cancel Remove Signup',
        'titleMr': '',
        'groupId': 'gajanan_maharaj_seattle',
        'status': SignupStatus.published.name,
        'requiresJoinCode': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': 'admin@test.com',
      });

      final slotRef = await signupRef.collection('slots').add({
        'titleEn': 'Slot 1',
        'titleMr': '',
        'maxCapacity': 5,
        'order': 0,
      });

      await signupRef.collection('entries').add({
        'slotId': slotRef.id,
        'name': 'Stay Put User',
        'phone': '1112223333',
        'createdAt': Timestamp.fromDate(now),
        'status': 'confirmed',
      });

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupEntriesScreen(
            signupId: signupRef.id,
            signup: stubSignup(signupRef.id),
            firestore: firestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stay Put User'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsOneWidget,
      );

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to remove this entry?'),
        findsNothing,
      );
      expect(find.text('Stay Put User'), findsOneWidget);
    });

    testWidgets('shows error snackbar when adminRemoveEntry fails', (
      tester,
    ) async {
      final now = DateTime.now();
      const signupId = 'fail_remove_signup';
      const slotId = 'slot_1';
      const entryId = 'entry_1';
      final signup = Signup(
        id: signupId,
        titleEn: 'Fail Remove Signup',
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
      final entry = SignupEntry(
        id: entryId,
        slotId: slotId,
        name: 'Fail Remove User',
        phone: '1112223333',
        joinedAt: now,
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
      ).thenAnswer((_) => Stream.value([entry]));
      when(
        () => mockService.adminRemoveEntry(signupId, entryId),
      ).thenThrow(Exception('Delete failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupEntriesScreen(
            signupId: signupId,
            signup: stubSignup(signupId),
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to remove entry'), findsOneWidget);
    });

    group('releasing a device link', () {
      Future<(DocumentReference<Map<String, dynamic>>, String)> seed({
        String? deviceId,
      }) async {
        final now = DateTime.now();
        final signupRef = await firestore.collection('signups').add({
          'titleEn': 'Signup',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });
        final slotRef = await signupRef.collection('slots').add({
          'labelEn': 'Morning Seva',
          'labelMr': '',
          'capacity': 3,
          'claimedCount': 1,
          'sortOrder': 0,
          'createdAt': Timestamp.fromDate(now),
        });
        final entryRef = await signupRef.collection('entries').add({
          'slotId': slotRef.id,
          'name': 'Jane',
          'phone': '+14255551234',
          'deviceId': deviceId,
          'joinedAt': Timestamp.fromDate(now),
        });
        return (signupRef, entryRef.id);
      }

      Future<void> openEdit(WidgetTester tester) async {
        await tester.tap(find.byTooltip('Edit Entry'));
        await tester.pumpAndSettle();
      }

      testWidgets('offers it only for an entry that belongs to a device', (
        tester,
      ) async {
        final (linked, _) = await seed(deviceId: 'device_a');
        await pumpScreen(tester, signupId: linked.id);
        await openEdit(tester);
        expect(find.text('Release Device Link'), findsOneWidget);
      });

      testWidgets('does not offer it for an entry with no device', (
        tester,
      ) async {
        final (unlinked, _) = await seed();
        await pumpScreen(tester, signupId: unlinked.id);
        await openEdit(tester);
        expect(find.text('Edit Entry'), findsOneWidget);
        expect(find.text('Release Device Link'), findsNothing);
      });

      testWidgets('does not offer it for an entry with an empty device', (
        tester,
      ) async {
        final (blank, _) = await seed(deviceId: '');
        await pumpScreen(tester, signupId: blank.id);
        await openEdit(tester);
        expect(find.text('Release Device Link'), findsNothing);
      });

      testWidgets('clears the device, keeps the entry, and says so', (
        tester,
      ) async {
        final (signupRef, entryId) = await seed(deviceId: 'device_a');
        await pumpScreen(tester, signupId: signupRef.id);
        await openEdit(tester);

        await tester.tap(find.text('Release Device Link'));
        await tester.pumpAndSettle();
        expect(find.text('Release device link?'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Device link released'), findsOneWidget);
        expect(find.text('Jane'), findsOneWidget);
        final entry = await signupRef.collection('entries').doc(entryId).get();
        expect(entry.data()!['deviceId'], isNull);
        expect(entry.data()!['name'], 'Jane');
        final slot = (await signupRef.collection('slots').get()).docs.single;
        expect(slot.data()['claimedCount'], 1);
      });

      testWidgets('leaves the link alone when declined', (tester) async {
        final (signupRef, entryId) = await seed(deviceId: 'device_a');
        await pumpScreen(tester, signupId: signupRef.id);
        await openEdit(tester);

        await tester.tap(find.text('Release Device Link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(find.text('Device link released'), findsNothing);
        final entry = await signupRef.collection('entries').doc(entryId).get();
        expect(entry.data()!['deviceId'], 'device_a');
      });

      testWidgets('shows an error snackbar when releasing fails', (
        tester,
      ) async {
        final now = DateTime.now();
        const signupId = 'release_fail_signup';
        final signup = Signup(
          id: signupId,
          titleEn: 'Signup',
          titleMr: '',
          groupId: 'gajanan_maharaj_seattle',
          status: SignupStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        );
        final slot = SignupSlot(
          id: 'slot_1',
          labelEn: 'Slot 1',
          labelMr: '',
          capacity: 5,
          sortOrder: 0,
          createdAt: now,
        );
        final entry = SignupEntry(
          id: 'entry_1',
          slotId: 'slot_1',
          name: 'Jane',
          phone: '+14255551234',
          deviceId: 'device_a',
          joinedAt: now,
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
        ).thenAnswer((_) => Stream.value([entry]));
        when(
          () => mockService.releaseEntryDevice(signupId, 'entry_1'),
        ).thenThrow(Exception('secret'));
        setLargeScreen(tester);
        addTearDown(() => resetScreen(tester));

        await tester.pumpWidget(
          createWidget(
            child: AdminSignupEntriesScreen(
              signupId: signupId,
              signup: stubSignup(signupId),
              signupService: mockService,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openEdit(tester);
        await tester.tap(find.text('Release Device Link'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to release device link'), findsOneWidget);
        expect(find.textContaining('secret'), findsNothing);
      });
    });

    testWidgets('shows error snackbar when updateEntry fails', (tester) async {
      final now = DateTime.now();
      const signupId = 'fail_update_signup';
      const slotId = 'slot_1';
      const entryId = 'entry_1';
      final signup = Signup(
        id: signupId,
        titleEn: 'Fail Update Signup',
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
      final entry = SignupEntry(
        id: entryId,
        slotId: slotId,
        name: 'Fail Update User',
        phone: '1112223333',
        joinedAt: now,
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
      ).thenAnswer((_) => Stream.value([entry]));
      when(
        () => mockService.updateEntry(signupId, any()),
      ).thenThrow(Exception('Update failed'));

      setLargeScreen(tester);
      addTearDown(() => resetScreen(tester));

      await tester.pumpWidget(
        createWidget(
          child: AdminSignupEntriesScreen(
            signupId: signupId,
            signup: stubSignup(signupId),
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update entry'), findsOneWidget);
    });

    testWidgets(
      'deleting from within edit dialog triggers confirm remove dialog',
      (tester) async {
        final now = DateTime.now();
        final signupRef = await firestore.collection('signups').add({
          'titleEn': 'Dialog Delete Signup',
          'titleMr': '',
          'groupId': 'gajanan_maharaj_seattle',
          'status': SignupStatus.published.name,
          'requiresJoinCode': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'createdBy': 'admin@test.com',
        });

        final slotRef = await signupRef.collection('slots').add({
          'labelEn': 'Slot 1',
          'labelMr': '',
          'capacity': 5,
          'sortOrder': 0,
          'createdAt': Timestamp.fromDate(now),
        });

        await signupRef.collection('entries').add({
          'slotId': slotRef.id,
          'name': 'Dialog Delete User',
          'phone': '1112223333',
          'joinedAt': Timestamp.fromDate(now),
        });

        await pumpScreen(tester, signupId: signupRef.id);

        await tester.tap(find.byTooltip('Edit Entry'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'Remove Entry'));
        await tester.pumpAndSettle();

        expect(
          find.text('Are you sure you want to remove this entry?'),
          findsOneWidget,
        );

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();
      },
    );
  });

  group('AdminSignupEntriesScreen tabs', () {
    final past = DateTime(2020, 1, 10);
    final future = DateTime(2099, 3, 15);
    final farFuture = DateTime(2099, 4, 1);

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

    testWidgets('shows a message on both tabs when there are no entries', (
      tester,
    ) async {
      final signup = await seedSignup();
      await addSlot(signup, 'Empty Week', date: future);
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('No one has signed up yet'), findsOneWidget);
      expect(find.text('Empty Week'), findsNothing); // no entries, no card
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();
      expect(find.text('No one has signed up yet'), findsOneWidget);
    });

    testWidgets('groups entries under their slot, upcoming and past apart', (
      tester,
    ) async {
      final signup = await seedSignup();
      final future1 = await addSlot(signup, 'Future Week', date: future);
      final old = await addSlot(signup, 'Old Week', date: past);
      await addEntry(signup, future1, 'Jane');
      await addEntry(signup, future1, 'Amit');
      await addEntry(signup, old, 'Priya');
      await pumpScreen(tester, signupId: signup.id);

      expect(find.text('Future Week'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
      expect(find.text('Amit'), findsOneWidget);
      expect(find.text('Priya'), findsNothing);

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Old Week'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Jane'), findsNothing);
    });

    testWidgets('orders slot cards by date, undated last, then slot order', (
      tester,
    ) async {
      final signup = await seedSignup();
      final undated = await addSlot(signup, 'Undated', sortOrder: 0);
      final later = await addSlot(
        signup,
        'Later',
        date: farFuture,
        sortOrder: 1,
      );
      final sameDayB = await addSlot(
        signup,
        'Same Day B',
        date: future,
        sortOrder: 3,
      );
      final sameDayA = await addSlot(
        signup,
        'Same Day A',
        date: future,
        sortOrder: 2,
      );
      for (final id in [undated, later, sameDayB, sameDayA]) {
        await addEntry(signup, id, 'Person $id');
      }
      await pumpScreen(tester, signupId: signup.id);

      double top(String label) => tester.getTopLeft(find.text(label)).dy;
      expect(top('Same Day A'), lessThan(top('Same Day B')));
      expect(top('Same Day B'), lessThan(top('Later')));
      expect(top('Later'), lessThan(top('Undated')));
    });

    testWidgets('keeps edit, remove and contact actions on each entry', (
      tester,
    ) async {
      final signup = await seedSignup();
      final slotId = await addSlot(signup, 'Week 1', date: future);
      await signup.collection('entries').add({
        'slotId': slotId,
        'name': 'Jane',
        'phone': '+11234567890',
        'email': 'jane@example.com',
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      });
      await pumpScreen(tester, signupId: signup.id);

      expect(find.byTooltip('Edit Entry'), findsOneWidget);
      expect(find.byTooltip('Remove Entry'), findsOneWidget);
      expect(find.byTooltip('WhatsApp'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    group('which tab an entry is on follows the end of its slot', () {
      final now = DateTime.now();

      Future<String> addTimed(
        DocumentReference<Map<String, dynamic>> signup,
        String label, {
        DateTime? startAt,
        DateTime? endAt,
        int sortOrder = 0,
      }) async {
        final ref = await signup.collection('slots').add({
          'labelEn': label,
          'labelMr': '',
          'capacity': 3,
          'claimedCount': 1,
          'sortOrder': sortOrder,
          'startAt': startAt == null ? null : Timestamp.fromDate(startAt),
          'endAt': endAt == null ? null : Timestamp.fromDate(endAt),
          'timezone': 'America/Los_Angeles',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        return ref.id;
      }

      Future<void> pumpEntryFor(
        WidgetTester tester, {
        DateTime? startAt,
        DateTime? endAt,
      }) async {
        final signup = await seedSignup();
        final slotId = await addTimed(
          signup,
          'Timed Week',
          startAt: startAt,
          endAt: endAt,
        );
        await addEntry(signup, slotId, 'Jane');
        await pumpScreen(tester, signupId: signup.id);
      }

      Future<void> expectOnUpcoming(WidgetTester tester) async {
        expect(find.text('Timed Week'), findsOneWidget);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('Timed Week'), findsNothing);
      }

      testWidgets('a slot that started earlier today but ends later is '
          'upcoming', (tester) async {
        await pumpEntryFor(
          tester,
          startAt: now.subtract(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 5)),
        );
        await expectOnUpcoming(tester);
      });

      testWidgets('a multi-day slot that is in progress is upcoming', (
        tester,
      ) async {
        await pumpEntryFor(
          tester,
          startAt: now.subtract(const Duration(days: 1)),
          endAt: now.add(const Duration(days: 2)),
        );
        await expectOnUpcoming(tester);
      });

      testWidgets('a slot with a start but no end is upcoming', (tester) async {
        await pumpEntryFor(
          tester,
          startAt: now.subtract(const Duration(days: 10)),
        );
        await expectOnUpcoming(tester);
      });

      testWidgets('a slot that ended earlier today is past', (tester) async {
        await pumpEntryFor(
          tester,
          startAt: now.subtract(const Duration(hours: 5)),
          endAt: now.subtract(const Duration(hours: 1)),
        );

        expect(find.text('Timed Week'), findsNothing);
        await tester.tap(find.text('Past'));
        await tester.pumpAndSettle();
        expect(find.text('Timed Week'), findsOneWidget);
      });

      testWidgets('lists slots on the same day by start time, whatever '
          'their slot order', (tester) async {
        final signup = await seedSignup();
        final day = DateTime.now().add(const Duration(days: 4));
        final morning = DateTime(day.year, day.month, day.day, 9);
        final evening = DateTime(day.year, day.month, day.day, 18);
        final eveningId = await addTimed(
          signup,
          'Evening',
          startAt: evening,
          endAt: evening.add(const Duration(hours: 2)),
          sortOrder: 0,
        );
        final morningId = await addTimed(
          signup,
          'Morning',
          startAt: morning,
          endAt: morning.add(const Duration(hours: 2)),
          sortOrder: 5,
        );
        await addEntry(signup, eveningId, 'Eve');
        await addEntry(signup, morningId, 'Mo');
        await pumpScreen(tester, signupId: signup.id);

        expect(
          tester.getTopLeft(find.text('Morning')).dy,
          lessThan(tester.getTopLeft(find.text('Evening')).dy),
        );
      });

      testWidgets('lists slots that tie on start and order by id, so the '
          'order is fixed', (tester) async {
        final signup = await seedSignup();
        final start = DateTime.now().add(const Duration(days: 4));
        final ids = <String, String>{};
        for (final label in ['Tie A', 'Tie B', 'Tie C']) {
          final id = await addTimed(
            signup,
            label,
            startAt: start,
            endAt: start.add(const Duration(hours: 2)),
          );
          ids[label] = id;
          await addEntry(signup, id, 'Person of $label');
        }
        await pumpScreen(tester, signupId: signup.id);

        final shown = ids.keys.toList()
          ..sort(
            (a, b) => tester
                .getTopLeft(find.text(a))
                .dy
                .compareTo(tester.getTopLeft(find.text(b)).dy),
          );
        final byId = ids.keys.toList()
          ..sort((a, b) => ids[a]!.compareTo(ids[b]!));
        expect(shown, byId);
      });
    });
  });
}
