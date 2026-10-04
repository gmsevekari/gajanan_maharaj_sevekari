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
      final seattle = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          timezone: pacific,
        ),
      );
      final ist = resolved(
        SlotScheduleInput(
          startDate: day(2026, 7, 1),
          startTime: at(18),
          timezone: india,
        ),
      );
      expect(ist.startAt.isBefore(seattle.startAt), isTrue);
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
}
