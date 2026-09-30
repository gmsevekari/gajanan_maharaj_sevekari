import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_entries_section.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  testWidgets('renders slot fill bar and empty entries state', (tester) async {
    final slot = SignupSlot(
      id: 'slot_1',
      labelEn: 'Week 1 - Cooking',
      labelMr: 'आठवडा १',
      capacity: 5,
      claimedCount: 0,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    SignupSlot? addedSlot;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminSlotEntriesSection(
            slot: slot,
            entries: const [],
            onAddEntry: (s) => addedSlot = s,
            onEditEntry: (_, _) {},
            onRemoveEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
    expect(find.text('0 of 5 claimed'), findsOneWidget);
    expect(
      find.text('No devotees have signed up for this slot yet'),
      findsOneWidget,
    );
    expect(find.text('Add Devotee'), findsOneWidget);

    await tester.tap(find.text('Add Devotee'));
    await tester.pumpAndSettle();

    expect(addedSlot, equals(slot));
  });

  testWidgets('renders entries with edit, remove, and contact actions', (
    tester,
  ) async {
    final slot = SignupSlot(
      id: 'slot_1',
      labelEn: 'Week 1 - Cooking',
      labelMr: 'आठवडा १',
      capacity: 2,
      claimedCount: 2,
      suggestedAmount: 50.0,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    final entries = [
      SignupEntry(
        id: 'entry_1',
        slotId: 'slot_1',
        name: 'Jane Doe',
        phone: '1234567890',
        email: 'jane@example.com',
        note: 'Bringing sweet dish',
        pledgeAmount: 50.0,
        joinedAt: DateTime.now(),
      ),
    ];

    SignupEntry? editedEntry;
    SignupEntry? removedEntry;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminSlotEntriesSection(
            slot: slot,
            entries: entries,
            onAddEntry: (_) {},
            onEditEntry: (e, _) => editedEntry = e,
            onRemoveEntry: (e) => removedEntry = e,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 claimed'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
    expect(find.text('Suggested: 50.0'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('Bringing sweet dish'), findsOneWidget);

    // Contact actions
    expect(find.byTooltip('Text'), findsOneWidget);
    expect(find.byTooltip('WhatsApp'), findsOneWidget);

    // Edit action
    await tester.tap(find.byTooltip('Edit Entry'));
    await tester.pumpAndSettle();
    expect(editedEntry, equals(entries.first));

    // Remove action
    await tester.tap(find.byTooltip('Remove Entry'));
    await tester.pumpAndSettle();
    expect(removedEntry, equals(entries.first));
  });

  testWidgets('renders the slot date when set', (tester) async {
    final slot = SignupSlot(
      id: 'slot_1',
      labelEn: 'Week 1 - Cooking',
      labelMr: 'आठवडा १',
      date: DateTime(2026, 3, 15),
      capacity: 5,
      claimedCount: 0,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminSlotEntriesSection(
            slot: slot,
            entries: const [],
            onAddEntry: (_) {},
            onEditEntry: (_, _) {},
            onRemoveEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('March 15'), findsOneWidget);
  });

  testWidgets('falls back to labelEn when labelMr is empty in Marathi locale', (
    tester,
  ) async {
    final slot = SignupSlot(
      id: 'slot_1',
      labelEn: 'Week 1 - Cooking',
      labelMr: '',
      capacity: 5,
      claimedCount: 0,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('mr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminSlotEntriesSection(
            slot: slot,
            entries: const [],
            onAddEntry: (_) {},
            onEditEntry: (_, _) {},
            onRemoveEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
  });
}
