import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/utils/notification_service_helper.dart';
import 'package:flutter/foundation.dart';

class ParayanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _eventsRef => _db.collection('parayan_events');

  Future<void> createEvent(ParayanEvent event) async {
    await _eventsRef.doc(event.id).set(event.toFirestore());
  }

  // Update status of a Parayan Event
  Future<void> updateEventStatus(String eventId, String newStatus) async {
    await _eventsRef.doc(eventId).update({'status': newStatus});

    // If status changed to allocated, perform batch adhyay allocation
    if (newStatus == 'allocated') {
      await allocateAdhyays(eventId);
    } else if (newStatus == 'completed') {
      // Unsubscribe the current (admin) device as well
      if (!kIsWeb) {
        await NotificationServiceHelper.unsubscribeFromEventTopics(eventId);
      }
    }
  }

  // Get a single Parayan Event by ID
  Stream<ParayanEvent> getEventById(String eventId) {
    return _eventsRef
        .doc(eventId)
        .snapshots()
        .map((doc) => ParayanEvent.fromFirestore(doc));
  }

  // Get all active/upcoming events
  Stream<List<ParayanEvent>> getActiveEvents() {
    return _eventsRef
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => ParayanEvent.fromFirestore(doc))
              .toList();
          // Sort by startDate ascending (nearest first)
          events.sort((a, b) => a.startDate.compareTo(b.startDate));
          return events;
        });
  }

  // Get all events for stats
  Stream<List<ParayanEvent>> getAllEvents() {
    return _eventsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParayanEvent.fromFirestore(doc))
              .toList(),
        );
  }

  // Enrollment Logic (Household-based) - Optimized for restricted permissions
  Future<void> enrollParticipants({
    required String eventId,
    required ParayanType type,
    required String deviceId,
    required List<String> names,
    required String phone,
  }) async {
    final eventDoc = _eventsRef.doc(eventId);
    final participantsRef = eventDoc.collection('participants');

    // 1. Get current participant count OUTSIDE transaction if possible,
    // or just use a query if the event doc has restricted WRITE permissions.
    // We'll fetch all docs to count them accurately for allocation.
    final querySnapshot = await participantsRef.get();
    int currentTotal = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final members = data['members'] as Map<String, dynamic>? ?? {};
      currentTotal += members.length;
    }
    // 1. Get all existing members for this device to handle deletions
    final existingSnapshot = await participantsRef
        .where('deviceId', isEqualTo: deviceId)
        .get();
    final Map<String, String> existingDocIdsByName = {
      for (var doc in existingSnapshot.docs)
        doc.data()['memberName'] ?? doc.data()['name'] ?? '': doc.id,
    };

    final batch = _db.batch();

    // 2. Delete members that are no longer in the list
    for (var entry in existingDocIdsByName.entries) {
      if (!names.contains(entry.key)) {
        batch.delete(participantsRef.doc(entry.value));
      }
    }

    // 3. Add or update remaining members
    for (var name in names) {
      final docId =
          existingDocIdsByName[name] ??
          "${deviceId}_${name.replaceAll(RegExp(r'\s+'), '_')}";
      final memberDoc = await participantsRef.doc(docId).get();

      if (memberDoc.exists) {
        // preserve existing (or update phone if changed)
        batch.update(participantsRef.doc(docId), {'phone': phone});
        continue;
      }

      final member = ParayanMember(
        name: name,
        assignedAdhyays: [],
        completions: {},
        joinedAt: DateTime.now(),
        deviceId: deviceId,
        phone: phone,
      );

      batch.set(participantsRef.doc(docId), member.toMap());
    }

    await batch.commit();

    // NOTE: We are skipping the eventDoc 'joinedParticipants' update here
    // because standard users likely don't have WRITE permission on the event doc.
    // Dashboard and Tabs calculate the count dynamically using getAllParticipants().
  }

  Future<ParayanHousehold?> getHousehold(
    String eventId,
    String deviceId, {
    bool forceServer = false,
  }) async {
    final participantsRef = _eventsRef.doc(eventId).collection('participants');
    final snapshot = await participantsRef
        .where('deviceId', isEqualTo: deviceId)
        .get(
          GetOptions(
            source: forceServer ? Source.server : Source.serverAndCache,
          ),
        );

    if (snapshot.docs.isEmpty) return null;

    final members = <String, ParayanMember>{};
    String phone = '';
    DateTime earliestJoin = DateTime.now();

    for (var doc in snapshot.docs) {
      final member = ParayanMember.fromMap('', doc.data(), deviceId: deviceId);
      members[member.name] = member;
      if (member.phone != null && member.phone!.isNotEmpty) {
        phone = member.phone!;
      }
      if (member.joinedAt.isBefore(earliestJoin)) {
        earliestJoin = member.joinedAt;
      }
    }

    return ParayanHousehold(
      deviceId: deviceId,
      phone: phone,
      joinedAt: earliestJoin,
      members: members,
    );
  }

  Future<void> updateMemberCompletion({
    required String eventId,
    required String memberId,
    required int dayIndex,
    required bool completed,
    String? deviceId,
  }) async {
    final docRef = _eventsRef.doc(eventId).collection('participants').doc(memberId);

    await docRef.update({'completions.$dayIndex': completed});

    // Topic subscription logic for day-specific reminders
    if (kIsWeb || deviceId == null) return;
    try {
      // 1. Get all members for this device to check if everyone is done (Force latest from server)
      final household = await getHousehold(
        eventId,
        deviceId,
        forceServer: true,
      );
      if (household != null) {
        final allCompleted = household.members.values.every(
          (m) => m.completions[dayIndex.toString()] == true,
        );

        final topic = NotificationConstants.getParayanReminderTopic(
          eventId,
          dayIndex,
        );
        if (allCompleted) {
          debugPrint(
            'Unsubscribing from $topic - All household members completed Day $dayIndex.',
          );
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        } else {
          final prefs = await SharedPreferences.getInstance();
          final remindersEnabled =
              prefs.getBool(NotificationConstants.parayanRemindersPrefKey) ??
              true;
          if (remindersEnabled) {
            await FirebaseMessaging.instance.subscribeToTopic(topic);
          }
        }
      }
    } catch (e) {
      // Silently ignore topic errors
    }
  }

  // Get participants (members) associated with a specific device
  Stream<List<ParayanMember>> getParticipantsByDevice(
    String eventId,
    String deviceId,
  ) {
    return _eventsRef
        .doc(eventId)
        .collection('participants')
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs
              .map(
                (doc) => ParayanMember.fromMap(doc.data()['name'] ?? '', {
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList();

          // Sort members for consistent order in MyAllocationTab
          members.sort((a, b) {
            final aIdx = a.globalIndex ?? -1;
            final bIdx = b.globalIndex ?? -1;
            if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);

            final aFirst = a.assignedAdhyays.isNotEmpty
                ? a.assignedAdhyays.first
                : 0;
            final bFirst = b.assignedAdhyays.isNotEmpty
                ? b.assignedAdhyays.first
                : 0;
            return aFirst.compareTo(bFirst);
          });
          return members;
        });
  }

  // Get all individual members for an event (Public Table)
  Stream<List<ParayanMember>> getAllParticipants(String eventId) {
    return _eventsRef
        .doc(eventId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ParayanMember.fromMap(doc.data()['name'] ?? '', {
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList();
        });
  }

  // Perform batch adhyay allocation for all participants
  Future<void> allocateAdhyays(String eventId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'allocateParayanAdhyays',
      );
      await callable.call({'eventId': eventId});
    } catch (e) {
      rethrow;
    }
  }

  // Get all active enrollments for a specific device
  Future<List<Map<String, dynamic>>> getMyActiveEnrollmentsWithHousehold(
    String deviceId,
  ) async {
    final querySnapshot = await _eventsRef
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .get();

    final List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      final household = await getHousehold(doc.id, deviceId);
      if (household != null) {
        results.add({
          'event': ParayanEvent.fromFirestore(doc),
          'household': household,
        });
      }
    }

    return results;
  }

  // Get ALL enrollments for a specific device (including past ones)
  Future<List<Map<String, dynamic>>> getAllMyEnrollments(
    String deviceId,
  ) async {
    final querySnapshot = await _eventsRef.get();
    final List<Map<String, dynamic>> results = [];

    for (var doc in querySnapshot.docs) {
      final household = await getHousehold(doc.id, deviceId);
      if (household != null) {
        results.add({
          'event': ParayanEvent.fromFirestore(doc),
          'household': household,
        });
      }
    }
    return results;
  }

  // Delete enrollment for a specific device (Delete ALL member docs)
  Future<void> deleteEnrollment(String eventId, String deviceId) async {
    final participantsRef = _eventsRef.doc(eventId).collection('participants');
    final snapshot = await participantsRef
        .where('deviceId', isEqualTo: deviceId)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Admin: Add multiple participants manually (via Cloud Function)
  // groups: List of { 'phone': String, 'names': List<String> }
  Future<void> adminAddParticipants({
    required String eventId,
    required List<Map<String, dynamic>> groups,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'adminAddParticipants',
      );
      await callable.call({'eventId': eventId, 'groups': groups});
    } catch (e) {
      rethrow;
    }
  }
}
