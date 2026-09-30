import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';

void main() {
  group('SignupSheet', () {
    test('round-trips through toMap/fromMap', () {
      final createdAt = DateTime(2026, 1, 1, 8, 0);
      final updatedAt = DateTime(2026, 1, 2, 8, 0);
      final startDate = DateTime(2026, 3, 1);
      final endDate = DateTime(2026, 3, 31);
      final sheet = SignupSheet(
        id: 'sheet1',
        titleEn: 'Sunday Prasad Seva',
        titleMr: 'रविवार प्रसाद सेवा',
        descriptionEn: 'Cook and serve prasad',
        descriptionMr: 'प्रसाद शिजवा आणि वाढा',
        groupId: 'gajanan_maharaj_seattle',
        status: 'published',
        requiresJoinCode: true,
        joinCode: 'ABC123',
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: 'admin@example.com',
      );

      final map = sheet.toMap();
      final roundTripped = SignupSheet.fromMap('sheet1', map);

      expect(roundTripped.id, 'sheet1');
      expect(roundTripped.titleEn, 'Sunday Prasad Seva');
      expect(roundTripped.titleMr, 'रविवार प्रसाद सेवा');
      expect(roundTripped.descriptionEn, 'Cook and serve prasad');
      expect(roundTripped.descriptionMr, 'प्रसाद शिजवा आणि वाढा');
      expect(roundTripped.groupId, 'gajanan_maharaj_seattle');
      expect(roundTripped.status, 'published');
      expect(roundTripped.requiresJoinCode, true);
      expect(roundTripped.joinCode, 'ABC123');
      expect(roundTripped.startDate, startDate);
      expect(roundTripped.endDate, endDate);
      expect(roundTripped.createdAt, createdAt);
      expect(roundTripped.updatedAt, updatedAt);
      expect(roundTripped.createdBy, 'admin@example.com');
    });

    test('defaults to status "draft" when not specified', () {
      final sheet = SignupSheet(
        titleEn: 'Draft Sheet',
        titleMr: 'मसुदा',
        groupId: 'group1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      expect(sheet.status, 'draft');
    });

    test('joinCode is null when requiresJoinCode is false', () {
      final sheet = SignupSheet(
        titleEn: 'Open Sheet',
        titleMr: 'खुली शीट',
        groupId: 'group1',
        requiresJoinCode: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      final map = sheet.toMap();
      expect(map['joinCode'], isNull);

      final roundTripped = SignupSheet.fromMap('sheet2', map);
      expect(roundTripped.requiresJoinCode, false);
      expect(roundTripped.joinCode, isNull);
    });

    test('startDate and endDate are null when absent', () {
      final sheet = SignupSheet(
        titleEn: 'No Date Range',
        titleMr: 'तारीख नाही',
        groupId: 'group1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      final map = sheet.toMap();
      expect(map['startDate'], isNull);
      expect(map['endDate'], isNull);

      final roundTripped = SignupSheet.fromMap('sheet3', map);
      expect(roundTripped.startDate, isNull);
      expect(roundTripped.endDate, isNull);
    });

    test(
      'fromMap defaults missing required string fields to empty rather than throwing',
      () {
        final sheet = SignupSheet.fromMap('sheet4', {});

        expect(sheet.titleEn, '');
        expect(sheet.titleMr, '');
        expect(sheet.groupId, '');
        expect(sheet.status, 'draft');
        expect(sheet.requiresJoinCode, false);
      },
    );
  });
}
