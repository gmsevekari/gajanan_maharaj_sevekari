import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:gajanan_maharaj_sevekari/event_calendar/event_calendar_screen.dart';
import 'package:gajanan_maharaj_sevekari/models/parayan_event.dart';
import 'package:gajanan_maharaj_sevekari/parayan/parayan_type.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarExportService {
  /// Exports a list of [Event] (Special Events) to an iCalendar file.
  static Future<void> exportEventsToIcs(
    List<Event> events,
    String baseName,
  ) async {
    if (events.isEmpty) return;
    const fileName = 'special_events.ics'; // Standard .ics is more robust on iOS
    final icsContent = _generateEventsIcs(events, baseName);
    await _handleExport(icsContent, fileName);
  }

  /// Exports a list of [ParayanEvent] to an iCalendar file.
  static Future<void> exportParayansToIcs(
    List<ParayanEvent> events,
    String baseName,
  ) async {
    if (events.isEmpty) return;
    const fileName = 'parayan_schedule.ics'; // Standard .ics is more robust on iOS
    final icsContent = _generateParayansIcs(events, baseName);
    await _handleExport(icsContent, fileName);
  }

  @visibleForTesting
  static String generateEventsIcs(List<Event> events, String calName) {
    // ... logic remains same, just renaming for clarity if needed
    // Actually, I'll just change the visibility for now.
    return _generateEventsIcs(events, calName);
  }

  static String _generateEventsIcs(List<Event> events, String calName) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//Gajanan Maharaj Sevekari//NONSGML v1.0//EN\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');
    buffer.write(_fold('X-WR-CALNAME:${_escapeIcs(calName)}') + '\r\n');
    buffer.write('X-WR-TIMEZONE:UTC\r\n');

    for (final event in events) {
      final start = event.start_time.toDate().toUtc();
      final end =
          event.end_time?.toDate().toUtc() ??
          start.add(const Duration(hours: 1));

      final stamp = DateFormat(
        "yyyyMMdd'T'HHmmss'Z'",
      ).format(DateTime.now().toUtc());
      final dtStart = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(start);
      final dtEnd = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(end);

      buffer.write('BEGIN:VEVENT\r\n');
      buffer.write(
        _fold('UID:${start.millisecondsSinceEpoch}_${event.title_en.hashCode}@gmsevekari.com') + '\r\n',
      );
      buffer.write('DTSTAMP:$stamp\r\n');
      buffer.write('DTSTART:$dtStart\r\n');
      buffer.write('DTEND:$dtEnd\r\n');
      buffer.write(_fold('SUMMARY:${_escapeIcs(event.title_en)}') + '\r\n');
      buffer.write(_fold('DESCRIPTION:${_escapeIcs(event.details_en ?? "")}') + '\r\n');
      if (event.location_en != null) {
        buffer.write(_fold('LOCATION:${_escapeIcs(event.location_en!)}') + '\r\n');
      }
      buffer.write('END:VEVENT\r\n');
    }

    buffer.write('END:VCALENDAR\r\n');
    return buffer.toString();
  }

  @visibleForTesting
  static String generateParayansIcs(List<ParayanEvent> events, String calName) {
    return _generateParayansIcs(events, calName);
  }

  static String _generateParayansIcs(List<ParayanEvent> events, String calName) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//Gajanan Maharaj Sevekari//NONSGML v1.0//EN\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');
    buffer.write(_fold('X-WR-CALNAME:${_escapeIcs(calName)}') + '\r\n');
    buffer.write('X-WR-TIMEZONE:UTC\r\n');

    for (final event in events) {
      final start = event.startDate;
      final end = event.endDate.add(const Duration(days: 1));

      final stamp = DateFormat(
        "yyyyMMdd'T'HHmmss'Z'",
      ).format(DateTime.now().toUtc());
      final dtStart = DateFormat("yyyyMMdd").format(start);
      final dtEnd = DateFormat("yyyyMMdd").format(end);

      String typeLabel = event.type == ParayanType.oneDay
          ? "1-Day Parayan"
          : event.type == ParayanType.threeDay
          ? "3-Day Parayan"
          : "GuruPushya Parayan";

      buffer.write('BEGIN:VEVENT\r\n');
      buffer.write(
        _fold('UID:${start.millisecondsSinceEpoch}_${event.titleEn.hashCode}@gmsevekari.com') + '\r\n',
      );
      buffer.write('DTSTAMP:$stamp\r\n');
      buffer.write('DTSTART;VALUE=DATE:$dtStart\r\n');
      buffer.write('DTEND;VALUE=DATE:$dtEnd\r\n');
      buffer.write(_fold('SUMMARY:${_escapeIcs("$typeLabel: ${event.titleEn}")}') + '\r\n');
      buffer.write(
        _fold('DESCRIPTION:Join the ${event.titleEn} parayan. Type: $typeLabel') + '\r\n',
      );
      buffer.write('END:VEVENT\r\n');
    }

    buffer.write('END:VCALENDAR\r\n');
    return buffer.toString();
  }

  static String _fold(String line) {
    if (line.length <= 75) return line;
    final buffer = StringBuffer();
    buffer.write(line.substring(0, 75));
    var remaining = line.substring(75);
    while (remaining.length > 74) {
      buffer.write('\r\n ');
      buffer.write(remaining.substring(0, 74));
      remaining = remaining.substring(74);
    }
    if (remaining.isNotEmpty) {
      buffer.write('\r\n ');
      buffer.write(remaining);
    }
    return buffer.toString();
  }

  static String _escapeIcs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\r\n', '\\n')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\n');
  }

  static Future<void> _handleExport(String content, String fileName) async {
    if (kIsWeb) {
      final encodedContent = Uri.encodeComponent(content);
      final url = 'data:text/calendar;charset=utf8,$encodedContent';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } else {
      // Use flutter_file_dialog for a native "Save As" experience on mobile
      try {
        final directory = await getTemporaryDirectory();
        final tempPath = '${directory.path}/$fileName';
        final file = File(tempPath);
        await file.writeAsString(content);

        final params = SaveFileDialogParams(sourceFilePath: tempPath);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath == null) {
          // User cancelled
          return;
        }
      } catch (e) {
        // Fallback to temporary file + share if file dialog fails
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(content);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path, mimeType: 'text/calendar')],
            subject: 'Calendar Export',
          ),
        );
      }
    }
  }
}
