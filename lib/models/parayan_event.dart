import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

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
  final bool is4DayParayan;
  final String? extraDayTithi;

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
    this.is4DayParayan = false,
    this.extraDayTithi,
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
      groupId: data['groupId'] ?? GroupConstants.seattle,
      timezone: data['timezone'] ?? 'America/Los_Angeles',
      is4DayParayan: data['is4DayParayan'] ?? false,
      extraDayTithi: data['extraDayTithi'],
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
      'is4DayParayan': is4DayParayan,
      if (extraDayTithi != null) 'extraDayTithi': extraDayTithi,
    };
  }

  /// Returns the calendar dates corresponding to a day index (0, 1, 2)
  List<DateTime> getDatesForDayIndex(int index) {
    if (type != ParayanType.threeDay || !is4DayParayan) {
      return [startDate.add(Duration(days: index))];
    }

    switch (extraDayTithi) {
      case 'dashami':
        if (index == 0) return [startDate, startDate.add(const Duration(days: 1))];
        if (index == 1) return [startDate.add(const Duration(days: 2))];
        if (index == 2) return [startDate.add(const Duration(days: 3))];
        break;
      case 'ekadashi':
        if (index == 0) return [startDate];
        if (index == 1) return [startDate.add(const Duration(days: 1)), startDate.add(const Duration(days: 2))];
        if (index == 2) return [startDate.add(const Duration(days: 3))];
        break;
      case 'dwadashi':
        if (index == 0) return [startDate];
        if (index == 1) return [startDate.add(const Duration(days: 1))];
        if (index == 2) return [startDate.add(const Duration(days: 2)), startDate.add(const Duration(days: 3))];
        break;
    }
    return [startDate.add(Duration(days: index))];
  }

  /// Formats the date header for the given day index
  String getFormattedDateHeaderForDayIndex(int index, String locale) {
    final dates = getDatesForDayIndex(index);
    if (dates.length == 1) {
      return formatDateShortWithEventTimezone(dates[0].toUtc(), timezone, locale);
    } else {
      final d1 = formatDateShortWithEventTimezone(dates[0].toUtc(), timezone, locale);
      final d2 = formatDateShortWithEventTimezone(dates[1].toUtc(), timezone, locale);
      return locale == 'mr' ? '$d1 आणि $d2' : '$d1 & $d2';
    }
  }
}
