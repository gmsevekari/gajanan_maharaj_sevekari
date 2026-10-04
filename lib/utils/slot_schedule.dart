import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';

/// A time of day, as chosen in a time picker.
typedef ClockTime = ({int hour, int minute});

/// Start time used when the admin leaves it empty.
const ClockTime slotDefaultStartTime = (hour: 0, minute: 0);

/// End time used when the admin leaves it empty.
const ClockTime slotDefaultEndTime = (hour: 23, minute: 59);

/// What an admin enters for one slot's schedule. Only [startDate] is
/// required; everything else has a default (see [resolveSlotSchedule]).
///
/// Only the year, month and day of the dates are used, so a picker's
/// `DateTime` with any time of day is fine.
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
}

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
  String toString() => 'SlotScheduleResolved($startAt - $endAt)';
}

final class SlotScheduleInvalid extends SlotScheduleResult {
  final SlotScheduleError error;

  const SlotScheduleInvalid(this.error);

  @override
  String toString() => 'SlotScheduleInvalid($error)';
}

/// Turns what the admin entered into concrete UTC start and end instants.
///
/// Empty fields default: start time to 00:00, end date to the start date, end
/// time to 23:59. So any combination is allowed, and the only thing that can
/// be wrong is an end that is not after the start (which also covers an end
/// date before the start date). A slot may cross midnight or span days.
SlotScheduleResult resolveSlotSchedule(SlotScheduleInput input) {
  final startDate = input.startDate;
  if (startDate == null) {
    return const SlotScheduleInvalid(SlotScheduleError.missingStartDate);
  }
  final endDate = input.endDate ?? startDate;
  final startTime = input.startTime ?? slotDefaultStartTime;
  final endTime = input.endTime ?? slotDefaultEndTime;

  final startAt = wallClockToUtc(
    _wallClock(startDate, startTime),
    input.timezone,
  );
  final endAt = wallClockToUtc(_wallClock(endDate, endTime), input.timezone);

  if (!endAt.isAfter(startAt)) {
    return const SlotScheduleInvalid(SlotScheduleError.endNotAfterStart);
  }
  return SlotScheduleResolved(startAt: startAt, endAt: endAt);
}

/// Built with `DateTime.utc` on purpose: see the wall-clock note in
/// event_timezone.dart.
DateTime _wallClock(DateTime date, ClockTime time) {
  assert(
    time.hour >= 0 && time.hour <= 23 && time.minute >= 0 && time.minute <= 59,
    'Invalid time of day: $time',
  );
  return DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
}
