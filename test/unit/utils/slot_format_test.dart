import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/slot_format.dart';

void main() {
  const pacific = EventTimezone.pacific;
  const india = EventTimezone.india;

  DateTime utc(int y, int m, int d, [int h = 0, int min = 0]) =>
      DateTime.utc(y, m, d, h, min);

  SignupSlot slot({
    DateTime? startAt,
    DateTime? endAt,
    String timezone = pacific,
  }) => SignupSlot(
    labelEn: 'L',
    labelMr: 'L',
    startAt: startAt,
    endAt: endAt,
    timezone: timezone,
    capacity: 1,
    sortOrder: 0,
    createdAt: DateTime.utc(2026),
  );

  SlotWhen? when(SignupSlot s) => formatSlotWhen(s);

  // Seattle, July 2026 is UTC-7, so wall-clock 18:00 on July 1 is already
  // July 2 in UTC: these also prove the slot's own zone is what is shown.
  group('one day', () {
    test('all-day: just the date with its weekday, no time', () {
      final result = when(
        slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 2, 6, 59)),
      );

      expect(result, const SlotWhen('Wednesday, July 1'));
      expect(result!.secondary, isNull);
    });

    test('timed: the date, then the range with the zone label', () {
      final result = when(
        slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 2, 2, 30)),
      );

      expect(
        result,
        const SlotWhen('Wednesday, July 1', '6:00 PM – 7:30 PM PT'),
      );
    });

    test('an all-day slot on a daylight-saving changeover day', () {
      // 2026-03-08: 00:00 PST to 23:59 PDT.
      final result = when(
        slot(startAt: utc(2026, 3, 8, 8), endAt: utc(2026, 3, 9, 6, 59)),
      );

      expect(result, const SlotWhen('Sunday, March 8'));
    });

    test('starts at midnight but ends in the afternoon: still timed', () {
      final result = when(
        slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 1, 21)),
      );

      expect(
        result,
        const SlotWhen('Wednesday, July 1', '12:00 AM – 2:00 PM PT'),
      );
    });

    test('noon reads as 12:00 PM', () {
      final result = when(
        slot(startAt: utc(2026, 7, 1, 19), endAt: utc(2026, 7, 1, 19, 30)),
      );

      expect(
        result,
        const SlotWhen('Wednesday, July 1', '12:00 PM – 12:30 PM PT'),
      );
    });

    test('minutes are kept', () {
      final result = when(
        slot(startAt: utc(2026, 7, 1, 16, 45), endAt: utc(2026, 7, 1, 18, 5)),
      );

      expect(
        result,
        const SlotWhen('Wednesday, July 1', '9:45 AM – 11:05 AM PT'),
      );
    });
  });

  group('several days', () {
    test('all-day: the first and last date, no weekday, no time', () {
      final result = when(
        slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 4, 6, 59)),
      );

      expect(result, const SlotWhen('July 1 – July 3'));
      expect(result!.secondary, isNull);
    });

    test('all-day across a month boundary', () {
      final result = when(
        slot(startAt: utc(2026, 6, 29, 7), endAt: utc(2026, 7, 3, 6, 59)),
      );

      expect(result, const SlotWhen('June 29 – July 2'));
    });

    test('timed: one line with both dates, times and the zone label', () {
      final result = when(
        slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 3, 19)),
      );

      expect(result, const SlotWhen('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'));
      expect(result!.secondary, isNull);
    });

    test('an overnight slot counts as several days', () {
      // 22:00 on July 1 to 02:00 on July 2, Seattle.
      final result = when(
        slot(startAt: utc(2026, 7, 2, 5), endAt: utc(2026, 7, 2, 9)),
      );

      expect(result, const SlotWhen('Jul 1, 10:00 PM – Jul 2, 2:00 AM PT'));
    });

    test('across New Year', () {
      // Seattle, Dec 31 18:00 to Jan 1 02:00 (UTC-8).
      final result = when(
        slot(startAt: utc(2027, 1, 1, 2), endAt: utc(2027, 1, 1, 10)),
      );

      expect(
        result,
        const SlotWhen('Dec 31, 2026, 6:00 PM – Jan 1, 2027, 2:00 AM PT'),
      );
    });
  });

  group('timezone', () {
    test('India: all-day and timed, labelled IST', () {
      // 2026-03-15, 00:00 to 23:59 IST.
      expect(
        when(
          slot(
            startAt: utc(2026, 3, 14, 18, 30),
            endAt: utc(2026, 3, 15, 18, 29),
            timezone: india,
          ),
        ),
        const SlotWhen('Sunday, March 15'),
      );
      // 06:00 to 08:30 IST.
      expect(
        when(
          slot(
            startAt: utc(2026, 3, 15, 0, 30),
            endAt: utc(2026, 3, 15, 3),
            timezone: india,
          ),
        ),
        const SlotWhen('Sunday, March 15', '6:00 AM – 8:30 AM IST'),
      );
    });

    test('the same instants read differently in different zones', () {
      final instants = (utc(2026, 7, 2, 1), utc(2026, 7, 2, 2, 30));
      expect(
        when(slot(startAt: instants.$1, endAt: instants.$2))!.secondary,
        '6:00 PM – 7:30 PM PT',
      );
      expect(
        when(
          slot(startAt: instants.$1, endAt: instants.$2, timezone: india),
        )!.secondary,
        '6:30 AM – 8:00 AM IST',
      );
    });

    test('an unknown zone is read, and labelled, as Pacific', () {
      final result = when(
        slot(
          startAt: utc(2026, 7, 2, 1),
          endAt: utc(2026, 7, 2, 2, 30),
          timezone: 'Mars/Olympus',
        ),
      );

      expect(
        result,
        const SlotWhen('Wednesday, July 1', '6:00 PM – 7:30 PM PT'),
      );
    });
  });

  group('locale', () {
    test('stays English even when the app locale is Marathi', () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = 'mr';

      expect(
        when(slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 2, 2, 30))),
        const SlotWhen('Wednesday, July 1', '6:00 PM – 7:30 PM PT'),
      );
      expect(
        when(slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 3, 19))),
        const SlotWhen('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'),
      );
      expect(
        when(slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 4, 6, 59))),
        const SlotWhen('July 1 – July 3'),
      );
      expect(
        when(slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 2, 6, 59))),
        const SlotWhen('Wednesday, July 1'),
      );
    });
  });

  group('edge cases', () {
    test('an all-day slot on the 25-hour fall-back day', () {
      // 2026-11-01: 00:00 PDT to 23:59 PST.
      expect(
        when(
          slot(startAt: utc(2026, 11, 1, 7), endAt: utc(2026, 11, 2, 7, 59)),
        ),
        const SlotWhen('Sunday, November 1'),
      );
    });

    test('a timed slot across the skipped spring hour', () {
      // 2026-03-08, 01:30 PST to 03:15 PDT.
      expect(
        when(
          slot(startAt: utc(2026, 3, 8, 9, 30), endAt: utc(2026, 3, 8, 10, 15)),
        ),
        const SlotWhen('Sunday, March 8', '1:30 AM – 3:15 AM PT'),
      );
    });

    test('a timed slot across the repeated autumn hour', () {
      // 2026-11-01, 01:30 PDT to 02:30 PST.
      expect(
        when(
          slot(
            startAt: utc(2026, 11, 1, 8, 30),
            endAt: utc(2026, 11, 1, 10, 30),
          ),
        ),
        const SlotWhen('Sunday, November 1', '1:30 AM – 2:30 AM PT'),
      );
    });

    test('ending exactly at midnight is a timed slot across two days', () {
      // 00:00 on July 1 to 00:00 on July 2 (not the 23:59 default).
      expect(
        when(slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 2, 7))),
        const SlotWhen('Jul 1, 12:00 AM – Jul 2, 12:00 AM PT'),
      );
    });

    test('a timed several-day slot that starts at midnight', () {
      expect(
        when(slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 3, 19))),
        const SlotWhen('Jul 1, 12:00 AM – Jul 3, 12:00 PM PT'),
      );
    });

    test('an India overnight slot', () {
      // 22:00 on July 1 to 04:00 on July 2, IST.
      expect(
        when(
          slot(
            startAt: utc(2026, 7, 1, 16, 30),
            endAt: utc(2026, 7, 1, 22, 30),
            timezone: india,
          ),
        ),
        const SlotWhen('Jul 1, 10:00 PM – Jul 2, 4:00 AM IST'),
      );
    });

    test('an all-day slot across New Year', () {
      // Seattle, Dec 30 00:00 to Jan 2 23:59.
      expect(
        when(
          slot(startAt: utc(2026, 12, 30, 8), endAt: utc(2027, 1, 3, 7, 59)),
        ),
        const SlotWhen('December 30, 2026 – January 2, 2027'),
      );
    });

    test('a zero-length or backwards slot is shown as stored; the form is '
        'what rejects it', () {
      expect(
        when(slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 2, 1))),
        const SlotWhen('Wednesday, July 1', '6:00 PM – 6:00 PM PT'),
      );
      expect(
        when(slot(startAt: utc(2026, 7, 2, 2), endAt: utc(2026, 7, 2, 1))),
        const SlotWhen('Wednesday, July 1', '7:00 PM – 6:00 PM PT'),
      );
    });
  });

  group('the year', () {
    test('is left out when a slot stays within one year', () {
      expect(
        when(slot(startAt: utc(2026, 7, 1, 7), endAt: utc(2026, 7, 4, 6, 59))),
        const SlotWhen('July 1 – July 3'),
      );
      expect(
        when(slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 3, 19))),
        const SlotWhen('Jul 1, 6:00 PM – Jul 3, 12:00 PM PT'),
      );
    });

    test('is shown on both ends when the years differ, so a year-long '
        'slot does not read as a single day', () {
      // Seattle, 2026-03-15 00:00 to 2027-03-16 23:59.
      expect(
        when(
          slot(startAt: utc(2026, 3, 15, 7), endAt: utc(2027, 3, 17, 6, 59)),
        ),
        const SlotWhen('March 15, 2026 – March 16, 2027'),
      );
    });

    test('is not added to a one-day slot', () {
      expect(
        when(slot(startAt: utc(2026, 7, 2, 1), endAt: utc(2026, 7, 2, 2, 30))),
        const SlotWhen('Wednesday, July 1', '6:00 PM – 7:30 PM PT'),
      );
    });
  });

  group('no schedule', () {
    test('is null for a slot without a start or end', () {
      expect(when(slot()), isNull);
    });

    test('is null when only one end is known', () {
      expect(when(slot(startAt: utc(2026, 7, 1, 7))), isNull);
      expect(when(slot(endAt: utc(2026, 7, 1, 7))), isNull);
    });
  });

  group('SlotWhen', () {
    test('compares by both lines', () {
      expect(const SlotWhen('a', 'b'), const SlotWhen('a', 'b'));
      expect(const SlotWhen('a').hashCode, const SlotWhen('a').hashCode);
      expect(const SlotWhen('a', 'b') == const SlotWhen('a'), isFalse);
      expect(const SlotWhen('a', 'b') == const SlotWhen('a', 'c'), isFalse);
      expect(const SlotWhen('a') == const SlotWhen('b'), isFalse);
    });

    test('has a readable description', () {
      expect(const SlotWhen('a', 'b').toString(), 'SlotWhen(a | b)');
      expect(const SlotWhen('a').toString(), 'SlotWhen(a)');
    });
  });
}
