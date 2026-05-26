/// Total number of adhyays in the Gajanan Vijay cycle.
const int _totalAdhyays = 21;

/// Number of adhyays assigned per parayan.
const int _adhyaysPerParayan = 3;

/// Default starting assignment when no prior adhyays exist.
const List<int> _defaultAdhyays = [1, 2, 3];

/// Given a list of assigned adhyays (e.g., [19, 20, 21]),
/// returns the next [_adhyaysPerParayan] adhyays in the 1–21 cycle
/// (e.g., [1, 2, 3]).
///
/// If the input is empty, returns [1, 2, 3] as the default starting
/// assignment.
List<int> getNextAdhyays(List<int> currentAdhyays) {
  if (currentAdhyays.isEmpty) {
    return _defaultAdhyays;
  }

  final currentSet = currentAdhyays.toSet();

  // Find the "end value" — the value v whose cyclic successor is NOT
  // in the set, i.e. the last element in the consecutive chain.
  final endVal = currentAdhyays.cast<int?>().firstWhere(
    (v) => !currentSet.contains((v! % _totalAdhyays) + 1),
    orElse: () => currentAdhyays.reduce((a, b) => a > b ? a : b),
  )!;

  final nextStart = (endVal % _totalAdhyays) + 1;

  return List<int>.generate(
    _adhyaysPerParayan,
    (i) => ((nextStart - 1 + i) % _totalAdhyays) + 1,
  );
}
