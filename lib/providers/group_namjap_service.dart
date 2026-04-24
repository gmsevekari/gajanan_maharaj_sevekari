import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_event.dart';
import 'package:gajanan_maharaj_sevekari/models/group_namjap_participant.dart';
import 'package:intl/intl.dart';

class GroupNamjapService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  GroupNamjapService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String eventsCollection = 'group_namjap_events';
  static const String participantsSubcollection = 'participants';

  /// Fetch all upcoming and ongoing group namjaps for this specific group.
  Stream<List<GroupNamjapEvent>> getActiveEvents(String groupId) {
    return _firestore
        .collection(eventsCollection)
        .where('groupId', isEqualTo: groupId)
        .where('status', whereIn: ['upcoming', 'ongoing', 'enrolling'])
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupNamjapEvent.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Fetch all completed group namjaps for this specific group.
  Stream<List<GroupNamjapEvent>> getCompletedEvents(String groupId) {
    return _firestore
        .collection(eventsCollection)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'completed')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupNamjapEvent.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get a stream of a specific event.
  Stream<GroupNamjapEvent?> getEventStream(String eventId) {
    return _firestore.collection(eventsCollection).doc(eventId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        return GroupNamjapEvent.fromMap(snapshot.id, snapshot.data()!);
      },
    );
  }

  /// Get a stream of a specific participant's progress.
  Stream<GroupNamjapParticipant?> getParticipantStream(
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
          return GroupNamjapParticipant.fromMap(snapshot.data()!);
        });
  }

  /// Get a stream of the number of participants in an event.
  Stream<int> getParticipantsCountStream(String eventId) {
    return _firestore
        .collection(eventsCollection)
        .doc(eventId)
        .collection(participantsSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a new event.
  Future<void> createEvent(GroupNamjapEvent event) async {
    await _firestore
        .collection(eventsCollection)
        .doc(event.id)
        .set(event.toMap());
  }

  /// Join an event if the code matches.
  Future<bool> joinEvent({
    required String eventId,
    required String joinCode,
    required GroupNamjapParticipant participant,
  }) async {
    final docRefs = _firestore.collection(eventsCollection).doc(eventId);
    final eventSnapshot = await docRefs.get();

    if (!eventSnapshot.exists) return false;
    final data = eventSnapshot.data()!;

    if (data['joinCode'] != joinCode) {
      return false; // Code mismatch
    }

    // Join logic success, insert into participants
    final participantId = '${participant.deviceId}_${participant.memberName}'
        .replaceAll(' ', '_');

    await docRefs
        .collection(participantsSubcollection)
        .doc(participantId)
        .set(participant.toMap());

    return true;
  }

  /// Atomically submit counts to both the user scope and global scope to natively bypass concurrent race conditions.
  Future<void> submitNamjapCount({
    required String eventId,
    required String deviceId,
    required String memberName,
    required int countToSubmit,
  }) async {
    if (countToSubmit <= 0) return;

    final participantId = '${deviceId}_$memberName'.replaceAll(' ', '_');
    final eventRef = _firestore.collection(eventsCollection).doc(eventId);
    final participantRef = eventRef
        .collection(participantsSubcollection)
        .doc(participantId);

    // We strictly map the time locally.
    final String localDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final batch = _firestore.batch();

    // 1. Increment global event counter
    batch.update(eventRef, {'totalCount': FieldValue.increment(countToSubmit)});

    // 2. Increment user counts
    batch.set(participantRef, {
      'totalCount': FieldValue.increment(countToSubmit),
      'dailyCounts': {localDateKey: FieldValue.increment(countToSubmit)},
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Check if a participant exists for this device.
  Future<GroupNamjapParticipant?> checkParticipation(
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
    return GroupNamjapParticipant.fromMap(querySnapshot.docs.first.data());
  }

  /// Delete participation for a specific participant.
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
