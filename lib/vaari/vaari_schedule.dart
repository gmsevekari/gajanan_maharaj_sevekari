/// A single scheduled halt of the actual Palkhi at [stopIndex] in
/// [dnyaneshwarPalkhiRoute], covering [startDate] through [endDate]
/// inclusive (India Standard Time calendar dates).
class VaariScheduleEntry {
  final int stopIndex;
  final DateTime startDate;
  final DateTime endDate;

  const VaariScheduleEntry({
    required this.stopIndex,
    required this.startDate,
    required this.endDate,
  });
}

/// The Sant Dnyaneshwar Maharaj Palkhi's published 2026 halt schedule, one
/// entry per stop in `dnyaneshwarPalkhiRoute` (see vaari_route.dart), in IST
/// calendar dates. Departs Alandi the evening of July 12 and arrives in
/// Pandharpur for Ashadhi Ekadashi Mahapuja on July 28.
final List<VaariScheduleEntry> dnyaneshwarPalkhiSchedule = [
  VaariScheduleEntry(
    stopIndex: 0, // Alandi
    startDate: DateTime.utc(2026, 7, 12),
    endDate: DateTime.utc(2026, 7, 12),
  ),
  VaariScheduleEntry(
    stopIndex: 1, // Pune
    startDate: DateTime.utc(2026, 7, 13),
    endDate: DateTime.utc(2026, 7, 14),
  ),
  VaariScheduleEntry(
    stopIndex: 2, // Saswad
    startDate: DateTime.utc(2026, 7, 15),
    endDate: DateTime.utc(2026, 7, 16),
  ),
  VaariScheduleEntry(
    stopIndex: 3, // Jejuri
    startDate: DateTime.utc(2026, 7, 17),
    endDate: DateTime.utc(2026, 7, 17),
  ),
  VaariScheduleEntry(
    stopIndex: 4, // Valhe
    startDate: DateTime.utc(2026, 7, 18),
    endDate: DateTime.utc(2026, 7, 18),
  ),
  VaariScheduleEntry(
    stopIndex: 5, // Lonand
    startDate: DateTime.utc(2026, 7, 19),
    endDate: DateTime.utc(2026, 7, 19),
  ),
  VaariScheduleEntry(
    stopIndex: 6, // Taradgaon
    startDate: DateTime.utc(2026, 7, 20),
    endDate: DateTime.utc(2026, 7, 20),
  ),
  VaariScheduleEntry(
    stopIndex: 7, // Phaltan
    startDate: DateTime.utc(2026, 7, 21),
    endDate: DateTime.utc(2026, 7, 21),
  ),
  VaariScheduleEntry(
    stopIndex: 8, // Barad
    startDate: DateTime.utc(2026, 7, 22),
    endDate: DateTime.utc(2026, 7, 22),
  ),
  VaariScheduleEntry(
    stopIndex: 9, // Natepute
    startDate: DateTime.utc(2026, 7, 23),
    endDate: DateTime.utc(2026, 7, 23),
  ),
  VaariScheduleEntry(
    stopIndex: 10, // Purandawade
    startDate: DateTime.utc(2026, 7, 24),
    endDate: DateTime.utc(2026, 7, 24),
  ),
  VaariScheduleEntry(
    stopIndex: 11, // Velapur
    startDate: DateTime.utc(2026, 7, 25),
    endDate: DateTime.utc(2026, 7, 25),
  ),
  VaariScheduleEntry(
    stopIndex: 12, // Bhandishegaon
    startDate: DateTime.utc(2026, 7, 26),
    endDate: DateTime.utc(2026, 7, 26),
  ),
  VaariScheduleEntry(
    stopIndex: 13, // Wakhari
    startDate: DateTime.utc(2026, 7, 27),
    endDate: DateTime.utc(2026, 7, 27),
  ),
  VaariScheduleEntry(
    stopIndex: 14, // Pandharpur
    startDate: DateTime.utc(2026, 7, 28),
    endDate: DateTime.utc(2026, 7, 28),
  ),
];

const Duration _istOffset = Duration(hours: 5, minutes: 30);

/// Today's calendar date in India Standard Time (UTC+5:30, no DST),
/// independent of the device's own local timezone.
DateTime currentIstDate() {
  final istNow = DateTime.now().toUtc().add(_istOffset);
  return DateTime.utc(istNow.year, istNow.month, istNow.day);
}

/// The route stop index the actual Palkhi occupies on [date] (an IST
/// calendar date) — clamped to the first stop before the schedule begins
/// and the last stop once it's over.
int scheduledStopIndexForDate(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  for (final entry in dnyaneshwarPalkhiSchedule) {
    if (!utcDate.isAfter(entry.endDate)) {
      return entry.stopIndex;
    }
  }
  return dnyaneshwarPalkhiSchedule.last.stopIndex;
}

