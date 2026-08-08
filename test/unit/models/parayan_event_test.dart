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

  group('ParayanEvent Unit Tests', () {
    final startDate = DateTime(2024, 5, 1);
    final endDate = DateTime(2024, 5, 3);
    final createdAt = DateTime(2024, 4, 1);

    test('toFirestore and fromFirestore serialize all fields including manualPingRequestedAt', () {
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
        manualPingRequestedAt: DateTime(2024, 4, 2),
        createdAt: createdAt,
        groupId: 'test_group',
        timezone: 'Asia/Kolkata',
      );

      final map = event.toFirestore();

      expect(map['title_en'], 'Test Event');
      expect(map['type'], 'threeDay');
      expect(map['startDate'], isA<Timestamp>());
      expect((map['startDate'] as Timestamp).toDate(), startDate);
      expect(map['manualPingRequestedAt'], isA<Timestamp>());

      final doc = FakeDocumentSnapshot('test_id', map);
      final deserialized = ParayanEvent.fromFirestore(doc);
      expect(deserialized.id, equals('test_id'));
      expect(deserialized.manualPingRequestedAt, equals(DateTime(2024, 4, 2)));
    });

    test('getDatesForDayIndex handles dashami and dwadashi tithis', () {
      final dashamiEvent = ParayanEvent(
        id: 'd1',
        titleEn: 'Dashami Event',
        titleMr: 'दशमी इव्हेंट',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.threeDay,
        startDate: startDate,
        endDate: endDate,
        status: 'ongoing',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: '',
        is4DayParayan: true,
        extraDayTithi: 'dashami',
      );

      expect(dashamiEvent.getDatesForDayIndex(0).length, equals(2));
      expect(dashamiEvent.getDatesForDayIndex(1).length, equals(1));
      expect(dashamiEvent.getDatesForDayIndex(2).length, equals(1));

      final dwadashiEvent = ParayanEvent(
        id: 'd2',
        titleEn: 'Dwadashi Event',
        titleMr: 'द्वादशी इव्हेंट',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.threeDay,
        startDate: startDate,
        endDate: endDate,
        status: 'ongoing',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: '',
        is4DayParayan: true,
        extraDayTithi: 'dwadashi',
      );

      expect(dwadashiEvent.getDatesForDayIndex(0).length, equals(1));
      expect(dwadashiEvent.getDatesForDayIndex(1).length, equals(1));
      expect(dwadashiEvent.getDatesForDayIndex(2).length, equals(2));
    });

    test('operator == and hashCode work accurately', () {
      final e1 = ParayanEvent(
        id: 'same',
        titleEn: 'T',
        titleMr: 'टी',
        descriptionEn: 'D',
        descriptionMr: 'डी',
        type: ParayanType.oneDay,
        startDate: startDate,
        endDate: endDate,
        status: 'upcoming',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: 'g',
      );

      final e2 = ParayanEvent(
        id: 'same',
        titleEn: 'T',
        titleMr: 'टी',
        descriptionEn: 'D',
        descriptionMr: 'डी',
        type: ParayanType.oneDay,
        startDate: startDate,
        endDate: endDate,
        status: 'upcoming',
        reminderTimes: [],
        createdAt: createdAt,
        groupId: 'g',
      );

      expect(e1 == e2, isTrue);
      expect(e1.hashCode, equals(e2.hashCode));
    });
  });
}
