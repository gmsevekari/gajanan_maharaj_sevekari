import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';

class ParayanEvent {
  final String id;
  final String titleEn;
  final String titleMr;
  final String descriptionEn;
  final String descriptionMr;
  final ParayanType type;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // upcoming, enrolling, ongoing, completed
  final List<String> reminderTimes; // e.g., ["20:00", "21:00"]
  final DateTime? manualPingRequestedAt;
  final DateTime createdAt;
  final Map<String, dynamic> sentReminders; // e.g., {'day1_20:00': Timestamp}
  final String? joinCode;
  final String groupId;
  final String timezone;

  const ParayanEvent({
    required this.id,
    required this.titleEn,
    required this.titleMr,
    required this.descriptionEn,
    required this.descriptionMr,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reminderTimes,
    this.manualPingRequestedAt,
    required this.createdAt,
    this.sentReminders = const {},
    this.joinCode,
    required this.groupId,
    this.timezone = 'America/Los_Angeles',
  });

  factory ParayanEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<String> times = List<String>.from(data['reminderTimes']);

    return ParayanEvent(
      id: doc.id,
      titleEn: data['title_en'] ?? data['title'] ?? '',
      titleMr: data['title_mr'] ?? data['title'] ?? '',
      descriptionEn: data['description_en'] ?? data['description'] ?? '',
      descriptionMr: data['description_mr'] ?? data['description'] ?? '',
      type: data['type'] == 'threeDay'
          ? ParayanType.threeDay
          : data['type'] == 'guruPushya'
          ? ParayanType.guruPushya
          : ParayanType.oneDay,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'upcoming',
      reminderTimes: times,
      manualPingRequestedAt: data['manualPingRequestedAt'] != null
          ? (data['manualPingRequestedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      sentReminders: data['sentReminders'] != null
          ? Map<String, dynamic>.from(data['sentReminders'] as Map)
          : {},
      joinCode: data['joinCode'],
      groupId: data['groupId'] ?? 'gajanan_maharaj_seattle',
      timezone: data['timezone'] ?? 'America/Los_Angeles',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title_en': titleEn,
      'title_mr': titleMr,
      'description_en': descriptionEn,
      'description_mr': descriptionMr,
      'type': type == ParayanType.threeDay
          ? 'threeDay'
          : type == ParayanType.guruPushya
          ? 'guruPushya'
          : 'oneDay',
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'reminderTimes': reminderTimes,
      if (manualPingRequestedAt != null)
        'manualPingRequestedAt': Timestamp.fromDate(
          manualPingRequestedAt as DateTime,
        ),
      'createdAt': Timestamp.fromDate(createdAt),
      'sentReminders': sentReminders,
      if (joinCode != null) 'joinCode': joinCode,
      'groupId': groupId,
      'timezone': timezone,
    };
  }
}
