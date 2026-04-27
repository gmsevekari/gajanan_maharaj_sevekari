import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { weeklyPooja, specialEvent, other }

class Event {
  final String titleMr;
  final String titleEn;
  final Timestamp startTime;
  final Timestamp? endTime;
  final String? locationMr;
  final String? locationEn;
  final String? detailsMr;
  final String? detailsEn;
  final String? address;
  final EventType eventType;
  final String? groupId;

  const Event({
    required this.titleMr,
    required this.titleEn,
    required this.startTime,
    this.endTime,
    this.locationMr,
    this.locationEn,
    this.detailsMr,
    this.detailsEn,
    this.address,
    this.eventType = EventType.other,
    this.groupId,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      titleMr: data['title_mr'] ?? '',
      titleEn: data['title_en'] ?? '',
      startTime: data['start_time'] ?? Timestamp.now(),
      endTime: data['end_time'] as Timestamp?,
      locationMr: data['location_mr'] as String?,
      locationEn: data['location_en'] as String?,
      detailsMr: data['details_mr'] as String?,
      detailsEn: data['details_en'] as String?,
      address: data['address'] as String?,
      eventType: _parseEventType(data['event_type'] as String?),
      groupId: data['groupId'] as String?,
    );
  }

  static EventType _parseEventType(String? typeStr) {
    if (typeStr == null) return EventType.other;
    switch (typeStr.toLowerCase()) {
      case 'weekly pooja':
      case 'weekly_pooja':
      case 'weeklypooja':
        return EventType.weeklyPooja;
      case 'special event':
      case 'special_event':
      case 'specialevent':
        return EventType.specialEvent;
      default:
        return EventType.other;
    }
  }
}
