import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_event.dart';
import 'package:gajanan_maharaj_sevekari/models/vaari_participant.dart';

class VaariService {
  final FirebaseFirestore _firestore;

  VaariService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String eventsCollection = 'vaari_events';
  static const String participantsSubcollection = 'participants';

  /// Distance covered per step when distance unit is kilometres.
  static const double _kmPerStep = 0.0008;

  /// Distance covered per step when distance unit is miles.
  static const double _milesPerStep = 0.0005; // ~2,000 steps per mile average

  /// Sanitised participant document ID — strips slashes and collapses spaces.
  String _getParticipantId(String deviceId, String memberName) {
    final safeDevice = deviceId.replaceAll('/', '_');
    final safeName = memberName.replaceAll('/', '_').replaceAll(' ', '_');
    return '${safeDevice}_$safeName';
  }

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
        final data = snapshot.data();
        if (data == null) return null;
        return VaariEvent.fromMap(snapshot.id, data);
      },
    );
  }

  Stream<VaariParticipant?> getParticipantStream(
    String eventId,
    String deviceId,
    String memberName,
  ) {
    final participantId = _getParticipantId(deviceId, memberName);
    return _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .doc(participantId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          final data = snapshot.data();
          if (data == null) return null;
          return VaariParticipant.fromMap(data);
        });
  }

  Stream<List<VaariParticipant>> getAllParticipants(String eventId) {
    return _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VaariParticipant.fromMap(doc.data()))
              .toList();
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
    try {
      await _firestore
          .collection(eventsCollection)
          .doc(event.id)
          .set(event.toMap());
    } on FirebaseException catch (e) {
      debugPrint('VaariService.createEvent Firestore error: $e');
      rethrow;
    }
  }

  Future<bool> joinEvent({
    required String eventId,
    required String joinCode,
    required VaariParticipant participant,
  }) async {
    try {
      final docRef = _firestore.collection(eventsCollection).doc(eventId);
      final eventSnapshot = await docRef.get();

      if (!eventSnapshot.exists) return false;
      final data = eventSnapshot.data();
      if (data == null) return false;

      if (data['joinCode'] != joinCode) {
        return false;
      }

      final participantId = _getParticipantId(
        participant.deviceId,
        participant.memberName,
      );

      await docRef
          .collection(participantsSubcollection)
          .doc(participantId)
          .set(participant.toMap());

      return true;
    } on FirebaseException catch (e) {
      debugPrint('VaariService.joinEvent Firestore error: $e');
      rethrow;
    }
  }

  Future<void> submitSteps({
    required String eventId,
    required String deviceId,
    required String memberName,
    required int stepsToSubmit,
    double? distanceToSubmit,
  }) async {
    if (stepsToSubmit <= 0) return;

    // Reject negative/zero distances when explicitly provided
    if (distanceToSubmit != null && distanceToSubmit <= 0) return;

    try {
      final eventRef = _firestore.collection(eventsCollection).doc(eventId);
      final eventSnapshot = await eventRef.get();
      if (!eventSnapshot.exists) return;

      final eventData = eventSnapshot.data();
      if (eventData == null) return;

      final unit = eventData['distanceUnit'] ?? 'km';

      final double distance =
          distanceToSubmit ??
          (stepsToSubmit * (unit == 'mi' ? _milesPerStep : _kmPerStep));

      final participantId = _getParticipantId(deviceId, memberName);
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
    } on FirebaseException catch (e) {
      debugPrint('VaariService.submitSteps Firestore error: $e');
      rethrow;
    }
  }

  Future<VaariParticipant?> checkParticipation(
    String eventId,
    String deviceId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .collection(participantsSubcollection)
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return VaariParticipant.fromMap(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      debugPrint('VaariService.checkParticipation Firestore error: $e');
      rethrow;
    }
  }

  Future<void> deleteParticipation({
    required String eventId,
    required String deviceId,
    required String memberName,
  }) async {
    try {
      final participantId = _getParticipantId(deviceId, memberName);
      await _firestore
          .collection(eventsCollection)
          .doc(eventId)
          .collection(participantsSubcollection)
          .doc(participantId)
          .delete();
    } on FirebaseException catch (e) {
      debugPrint('VaariService.deleteParticipation Firestore error: $e');
      rethrow;
    }
  }
}
