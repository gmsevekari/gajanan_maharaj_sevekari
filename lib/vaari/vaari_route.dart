/// A single named stop along [dnyaneshwarPalkhiRoute].
class VaariRouteStop {
  final String nameEn;
  final String nameMr;

  /// Distance from the route's starting stop (Alandi), in miles.
  final double cumulativeMiles;

  const VaariRouteStop({
    required this.nameEn,
    required this.nameMr,
    required this.cumulativeMiles,
  });

  String get name => nameEn;

  String localizedName(String langCode) => langCode == 'mr' ? nameMr : nameEn;
}

/// The Sant Dnyaneshwar Maharaj Palkhi route: Alandi -> Pandharpur.
/// Distances are cumulative miles from Alandi, scaled from the published
/// leg-by-leg distances so the full route totals the event's 155-mile
/// target distance.
const List<VaariRouteStop> dnyaneshwarPalkhiRoute = [
  VaariRouteStop(nameEn: 'Alandi', nameMr: 'आळंदी', cumulativeMiles: 0.0),
  VaariRouteStop(nameEn: 'Pune', nameMr: 'पुणे', cumulativeMiles: 13.1),
  VaariRouteStop(nameEn: 'Saswad', nameMr: 'सासवड', cumulativeMiles: 31.6),
  VaariRouteStop(nameEn: 'Jejuri', nameMr: 'जेजुरी', cumulativeMiles: 41.8),
  VaariRouteStop(nameEn: 'Valhe', nameMr: 'वाल्हे', cumulativeMiles: 52.0),
  VaariRouteStop(nameEn: 'Lonand', nameMr: 'लोणंद', cumulativeMiles: 65.7),
  VaariRouteStop(nameEn: 'Taradgaon', nameMr: 'तरडगाव', cumulativeMiles: 69.8),
  VaariRouteStop(nameEn: 'Phaltan', nameMr: 'फलटण', cumulativeMiles: 83.5),
  VaariRouteStop(nameEn: 'Barad', nameMr: 'बरड', cumulativeMiles: 94.8),
  VaariRouteStop(
    nameEn: 'Natepute',
    nameMr: 'नातेपुते',
    cumulativeMiles: 109.1,
  ),
  VaariRouteStop(
    nameEn: 'Malshiras',
    nameMr: 'माळशिरस',
    cumulativeMiles: 116.3,
  ),
  VaariRouteStop(nameEn: 'Velapur', nameMr: 'वेळापूर', cumulativeMiles: 130.0),
  VaariRouteStop(
    nameEn: 'Bhandishegaon',
    nameMr: 'भंडीशेगाव',
    cumulativeMiles: 143.7,
  ),
  VaariRouteStop(nameEn: 'Wakhari', nameMr: 'वाखरी', cumulativeMiles: 150.9),
  VaariRouteStop(
    nameEn: 'Pandharpur',
    nameMr: 'पंढरपूर',
    cumulativeMiles: 155.0,
  ),
];

const double _kmPerMile = 1.60934;

/// Converts a distance in [unit] ('mi' or otherwise treated as km) to miles
/// — the unit [dnyaneshwarPalkhiRoute] is defined in.
double distanceUnitToMiles(double distance, String unit) =>
    unit == 'mi' ? distance : distance / _kmPerMile;

/// Converts a distance in miles to [unit] ('mi' or otherwise treated as km).
double milesToDistanceUnit(double miles, String unit) =>
    unit == 'mi' ? miles : miles * _kmPerMile;

/// Which pass (1-indexed) of the fixed-length route a cumulative distance
/// falls on, and the progress within that pass.
class VaariLapProgress {
  final int lapNumber;
  final double milesInLap;

  const VaariLapProgress({required this.lapNumber, required this.milesInLap});
}

/// A cumulative distance that exceeds [totalMiles] means the group has
/// finished the route and started again from Alandi — this computes which
/// lap (1-indexed) [coveredMiles] falls on and the progress within that lap
/// (0..[totalMiles]). Landing exactly on a lap boundary is treated as having
/// just finished that lap (`milesInLap == totalMiles`) rather than starting
/// the next one at 0.
VaariLapProgress computeLapProgress(double coveredMiles, double totalMiles) {
  final safeCovered = coveredMiles < 0 ? 0.0 : coveredMiles;
  if (totalMiles <= 0 || safeCovered == 0) {
    return const VaariLapProgress(lapNumber: 1, milesInLap: 0.0);
  }

  final completedLaps = (safeCovered / totalMiles).floor();
  final remainder = safeCovered - completedLaps * totalMiles;

  // Tolerate floating-point slop when checking for an exact lap boundary.
  if (remainder < 1e-9) {
    return VaariLapProgress(lapNumber: completedLaps, milesInLap: totalMiles);
  }
  return VaariLapProgress(lapNumber: completedLaps + 1, milesInLap: remainder);
}
