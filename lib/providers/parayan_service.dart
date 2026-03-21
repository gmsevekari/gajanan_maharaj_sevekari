import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gajanan_maharaj_sevekari/notifications/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    required String email,
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
      final data = doc.data() as Map<String, dynamic>;
      final members = data['members'] as Map<String, dynamic>? ?? {};
      currentTotal += members.length;
    }

    final Map<String, ParayanMember> membersMap = {};

    for (var name in names) {
      List<int> assigned;
      Map<String, bool> completions = {};

      if (type == ParayanType.oneDay) {
        final adhyay = (currentTotal % 21) + 1;
        assigned = [adhyay];
        completions["1"] = false;
      } else {
        final group = (currentTotal % 3) + 1;
        final k = currentTotal ~/ 3;

        int day1 = (group + (k * 3) - 1) % 21 + 1;
        int day2 = (day1 + 3 - 1) % 21 + 1;
        int day3 = (day1 + 6 - 1) % 21 + 1;

        assigned = [day1, day2, day3];
        completions = {"1": false, "2": false, "3": false};
      }

      membersMap[name] = ParayanMember(
        name: name,
        assignedAdhyays: assigned,
        completions: completions,
      );
      currentTotal++;
    }

    final household = ParayanHousehold(
      deviceId: deviceId,
      email: email,
      phone: phone,
      joinedAt: DateTime.now(),
      members: membersMap,
    );

    // We only write to the participants subcollection document.
    // This avoids the permission error on the main parayan_events document.
    await participantsRef.doc(deviceId).set(household.toFirestore());

    // NOTE: We are skipping the eventDoc 'joinedParticipants' update here
    // because standard users likely don't have WRITE permission on the event doc.
    // Dashboard and Tabs calculate the count dynamically using getAllParticipants().
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
    try {
      final updatedDoc = await docRef.get();
      if (updatedDoc.exists) {
        final household = ParayanHousehold.fromFirestore(updatedDoc);
        final allCompleted = household.members.values.every(
          (m) => m.completions[dayIndex.toString()] == true,
        );

        final topic = NotificationConstants.getParayanReminderTopic(
          eventId,
          dayIndex,
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
}
