import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/signups/my_signups_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_slots_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
  });

  Widget wrap(Widget child, {Locale? locale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FestivalProvider()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? '')),
            body: Text('Navigated to: ${settings.name}'),
          ),
        ),
        home: child,
      ),
    );
  }

  Future<String> createOpenSignup({
    bool requiresJoinCode = false,
    String? headerImageUrl,
  }) async {
    final now = DateTime.now();
    return service.createSignup(
      Signup(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: 'Cook and serve prasad',
        descriptionMr: 'प्रसाद शिजवा आणि वाढा',
        groupId: 'group_1',
        status: SignupStatus.published,
        requiresJoinCode: requiresJoinCode,
        joinCode: requiresJoinCode ? 'ABC123' : null,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
        headerImageUrl: headerImageUrl,
      ),
    );
  }

  group('SignupDetailScreen', () {
    testWidgets('shows not-found message when the signup does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'missing',
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign up not found'), findsOneWidget);
    });

    testWidgets('tapping home icon navigates to home', (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'missing',
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /home'), findsOneWidget);
    });

    testWidgets('tapping settings icon navigates to settings', (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'missing',
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is IconButton && w.onPressed != null)
            .at(1),
      );
      await tester.pumpAndSettle();

      expect(find.text('Navigated to: /settings'), findsOneWidget);
    });

    testWidgets('renders the signup title, description, and nav cards', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
      expect(find.text('Cook and serve prasad'), findsOneWidget);
      expect(find.text('My Signups'), findsOneWidget);
      expect(find.text('Slots'), findsOneWidget);
    });

    testWidgets('tapping the My Sign Ups card opens MySignupsScreen', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Signups'));
      await tester.pumpAndSettle();

      expect(find.byType(MySignupsScreen), findsOneWidget);
    });

    testWidgets('tapping the Slots card opens SignupSlotsScreen', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Slots'));
      await tester.pumpAndSettle();

      expect(find.byType(SignupSlotsScreen), findsOneWidget);
    });

    testWidgets('shows a message in the Entries table when there are none', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('No one has signed up yet'), findsOneWidget);
    });

    testWidgets('lists every entry in the Entries table', (tester) async {
      final signupId = await createOpenSignup();
      final slot1 = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          date: DateTime(2026, 3, 15),
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );
      final slot2 = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Week 2',
          labelMr: 'आठवडा २',
          date: DateTime(2026, 3, 1),
          capacity: 2,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      );
      final slot3 = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Week 3',
          labelMr: 'आठवडा ३',
          capacity: 1,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
      );
      // Same date as slot1, to exercise the sort's tie-break-by-name branch.
      final slot4 = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Week 4',
          labelMr: 'आठवडा ४',
          date: DateTime(2026, 3, 15),
          capacity: 1,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),
      );
      await service.claimSlot(signupId: signupId, slotId: slot1, name: 'Jane');
      await service.claimSlot(signupId: signupId, slotId: slot2, name: 'Amit');
      await service.claimSlot(signupId: signupId, slotId: slot3, name: 'Priya');
      await service.claimSlot(signupId: signupId, slotId: slot4, name: 'Anil');

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rows are sorted by slot date (slot3's null date sorts last, slot1
      // and slot4 tie on date and fall back to comparing names) - verifies
      // every branch of the comparator.
      final dataTable = tester.widget<DataTable>(find.byType(DataTable));
      final rows = dataTable.rows
          .map(
            (row) =>
                row.cells.map((cell) => (cell.child as Text).data).toList(),
          )
          .toList();
      expect(rows, [
        ['March 1', 'Week 2', 'Amit', '1'], // slot2: 2 capacity - 1 claimed
        ['March 15', 'Week 4', 'Anil', '0'], // slot4: 1 capacity - 1 claimed
        ['March 15', 'Week 1', 'Jane', '2'], // slot1: 3 capacity - 1 claimed
        ['-', 'Week 3', 'Priya', '0'], // slot3: no date, 1 cap - 1 claimed
      ]);
    });

    testWidgets('shows the Marathi slot label in the Entries table', (
      tester,
    ) async {
      final signupId = await createOpenSignup();
      final slotId = await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('आठवडा १'), findsOneWidget);
    });

    testWidgets(
      'shows a blank title and dash for an entry whose slot was deleted',
      (tester) async {
        final signupId = await createOpenSignup();
        final slotId = await service.addSlot(
          signupId,
          SignupSlot(
            labelEn: 'Week 1',
            labelMr: 'आठवडा १',
            capacity: 3,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        );
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Orphan',
        );
        // Bypass SignupService.deleteSlot's claimed-entry guard to simulate
        // an entry left behind after its slot is gone some other way.
        await firestore
            .collection('signups')
            .doc(signupId)
            .collection('slots')
            .doc(slotId)
            .delete();

        await tester.pumpWidget(
          wrap(
            SignupDetailScreen(
              signupId: signupId,
              deviceId: 'device_1',
              firestore: firestore,
              signupService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Orphan'), findsOneWidget);
        expect(find.text('-'), findsNWidgets(2)); // date column + count column
      },
    );

    testWidgets('fetches the device id automatically when not injected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'unique_device_id': 'mock-device-id',
      });
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('My Signups'), findsOneWidget);
    });

    testWidgets('resolves the signup id from ModalRoute arguments', (
      tester,
    ) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => FestivalProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => SignupDetailScreen(
                deviceId: 'device_1',
                firestore: firestore,
                signupService: service,
              ),
            ),
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(arguments: {'signupId': signupId}),
                    builder: (_) => SignupDetailScreen(
                      deviceId: 'device_1',
                      firestore: firestore,
                      signupService: service,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    });

    testWidgets('renders the Marathi title when locale is mr', (tester) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
    });

    testWidgets('falls back to the English description when Marathi is blank', (
      tester,
    ) async {
      final now = DateTime.now();
      final signupId = await service.createSignup(
        Signup(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          descriptionEn: 'Cook and serve prasad',
          descriptionMr: '',
          groupId: 'group_1',
          status: SignupStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
          locale: const Locale('mr'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cook and serve prasad'), findsOneWidget);
    });

    testWidgets('does not resubscribe to getAllEntries on every rebuild', (
      tester,
    ) async {
      final signup = Signup(
        id: 'signup_rebuild',
        titleEn: 'Signup',
        titleMr: 'शीट',
        groupId: 'group_1',
        status: SignupStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin@test.com',
      );
      final slotsController = StreamController<List<SignupSlot>>.broadcast();
      addTearDown(slotsController.close);
      final mockService = MockSignupService();
      when(
        () => mockService.getSignupById('signup_rebuild'),
      ).thenAnswer((_) => Stream.value(signup));
      when(
        () => mockService.getSlots('signup_rebuild'),
      ).thenAnswer((_) => slotsController.stream);
      when(
        () => mockService.getAllEntries('signup_rebuild'),
      ).thenAnswer((_) => Stream.value(const []));

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: 'signup_rebuild',
            deviceId: 'device_1',
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate the slots stream emitting again (e.g. another devotee
      // claims a slot) - this must not tear down and resubscribe the
      // unrelated entries stream.
      slotsController.add(const []);
      await tester.pumpAndSettle();
      slotsController.add(const []);
      await tester.pumpAndSettle();

      verify(() => mockService.getAllEntries('signup_rebuild')).called(1);
    });

    testWidgets('renders the header image when the signup has one', (
      tester,
    ) async {
      final signupId = await createOpenSignup(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Image.network makes a real HTTP request with no network access in
      // the test environment; expected and harmless here, since this
      // test only checks that an Image widget renders, not its pixels.
      tester.takeException();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders no image when the signup has none', (tester) async {
      final signupId = await createOpenSignup();

      await tester.pumpWidget(
        wrap(
          SignupDetailScreen(
            signupId: signupId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });
  });
}
