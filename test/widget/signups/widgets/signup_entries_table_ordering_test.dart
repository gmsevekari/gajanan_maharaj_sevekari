import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/signups/widgets/signup_entries_table.dart';

void main() {
  SignupSlot slot(String id, {DateTime? startAt, int sortOrder = 0}) =>
      SignupSlot(
        id: id,
        labelEn: id,
        labelMr: id,
        startAt: startAt,
        endAt: startAt?.add(const Duration(hours: 2)),
        capacity: 5,
        sortOrder: sortOrder,
        createdAt: DateTime.utc(2026),
      );

  SignupEntry entry(String name, String slotId) => SignupEntry(
    id: '$slotId-$name',
    slotId: slotId,
    name: name,
    joinedAt: DateTime.utc(2026),
  );

  /// Entries in the order the table lists them, as `slot:name`.
  List<String> ordered(List<SignupEntry> entries, List<SignupSlot> slots) {
    final byId = {for (final s in slots) s.id: s};
    return (entries.toList()
          ..sort((a, b) => SignupEntriesTable.compareEntries(a, b, byId)))
        .map((e) => '${e.slotId}:${e.name}')
        .toList();
  }

  final day1 = DateTime.utc(2026, 7, 1, 9);
  final day2 = DateTime.utc(2026, 7, 2, 9);

  test('orders by the slot\'s start, then name within a slot', () {
    final slots = [slot('late', startAt: day2), slot('early', startAt: day1)];
    final entries = [
      entry('Zed', 'late'),
      entry('Bea', 'early'),
      entry('Amy', 'late'),
      entry('Cal', 'early'),
    ];

    expect(ordered(entries, slots), [
      'early:Bea',
      'early:Cal',
      'late:Amy',
      'late:Zed',
    ]);
  });

  test('uses slot order when two slots start together, and keeps each '
      'slot\'s entries together', () {
    final slots = [
      slot('b', startAt: day1, sortOrder: 2),
      slot('a', startAt: day1, sortOrder: 1),
    ];
    final entries = [entry('Zed', 'a'), entry('Amy', 'b'), entry('Bea', 'a')];

    expect(ordered(entries, slots), ['a:Bea', 'a:Zed', 'b:Amy']);
  });

  test('falls back to the slot id so slots that tie on start and order '
      'still group', () {
    final slots = [slot('s2', startAt: day1), slot('s1', startAt: day1)];
    final entries = [
      entry('Zed', 's1'),
      entry('Amy', 's2'),
      entry('Bea', 's1'),
      entry('Cal', 's2'),
    ];

    expect(ordered(entries, slots), ['s1:Bea', 's1:Zed', 's2:Amy', 's2:Cal']);
  });

  test('puts slots with no start after dated slots', () {
    final slots = [slot('undated'), slot('dated', startAt: day1)];
    final entries = [entry('A', 'undated'), entry('B', 'dated')];

    expect(ordered(entries, slots), ['dated:B', 'undated:A']);
  });

  group('an entry whose slot is gone', () {
    final slots = [slot('live', startAt: day2), slot('undated')];

    test('sorts after entries that have a slot, in either position', () {
      final orphan = entry('Orphan', 'gone');
      final live = entry('Live', 'live');
      final byId = {for (final s in slots) s.id: s};

      // Both argument orders, so both branches of the comparison run.
      expect(
        SignupEntriesTable.compareEntries(orphan, live, byId),
        greaterThan(0),
      );
      expect(
        SignupEntriesTable.compareEntries(live, orphan, byId),
        lessThan(0),
      );
    });

    test('sorts after undated slots too', () {
      final entries = [entry('Orphan', 'gone'), entry('U', 'undated')];
      expect(ordered(entries, slots), ['undated:U', 'gone:Orphan']);
    });

    test('groups several orphans by slot id, then name', () {
      final entries = [
        entry('Zed', 'gone2'),
        entry('Amy', 'gone1'),
        entry('Bea', 'gone2'),
        entry('Live', 'live'),
        entry('Cal', 'gone1'),
      ];

      expect(ordered(entries, slots), [
        'live:Live',
        'gone1:Amy',
        'gone1:Cal',
        'gone2:Bea',
        'gone2:Zed',
      ]);
    });

    test('two orphans of the same slot compare by name', () {
      final byId = {for (final s in slots) s.id: s};
      expect(
        SignupEntriesTable.compareEntries(
          entry('Amy', 'gone'),
          entry('Bea', 'gone'),
          byId,
        ),
        lessThan(0),
      );
    });
  });

  test('is zero for the same entry', () {
    final slots = {'a': slot('a', startAt: day1)};
    final e = entry('Amy', 'a');
    expect(SignupEntriesTable.compareEntries(e, e, slots), 0);
  });
}
