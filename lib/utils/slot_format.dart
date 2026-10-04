import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:intl/intl.dart';

/// How a slot's schedule reads on screen: a [primary] line and, for a
/// one-day slot with times, a [secondary] line under it.
class SlotWhen {
  final String primary;
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
  if (slot.isAllDay) {
    return SlotWhen('${_day.format(start)} $_dash ${_day.format(end)}');
  }
  return SlotWhen(
    '${_dayAndTime.format(start)} $_dash ${_dayAndTime.format(end)} $label',
  );
}

const String _dash = '–';

// Fixed to US English, which needs no locale-data setup: these must not
// follow the device's locale. Created per call (not cached in a top-level
// final) so a format is never built under a locale that was current by chance
// when it was first used.
DateFormat get _dayWithWeekday => DateFormat('EEEE, MMMM d', 'en_US');
DateFormat get _day => DateFormat('MMMM d', 'en_US');
DateFormat get _time => DateFormat('h:mm a', 'en_US');
DateFormat get _dayAndTime => DateFormat('MMM d, h:mm a', 'en_US');
