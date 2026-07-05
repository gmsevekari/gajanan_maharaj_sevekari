import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/vaari/vaari_schedule.dart';

void main() {
  group('scheduledStopIndexForDate', () {
    test('clamps to Alandi before the schedule begins', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 1, 1)), 0);
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 11)), 0);
    });

    test('is at Alandi on the departure day', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 12)), 0);
    });

    test('halts at Pune for both of its scheduled days', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 13)), 1);
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 14)), 1);
    });

    test('halts at Saswad for both of its scheduled days', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 15)), 2);
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 16)), 2);
    });

    test('advances to the next single-day stop each day', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 17)), 3); // Jejuri
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 18)), 4); // Valhe
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 19)), 5); // Lonand
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 20)), 6); // Taradgaon
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 21)), 7); // Phaltan
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 22)), 8); // Barad
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 23)), 9); // Natepute
      expect(
        scheduledStopIndexForDate(DateTime(2026, 7, 24)),
        10,
      ); // Purandawade
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 25)), 11); // Velapur
      expect(
        scheduledStopIndexForDate(DateTime(2026, 7, 26)),
        12,
      ); // Bhandishegaon
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 27)), 13); // Wakhari
    });

    test('arrives at Pandharpur on Ashadhi Ekadashi', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 28)), 14);
    });

    test('clamps to Pandharpur after the schedule ends', () {
      expect(scheduledStopIndexForDate(DateTime(2026, 7, 29)), 14);
      expect(scheduledStopIndexForDate(DateTime(2027, 1, 1)), 14);
    });
  });

  group('currentIstDate', () {
    test('returns a date-only value (no time component)', () {
      final today = currentIstDate();
      expect(today.hour, 0);
      expect(today.minute, 0);
      expect(today.second, 0);
    });

    test('returns a UTC date-only value', () {
      final today = currentIstDate();
      expect(today.isUtc, true);
    });
  });
}
