import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

/// A time of day, as chosen in a time picker.
typedef ClockTime = ({int hour, int minute});

/// Start time used when the admin leaves it empty.
const ClockTime slotDefaultStartTime = (hour: 0, minute: 0);

/// End time used when the admin leaves it empty. A slot with no end time
/// therefore ends at 23:59:00, and its last 59 seconds count as past.
const ClockTime slotDefaultEndTime = (hour: 23, minute: 59);

/// What an admin enters for one slot's schedule. Only [startDate] is
/// required; everything else has a default (see [resolveSlotSchedule]).
///
/// The dates are read as the calendar day they show (`year`, `month`, `day`),
/// so a picker's `DateTime` with any time of day is fine, and two inputs for
/// the same day are equal.
class SlotScheduleInput {
  final DateTime? startDate;
  final ClockTime? startTime;
  final DateTime? endDate;
  final ClockTime? endTime;

  /// The zone the dates and times were entered in.
  final String timezone;

  const SlotScheduleInput({
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.timezone = EventTimezone.defaultZone,
  });

  /// A copy with the given fields replaced. A nullable field can't be set
  /// back to null by passing null (that means "keep"), so each has a
  /// `clear...` flag for that; a flag wins over the matching value.
  SlotScheduleInput copyWith({
    DateTime? startDate,
    ClockTime? startTime,
    DateTime? endDate,
    ClockTime? endTime,
    String? timezone,
    bool clearStartDate = false,
    bool clearStartTime = false,
    bool clearEndDate = false,
    bool clearEndTime = false,
  }) {
    return SlotScheduleInput(
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      startTime: clearStartTime ? null : startTime ?? this.startTime,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      endTime: clearEndTime ? null : endTime ?? this.endTime,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotScheduleInput &&
          _sameDay(startDate, other.startDate) &&
          startTime == other.startTime &&
          _sameDay(endDate, other.endDate) &&
          endTime == other.endTime &&
          timezone == other.timezone;

  @override
  int get hashCode => Object.hash(
    _dayKey(startDate),
    startTime,
    _dayKey(endDate),
    endTime,
    timezone,
  );

  @override
  String toString() =>
      'SlotScheduleInput(start: ${_dayKey(startDate)} $startTime, '
      'end: ${_dayKey(endDate)} $endTime, $timezone)';
}

bool _sameDay(DateTime? a, DateTime? b) => _dayKey(a) == _dayKey(b);

/// `2026-07-01`, or null for a missing date.
String? _dayKey(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

enum SlotScheduleError {
  /// No start date was chosen.
  missingStartDate,

  /// The end is not strictly after the start.
  endNotAfterStart,
}

sealed class SlotScheduleResult {
  const SlotScheduleResult();
}

/// A valid schedule as UTC instants.
final class SlotScheduleResolved extends SlotScheduleResult {
  final DateTime startAt;
  final DateTime endAt;

  const SlotScheduleResolved({required this.startAt, required this.endAt});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotScheduleResolved &&
          startAt == other.startAt &&
          endAt == other.endAt;

  @override
  int get hashCode => Object.hash(startAt, endAt);

  @override
  String toString() => 'SlotScheduleResolved($startAt - $endAt)';
}

final class SlotScheduleInvalid extends SlotScheduleResult {
  final SlotScheduleError error;

  const SlotScheduleInvalid(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotScheduleInvalid && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'SlotScheduleInvalid($error)';
}

/// Turns what the admin entered into concrete UTC start and end instants.
///
/// Empty fields default: start time to 00:00, end date to the start date, end
/// time to 23:59. So any combination is allowed, and the only thing that can
/// be wrong is an end that is not after the start (which also covers an end
/// date before the start date). A slot may cross midnight or span days.
///
/// Throws [ArgumentError] for an hour or minute that is not a real time of
/// day; a time picker can't produce one, so that is a programming error.
SlotScheduleResult resolveSlotSchedule(SlotScheduleInput input) {
  final startDate = input.startDate;
  if (startDate == null) {
    return const SlotScheduleInvalid(SlotScheduleError.missingStartDate);
  }
  final startAt = _toUtc(
    startDate,
    input.startTime ?? slotDefaultStartTime,
    input.timezone,
  );
  final endAt = _toUtc(
    input.endDate ?? startDate,
    input.endTime ?? slotDefaultEndTime,
    input.timezone,
  );

  if (!endAt.isAfter(startAt)) {
    return const SlotScheduleInvalid(SlotScheduleError.endNotAfterStart);
  }
  return SlotScheduleResolved(startAt: startAt, endAt: endAt);
}

DateTime _toUtc(DateTime date, ClockTime time, String timezone) {
  if (time.hour < 0 || time.hour > 23 || time.minute < 0 || time.minute > 59) {
    throw ArgumentError.value(time, 'time', 'is not a time of day');
  }
  return wallClockToUtc(
    year: date.year,
    month: date.month,
    day: date.day,
    hour: time.hour,
    minute: time.minute,
    timezone: timezone,
  );
}
