import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';

void main() {
  group('ParayanMember', () {
    final joinedAt = DateTime(2024, 1, 1);
    final timestamp = Timestamp.fromDate(joinedAt);

    test('fromMap should correctly parse a map', () {
      final data = {
        'id': 'test_id',
        'memberName': 'Gajanan',
        'assignedAdhyays': [1, 2, 3],
        'completions': {'1': true, '2': false},
        'joinedAt': timestamp,
        'deviceId': 'device_123',
        'phone': '1234567890',
        'globalIndex': 10,
        'groupNumber': 1,
      };

      final member = ParayanMember.fromMap('Gajanan', data);

      expect(member.id, 'test_id');
      expect(member.name, 'Gajanan');
      expect(member.assignedAdhyays, [1, 2, 3]);
      expect(member.completions, {'1': true, '2': false});
      expect(member.joinedAt, joinedAt);
      expect(member.deviceId, 'device_123');
      expect(member.phone, '1234567890');
      expect(member.globalIndex, 10);
      expect(member.groupNumber, 1);
    });

    test('toMap should correctly serialize a member', () {
      final member = ParayanMember(
        id: 'test_id',
        name: 'Gajanan',
        assignedAdhyays: [1, 2, 3],
        completions: {'1': true, '2': true},
        joinedAt: joinedAt,
        deviceId: 'device_123',
        phone: '1234567890',
        globalIndex: 10,
        groupNumber: 1,
      );

      final map = member.toMap();

      expect(map['id'], 'test_id');
      expect(map['memberName'], 'Gajanan');
      expect(map['assignedAdhyays'], [1, 2, 3]);
      expect(map['completions'], {'1': true, '2': true});
      expect(map['joinedAt'], isA<Timestamp>());
      expect((map['joinedAt'] as Timestamp).toDate(), joinedAt);
    });

    test(
      'isFullyCompleted should return true only when all assigned adhyays are done',
      () {
        final member1 = ParayanMember(
          name: 'Gajanan',
          assignedAdhyays: [1, 2],
          completions: {'1': true, '2': true},
          joinedAt: DateTime.now(),
        );
        expect(member1.isFullyCompleted, true);

        final member2 = ParayanMember(
          name: 'Gajanan',
          assignedAdhyays: [1, 2],
          completions: {'1': true, '2': false},
          joinedAt: DateTime.now(),
        );
        expect(member2.isFullyCompleted, false);

        final member3 = ParayanMember(
          name: 'Gajanan',
          assignedAdhyays: [],
          completions: {},
          joinedAt: DateTime.now(),
        );
        expect(member3.isFullyCompleted, false);
      },
    );

    test('isClaimed should return based on deviceId', () {
      final m1 = ParayanMember(
        name: 'G',
        assignedAdhyays: [],
        completions: {},
        joinedAt: DateTime.now(),
        deviceId: 'real_device_id',
      );
      expect(m1.isClaimed, true);

      final m2 = ParayanMember(
        name: 'G',
        assignedAdhyays: [],
        completions: {},
        joinedAt: DateTime.now(),
        deviceId: 'ADMIN_MANUAL',
      );
      expect(m2.isClaimed, false);

      final m3 = ParayanMember(
        name: 'G',
        assignedAdhyays: [],
        completions: {},
        joinedAt: DateTime.now(),
        deviceId: null,
      );
      expect(m3.isClaimed, false);
    });
  });

  group('ParayanHousehold', () {
    test('fromFirestore should handle flattened member documents', () {
      // Create a mock DocumentSnapshot would be complex,
      // but we can test the logic via a fake data map if we had a factory that took a map.
      // Since fromFirestore takes DocumentSnapshot, we might need a mock for it.
      // For now, let's focus on ParayanMember as it's the primary model now.
    });
  });
}
