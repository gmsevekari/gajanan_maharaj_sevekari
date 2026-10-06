/// How a "claim my sign up" attempt ended.
enum ClaimEntriesStatus {
  /// Every entry with that phone number now belongs to this device.
  success,

  /// No entry has that phone number (or the sign-up is gone).
  notFound,

  /// An entry with that phone number already belongs to another device;
  /// nothing was changed.
  alreadyClaimed,

  /// The sign-up needs a join code and it was missing or wrong.
  invalidJoinCode,
}

/// The outcome of a claim: its [status] and, on success, how many entries
/// the phone number matched.
class ClaimEntriesResult {
  final ClaimEntriesStatus status;
  final int count;

  const ClaimEntriesResult(this.status, {this.count = 0});
}
