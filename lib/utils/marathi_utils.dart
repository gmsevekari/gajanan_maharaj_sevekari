import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'locale_extensions.dart';

String toMarathiNumerals(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], marathi[i]);
  }
  return input;
}

String toEnglishNumerals(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  for (int i = 0; i < marathi.length; i++) {
    input = input.replaceAll(marathi[i], english[i]);
  }
  return input;
}

String formatNumberLocalized(
  dynamic number,
  String languageCode, {
  bool pad = true,
}) {
  if (number == null) return '';

  num? parsedNumber;
  if (number is num) {
    parsedNumber = number;
  } else if (number is String) {
    parsedNumber = num.tryParse(number);
  }

  // Use Indian numbering system for commas (e.g. 1,23,456)
  final formatter = NumberFormat('#,##,###', 'en_IN');
  String numStr = parsedNumber != null
      ? formatter.format(parsedNumber)
      : number.toString();

  if (pad) {
    if (numStr.length == 1 && int.tryParse(numStr) != null) {
      numStr = numStr.padLeft(2, '0');
    }
  }

  if (languageCode != 'mr') return numStr;
  return toMarathiNumerals(numStr);
}

String formatLocalizedText(String text, Locale locale) {
  if (locale.useMarathiContent) {
    return toMarathiNumerals(text);
  }
  return text;
}

/// Formats a distance value to one decimal place, converting digits to
/// Marathi numerals when [languageCode] is 'mr'.
String formatDistanceLocalized(double distance, String languageCode) {
  final formatted = distance.toStringAsFixed(1);
  return languageCode == 'mr' ? toMarathiNumerals(formatted) : formatted;
}

/// Human-readable distance unit label for the given [languageCode] —
/// Firestore stores the short code ('mi'/'km'), but the UI should show
/// "miles"/"मैल" and "किमी" rather than the raw code.
String localizedDistanceUnitLabel(String distanceUnit, String languageCode) {
  final isMiles = distanceUnit == 'mi';
  if (languageCode == 'mr') {
    return isMiles ? 'मैल' : 'किमी';
  }
  return isMiles ? 'miles' : distanceUnit;
}
