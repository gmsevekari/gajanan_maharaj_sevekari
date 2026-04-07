import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';

void main() {
  group('ParayanEvent', () {
    final startDate = DateTime(2024, 5, 1);
    final endDate = DateTime(2024, 5, 3);
    final createdAt = DateTime(2024, 4, 1);

    test('toFirestore should correctly serialize the event', () {
      final event = ParayanEvent(
        id: 'test_id',
        titleEn: 'Test Event',
        titleMr: 'टेस्ट इव्हेंट',
        descriptionEn: 'Desc En',
        descriptionMr: 'Desc Mr',
        type: ParayanType.threeDay,
        startDate: startDate,
        endDate: endDate,
        status: 'enrolling',
        reminderTimes: ['20:00'],
        createdAt: createdAt,
        joinedParticipants: 5,
        groupId: 'test_group',
      );

      final map = event.toFirestore();

      expect(map['title_en'], 'Test Event');
      expect(map['type'], 'threeDay');
      expect(map['startDate'], isA<Timestamp>());
      expect((map['startDate'] as Timestamp).toDate(), startDate);
      expect(map['status'], 'enrolling');
      expect(map['joinedParticipants'], 5);
    });

    test('Status mapping from type', () {
      final event1 = ParayanEvent(
        id: '1',
        titleEn: '', titleMr: '', descriptionEn: '', descriptionMr: '',
        type: ParayanType.oneDay,
        startDate: startDate, endDate: endDate, status: 'upcoming',
        reminderTimes: [], createdAt: createdAt, groupId: '',
      );
      expect(event1.toFirestore()['type'], 'oneDay');

      final event2 = ParayanEvent(
        id: '2',
        titleEn: '', titleMr: '', descriptionEn: '', descriptionMr: '',
        type: ParayanType.guruPushya,
        startDate: startDate, endDate: endDate, status: 'upcoming',
        reminderTimes: [], createdAt: createdAt, groupId: '',
      );
      expect(event2.toFirestore()['type'], 'guruPushya');
    });
  });
}
