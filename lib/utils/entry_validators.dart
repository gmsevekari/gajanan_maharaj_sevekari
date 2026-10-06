import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';

final RegExp _emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

/// Whether [value] (trimmed) looks like an email address.
bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// The pledge amount typed in [text] (trimmed), or null when it isn't a
/// finite number from 0 to [SignupEntry.maxPledgeAmount] - the range
/// Firestore accepts. `double.tryParse` alone would let NaN, Infinity and
/// huge amounts through to a rules rejection.
double? parsePledgeAmount(String text) {
  final amount = double.tryParse(text.trim());
  if (amount == null || !amount.isFinite) return null;
  if (amount < 0 || amount > SignupEntry.maxPledgeAmount) return null;
  return amount;
}

/// A pledge amount for display or a form field: whole numbers without a
/// trailing ".0" (51.0 -> "51"), fractional amounts as they are (50.5 ->
/// "50.5").
String formatPledgeAmount(double amount) =>
    amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
