import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

void main() {
  group('Event Model', () {
    final now = Timestamp.now();

    test('fromFirestore correctly parses all fields', () {
      final data = {
        'title_mr': 'शीर्षक',
        'title_en': 'Title',
        'start_time': now,
        'end_time': now,
        'location_mr': 'स्थान',
        'location_en': 'Location',
        'details_mr': 'तपशील',
        'details_en': 'Details',
        'address': '123 Street',
        'event_type': 'special_event',
        'groupId': 'group_1',
      };

      final doc = FakeDocumentSnapshot('test_id', data);
      final event = Event.fromFirestore(doc);

      expect(event.titleMr, 'शीर्षक');
      expect(event.titleEn, 'Title');
      expect(event.startTime, now);
      expect(event.endTime, now);
      expect(event.locationMr, 'स्थान');
      expect(event.locationEn, 'Location');
      expect(event.detailsMr, 'तपशील');
      expect(event.detailsEn, 'Details');
      expect(event.address, '123 Street');
      expect(event.eventType, EventType.specialEvent);
      expect(event.groupId, 'group_1');
    });

    test('fromFirestore uses defaults for missing fields', () {
      final data = <String, dynamic>{};
      final doc = FakeDocumentSnapshot('test_id', data);
      final event = Event.fromFirestore(doc);

      expect(event.titleMr, '');
      expect(event.titleEn, '');
      expect(event.startTime, isA<Timestamp>());
      expect(event.endTime, isNull);
      expect(event.eventType, EventType.other);
      expect(event.groupId, isNull);
    });

    test('EventType parsing handles various formats', () {
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weekly pooja'})).eventType, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weekly_pooja'})).eventType, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weeklypooja'})).eventType, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'WEEKLY POOJA'})).eventType, EventType.weeklyPooja);
      
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'special event'})).eventType, EventType.specialEvent);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'special_event'})).eventType, EventType.specialEvent);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'specialevent'})).eventType, EventType.specialEvent);
      
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'other'})).eventType, EventType.other);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': null})).eventType, EventType.other);
    });
  });
}
