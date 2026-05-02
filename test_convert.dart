import 'package:intl/intl.dart';

String toEnglishNumerals(String input) {
  const marathiToEnglish = {
    '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
    '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
  };
  return input.split('').map((char) => marathiToEnglish[char] ?? char).join();
}

String toMarathiNumerals(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const marathi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], marathi[i]);
  }
  return input;
}

String formatTimeLocalized(DateTime date, String locale) {
  final localDate = date.toLocal();
  if (locale == 'mr') {
    final hour = localDate.hour;
    String period;
    if (hour >= 5 && hour < 12) period = "स.";
    else if (hour >= 12 && hour < 17) period = "दु.";
    else if (hour >= 17 && hour < 20) period = "सं.";
    else period = "रा.";
    final formattedTime = DateFormat('h:mm').format(localDate);
    final marathiTime = toMarathiNumerals(formattedTime);
    return '$period $marathiTime';
  } else {
    return DateFormat('h:mm a', 'en').format(localDate).toLowerCase();
  }
}

String convertTextTimings(String text, DateTime referenceLocalTime, String locale) {
  if (text.trim().isEmpty) return text;
  final regex = RegExp(r'((?:स\.|दु\.|सं\.|रा\.|am|pm|AM|PM)\s+)?([०-९0-9]{1,2}):([०-९0-9]{2})(?:\s+(am|pm|AM|PM))?');
  
  final firstMatch = regex.firstMatch(text);
  if (firstMatch == null) return text; 

  int parseHour(String hourStr, String? periodPrefix, String? periodSuffix) {
    int h = int.parse(toEnglishNumerals(hourStr));
    final period = (periodPrefix ?? periodSuffix ?? '').toLowerCase().trim();
    if (period == 'दु.' || period == 'सं.' || period == 'रा.' || period == 'pm') {
      if (h < 12) h += 12;
    } else if (period == 'स.' || period == 'am') {
      if (h == 12) h = 0;
    }
    return h;
  }

  int firstHour = parseHour(firstMatch.group(2)!, firstMatch.group(1), firstMatch.group(4));
  int firstMin = int.parse(toEnglishNumerals(firstMatch.group(3)!));

  int offsetMinutes = (referenceLocalTime.hour * 60 + referenceLocalTime.minute) - (firstHour * 60 + firstMin);
  
  if (offsetMinutes == 0) return text; 

  return text.replaceAllMapped(regex, (match) {
    int h = parseHour(match.group(2)!, match.group(1), match.group(4));
    int m = int.parse(toEnglishNumerals(match.group(3)!));

    int totalMinutes = h * 60 + m + offsetMinutes;
    totalMinutes = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);

    int newHour = totalMinutes ~/ 60;
    int newMin = totalMinutes % 60;

    final dummyDate = DateTime(2000, 1, 1, newHour, newMin);
    return formatTimeLocalized(dummyDate, locale);
  });
}

void main() {
  String enText = '''
10:30 am: Abhishek
11:30 am: Vastralankar
12:00 pm: Sai baba Arti
12:30 pm: Gajanan Maharaj Arti
01:00 pm: Prasad
''';

  DateTime referenceLocalTime = DateTime(2024, 1, 1, 23, 00); // 11:00 PM

  String convertedEn = convertTextTimings(enText, referenceLocalTime, 'en');
  print('--- English ---');
  print(convertedEn);

  String mrText = '''
स. १०:३०: अभिषेक
स. ११:३०: वस्त्रालंकार
दु. १२:००: साईबाबा मध्यान आरती
दु. १२:३०: गजानन महाराज मध्यान आरती
दु. ०१:००: प्रसाद
''';
  String convertedMr = convertTextTimings(mrText, referenceLocalTime, 'mr');
  print('--- Marathi ---');
  print(convertedMr);
}
