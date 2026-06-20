import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

/// Formats a date into a long format: "d MMMM, yyyy" for Marathi or "MMMM d, yyyy" for others.
String formatDateLong(DateTime date, String locale) {
  final localDate = date.toLocal();
  final dateStr = locale == 'mr'
      ? DateFormat('d MMMM, yyyy', 'mr').format(localDate)
      : DateFormat('MMMM d, yyyy').format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date with the day of the week: "EEEE, d MMMM, yyyy".
String formatDateWithDay(DateTime date, String locale) {
  final localDate = date.toLocal();
  final dateStr = locale == 'mr'
      ? DateFormat('EEEE, d MMMM, yyyy', 'mr').format(localDate)
      : DateFormat('EEEE, MMMM d, yyyy').format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date into a short format: "d MMMM" for Marathi or "MMMM d" for others.
String formatDateShort(DateTime date, String locale) {
  final localDate = date.toLocal();
  final dateStr = locale == 'mr'
      ? DateFormat('d MMMM', 'mr').format(localDate)
      : DateFormat('MMMM d').format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date into a short format with day: "EEEE, d MMMM" or "EEEE, MMMM d".
String formatDateShortWithDay(DateTime date, String locale) {
  final localDate = date.toLocal();
  final dateStr = locale == 'mr'
      ? DateFormat('EEEE, d MMMM', 'mr').format(localDate)
      : DateFormat('EEEE, MMMM d').format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats time in a localized format (e.g., "10:30 am" or "स. १०:३०").
String formatTimeLocalized(DateTime date, String locale) {
  final localDate = date.toLocal();
  if (locale == 'mr') {
    final hour = localDate.hour;
    String period;
    if (hour >= 5 && hour < 12) {
      period = "स.";
    } else if (hour >= 12 && hour < 17) {
      period = "दु.";
    } else if (hour >= 17 && hour < 20) {
      period = "सं.";
    } else {
      period = "रा.";
    }
    final formattedTime = DateFormat('h:mm').format(localDate);
    final marathiTime = toMarathiNumerals(formattedTime);
    return '$period $marathiTime';
  } else {
    return DateFormat('h:mm a', 'en').format(localDate).toLowerCase();
  }
}

/// Formats time with descriptive periods for Marathi (e.g., "सकाळी १०:३०").
String formatTimeDetailed(DateTime time, String locale) {
  final localDate = time.toLocal();
  if (locale == 'mr') {
    final hour = localDate.hour;
    String period;
    if (hour >= 5 && hour < 12) {
      period = "सकाळी";
    } else if (hour >= 12 && hour < 17) {
      period = "दुपारी";
    } else if (hour >= 17 && hour < 20) {
      period = "सायंकाळी";
    } else {
      period = "रात्री";
    }
    final formattedTime = DateFormat('h:mm').format(localDate);
    final marathiTime = toMarathiNumerals(formattedTime);
    return '$period $marathiTime';
  } else {
    return DateFormat('h:mm a', 'en').format(localDate).toLowerCase();
  }
}

/// Formats a date into a medium format: "MMM d, yyyy" with optional time.
///
/// When [includeTime] is true, appends " - hh:mm a" (e.g., "Jun 20, 2026 - 02:30 PM").
String formatDateMedium(DateTime date, String locale, {bool includeTime = false}) {
  final localDate = date.toLocal();
  final formatStr = includeTime ? 'MMM d, yyyy - hh:mm a' : 'MMM d, yyyy';
  final dateStr = DateFormat(formatStr, locale).format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats date to "MMMM yyyy" format.
String formatMonthYear(DateTime date, String locale) {
  final localDate = date.toLocal();
  final dateStr = DateFormat('MMMM yyyy', locale).format(localDate);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Dynamically converts text timings in a block of text (like "स. १०:३०" or "10:30 am")
/// based on the offset of a reference time. Assumes the first time in the text 
/// corresponds to the referenceLocalTime.
String convertTextTimings(String text, DateTime referenceLocalTime, String locale) {
  if (text.trim().isEmpty) return text;

  // Match times with optional am/pm/marathi period prefixes or suffixes.
  // Supports both colon (:) and period (.) separators (e.g. 10:30 or 10.30).
  final regex = RegExp(r'((?:स\.|दु\.|सं\.|रा\.|am|pm|AM|PM)\s+)?([०-९0-9]{1,2})[:\.]([०-९0-9]{2})(?:\s+(am|pm|AM|PM))?');
  
  final firstMatch = regex.firstMatch(text);
  if (firstMatch == null) return text; // No times found

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

  int lastParsedMinutes = -1;

  return text.replaceAllMapped(regex, (match) {
    int h = int.parse(toEnglishNumerals(match.group(2)!));
    int m = int.parse(toEnglishNumerals(match.group(3)!));
    final period = (match.group(1) ?? match.group(4) ?? '').toLowerCase().trim();

    if (period == 'दु.' || period == 'सं.' || period == 'रा.' || period == 'pm') {
      if (h < 12) h += 12;
    } else if (period == 'स.' || period == 'am') {
      if (h == 12) h = 0;
    }

    int currentTotalMinutes = h * 60 + m;

    // Sequential Time Guarantee: Schedules usually progress forward in time.
    // If time jumps backwards (e.g. 11:30 AM -> 1:00 AM or 12:00 AM), 
    // it's likely a missing or incorrect AM/PM suffix.
    if (lastParsedMinutes != -1 && currentTotalMinutes < lastParsedMinutes) {
      if (h < 12) {
        h += 12;
        currentTotalMinutes += 12 * 60;
      }
    }
    lastParsedMinutes = currentTotalMinutes;

    int totalMinutes = currentTotalMinutes + offsetMinutes;
    totalMinutes = (totalMinutes % (24 * 60) + (24 * 60)) % (24 * 60);

    int newHour = totalMinutes ~/ 60;
    int newMin = totalMinutes % 60;

    // Use dummy date to format
    final dummyDate = DateTime(2000, 1, 1, newHour, newMin);
    return formatTimeLocalized(dummyDate, locale);
  });
}
