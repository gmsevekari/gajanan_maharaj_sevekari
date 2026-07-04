/// A single named stop along [dnyaneshwarPalkhiRoute].
class VaariRouteStop {
  final String name;

  /// Distance from the route's starting stop (Alandi), in miles.
  final double cumulativeMiles;

  const VaariRouteStop({required this.name, required this.cumulativeMiles});
}

/// The Sant Dnyaneshwar Maharaj Palkhi route: Alandi -> Pandharpur.
/// Distances are cumulative miles from Alandi, scaled from the published
/// leg-by-leg distances so the full route totals the event's 155-mile
/// target distance.
const List<VaariRouteStop> dnyaneshwarPalkhiRoute = [
  VaariRouteStop(name: 'Alandi', cumulativeMiles: 0.0),
  VaariRouteStop(name: 'Pune', cumulativeMiles: 13.1),
  VaariRouteStop(name: 'Saswad', cumulativeMiles: 31.6),
  VaariRouteStop(name: 'Jejuri', cumulativeMiles: 41.8),
  VaariRouteStop(name: 'Valhe', cumulativeMiles: 52.0),
  VaariRouteStop(name: 'Lonand', cumulativeMiles: 65.7),
  VaariRouteStop(name: 'Taradgaon', cumulativeMiles: 69.8),
  VaariRouteStop(name: 'Phaltan', cumulativeMiles: 83.5),
  VaariRouteStop(name: 'Barad', cumulativeMiles: 94.8),
  VaariRouteStop(name: 'Natepute', cumulativeMiles: 109.1),
  VaariRouteStop(name: 'Purandawade', cumulativeMiles: 116.3),
  VaariRouteStop(name: 'Velapur', cumulativeMiles: 130.0),
  VaariRouteStop(name: 'Bhandishegaon', cumulativeMiles: 143.7),
  VaariRouteStop(name: 'Wakhari', cumulativeMiles: 150.9),
  VaariRouteStop(name: 'Pandharpur', cumulativeMiles: 155.0),
];

const double _kmPerMile = 1.60934;

/// Converts a distance in [unit] ('mi' or otherwise treated as km) to miles
/// — the unit [dnyaneshwarPalkhiRoute] is defined in.
double distanceUnitToMiles(double distance, String unit) =>
    unit == 'mi' ? distance : distance / _kmPerMile;

/// Converts a distance in miles to [unit] ('mi' or otherwise treated as km).
double milesToDistanceUnit(double miles, String unit) =>
    unit == 'mi' ? miles : miles * _kmPerMile;
