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
