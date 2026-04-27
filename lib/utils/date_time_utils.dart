import 'package:intl/intl.dart';
import 'package:gajanan_maharaj_sevekari/utils/marathi_utils.dart';

/// Formats a date into a long format: "d MMMM, yyyy" for Marathi or "MMMM d, yyyy" for others.
String formatDateLong(DateTime date, String locale) {
  final dateStr = locale == 'mr'
      ? DateFormat('d MMMM, yyyy', 'mr').format(date)
      : DateFormat('MMMM d, yyyy').format(date);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date with the day of the week: "EEEE, d MMMM, yyyy".
String formatDateWithDay(DateTime date, String locale) {
  final dateStr = locale == 'mr'
      ? DateFormat('EEEE, d MMMM, yyyy', 'mr').format(date)
      : DateFormat('EEEE, MMMM d, yyyy').format(date);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date into a short format: "d MMMM" for Marathi or "MMMM d" for others.
String formatDateShort(DateTime date, String locale) {
  final dateStr = locale == 'mr'
      ? DateFormat('d MMMM', 'mr').format(date)
      : DateFormat('MMMM d').format(date);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats a date into a short format with day: "EEEE, d MMMM" or "EEEE, MMMM d".
String formatDateShortWithDay(DateTime date, String locale) {
  final dateStr = locale == 'mr'
      ? DateFormat('EEEE, d MMMM', 'mr').format(date)
      : DateFormat('EEEE, MMMM d').format(date);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}

/// Formats time in a localized format (e.g., "10:30 AM").
String formatTimeLocalized(DateTime date, String locale) {
  final timeStr = DateFormat.jm(locale).format(date);
  return locale == 'mr' ? toMarathiNumerals(timeStr) : timeStr;
}

/// Formats time with descriptive periods for Marathi (e.g., "सकाळी १०:३०").
String formatTimeDetailed(DateTime time, String locale) {
  if (locale == 'mr') {
    final hour = time.hour;
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
    final formattedTime = DateFormat('hh:mm').format(time);
    final marathiTime = toMarathiNumerals(formattedTime);
    return '$period $marathiTime';
  } else {
    return DateFormat.jm().format(time);
  }
}

/// Formats date to "MMMM yyyy" format.
String formatMonthYear(DateTime date, String locale) {
  final dateStr = DateFormat('MMMM yyyy', locale).format(date);
  return locale == 'mr' ? toMarathiNumerals(dateStr) : dateStr;
}
