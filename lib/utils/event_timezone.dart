/// Timezone helpers for events entered in a fixed wall-clock zone (sign-up
/// slots). Pure Dart: no Flutter imports.
///
/// Only the two zones the app uses are supported - Seattle (US Pacific) and
/// India - because there is no timezone database in the app. The conversion
/// is done by hand, like the Parayan and Namjap screens do, but written and
/// tested here on its own.
///
/// A "wall clock" value is a [DateTime] whose year ... second fields are what
/// a clock on the wall of that zone shows. **Always build one with
/// `DateTime.utc(...)`**: a local `DateTime(...)` silently shifts a time that
/// doesn't exist on the *device's own* clock (e.g. 02:30 on the US spring
/// daylight-saving day), which would move a slot entered in another zone by an
/// hour. [wallClockToUtc] asserts this. Values this file returns are UTC-flagged
/// for the same reason (and so `DateFormat` doesn't re-apply the device offset).
class EventTimezone {
  EventTimezone._();

  static const String pacific = 'America/Los_Angeles';
  static const String india = 'Asia/Kolkata';
  static const String defaultZone = pacific;
  static const List<String> supported = [pacific, india];
}

const Duration _indiaOffset = Duration(hours: 5, minutes: 30);
const Duration _pacificStandardOffset = Duration(hours: 8);
const Duration _pacificDaylightOffset = Duration(hours: 7);

/// [timezone] if it is a supported zone, else the default (Pacific).
String normalizeTimezone(String? timezone) =>
    EventTimezone.supported.contains(timezone)
    ? timezone!
    : EventTimezone.defaultZone;

/// Short label shown beside a time: `PT` or `IST`.
String timezoneLabel(String? timezone) =>
    normalizeTimezone(timezone) == EventTimezone.india ? 'IST' : 'PT';

/// The UTC instant at which [wallClock] occurs in [timezone]. [wallClock] must
/// be UTC-flagged (see the library comment).
///
/// Pacific daylight time runs from 02:00 on the second Sunday of March to
/// 02:00 on the first Sunday of November. On those two days the clock repeats
/// or skips an hour: a wall-clock time of 02:00 or later on the March day
/// counts as daylight time, and one before 02:00 on the November day counts
/// as daylight time too (the first of the two repeats), matching the existing
/// Parayan code.
DateTime wallClockToUtc(DateTime wallClock, String timezone) {
  assert(
    wallClock.isUtc,
    'Build wall-clock values with DateTime.utc, not a local DateTime',
  );
  final fields = _fieldsAsUtc(wallClock);
  if (normalizeTimezone(timezone) == EventTimezone.india) {
    return fields.subtract(_indiaOffset);
  }
  final isDaylight =
      !fields.isBefore(_pacificDaylightStartWall(fields.year)) &&
      fields.isBefore(_pacificDaylightEndWall(fields.year));
  return fields.add(
    isDaylight ? _pacificDaylightOffset : _pacificStandardOffset,
  );
}

/// The wall clock in [timezone] at the UTC instant [utc], as a UTC-flagged
/// [DateTime] holding the wall-clock fields.
DateTime utcToWallClock(DateTime utc, String timezone) {
  final instant = utc.toUtc();
  if (normalizeTimezone(timezone) == EventTimezone.india) {
    return instant.add(_indiaOffset);
  }
  final isDaylight =
      !instant.isBefore(_pacificDaylightStartInstant(instant.year)) &&
      instant.isBefore(_pacificDaylightEndInstant(instant.year));
  return instant.subtract(
    isDaylight ? _pacificDaylightOffset : _pacificStandardOffset,
  );
}

DateTime _fieldsAsUtc(DateTime d) => DateTime.utc(
  d.year,
  d.month,
  d.day,
  d.hour,
  d.minute,
  d.second,
  d.millisecond,
);

/// The [nth] (1-based) Sunday of [month] in [year], as a day of the month.
int _nthSunday(int year, int month, int nth) {
  final firstOfMonth = DateTime.utc(year, month);
  // DateTime.weekday is 1 (Monday) to 7 (Sunday).
  final firstSunday = 1 + (DateTime.sunday - firstOfMonth.weekday) % 7;
  return firstSunday + 7 * (nth - 1);
}

// Wall-clock moments (as UTC-flagged field values) at which the Pacific
// offset changes.
DateTime _pacificDaylightStartWall(int year) =>
    DateTime.utc(year, 3, _nthSunday(year, 3, 2), 2);

DateTime _pacificDaylightEndWall(int year) =>
    DateTime.utc(year, 11, _nthSunday(year, 11, 1), 2);

// The same two changes as real UTC instants: 02:00 PST is 10:00Z in March,
// and 02:00 PDT is 09:00Z in November.
DateTime _pacificDaylightStartInstant(int year) =>
    DateTime.utc(year, 3, _nthSunday(year, 3, 2), 10);

DateTime _pacificDaylightEndInstant(int year) =>
    DateTime.utc(year, 11, _nthSunday(year, 11, 1), 9);
