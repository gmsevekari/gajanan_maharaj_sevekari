import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_sheet_detail_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSignupService extends Mock implements SignupService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(settings.name ?? '')),
          body: Text('Navigated to: ${settings.name}'),
        ),
      ),
      home: child,
    );
  }

  Future<String> createOpenSheet({
    bool requiresJoinCode = false,
    String? headerImageUrl,
  }) async {
    final now = DateTime.now();
    return service.createSheet(
      SignupSheet(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: 'Cook and serve prasad',
        descriptionMr: 'प्रसाद शिजवा आणि वाढा',
        groupId: 'group_1',
        status: SignupSheetStatus.published,
        requiresJoinCode: requiresJoinCode,
        joinCode: requiresJoinCode ? 'ABC123' : null,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
        headerImageUrl: headerImageUrl,
      ),
    );
  }

  group('SignupSheetDetailScreen', () {
    testWidgets('shows not-found message when the sheet does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: 'missing',
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign up not found'), findsOneWidget);
    });

    testWidgets('renders the sheet title, description, and slots', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();
      final now = DateTime.now();
      await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: now,
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
      expect(find.text('Cook and serve prasad'), findsOneWidget);
      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('0 of 3 claimed'), findsOneWidget);
    });

    testWidgets(
      'shows the empty My Signups state when the device has no entries',
      (tester) async {
        final sheetId = await createOpenSheet();

        await tester.pumpWidget(
          wrap(
            SignupSheetDetailScreen(
              sheetId: sheetId,
              deviceId: 'device_1',
              firestore: firestore,
              signupService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Signups'), findsOneWidget);
        expect(
          find.text("You haven't signed up for anything yet"),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping an open slot claims it and shows it in My Signups', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();
      final now = DateTime.now();
      await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: now,
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week 1'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 claimed'), findsOneWidget);
      expect(find.text("You haven't signed up for anything yet"), findsNothing);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('tapping a full slot does not open the claim dialog', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();
      final slotId = await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 1,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );
      await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'First');

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_2',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full'), findsOneWidget);

      await tester.tap(find.text('Week 1'));
      await tester.pumpAndSettle();

      expect(find.text('Claim Slot'), findsNothing);
    });

    testWidgets('cancelling an own entry removes it after confirmation', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();
      final slotId = await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_1',
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jane'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Signup?'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(
        find.text("You haven't signed up for anything yet"),
        findsOneWidget,
      );
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, isEmpty);
    });

    testWidgets('declining the cancel confirmation keeps the entry', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();
      final slotId = await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_1',
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(find.text('Jane'), findsOneWidget);
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, hasLength(1));
    });

    testWidgets('passes requiresJoinCode through to the claim dialog', (
      tester,
    ) async {
      final sheetId = await createOpenSheet(requiresJoinCode: true);
      await service.addSlot(
        sheetId,
        SignupSlot(
          labelEn: 'Week 1',
          labelMr: 'आठवडा १',
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week 1'));
      await tester.pumpAndSettle();

      expect(find.text('Join Code'), findsOneWidget);
    });

    testWidgets('fetches the device id automatically when not injected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'unique_device_id': 'mock-device-id',
      });
      final sheetId = await createOpenSheet();

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text("You haven't signed up for anything yet"),
        findsOneWidget,
      );
    });

    testWidgets('resolves the sheet id from ModalRoute arguments', (
      tester,
    ) async {
      final sheetId = await createOpenSheet();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => SignupSheetDetailScreen(
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
                  settings: RouteSettings(arguments: {'sheetId': sheetId}),
                  builder: (_) => SignupSheetDetailScreen(
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
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sunday Prasad Seva'), findsOneWidget);
    });

    testWidgets('shows an error snackbar when cancelling an entry fails', (
      tester,
    ) async {
      final entry = SignupEntry(
        id: 'entry_1',
        slotId: 'slot_1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      );
      final sheet = SignupSheet(
        id: 'sheet_err',
        titleEn: 'Sheet',
        titleMr: 'शीट',
        groupId: 'group_1',
        status: SignupSheetStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin@test.com',
      );
      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById('sheet_err'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_err'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => mockService.getEntriesByDevice('sheet_err', 'device_1'),
      ).thenAnswer((_) => Stream.value([entry]));
      when(
        () => mockService.cancelEntry('sheet_err', 'entry_1'),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: 'sheet_err',
            deviceId: 'device_1',
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to cancel signup. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('renders the Marathi title when locale is mr', (tester) async {
      final sheetId = await createOpenSheet();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रविवार प्रसाद सेवा'), findsOneWidget);
    });

    testWidgets('falls back to the English description when Marathi is blank', (
      tester,
    ) async {
      final now = DateTime.now();
      final sheetId = await service.createSheet(
        SignupSheet(
          titleEn: 'Sunday Prasad Seva',
          titleMr: 'रविवार प्रसाद सेवा',
          descriptionEn: 'Cook and serve prasad',
          descriptionMr: '',
          groupId: 'group_1',
          status: SignupSheetStatus.published,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin@test.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignupSheetDetailScreen(
            sheetId: sheetId,
            deviceId: 'device_1',
            firestore: firestore,
            signupService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cook and serve prasad'), findsOneWidget);
    });

    testWidgets('does not resubscribe to getEntriesByDevice on every rebuild', (
      tester,
    ) async {
      final sheet = SignupSheet(
        id: 'sheet_rebuild',
        titleEn: 'Sheet',
        titleMr: 'शीट',
        groupId: 'group_1',
        status: SignupSheetStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin@test.com',
      );
      final slotsController = StreamController<List<SignupSlot>>.broadcast();
      addTearDown(slotsController.close);
      final mockService = MockSignupService();
      when(
        () => mockService.getSheetById('sheet_rebuild'),
      ).thenAnswer((_) => Stream.value(sheet));
      when(
        () => mockService.getSlots('sheet_rebuild'),
      ).thenAnswer((_) => slotsController.stream);
      when(
        () => mockService.getEntriesByDevice('sheet_rebuild', 'device_1'),
      ).thenAnswer((_) => Stream.value(const []));

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: 'sheet_rebuild',
            deviceId: 'device_1',
            signupService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate the slots stream emitting again (e.g. another devotee
      // claims a slot) - this must not tear down and resubscribe the
      // unrelated "my entries" stream.
      slotsController.add(const []);
      await tester.pumpAndSettle();
      slotsController.add(const []);
      await tester.pumpAndSettle();

      verify(
        () => mockService.getEntriesByDevice('sheet_rebuild', 'device_1'),
      ).called(1);
    });

    testWidgets('renders the header image when the sheet has one', (
      tester,
    ) async {
      final sheetId = await createOpenSheet(
        headerImageUrl: 'https://example.com/header.jpg',
      );

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
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

    testWidgets('renders no image when the sheet has none', (tester) async {
      final sheetId = await createOpenSheet();

      await tester.pumpWidget(
        wrap(
          SignupSheetDetailScreen(
            sheetId: sheetId,
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
