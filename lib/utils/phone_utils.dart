/// Country codes the app already recognises when splitting a stored phone
/// number (the same set the Parayan sign-up uses, plus Singapore and South
/// Africa, which it validates).
const List<String> knownCountryCodes = [
  '+971',
  '+91',
  '+44',
  '+61',
  '+65',
  '+27',
  '+1',
];

/// Fewest digits a phone number needs shy of its country code. Matches the
/// Parayan sign-up: 10 unless the country is known to use fewer.
int minPhoneDigits(String countryCode) => switch (countryCode.trim()) {
  '+65' => 8,
  '+27' || '+971' => 9,
  _ => 10,
};

/// A country code is a `+` and one to four digits.
bool isValidCountryCode(String? code) =>
    code != null && RegExp(r'^\+[0-9]{1,4}$').hasMatch(code.trim());

/// Splits a stored phone number into its country code and the rest, so an
/// entry can be edited in a code field plus a number field.
///
/// A number that starts with a [knownCountryCodes] entry is split there
/// (longest code first). A number stored as digits only - the current format,
/// see [joinPhone] - is split on a known code's digits when more than ten
/// digits are stored, since a ten-digit number saved before country codes
/// existed (`4255551234`) can start with the same digits as a code (`6505551234`
/// starts with Singapore's 65). Anything else - such a number, or one with a
/// code the app doesn't know - keeps its whole text as the number under
/// [defaultCode], so nothing the admin typed is lost.
({String code, String number}) splitPhone(String? phone, String defaultCode) {
  final value = phone?.trim() ?? '';
  if (value.isEmpty) return (code: defaultCode, number: '');
  final codes = [...knownCountryCodes]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final code in codes) {
    if (value.startsWith(code)) {
      return (code: code, number: value.substring(code.length).trim());
    }
  }
  if (RegExp(r'^\d+$').hasMatch(value) && value.length > _legacyNumberLength) {
    for (final code in codes) {
      final digits = code.substring(1);
      if (value.startsWith(digits) &&
          value.length - digits.length >= minPhoneDigits(code)) {
        return (code: code, number: value.substring(digits.length));
      }
    }
  }
  return (code: defaultCode, number: value);
}

/// Numbers saved before country codes were added are ten digits.
const int _legacyNumberLength = 10;

/// Joins a country code and number for storage as digits only - the code's
/// digits then the number's, with no plus, spaces, dashes or brackets (so
/// `+1` and `(425) 555-1234` store as `14255551234`) - or `null` when the
/// number has no digits (a lone prefilled code isn't a phone number).
String? joinPhone(String code, String number) {
  final numberDigits = number.replaceAll(RegExp(r'\D'), '');
  if (numberDigits.isEmpty) return null;
  return '${code.replaceAll(RegExp(r'\D'), '')}$numberDigits';
}

/// Whether two stored phone numbers are the same line.
///
/// Compares digits only, and treats one as matching the other when it is the
/// same number minus a country code - entries saved before country codes
/// were added have none, so an exact comparison would miss a repeat signup.
/// Numbers shorter than eight digits never match.
bool phonesMatch(String? a, String? b) {
  final digitsA = a?.replaceAll(RegExp(r'\D'), '') ?? '';
  final digitsB = b?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digitsA.length < 8 || digitsB.length < 8) return false;
  return digitsA.endsWith(digitsB) || digitsB.endsWith(digitsA);
}
