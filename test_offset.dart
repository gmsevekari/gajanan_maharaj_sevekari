import 'dart:core';

String toEnglishNumerals(String input) {
  const marathiToEnglish = {
    '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
    '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
  };
  return input.split('').map((char) => marathiToEnglish[char] ?? char).join();
}

void main() {
  String text = '''
स. १०:३०: अभिषेक
स. ११:३०: वस्त्रालंकार
दु. १२:००: साईबाबा मध्यान आरती
दु. १२:३०: गजानन महाराज मध्यान आरती
दु. ०१:००: प्रसाद
''';

  // Suppose the local event startTime is 11:30 PM (23:30)
  // But the first time in the text is 10:30 AM (10:30).
  // The offset should be 23:30 - 10:30 = +13 hours.
  
  DateTime referenceLocalTime = DateTime(2024, 1, 1, 23, 30); // 11:30 PM

  final regex = RegExp(r'((?:स\.|दु\.|सं\.|रा\.|am|pm|AM|PM)\s+)?([०-९0-9]{1,2}):([०-९0-9]{2})(?:\s+(am|pm|AM|PM))?');
  
  final firstMatch = regex.firstMatch(text);
  if (firstMatch == null) return;

  int _parseHour(String hourStr, String? periodPrefix, String? periodSuffix) {
    int h = int.parse(toEnglishNumerals(hourStr));
    final period = (periodPrefix ?? periodSuffix ?? '').toLowerCase().trim();
    if (period == 'दु.' || period == 'सं.' || period == 'रा.' || period == 'pm') {
      if (h < 12) h += 12;
    } else if (period == 'स.' || period == 'am') {
      if (h == 12) h = 0;
    }
    return h;
  }

  int firstHour = _parseHour(firstMatch.group(2)!, firstMatch.group(1), firstMatch.group(4));
  int firstMin = int.parse(toEnglishNumerals(firstMatch.group(3)!));

  int offsetMinutes = (referenceLocalTime.hour * 60 + referenceLocalTime.minute) - (firstHour * 60 + firstMin);
  print('Offset Minutes: $offsetMinutes');

  // Now replace all times
  String convertedText = text.replaceAllMapped(regex, (match) {
    int h = _parseHour(match.group(2)!, match.group(1), match.group(4));
    int m = int.parse(toEnglishNumerals(match.group(3)!));

    int totalMinutes = h * 60 + m + offsetMinutes;
    
    // handle day wraparound (simplified, ignoring date shift text for now)
    totalMinutes = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);

    int newHour = totalMinutes ~/ 60;
    int newMin = totalMinutes % 60;

    String newPeriod = '';
    if (newHour >= 5 && newHour < 12) newPeriod = 'स.';
    else if (newHour >= 12 && newHour < 17) newPeriod = 'दु.';
    else if (newHour >= 17 && newHour < 20) newPeriod = 'सं.';
    else newPeriod = 'रा.';

    int displayHour = newHour > 12 ? newHour - 12 : (newHour == 0 ? 12 : newHour);
    
    // We should output in the same format as date_time_utils formatTimeLocalized
    // Let's just output `१०:३० स.` if Marathi, `10:30 am` if English.
    // Wait, the user has 'स. १०:३०', we should just format it exactly as formatTimeLocalized!
    // But formatTimeLocalized puts the period at the end!
    
    String hrStr = displayHour.toString().padLeft(2, '0');
    String minStr = newMin.toString().padLeft(2, '0');
    
    return '$hrStr:$minStr $newPeriod';
  });

  print(convertedText);
}
