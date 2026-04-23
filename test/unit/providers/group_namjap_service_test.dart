import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GroupNamjapService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = GroupNamjapService(firestore: fakeFirestore);
  });

  group('GroupNamjapService tests', () {
    final testEvent = GroupNamjapEvent(
      id: 'event_1',
      nameEn: 'Event 1',
      nameMr: 'इव्हेंट १',
      sankalpEn: 'Sankalp 1',
      sankalpMr: 'संकल्प १',
      mantra: 'Mantra 1',
      targetCount: 1000,
      totalCount: 0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      status: 'ongoing',
      joinCode: '123456',
      groupId: 'group_1',
    );

    test('createEvent should add event to Firestore', () async {
      await service.createEvent(testEvent);
      final doc = await fakeFirestore
          .collection('group_namjap_events')
          .doc('event_1')
          .get();
      expect(doc.exists, true);
      expect(doc.data()?['name_en'], 'Event 1');
    });

    test(
      'getActiveEvents should return ongoing/upcoming/enrolling events',
      () async {
        await service.createEvent(testEvent); // ongoing
        await service.createEvent(
          testEvent.copyWith(id: 'event_2', status: 'enrolling'),
        );
        await service.createEvent(
          testEvent.copyWith(id: 'event_3', status: 'upcoming'),
        );
        await service.createEvent(
          testEvent.copyWith(id: 'event_4', status: 'completed'),
        );

        final events = await service.getActiveEvents('group_1').first;
        expect(events.length, 3);
        expect(events.any((e) => e.id == 'event_1'), true);
        expect(events.any((e) => e.id == 'event_2'), true);
        expect(events.any((e) => e.id == 'event_3'), true);
      },
    );

    test('joinEvent should return false if code mismatch', () async {
      await service.createEvent(testEvent);
      final participant = GroupNamjapParticipant(
        memberName: 'User 1',
        deviceId: 'device_1',
        phone: '1234567890',
        joinedAt: DateTime.now(),
        totalCount: 0,
      );

      final result = await service.joinEvent(
        eventId: 'event_1',
        joinCode: 'wrong_code',
        participant: participant,
      );

      expect(result, false);
    });

    test(
      'joinEvent should return true and add participant if code matches',
      () async {
        await service.createEvent(testEvent);
        final participant = GroupNamjapParticipant(
          memberName: 'User 1',
          deviceId: 'device_1',
          phone: '1234567890',
          joinedAt: DateTime.now(),
          totalCount: 0,
        );

        final result = await service.joinEvent(
          eventId: 'event_1',
          joinCode: '123456',
          participant: participant,
        );

        expect(result, true);
        final partDoc = await fakeFirestore
            .collection('group_namjap_events')
            .doc('event_1')
            .collection('participants')
            .doc('device_1_User_1')
            .get();
        expect(partDoc.exists, true);
      },
    );

    test(
      'submitNamjapCount should increment both event and participant counts',
      () async {
        await service.createEvent(testEvent);
        final participant = GroupNamjapParticipant(
          memberName: 'User 1',
          deviceId: 'device_1',
          phone: '1234567890',
          joinedAt: DateTime.now(),
          totalCount: 0,
        );
        await service.joinEvent(
          eventId: 'event_1',
          joinCode: '123456',
          participant: participant,
        );

        await service.submitNamjapCount(
          eventId: 'event_1',
          deviceId: 'device_1',
          memberName: 'User 1',
          countToSubmit: 108,
        );

        final eventDoc = await fakeFirestore
            .collection('group_namjap_events')
            .doc('event_1')
            .get();
        expect(eventDoc.data()?['totalCount'], 108);

        final partDoc = await fakeFirestore
            .collection('group_namjap_events')
            .doc('event_1')
            .collection('participants')
            .doc('device_1_User_1')
            .get();
        expect(partDoc.data()?['totalCount'], 108);
        expect(partDoc.data()?['dailyCounts'], isNotNull);
      },
    );

    test('checkParticipation should return participant if exists', () async {
      await service.createEvent(testEvent);
      final participant = GroupNamjapParticipant(
        memberName: 'User 1',
        deviceId: 'device_1',
        phone: '1234567890',
        joinedAt: DateTime.now(),
        totalCount: 0,
      );
      await service.joinEvent(
        eventId: 'event_1',
        joinCode: '123456',
        participant: participant,
      );

      final result = await service.checkParticipation('event_1', 'device_1');
      expect(result, isNotNull);
      expect(result?.memberName, 'User 1');
    });
  });
}
