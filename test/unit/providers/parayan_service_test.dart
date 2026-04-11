import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;
  late MockFirebaseFunctions mockFunctions;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    mockFunctions = MockFirebaseFunctions();

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('ParayanService', () {
    test('exists should return true if document exists', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions, // This will fail because functions is not in constructor yet
      );
      when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);

      final result = await service.exists('test_id');

      expect(result, true);
      verify(() => mockFirestore.collection('parayan_events')).called(1);
    });

    test('createEvent should call set on firestore', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );
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

    test('claimAllocation should call claimParayanAllocation cloud function', () async {
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();

      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );

      when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);
      when(() => mockResult.data).thenReturn({
        'status': 'SUCCESS',
        'participants': [
          {'name': 'Test User', 'assignedAdhyays': [1, 2, 3]}
        ],
      });

      final result = await service.claimAllocation(
        eventId: 'event_123',
        phone: '+911234567890',
        deviceId: 'device_abc',
      );

      expect(result['status'], 'SUCCESS');
      expect(result['participants'].length, 1);
      verify(() => mockFunctions.httpsCallable('claimParayanAllocation')).called(1);
      verify(() => mockCallable.call({
            'eventId': 'event_123',
            'phone': '+911234567890',
            'deviceId': 'device_abc',
            'overwrite': false,
          })).called(1);
    });
  });
}
