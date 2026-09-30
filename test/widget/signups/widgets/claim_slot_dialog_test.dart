import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/claim_slot_dialog.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SignupService service;
  late String openSheetId;
  late String plainSlotId;
  late String donationSlotId;
  late String codeSheetId;
  late String codeSlotId;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    final now = DateTime.now();

    openSheetId = await service.createSheet(
      SignupSheet(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        groupId: 'group_1',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
    plainSlotId = await service.addSlot(
      openSheetId,
      SignupSlot(
        labelEn: 'Week 1',
        labelMr: 'आठवडा १',
        capacity: 1,
        sortOrder: 0,
        createdAt: now,
      ),
    );
    donationSlotId = await service.addSlot(
      openSheetId,
      SignupSlot(
        labelEn: 'Donation Item',
        labelMr: 'देणगी वस्तू',
        capacity: 5,
        suggestedAmount: 25.0,
        sortOrder: 1,
        createdAt: now,
      ),
    );

    codeSheetId = await service.createSheet(
      SignupSheet(
        titleEn: 'Members-Only Seva',
        titleMr: 'सदस्यांसाठी सेवा',
        groupId: 'group_1',
        requiresJoinCode: true,
        joinCode: 'ABC123',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
    codeSlotId = await service.addSlot(
      codeSheetId,
      SignupSlot(
        labelEn: 'Week 1',
        labelMr: 'आठवडा १',
        capacity: 1,
        sortOrder: 0,
        createdAt: now,
      ),
    );
  });

  Future<SignupSlot> slotById(String sheetId, String slotId) async {
    return (await service.getSlots(sheetId).first).firstWhere(
      (s) => s.id == slotId,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required String sheetId,
    required String slotId,
    required bool requiresJoinCode,
  }) async {
    final slot = await slotById(sheetId, slotId);
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ClaimSlotDialog(
                sheetId: sheetId,
                slot: slot,
                requiresJoinCode: requiresJoinCode,
                deviceId: 'device_1',
                signupService: service,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ClaimSlotDialog', () {
    testWidgets(
      'renders name/phone/email/note but not pledge or join code by default',
      (tester) async {
        await openDialog(
          tester,
          sheetId: openSheetId,
          slotId: plainSlotId,
          requiresJoinCode: false,
        );

        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Phone'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Note'), findsOneWidget);
        expect(find.text('Pledge Amount'), findsNothing);
        expect(find.text('Join Code'), findsNothing);
      },
    );

    testWidgets('shows the pledge field for a slot with a suggested amount', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: donationSlotId,
        requiresJoinCode: false,
      );

      expect(find.text('Pledge Amount'), findsOneWidget);
    });

    testWidgets('shows the join code field when the sheet requires one', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: codeSheetId,
        slotId: codeSlotId,
        requiresJoinCode: true,
      );

      expect(find.text('Join Code'), findsOneWidget);
    });

    testWidgets('validates that a name is required', (tester) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: plainSlotId,
        requiresJoinCode: false,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets(
      'shows a confirmation dialog before submitting, and cancelling it does not claim',
      (tester) async {
        await openDialog(
          tester,
          sheetId: openSheetId,
          slotId: plainSlotId,
          requiresJoinCode: false,
        );

        await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Signup'), findsOneWidget);
        expect(find.text('Submit this signup?'), findsOneWidget);

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        final entries = await service.getAllEntries(openSheetId).first;
        expect(entries, isEmpty);
      },
    );

    testWidgets('confirming claims the slot and pops with true', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: plainSlotId,
        requiresJoinCode: false,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.byType(ClaimSlotDialog), findsNothing);
      final entries = await service.getAllEntries(openSheetId).first;
      expect(entries.single.name, 'Jane');
      final slot = await slotById(openSheetId, plainSlotId);
      expect(slot.claimedCount, 1);
    });

    testWidgets('shows a visible error and stays open when the slot is full', (
      tester,
    ) async {
      // Fill the only spot first.
      await service.claimSlot(
        sheetId: openSheetId,
        slotId: plainSlotId,
        name: 'First',
      );

      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: plainSlotId,
        requiresJoinCode: false,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('This slot is already full'), findsOneWidget);
      expect(find.byType(ClaimSlotDialog), findsOneWidget);
    });

    testWidgets('shows a visible error and stays open for a wrong join code', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: codeSheetId,
        slotId: codeSlotId,
        requiresJoinCode: true,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.enterText(
        find.byKey(const Key('claimJoinCodeField')),
        'WRONG',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Join Code!'), findsOneWidget);
      expect(find.byType(ClaimSlotDialog), findsOneWidget);
    });

    testWidgets('submits phone, email, and note when filled in', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: plainSlotId,
        requiresJoinCode: false,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.enterText(
        find.byKey(const Key('claimPhoneField')),
        '1234567890',
      );
      await tester.enterText(
        find.byKey(const Key('claimEmailField')),
        'jane@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('claimNoteField')),
        'Bringing sweets',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      final entry = (await service.getAllEntries(openSheetId).first).single;
      expect(entry.phone, '1234567890');
      expect(entry.email, 'jane@example.com');
      expect(entry.note, 'Bringing sweets');
    });

    testWidgets(
      'falls back to the Marathi label in the confirmation dialog when English is empty',
      (tester) async {
        final now = DateTime.now();
        final noEnglishSlotId = await service.addSlot(
          openSheetId,
          SignupSlot(
            labelEn: '',
            labelMr: 'आठवडा २',
            capacity: 1,
            sortOrder: 2,
            createdAt: now,
          ),
        );

        await openDialog(
          tester,
          sheetId: openSheetId,
          slotId: noEnglishSlotId,
          requiresJoinCode: false,
        );

        await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('आठवडा २'), findsOneWidget);
      },
    );

    testWidgets('submits a donation slot with a valid pledge amount', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: donationSlotId,
        requiresJoinCode: false,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.enterText(find.byKey(const Key('claimPledgeField')), '25.5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      final entry = (await service.getAllEntries(openSheetId).first).single;
      expect(entry.pledgeAmount, 25.5);
    });

    testWidgets('rejects a non-numeric pledge amount', (tester) async {
      await openDialog(
        tester,
        sheetId: openSheetId,
        slotId: donationSlotId,
        requiresJoinCode: false,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.enterText(
        find.byKey(const Key('claimPledgeField')),
        'not a number',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid amount'), findsOneWidget);
      final entries = await service.getAllEntries(openSheetId).first;
      expect(entries, isEmpty);
    });

    testWidgets('requires a join code to be entered when the sheet needs one', (
      tester,
    ) async {
      await openDialog(
        tester,
        sheetId: codeSheetId,
        slotId: codeSlotId,
        requiresJoinCode: true,
      );

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The hint text and the validator's error message are the same
      // string ("Enter 6-character code"), so it now renders twice.
      expect(find.text('Enter 6-character code'), findsNWidgets(2));
      final entries = await service.getAllEntries(codeSheetId).first;
      expect(entries, isEmpty);
    });

    testWidgets('shows a generic error message for an unexpected failure', (
      tester,
    ) async {
      final now = DateTime.now();
      final missingSlot = SignupSlot(
        id: 'nonexistent_slot',
        labelEn: 'Ghost Slot',
        labelMr: 'भूत स्लॉट',
        capacity: 1,
        sortOrder: 99,
        createdAt: now,
      );

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ClaimSlotDialog(
                  sheetId: openSheetId,
                  slot: missingSlot,
                  requiresJoinCode: false,
                  deviceId: 'device_1',
                  signupService: service,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to claim slot. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
