import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  group('SignupSlot', () {
    test('round-trips through toMap/fromMap', () {
      final createdAt = DateTime(2026, 1, 1, 10, 30);
      final date = DateTime(2026, 3, 15);
      final slot = SignupSlot(
        id: 'slot1',
        labelEn: 'Week 1 - Team A',
        labelMr: 'आठवडा १ - टीम अ',
        date: date,
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
      expect(roundTripped.date, date);
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

    test('date and suggestedAmount are null when absent', () {
      final slot = SignupSlot(
        labelEn: 'Aarti Flowers',
        labelMr: 'आरती फुले',
        capacity: 1,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = slot.toMap();
      expect(map['date'], isNull);
      expect(map['suggestedAmount'], isNull);

      final roundTripped = SignupSlot.fromMap('slot3', map);
      expect(roundTripped.date, isNull);
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
          'date': '2026-01-01',
          'capacity': 'three',
          'claimedCount': 'one',
          'suggestedAmount': 'fifty',
          'sortOrder': 'zero',
        });

        expect(slot.labelEn, '');
        expect(slot.labelMr, '');
        expect(slot.date, isNull);
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
  });
}
