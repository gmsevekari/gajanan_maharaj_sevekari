import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';

void main() {
  group('GroupNamjapParticipant Model Tests', () {
    final now = DateTime.now();
    final Map<String, dynamic> participantMap = {
      'memberName': 'Abhishek',
      'deviceId': 'device123',
      'phone': '+1234567890',
      'joinedAt': Timestamp.fromDate(now),
      'totalCount': 200,
      'dailyCounts': {
        '2026-04-20': 50,
        '2026-04-21': 150,
      },
    };

    test('should correctly deserialize from Firestore map', () {
      final participant = GroupNamjapParticipant.fromMap(participantMap);

      expect(participant.memberName, 'Abhishek');
      expect(participant.deviceId, 'device123');
      expect(participant.phone, '+1234567890');
      expect(participant.totalCount, 200);
      expect(participant.dailyCounts.length, 2);
      expect(participant.dailyCounts['2026-04-20'], 50);
      expect(participant.dailyCounts['2026-04-21'], 150);
    });

    test('should handle missing dailyCounts gracefully', () {
      final incompleteMap = {
        'memberName': 'Abhishek',
        'deviceId': 'device123',
        'phone': '+1234567890',
        'joinedAt': Timestamp.fromDate(now),
        'totalCount': 0,
      };

      final participant = GroupNamjapParticipant.fromMap(incompleteMap);
      expect(participant.dailyCounts.isEmpty, true);
      expect(participant.totalCount, 0);
    });

    test('should correctly serialize to Firestore map', () {
      final participant = GroupNamjapParticipant(
        memberName: 'Abhishek',
        deviceId: 'device123',
        phone: '+1234567890',
        joinedAt: now,
        totalCount: 200,
        dailyCounts: {'2026-04-20': 50, '2026-04-21': 150},
      );

      final map = participant.toMap();

      expect(map['memberName'], 'Abhishek');
      expect(map['deviceId'], 'device123');
      expect(map['phone'], '+1234567890');
      expect(map['totalCount'], 200);
      expect(map['joinedAt'], isA<Timestamp>());
      expect(map['dailyCounts'], isA<Map<String, dynamic>>());
      expect((map['dailyCounts'] as Map)['2026-04-20'], 50);
    });
  });
}
