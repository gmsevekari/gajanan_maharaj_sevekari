import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

void main() {
  const pacific = EventTimezone.pacific;
  const india = EventTimezone.india;

  DateTime toUtc(
    String timezone,
    int y,
    int m,
    int d, [
    int h = 0,
    int min = 0,
    int s = 0,
  ]) => wallClockToUtc(
    year: y,
    month: m,
    day: d,
    hour: h,
    minute: min,
    second: s,
    timezone: timezone,
  );

  DateTime utc(int y, int m, int d, [int h = 0, int min = 0, int s = 0]) =>
      DateTime.utc(y, m, d, h, min, s);

  // US daylight time for 2020-2035, read from the operating system's own
  // timezone database (an independent oracle): the (month, day) the clocks go
  // forward, and the (month, day) they go back. Both change at 02:00 local.
  const springForward = <int, int>{
    2020: 8,
    2021: 14,
    2022: 13,
    2023: 12,
    2024: 10,
    2025: 9,
    2026: 8,
    2027: 14,
    2028: 12,
    2029: 11,
    2030: 10,
    2031: 9,
    2032: 14,
    2033: 13,
    2034: 12,
    2035: 11,
  };
  const fallBack = <int, int>{
    2020: 1,
    2021: 7,
    2022: 6,
    2023: 5,
    2024: 3,
    2025: 2,
    2026: 1,
    2027: 7,
    2028: 5,
    2029: 4,
    2030: 3,
    2031: 2,
    2032: 7,
    2033: 6,
    2034: 5,
    2035: 4,
  };

  group('wallClockToUtc - Pacific', () {
    test('uses UTC-7 in daylight time', () {
      expect(toUtc(pacific, 2026, 7, 1, 18), utc(2026, 7, 2, 1));
    });

    test('uses UTC-8 in standard time', () {
      expect(toUtc(pacific, 2026, 12, 1, 18), utc(2026, 12, 2, 2));
    });

    test('daylight time starts at the second Sunday of March', () {
      // 2026: the second Sunday of March is the 8th.
      expect(toUtc(pacific, 2026, 3, 7, 23, 59), utc(2026, 3, 8, 7, 59));
      expect(toUtc(pacific, 2026, 3, 8, 1, 59), utc(2026, 3, 8, 9, 59));
      expect(toUtc(pacific, 2026, 3, 8, 3), utc(2026, 3, 8, 10));
      expect(toUtc(pacific, 2026, 3, 9, 12), utc(2026, 3, 9, 19));
    });

    test('a wall-clock time skipped on the March day is read as the moment '
        'the clocks jump', () {
      // 02:00-03:00 on 2026-03-08 never shows on a real clock. All of it maps
      // to 10:00Z (03:00 PDT): never before 01:59 (09:59Z) and never after
      // 03:00, so the order of wall-clock times is preserved.
      expect(toUtc(pacific, 2026, 3, 8, 2), utc(2026, 3, 8, 10));
      expect(toUtc(pacific, 2026, 3, 8, 2, 30), utc(2026, 3, 8, 10));
      expect(toUtc(pacific, 2026, 3, 8, 2, 59, 59), utc(2026, 3, 8, 10));
      expect(
        utcToWallClock(toUtc(pacific, 2026, 3, 8, 2, 30), pacific),
        utc(2026, 3, 8, 3),
      );
    });

    test('daylight time ends at the first Sunday of November', () {
      // 2026: the first Sunday of November is the 1st.
      expect(toUtc(pacific, 2026, 10, 31, 12), utc(2026, 10, 31, 19));
      expect(toUtc(pacific, 2026, 11, 1, 0, 30), utc(2026, 11, 1, 7, 30));
      expect(toUtc(pacific, 2026, 11, 1, 2), utc(2026, 11, 1, 10));
      expect(toUtc(pacific, 2026, 11, 1, 3), utc(2026, 11, 1, 11));
    });

    test('a wall-clock time repeated on the November day is read as its '
        'first occurrence', () {
      // 01:00-02:00 on 2026-11-01 happens twice; the daylight one wins.
      expect(toUtc(pacific, 2026, 11, 1, 1, 30), utc(2026, 11, 1, 8, 30));
      expect(toUtc(pacific, 2026, 11, 1, 1, 59), utc(2026, 11, 1, 8, 59));
    });

    test('moves the UTC day when the wall-clock evening crosses midnight', () {
      expect(toUtc(pacific, 2026, 7, 1, 23, 59), utc(2026, 7, 2, 6, 59));
      expect(toUtc(pacific, 2026, 7, 1), utc(2026, 7, 1, 7));
    });

    test('keeps seconds', () {
      expect(
        toUtc(pacific, 2026, 7, 1, 18, 30, 15),
        utc(2026, 7, 2, 1, 30, 15),
      );
    });

    test('matches the real US transition dates for 2020-2035', () {
      for (var year = 2020; year <= 2035; year++) {
        final spring = springForward[year]!;
        final fall = fallBack[year]!;
        // Clocks go forward: 02:00 PST is 10:00Z.
        expect(
          toUtc(pacific, year, 3, spring, 1, 59, 59),
          utc(year, 3, spring, 9, 59, 59),
          reason: '$year spring, before',
        );
        expect(
          toUtc(pacific, year, 3, spring, 3),
          utc(year, 3, spring, 10),
          reason: '$year spring, after',
        );
        // The day before is still standard time, the day after daylight.
        expect(
          toUtc(pacific, year, 3, spring - 1, 12),
          utc(year, 3, spring - 1, 20),
          reason: '$year spring, day before',
        );
        expect(
          toUtc(pacific, year, 3, spring + 1, 12),
          utc(year, 3, spring + 1, 19),
          reason: '$year spring, day after',
        );
        // Clocks go back: 02:00 PDT is 09:00Z.
        expect(
          toUtc(pacific, year, 11, fall, 1, 59, 59),
          utc(year, 11, fall, 8, 59, 59),
          reason: '$year fall, before',
        );
        expect(
          toUtc(pacific, year, 11, fall, 2),
          utc(year, 11, fall, 10),
          reason: '$year fall, after',
        );
        // (Day 0 rolls back to the end of the previous month.)
        expect(
          toUtc(pacific, year, 11, fall - 1, 12),
          utc(year, 11, fall - 1, 19),
          reason: '$year fall, day before',
        );
        expect(
          toUtc(pacific, year, 11, fall + 1, 12),
          utc(year, 11, fall + 1, 20),
          reason: '$year fall, day after',
        );
      }
    });

    test('never goes back in time as the wall clock moves forward', () {
      // Sweep every minute across both changeover days (and a day either
      // side) for every year, so no skipped or repeated hour can reorder two
      // wall-clock times.
      for (var year = 2020; year <= 2035; year++) {
        for (final (month, day) in [
          (3, springForward[year]!),
          (11, fallBack[year]!),
        ]) {
          var previous = toUtc(pacific, year, month, day - 1);
          for (var minute = 0; minute < 3 * 24 * 60; minute += 1) {
            final current = toUtc(pacific, year, month, day - 1, 0, minute);
            expect(
              current.isBefore(previous),
              isFalse,
              reason: '$year-$month-$day minute $minute',
            );
            previous = current;
          }
        }
      }
    });
  });

  group('wallClockToUtc - India', () {
    test('uses a fixed UTC+5:30', () {
      expect(toUtc(india, 2026, 3, 15), utc(2026, 3, 14, 18, 30));
      expect(toUtc(india, 2026, 7, 1, 18), utc(2026, 7, 1, 12, 30));
      expect(toUtc(india, 2026, 12, 31, 23, 59), utc(2026, 12, 31, 18, 29));
    });

    test('is not affected by US daylight-saving days', () {
      expect(toUtc(india, 2026, 3, 8, 2, 30), utc(2026, 3, 7, 21));
      expect(toUtc(india, 2026, 11, 1, 1, 30), utc(2026, 10, 31, 20));
    });
  });

  group('utcToWallClock', () {
    test('returns a UTC-flagged DateTime carrying the wall-clock fields', () {
      final result = utcToWallClock(utc(2026, 7, 2, 1), pacific);
      expect(result.isUtc, isTrue);
      expect(result, utc(2026, 7, 1, 18));
    });

    test('Pacific: daylight and standard time', () {
      expect(utcToWallClock(utc(2026, 7, 2, 1), pacific), utc(2026, 7, 1, 18));
      expect(
        utcToWallClock(utc(2026, 12, 2, 2), pacific),
        utc(2026, 12, 1, 18),
      );
    });

    test('Pacific: the exact March transition instant', () {
      // 10:00Z on 2026-03-08 is when 02:00 PST becomes 03:00 PDT.
      expect(
        utcToWallClock(utc(2026, 3, 8, 9, 59, 59), pacific),
        utc(2026, 3, 8, 1, 59, 59),
      );
      expect(utcToWallClock(utc(2026, 3, 8, 10), pacific), utc(2026, 3, 8, 3));
    });

    test('Pacific: the exact November transition instant', () {
      // 09:00Z on 2026-11-01 is when 02:00 PDT becomes 01:00 PST.
      expect(
        utcToWallClock(utc(2026, 11, 1, 8, 59, 59), pacific),
        utc(2026, 11, 1, 1, 59, 59),
      );
      expect(utcToWallClock(utc(2026, 11, 1, 9), pacific), utc(2026, 11, 1, 1));
      expect(
        utcToWallClock(utc(2026, 11, 1, 10), pacific),
        utc(2026, 11, 1, 2),
      );
    });

    test('Pacific: matches the real US transition instants for 2020-2035', () {
      for (var year = 2020; year <= 2035; year++) {
        final spring = springForward[year]!;
        final fall = fallBack[year]!;
        expect(
          utcToWallClock(utc(year, 3, spring, 9, 59, 59), pacific),
          utc(year, 3, spring, 1, 59, 59),
          reason: '$year spring, before',
        );
        expect(
          utcToWallClock(utc(year, 3, spring, 10), pacific),
          utc(year, 3, spring, 3),
          reason: '$year spring, after',
        );
        expect(
          utcToWallClock(utc(year, 11, fall, 8, 59, 59), pacific),
          utc(year, 11, fall, 1, 59, 59),
          reason: '$year fall, before',
        );
        expect(
          utcToWallClock(utc(year, 11, fall, 9), pacific),
          utc(year, 11, fall, 1),
          reason: '$year fall, after',
        );
      }
    });

    test('India: fixed offset, crossing the UTC day', () {
      expect(utcToWallClock(utc(2026, 3, 14, 18, 30), india), utc(2026, 3, 15));
      expect(
        utcToWallClock(utc(2026, 12, 31, 18, 29), india),
        utc(2026, 12, 31, 23, 59),
      );
    });

    test('accepts a non-UTC DateTime for the same instant', () {
      final instant = DateTime.utc(2026, 7, 2, 1).toLocal();
      expect(utcToWallClock(instant, pacific), utc(2026, 7, 1, 18));
    });
  });

  group('round trip', () {
    test('wall clock -> UTC -> wall clock is the identity', () {
      // Noon avoids the repeated and skipped hours on transition days; those
      // are covered by the dedicated tests above.
      for (final zone in EventTimezone.supported) {
        var day = DateTime.utc(2026);
        while (day.year < 2029) {
          final back = utcToWallClock(
            toUtc(zone, day.year, day.month, day.day, 12, 30),
            zone,
          );
          expect(
            back,
            DateTime.utc(day.year, day.month, day.day, 12, 30),
            reason: '$zone $day',
          );
          day = DateTime.utc(day.year, day.month, day.day + 1);
        }
      }
    });

    test('UTC -> wall clock -> UTC is the identity outside the overlap', () {
      for (var hour = 0; hour < 24 * 366; hour += 7) {
        final instant = DateTime.utc(2026).add(Duration(hours: hour));
        // Skip the repeated hour on 2026-11-01 (01:00-02:00 occurs twice).
        if (instant.isAfter(utc(2026, 11, 1, 7, 59)) &&
            instant.isBefore(utc(2026, 11, 1, 10))) {
          continue;
        }
        for (final zone in EventTimezone.supported) {
          final wall = utcToWallClock(instant, zone);
          expect(
            toUtc(
              zone,
              wall.year,
              wall.month,
              wall.day,
              wall.hour,
              wall.minute,
              wall.second,
            ),
            instant,
            reason: '$zone $instant',
          );
        }
      }
    });
  });

  group('normalizeTimezone', () {
    test('keeps a supported zone', () {
      expect(normalizeTimezone(india), india);
      expect(normalizeTimezone(pacific), pacific);
    });

    test('falls back to Pacific for null, empty or unknown zones', () {
      expect(normalizeTimezone(null), pacific);
      expect(normalizeTimezone(''), pacific);
      expect(normalizeTimezone('Europe/London'), pacific);
    });

    test('conversions treat an unknown zone as Pacific', () {
      expect(toUtc('Mars/Olympus', 2026, 7, 1, 18), utc(2026, 7, 2, 1));
      expect(
        utcToWallClock(utc(2026, 7, 2, 1), 'Mars/Olympus'),
        utc(2026, 7, 1, 18),
      );
    });
  });

  group('timezoneLabel', () {
    test('is PT for Pacific and IST for India', () {
      expect(timezoneLabel(pacific), 'PT');
      expect(timezoneLabel(india), 'IST');
    });

    test('is PT for an unknown or missing zone', () {
      expect(timezoneLabel('Mars/Olympus'), 'PT');
      expect(timezoneLabel(null), 'PT');
    });
  });

  group('EventTimezone', () {
    test('Pacific is the default and listed first', () {
      expect(EventTimezone.defaultZone, pacific);
      expect(EventTimezone.supported, [pacific, india]);
    });
  });
}
