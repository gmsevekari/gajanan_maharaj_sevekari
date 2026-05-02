import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/parayan_service.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Timestamp(0, 0));
    registerFallbackValue(MockWriteBatch());
    registerFallbackValue(MockDocumentReference());
    print('STARTING PHASE 2 STABLE SUITE VERIFICATION');
    registerFallbackValue(Timestamp(0, 0));
    registerFallbackValue(MockWriteBatch());
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(GetOptions()); // FIX: add fallback for GetOptions
  });

  late MockFirestore mockFirestore;
  late MockCollectionReference mockEventsCollection;
  late MockCollectionReference mockParticipantsCollection;
  late MockDocumentReference mockEventDoc;
  late MockDocumentReference mockParticipantDoc;
  late MockDocumentSnapshot mockSnapshot;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockCallableResult;

  setUp(() {
    mockFirestore = MockFirestore();
    mockEventsCollection = MockCollectionReference();
    mockParticipantsCollection = MockCollectionReference();
    mockEventDoc = MockDocumentReference();
    mockParticipantDoc = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockCallableResult = MockHttpsCallableResult();

    // Default wiring with BROAD matchers
    when(
      () => mockFirestore.collection(any()),
    ).thenReturn(mockEventsCollection);
    when(() => mockEventsCollection.doc(any())).thenReturn(mockEventDoc);
    when(
      () => mockEventsCollection.where(
        any(),
        isEqualTo: any(named: 'isEqualTo'),
        isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'),
      ),
    ).thenReturn(mockEventsCollection);
    when(
      () => mockEventsCollection.orderBy(
        any(),
        descending: any(named: 'descending'),
      ),
    ).thenReturn(mockEventsCollection);
    when(
      () => mockEventsCollection.orderBy(any()),
    ).thenReturn(mockEventsCollection);
    when(
      () => mockEventsCollection.get(any()),
    ).thenAnswer((_) async => MockQuerySnapshot());
    when(
      () => mockEventsCollection.get(),
    ).thenAnswer((_) async => MockQuerySnapshot());
    when(
      () => mockEventsCollection.snapshots(),
    ).thenAnswer((_) => Stream.value(MockQuerySnapshot()));

    when(
      () => mockEventDoc.collection(any()),
    ).thenReturn(mockParticipantsCollection);
    when(() => mockEventDoc.get()).thenAnswer((_) async => mockSnapshot);
    when(() => mockEventDoc.update(any())).thenAnswer((_) async => {});
    when(() => mockEventDoc.set(any())).thenAnswer((_) async => {});
    when(
      () => mockEventDoc.snapshots(),
    ).thenAnswer((_) => Stream.value(mockSnapshot));

    when(
      () => mockParticipantsCollection.doc(any()),
    ).thenReturn(mockParticipantDoc);
    when(
      () => mockParticipantsCollection.where(
        any(),
        isEqualTo: any(named: 'isEqualTo'),
      ),
    ).thenReturn(mockParticipantsCollection);
    when(
      () => mockParticipantsCollection.orderBy(
        any(),
        descending: any(named: 'descending'),
      ),
    ).thenReturn(mockParticipantsCollection);
    when(
      () => mockParticipantsCollection.orderBy(any()),
    ).thenReturn(mockParticipantsCollection);
    when(
      () => mockParticipantsCollection.get(any()),
    ).thenAnswer((_) async => MockQuerySnapshot());
    when(
      () => mockParticipantsCollection.get(),
    ).thenAnswer((_) async => MockQuerySnapshot());
    when(
      () => mockParticipantsCollection.snapshots(),
    ).thenAnswer((_) => Stream.value(MockQuerySnapshot()));

    when(() => mockParticipantDoc.get()).thenAnswer((_) async => mockSnapshot);
    when(() => mockParticipantDoc.update(any())).thenAnswer((_) async => {});
    when(() => mockParticipantDoc.set(any())).thenAnswer((_) async => {});

    when(() => mockSnapshot.exists).thenReturn(true);
    when(() => mockSnapshot.id).thenReturn('e1');
    when(() => mockSnapshot.data()).thenReturn({
      'id': 'e1',
      'title_en': 'E',
      'title_mr': 'E',
      'description_en': 'D',
      'description_mr': 'D',
      'type': 'oneDay',
      'status': 'upcoming',
      'groupId': 'g1',
      'startDate': Timestamp.now(),
      'endDate': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'reminderTimes': [],
    });

    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
    when(
      () => mockCallable.call(any()),
    ).thenAnswer((_) async => mockCallableResult);
    when(() => mockCallableResult.data).thenReturn({'status': 'SUCCESS'});

    SharedPreferences.setMockInitialValues({});
  });

  group('ParayanService Phase 2 Stable Suite', () {
    test('Basic Event Operations & Streams', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );
      expect(await service.exists('e1'), true);

      final event = ParayanEvent(
        id: 'e1',
        titleEn: 'T',
        titleMr: 'T',
        descriptionEn: 'D',
        descriptionMr: 'D',
        groupId: 'g1',
        type: ParayanType.oneDay,
        status: 'upcoming',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdAt: DateTime.now(),
        reminderTimes: [],
      );
      await service.createEvent(event);
      await service.updateEventStatus(event, 'allocated');
      await service.updateEventStatus(event, 'completed');

      final qs = MockQuerySnapshot();
      final edoc = MockQueryDocumentSnapshot();
      when(
        () => mockEventsCollection.snapshots(),
      ).thenAnswer((_) => Stream.value(qs));
      when(() => qs.docs).thenReturn([edoc]);
      when(() => edoc.id).thenReturn('e1');
      when(() => edoc.data()).thenReturn({
        'title_en': 'E',
        'title_mr': 'E',
        'description_en': 'D',
        'description_mr': 'D',
        'type': 'oneDay',
        'status': 'upcoming',
        'groupId': 'g1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'reminderTimes': [],
      });

      await service.getEventById('e1').first;
      await service.getActiveEvents('g1').first;
      await service.getAllEvents('g1').first;
    });

    test('Participant Management & Sorting', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );
      final mockBatch = MockWriteBatch();
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
      when(() => mockBatch.commit()).thenAnswer((_) async => {});

      final eqs = MockQuerySnapshot();
      when(
        () => mockParticipantsCollection.get(any()),
      ).thenAnswer((_) async => eqs);
      when(() => mockParticipantsCollection.get()).thenAnswer((_) async => eqs);
      when(() => eqs.docs).thenReturn([]);
      await service.enrollParticipants(
        eventId: 'e1',
        type: ParayanType.oneDay,
        deviceId: 'd1',
        names: ['P1'],
        phone: '123',
      );

      final pqs = MockQuerySnapshot();
      final pd1 = MockQueryDocumentSnapshot();
      final pd2 = MockQueryDocumentSnapshot();
      when(
        () => mockParticipantsCollection.snapshots(),
      ).thenAnswer((_) => Stream.value(pqs));
      when(() => pqs.docs).thenReturn([pd1, pd2]);
      final base = {
        'phone': '1',
        'deviceId': 'd1',
        'joinedAt': Timestamp.now(),
        'assignedAdhyays': [1],
      };
      when(() => pd1.id).thenReturn('a');
      when(
        () => pd1.data(),
      ).thenReturn({...base, 'name': 'A', 'globalIndex': 10});
      when(() => pd2.id).thenReturn('b');
      when(
        () => pd2.data(),
      ).thenReturn({...base, 'name': 'B', 'globalIndex': 5});
      final plist = await service.getParticipantsByDevice('e1', 'd1').first;
      expect(plist[0].name, 'B');

      final pdAll = MockQueryDocumentSnapshot();
      when(() => pdAll.id).thenReturn('p1');
      when(() => pdAll.data()).thenReturn({...base, 'name': 'P1'});
      when(() => pqs.docs).thenReturn([pdAll]);
      await service.getAllParticipants('e1').first;
    });

    test('Household & Enrollments', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );

      final hqs = MockQuerySnapshot();
      final hd1 = MockQueryDocumentSnapshot();
      // FIX: ensure get(any()) is stubbed
      when(
        () => mockParticipantsCollection.get(any()),
      ).thenAnswer((_) async => hqs);
      when(() => mockParticipantsCollection.get()).thenAnswer((_) async => hqs);
      when(() => hqs.docs).thenReturn([hd1]);
      when(() => hd1.id).thenReturn('m1');
      when(() => hd1.reference).thenReturn(mockParticipantDoc);
      final base = {
        'name': 'M1',
        'deviceId': 'd1',
        'phone': '1',
        'joinedAt': Timestamp.now(),
        'assignedAdhyays': [1],
      };
      when(() => hd1.data()).thenReturn({
        ...base,
        'completions': {'1': true},
      });

      await service.getHousehold('e1', 'd1');
      await service.updateMemberCompletion(
        eventId: 'e1',
        memberId: 'm1',
        dayIndex: 1,
        completed: true,
        deviceId: 'd1',
      );

      final eqs = MockQuerySnapshot();
      final edoc = MockQueryDocumentSnapshot();
      when(() => mockEventsCollection.get(any())).thenAnswer((_) async => eqs);
      when(() => mockEventsCollection.get()).thenAnswer((_) async => eqs);
      when(() => eqs.docs).thenReturn([edoc]);
      when(() => edoc.id).thenReturn('e1');
      when(() => edoc.data()).thenReturn({
        'id': 'e1',
        'title_en': 'E',
        'title_mr': 'E',
        'description_en': 'D',
        'description_mr': 'D',
        'type': 'oneDay',
        'status': 'upcoming',
        'groupId': 'g1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'reminderTimes': [],
      });

      await service.getMyActiveEnrollmentsWithHousehold('d1');
      await service.getAllMyEnrollments('d1');
    });

    test('Claim, Allocation & Delete', () async {
      final service = ParayanService(
        firestore: mockFirestore,
        functions: mockFunctions,
      );
      await service.claimAllocation(
        eventId: 'e1',
        phone: '123',
        deviceId: 'd1',
      );
      await service.allocateAdhyays('e1');

      final mockBatch = MockWriteBatch();
      final bqs = MockQuerySnapshot();
      final bdoc = MockQueryDocumentSnapshot();
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
      when(
        () => mockParticipantsCollection.get(any()),
      ).thenAnswer((_) async => bqs);
      when(() => mockParticipantsCollection.get()).thenAnswer((_) async => bqs);
      when(() => bqs.docs).thenReturn([bdoc]);
      when(() => bdoc.reference).thenReturn(mockParticipantDoc);
      when(() => mockBatch.delete(any())).thenReturn(mockBatch);
      when(() => mockBatch.commit()).thenAnswer((_) async => {});
      await service.deleteEnrollment('e1', 'd1');
    });
  });
}
