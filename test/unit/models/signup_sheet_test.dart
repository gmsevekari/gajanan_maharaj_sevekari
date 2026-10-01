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
        status: SignupSheetStatus.published,
        requiresJoinCode: true,
        joinCode: 'ABC123',
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: 'admin@example.com',
        headerImageUrl: 'https://example.com/header.jpg',
      );

      final map = sheet.toMap();
      final roundTripped = SignupSheet.fromMap('sheet1', map);

      expect(roundTripped.id, 'sheet1');
      expect(roundTripped.titleEn, 'Sunday Prasad Seva');
      expect(roundTripped.titleMr, 'रविवार प्रसाद सेवा');
      expect(roundTripped.descriptionEn, 'Cook and serve prasad');
      expect(roundTripped.descriptionMr, 'प्रसाद शिजवा आणि वाढा');
      expect(roundTripped.groupId, 'gajanan_maharaj_seattle');
      expect(roundTripped.status, SignupSheetStatus.published);
      expect(roundTripped.requiresJoinCode, true);
      expect(roundTripped.joinCode, 'ABC123');
      expect(roundTripped.startDate, startDate);
      expect(roundTripped.endDate, endDate);
      expect(roundTripped.createdAt, createdAt);
      expect(roundTripped.updatedAt, updatedAt);
      expect(roundTripped.createdBy, 'admin@example.com');
      expect(roundTripped.headerImageUrl, 'https://example.com/header.jpg');
    });

    test('headerImageUrl defaults to null when not specified', () {
      final sheet = SignupSheet(
        titleEn: 'No Image',
        titleMr: 'प्रतिमा नाही',
        groupId: 'group1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      expect(sheet.headerImageUrl, isNull);
      expect(sheet.toMap()['headerImageUrl'], isNull);
    });

    test('defaults to status draft when not specified', () {
      final sheet = SignupSheet(
        titleEn: 'Draft Sheet',
        titleMr: 'मसुदा',
        groupId: 'group1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      expect(sheet.status, SignupSheetStatus.draft);
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
        expect(sheet.status, SignupSheetStatus.draft);
        expect(sheet.requiresJoinCode, false);
      },
    );

    test('fromMap defaults createdAt/updatedAt to now when absent', () {
      final before = DateTime.now();
      final sheet = SignupSheet.fromMap('sheet5', {});
      final after = DateTime.now();

      expect(
        sheet.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        sheet.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        sheet.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        sheet.updatedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    group('SignupSheetStatus', () {
      test('fromMap parses published and closed statuses', () {
        final published = SignupSheet.fromMap('s1', {'status': 'published'});
        final closed = SignupSheet.fromMap('s2', {'status': 'closed'});

        expect(published.status, SignupSheetStatus.published);
        expect(closed.status, SignupSheetStatus.closed);
      });

      test('fromMap defaults an unrecognized status string to draft', () {
        final sheet = SignupSheet.fromMap('s3', {'status': 'not-a-status'});

        expect(sheet.status, SignupSheetStatus.draft);
      });

      test('fromMap defaults a wrong-typed status field to draft', () {
        final sheet = SignupSheet.fromMap('s4', {'status': 42});

        expect(sheet.status, SignupSheetStatus.draft);
      });

      test('toMap writes the enum name as a plain string', () {
        final sheet = SignupSheet(
          titleEn: 'T',
          titleMr: 'T',
          groupId: 'g',
          status: SignupSheetStatus.closed,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          createdBy: 'admin@example.com',
        );

        expect(sheet.toMap()['status'], 'closed');
      });
    });

    group('requiresJoinCode/joinCode invariant', () {
      test(
        'constructor throws an assertion error when joinCode is set but requiresJoinCode is false',
        () {
          expect(
            () => SignupSheet(
              titleEn: 'T',
              titleMr: 'T',
              groupId: 'g',
              requiresJoinCode: false,
              joinCode: 'ABC123',
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
              createdBy: 'admin@example.com',
            ),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test('constructor allows joinCode when requiresJoinCode is true', () {
        final sheet = SignupSheet(
          titleEn: 'T',
          titleMr: 'T',
          groupId: 'g',
          requiresJoinCode: true,
          joinCode: 'ABC123',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          createdBy: 'admin@example.com',
        );

        expect(sheet.joinCode, 'ABC123');
      });
    });

    group('copyWith', () {
      final base = SignupSheet(
        id: 'sheet1',
        titleEn: 'Original',
        titleMr: 'मूळ',
        groupId: 'group1',
        status: SignupSheetStatus.draft,
        requiresJoinCode: true,
        joinCode: 'ABC123',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdBy: 'admin@example.com',
      );

      test('with no arguments returns an identical copy', () {
        final copy = base.copyWith();

        expect(copy, equals(base));
      });

      test('preserves unspecified fields', () {
        final updated = base.copyWith(titleEn: 'Updated');

        expect(updated.titleEn, 'Updated');
        expect(updated.titleMr, base.titleMr);
        expect(updated.groupId, base.groupId);
        expect(updated.status, base.status);
        expect(updated.joinCode, base.joinCode);
      });

      test('updates the status field', () {
        final updated = base.copyWith(status: SignupSheetStatus.published);

        expect(updated.status, SignupSheetStatus.published);
      });

      test(
        'clears joinCode automatically when requiresJoinCode set to false',
        () {
          final updated = base.copyWith(requiresJoinCode: false);

          expect(updated.requiresJoinCode, false);
          expect(updated.joinCode, isNull);
        },
      );

      test('updates the headerImageUrl field', () {
        final updated = base.copyWith(
          headerImageUrl: 'https://example.com/new.jpg',
        );

        expect(updated.headerImageUrl, 'https://example.com/new.jpg');
      });

      test('preserves headerImageUrl when not specified', () {
        final withImage = base.copyWith(
          headerImageUrl: 'https://example.com/a.jpg',
        );
        final updated = withImage.copyWith(titleEn: 'Updated');

        expect(updated.headerImageUrl, 'https://example.com/a.jpg');
      });
    });

    group('equality', () {
      test(
        'two sheets with identical fields are equal and share a hashCode',
        () {
          final createdAt = DateTime(2026, 1, 1);
          final updatedAt = DateTime(2026, 1, 2);
          final a = SignupSheet(
            id: 'sheet1',
            titleEn: 'T',
            titleMr: 'T',
            groupId: 'g',
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: 'admin@example.com',
          );
          final b = SignupSheet(
            id: 'sheet1',
            titleEn: 'T',
            titleMr: 'T',
            groupId: 'g',
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: 'admin@example.com',
          );

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('sheets differing by one field are not equal', () {
        final createdAt = DateTime(2026, 1, 1);
        final a = SignupSheet(
          id: 'sheet1',
          titleEn: 'T',
          titleMr: 'T',
          groupId: 'g',
          createdAt: createdAt,
          updatedAt: createdAt,
          createdBy: 'admin@example.com',
        );
        final b = a.copyWith(titleEn: 'Different');

        expect(a == b, isFalse);
      });

      test('sheets differing only by headerImageUrl are not equal', () {
        final createdAt = DateTime(2026, 1, 1);
        final a = SignupSheet(
          id: 'sheet1',
          titleEn: 'T',
          titleMr: 'T',
          groupId: 'g',
          createdAt: createdAt,
          updatedAt: createdAt,
          createdBy: 'admin@example.com',
          headerImageUrl: 'https://example.com/a.jpg',
        );
        final b = a.copyWith(headerImageUrl: 'https://example.com/b.jpg');

        expect(a == b, isFalse);
      });
    });

    group('fromMap type guards', () {
      test('falls back to defaults when fields have the wrong type', () {
        final sheet = SignupSheet.fromMap('sheet6', {
          'titleEn': 123,
          'titleMr': true,
          'descriptionEn': 1.5,
          'descriptionMr': [],
          'groupId': {},
          'requiresJoinCode': 'yes',
          'joinCode': 42,
          'startDate': '2026-01-01',
          'endDate': 12345,
          'createdBy': 99,
          'headerImageUrl': 7,
        });

        expect(sheet.titleEn, '');
        expect(sheet.titleMr, '');
        expect(sheet.descriptionEn, '');
        expect(sheet.descriptionMr, '');
        expect(sheet.groupId, '');
        expect(sheet.requiresJoinCode, false);
        expect(sheet.joinCode, isNull);
        expect(sheet.startDate, isNull);
        expect(sheet.endDate, isNull);
        expect(sheet.createdBy, '');
        expect(sheet.headerImageUrl, isNull);
      });
    });
  });
}
