import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';

void main() {
  group('GroupNamjapEvent Model Tests', () {
    final now = DateTime.now();
    final eventMap = {
      'name_en': 'Sunday Chanting',
      'name_mr': 'रविवार नामजप',
      'sankalp_en': 'Peace',
      'sankalp_mr': 'शांती',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
      'targetCount': 1000,
      'totalCount': 150,
      'mantra': 'Gan Gan Ganat Bote',
      'joinCode': 'ABC123',
      'status': 'ongoing',
      'groupId': 'gajanan_maharaj_seattle',
      'createdAt': Timestamp.fromDate(now),
    };

    test('should correctly deserialize from Firestore map', () {
      final event = GroupNamjapEvent.fromMap('doc_123', eventMap);

      expect(event.id, 'doc_123');
      expect(event.nameEn, 'Sunday Chanting');
      expect(event.nameMr, 'रविवार नामजप');
      expect(event.sankalpEn, 'Peace');
      expect(event.sankalpMr, 'शांती');
      expect(event.targetCount, 1000);
      expect(event.totalCount, 150);
      expect(event.mantra, 'Gan Gan Ganat Bote');
      expect(event.joinCode, 'ABC123');
      expect(event.status, 'ongoing');
      expect(event.groupId, 'gajanan_maharaj_seattle');
    });

    test('should correctly serialize to Firestore map', () {
      final event = GroupNamjapEvent(
        id: 'doc_123',
        nameEn: 'Sunday Chanting',
        nameMr: 'रविवार नामजप',
        sankalpEn: 'Peace',
        sankalpMr: 'शांती',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        targetCount: 1000,
        totalCount: 150,
        mantra: 'Gan Gan Ganat Bote',
        joinCode: 'ABC123',
        status: 'ongoing',
        groupId: 'gajanan_maharaj_seattle',
        createdAt: now,
      );

      final map = event.toMap();

      expect(map['name_en'], 'Sunday Chanting');
      expect(map['name_mr'], 'रविवार नामजप');
      expect(map['sankalp_en'], 'Peace');
      expect(map['sankalp_mr'], 'शांती');
      expect(map['targetCount'], 1000);
      expect(map['totalCount'], 150);
      expect(map['mantra'], 'Gan Gan Ganat Bote');
      expect(map['joinCode'], 'ABC123');
      expect(map['status'], 'ongoing');
      expect(map['groupId'], 'gajanan_maharaj_seattle');
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
