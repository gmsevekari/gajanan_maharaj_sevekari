import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:intl/intl.dart';

/// How a slot's schedule reads on screen: a [primary] line and, for a
/// one-day slot with times, a [secondary] line under it.
class SlotWhen {
  /// The date line, or the whole range for a slot that spans days.
  final String primary;

  /// The time range, for a one-day slot that has times; otherwise null.
  final String? secondary;

  const SlotWhen(this.primary, [this.secondary]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotWhen &&
          primary == other.primary &&
          secondary == other.secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() =>
      'SlotWhen($primary${secondary == null ? '' : ' | $secondary'})';
}

/// The slot's date and time range in English, in the slot's own timezone, so
/// everyone sees the same wall-clock time whatever their device's zone. Sign-up
/// screens are English-only UI. Times carry a zone label (`PT` / `IST`):
///
/// | Slot | primary | secondary |
/// |---|---|---|
/// | all-day, one day | `Friday, March 15` | - |
/// | timed, one day | `Friday, March 15` | `6:00 PM – 7:30 PM PT` |
/// | several days, all-day | `March 15 – March 17` | - |
/// | several days, timed | `Mar 15, 6:00 PM – Mar 17, 12:00 PM PT` | - |
///
/// The year is left out unless a slot's start and end fall in different
/// years, when both ends show it (`March 15, 2026 – March 16, 2027`) so a
/// long slot can't read as a single day.
///
/// Returns null for a slot without a start and end, which has nothing to show.
SlotWhen? formatSlotWhen(SignupSlot slot) {
  if (!slot.hasSchedule) return null;
  final start = utcToWallClock(slot.startAt!, slot.timezone);
  final end = utcToWallClock(slot.endAt!, slot.timezone);
  final label = timezoneLabel(slot.timezone);

  if (!slot.isMultiDay) {
    final date = _dayWithWeekday.format(start);
    if (slot.isAllDay) return SlotWhen(date);
    return SlotWhen(
      date,
      '${_time.format(start)} $_dash ${_time.format(end)} $label',
    );
  }
  final crossesYears = start.year != end.year;
  if (slot.isAllDay) {
    final format = crossesYears ? _dayWithYear : _day;
    return SlotWhen('${format.format(start)} $_dash ${format.format(end)}');
  }
  final format = crossesYears ? _dayYearAndTime : _dayAndTime;
  return SlotWhen(
    '${format.format(start)} $_dash ${format.format(end)} $label',
  );
}

const String _dash = '–';

// Fixed to US English, which needs no locale-data setup, so the output never
// follows the device's or the app's locale. Created per call; the cost is
// negligible next to building a widget.
DateFormat get _dayWithWeekday => DateFormat('EEEE, MMMM d', 'en_US');
DateFormat get _day => DateFormat('MMMM d', 'en_US');
DateFormat get _dayWithYear => DateFormat('MMMM d, y', 'en_US');
DateFormat get _time => DateFormat('h:mm a', 'en_US');
DateFormat get _dayAndTime => DateFormat('MMM d, h:mm a', 'en_US');
DateFormat get _dayYearAndTime => DateFormat('MMM d, y, h:mm a', 'en_US');
