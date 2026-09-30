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
  });
}
