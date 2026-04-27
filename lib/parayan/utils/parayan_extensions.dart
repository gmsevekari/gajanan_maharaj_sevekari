import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:gajanan_maharaj_sevekari/utils/date_time_utils.dart';

extension ParayanEventFormatting on ParayanEvent {
  /// Returns a human-readable date range, intelligently handling same-day vs multi-day events.
  /// Includes time ranges for specific parayan types.
  String getSmartDate(String locale, {bool includeTime = true}) {
    final isSameDay =
        startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    String dateStr;
    if (isSameDay) {
      dateStr = formatDateWithDay(startDate, locale);
    } else {
      final start = formatDateShortWithDay(startDate, locale);
      final end = formatDateWithDay(endDate, locale);
      dateStr = "$start - $end";
    }

    // Add time range for multi-day or specialized events
    if (includeTime && (type == ParayanType.guruPushya || type == ParayanType.threeDay)) {
      final startTime = formatTimeLocalized(startDate, locale);
      final endTime = formatTimeLocalized(endDate, locale);
      return "$dateStr ($startTime - $endTime)";
    }

    return dateStr;
  }

  /// Returns a descriptive status message based on the event's current state.
  /// [usePreallocatedWording] uses a simplified message for events where participants are pre-assigned.
  String getDescriptiveStatus(
    AppLocalizations localizations,
    String locale, {
    bool usePreallocatedWording = false,
  }) {
    final date = formatDateLong(startDate, locale);

    if (usePreallocatedWording) {
      switch (status) {
        case 'upcoming':
        case 'enrolling':
        case 'allocated':
          return localizations.parayanWillStartOn(date);
        case 'ongoing':
          return localizations.statusOngoingDesc;
        case 'completed':
          return localizations.statusCompletedDesc;
        default:
          return "";
      }
    }

    switch (status) {
      case 'upcoming':
        return type == ParayanType.oneDay || type == ParayanType.guruPushya
            ? localizations.statusUpcomingOneDay(date)
            : localizations.statusUpcomingMultiDay(date);
      case 'enrolling':
        return localizations.statusEnrollingDesc(date);
      case 'allocated':
        return localizations.statusAllocatedDesc(date);
      case 'ongoing':
        return localizations.statusOngoingDesc;
      case 'completed':
        return localizations.statusCompletedDesc;
      default:
        return "";
    }
  }
}
