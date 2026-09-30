import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

void main() {
  group('SignupEntry', () {
    test('round-trips through toMap/fromMap', () {
      final joinedAt = DateTime(2026, 2, 1, 9, 0);
      final entry = SignupEntry(
        id: 'entry1',
        slotId: 'slot1',
        name: 'Jane Doe',
        phone: '+911234567890',
        email: 'jane@example.com',
        deviceId: 'device123',
        pledgeAmount: 25.5,
        note: 'Bringing gulab jamun',
        joinedAt: joinedAt,
      );

      final map = entry.toMap();
      final roundTripped = SignupEntry.fromMap('entry1', map);

      expect(roundTripped.id, 'entry1');
      expect(roundTripped.slotId, 'slot1');
      expect(roundTripped.name, 'Jane Doe');
      expect(roundTripped.phone, '+911234567890');
      expect(roundTripped.email, 'jane@example.com');
      expect(roundTripped.deviceId, 'device123');
      expect(roundTripped.pledgeAmount, 25.5);
      expect(roundTripped.note, 'Bringing gulab jamun');
      expect(roundTripped.joinedAt, joinedAt);
    });

    test(
      'phone, email, deviceId, pledgeAmount, and note are all null when absent',
      () {
        final entry = SignupEntry(
          slotId: 'slot1',
          name: 'Jane Doe',
          joinedAt: DateTime(2026, 2, 1),
        );

        final map = entry.toMap();
        expect(map['phone'], isNull);
        expect(map['email'], isNull);
        expect(map['deviceId'], isNull);
        expect(map['pledgeAmount'], isNull);
        expect(map['note'], isNull);

        final roundTripped = SignupEntry.fromMap('entry2', map);
        expect(roundTripped.phone, isNull);
        expect(roundTripped.email, isNull);
        expect(roundTripped.deviceId, isNull);
        expect(roundTripped.pledgeAmount, isNull);
        expect(roundTripped.note, isNull);
      },
    );

    test(
      'fromMap defaults missing required string fields to empty rather than throwing',
      () {
        final entry = SignupEntry.fromMap('entry3', {});

        expect(entry.slotId, '');
        expect(entry.name, '');
      },
    );

    test('fromMap defaults joinedAt to now when absent', () {
      final before = DateTime.now();
      final entry = SignupEntry.fromMap('entry4', {});
      final after = DateTime.now();

      expect(
        entry.joinedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        entry.joinedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    group('fromMap type guards', () {
      test('falls back to defaults when fields have the wrong type', () {
        final entry = SignupEntry.fromMap('entry5', {
          'slotId': 123,
          'name': true,
          'phone': 456,
          'email': [],
          'deviceId': {},
          'pledgeAmount': 'twenty',
          'note': 789,
        });

        expect(entry.slotId, '');
        expect(entry.name, '');
        expect(entry.phone, isNull);
        expect(entry.email, isNull);
        expect(entry.deviceId, isNull);
        expect(entry.pledgeAmount, isNull);
        expect(entry.note, isNull);
      });
    });

    group('copyWith', () {
      final base = SignupEntry(
        id: 'entry1',
        slotId: 'slot1',
        name: 'Jane Doe',
        joinedAt: DateTime(2026, 2, 1),
      );

      test('preserves unspecified fields', () {
        final updated = base.copyWith(name: 'Updated Name');

        expect(updated.name, 'Updated Name');
        expect(updated.slotId, base.slotId);
        expect(updated.joinedAt, base.joinedAt);
      });
    });

    group('equality', () {
      test(
        'two entries with identical fields are equal and share a hashCode',
        () {
          final joinedAt = DateTime(2026, 2, 1);
          final a = SignupEntry(
            id: 'entry1',
            slotId: 'slot1',
            name: 'Jane',
            joinedAt: joinedAt,
          );
          final b = SignupEntry(
            id: 'entry1',
            slotId: 'slot1',
            name: 'Jane',
            joinedAt: joinedAt,
          );

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('entries differing by name are not equal', () {
        final joinedAt = DateTime(2026, 2, 1);
        final a = SignupEntry(
          id: 'entry1',
          slotId: 'slot1',
          name: 'Jane',
          joinedAt: joinedAt,
        );
        final b = a.copyWith(name: 'John');

        expect(a == b, isFalse);
      });
    });
  });
}
