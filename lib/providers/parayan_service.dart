import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

    final doc = await participantsRef.doc(deviceId).get();
    ParayanHousehold? existingHousehold;
    if (doc.exists) {
      existingHousehold = ParayanHousehold.fromFirestore(doc);
    }

    final Map<String, ParayanMember> membersMap = {};

    for (var name in names) {
      if (existingHousehold != null &&
          existingHousehold.members.containsKey(name)) {
        // PRESERVE HISTORICAL ALLOCATION ACTUALLY
        membersMap[name] = existingHousehold.members[name]!;
        continue;
      }

      // No adhyay assignment here anymore - will be done in batch later
      membersMap[name] = ParayanMember(
        name: name,
        assignedAdhyays: [], // Empty initially
        completions: {},
      );
    }

    final household = ParayanHousehold(
      deviceId: deviceId,
      phone: phone,
      joinedAt: existingHousehold?.joinedAt ?? DateTime.now(),
      members: membersMap,
    );

    // We only write to the participants subcollection document.
    await participantsRef.doc(deviceId).set(household.toFirestore());

    // NOTE: We are skipping the eventDoc 'joinedParticipants' update here
    // because standard users likely don't have WRITE permission on the event doc.
    // Dashboard and Tabs calculate the count dynamically using getAllParticipants().
  }

  Future<ParayanHousehold?> getHousehold(
    String eventId,
    String deviceId,
  ) async {
    final docRef = _eventsRef
        .doc(eventId)
        .collection('participants')
        .doc(deviceId);
    final doc = await docRef.get();
    if (doc.exists) {
      return ParayanHousehold.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateMemberCompletion({
    required String eventId,
    required String deviceId,
    required String memberName,
    required int dayIndex,
    required bool completed,
  }) async {
    final docRef = _eventsRef
        .doc(eventId)
        .collection('participants')
        .doc(deviceId);
    await docRef.update({
      'members.$memberName.completions.$dayIndex': completed,
    });

    // Topic subscription logic for day-specific reminders
    if (kIsWeb) return;
    try {
      final updatedDoc = await docRef.get();
      if (updatedDoc.exists) {
        final household = ParayanHousehold.fromFirestore(updatedDoc);
        final allCompleted = household.members.values.every(
          (m) => m.completions[dayIndex.toString()] == true,
        );

        final topic = NotificationConstants.getParayanReminderTopic(
          eventId,
          dayIndex + 1,
        );
        if (completed && allCompleted) {
          await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        } else if (!completed) {
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
        .doc(deviceId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          final household = ParayanHousehold.fromFirestore(doc);
          final members = household.members.values.toList();
          // Sort members by their first assigned adhyay for consistent order
          members.sort((a, b) {
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
          final List<ParayanMember> allMembers = [];
          for (var doc in snapshot.docs) {
            final household = ParayanHousehold.fromFirestore(doc);
            final members = household.members.values.toList();
            // Sort members within each household by adhyay
            members.sort((a, b) {
              final aFirst = a.assignedAdhyays.isNotEmpty
                  ? a.assignedAdhyays.first
                  : 0;
              final bFirst = b.assignedAdhyays.isNotEmpty
                  ? b.assignedAdhyays.first
                  : 0;
              return aFirst.compareTo(bFirst);
            });
            allMembers.addAll(members);
          }
          return allMembers;
        });
  }

  // Perform batch adhyay allocation for all participants
  Future<void> allocateAdhyays(String eventId) async {
    final eventDoc = await _eventsRef.doc(eventId).get();
    if (!eventDoc.exists) return;
    final event = ParayanEvent.fromFirestore(eventDoc);
    final type = event.type;

    final participantsRef = _eventsRef.doc(eventId).collection('participants');
    final querySnapshot = await participantsRef
        .orderBy('joinedAt', descending: false)
        .get();

    final WriteBatch batch = _db.batch();
    int currentTotal = 0;

    for (var doc in querySnapshot.docs) {
      final household = ParayanHousehold.fromFirestore(doc);
      final newMembers = <String, ParayanMember>{};
      bool changed = false;

      // Sort house members consistently for group allocation
      final membersList = household.members.values.toList();
      // No extra sort needed here as we want to preserve internal household order

      for (var member in membersList) {
        // Skip if already assigned? Or re-assign everyone for perfect alignment?
        // Let's re-assign everyone to guarantee consistency.

        List<int> assigned;
        Map<String, bool> completions = {};

        if (type == ParayanType.oneDay || type == ParayanType.guruPushya) {
          final adhyay = (currentTotal % 21) + 1;
          assigned = [adhyay];
          completions["1"] = false;
        } else if (type == ParayanType.threeDay) {
          final groupOffset = (currentTotal ~/ 7) % 3;
          final participantOffset = (currentTotal % 7) * 3;

          final day1 = (groupOffset + participantOffset) % 21 + 1;
          final day2 = (day1 % 21) + 1;
          final day3 = (day2 % 21) + 1;

          assigned = [day1, day2, day3];
          completions = {"1": false, "2": false, "3": false};
        } else {
          // Default to 1-21 if type unknown
          final adhyay = (currentTotal % 21) + 1;
          assigned = [adhyay];
          completions["1"] = false;
        }

        newMembers[member.name] = ParayanMember(
          name: member.name,
          assignedAdhyays: assigned,
          completions: completions,
          deviceId: member.deviceId,
          phone: member.phone,
        );
        currentTotal++;
        changed = true;
      }

      if (changed) {
        final updatedHousehold = ParayanHousehold(
          deviceId: household.deviceId,
          phone: household.phone,
          joinedAt: household.joinedAt,
          members: newMembers,
        );
        batch.set(doc.reference, updatedHousehold.toFirestore());
      }
    }

    await batch.commit();
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
      final participantDoc = await doc.reference
          .collection('participants')
          .doc(deviceId)
          .get();
      if (participantDoc.exists) {
        results.add({
          'event': ParayanEvent.fromFirestore(doc),
          'household': ParayanHousehold.fromFirestore(participantDoc),
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
      final participantDoc = await doc.reference
          .collection('participants')
          .doc(deviceId)
          .get();
      if (participantDoc.exists) {
        results.add({
          'event': ParayanEvent.fromFirestore(doc),
          'household': ParayanHousehold.fromFirestore(participantDoc),
        });
      }
    }
    return results;
  }

  // Delete enrollment for a specific device
  Future<void> deleteEnrollment(String eventId, String deviceId) async {
    final docRef = _eventsRef
        .doc(eventId)
        .collection('participants')
        .doc(deviceId);
    await docRef.delete();
  }
}
