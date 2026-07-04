import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/vaari_service.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';
import '../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Timestamp(0, 0));
    registerFallbackValue(MockWriteBatch());
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(GetOptions());
    registerFallbackValue(SetOptions(merge: true));
  });

  late MockFirestore mockFirestore;
  late MockCollectionReference mockEventsCollection;
  late MockCollectionReference mockParticipantsCollection;
  late MockDocumentReference mockEventDoc;
  late MockDocumentReference mockParticipantDoc;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestore = MockFirestore();
    mockEventsCollection = MockCollectionReference();
    mockParticipantsCollection = MockCollectionReference();
    mockEventDoc = MockDocumentReference();
    mockParticipantDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    // Default wiring
    when(() => mockFirestore.collection(any())).thenReturn(mockEventsCollection);
    when(() => mockEventsCollection.doc(any())).thenReturn(mockEventDoc);
    when(() => mockEventsCollection.where(
          any(),
          isEqualTo: any(named: 'isEqualTo'),
          whereIn: any(named: 'whereIn'),
        )).thenReturn(mockEventsCollection);
    when(() => mockEventsCollection.orderBy(
          any(),
          descending: any(named: 'descending'),
        )).thenReturn(mockEventsCollection);
    when(() => mockEventsCollection.orderBy(any())).thenReturn(mockEventsCollection);
    when(() => mockEventsCollection.snapshots()).thenAnswer((_) => Stream.value(MockQuerySnapshot()));

    when(() => mockEventDoc.collection(any())).thenReturn(mockParticipantsCollection);
    when(() => mockEventDoc.get()).thenAnswer((_) async => mockSnapshot);
    when(() => mockEventDoc.update(any())).thenAnswer((_) async => {});
    when(() => mockEventDoc.set(any())).thenAnswer((_) async => {});
    when(() => mockEventDoc.snapshots()).thenAnswer((_) => Stream.value(mockSnapshot));

    when(() => mockParticipantsCollection.doc(any())).thenReturn(mockParticipantDoc);
    when(() => mockParticipantsCollection.where(
          any(),
          isEqualTo: any(named: 'isEqualTo'),
        )).thenReturn(mockParticipantsCollection);
    when(() => mockParticipantsCollection.limit(any())).thenReturn(mockParticipantsCollection);
    when(() => mockParticipantsCollection.snapshots()).thenAnswer((_) => Stream.value(MockQuerySnapshot()));
    when(() => mockParticipantsCollection.get()).thenAnswer((_) async => MockQuerySnapshot());

    when(() => mockParticipantDoc.get()).thenAnswer((_) async => mockSnapshot);
    when(() => mockParticipantDoc.update(any())).thenAnswer((_) async => {});
    when(() => mockParticipantDoc.set(any())).thenAnswer((_) async => {});
    when(() => mockParticipantDoc.delete()).thenAnswer((_) async => {});

    when(() => mockSnapshot.exists).thenReturn(true);
    when(() => mockSnapshot.id).thenReturn('vaari_1');
    when(() => mockSnapshot.data()).thenReturn({
      'createdAt': Timestamp.now(),
      'endDate': Timestamp.now(),
      'groupId': 'gajanan_gunjan',
      'joinCode': '123456',
      'name_en': 'Weekly Vaari',
      'name_mr': 'साप्ताहिक वारी',
      'description_en': 'Walk',
      'description_mr': 'चाला',
      'startDate': Timestamp.now(),
      'status': 'ongoing',
      'timezone': 'Asia/Kolkata',
      'totalSteps': 10000,
      'totalDistance': 8.0,
      'distanceUnit': 'km',
    });
  });

  group('VaariService Tests', () {
    test('VaariService constructor uses default Firestore instance if none provided', () {
      expect(() => VaariService(), throwsA(isA<FirebaseException>()));
    });

    test('getActiveEvents and getCompletedEvents build queries correctly', () async {
      final service = VaariService(firestore: mockFirestore);
      
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.id).thenReturn('vaari_1');
      when(() => mockDocSnapshot.data()).thenReturn({
        'createdAt': Timestamp.now(),
        'endDate': Timestamp.now(),
        'groupId': 'gajanan_gunjan',
        'joinCode': '123456',
        'name_en': 'Weekly Vaari',
        'name_mr': 'साप्ताहिक वारी',
        'description_en': 'Walk',
        'description_mr': 'चाला',
        'startDate': Timestamp.now(),
        'status': 'ongoing',
        'timezone': 'Asia/Kolkata',
        'totalSteps': 10000,
        'totalDistance': 8.0,
        'distanceUnit': 'km',
      });

      when(() => mockEventsCollection.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final activeEvents = await service.getActiveEvents('gajanan_gunjan').first;
      final completedEvents = await service.getCompletedEvents('gajanan_gunjan').first;

      expect(activeEvents, hasLength(1));
      expect(completedEvents, hasLength(1));
    });

    test('getEventStream returns correct model stream', () async {
      final service = VaariService(firestore: mockFirestore);
      final stream = service.getEventStream('vaari_1');
      expect(stream, isNotNull);

      final event = await stream.first;
      expect(event?.id, 'vaari_1');
    });

    test('getParticipantStream returns correct model stream', () async {
      final service = VaariService(firestore: mockFirestore);
      
      final mockPartSnapshot = MockDocumentSnapshot();
      when(() => mockPartSnapshot.exists).thenReturn(true);
      when(() => mockPartSnapshot.data()).thenReturn({
        'memberName': 'Abhishek',
        'deviceId': 'device_1',
        'phone': '123',
        'joinedAt': Timestamp.now(),
        'totalSteps': 5000,
        'totalDistance': 4.0,
      });
      when(() => mockParticipantDoc.snapshots()).thenAnswer((_) => Stream.value(mockPartSnapshot));

      final stream = service.getParticipantStream('vaari_1', 'device_1', 'Abhishek');
      expect(stream, isNotNull);

      final participant = await stream.first;
      expect(participant?.memberName, 'Abhishek');
    });

    test('getParticipantsCountStream returns count stream', () async {
      final service = VaariService(firestore: mockFirestore);
      final stream = service.getParticipantsCountStream('vaari_1');
      expect(stream, isNotNull);
    });

    test('createEvent successfully sets document', () async {
      final service = VaariService(firestore: mockFirestore);
      final event = VaariEvent(
        id: 'vaari_1',
        createdAt: DateTime.now(),
        endDate: DateTime.now(),
        groupId: 'gajanan_gunjan',
        joinCode: '123',
        nameEn: 'E',
        nameMr: 'M',
        descriptionEn: 'E',
        descriptionMr: 'M',
        startDate: DateTime.now(),
        status: 'ongoing',
        timezone: 'Asia/Kolkata',
        totalSteps: 0,
        totalDistance: 0.0,
        distanceUnit: 'km',
      );

      await service.createEvent(event);
      verify(() => mockEventDoc.set(any())).called(1);
    });

    test('joinEvent checks code and writes participant', () async {
      final service = VaariService(firestore: mockFirestore);
      final participant = VaariParticipant(
        memberName: 'Abhishek',
        deviceId: 'device_1',
        phone: '123',
        joinedAt: DateTime.now(),
        totalSteps: 0,
        totalDistance: 0.0,
      );

      final result = await service.joinEvent(
        eventId: 'vaari_1',
        joinCode: '123456',
        participant: participant,
      );

      expect(result, isTrue);
    });

    test('submitSteps with provided distance uses provided value', () async {
      final service = VaariService(firestore: mockFirestore);
      final mockBatch = MockWriteBatch();
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
      when(() => mockBatch.commit()).thenAnswer((_) async => {});
      when(() => mockBatch.update(any(), any())).thenReturn(mockBatch);
      when(() => mockBatch.set(any(), any(), any())).thenReturn(mockBatch);

      await service.submitSteps(
        eventId: 'vaari_1',
        deviceId: 'device_1',
        memberName: 'Abhishek',
        stepsToSubmit: 5000,
        distanceToSubmit: 4.5,
      );

      verify(() => mockBatch.commit()).called(1);
    });

    test('submitSteps with null distance computes distance based on unit', () async {
      final service = VaariService(firestore: mockFirestore);
      final mockBatch = MockWriteBatch();
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
      when(() => mockBatch.commit()).thenAnswer((_) async => {});
      when(() => mockBatch.update(any(), any())).thenReturn(mockBatch);
      when(() => mockBatch.set(any(), any(), any())).thenReturn(mockBatch);

      // Unit is 'km' from stub, so 5000 steps * 0.0008 = 4.0 km
      await service.submitSteps(
        eventId: 'vaari_1',
        deviceId: 'device_1',
        memberName: 'Abhishek',
        stepsToSubmit: 5000,
      );

      verify(() => mockBatch.commit()).called(1);
    });

    test('checkParticipation returns participant if exists', () async {
      final service = VaariService(firestore: mockFirestore);
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockParticipantsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.data()).thenReturn({
        'memberName': 'Abhishek',
        'deviceId': 'device_1',
        'phone': '123',
        'joinedAt': Timestamp.now(),
        'totalSteps': 0,
        'totalDistance': 0.0,
      });

      final result = await service.checkParticipation('vaari_1', 'device_1');
      expect(result?.memberName, 'Abhishek');
    });

    test('deleteParticipation removes participant document', () async {
      final service = VaariService(firestore: mockFirestore);
      await service.deleteParticipation(
        eventId: 'vaari_1',
        deviceId: 'device_1',
        memberName: 'Abhishek',
      );

      verify(() => mockParticipantDoc.delete()).called(1);
    });
  });
}
