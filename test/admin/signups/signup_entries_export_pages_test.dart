import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/signups/signup_entries_export_pages.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);

  SignupSlot slot(String id, {int day = 10, int sortOrder = 0}) => SignupSlot(
    id: id,
    labelEn: id,
    labelMr: '',
    startAt: DateTime.utc(2026, 10, day, 18),
    endAt: DateTime.utc(2026, 10, day, 20),
    timezone: 'America/Los_Angeles',
    capacity: 500,
    claimedCount: 0,
    sortOrder: sortOrder,
    createdAt: now,
  );

  List<SignupEntry> entriesFor(String slotId, int count) => [
    for (var i = 0; i < count; i++)
      SignupEntry(id: '$slotId$i', slotId: slotId, name: 'n$i', joinedAt: now),
  ];

  group('paginateSignupExport', () {
    test('keeps a short list on one page at full sharpness', () {
      final pages = paginateSignupExport(
        slots: [slot('a'), slot('b', day: 11)],
        entries: [...entriesFor('a', 3), ...entriesFor('b', 2)],
      );

      expect(pages, hasLength(1));
      expect(pages.single.slots.map((s) => s.id), ['a', 'b']);
      expect(pages.single.entries, hasLength(5));
      expect(pages.single.pixelRatio, SignupExportPage.idealPixelRatio);
    });

    test(
      'reckons even a one-entry slot as tall as its date and title need',
      () {
        final page = paginateSignupExport(
          slots: [slot('a')],
          entries: entriesFor('a', 1),
        ).single;

        expect(
          page.estimatedHeight,
          SignupExportPage.chromeHeight + SignupExportPage.slotMinHeight,
        );
      },
    );

    test('has no pages when there are no entries', () {
      expect(
        paginateSignupExport(slots: [slot('a')], entries: const []),
        isEmpty,
      );
    });

    test('leaves slots with no entries off every page', () {
      final pages = paginateSignupExport(
        slots: [slot('a'), slot('empty', day: 11)],
        entries: entriesFor('a', 2),
      );

      expect(pages.single.slots.map((s) => s.id), ['a']);
    });

    test('ignores entries whose slot was not chosen', () {
      final pages = paginateSignupExport(
        slots: [slot('a')],
        entries: [...entriesFor('a', 1), ...entriesFor('other', 4)],
      );

      expect(pages.single.entries.map((e) => e.slotId), ['a']);
    });

    test('puts slots in date order, whatever order they were given in', () {
      final pages = paginateSignupExport(
        slots: [slot('late', day: 20), slot('early', day: 11)],
        entries: [...entriesFor('late', 1), ...entriesFor('early', 1)],
      );

      expect(pages.single.slots.map((s) => s.id), ['early', 'late']);
    });

    test('starts a new page rather than let one grow too tall', () {
      final perSlot = 30;
      final pages = paginateSignupExport(
        slots: [slot('a'), slot('b', day: 11), slot('c', day: 12)],
        entries: [
          ...entriesFor('a', perSlot),
          ...entriesFor('b', perSlot),
          ...entriesFor('c', perSlot),
        ],
      );

      expect(pages.length, greaterThan(1));
      for (final page in pages) {
        expect(
          page.estimatedHeight,
          lessThanOrEqualTo(SignupExportPage.maxPageHeight),
        );
      }
      // Nothing lost, nothing repeated, and slots are never cut in two.
      expect(pages.expand((p) => p.entries), hasLength(perSlot * 3));
      expect(pages.expand((p) => p.slots).map((s) => s.id), ['a', 'b', 'c']);
      for (final page in pages) {
        final ids = page.slots.map((s) => s.id).toSet();
        expect(page.entries.every((e) => ids.contains(e.slotId)), isTrue);
      }
    });

    test('keeps one slot whole on its own page, drawn less sharply', () {
      final pages = paginateSignupExport(
        slots: [slot('big'), slot('small', day: 11)],
        entries: [...entriesFor('big', 100), ...entriesFor('small', 1)],
      );

      expect(pages.map((p) => p.slots.map((s) => s.id).toList()), [
        ['big'],
        ['small'],
      ]);
      expect(pages.first.entries, hasLength(100));
      expect(
        pages.first.pixelRatio,
        lessThan(SignupExportPage.idealPixelRatio),
      );
      expect(pages.first.pixelRatio, greaterThanOrEqualTo(1));
      expect(pages.last.pixelRatio, SignupExportPage.idealPixelRatio);
    });

    test('never draws below its own pixel size, however long a slot is', () {
      final pages = paginateSignupExport(
        slots: [slot('huge')],
        entries: entriesFor('huge', 1000),
      );

      expect(pages.single.pixelRatio, 1);
    });

    test('keeps the image within the texture limit at the chosen ratio', () {
      final pages = paginateSignupExport(
        slots: [for (var i = 0; i < 10; i++) slot('s$i', day: 10 + i)],
        entries: [for (var i = 0; i < 10; i++) ...entriesFor('s$i', 13)],
      );

      for (final page in pages) {
        expect(
          page.estimatedHeight * page.pixelRatio,
          lessThanOrEqualTo(SignupExportPage.maxTexturePixels),
        );
      }
    });
  });
}
