import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/models/event.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/providers/group_selection_provider.dart';

class GroupEvents {
  final Event? weeklyPooja;
  final Event? specialEvent;
  final ParayanEvent? parayan;

  const GroupEvents({
    this.weeklyPooja,
    this.specialEvent,
    this.parayan,
  });

  bool get isEmpty => weeklyPooja == null && specialEvent == null && parayan == null;
}

class EventProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final GroupSelectionProvider _groupSelectionProvider;

  Map<String, GroupEvents> _groupedEvents = {};
  bool _isLoading = false;
  String? _error;

  EventProvider({
    FirebaseFirestore? firestore,
    required GroupSelectionProvider groupSelectionProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _groupSelectionProvider = groupSelectionProvider {
    _groupSelectionProvider.addListener(_onGroupsChanged);
    fetchEvents();
  }

  Map<String, GroupEvents> get groupedEvents => _groupedEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onGroupsChanged() {
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final groupIds = _groupSelectionProvider.selectedGroupIds;
    if (groupIds.isEmpty) {
      _groupedEvents = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);
      // Fetch from start of today to catch ongoing events
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfTodayTimestamp = Timestamp.fromDate(startOfToday);

      final results = await Future.wait(groupIds.map((groupId) => _fetchEventsForGroup(
            groupId,
            startOfTodayTimestamp,
            nowTimestamp,
            now,
          )));

      final Map<String, GroupEvents> newGroupedEvents = {};
      for (int i = 0; i < groupIds.length; i++) {
        newGroupedEvents[groupIds[i]] = results[i];
      }

      _groupedEvents = newGroupedEvents;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching events: $e');
    }
  }

  Future<GroupEvents> _fetchEventsForGroup(
    String groupId,
    Timestamp startOfTodayTimestamp,
    Timestamp nowTimestamp,
    DateTime now,
  ) async {
    // 1. Fetch Generic Events (Weekly Pooja & Special Event)
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('groupId', isEqualTo: groupId)
        .where('start_time', isGreaterThanOrEqualTo: startOfTodayTimestamp)
        .orderBy('start_time')
        .limit(20)
        .get();

    Event? weeklyPooja;
    Event? specialEvent;

    for (var doc in eventsSnapshot.docs) {
      final event = Event.fromFirestore(doc);

      // Check if event is still active (end_time > now)
      final effectiveEndTime = event.end_time?.toDate() ??
          event.start_time.toDate().add(const Duration(hours: 1));

      if (effectiveEndTime.isBefore(now)) continue;

      if (weeklyPooja == null && event.event_type == EventType.weeklyPooja) {
        weeklyPooja = event;
      }
      if (specialEvent == null && event.event_type == EventType.specialEvent) {
        specialEvent = event;
      }
      if (weeklyPooja != null && specialEvent != null) break;
    }

    // 2. Fetch Parayan Events
    final parayanSnapshot = await _firestore
        .collection('parayan_events')
        .where('groupId', isEqualTo: groupId)
        .where('endDate', isGreaterThanOrEqualTo: nowTimestamp)
        .orderBy('endDate')
        .limit(5)
        .get();

    ParayanEvent? upcomingParayan;
    for (var doc in parayanSnapshot.docs) {
      final event = ParayanEvent.fromFirestore(doc);
      if (event.endDate.isAfter(now) && event.status != 'completed') {
        upcomingParayan = event;
        break;
      }
    }

    return GroupEvents(
      weeklyPooja: weeklyPooja,
      specialEvent: specialEvent,
      parayan: upcomingParayan,
    );
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _groupSelectionProvider.removeListener(_onGroupsChanged);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
