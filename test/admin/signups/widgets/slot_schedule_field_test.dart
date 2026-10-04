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

  // A fixed date far enough ahead that the date picker opens on a known month.
  final may10 = DateTime(2030, 5, 10);

  Widget harness({
    SlotScheduleInput initial = const SlotScheduleInput(),
    int index = 0,
    double width = 400,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
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

      expect(buttonText('slotStartDate_', 'May 12, 2030'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 12, 2030'), findsOneWidget);
    });

    testWidgets('an end chosen later stops following the start', (
      tester,
    ) async {
      await tester.pumpWidget(harness(initial: both));

      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await confirmPicker(tester);
      expect(buttonText('slotEndDate_', 'May 15, 2030'), findsOneWidget);

      await tester.tap(key('slotStartDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('13'));
      await confirmPicker(tester);

      expect(buttonText('slotStartDate_', 'May 13, 2030'), findsOneWidget);
      expect(buttonText('slotEndDate_', 'May 15, 2030'), findsOneWidget);
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

      expect(buttonText('slotEndDate_', 'May 12, 2030'), findsOneWidget);
    });

    testWidgets('the end picker will not go before the start date', (
      tester,
    ) async {
      await tester.pumpWidget(harness(initial: both));

      await tester.tap(key('slotEndDate_'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8')); // before May 10: not selectable
      await confirmPicker(tester);

      expect(buttonText('slotEndDate_', 'May 10, 2030'), findsOneWidget);
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
            startDate: DateTime(2030, 5, 12),
            endDate: DateTime(2030, 5, 10),
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
}
