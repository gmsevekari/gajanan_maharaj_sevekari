import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

import '../../../helpers/slot_fixtures.dart';

void main() {
  SignupSlot slot({
    String labelEn = 'Week 1 - Cooking',
    String labelMr = 'आठवडा १',
    DateTime? start,
    DateTime? end,
    String timezone = EventTimezone.pacific,
    int capacity = 5,
    int claimedCount = 0,
    double? suggestedAmount,
  }) => SignupSlot(
    id: 'slot_1',
    labelEn: labelEn,
    labelMr: labelMr,
    startAt: start,
    endAt: end,
    timezone: timezone,
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
    await tester.pumpWidget(wrap(allDaySlot(2026, 3, 15, suggestedAmount: 50)));

    expect(find.text('Sunday, March 15'), findsOneWidget);
    expect(find.text('Suggested: 50.0'), findsOneWidget);
  });

  testWidgets('shows neither when unset', (tester) async {
    await tester.pumpWidget(wrap(slot()));

    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.byType(SlotWhenView), findsNothing);
    expect(find.textContaining('Suggested'), findsNothing);
  });

  testWidgets('shows no date for a slot with a start but no end', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(slot(start: wallClock(2030, 7, 3, 18))));

    expect(find.byType(SlotWhenView), findsNothing);
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

  group('slot time range', () {
    testWidgets('shows the time range under the date for a timed slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          slot(
            start: wallClock(2030, 7, 3, 18),
            end: wallClock(2030, 7, 3, 19, 30),
          ),
        ),
      );

      expect(find.text('Wednesday, July 3'), findsOneWidget);
      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });

    testWidgets('shows a multi-day timed range with the zone label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          slot(
            start: wallClock(2030, 7, 1, 18),
            end: wallClock(2030, 7, 3, 12),
          ),
        ),
      );

      expect(find.text('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'), findsOneWidget);
    });

    testWidgets('shows a multi-day all-day range', (tester) async {
      await tester.pumpWidget(
        wrap(
          slot(
            start: wallClock(2030, 7, 1),
            end: wallClock(2030, 7, 3, 23, 59),
          ),
        ),
      );

      expect(find.text('July 1 – July 3'), findsOneWidget);
    });

    testWidgets('shows the time in the slot\'s own zone', (tester) async {
      await tester.pumpWidget(
        wrap(
          slot(
            timezone: EventTimezone.india,
            start: wallClock(2030, 7, 3, 18, 0, EventTimezone.india),
            end: wallClock(2030, 7, 3, 19, 30, EventTimezone.india),
          ),
        ),
      );

      expect(find.text('6:00 PM – 7:30 PM IST'), findsOneWidget);
    });

    testWidgets('wraps a long multi-day range at 360px without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          slot(
            start: wallClock(2030, 12, 28, 18),
            end: wallClock(2031, 1, 3, 12),
            suggestedAmount: 50,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final range = find.text(
        'Dec 28, 2030, 6:00 PM – Jan 3, 2031, 12:00 PM PT',
      );
      expect(range, findsOneWidget);
      // Wrapped onto several lines and kept inside the screen.
      expect(tester.getSize(range).height, greaterThan(20));
      expect(tester.getRect(range).right, lessThanOrEqualTo(360));
      // The amount wraps onto its own line beside the long range.
      expect(find.text('Suggested: 50.0'), findsOneWidget);
      expect(
        tester.getRect(find.text('Suggested: 50.0')).right,
        lessThanOrEqualTo(360),
      );
    });

    testWidgets('shows the time range in English under a Marathi locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          slot(
            start: wallClock(2030, 7, 3, 18),
            end: wallClock(2030, 7, 3, 19, 30),
          ),
          locale: const Locale('mr'),
        ),
      );

      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });
  });
}
