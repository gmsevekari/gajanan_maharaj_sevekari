import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { weeklyPooja, specialEvent, other }

class Event {
  final String title_mr;
  final String title_en;
  final Timestamp start_time;
  final Timestamp? end_time;
  final String? location_mr;
  final String? location_en;
  final String? details_mr;
  final String? details_en;
  final String? address;
  final EventType event_type;
  final String? groupId;

  const Event({
    required this.title_mr,
    required this.title_en,
    required this.start_time,
    this.end_time,
    this.location_mr,
    this.location_en,
    this.details_mr,
    this.details_en,
    this.address,
    this.event_type = EventType.other,
    this.groupId,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      title_mr: data['title_mr'] ?? '',
      title_en: data['title_en'] ?? '',
      start_time: data['start_time'] ?? Timestamp.now(),
      end_time: data['end_time'] as Timestamp?,
      location_mr: data['location_mr'] as String?,
      location_en: data['location_en'] as String?,
      details_mr: data['details_mr'] as String?,
      details_en: data['details_en'] as String?,
      address: data['address'] as String?,
      event_type: _parseEventType(data['event_type'] as String?),
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
