import 'dart:math';

/// A 6-character, uppercase-letter-and-digit sharing code (e.g. for a
/// Vaari/Parayan/Group Namjap/Signup Signup join link). This is an
/// anti-spam friction code, not a security credential, so
/// [Random.secure] is used for good measure rather than as a hard
/// requirement.
String generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
  );
}

/// The join code a sign-up should have after an admin edits it. Off means no
/// code. Staying on keeps the code. Switching on makes a new one - even if an
/// old code is still around - so a code from before the requirement was turned
/// off never comes back. A required but missing or blank code is replaced.
String? joinCodeAfterEdit({
  required bool wasRequired,
  required String? currentCode,
  required bool nowRequired,
  String Function() generate = generateJoinCode,
}) {
  if (!nowRequired) return null;
  final keep =
      wasRequired && currentCode != null && currentCode.trim().isNotEmpty;
  return keep ? currentCode : generate();
}
