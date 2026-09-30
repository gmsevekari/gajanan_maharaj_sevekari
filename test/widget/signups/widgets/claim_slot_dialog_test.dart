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
  late String sheetId;
  late String plainSlotId;
  late String donationSlotId;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = SignupService(firestore: firestore);
    final now = DateTime.now();
    sheetId = await service.createSheet(
      SignupSheet(
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        groupId: 'group_1',
        requiresJoinCode: true,
        joinCode: 'ABC123',
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin@test.com',
      ),
    );
    plainSlotId = await service.addSlot(
      sheetId,
      SignupSlot(
        labelEn: 'Week 1',
        labelMr: 'आठवडा १',
        capacity: 1,
        sortOrder: 0,
        createdAt: now,
      ),
    );
    donationSlotId = await service.addSlot(
      sheetId,
      SignupSlot(
        labelEn: 'Donation Item',
        labelMr: 'देणगी वस्तू',
        capacity: 5,
        suggestedAmount: 25.0,
        sortOrder: 1,
        createdAt: now,
      ),
    );
  });

  Future<SignupSlot> slotById(String slotId) async {
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
    required String slotId,
    required bool requiresJoinCode,
  }) async {
    final slot = await slotById(slotId);
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
        await openDialog(tester, slotId: plainSlotId, requiresJoinCode: false);

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
      await openDialog(tester, slotId: donationSlotId, requiresJoinCode: false);

      expect(find.text('Pledge Amount'), findsOneWidget);
    });

    testWidgets('shows the join code field when the sheet requires one', (
      tester,
    ) async {
      await openDialog(tester, slotId: plainSlotId, requiresJoinCode: true);

      expect(find.text('Join Code'), findsOneWidget);
    });

    testWidgets('validates that a name is required', (tester) async {
      await openDialog(tester, slotId: plainSlotId, requiresJoinCode: false);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets(
      'shows a confirmation dialog before submitting, and cancelling it does not claim',
      (tester) async {
        await openDialog(tester, slotId: plainSlotId, requiresJoinCode: false);

        await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Signup'), findsOneWidget);
        expect(find.text('Submit this signup?'), findsOneWidget);

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        final entries = await service.getAllEntries(sheetId).first;
        expect(entries, isEmpty);
      },
    );

    testWidgets('confirming claims the slot and pops with true', (
      tester,
    ) async {
      await openDialog(tester, slotId: plainSlotId, requiresJoinCode: false);

      await tester.enterText(find.byKey(const Key('claimNameField')), 'Jane');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.byType(ClaimSlotDialog), findsNothing);
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries.single.name, 'Jane');
      final slot = await slotById(plainSlotId);
      expect(slot.claimedCount, 1);
    });

    testWidgets('shows a visible error and stays open when the slot is full', (
      tester,
    ) async {
      // Fill the only spot first.
      await service.claimSlot(
        sheetId: sheetId,
        slotId: plainSlotId,
        name: 'First',
      );

      await openDialog(tester, slotId: plainSlotId, requiresJoinCode: false);

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
      await openDialog(tester, slotId: plainSlotId, requiresJoinCode: true);

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
  });
}
