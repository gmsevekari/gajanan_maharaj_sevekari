import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';

void main() {
  group('VaariParticipant Model Tests', () {
    final now = DateTime.now();
    final participantMap = {
      'memberName': 'Abhishek Kulkarni',
      'deviceId': 'device_123',
      'phone': '1234567890',
      'joinedAt': Timestamp.fromDate(now),
      'totalSteps': 12000,
      'totalDistance': 9.6,
    };

    test('should correctly deserialize from Firestore map', () {
      final participant = VaariParticipant.fromMap(participantMap);

      expect(participant.memberName, 'Abhishek Kulkarni');
      expect(participant.deviceId, 'device_123');
      expect(participant.phone, '1234567890');
      expect(participant.joinedAt, isA<DateTime>());
      expect(participant.totalSteps, 12000);
      expect(participant.totalDistance, 9.6);
    });

    test('should correctly serialize to Firestore map', () {
      final participant = VaariParticipant(
        memberName: 'Abhishek Kulkarni',
        deviceId: 'device_123',
        phone: '1234567890',
        joinedAt: now,
        totalSteps: 12000,
        totalDistance: 9.6,
      );

      final map = participant.toMap();

      expect(map['memberName'], 'Abhishek Kulkarni');
      expect(map['deviceId'], 'device_123');
      expect(map['phone'], '1234567890');
      expect(map['totalSteps'], 12000);
      expect(map['totalDistance'], 9.6);
      expect(map['joinedAt'], isA<Timestamp>());
    });
  });
}
