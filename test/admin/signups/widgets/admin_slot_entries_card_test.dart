import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/admin_slot_entries_card.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

import '../../../helpers/slot_fixtures.dart';

void main() {
  SignupSlot slot({
    String labelMr = 'आठवडा १',
    DateTime? start,
    DateTime? end,
    String timezone = EventTimezone.pacific,
  }) => SignupSlot(
    id: 'slot_1',
    labelEn: 'Week 1 - Cooking',
    labelMr: labelMr,
    startAt: start,
    endAt: end,
    timezone: timezone,
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
    await tester.pumpWidget(
      wrap(allDaySlot(2026, 3, 15, labelEn: 'Week 1 - Cooking'), [entry()]),
    );

    expect(find.text('Week 1 - Cooking'), findsOneWidget);
    expect(find.text('Sunday, March 15'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('omits the date when the slot has none', (tester) async {
    await tester.pumpWidget(wrap(slot(), [entry()]));

    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.byType(SlotWhenView), findsNothing);
  });

  testWidgets('omits the date when the slot has a start but no end', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(slot(start: wallClock(2030, 7, 3, 18)), [entry()]),
    );

    expect(find.byType(SlotWhenView), findsNothing);
  });

  testWidgets('lists every entry with its contact details', (tester) async {
    await tester.pumpWidget(
      wrap(slot(), [entry(), entry(name: 'Joe Bloggs', phone: null)]),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Joe Bloggs'), findsOneWidget);
    expect(find.text('+11234567890'), findsOneWidget);
    expect(find.text('jane@example.com'), findsNWidgets(2));
    expect(find.text('Note: Bringing sweet dish'), findsNWidgets(2));
    expect(find.text('Pledge Amount: 50'), findsNWidgets(2));
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
          [entry()],
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
          [entry()],
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
          [entry()],
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
          [entry()],
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
          ),
          [entry()],
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
          [entry()],
        ),
      );

      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });
  });
}
