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

      expect(event.title_mr, 'शीर्षक');
      expect(event.title_en, 'Title');
      expect(event.start_time, now);
      expect(event.end_time, now);
      expect(event.location_mr, 'स्थान');
      expect(event.location_en, 'Location');
      expect(event.details_mr, 'तपशील');
      expect(event.details_en, 'Details');
      expect(event.address, '123 Street');
      expect(event.event_type, EventType.specialEvent);
      expect(event.groupId, 'group_1');
    });

    test('fromFirestore uses defaults for missing fields', () {
      final data = <String, dynamic>{};
      final doc = FakeDocumentSnapshot('test_id', data);
      final event = Event.fromFirestore(doc);

      expect(event.title_mr, '');
      expect(event.title_en, '');
      expect(event.start_time, isA<Timestamp>());
      expect(event.end_time, isNull);
      expect(event.event_type, EventType.other);
      expect(event.groupId, isNull);
    });

    test('EventType parsing handles various formats', () {
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weekly pooja'})).event_type, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weekly_pooja'})).event_type, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'weeklypooja'})).event_type, EventType.weeklyPooja);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'WEEKLY POOJA'})).event_type, EventType.weeklyPooja);
      
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'special event'})).event_type, EventType.specialEvent);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'special_event'})).event_type, EventType.specialEvent);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'specialevent'})).event_type, EventType.specialEvent);
      
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': 'other'})).event_type, EventType.other);
      expect(Event.fromFirestore(FakeDocumentSnapshot('1', {'event_type': null})).event_type, EventType.other);
    });
  });
}
