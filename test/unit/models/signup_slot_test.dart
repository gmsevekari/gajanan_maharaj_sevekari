import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

void main() {
  group('SignupSlot', () {
    test('round-trips through toMap/fromMap', () {
      final createdAt = DateTime(2026, 1, 1, 10, 30);
      final startAt = DateTime.utc(2026, 3, 15, 7);
      final endAt = DateTime.utc(2026, 3, 16, 6, 59);
      final slot = SignupSlot(
        id: 'slot1',
        labelEn: 'Week 1 - Team A',
        labelMr: 'आठवडा १ - टीम अ',
        startAt: startAt,
        endAt: endAt,
        timezone: EventTimezone.india,
        capacity: 3,
        claimedCount: 1,
        suggestedAmount: 50.0,
        sortOrder: 0,
        createdAt: createdAt,
      );

      final map = slot.toMap();
      final roundTripped = SignupSlot.fromMap('slot1', map);

      expect(roundTripped.id, 'slot1');
      expect(roundTripped.labelEn, 'Week 1 - Team A');
      expect(roundTripped.labelMr, 'आठवडा १ - टीम अ');
      expect(roundTripped.startAt, startAt);
      expect(roundTripped.endAt, endAt);
      expect(roundTripped.timezone, EventTimezone.india);
      expect(roundTripped.capacity, 3);
      expect(roundTripped.claimedCount, 1);
      expect(roundTripped.suggestedAmount, 50.0);
      expect(roundTripped.sortOrder, 0);
      expect(roundTripped.createdAt, createdAt);
    });

    test('claimedCount defaults to 0 when not provided', () {
      final slot = SignupSlot(
        labelEn: 'Day 3',
        labelMr: 'दिवस ३',
        capacity: 5,
        sortOrder: 2,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(slot.claimedCount, 0);
    });

    test('claimedCount defaults to 0 when reading a map missing the field', () {
      final slot = SignupSlot.fromMap('slot2', {
        'labelEn': 'Day 4',
        'labelMr': 'दिवस ४',
        'capacity': 2,
        'sortOrder': 3,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(slot.claimedCount, 0);
    });

    test('start, end and suggestedAmount are null when absent', () {
      final slot = SignupSlot(
        labelEn: 'Aarti Flowers',
        labelMr: 'आरती फुले',
        capacity: 1,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = slot.toMap();
      expect(map['startAt'], isNull);
      expect(map['endAt'], isNull);
      expect(map['suggestedAmount'], isNull);

      final roundTripped = SignupSlot.fromMap('slot3', map);
      expect(roundTripped.startAt, isNull);
      expect(roundTripped.endAt, isNull);
      expect(roundTripped.suggestedAmount, isNull);
    });

    test(
      'fromMap defaults missing string fields to empty rather than throwing',
      () {
        final slot = SignupSlot.fromMap('slot4', {});

        expect(slot.labelEn, '');
        expect(slot.labelMr, '');
        expect(slot.capacity, 0);
        expect(slot.sortOrder, 0);
      },
    );

    test('fromMap defaults createdAt to now when absent', () {
      final before = DateTime.now();
      final slot = SignupSlot.fromMap('slot5', {});
      final after = DateTime.now();

      expect(
        slot.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        slot.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    group('fromMap type guards', () {
      test('falls back to defaults when fields have the wrong type', () {
        final slot = SignupSlot.fromMap('slot6', {
          'labelEn': 123,
          'labelMr': true,
          'startAt': '2026-01-01',
          'endAt': 5,
          'timezone': 42,
          'capacity': 'three',
          'claimedCount': 'one',
          'suggestedAmount': 'fifty',
          'sortOrder': 'zero',
        });

        expect(slot.labelEn, '');
        expect(slot.labelMr, '');
        expect(slot.startAt, isNull);
        expect(slot.endAt, isNull);
        expect(slot.timezone, EventTimezone.defaultZone);
        expect(slot.capacity, 0);
        expect(slot.claimedCount, 0);
        expect(slot.suggestedAmount, isNull);
        expect(slot.sortOrder, 0);
      });
    });

    group('copyWith', () {
      final base = SignupSlot(
        id: 'slot1',
        labelEn: 'Week 1',
        labelMr: 'आठवडा १',
        capacity: 3,
        claimedCount: 1,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      test('with no arguments returns an identical copy', () {
        final copy = base.copyWith();

        expect(copy, equals(base));
      });

      test('preserves unspecified fields', () {
        final updated = base.copyWith(claimedCount: 2);

        expect(updated.claimedCount, 2);
        expect(updated.labelEn, base.labelEn);
        expect(updated.capacity, base.capacity);
        expect(updated.sortOrder, base.sortOrder);
      });
    });

    group('equality', () {
      test(
        'two slots with identical fields are equal and share a hashCode',
        () {
          final createdAt = DateTime(2026, 1, 1);
          final a = SignupSlot(
            id: 'slot1',
            labelEn: 'L',
            labelMr: 'L',
            capacity: 3,
            sortOrder: 0,
            createdAt: createdAt,
          );
          final b = SignupSlot(
            id: 'slot1',
            labelEn: 'L',
            labelMr: 'L',
            capacity: 3,
            sortOrder: 0,
            createdAt: createdAt,
          );

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('slots differing by claimedCount are not equal', () {
        final createdAt = DateTime(2026, 1, 1);
        final a = SignupSlot(
          id: 'slot1',
          labelEn: 'L',
          labelMr: 'L',
          capacity: 3,
          sortOrder: 0,
          createdAt: createdAt,
        );
        final b = a.copyWith(claimedCount: 1);

        expect(a == b, isFalse);
      });
    });

    group('timezone and schedule fields', () {
      SignupSlot build({
        DateTime? startAt,
        DateTime? endAt,
        String timezone = EventTimezone.pacific,
      }) => SignupSlot(
        labelEn: 'L',
        labelMr: 'L',
        startAt: startAt,
        endAt: endAt,
        timezone: timezone,
        capacity: 1,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      test('timezone defaults to Pacific', () {
        expect(
          SignupSlot(
            labelEn: 'L',
            labelMr: 'L',
            capacity: 1,
            sortOrder: 0,
            createdAt: DateTime(2026, 1, 1),
          ).timezone,
          EventTimezone.pacific,
        );
      });

      test('toMap writes the instants as Timestamps and the zone as text', () {
        final map = build(
          startAt: DateTime.utc(2026, 3, 15, 7),
          endAt: DateTime.utc(2026, 3, 16, 6, 59),
          timezone: EventTimezone.india,
        ).toMap();

        expect(
          map['startAt'],
          Timestamp.fromDate(DateTime.utc(2026, 3, 15, 7)),
        );
        expect(
          map['endAt'],
          Timestamp.fromDate(DateTime.utc(2026, 3, 16, 6, 59)),
        );
        expect(map['timezone'], EventTimezone.india);
        expect(map.containsKey('date'), isFalse);
      });

      test('a document missing the new fields loads without error', () {
        // E.g. a slot saved before these fields existed.
        final slot = SignupSlot.fromMap('old', {
          'labelEn': 'Week 1',
          'labelMr': 'आठवडा १',
          'capacity': 3,
          'claimedCount': 1,
          'sortOrder': 0,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });

        expect(slot.startAt, isNull);
        expect(slot.endAt, isNull);
        expect(slot.timezone, EventTimezone.defaultZone);
        expect(slot.hasSchedule, isFalse);
      });

      test('ignores a leftover legacy date field', () {
        final slot = SignupSlot.fromMap('old', {
          'labelEn': 'Week 1',
          'date': Timestamp.fromDate(DateTime(2026, 3, 15)),
        });

        expect(slot.startAt, isNull);
        expect(slot.endAt, isNull);
      });

      test('fromMap returns UTC instants', () {
        final slot = SignupSlot.fromMap('s', {
          'startAt': Timestamp.fromDate(DateTime.utc(2026, 3, 15, 7)),
          'endAt': Timestamp.fromDate(DateTime.utc(2026, 3, 16, 6, 59)),
        });

        expect(slot.startAt!.isUtc, isTrue);
        expect(slot.endAt!.isUtc, isTrue);
      });

      test('keeps an unrecognised zone name rather than rewriting it', () {
        final slot = SignupSlot.fromMap('s', {'timezone': 'Europe/London'});
        expect(slot.timezone, 'Europe/London');
        expect(slot.toMap()['timezone'], 'Europe/London');
      });

      group('hasSchedule', () {
        test('needs both a start and an end', () {
          expect(build().hasSchedule, isFalse);
          expect(
            build(startAt: DateTime.utc(2026, 3, 15)).hasSchedule,
            isFalse,
          );
          expect(build(endAt: DateTime.utc(2026, 3, 15)).hasSchedule, isFalse);
          expect(
            build(
              startAt: DateTime.utc(2026, 3, 15),
              endAt: DateTime.utc(2026, 3, 16),
            ).hasSchedule,
            isTrue,
          );
        });
      });

      group('isAllDay', () {
        test('is true from 00:00 to 23:59 in the slot\'s zone', () {
          // Seattle, 2026-07-01 (UTC-7).
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 7),
              endAt: DateTime.utc(2026, 7, 2, 6, 59),
            ).isAllDay,
            isTrue,
          );
        });

        test('is true across days too, and on a daylight-saving day', () {
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 7),
              endAt: DateTime.utc(2026, 7, 4, 6, 59),
            ).isAllDay,
            isTrue,
          );
          // 2026-03-08: 00:00 PST to 23:59 PDT.
          expect(
            build(
              startAt: DateTime.utc(2026, 3, 8, 8),
              endAt: DateTime.utc(2026, 3, 9, 6, 59),
            ).isAllDay,
            isTrue,
          );
        });

        test('is false when a time was set', () {
          // 18:00-19:30 Seattle.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 2, 1),
              endAt: DateTime.utc(2026, 7, 2, 2, 30),
            ).isAllDay,
            isFalse,
          );
          // Starts at midnight but ends at 14:00.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 7),
              endAt: DateTime.utc(2026, 7, 1, 21),
            ).isAllDay,
            isFalse,
          );
          // Starts at 06:00 and ends at 23:59.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 13),
              endAt: DateTime.utc(2026, 7, 2, 6, 59),
            ).isAllDay,
            isFalse,
          );
        });

        test('depends on the slot\'s zone, not the viewer\'s', () {
          final instants = (
            DateTime.utc(2026, 7, 1, 7),
            DateTime.utc(2026, 7, 2, 6, 59),
          );
          expect(
            build(startAt: instants.$1, endAt: instants.$2).isAllDay,
            isTrue,
          );
          expect(
            build(
              startAt: instants.$1,
              endAt: instants.$2,
              timezone: EventTimezone.india,
            ).isAllDay,
            isFalse,
          );
        });

        test('is false without a full schedule', () {
          expect(build().isAllDay, isFalse);
          expect(build(startAt: DateTime.utc(2026, 7, 1, 7)).isAllDay, isFalse);
        });
      });

      group('isMultiDay', () {
        test('is false within one wall-clock day', () {
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 2, 1),
              endAt: DateTime.utc(2026, 7, 2, 2, 30),
            ).isMultiDay,
            isFalse,
          );
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 7),
              endAt: DateTime.utc(2026, 7, 2, 6, 59),
            ).isMultiDay,
            isFalse,
          );
        });

        test('is true across wall-clock days, including overnight', () {
          // 22:00 to 02:00 next day, Seattle.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 2, 5),
              endAt: DateTime.utc(2026, 7, 2, 9),
            ).isMultiDay,
            isTrue,
          );
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 1, 7),
              endAt: DateTime.utc(2026, 7, 4, 6, 59),
            ).isMultiDay,
            isTrue,
          );
        });

        test('compares the whole date: month and year, not just the day', () {
          // Same day of the month, a month apart.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 15, 19),
              endAt: DateTime.utc(2026, 8, 15, 19),
            ).isMultiDay,
            isTrue,
          );
          // Same day and month, a year apart.
          expect(
            build(
              startAt: DateTime.utc(2026, 7, 15, 19),
              endAt: DateTime.utc(2027, 7, 15, 19),
            ).isMultiDay,
            isTrue,
          );
          // The wall-clock new year: Seattle 23:00 on Dec 31 to 01:00 Jan 1.
          expect(
            build(
              startAt: DateTime.utc(2027, 1, 1, 7),
              endAt: DateTime.utc(2027, 1, 1, 9),
            ).isMultiDay,
            isTrue,
          );
        });

        test('depends on the slot\'s zone', () {
          // 10:30-12:00 in Seattle, but 23:00-00:30 across midnight in India.
          final start = DateTime.utc(2026, 7, 1, 17, 30);
          final end = DateTime.utc(2026, 7, 1, 19);
          expect(build(startAt: start, endAt: end).isMultiDay, isFalse);
          expect(
            build(
              startAt: start,
              endAt: end,
              timezone: EventTimezone.india,
            ).isMultiDay,
            isTrue,
          );
        });

        test('is false without a full schedule', () {
          expect(build().isMultiDay, isFalse);
          expect(
            build(startAt: DateTime.utc(2026, 7, 1, 7)).isMultiDay,
            isFalse,
          );
        });
      });

      test('copyWith can replace the new fields and keeps them otherwise', () {
        final base = build(
          startAt: DateTime.utc(2026, 7, 2, 1),
          endAt: DateTime.utc(2026, 7, 2, 2),
        );
        final moved = base.copyWith(
          startAt: DateTime.utc(2026, 7, 3, 1),
          endAt: DateTime.utc(2026, 7, 3, 2),
          timezone: EventTimezone.india,
        );

        expect(moved.startAt, DateTime.utc(2026, 7, 3, 1));
        expect(moved.endAt, DateTime.utc(2026, 7, 3, 2));
        expect(moved.timezone, EventTimezone.india);
        expect(base.copyWith().startAt, base.startAt);
        expect(base.copyWith().timezone, base.timezone);
      });

      test('equality includes start, end and timezone', () {
        final base = build(
          startAt: DateTime.utc(2026, 7, 2, 1),
          endAt: DateTime.utc(2026, 7, 2, 2),
        );
        final same = build(
          startAt: DateTime.utc(2026, 7, 2, 1),
          endAt: DateTime.utc(2026, 7, 2, 2),
        );
        expect(base, same);
        expect(base.hashCode, same.hashCode);
        expect(
          base == base.copyWith(startAt: DateTime.utc(2026, 7, 2, 0)),
          isFalse,
        );
        expect(
          base == base.copyWith(endAt: DateTime.utc(2026, 7, 2, 3)),
          isFalse,
        );
        expect(base == base.copyWith(timezone: EventTimezone.india), isFalse);
      });

      test('equality compares the instant, not the UTC flag', () {
        final utcSlot = build(
          startAt: DateTime.utc(2026, 7, 2, 1),
          endAt: DateTime.utc(2026, 7, 2, 2),
        );
        final localSlot = build(
          startAt: DateTime.utc(2026, 7, 2, 1).toLocal(),
          endAt: DateTime.utc(2026, 7, 2, 2).toLocal(),
        );
        expect(utcSlot, localSlot);
        expect(utcSlot.hashCode, localSlot.hashCode);
      });

      test('equality compares createdAt by instant too', () {
        final a = build().copyWith(createdAt: DateTime.utc(2026, 1, 1, 8));
        final b = build().copyWith(
          createdAt: DateTime.utc(2026, 1, 1, 8).toLocal(),
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(
          a == build().copyWith(createdAt: DateTime.utc(2026, 1, 1, 9)),
          isFalse,
        );
      });

      test('a slot with a start is not equal to one without', () {
        final withStart = build(startAt: DateTime.utc(2026, 7, 2, 1));
        expect(withStart == build(), isFalse);
        expect(build() == withStart, isFalse);
      });
    });
  });
}
