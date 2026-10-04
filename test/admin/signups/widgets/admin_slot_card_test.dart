import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  SignupSlot slot({
    String labelEn = 'Week 1 - Cooking',
    String labelMr = 'आठवडा १',
    DateTime? date,
    int capacity = 5,
    int claimedCount = 0,
    double? suggestedAmount,
  }) => SignupSlot(
    id: 'slot_1',
    labelEn: labelEn,
    labelMr: labelMr,
    date: date,
    capacity: capacity,
    claimedCount: claimedCount,
    suggestedAmount: suggestedAmount,
    sortOrder: 0,
    createdAt: DateTime.now(),
  );

  Widget wrap(
    SignupSlot s, {
    void Function(SignupSlot)? onAdd,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AdminSlotCard(slot: s, onAddEntry: onAdd ?? (_) {}),
      ),
    );
  }

  testWidgets('shows the label, fill count and percentage', (tester) async {
    await tester.pumpWidget(wrap(slot(claimedCount: 2)));

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
    expect(find.text('2 of 5 claimed'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Full'), findsNothing);
  });

  testWidgets('marks a full slot', (tester) async {
    await tester.pumpWidget(wrap(slot(capacity: 2, claimedCount: 2)));

    expect(find.text('Full'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('shows the date and suggested amount when set', (tester) async {
    await tester.pumpWidget(
      wrap(slot(date: DateTime(2026, 3, 15), suggestedAmount: 50)),
    );

    expect(find.text('Sunday, March 15'), findsOneWidget);
    expect(find.text('Suggested: 50.0'), findsOneWidget);
  });

  testWidgets('shows neither when unset', (tester) async {
    await tester.pumpWidget(wrap(slot()));

    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.textContaining('Suggested'), findsNothing);
  });

  testWidgets('does not list entries, only offers to add one', (tester) async {
    await tester.pumpWidget(wrap(slot(claimedCount: 3)));

    expect(find.text('Add Devotee'), findsOneWidget);
    expect(find.byTooltip('Edit Entry'), findsNothing);
    expect(
      find.text('No devotees have signed up for this slot yet'),
      findsNothing,
    );
  });

  testWidgets('reports the slot when Add Devotee is tapped', (tester) async {
    SignupSlot? added;
    final s = slot();
    await tester.pumpWidget(wrap(s, onAdd: (v) => added = v));

    await tester.tap(find.text('Add Devotee'));

    expect(added, s);
  });

  testWidgets('falls back to the English label when the Marathi is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(slot(labelMr: ''), locale: const Locale('mr')),
    );

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
  });
}
