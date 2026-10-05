import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_slot_tile.dart';

import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

import '../../../helpers/slot_fixtures.dart';

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SignupSlot buildSlot({
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    DateTime? start,
    DateTime? end,
    int capacity = 3,
    int claimedCount = 0,
  }) {
    return SignupSlot(
      id: 'slot_1',
      labelEn: labelEn,
      labelMr: labelMr,
      startAt: start,
      endAt: end,
      capacity: capacity,
      claimedCount: claimedCount,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('renders the label and fill count', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(claimedCount: 1), onTap: () {})),
    );

    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('1 of 3 claimed'), findsOneWidget);
  });

  testWidgets('shows the slot date when set', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: allDaySlot(2026, 3, 15), onTap: () {})),
    );

    expect(find.text('Sunday, March 15'), findsOneWidget);
  });

  testWidgets('shows nothing for the date when unset', (tester) async {
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(), onTap: () {})),
    );

    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets('invokes onTap when the Sign Up button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(SignupSlotTile(slot: buildSlot(), onTap: () => tapped = true)),
    );

    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows a Full badge and no Sign Up button when full', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(capacity: 1, claimedCount: 1),
          onTap: null,
        ),
      ),
    );

    expect(find.text('Full'), findsOneWidget);
    expect(find.byKey(const Key('signUpButton')), findsNothing);
  });

  testWidgets('falls back to the Marathi label when English is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SignupSlotTile(
          slot: buildSlot(labelEn: '', labelMr: 'आठवडा १'),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('आठवडा १'), findsOneWidget);
  });

  testWidgets(
    'always formats the date in English, even under a Marathi locale',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          SignupSlotTile(
            slot: allDaySlot(2026, 3, 15, claimedCount: 1),
            onTap: () {},
          ),
          locale: const Locale('mr'),
        ),
      );

      expect(find.text('Sunday, March 15'), findsOneWidget);
    },
  );

  group('slot time range', () {
    Future<void> show(
      WidgetTester tester,
      SignupSlot slot, {
      Locale locale = const Locale('en'),
    }) => tester.pumpWidget(
      wrap(
        SignupSlotTile(slot: slot, onTap: () {}),
        locale: locale,
      ),
    );

    testWidgets('shows the time range under the date for a timed slot', (
      tester,
    ) async {
      await show(
        tester,
        buildSlot(
          start: wallClock(2030, 7, 3, 18),
          end: wallClock(2030, 7, 3, 19, 30),
        ),
      );

      expect(find.text('Wednesday, July 3'), findsOneWidget);
      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });

    testWidgets('shows a multi-day range', (tester) async {
      await show(
        tester,
        buildSlot(
          start: wallClock(2030, 7, 1, 18),
          end: wallClock(2030, 7, 3, 12),
        ),
      );

      expect(find.text('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'), findsOneWidget);
    });

    testWidgets('shows the time in the slot\'s own zone, not the device\'s', (
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

    testWidgets('shows no date row for a slot with no schedule', (
      tester,
    ) async {
      await show(tester, buildSlot());

      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('wraps a long multi-day range at 360px without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await show(
        tester,
        buildSlot(
          start: wallClock(2030, 12, 28, 18),
          end: wallClock(2031, 1, 3, 12),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Dec 28, 2030, 6:00 PM – Jan 3, 2031, 12:00 PM PT'),
        findsOneWidget,
      );
    });

    testWidgets('shows the time range in English under a Marathi locale', (
      tester,
    ) async {
      await show(
        tester,
        buildSlot(
          start: wallClock(2030, 7, 3, 18),
          end: wallClock(2030, 7, 3, 19, 30),
        ),
        locale: const Locale('mr'),
      );

      expect(find.text('6:00 PM – 7:30 PM PT'), findsOneWidget);
    });
  });
}
