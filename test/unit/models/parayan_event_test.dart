import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  setUpAll(() async {
    await initializeDateFormatting('mr', null);
    await initializeDateFormatting('en', null);
  });

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
        groupId: 'test_group',
        timezone: 'Asia/Kolkata',
      );

      final map = event.toFirestore();

      expect(map['title_en'], 'Test Event');
      expect(map['type'], 'threeDay');
      expect(map['startDate'], isA<Timestamp>());
      expect((map['startDate'] as Timestamp).toDate(), startDate);
      expect(map['status'], 'enrolling');
      expect(map['timezone'], 'Asia/Kolkata');
    });

    test(
      'fromFirestore should correctly deserialize with default timezone',
      () {
        final map = {
          'title_en': 'Test',
          'title_mr': 'टेस्ट',
          'description_en': 'Desc',
          'description_mr': 'डिस्क',
          'type': 'oneDay',
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'status': 'upcoming',
          'reminderTimes': <String>[],
          'createdAt': Timestamp.fromDate(createdAt),
          'groupId': 'group1',
        };

        final doc = FakeDocumentSnapshot('id1', map);
        final event = ParayanEvent.fromFirestore(doc);

        expect(event.titleEn, 'Test');
        expect(event.timezone, 'America/Los_Angeles'); // Default
      },
    );

    test('fromFirestore should use provided timezone', () {
      final map = {
        'title_en': 'Test',
        'title_mr': 'टेस्ट',
        'description_en': 'Desc',
        'description_mr': 'डिस्क',
        'type': 'oneDay',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'upcoming',
        'reminderTimes': <String>[],
        'createdAt': Timestamp.fromDate(createdAt),
        'groupId': 'group1',
        'timezone': 'Asia/Kolkata',
      };

      final doc = FakeDocumentSnapshot('id2', map);
      final event = ParayanEvent.fromFirestore(doc);

      expect(event.timezone, 'Asia/Kolkata');
    });

    test('Status mapping from type', () {
      final event1 = ParayanEvent(
        id: '1',
        titleEn: '',
        titleMr: '',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.oneDay,
        startDate: startDate,
        endDate: endDate,
        status: 'upcoming',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: '',
      );
      expect(event1.toFirestore()['type'], 'oneDay');

      final event2 = ParayanEvent(
        id: '2',
        titleEn: '',
        titleMr: '',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.guruPushya,
        startDate: startDate,
        endDate: endDate,
        status: 'upcoming',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: '',
      );
      expect(event2.toFirestore()['type'], 'guruPushya');
    });

    test('serialization of 4-day parayan fields', () {
      final event = ParayanEvent(
        id: 'test_4day',
        titleEn: '4-Day Event',
        titleMr: '४-दिवस इव्हेंट',
        descriptionEn: 'Desc En',
        descriptionMr: 'Desc Mr',
        type: ParayanType.threeDay,
        startDate: startDate,
        endDate: endDate,
        status: 'ongoing',
        reminderTimes: ['20:00'],
        createdAt: createdAt,
        groupId: 'test_group',
        timezone: 'Asia/Kolkata',
        is4DayParayan: true,
        extraDayTithi: 'ekadashi',
      );

      final map = event.toFirestore();
      expect(map['is4DayParayan'], true);
      expect(map['extraDayTithi'], 'ekadashi');

      final doc = FakeDocumentSnapshot('test_4day', map);
      final deserialized = ParayanEvent.fromFirestore(doc);
      expect(deserialized.is4DayParayan, true);
      expect(deserialized.extraDayTithi, 'ekadashi');
    });

    test('getDatesForDayIndex maps tithi correct day offsets', () {
      final event = ParayanEvent(
        id: 'test_4day',
        titleEn: '4-Day Event',
        titleMr: '४-दिवस इव्हेंट',
        descriptionEn: 'Desc En',
        descriptionMr: 'Desc Mr',
        type: ParayanType.threeDay,
        startDate: startDate,
        endDate: endDate,
        status: 'ongoing',
        reminderTimes: ['20:00'],
        createdAt: createdAt,
        groupId: 'test_group',
        timezone: 'Asia/Kolkata',
        is4DayParayan: true,
        extraDayTithi: 'ekadashi',
      );

      // Ekadashi spans offset 1 and 2
      final dates0 = event.getDatesForDayIndex(0); // Day 1: Alandi (offset 0)
      final dates1 = event.getDatesForDayIndex(1); // Day 2: Pune (offset 1 & 2)
      final dates2 = event.getDatesForDayIndex(2); // Day 3: Saswad (offset 3)

      expect(dates0.length, 1);
      expect(dates0[0], startDate);
      expect(dates1.length, 2);
      expect(dates1[0], startDate.add(const Duration(days: 1)));
      expect(dates1[1], startDate.add(const Duration(days: 2)));
      expect(dates2.length, 1);
      expect(dates2[0], startDate.add(const Duration(days: 3)));
    });

    test(
      'getFormattedDateHeaderForDayIndex returns correct string representation',
      () {
        final event = ParayanEvent(
          id: 'test_4day',
          titleEn: '4-Day Event',
          titleMr: '४-दिवस इव्हेंट',
          descriptionEn: 'Desc En',
          descriptionMr: 'Desc Mr',
          type: ParayanType.threeDay,
          startDate: DateTime.utc(2026, 7, 12),
          endDate: DateTime.utc(2026, 7, 16),
          status: 'ongoing',
          reminderTimes: ['20:00'],
          createdAt: createdAt,
          groupId: 'test_group',
          timezone: 'Asia/Kolkata',
          is4DayParayan: true,
          extraDayTithi: 'ekadashi',
        );

        expect(event.getFormattedDateHeaderForDayIndex(0, 'en', ' & '), 'July 12');
        expect(
          event.getFormattedDateHeaderForDayIndex(1, 'en', ' & '),
          'July 13 & July 14',
        );
        expect(
          event.getFormattedDateHeaderForDayIndex(1, 'mr', ' आणि '),
          '१३ जुलै आणि १४ जुलै',
        );
        expect(event.getFormattedDateHeaderForDayIndex(2, 'en', ' & '), 'July 15');
      },
    );
  });
}
