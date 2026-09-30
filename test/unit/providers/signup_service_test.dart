import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late SignupService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = SignupService(firestore: fakeFirestore);
  });

  SignupSheet buildSheet({
    String titleEn = 'Sunday Prasad Seva',
    String titleMr = 'रविवार प्रसाद सेवा',
    String groupId = 'group_1',
    SignupSheetStatus status = SignupSheetStatus.draft,
    bool requiresJoinCode = false,
    String? joinCode,
  }) {
    final now = DateTime.now();
    return SignupSheet(
      titleEn: titleEn,
      titleMr: titleMr,
      groupId: groupId,
      status: status,
      requiresJoinCode: requiresJoinCode,
      joinCode: joinCode,
      createdAt: now,
      updatedAt: now,
      createdBy: 'admin@example.com',
    );
  }

  SignupSlot buildSlot({
    String labelEn = 'Week 1',
    String labelMr = 'आठवडा १',
    int capacity = 3,
    int sortOrder = 0,
  }) {
    return SignupSlot(
      labelEn: labelEn,
      labelMr: labelMr,
      capacity: capacity,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  group('SignupService sheet CRUD', () {
    test('createSheet writes a new document and returns its auto-id', () async {
      final id = await service.createSheet(buildSheet());

      expect(id, isNotEmpty);
      final doc = await fakeFirestore.collection('signup_sheets').doc(id).get();
      expect(doc.exists, true);
      expect(doc.data()?['titleEn'], 'Sunday Prasad Seva');
    });

    test('getSheetById streams the created sheet', () async {
      final id = await service.createSheet(buildSheet());

      final sheet = await service.getSheetById(id).first;

      expect(sheet, isNotNull);
      expect(sheet!.id, id);
      expect(sheet.titleEn, 'Sunday Prasad Seva');
    });

    test('getSheetById emits null when the sheet does not exist', () async {
      final sheet = await service.getSheetById('missing').first;

      expect(sheet, isNull);
    });

    test(
      'getActiveSheets returns only published sheets for the group',
      () async {
        final publishedId = await service.createSheet(
          buildSheet(status: SignupSheetStatus.published),
        );
        await service.createSheet(buildSheet(status: SignupSheetStatus.draft));
        await service.createSheet(
          buildSheet(status: SignupSheetStatus.published, groupId: 'group_2'),
        );

        final sheets = await service.getActiveSheets('group_1').first;

        expect(sheets.length, 1);
        expect(sheets.single.id, publishedId);
      },
    );

    test('getAllSheets returns every status for the group', () async {
      await service.createSheet(buildSheet(status: SignupSheetStatus.draft));
      await service.createSheet(
        buildSheet(status: SignupSheetStatus.published),
      );
      await service.createSheet(buildSheet(status: SignupSheetStatus.closed));
      await service.createSheet(buildSheet(groupId: 'group_2'));

      final sheets = await service.getAllSheets('group_1').first;

      expect(sheets.length, 3);
    });

    test('updateSheet overwrites the stored fields', () async {
      final id = await service.createSheet(buildSheet());
      final updated = (await service.getSheetById(id).first)!.copyWith(
        titleEn: 'Updated Title',
      );

      await service.updateSheet(updated);

      final sheet = await service.getSheetById(id).first;
      expect(sheet!.titleEn, 'Updated Title');
    });

    test(
      'updateSheet throws when sheet.id is null instead of writing a stray doc',
      () async {
        await expectLater(
          service.updateSheet(buildSheet()),
          throwsArgumentError,
        );

        final sheets = await service.getAllSheets('group_1').first;
        expect(sheets, isEmpty);
      },
    );

    test('updateSheetStatus changes only the status and updatedAt', () async {
      final id = await service.createSheet(buildSheet());
      final before = (await service.getSheetById(id).first)!;

      await service.updateSheetStatus(id, SignupSheetStatus.published);

      final after = await service.getSheetById(id).first;
      expect(after!.status, SignupSheetStatus.published);
      expect(after.titleEn, before.titleEn);
      expect(
        after.updatedAt.isAfter(before.updatedAt) ||
            after.updatedAt.isAtSameMomentAs(before.updatedAt),
        isTrue,
      );
    });
  });

  group('SignupService slot CRUD', () {
    test(
      'addSlot writes a new slot document and returns its auto-id',
      () async {
        final sheetId = await service.createSheet(buildSheet());

        final slotId = await service.addSlot(sheetId, buildSlot());

        expect(slotId, isNotEmpty);
        final doc = await fakeFirestore
            .collection('signup_sheets')
            .doc(sheetId)
            .collection('slots')
            .doc(slotId)
            .get();
        expect(doc.exists, true);
        expect(doc.data()?['labelEn'], 'Week 1');
      },
    );

    test('getSlots streams slots ordered by sortOrder ascending', () async {
      final sheetId = await service.createSheet(buildSheet());
      await service.addSlot(sheetId, buildSlot(labelEn: 'Third', sortOrder: 2));
      await service.addSlot(sheetId, buildSlot(labelEn: 'First', sortOrder: 0));
      await service.addSlot(
        sheetId,
        buildSlot(labelEn: 'Second', sortOrder: 1),
      );

      final slots = await service.getSlots(sheetId).first;

      expect(slots.map((s) => s.labelEn).toList(), [
        'First',
        'Second',
        'Third',
      ]);
    });

    test('updateSlot overwrites the stored fields', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot());
      final slot = (await service.getSlots(sheetId).first).single;

      await service.updateSlot(sheetId, slot.copyWith(capacity: 10));

      final updated = (await service.getSlots(sheetId).first).single;
      expect(updated.id, slotId);
      expect(updated.capacity, 10);
    });

    test(
      'updateSlot throws when slot.id is null instead of writing a stray doc',
      () async {
        final sheetId = await service.createSheet(buildSheet());

        await expectLater(
          service.updateSlot(sheetId, buildSlot()),
          throwsArgumentError,
        );

        final slots = await service.getSlots(sheetId).first;
        expect(slots, isEmpty);
      },
    );

    test('deleteSlot removes the slot document', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot());

      await service.deleteSlot(sheetId, slotId);

      final slots = await service.getSlots(sheetId).first;
      expect(slots, isEmpty);
    });

    test('reorderSlots rewrites sortOrder to match the given order', () async {
      final sheetId = await service.createSheet(buildSheet());
      final firstId = await service.addSlot(
        sheetId,
        buildSlot(labelEn: 'A', sortOrder: 0),
      );
      final secondId = await service.addSlot(
        sheetId,
        buildSlot(labelEn: 'B', sortOrder: 1),
      );

      await service.reorderSlots(sheetId, [secondId, firstId]);

      final slots = await service.getSlots(sheetId).first;
      expect(slots.map((s) => s.id).toList(), [secondId, firstId]);
      expect(slots[0].sortOrder, 0);
      expect(slots[1].sortOrder, 1);
    });
  });

  group('SignupService createSheetWithSlots', () {
    test('creates the sheet and every slot in one batch', () async {
      final sheetId = await service.createSheetWithSlots(buildSheet(), [
        buildSlot(labelEn: 'Week 1', sortOrder: 0),
        buildSlot(labelEn: 'Week 2', sortOrder: 1),
      ]);

      final sheet = await service.getSheetById(sheetId).first;
      expect(sheet, isNotNull);

      final slots = await service.getSlots(sheetId).first;
      expect(slots.map((s) => s.labelEn).toList(), ['Week 1', 'Week 2']);
    });

    test('rejects an empty slot list without writing a sheet', () async {
      await expectLater(
        service.createSheetWithSlots(buildSheet(), []),
        throwsArgumentError,
      );

      final sheets = await service.getAllSheets('group_1').first;
      expect(sheets, isEmpty);
    });
  });

  group('SignupService claimSlot', () {
    test('happy path creates an entry and increments claimedCount', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane Doe',
        phone: '+911234567890',
      );

      expect(result['success'], true);
      expect(result['entryId'], isNotEmpty);

      final entries = await service.getAllEntries(sheetId).first;
      expect(entries.single.name, 'Jane Doe');

      final myEntries = await service
          .getEntriesByDevice(sheetId, 'no_such_device')
          .first;
      expect(myEntries, isEmpty);

      final slot = (await service.getSlots(sheetId).first).single;
      expect(slot.claimedCount, 1);
    });

    test('getEntriesByDevice returns only that device\'s entries', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 5));
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_1',
      );
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'John',
        deviceId: 'device_2',
      );

      final myEntries = await service
          .getEntriesByDevice(sheetId, 'device_1')
          .first;

      expect(myEntries.map((e) => e.name).toList(), ['Jane']);
    });

    test(
      'rejects with slot_full when capacity is reached, without creating an entry',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 1));
        await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'First',
        );

        final result = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Second',
        );

        expect(result, {'success': false, 'error': 'slot_full'});
        final entries = await service.getAllEntries(sheetId).first;
        expect(entries.length, 1);
        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 1);
      },
    );

    test(
      'rejects a missing/wrong join code when the sheet requires one',
      () async {
        final sheetId = await service.createSheet(
          buildSheet(requiresJoinCode: true, joinCode: 'ABC123'),
        );
        final slotId = await service.addSlot(sheetId, buildSlot());

        final missing = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
        );
        final wrong = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
          joinCode: 'WRONG',
        );

        expect(missing, {'success': false, 'error': 'invalid_join_code'});
        expect(wrong, {'success': false, 'error': 'invalid_join_code'});
        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'succeeds without a join code when the sheet does not require one',
      () async {
        final sheetId = await service.createSheet(
          buildSheet(requiresJoinCode: false),
        );
        final slotId = await service.addSlot(sheetId, buildSlot());

        final result = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
        );

        expect(result['success'], true);
      },
    );

    test('returns not_found when the slot does not exist', () async {
      final sheetId = await service.createSheet(buildSheet());

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: 'missing',
        name: 'Jane',
      );

      expect(result, {'success': false, 'error': 'not_found'});
    });

    test('returns not_found when the sheet does not exist', () async {
      final result = await service.claimSlot(
        sheetId: 'missing',
        slotId: 'also_missing',
        name: 'Jane',
      );

      expect(result, {'success': false, 'error': 'not_found'});
    });

    test(
      // NOTE: fake_cloud_firestore's runTransaction is a passthrough
      // (`_DummyTransaction`) with no locking or retry — it does not
      // actually serialize concurrent transactions the way real Firestore
      // does. This test only proves the capacity check itself is correct
      // when claimSlot calls happen one after another; it cannot prove two
      // truly concurrent claims against real Firestore can't both squeeze
      // through. Manual/emulator verification is still needed before this
      // ships.
      'exactly one of two claims against a capacity-1 slot succeeds',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 1));

        final first = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'First',
        );
        final second = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Second',
        );

        final results = [first, second];
        expect(results.where((r) => r['success'] == true).length, 1);
        expect(results.where((r) => r['error'] == 'slot_full').length, 1);
        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 1);
      },
    );
  });

  group('SignupService cancelEntry / adminRemoveEntry', () {
    test('cancelEntry deletes the entry and decrements claimedCount', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
      final claim = await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
      );

      await service.cancelEntry(sheetId, claim['entryId'] as String);

      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, isEmpty);
      final slot = (await service.getSlots(sheetId).first).single;
      expect(slot.claimedCount, 0);
    });

    test(
      'cancelEntry is a no-op if called twice (never goes below 0)',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
        );
        final entryId = claim['entryId'] as String;

        await service.cancelEntry(sheetId, entryId);
        await service.cancelEntry(sheetId, entryId);

        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'adminRemoveEntry deletes the entry and decrements claimedCount',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
        );

        await service.adminRemoveEntry(sheetId, claim['entryId'] as String);

        final entries = await service.getAllEntries(sheetId).first;
        expect(entries, isEmpty);
        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'cancelEntry deletes the entry without error when its slot is already gone',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Jane',
        );
        // Simulate the slot having been removed some other way (e.g. a
        // manual console edit) while an entry still references it.
        await fakeFirestore
            .collection('signup_sheets')
            .doc(sheetId)
            .collection('slots')
            .doc(slotId)
            .delete();

        await service.cancelEntry(sheetId, claim['entryId'] as String);

        final entries = await service.getAllEntries(sheetId).first;
        expect(entries, isEmpty);
      },
    );
  });

  group('SignupService duplicateSheet', () {
    test(
      'copies title/description/requiresJoinCode and resets status to draft',
      () async {
        final sheetId = await service.createSheet(
          buildSheet(
            titleEn: 'Original Title',
            requiresJoinCode: false,
            status: SignupSheetStatus.closed,
          ),
        );

        final newId = await service.duplicateSheet(sheetId);

        final copy = await service.getSheetById(newId).first;
        expect(copy!.titleEn, 'Original Title');
        expect(copy.requiresJoinCode, false);
        expect(copy.joinCode, isNull);
        expect(copy.status, SignupSheetStatus.draft);
      },
    );

    test('generates a fresh join code when requiresJoinCode is true', () async {
      final sheetId = await service.createSheet(
        buildSheet(requiresJoinCode: true, joinCode: 'ORIGINAL'),
      );

      final newId = await service.duplicateSheet(sheetId);

      final copy = await service.getSheetById(newId).first;
      expect(copy!.requiresJoinCode, true);
      expect(copy.joinCode, isNotNull);
      expect(copy.joinCode, isNot('ORIGINAL'));
    });

    test('copies every slot with claimedCount reset to 0', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
      await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'Jane');

      final newId = await service.duplicateSheet(sheetId);

      final newSlots = await service.getSlots(newId).first;
      expect(newSlots.single.labelEn, 'Week 1');
      expect(newSlots.single.claimedCount, 0);
    });

    test('does not copy entries', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
      await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'Jane');

      final newId = await service.duplicateSheet(sheetId);

      final newEntries = await service.getAllEntries(newId).first;
      expect(newEntries, isEmpty);
    });

    test('throws when the source sheet does not exist', () async {
      await expectLater(service.duplicateSheet('missing'), throwsArgumentError);
    });
  });

  group('SignupService adminAddEntry', () {
    test(
      'creates an entry and increments claimedCount, bypassing the join code',
      () async {
        final sheetId = await service.createSheet(
          buildSheet(requiresJoinCode: true, joinCode: 'ABC123'),
        );
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));

        final result = await service.adminAddEntry(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Phoned-in Devotee',
          phone: '+911234567890',
        );

        expect(result['success'], true);
        expect(result['entryId'], isNotEmpty);
        final entries = await service.getAllEntries(sheetId).first;
        expect(entries.single.name, 'Phoned-in Devotee');
        final slot = (await service.getSlots(sheetId).first).single;
        expect(slot.claimedCount, 1);
      },
    );

    test(
      'rejects with slot_full when capacity is reached, without creating an entry',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 1));
        await service.adminAddEntry(
          sheetId: sheetId,
          slotId: slotId,
          name: 'First',
        );

        final result = await service.adminAddEntry(
          sheetId: sheetId,
          slotId: slotId,
          name: 'Second',
        );

        expect(result, {'success': false, 'error': 'slot_full'});
        final entries = await service.getAllEntries(sheetId).first;
        expect(entries.length, 1);
      },
    );

    test('returns not_found when the slot does not exist', () async {
      final sheetId = await service.createSheet(buildSheet());

      final result = await service.adminAddEntry(
        sheetId: sheetId,
        slotId: 'missing',
        name: 'Jane',
      );

      expect(result, {'success': false, 'error': 'not_found'});
    });
  });

  group('SignupService updateSlot preserves claimedCount', () {
    test(
      'does not revert a claim made after the slot was loaded for editing',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
        final staleSlot = (await service.getSlots(sheetId).first).single;

        // A devotee claims the slot after the admin loaded it for editing.
        await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'Jane');

        // Admin saves an edit built from the stale (pre-claim) slot object.
        await service.updateSlot(sheetId, staleSlot.copyWith(capacity: 10));

        final updated = (await service.getSlots(sheetId).first).single;
        expect(updated.capacity, 10);
        expect(updated.claimedCount, 1);
      },
    );
  });

  group('SignupService deleteSlot claimed-entry guard', () {
    test(
      'throws and does not delete when the slot has claimed entries',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
        await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'Jane');

        await expectLater(
          service.deleteSlot(sheetId, slotId),
          throwsStateError,
        );

        final slots = await service.getSlots(sheetId).first;
        expect(slots, isNotEmpty);
      },
    );

    test('succeeds when the slot has no claims', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));

      await service.deleteSlot(sheetId, slotId);

      final slots = await service.getSlots(sheetId).first;
      expect(slots, isEmpty);
    });
  });
}
