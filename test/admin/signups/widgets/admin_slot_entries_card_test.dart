import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_entries_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  SignupSlot slot({String labelMr = 'आठवडा १', DateTime? date}) => SignupSlot(
    id: 'slot_1',
    labelEn: 'Week 1 - Cooking',
    labelMr: labelMr,
    date: date,
    capacity: 5,
    claimedCount: 1,
    sortOrder: 0,
    createdAt: DateTime.now(),
  );

  SignupEntry entry({
    String name = 'Jane Doe',
    String? phone = '+11234567890',
    String? email = 'jane@example.com',
    String? note = 'Bringing sweet dish',
    double? pledge = 50,
  }) => SignupEntry(
    id: 'entry_$name',
    slotId: 'slot_1',
    name: name,
    phone: phone,
    email: email,
    note: note,
    pledgeAmount: pledge,
    joinedAt: DateTime.now(),
  );

  Widget wrap(
    SignupSlot s,
    List<SignupEntry> entries, {
    void Function(SignupEntry)? onEdit,
    void Function(SignupEntry)? onRemove,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AdminSlotEntriesCard(
            slot: s,
            entries: entries,
            onEditEntry: onEdit ?? (_) {},
            onRemoveEntry: onRemove ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the slot label and date above its entries', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(slot(date: DateTime(2026, 3, 15)), [entry()]));

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
    expect(find.text('March 15'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('omits the date when the slot has none', (tester) async {
    await tester.pumpWidget(wrap(slot(), [entry()]));

    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets('lists every entry with its contact details', (tester) async {
    await tester.pumpWidget(
      wrap(slot(), [entry(), entry(name: 'Joe Bloggs', phone: null)]),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Joe Bloggs'), findsOneWidget);
    expect(find.text('+11234567890'), findsOneWidget);
    expect(find.text('jane@example.com'), findsNWidgets(2));
    expect(find.text('Bringing sweet dish'), findsNWidgets(2));
    expect(find.byTooltip('Text'), findsOneWidget); // only Jane has a phone
    expect(find.byTooltip('WhatsApp'), findsOneWidget);
  });

  testWidgets('reports the entry when Edit or Remove is tapped', (
    tester,
  ) async {
    SignupEntry? edited;
    SignupEntry? removed;
    final e = entry();
    await tester.pumpWidget(
      wrap(
        slot(),
        [e],
        onEdit: (v) => edited = v,
        onRemove: (v) => removed = v,
      ),
    );

    await tester.tap(find.byTooltip('Edit Entry'));
    await tester.tap(find.byTooltip('Remove Entry'));

    expect(edited, e);
    expect(removed, e);
  });

  testWidgets('falls back to the English label when the Marathi is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(slot(labelMr: ''), [entry()], locale: const Locale('mr')),
    );

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
  });
}
