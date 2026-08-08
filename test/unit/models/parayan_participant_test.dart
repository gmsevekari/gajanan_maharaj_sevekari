import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParayanMember & ParayanHousehold Unit Tests', () {
    final now = DateTime(2026, 8, 7, 10, 0);

    test('ParayanMember getters and serialization work correctly', () {
      final memberMap = {
        'id': 'mem_1',
        'memberName': 'Abhishek',
        'assignedAdhyays': [1, 2, 3],
        'completions': {'1': true, '2': true, '3': true},
        'joinedAt': Timestamp.fromDate(now),
        'deviceId': 'device_123',
        'phone': '+1234567890',
        'globalIndex': 5,
        'groupNumber': 1,
      };

      final member = ParayanMember.fromMap('Abhishek', memberMap);

      expect(member.id, equals('mem_1'));
      expect(member.name, equals('Abhishek'));
      expect(member.isFullyCompleted, isTrue);
      expect(member.isClaimed, isTrue);

      final exported = member.toMap();
      expect(exported['id'], equals('mem_1'));
      expect(exported['memberName'], equals('Abhishek'));
    });

    test('ParayanMember handles legacy fallback for joinedAt', () {
      final memberMap = {
        'memberName': 'Sevekari',
        'assignedAdhyays': [1],
        'completions': {'1': false},
      };

      final member = ParayanMember.fromMap('Sevekari', memberMap);
      expect(member.joinedAt, equals(DateTime(2024, 1, 1)));
      expect(member.isFullyCompleted, isFalse);
      expect(member.isClaimed, isFalse);
    });

    test('ParayanHousehold.fromFirestore creates virtual household for flattened member doc', () {
      final docData = {
        'id': 'mem_2',
        'memberName': 'Rahul',
        'assignedAdhyays': [4, 5],
        'completions': {'1': true},
        'deviceId': 'dev_456',
        'phone': '+1987654321',
        'joinedAt': Timestamp.fromDate(now),
      };

      final doc = FakeDocumentSnapshot('mem_2', docData);
      final household = ParayanHousehold.fromFirestore(doc);

      expect(household.deviceId, equals('dev_456'));
      expect(household.members.length, equals(1));
      expect(household.members['Rahul']?.name, equals('Rahul'));
    });

    test('ParayanHousehold.fromFirestore creates traditional household doc', () {
      final docData = {
        'deviceId': 'house_789',
        'phone': '+1122334455',
        'joinedAt': Timestamp.fromDate(now),
        'members': {
          'Member 1': {
            'memberName': 'Member 1',
            'assignedAdhyays': [1],
            'completions': {'1': true},
            'joinedAt': Timestamp.fromDate(now),
          }
        }
      };

      final doc = FakeDocumentSnapshot('house_789', docData);
      final household = ParayanHousehold.fromFirestore(doc);

      expect(household.members.length, equals(1));
      expect(household.toFirestore()['deviceId'], equals('house_789'));
    });
  });
}
