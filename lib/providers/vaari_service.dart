import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';

class VaariService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  VaariService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String eventsCollection = 'vaari_events';
  static const String participantsSubcollection = 'participants';

  Stream<List<VaariEvent>> getActiveEvents(String groupId) {
    return _firestore
        .collection(eventsCollection)
        .where('groupId', isEqualTo: groupId)
        .where('status', whereIn: ['upcoming', 'ongoing', 'enrolling'])
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VaariEvent.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<VaariEvent>> getCompletedEvents(String groupId) {
    return _firestore
        .collection(eventsCollection)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'completed')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VaariEvent.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<VaariEvent?> getEventStream(String eventId) {
    return _firestore.collection(eventsCollection).doc(eventId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        return VaariEvent.fromMap(snapshot.id, snapshot.data()!);
      },
    );
  }

  Stream<VaariParticipant?> getParticipantStream(
    String eventId,
    String deviceId,
    String memberName,
  ) {
    final participantId = '${deviceId}_$memberName'.replaceAll(' ', '_');
    return _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .doc(participantId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return VaariParticipant.fromMap(snapshot.data()!);
        });
  }

  Stream<int> getParticipantsCountStream(String eventId) {
    return _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> createEvent(VaariEvent event) async {
    await _firestore
        .collection(eventsCollection)
        .doc(event.id)
        .set(event.toMap());
  }

  Future<bool> joinEvent({
    required String eventId,
    required String joinCode,
    required VaariParticipant participant,
  }) async {
    final docRef = _firestore.collection(eventsCollection).doc(eventId);
    final eventSnapshot = await docRef.get();

    if (!eventSnapshot.exists) return false;
    final data = eventSnapshot.data()!;

    if (data['joinCode'] != joinCode) {
      return false;
    }

    final participantId = '${participant.deviceId}_${participant.memberName}'
        .replaceAll(' ', '_');

    await docRef
        .collection(participantsSubcollection)
        .doc(participantId)
        .set(participant.toMap());

    return true;
  }

  Future<void> submitSteps({
    required String eventId,
    required String deviceId,
    required String memberName,
    required int stepsToSubmit,
    double? distanceToSubmit,
  }) async {
    if (stepsToSubmit <= 0) return;

    final eventRef = _firestore.collection(eventsCollection).doc(eventId);
    final eventSnapshot = await eventRef.get();
    if (!eventSnapshot.exists) return;

    final eventData = eventSnapshot.data()!;
    final unit = eventData['distanceUnit'] ?? 'km';

    double distance = distanceToSubmit ??
        (stepsToSubmit * (unit == 'km' ? 0.0008 : 0.0005));

    final participantId = '${deviceId}_$memberName'.replaceAll(' ', '_');
    final participantRef = eventRef
        .collection(participantsSubcollection)
        .doc(participantId);

    final batch = _firestore.batch();

    // Increment global counters
    batch.update(eventRef, {
      'totalSteps': FieldValue.increment(stepsToSubmit),
      'totalDistance': FieldValue.increment(distance),
    });

    // Increment user counters
    batch.set(participantRef, {
      'totalSteps': FieldValue.increment(stepsToSubmit),
      'totalDistance': FieldValue.increment(distance),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<VaariParticipant?> checkParticipation(
    String eventId,
    String deviceId,
  ) async {
    final querySnapshot = await _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return VaariParticipant.fromMap(querySnapshot.docs.first.data());
  }

  Future<void> deleteParticipation({
    required String eventId,
    required String deviceId,
    required String memberName,
  }) async {
    final participantId = '${deviceId}_$memberName'.replaceAll(' ', '_');
    await _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .doc(participantId)
        .delete();
  }
}
