import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

void main() {
  const pacific = EventTimezone.pacific;
  const india = EventTimezone.india;

  // Wall-clock values are built with DateTime.utc: a local DateTime would be
  // shifted on a machine whose own clock skips that hour (e.g. 02:00 on the
  // US spring daylight-saving day), making these tests depend on the TZ the
  // suite happens to run in.
  DateTime wall(int y, int m, int d, [int h = 0, int min = 0, int s = 0]) =>
      DateTime.utc(y, m, d, h, min, s);

  DateTime utc(int y, int m, int d, [int h = 0, int min = 0, int s = 0]) =>
      DateTime.utc(y, m, d, h, min, s);

  group('wallClockToUtc - Pacific', () {
    test('uses UTC-7 in daylight time', () {
      expect(wallClockToUtc(wall(2026, 7, 1, 18), pacific), utc(2026, 7, 2, 1));
    });

    test('uses UTC-8 in standard time', () {
      expect(
        wallClockToUtc(wall(2026, 12, 1, 18), pacific),
        utc(2026, 12, 2, 2),
      );
    });

    test('daylight time starts at 02:00 on the second Sunday of March', () {
      // 2026: the second Sunday of March is the 8th.
      expect(
        wallClockToUtc(wall(2026, 3, 7, 23, 59), pacific),
        utc(2026, 3, 8, 7, 59),
      );
      expect(
        wallClockToUtc(wall(2026, 3, 8, 1, 59), pacific),
        utc(2026, 3, 8, 9, 59),
      );
      expect(wallClockToUtc(wall(2026, 3, 8, 3), pacific), utc(2026, 3, 8, 10));
      expect(
        wallClockToUtc(wall(2026, 3, 9, 12), pacific),
        utc(2026, 3, 9, 19),
      );
    });

    test('a skipped March wall-clock time counts as daylight time', () {
      // 02:00-03:00 on 2026-03-08 never happens on a real clock; like the
      // existing Parayan code, 02:00 or later takes the new (daylight) offset.
      expect(wallClockToUtc(wall(2026, 3, 8, 2), pacific), utc(2026, 3, 8, 9));
      expect(
        wallClockToUtc(wall(2026, 3, 8, 2, 30), pacific),
        utc(2026, 3, 8, 9, 30),
      );
    });

    test('a repeated November wall-clock time counts as its first '
        'occurrence', () {
      // 01:00-02:00 on 2026-11-01 happens twice; the daylight one wins.
      expect(
        wallClockToUtc(wall(2026, 11, 1, 1, 30), pacific),
        utc(2026, 11, 1, 8, 30),
      );
      expect(
        wallClockToUtc(wall(2026, 11, 1, 1, 59), pacific),
        utc(2026, 11, 1, 8, 59),
      );
    });

    test('daylight time ends at 02:00 on the first Sunday of November', () {
      // 2026: the first Sunday of November is the 1st.
      expect(
        wallClockToUtc(wall(2026, 10, 31, 12), pacific),
        utc(2026, 10, 31, 19),
      );
      expect(
        wallClockToUtc(wall(2026, 11, 1, 0, 30), pacific),
        utc(2026, 11, 1, 7, 30),
      );
      expect(
        wallClockToUtc(wall(2026, 11, 1, 2), pacific),
        utc(2026, 11, 1, 10),
      );
      expect(
        wallClockToUtc(wall(2026, 11, 1, 3), pacific),
        utc(2026, 11, 1, 11),
      );
    });

    test('finds the transition Sundays in another year', () {
      // 2027: March 14 and November 7.
      expect(
        wallClockToUtc(wall(2027, 3, 14, 1, 59), pacific),
        utc(2027, 3, 14, 9, 59),
      );
      expect(
        wallClockToUtc(wall(2027, 3, 14, 3), pacific),
        utc(2027, 3, 14, 10),
      );
      expect(
        wallClockToUtc(wall(2027, 11, 7, 0, 30), pacific),
        utc(2027, 11, 7, 7, 30),
      );
      expect(
        wallClockToUtc(wall(2027, 11, 7, 2), pacific),
        utc(2027, 11, 7, 10),
      );
    });

    test('moves the UTC day when the wall-clock evening crosses midnight', () {
      expect(
        wallClockToUtc(wall(2026, 7, 1, 23, 59), pacific),
        utc(2026, 7, 2, 6, 59),
      );
      expect(wallClockToUtc(wall(2026, 7, 1), pacific), utc(2026, 7, 1, 7));
    });

    test('rejects a local DateTime, which could be silently shifted', () {
      expect(
        () => wallClockToUtc(DateTime(2026, 7, 1, 18), pacific),
        throwsAssertionError,
      );
    });

    test('keeps seconds', () {
      expect(
        wallClockToUtc(wall(2026, 7, 1, 18, 30, 15), pacific),
        utc(2026, 7, 2, 1, 30, 15),
      );
    });
  });

  group('wallClockToUtc - India', () {
    test('uses a fixed UTC+5:30', () {
      expect(
        wallClockToUtc(wall(2026, 3, 15), india),
        utc(2026, 3, 14, 18, 30),
      );
      expect(
        wallClockToUtc(wall(2026, 7, 1, 18), india),
        utc(2026, 7, 1, 12, 30),
      );
      expect(
        wallClockToUtc(wall(2026, 12, 31, 23, 59), india),
        utc(2026, 12, 31, 18, 29),
      );
    });

    test('has no daylight saving', () {
      final winter = wallClockToUtc(wall(2026, 1, 15, 12), india);
      final summer = wallClockToUtc(wall(2026, 7, 15, 12), india);
      expect(winter.hour, summer.hour);
      expect(winter.minute, summer.minute);
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
      // Noon avoids the repeated and skipped hours on transition days.
      for (final zone in EventTimezone.supported) {
        var day = DateTime.utc(2026);
        while (day.year < 2029) {
          final original = DateTime.utc(day.year, day.month, day.day, 12, 30);
          final back = utcToWallClock(wallClockToUtc(original, zone), zone);
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
          expect(
            wallClockToUtc(utcToWallClock(instant, zone), zone),
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
      expect(
        wallClockToUtc(wall(2026, 7, 1, 18), 'Mars/Olympus'),
        utc(2026, 7, 2, 1),
      );
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

    test('is PT for an unknown zone', () {
      expect(timezoneLabel('Mars/Olympus'), 'PT');
    });
  });

  group('EventTimezone', () {
    test('lists the supported zones with Pacific as the default', () {
      expect(EventTimezone.supported, [pacific, india]);
      expect(EventTimezone.defaultZone, pacific);
    });
  });
}
