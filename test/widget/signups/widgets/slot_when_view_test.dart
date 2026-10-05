import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/slot_when_view.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

import '../../../helpers/slot_fixtures.dart';

void main() {
  Widget wrap(
    Widget child, {
    Locale locale = const Locale('en'),
    double? width,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  Future<void> show(
    WidgetTester tester,
    SignupSlot slot, {
    bool showIcon = true,
    Locale locale = const Locale('en'),
    double? width,
  }) => tester.pumpWidget(
    wrap(
      SlotWhenView(slot: slot, showIcon: showIcon),
      locale: locale,
      width: width,
    ),
  );

  testWidgets('shows the date alone for an all-day slot on one day', (
    tester,
  ) async {
    await show(tester, allDaySlot(2030, 7, 3));

    expect(find.text('Wednesday, July 3'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows the time range under the date for a timed slot', (
    tester,
  ) async {
    await show(
      tester,
      scheduledSlot(
        start: wallClock(2030, 7, 3, 18),
        end: wallClock(2030, 7, 3, 19, 30),
      ),
    );

    expect(find.text('Wednesday, July 3'), findsOneWidget);
    expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('6:00 PM – 7:30 PM PT')).dy,
      greaterThan(tester.getBottomLeft(find.text('Wednesday, July 3')).dy - 1),
    );
  });

  testWidgets('shows a multi-day all-day range on one line', (tester) async {
    await show(
      tester,
      scheduledSlot(
        start: wallClock(2030, 7, 1),
        end: wallClock(2030, 7, 3, 23, 59),
      ),
    );

    expect(find.text('July 1 – July 3'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('shows a multi-day timed range with the zone label', (
    tester,
  ) async {
    await show(
      tester,
      scheduledSlot(
        start: wallClock(2030, 7, 1, 18),
        end: wallClock(2030, 7, 3, 12),
      ),
    );

    expect(find.text('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'), findsOneWidget);
  });

  testWidgets('shows the time in the slot\'s own zone, labelled IST', (
    tester,
  ) async {
    await show(
      tester,
      scheduledSlot(
        timezone: EventTimezone.india,
        start: wallClock(2030, 7, 3, 18, 0, EventTimezone.india),
        end: wallClock(2030, 7, 3, 19, 30, EventTimezone.india),
      ),
    );

    expect(find.text('Wednesday, July 3'), findsOneWidget);
    expect(find.text('6:00 PM – 7:30 PM IST'), findsOneWidget);
  });

  testWidgets('shows nothing for a slot with no schedule', (tester) async {
    await show(tester, scheduledSlot());

    expect(find.byType(Text), findsNothing);
    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets('shows nothing for a slot with a start but no end', (
    tester,
  ) async {
    await show(tester, scheduledSlot(start: wallClock(2030, 7, 3, 18)));

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows a calendar icon unless showIcon is false', (tester) async {
    await show(tester, allDaySlot(2030, 7, 3));
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);

    await show(tester, allDaySlot(2030, 7, 3), showIcon: false);
    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.text('Wednesday, July 3'), findsOneWidget);
  });

  testWidgets(
    'wraps a long multi-day timed range in a narrow width without overflow',
    (tester) async {
      await show(
        tester,
        scheduledSlot(
          start: wallClock(2030, 12, 28, 18),
          end: wallClock(2031, 1, 3, 12),
        ),
        width: 200,
      );

      expect(tester.takeException(), isNull);
      final text = find.text(
        'Dec 28, 2030, 6:00 PM – Jan 3, 2031, 12:00 PM PT',
      );
      expect(text, findsOneWidget);
      expect(tester.getSize(text).height, greaterThan(20)); // wrapped
      expect(
        tester.getSize(find.byType(SlotWhenView)).width,
        lessThanOrEqualTo(200),
      );
    },
  );

  testWidgets('stays English under a Marathi locale', (tester) async {
    await show(
      tester,
      scheduledSlot(
        start: wallClock(2030, 7, 3, 18),
        end: wallClock(2030, 7, 3, 19, 30),
      ),
      locale: const Locale('mr'),
    );

    expect(find.text('Wednesday, July 3'), findsOneWidget);
    expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
  });
}
