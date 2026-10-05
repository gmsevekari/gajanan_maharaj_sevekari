import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/widgets/slot_schedule_field.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_format.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';

void main() {
  const pacific = EventTimezone.pacific;
  const india = EventTimezone.india;

  late GlobalKey<FormState> formKey;
  late List<SlotScheduleInput> changes;

  setUp(() {
    formKey = GlobalKey<FormState>();
    changes = [];
  });

  ClockTime at(int hour, [int minute = 0]) => (hour: hour, minute: minute);

  // A date three years ahead, so the date picker opens on a known month
  // without drifting out of its selectable range as time passes.
  final year = DateTime.now().year + 3;
  final may10 = DateTime(year, 5, 10);

  Widget harness({
    SlotScheduleInput initial = const SlotScheduleInput(),
    int index = 0,
    double width = 400,
    Locale? locale,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: SlotScheduleField(
                  index: index,
                  initialValue: initial,
                  dateRequiredMessage: 'Please select a date',
                  endNotAfterStartMessage: 'End must be after the start',
                  onChanged: changes.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder key(String name, [int index = 0]) => find.byKey(Key('$name$index'));

  Finder buttonText(String keyName, String text, [int index = 0]) =>
      find.descendant(of: key(keyName, index), matching: find.text(text));

  Future<bool> validate(WidgetTester tester) async {
    final valid = formKey.currentState!.validate();
    await tester.pumpAndSettle();
    return valid;
  }

  /// Runs [body] with semantics on, always releasing the handle - even if an
  /// expectation fails - so one failing test can't wedge the rest.
  Future<void> withSemantics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await body();
    } finally {
      handle.dispose();
    }
  }

  Future<void> confirmPicker(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('shows Starts, Ends and Timezone with empty inputs', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Ends'), findsOneWidget);
      expect(find.text('Timezone'), findsWidgets);
      expect(buttonText('slotStartDate_', 'Select Date'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'Select Date'), findsOneWidget);
    });

    testWidgets('empty times show the default as a hint, with no clear '
        'button', (tester) async {
      await tester.pumpWidget(harness());

      expect(buttonText('slotStartTime_', '12:00 AM'), findsOneWidget);
      expect(buttonText('slotEndTime_', '11:59 PM'), findsOneWidget);
      expect(key('slotClearStartTime_'), findsNothing);
      expect(key('slotClearEndTime_'), findsNothing);
    });

    testWidgets('shows the dates and times it was given', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: DateTime(2026, 3, 15),
            startTime: at(18),
            endDate: DateTime(2026, 3, 16),
            endTime: at(19, 30),
          ),
        ),
      );

      expect(buttonText('slotStartDate_', 'Mar 15, 2026'), findsOneWidget);
      expect(buttonText('slotStartTime_', '6:00 PM'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'Mar 16, 2026'), findsOneWidget);
      expect(buttonText('slotEndTime_', '7:30 PM'), findsOneWidget);
      expect(key('slotClearStartTime_'), findsOneWidget);
      expect(key('slotClearEndTime_'), findsOneWidget);
    });

    testWidgets('keys carry the row index', (tester) async {
      await tester.pumpWidget(harness(index: 3));

      expect(key('slotStartDate_', 3), findsOneWidget);
      expect(key('slotEndTime_', 3), findsOneWidget);
      expect(key('slotTimezone_', 3), findsOneWidget);
    });

    testWidgets('fits a 320 px wide screen with everything filled in', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          width: 264, // a 320 px phone minus the screen and card padding
          initial: SlotScheduleInput(
            startDate: DateTime(2026, 12, 28),
            startTime: at(23, 59),
            endDate: DateTime(2026, 12, 31),
            endTime: at(23, 59),
            timezone: india,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('start date', () {
    testWidgets('is required', (tester) async {
      await tester.pumpWidget(harness());

      expect(await validate(tester), isFalse);
      expect(find.text('Please select a date'), findsOneWidget);
    });

    testWidgets('picking it fills the start button and the end date', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester); // the picker opens on today
      final today = formatSlotInputDate(DateTime.now());

      expect(buttonText('slotStartDate_', today), findsOneWidget);
      expect(buttonText('slotEndDate_', today), findsOneWidget);
      expect(changes.last.startDate, isNotNull);
      expect(changes.last.endDate, changes.last.startDate);
    });

    testWidgets('the error clears once a date is picked', (tester) async {
      await tester.pumpWidget(harness());
      await validate(tester);
      expect(find.text('Please select a date'), findsOneWidget);

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester);

      expect(find.text('Please select a date'), findsNothing);
      expect(await validate(tester), isTrue);
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(buttonText('slotStartDate_', 'Select Date'), findsOneWidget);
      expect(changes, isEmpty);
    });
  });

  group('end date follows the start date until it is changed', () {
    final both = SlotScheduleInput(startDate: may10, endDate: may10);

    testWidgets('moving the start moves an end that was the same day', (
      tester,
    ) async {
      await tester.pumpWidget(harness(initial: both));

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await confirmPicker(tester);

      expect(buttonText('slotStartDate_', 'May 12, $year'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 12, $year'), findsOneWidget);
    });

    testWidgets('an end chosen later stops following the start', (
      tester,
    ) async {
      await tester.pumpWidget(harness(initial: both));

      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await confirmPicker(tester);
      expect(buttonText('slotEndDate_', 'May 15, $year'), findsOneWidget);

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('13'));
      await confirmPicker(tester);

      expect(buttonText('slotStartDate_', 'May 13, $year'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 15, $year'), findsOneWidget);
    });

    testWidgets('an end date left empty is filled in from the start', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(initial: SlotScheduleInput(startDate: may10)),
      );

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await confirmPicker(tester);

      expect(buttonText('slotEndDate_', 'May 12, $year'), findsOneWidget);
    });

    testWidgets('the end picker will not go before the start date', (
      tester,
    ) async {
      await tester.pumpWidget(harness(initial: both));

      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8')); // before May 10: not selectable
      await confirmPicker(tester);

      expect(buttonText('slotEndDate_', 'May 10, $year'), findsOneWidget);
    });
  });

  group('times', () {
    testWidgets('picking a start time shows it and offers to clear it', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      await tester.tap(key('slotStartTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester); // opens on 9:00 AM

      expect(buttonText('slotStartTime_', '9:00 AM'), findsOneWidget);
      expect(key('slotClearStartTime_'), findsOneWidget);
      expect(changes.last.startTime, at(9));
    });

    testWidgets('the end time picker opens an hour after the start time', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(initial: SlotScheduleInput(startTime: at(18))),
      );

      await tester.tap(key('slotEndTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester);

      expect(buttonText('slotEndTime_', '7:00 PM'), findsOneWidget);
      expect(changes.last.endTime, at(19));
    });

    testWidgets('with no start time the end time picker opens on 10:00 AM', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      await tester.tap(key('slotEndTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester);

      expect(buttonText('slotEndTime_', '10:00 AM'), findsOneWidget);
    });

    testWidgets('the clear buttons empty each time again', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            startTime: at(18),
            endTime: at(19, 30),
          ),
        ),
      );

      await tester.tap(key('slotClearStartTime_'));
      await tester.pumpAndSettle();
      expect(buttonText('slotStartTime_', '12:00 AM'), findsOneWidget);
      expect(changes.last.startTime, isNull);
      expect(changes.last.endTime, at(19, 30)); // untouched

      await tester.tap(key('slotClearEndTime_'));
      await tester.pumpAndSettle();
      expect(buttonText('slotEndTime_', '11:59 PM'), findsOneWidget);
      expect(changes.last.endTime, isNull);
      expect(key('slotClearStartTime_'), findsNothing);
      expect(key('slotClearEndTime_'), findsNothing);
    });

    testWidgets('cancelling a time picker changes nothing', (tester) async {
      await tester.pumpWidget(harness());

      await tester.tap(key('slotStartTime_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(buttonText('slotStartTime_', '12:00 AM'), findsOneWidget);
      expect(changes, isEmpty);
    });
  });

  group('end must be after the start', () {
    SlotScheduleInput backwards() => SlotScheduleInput(
      startDate: may10,
      startTime: at(18),
      endDate: may10,
      endTime: at(9),
    );

    testWidgets('an end before the start is reported', (tester) async {
      await tester.pumpWidget(harness(initial: backwards()));

      expect(await validate(tester), isFalse);
      expect(find.text('End must be after the start'), findsOneWidget);
    });

    testWidgets('an end date before the start date is reported', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: DateTime(year, 5, 12),
            endDate: DateTime(year, 5, 10),
          ),
        ),
      );

      expect(await validate(tester), isFalse);
      expect(find.text('End must be after the start'), findsOneWidget);
    });

    testWidgets('an end equal to the start is reported', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            startTime: at(18),
            endTime: at(18),
          ),
        ),
      );

      expect(await validate(tester), isFalse);
      expect(find.text('End must be after the start'), findsOneWidget);
    });

    testWidgets('the error goes as soon as the input is fixed', (tester) async {
      await tester.pumpWidget(harness(initial: backwards()));
      await validate(tester);
      expect(find.text('End must be after the start'), findsOneWidget);

      await tester.tap(key('slotClearEndTime_')); // end becomes 23:59
      await tester.pumpAndSettle();

      expect(find.text('End must be after the start'), findsNothing);
      expect(await validate(tester), isTrue);
    });

    testWidgets('the error appears when a pick makes the range invalid', (
      tester,
    ) async {
      // An 8:00 AM end with no start time: valid (the start is 12:00 AM).
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            endDate: may10,
            endTime: at(8),
          ),
        ),
      );
      await validate(tester);
      expect(find.text('End must be after the start'), findsNothing);

      // Picking a 9:00 AM start puts it after the end.
      await tester.tap(key('slotStartTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester);

      expect(find.text('End must be after the start'), findsOneWidget);
    });
  });

  group('through the UI, each case resolves to the expected range', () {
    SlotScheduleResolved resolved() {
      final result = resolveSlotSchedule(changes.last);
      expect(result, isA<SlotScheduleResolved>());
      return result as SlotScheduleResolved;
    }

    testWidgets('start date only: the whole day', (tester) async {
      await tester.pumpWidget(
        harness(initial: SlotScheduleInput(startDate: may10)),
      );
      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('11'));
      await confirmPicker(tester);

      final r = resolved();
      expect(
        r.endAt.difference(r.startAt),
        const Duration(hours: 23, minutes: 59),
      );
    });

    testWidgets('start date and an end time: midnight until then', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: may10, endDate: may10),
        ),
      );
      await tester.tap(key('slotEndTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester); // 10:00 AM

      expect(
        resolved().endAt.difference(resolved().startAt),
        const Duration(hours: 10),
      );
    });

    testWidgets('start time and end date: a multi-day range', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: may10, endDate: may10),
        ),
      );
      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await confirmPicker(tester);
      await tester.tap(key('slotStartTime_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester); // 9:00 AM

      // May 10 09:00 to May 12 23:59 Pacific.
      expect(
        resolved().endAt.difference(resolved().startAt),
        const Duration(days: 2, hours: 14, minutes: 59),
      );
    });
  });

  group('timezone', () {
    testWidgets('defaults to what it was given and lists both zones', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(initial: const SlotScheduleInput(timezone: india)),
      );

      expect(find.text('India (IST)'), findsOneWidget);

      await tester.tap(key('slotTimezone_'));
      await tester.pumpAndSettle();
      expect(find.text('Seattle (Pacific Time)'), findsOneWidget);
      expect(find.text('India (IST)'), findsWidgets);
    });

    testWidgets('choosing a zone reports it and keeps the rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            startTime: at(18),
            timezone: pacific,
          ),
        ),
      );

      await tester.tap(key('slotTimezone_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('India (IST)').last);
      await tester.pumpAndSettle();

      expect(changes.last.timezone, india);
      expect(changes.last.startTime, at(18));
      expect(changes.last.startDate, may10);
      expect(find.text('India (IST)'), findsOneWidget);
    });

    testWidgets('shows an unsupported zone as Seattle, like the rest of the '
        'app treats it', (tester) async {
      await tester.pumpWidget(
        harness(initial: const SlotScheduleInput(timezone: 'Mars/Olympus')),
      );

      expect(find.text('Seattle (Pacific Time)'), findsOneWidget);
    });
  });

  group('the pickers stay in English', () {
    testWidgets('even when the app language is Marathi', (tester) async {
      await tester.pumpWidget(harness(locale: const Locale('mr')));

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      // Material's own Marathi wording would be 'ठीक आहे', not 'OK'.
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(key('slotStartTime_'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('the end date and the start date', () {
    testWidgets('an end the admin chose different stays put when the start '
        'later lands on the same day', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: may10, endDate: may10),
        ),
      );
      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('17'));
      await confirmPicker(tester);

      // The start catches up to the chosen end, then moves past it.
      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('17'));
      await confirmPicker(tester);
      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await confirmPicker(tester);

      expect(buttonText('slotStartDate_', 'May 20, $year'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 17, $year'), findsOneWidget);
    });

    testWidgets('an end deliberately set equal to the start no longer moves '
        'with it', (tester) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: may10, endDate: may10),
        ),
      );
      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10')); // the same day, on purpose
      await confirmPicker(tester);

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await confirmPicker(tester);

      expect(buttonText('slotStartDate_', 'May 9, $year'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 10, $year'), findsOneWidget);
    });

    testWidgets('an end picked before any start is kept when the start is '
        'picked later', (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester); // opens on today
      final end = changes.last.endDate!;

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await confirmPicker(tester);

      expect(changes.last.endDate, end);
      expect(changes.last.startDate, isNotNull);
    });

    testWidgets('an end left alone keeps following every start change', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: may10, endDate: may10),
        ),
      );
      for (final day in ['12', '14']) {
        await tester.tap(key('slotStartDate_'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(day));
        await confirmPicker(tester);
      }

      expect(buttonText('slotEndDate_', 'May 14, $year'), findsOneWidget);
    });

    testWidgets('a differing end the form starts with counts as chosen', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            endDate: DateTime(year, 5, 15),
          ),
        ),
      );

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await confirmPicker(tester);

      expect(buttonText('slotEndDate_', 'May 15, $year'), findsOneWidget);
    });
  });

  group('out-of-range input', () {
    testWidgets('an end picker still opens for a start date beyond what can '
        'be picked', (tester) async {
      final far = DateTime.now().add(const Duration(days: 365 * 6));
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: far, endDate: far),
        ),
      );

      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('a start picker opens for a start date older than the '
        'picker allows', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 90));
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(startDate: old, endDate: old),
        ),
      );

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('a picker that outlives the field', () {
    testWidgets('picking after the field has gone is ignored without '
        'errors', (tester) async {
      final show = ValueNotifier<bool>(true);
      addTearDown(show.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (context, visible, _) => visible
                  ? SingleChildScrollView(
                      child: Form(
                        child: SlotScheduleField(
                          index: 0,
                          initialValue: const SlotScheduleInput(),
                          dateRequiredMessage: 'Please select a date',
                          endNotAfterStartMessage:
                              'End must be after the start',
                          onChanged: changes.add,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();

      show.value = false; // the field leaves while the picker stays open
      await tester.pump();
      await confirmPicker(tester);

      expect(tester.takeException(), isNull);
      expect(changes, isEmpty);
    });
  });

  group('accessibility', () {
    testWidgets('each button announces what it is, not just its value', (
      tester,
    ) async {
      await withSemantics(tester, () async {
        await tester.pumpWidget(
          harness(
            initial: SlotScheduleInput(
              startDate: DateTime(2026, 3, 15),
              startTime: at(18),
              endDate: DateTime(2026, 3, 16),
            ),
          ),
        );

        void expectButton(String keyName, String label, String value) {
          final node = tester.getSemantics(key(keyName));
          expect(node.label, label, reason: keyName);
          expect(node.value, value, reason: keyName);
          expect(
            node.getSemanticsData().flagsCollection.isButton,
            isTrue,
            reason: keyName,
          );
        }

        expectButton('slotStartDate_', 'Start Date', 'Mar 15, 2026');
        expectButton('slotStartTime_', 'Start Time', '6:00 PM');
        expectButton('slotEndDate_', 'End Date', 'Mar 16, 2026');
        // An unset time says so, instead of sounding like a chosen one.
        final endTime = tester.getSemantics(key('slotEndTime_'));
        expect(endTime.label, 'End Time');
        expect(endTime.value, '11:59 PM');
        expect(endTime.hint, 'Time (optional)');
      });
    });

    testWidgets('the two clear buttons say which time they clear', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          initial: SlotScheduleInput(
            startDate: may10,
            startTime: at(18),
            endTime: at(19),
          ),
        ),
      );

      expect(find.byTooltip('Clear Time: Start Time'), findsOneWidget);
      expect(find.byTooltip('Clear Time: End Time'), findsOneWidget);
    });

    testWidgets('a validation error is a live region', (tester) async {
      await withSemantics(tester, () async {
        await tester.pumpWidget(harness());
        await validate(tester);

        final error = tester.getSemantics(find.text('Please select a date'));
        expect(error.label, 'Please select a date');
        expect(error.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      });
    });
  });

  group('layout', () {
    testWidgets('the error sits with the date and time inputs, above the '
        'timezone', (tester) async {
      await tester.pumpWidget(harness());
      await validate(tester);

      expect(
        tester.getTopLeft(find.text('Please select a date')).dy,
        lessThan(tester.getTopLeft(key('slotTimezone_')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Please select a date')).dy,
        greaterThan(tester.getBottomLeft(key('slotEndDate_')).dy),
      );
    });

    testWidgets('large text shrinks the date and time text to fit instead of '
        'cutting it off', (tester) async {
      await tester.pumpWidget(
        harness(
          width: 264,
          textScale: 2.0,
          initial: SlotScheduleInput(
            startDate: DateTime(2026, 12, 28),
            startTime: at(23, 59),
            endDate: DateTime(2026, 12, 31),
            endTime: at(23, 59),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final name in ['slotStartTime_', 'slotEndTime_']) {
        final fitted = find.descendant(
          of: key(name),
          matching: find.byType(FittedBox),
        );
        expect(fitted, findsOneWidget, reason: name);
        expect(tester.widget<FittedBox>(fitted).fit, BoxFit.scaleDown);
        // At double size the text is wider than its slot, so it is the
        // FittedBox that makes it fit rather than the text being cut off.
        final slot = tester.getSize(fitted).width;
        final natural = tester
            .getSize(find.descendant(of: fitted, matching: find.byType(Text)))
            .width;
        expect(natural, greaterThan(slot), reason: name);
      }
    });
  });
}
