import 'package:flutter/foundation.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class Festival {
  final String id;
  final String nameEn;
  final String nameMr;
  final DateTime startDate;
  final DateTime endDate;
  final ThemePreset themePreset;

  Festival({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.startDate,
    required this.endDate,
    required this.themePreset,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    ThemePreset preset = ThemePreset.saffron;
    try {
      preset = ThemePreset.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['themePreset'] as String?)?.toLowerCase(),
        orElse: () => ThemePreset.saffron,
      );
    } catch (_) {}

    return Festival(
      id: json['id'] as String? ?? 'unknown',
      nameEn: json['name_en'] as String? ?? 'Unknown',
      nameMr: json['name_mr'] as String? ?? 'Unknown',
      startDate:
          DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      // Make endDate inclusive by adding a day minus one millisecond if needed, or we handle it in `isActive`
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      themePreset: preset,
    );
  }

  bool isActive(DateTime currentDate) {
    // Normalize currentDate to start of day to avoid time-of-day precision issues
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    // Add 1 day to end date to ensure the festival spans the entire end date
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    return !normalizedCurrent.isBefore(normalizedStart) &&
        normalizedCurrent.isBefore(normalizedEnd);
  }
}
