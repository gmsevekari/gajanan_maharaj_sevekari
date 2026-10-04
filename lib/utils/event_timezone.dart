/// Timezone helpers for events entered in a fixed wall-clock zone (sign-up
/// slots). Pure Dart: no Flutter imports.
///
/// Only the two zones the app uses are supported - Seattle (US Pacific) and
/// India - because there is no timezone database in the app. The conversion
/// is done by hand, like the Parayan and Namjap screens do, but written and
/// tested here on its own. The Pacific rule is the current US one (in force
/// since 2007); India has no daylight saving.
///
/// A "wall clock" value is what a clock on the wall of a zone shows. It goes
/// in as separate year/month/day/hour/minute arguments, never as a
/// `DateTime`: a local `DateTime(...)` silently shifts a time that doesn't
/// exist on the *device's own* clock (e.g. 02:30 on the US spring
/// daylight-saving day), which would move a slot entered in another zone by an
/// hour. Wall-clock values coming out are UTC-flagged `DateTime`s holding the
/// wall-clock fields, so `DateFormat` doesn't re-apply the device's offset.
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

/// US clocks change at 02:00 local time on both transition days.
const int _changeoverHour = 2;

/// [timezone] if it is a supported zone, else the default (Pacific).
String normalizeTimezone(String? timezone) =>
    EventTimezone.supported.contains(timezone)
    ? timezone!
    : EventTimezone.defaultZone;

/// Short label shown beside a time: `PT` or `IST`.
String timezoneLabel(String? timezone) =>
    normalizeTimezone(timezone) == EventTimezone.india ? 'IST' : 'PT';

/// The UTC instant at which the wall clock in [timezone] shows the given
/// date and time.
///
/// Pacific daylight time runs from 02:00 on the second Sunday of March to
/// 02:00 on the first Sunday of November. On those two days the clock skips
/// or repeats an hour, and the result never goes backwards as the wall clock
/// moves forward:
/// - **March, 02:00-02:59** never shows on a real clock. Every such time is
///   read as the moment the clocks jump (03:00 PDT), so ranges across the gap
///   keep their order (01:30-02:15 is a valid 30 minutes) and nothing lands
///   before 01:59. Two skipped times therefore map to the same instant.
/// - **November, 01:00-01:59** shows twice; it is read as the first (daylight)
///   occurrence.
DateTime wallClockToUtc({
  required int year,
  required int month,
  required int day,
  int hour = 0,
  int minute = 0,
  int second = 0,
  required String timezone,
}) {
  final wall = DateTime.utc(year, month, day, hour, minute, second);
  if (normalizeTimezone(timezone) == EventTimezone.india) {
    return wall.subtract(_indiaOffset);
  }
  final springWall = DateTime.utc(
    wall.year,
    3,
    _springForwardDay(wall.year),
    _changeoverHour,
  );
  final springInstant = springWall.add(_pacificStandardOffset);
  final skippedUntilWall = springWall.add(const Duration(hours: 1));
  if (!wall.isBefore(springWall) && wall.isBefore(skippedUntilWall)) {
    return springInstant; // a skipped time: clamp to the moment of the jump
  }
  final fallWall = DateTime.utc(
    wall.year,
    11,
    _fallBackDay(wall.year),
    _changeoverHour,
  );
  final isDaylight =
      !wall.isBefore(skippedUntilWall) && wall.isBefore(fallWall);
  return wall.add(isDaylight ? _pacificDaylightOffset : _pacificStandardOffset);
}

/// The wall clock in [timezone] at the UTC instant [utc], as a UTC-flagged
/// [DateTime] holding the wall-clock fields.
DateTime utcToWallClock(DateTime utc, String timezone) {
  final instant = utc.toUtc();
  if (normalizeTimezone(timezone) == EventTimezone.india) {
    return instant.add(_indiaOffset);
  }
  // 02:00 PST is when clocks go forward; 02:00 PDT is when they go back.
  final daylightFromInstant = DateTime.utc(
    instant.year,
    3,
    _springForwardDay(instant.year),
    _changeoverHour,
  ).add(_pacificStandardOffset);
  final daylightToInstant = DateTime.utc(
    instant.year,
    11,
    _fallBackDay(instant.year),
    _changeoverHour,
  ).add(_pacificDaylightOffset);
  final isDaylight =
      !instant.isBefore(daylightFromInstant) &&
      instant.isBefore(daylightToInstant);
  return instant.subtract(
    isDaylight ? _pacificDaylightOffset : _pacificStandardOffset,
  );
}

/// Day of March on which US clocks go forward: the second Sunday.
int _springForwardDay(int year) => _nthSunday(year, 3, 2);

/// Day of November on which US clocks go back: the first Sunday.
int _fallBackDay(int year) => _nthSunday(year, 11, 1);

/// The [nth] (1-based) Sunday of [month] in [year], as a day of the month.
int _nthSunday(int year, int month, int nth) {
  final firstOfMonth = DateTime.utc(year, month);
  // DateTime.weekday is 1 (Monday) to 7 (Sunday).
  final firstSunday = 1 + (DateTime.sunday - firstOfMonth.weekday) % 7;
  return firstSunday + 7 * (nth - 1);
}
