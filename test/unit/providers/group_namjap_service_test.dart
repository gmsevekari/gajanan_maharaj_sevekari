import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_namjap_service.dart';
import 'package:intl/intl.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GroupNamjapService service;

  const groupId = 'group1';
  const eventId = 'event1';
  const deviceId = 'device1';
  const memberName = 'John Doe';
  const phone = '1234567890';
  final participantId = '${deviceId}_$memberName'.replaceAll(' ', '_');

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = GroupNamjapService(firestore: fakeFirestore);
  });

  group('GroupNamjapService - Fetching', () {
    test('getActiveEvents returns filtered events', () async {
      await fakeFirestore.collection('group_namjap_events').doc('e1').set({
        'groupId': groupId,
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      await fakeFirestore.collection('group_namjap_events').doc('e2').set({
        'groupId': groupId,
        'status': 'completed',
        'name_en': 'Event 2',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final events = await service.getActiveEvents(groupId).first;
      expect(events.length, 1);
      expect(events.first.id, 'e1');
    });

    test('getCompletedEvents returns filtered events', () async {
      await fakeFirestore.collection('group_namjap_events').doc('e1').set({
        'groupId': groupId,
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
      await fakeFirestore.collection('group_namjap_events').doc('e2').set({
        'groupId': groupId,
        'status': 'completed',
        'name_en': 'Event 2',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final events = await service.getCompletedEvents(groupId).first;
      expect(events.length, 1);
      expect(events.first.id, 'e2');
    });

    test('getEventStream returns correct event', () async {
      await fakeFirestore.collection('group_namjap_events').doc(eventId).set({
        'groupId': groupId,
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final event = await service.getEventStream(eventId).first;
      expect(event?.id, eventId);
      expect(event?.nameEn, 'Event 1');
    });

    test('getParticipantStream returns correct participant', () async {
      await fakeFirestore
          .collection('group_namjap_events')
          .doc(eventId)
          .collection('participants')
          .doc(participantId)
          .set({
        'deviceId': deviceId,
        'memberName': memberName,
        'phone': phone,
        'totalCount': 100,
        'joinedAt': Timestamp.now(),
      });

      final participant = await service
          .getParticipantStream(eventId, deviceId, memberName)
          .first;
      expect(participant?.memberName, memberName);
      expect(participant?.totalCount, 100);
    });
  });

  group('GroupNamjapService - Actions', () {
    test('joinEvent succeeds with correct code', () async {
      await fakeFirestore.collection('group_namjap_events').doc(eventId).set({
        'groupId': groupId,
        'joinCode': '1234',
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final participant = GroupNamjapParticipant(
        deviceId: deviceId,
        memberName: memberName,
        phone: phone,
        joinedAt: DateTime.now(),
        totalCount: 0,
      );

      final success = await service.joinEvent(
        eventId: eventId,
        joinCode: '1234',
        participant: participant,
      );

      expect(success, isTrue);

      final doc = await fakeFirestore
          .collection('group_namjap_events')
          .doc(eventId)
          .collection('participants')
          .doc(participantId)
          .get();
      expect(doc.exists, isTrue);
    });

    test('joinEvent fails with wrong code', () async {
      await fakeFirestore.collection('group_namjap_events').doc(eventId).set({
        'groupId': groupId,
        'joinCode': '1234',
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      final participant = GroupNamjapParticipant(
        deviceId: deviceId,
        memberName: memberName,
        phone: phone,
        joinedAt: DateTime.now(),
        totalCount: 0,
      );

      final success = await service.joinEvent(
        eventId: eventId,
        joinCode: 'wrong',
        participant: participant,
      );

      expect(success, isFalse);
    });

    test('submitNamjapCount increments global and user counts', () async {
      await fakeFirestore.collection('group_namjap_events').doc(eventId).set({
        'groupId': groupId,
        'totalCount': 500,
        'status': 'ongoing',
        'name_en': 'Event 1',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore
          .collection('group_namjap_events')
          .doc(eventId)
          .collection('participants')
          .doc(participantId)
          .set({
        'deviceId': deviceId,
        'memberName': memberName,
        'phone': phone,
        'totalCount': 100,
        'joinedAt': Timestamp.now(),
      });

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await service.submitNamjapCount(
        eventId: eventId,
        deviceId: deviceId,
        memberName: memberName,
        countToSubmit: 50,
      );

      // Verify global count
      final eventDoc =
          await fakeFirestore.collection('group_namjap_events').doc(eventId).get();
      expect(eventDoc.data()?['totalCount'], 550);

      // Verify user count
      final participantDoc = await fakeFirestore
          .collection('group_namjap_events')
          .doc(eventId)
          .collection('participants')
          .doc(participantId)
          .get();
      expect(participantDoc.data()?['totalCount'], 150);
      expect(participantDoc.data()?['dailyCounts'][today], 50);
    });
  });
}
