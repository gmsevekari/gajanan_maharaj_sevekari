import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

/// A single claimable slot within a [Signup]'s `slots` subcollection.
///
/// A slot runs from [startAt] to [endAt] (UTC instants) and may span days.
/// [timezone] is the zone its times were entered in, and the zone they are
/// shown in. A slot saved without these fields (no [startAt] / [endAt]) loads
/// as an undated slot.
class SignupSlot {
  final String? id;
  final String labelEn;
  final String labelMr;
  final DateTime? startAt;
  final DateTime? endAt;
  final String timezone;
  final int capacity;
  final int claimedCount;
  final double? suggestedAmount;
  final int sortOrder;
  final DateTime createdAt;

  const SignupSlot({
    this.id,
    required this.labelEn,
    required this.labelMr,
    this.startAt,
    this.endAt,
    this.timezone = EventTimezone.defaultZone,
    required this.capacity,
    this.claimedCount = 0,
    this.suggestedAmount,
    required this.sortOrder,
    required this.createdAt,
  });

  factory SignupSlot.fromMap(String id, Map<String, dynamic> data) {
    return SignupSlot(
      id: id,
      labelEn: data['labelEn'] is String ? data['labelEn'] as String : '',
      labelMr: data['labelMr'] is String ? data['labelMr'] as String : '',
      startAt: _instant(data['startAt']),
      endAt: _instant(data['endAt']),
      // Kept verbatim, even if unrecognised, so saving a slot never rewrites
      // it; the zone helpers treat an unknown zone as Pacific.
      timezone: data['timezone'] is String
          ? data['timezone'] as String
          : EventTimezone.defaultZone,
      capacity: data['capacity'] is num ? (data['capacity'] as num).toInt() : 0,
      claimedCount: data['claimedCount'] is num
          ? (data['claimedCount'] as num).toInt()
          : 0,
      suggestedAmount: data['suggestedAmount'] is num
          ? (data['suggestedAmount'] as num).toDouble()
          : null,
      sortOrder: data['sortOrder'] is num
          ? (data['sortOrder'] as num).toInt()
          : 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static DateTime? _instant(Object? value) =>
      value is Timestamp ? value.toDate().toUtc() : null;

  Map<String, dynamic> toMap() {
    return {
      'labelEn': labelEn,
      'labelMr': labelMr,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'timezone': timezone,
      'capacity': capacity,
      'claimedCount': claimedCount,
      'suggestedAmount': suggestedAmount,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Whether the slot has both a start and an end.
  bool get hasSchedule => startAt != null && endAt != null;

  /// True when, in [timezone], the slot starts at 00:00 and ends at 23:59 -
  /// what an empty time gives when it is created - so no time needs showing.
  bool get isAllDay {
    if (!hasSchedule) return false;
    final start = utcToWallClock(startAt!, timezone);
    final end = utcToWallClock(endAt!, timezone);
    return start.hour == 0 &&
        start.minute == 0 &&
        end.hour == 23 &&
        end.minute == 59;
  }

  /// True when, in [timezone], the slot starts and ends on different days
  /// (including an overnight slot).
  bool get isMultiDay {
    if (!hasSchedule) return false;
    final start = utcToWallClock(startAt!, timezone);
    final end = utcToWallClock(endAt!, timezone);
    return start.year != end.year ||
        start.month != end.month ||
        start.day != end.day;
  }

  /// Whether the slot has finished by [now]: it has an end, and that end has
  /// passed. A slot without an end is never past.
  bool isPast(DateTime now) => endAt != null && endAt!.isBefore(now);

  /// Orders slots by [startAt] (earliest first), then by [sortOrder]. Slots
  /// without a start come last, in their own [sortOrder]. Compares instants,
  /// so it is right whatever zone each slot was entered in.
  static int compareByStart(SignupSlot a, SignupSlot b) {
    final startA = a.startAt;
    final startB = b.startAt;
    if (startA == null && startB != null) return 1;
    if (startA != null && startB == null) return -1;
    if (startA != null && startB != null) {
      final byStart = startA.compareTo(startB);
      if (byStart != 0) return byStart;
    }
    return a.sortOrder.compareTo(b.sortOrder);
  }

  SignupSlot copyWith({
    String? id,
    String? labelEn,
    String? labelMr,
    DateTime? startAt,
    DateTime? endAt,
    String? timezone,
    int? capacity,
    int? claimedCount,
    double? suggestedAmount,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return SignupSlot(
      id: id ?? this.id,
      labelEn: labelEn ?? this.labelEn,
      labelMr: labelMr ?? this.labelMr,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timezone: timezone ?? this.timezone,
      capacity: capacity ?? this.capacity,
      claimedCount: claimedCount ?? this.claimedCount,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          labelEn == other.labelEn &&
          labelMr == other.labelMr &&
          _sameInstant(startAt, other.startAt) &&
          _sameInstant(endAt, other.endAt) &&
          timezone == other.timezone &&
          capacity == other.capacity &&
          claimedCount == other.claimedCount &&
          suggestedAmount == other.suggestedAmount &&
          sortOrder == other.sortOrder &&
          _sameInstant(createdAt, other.createdAt);

  /// Compares the moment in time, not the UTC flag (a local and a UTC
  /// `DateTime` for the same moment are `!=` in Dart).
  static bool _sameInstant(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : a.isAtSameMomentAs(b);

  @override
  int get hashCode => Object.hash(
    id,
    labelEn,
    labelMr,
    startAt?.millisecondsSinceEpoch,
    endAt?.millisecondsSinceEpoch,
    timezone,
    capacity,
    claimedCount,
    suggestedAmount,
    sortOrder,
    createdAt.millisecondsSinceEpoch,
  );
}
