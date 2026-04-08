import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('ParayanService', () {
    test('exists should return true if document exists', () async {
      final service = ParayanService(firestore: mockFirestore);
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);

      final result = await service.exists('test_id');

      expect(result, true);
      verify(() => mockFirestore.collection('parayan_events')).called(1);
    });

    test('createEvent should call set on firestore', () async {
      final service = ParayanService(firestore: mockFirestore);
      final event = ParayanEvent(
        id: 'new_id',
        titleEn: 'Test',
        titleMr: 'चाचणी',
        descriptionEn: '',
        descriptionMr: '',
        type: ParayanType.oneDay,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        status: 'upcoming',
        reminderTimes: [],
        createdAt: DateTime.now(),
        groupId: 'g1',
      );

      when(() => mockDocument.set(any())).thenAnswer((_) async => {});

      await service.createEvent(event);

      verify(() => mockDocument.set(any())).called(1);
    });
  });
}
