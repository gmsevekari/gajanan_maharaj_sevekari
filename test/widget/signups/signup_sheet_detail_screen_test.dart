import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/signup_sheet_detail_screen.dart';

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

  Future<String> createOpenSheet({bool requiresJoinCode = false}) async {
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

      expect(find.text('Sign-up sheet not found'), findsOneWidget);
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
  });
}
