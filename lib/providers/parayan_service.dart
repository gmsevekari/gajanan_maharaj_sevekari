import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_participant.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';

class ParayanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _eventsRef => _db.collection('parayan_events');

  // Create a new Parayan Event (Admin)
  Future<void> createEvent(ParayanEvent event) async {
    await _eventsRef.doc(event.id).set(event.toFirestore());
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
        .map((snapshot) => snapshot.docs
            .map((doc) => ParayanEvent.fromFirestore(doc))
            .toList());
  }

  // Enrollment Logic (Round Robin / Circular Shift)
  Future<void> enrollParticipant({
    required String eventId,
    required ParayanType type,
    required String deviceId,
    required String name,
    required String email,
    required String phone,
  }) async {
    final eventDoc = _eventsRef.doc(eventId);
    final participantsRef = eventDoc.collection('participants');

    return _db.runTransaction((transaction) async {
      // 1. Get current participant count for FCFS logic
      final querySnapshot = await participantsRef.get();
      final currentCount = querySnapshot.docs.length;

      List<int> assigned;
      Map<String, bool> completions = {};

      if (type == ParayanType.oneDay) {
        // 1-Day: Sequential 1-21, then wrap
        final adhyay = (currentCount % 21) + 1;
        assigned = [adhyay];
        completions["1"] = false;
      } else {
        // 3-Day: Circular Shift / Interlaced Round Robin
        // Group determined by order: Group 1 (starts at 1), Group 2 (starts at 2), Group 3 (starts at 3)
        final group = (currentCount % 3) + 1;
        final k = currentCount ~/ 3; // Nth person in that group

        // Day 1 Adhyay: ((Group + (k * 9)) - 1) % 21 + 1
        // We use +9 increment per person in group to spread out coverage? 
        // User asked for: Group 1 starts at 1 and increments by 3 for each participant.
        // Let's re-read: "Group 1 starts at Adhyay 1 and increments by 3 for each participant."
        // That means:
        // Person 0 (Group 1): Day 1=1, Day 2=4, Day 3=7
        // Person 1 (Group 2): Day 1=2, Day 2=5, Day 3=8
        // Person 2 (Group 3): Day 1=3, Day 2=6, Day 3=9
        // Person 3 (Group 1): Day 1=10, Day 2=13, Day 3=16 ... no wait.
        
        // Let's follow the user's specific text:
        // "Group 1 starts at Adhyay 1 and increments by 3 for each participant."
        // "Group 2 starts at Adhyay 2 and increments."
        // "Group 3 starts at Adhyay 3 and increments."
        
        // This implies:
        // Group index g = currentCount % 3 (0, 1, 2)
        // Person index in group p = currentCount ~/ 3
        
        // Day 1 for Group 1 (group=1) should be: 1, 4, 7, 10, 13, 16, 19, (wrap) ... 1+3*k
        int day1 = (group + (k * 3) - 1) % 21 + 1;
        int day2 = (day1 + 3 - 1) % 21 + 1;
        int day3 = (day1 + 6 - 1) % 21 + 1;
        
        assigned = [day1, day2, day3];
        completions = {"1": false, "2": false, "3": false};
      }

      final participant = ParayanParticipant(
        deviceId: deviceId,
        name: name,
        email: email,
        phone: phone,
        joinedAt: DateTime.now(),
        assignedAdhyays: assigned,
        completions: completions,
      );

      transaction.set(participantsRef.doc(deviceId), participant.toFirestore());
      
      // 4. Update joinedParticipants count in the event document
      transaction.update(eventDoc, {
        'joinedParticipants': FieldValue.increment(1),
      });
    });
  }

  // Submit completion
  Future<void> submitCompletion(String eventId, String deviceId, int dayIndex) async {
    final docRef = _eventsRef.doc(eventId).collection('participants').doc(deviceId);
    await docRef.update({
      'completions.$dayIndex': true,
    });
  }

  // Get participant details for a user
  Stream<ParayanParticipant?> getParticipant(String eventId, String deviceId) {
    return _eventsRef
        .doc(eventId)
        .collection('participants')
        .doc(deviceId)
        .snapshots()
        .map((doc) => doc.exists ? ParayanParticipant.fromFirestore(doc) : null);
  }

  // Get all participants for an event (Public Table)
  Stream<List<ParayanParticipant>> getAllParticipants(String eventId) {
    return _eventsRef
        .doc(eventId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParayanParticipant.fromFirestore(doc))
            .toList());
  }
}
