import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_schedule.dart';

void main() {
  const pacific = EventTimezone.pacific;
  const india = EventTimezone.india;

  // The date picker returns a local DateTime; only its year/month/day are
  // used, so these deliberately carry a time of day.
  DateTime day(int y, int m, int d) => DateTime(y, m, d, 15, 45);

  DateTime utc(int y, int m, int d, [int h = 0, int min = 0]) =>
      DateTime.utc(y, m, d, h, min);

  ClockTime at(int hour, [int minute = 0]) => (hour: hour, minute: minute);

  SlotScheduleResolved resolved(SlotScheduleInput input) {
    final result = resolveSlotSchedule(input);
    expect(result, isA<SlotScheduleResolved>(), reason: '$result');
    return result as SlotScheduleResolved;
  }

  SlotScheduleError invalid(SlotScheduleInput input) {
    final result = resolveSlotSchedule(input);
    expect(result, isA<SlotScheduleInvalid>(), reason: '$result');
    return (result as SlotScheduleInvalid).error;
  }

  group('defaults', () {
    test('are 00:00 for the start and 23:59 for the end', () {
      expect(slotDefaultStartTime, (hour: 0, minute: 0));
      expect(slotDefaultEndTime, (hour: 23, minute: 59));
    });

    test('the input defaults to the Pacific zone', () {
      expect(const SlotScheduleInput().timezone, pacific);
    });
  });

  group('optional fields fall back to their defaults (Seattle, July)', () {
    test('start date only: the whole day, 00:00 to 23:59', () {
      final r = resolved(
        SlotScheduleInput(startDate: day(2026, 7, 1), timezone: pacific),
      );
      expect(r.startAt, utc(2026, 7, 1, 7));
      expect(r.endAt, utc(2026, 7, 2, 6, 59));
    });

    test('start date + start time: from then until 23:59 the same day', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 2, 1));
      expect(r.endAt, utc(2026, 7, 2, 6, 59));
    });

    test('end time only: 00:00 until then on the start date', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          endTime: at(14),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 1, 7));
      expect(r.endAt, utc(2026, 7, 1, 21));
    });

    test('start date + end date: whole days, first 00:00 to last 23:59', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          endDate: day(2026, 7, 3),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 1, 7));
      expect(r.endAt, utc(2026, 7, 4, 6, 59));
    });
  });

  group('explicit ranges (Seattle, July)', () {
    test('one day with both times', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          endDate: day(2026, 7, 1),
          endTime: at(19, 30),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 2, 1));
      expect(r.endAt, utc(2026, 7, 2, 2, 30));
    });

    test('an overnight range crossing midnight', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(22),
          endDate: day(2026, 7, 2),
          endTime: at(2),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 2, 5));
      expect(r.endAt, utc(2026, 7, 2, 9));
    });

    test('a multi-day range with times', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          endDate: day(2026, 7, 3),
          endTime: at(12),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 7, 2, 1));
      expect(r.endAt, utc(2026, 7, 3, 19));
    });

    test('an end one minute after the start is valid', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          endTime: at(18, 1),
          timezone: pacific,
        ),
      );
      expect(r.endAt.difference(r.startAt), const Duration(minutes: 1));
    });

    test('ignores the time of day carried by the picked dates', () {
      final a = resolved(
        SlotScheduleInput(startDate: DateTime(2026, 7, 1), timezone: pacific),
      );
      final b = resolved(
        SlotScheduleInput(
          startDate: DateTime(2026, 7, 1, 23, 59),
          timezone: pacific,
        ),
      );
      expect(a.startAt, b.startAt);
      expect(a.endAt, b.endAt);
    });
  });

  group('India', () {
    test('start date only: the whole day in IST', () {
      final r = resolved(
        SlotScheduleInput(startDate: day(2026, 3, 15), timezone: india),
      );
      expect(r.startAt, utc(2026, 3, 14, 18, 30));
      expect(r.endAt, utc(2026, 3, 15, 18, 29));
    });

    test('a timed range in IST', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 3, 15),
          startTime: at(6),
          endTime: at(8, 30),
          timezone: india,
        ),
      );
      expect(r.startAt, utc(2026, 3, 15, 0, 30));
      expect(r.endAt, utc(2026, 3, 15, 3));
    });

    test('the zone changes the instants for the same wall-clock input', () {
      SlotScheduleResolved at18(String timezone) => resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          timezone: timezone,
        ),
      );
      // 18:00 in Seattle (UTC-7) is 12.5 hours after 18:00 in India (UTC+5:30).
      expect(
        at18(pacific).startAt.difference(at18(india).startAt),
        const Duration(hours: 12, minutes: 30),
      );
    });

    test('rejects an end that is not after the start', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 3, 15),
            startTime: at(9),
            endTime: at(8),
            timezone: india,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 3, 16),
            endDate: day(2026, 3, 15),
            timezone: india,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });
  });

  group('daylight-saving changeover days (Seattle)', () {
    test('the day clocks go forward is 23 hours long', () {
      final r = resolved(
        SlotScheduleInput(startDate: day(2026, 3, 8), timezone: pacific),
      );
      expect(r.startAt, utc(2026, 3, 8, 8)); // 00:00 PST
      expect(r.endAt, utc(2026, 3, 9, 6, 59)); // 23:59 PDT
    });

    test('the day clocks go back is 25 hours long', () {
      final r = resolved(
        SlotScheduleInput(startDate: day(2026, 11, 1), timezone: pacific),
      );
      expect(r.startAt, utc(2026, 11, 1, 7)); // 00:00 PDT
      expect(r.endAt, utc(2026, 11, 2, 7, 59)); // 23:59 PST
    });

    test('a multi-day range spanning the spring change keeps its wall-clock '
        'times', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 3, 7),
          startTime: at(20),
          endDate: day(2026, 3, 9),
          endTime: at(9),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 3, 8, 4)); // 20:00 PST
      expect(r.endAt, utc(2026, 3, 9, 16)); // 09:00 PDT
    });

    test('a multi-day range spanning the fall change keeps its wall-clock '
        'times', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 10, 31),
          startTime: at(20),
          endDate: day(2026, 11, 2),
          endTime: at(9),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 11, 1, 3)); // 20:00 PDT
      expect(r.endAt, utc(2026, 11, 2, 17)); // 09:00 PST
    });

    test('a range across the skipped hour is valid and stays in order', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 3, 8),
          startTime: at(1, 30),
          endTime: at(2, 15),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 3, 8, 9, 30)); // 01:30 PST
      expect(r.endAt, utc(2026, 3, 8, 10)); // the jump to 03:00 PDT
    });

    test('a range entirely inside the skipped hour has no length', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 3, 8),
            startTime: at(2, 10),
            endTime: at(2, 40),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });

    test('a range across the repeated hour is valid', () {
      final r = resolved(
        SlotScheduleInput(
          startDate: day(2026, 11, 1),
          startTime: at(1, 30),
          endTime: at(3),
          timezone: pacific,
        ),
      );
      expect(r.startAt, utc(2026, 11, 1, 8, 30)); // 01:30 PDT
      expect(r.endAt, utc(2026, 11, 1, 11)); // 03:00 PST
    });
  });

  group('timezone', () {
    test('an unknown zone is treated as Pacific', () {
      final r = resolved(
        SlotScheduleInput(startDate: day(2026, 7, 1), timezone: 'Mars/Olympus'),
      );
      expect(r.startAt, utc(2026, 7, 1, 7));
    });
  });

  group('errors', () {
    test('a missing start date is reported', () {
      expect(
        invalid(const SlotScheduleInput(timezone: pacific)),
        SlotScheduleError.missingStartDate,
      );
    });

    test('a missing start date wins over anything else that is set', () {
      expect(
        invalid(
          SlotScheduleInput(
            startTime: at(18),
            endDate: day(2026, 7, 1),
            endTime: at(9),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.missingStartDate,
      );
    });

    test('an end date before the start date', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 7, 3),
            endDate: day(2026, 7, 1),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });

    test('an end time before the start time on the same day', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 7, 1),
            startTime: at(18),
            endTime: at(9),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });

    test('an end equal to the start', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 7, 1),
            startTime: at(18),
            endTime: at(18),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });

    test('a start time of 23:59 with no end leaves nothing after it', () {
      expect(
        invalid(
          SlotScheduleInput(
            startDate: day(2026, 7, 1),
            startTime: at(23, 59),
            timezone: pacific,
          ),
        ),
        SlotScheduleError.endNotAfterStart,
      );
    });

    test(
      'an end time of 00:00 with no start time equals the default start',
      () {
        expect(
          invalid(
            SlotScheduleInput(
              startDate: day(2026, 7, 1),
              endTime: at(0),
              timezone: pacific,
            ),
          ),
          SlotScheduleError.endNotAfterStart,
        );
      },
    );
  });

  group('input validation', () {
    test('rejects an hour or minute outside a real time of day', () {
      for (final bad in [
        (hour: 24, minute: 0),
        (hour: -1, minute: 0),
        (hour: 10, minute: 60),
        (hour: 10, minute: -1),
      ]) {
        expect(
          () => resolveSlotSchedule(
            SlotScheduleInput(
              startDate: day(2026, 7, 1),
              startTime: bad,
              timezone: pacific,
            ),
          ),
          throwsArgumentError,
          reason: '$bad',
        );
        expect(
          () => resolveSlotSchedule(
            SlotScheduleInput(
              startDate: day(2026, 7, 1),
              endTime: bad,
              timezone: pacific,
            ),
          ),
          throwsArgumentError,
          reason: '$bad',
        );
      }
    });

    test('accepts the first and last minute of the day', () {
      expect(
        resolveSlotSchedule(
          SlotScheduleInput(
            startDate: day(2026, 7, 1),
            startTime: at(0),
            endTime: at(23, 59),
            timezone: pacific,
          ),
        ),
        isA<SlotScheduleResolved>(),
      );
    });
  });

  group('SlotScheduleInput', () {
    final full = SlotScheduleInput(
      startDate: DateTime(2026, 7, 1),
      startTime: at(18),
      endDate: DateTime(2026, 7, 2),
      endTime: at(9),
      timezone: india,
    );

    test('copyWith replaces only the fields given', () {
      final copy = full.copyWith(startTime: at(7), timezone: pacific);
      expect(copy.startTime, at(7));
      expect(copy.timezone, pacific);
      expect(copy.startDate, full.startDate);
      expect(copy.endDate, full.endDate);
      expect(copy.endTime, full.endTime);
    });

    test('copyWith can set a missing field', () {
      final copy = const SlotScheduleInput().copyWith(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 3),
        endTime: at(12),
      );
      expect(copy.startDate, DateTime(2026, 7, 1));
      expect(copy.endDate, DateTime(2026, 7, 3));
      expect(copy.endTime, at(12));
      expect(copy.startTime, isNull);
    });

    test('copyWith clears a field only when asked to', () {
      expect(full.copyWith().startTime, at(18));
      expect(full.copyWith(clearStartTime: true).startTime, isNull);
      expect(full.copyWith(clearEndTime: true).endTime, isNull);
      expect(full.copyWith(clearEndDate: true).endDate, isNull);
      expect(full.copyWith(clearStartDate: true).startDate, isNull);
      // Clearing one field leaves the rest alone.
      final cleared = full.copyWith(clearEndTime: true);
      expect(cleared.startTime, at(18));
      expect(cleared.endDate, full.endDate);
    });

    test('is equal when the same day, times and zone are chosen', () {
      final same = SlotScheduleInput(
        startDate: DateTime(2026, 7, 1),
        startTime: at(18),
        endDate: DateTime(2026, 7, 2),
        endTime: at(9),
        timezone: india,
      );
      expect(full, same);
      expect(full.hashCode, same.hashCode);
    });

    test('compares dates by day, ignoring the time of day a picker adds', () {
      final withClock = full.copyWith(
        startDate: DateTime(2026, 7, 1, 15, 45),
        endDate: DateTime(2026, 7, 2, 3, 10),
      );
      expect(withClock, full);
      expect(withClock.hashCode, full.hashCode);
    });

    test('differs when any field differs', () {
      expect(full == full.copyWith(startDate: DateTime(2026, 7, 5)), isFalse);
      expect(full == full.copyWith(startTime: at(19)), isFalse);
      expect(full == full.copyWith(endDate: DateTime(2026, 7, 5)), isFalse);
      expect(full == full.copyWith(endTime: at(10)), isFalse);
      expect(full == full.copyWith(timezone: pacific), isFalse);
      expect(full == full.copyWith(clearStartTime: true), isFalse);
      expect(full == const SlotScheduleInput(), isFalse);
    });

    test('has a readable toString', () {
      expect(full.toString(), contains('2026-07-01'));
      expect(full.toString(), contains(india));
    });
  });

  group('results', () {
    test('resolved results compare by instants', () {
      final a = SlotScheduleResolved(
        startAt: utc(2026, 7, 1),
        endAt: utc(2026, 7, 2),
      );
      final b = SlotScheduleResolved(
        startAt: utc(2026, 7, 1),
        endAt: utc(2026, 7, 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a ==
            SlotScheduleResolved(
              startAt: utc(2026, 7, 1),
              endAt: utc(2026, 7, 3),
            ),
        isFalse,
      );
      expect(
        a ==
            SlotScheduleResolved(
              startAt: utc(2026, 6, 30),
              endAt: utc(2026, 7, 2),
            ),
        isFalse,
      );
    });

    test('invalid results compare by error', () {
      expect(
        const SlotScheduleInvalid(SlotScheduleError.missingStartDate),
        const SlotScheduleInvalid(SlotScheduleError.missingStartDate),
      );
      expect(
        const SlotScheduleInvalid(SlotScheduleError.missingStartDate) ==
            const SlotScheduleInvalid(SlotScheduleError.endNotAfterStart),
        isFalse,
      );
    });

    test('invalid results hash by error', () {
      expect(
        const SlotScheduleInvalid(SlotScheduleError.endNotAfterStart).hashCode,
        const SlotScheduleInvalid(SlotScheduleError.endNotAfterStart).hashCode,
      );
    });

    test('results have readable descriptions', () {
      expect(
        SlotScheduleResolved(
          startAt: utc(2026, 7, 1),
          endAt: utc(2026, 7, 2),
        ).toString(),
        contains('2026-07-01'),
      );
      expect(
        const SlotScheduleInvalid(
          SlotScheduleError.missingStartDate,
        ).toString(),
        contains('missingStartDate'),
      );
    });

    test('resolving the same input twice gives equal results', () {
      final input = SlotScheduleInput(
        startDate: day(2026, 7, 1),
        timezone: pacific,
      );
      expect(resolveSlotSchedule(input), resolveSlotSchedule(input));
    });
  });

  group('suggestedSlotEndTime', () {
    test('is an hour after the start time', () {
      expect(suggestedSlotEndTime(at(9)), at(10));
      expect(suggestedSlotEndTime(at(0)), at(1));
      expect(suggestedSlotEndTime(at(18, 30)), at(19, 30));
    });

    test('stops at 23:59 rather than rolling into the next day', () {
      expect(suggestedSlotEndTime(at(23, 30)), at(23, 59));
      expect(suggestedSlotEndTime(at(22, 59)), at(23, 59));
      expect(suggestedSlotEndTime(at(23, 59)), at(23, 59));
    });

    test('with no start time assumes the picker\'s own start of 9:00', () {
      expect(slotPickerStartTime, at(9));
      expect(suggestedSlotEndTime(null), at(10));
    });
  });

  group('slotScheduleInputFromInstants', () {
    SlotScheduleInput from(
      DateTime start,
      DateTime end, [
      String timezone = pacific,
    ]) => slotScheduleInputFromInstants(
      startAt: start,
      endAt: end,
      timezone: timezone,
    );

    DateTime wall(
      int y,
      int m,
      int d, [
      int h = 0,
      int min = 0,
      String timezone = pacific,
    ]) => wallClockToUtc(
      year: y,
      month: m,
      day: d,
      hour: h,
      minute: min,
      timezone: timezone,
    );

    test('gives just the date for a full-day slot', () {
      final input = from(wall(2030, 7, 3), wall(2030, 7, 3, 23, 59));

      expect(input.startDate, DateTime(2030, 7, 3));
      expect(input.startTime, isNull);
      expect(input.endDate, isNull);
      expect(input.endTime, isNull);
      expect(input.timezone, pacific);
    });

    test('gives the times for a timed slot on one day', () {
      final input = from(wall(2030, 7, 3, 18), wall(2030, 7, 3, 19, 30));

      expect(input.startDate, DateTime(2030, 7, 3));
      expect(input.startTime, at(18));
      expect(input.endDate, isNull);
      expect(input.endTime, at(19, 30));
    });

    test('gives both dates for a slot that spans days', () {
      final input = from(wall(2030, 7, 1), wall(2030, 7, 3, 23, 59));

      expect(input.startDate, DateTime(2030, 7, 1));
      expect(input.endDate, DateTime(2030, 7, 3));
      expect(input.startTime, isNull);
      expect(input.endTime, isNull);
    });

    test('keeps an end date that is the same day number in another month '
        'or year', () {
      expect(
        from(wall(2030, 7, 3), wall(2030, 8, 3, 23, 59)).endDate,
        DateTime(2030, 8, 3),
      );
      expect(
        from(wall(2030, 7, 3), wall(2031, 7, 3, 23, 59)).endDate,
        DateTime(2031, 7, 3),
      );
    });

    test('gives the end date and time for a slot that crosses midnight', () {
      final input = from(wall(2030, 7, 3, 18), wall(2030, 7, 4, 2));

      expect(input.startDate, DateTime(2030, 7, 3));
      expect(input.startTime, at(18));
      expect(input.endDate, DateTime(2030, 7, 4));
      expect(input.endTime, at(2));
    });

    test('leaves out a time that is only the default', () {
      expect(from(wall(2030, 7, 3), wall(2030, 7, 3, 12)).startTime, isNull);
      expect(
        from(wall(2030, 7, 3, 9), wall(2030, 7, 3, 23, 59)).endTime,
        isNull,
      );
    });

    test('reads the dates and times in the slot\'s own zone', () {
      final input = from(
        wall(2030, 7, 3, 18, 0, india),
        wall(2030, 7, 3, 19, 30, india),
        india,
      );

      expect(input.startDate, DateTime(2030, 7, 3));
      expect(input.startTime, at(18));
      expect(input.endTime, at(19, 30));
      expect(input.timezone, india);
    });

    test('keeps the day when the UTC date differs from the local one', () {
      // 6 PM Pacific on 3 July is 01:00 UTC on 4 July.
      final input = from(wall(2030, 7, 3, 18), wall(2030, 7, 3, 19));

      expect(input.startDate, DateTime(2030, 7, 3));
    });

    test('treats an unknown timezone as the default zone', () {
      final input = slotScheduleInputFromInstants(
        startAt: wall(2030, 7, 3),
        endAt: wall(2030, 7, 3, 23, 59),
        timezone: 'Mars/Olympus',
      );

      expect(input.timezone, pacific);
    });

    test('gives an empty input, in the slot\'s zone, for a slot with no '
        'schedule', () {
      final input = slotScheduleInputFromInstants(
        startAt: null,
        endAt: null,
        timezone: india,
      );

      expect(input.startDate, isNull);
      expect(input.endDate, isNull);
      expect(input.startTime, isNull);
      expect(input.endTime, isNull);
      expect(input.timezone, india);
    });

    test('gives an empty input for a slot with a start but no end', () {
      final input = slotScheduleInputFromInstants(
        startAt: wall(2030, 7, 3),
        endAt: null,
        timezone: pacific,
      );

      expect(input.startDate, isNull);
    });

    test('resolves back to exactly the same instants', () {
      // Whole days and timed ranges, either zone, across both daylight-saving
      // changes and a year end.
      final cases = <(DateTime, DateTime, String)>[
        (wall(2030, 7, 3), wall(2030, 7, 3, 23, 59), pacific),
        (wall(2030, 7, 3, 18), wall(2030, 7, 3, 19, 30), pacific),
        (wall(2030, 3, 10, 1), wall(2030, 3, 10, 4), pacific),
        (wall(2030, 11, 3, 0), wall(2030, 11, 3, 23, 59), pacific),
        (wall(2030, 11, 2, 18), wall(2030, 11, 4, 9), pacific),
        (wall(2030, 12, 31, 20), wall(2031, 1, 1, 2), pacific),
        (wall(2030, 7, 3, 0, 0, india), wall(2030, 7, 5, 23, 59, india), india),
        (wall(2030, 7, 3, 21, 0, india), wall(2030, 7, 4, 1, 0, india), india),
      ];
      for (final (start, end, zone) in cases) {
        final result = resolveSlotSchedule(from(start, end, zone));

        expect(
          result,
          SlotScheduleResolved(startAt: start, endAt: end),
          reason: '$start - $end $zone',
        );
      }
    });
  });
}
