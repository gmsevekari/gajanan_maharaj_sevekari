import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';

/// firebase_storage_mocks' Reference.delete() never throws, so this
/// stands in for both branches of deleteHeaderImageFile's error handling:
/// pass code: 'object-not-found' for the tolerated "already gone" case,
/// or any other code for the "real error, must rethrow" case.
class _ThrowingReference implements Reference {
  final String code;

  _ThrowingReference({this.code = 'unauthorized'});

  @override
  Future<void> delete() =>
      Future.error(FirebaseException(plugin: 'firebase_storage', code: code));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingHeaderImageStorage implements FirebaseStorage {
  final String code;

  _ThrowingHeaderImageStorage({this.code = 'unauthorized'});

  @override
  Reference ref([String? path]) => _ThrowingReference(code: code);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;
  late SignupService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    service = SignupService(firestore: fakeFirestore, storage: mockStorage);
  });

  SignupSheet buildSheet({
    String? id,
    String titleEn = 'Sunday Prasad Seva',
    String titleMr = 'रविवार प्रसाद सेवा',
    String groupId = 'group_1',
    SignupSheetStatus status = SignupSheetStatus.draft,
    bool requiresJoinCode = false,
    String? joinCode,
  }) {
    final now = DateTime.now();
    return SignupSheet(
      id: id,
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
      final doc = await fakeFirestore.collection('signups').doc(id).get();
      expect(doc.exists, true);
      expect(doc.data()?['titleEn'], 'Sunday Prasad Seva');
    });

    test(
      'createSheet writes to a pre-set id instead of auto-generating one',
      () async {
        final preGeneratedId = service.newSheetId();

        final id = await service.createSheet(buildSheet(id: preGeneratedId));

        expect(id, preGeneratedId);
        final doc = await fakeFirestore
            .collection('signups')
            .doc(preGeneratedId)
            .get();
        expect(doc.exists, true);
      },
    );

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
            .collection('signups')
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

    test('writes to a pre-set id instead of auto-generating one', () async {
      final preGeneratedId = service.newSheetId();

      final sheetId = await service.createSheetWithSlots(
        buildSheet(id: preGeneratedId),
        [buildSlot()],
      );

      expect(sheetId, preGeneratedId);
      final sheet = await service.getSheetById(preGeneratedId).first;
      expect(sheet, isNotNull);
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

    test('rejects a second claim on the same slot with the same email, '
        'without creating an entry', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 5));
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
        email: 'jane@example.com',
      );

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane Again',
        email: 'JANE@EXAMPLE.COM', // case-insensitive match
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, hasLength(1));
    });

    test('rejects a second claim on the same slot with the same phone '
        'regardless of formatting, without creating an entry', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 5));
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane',
        phone: '(123) 456-7890',
      );

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane Again',
        phone: '123-456-7890',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, hasLength(1));
    });

    test('allows the same email/phone to claim a different slot on the same '
        'sheet', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slot1 = await service.addSlot(sheetId, buildSlot(capacity: 5));
      final slot2 = await service.addSlot(sheetId, buildSlot(capacity: 5));
      await service.claimSlot(
        sheetId: sheetId,
        slotId: slot1,
        name: 'Jane',
        email: 'jane@example.com',
        phone: '1234567890',
      );

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: slot2,
        name: 'Jane',
        email: 'jane@example.com',
        phone: '1234567890',
      );

      expect(result['success'], true);
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, hasLength(2));
    });

    test('allows two claims on the same slot when neither has an email or '
        'phone to match on', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 5));
      await service.claimSlot(sheetId: sheetId, slotId: slotId, name: 'A');

      final result = await service.claimSlot(
        sheetId: sheetId,
        slotId: slotId,
        name: 'B',
      );

      expect(result['success'], true);
      final entries = await service.getAllEntries(sheetId).first;
      expect(entries, hasLength(2));
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
            .collection('signups')
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

  group('SignupService updateEntry', () {
    test('updates an existing entry fields', () async {
      final sheetId = await service.createSheet(buildSheet());
      final slotId = await service.addSlot(sheetId, buildSlot(capacity: 3));
      final addResult = await service.adminAddEntry(
        sheetId: sheetId,
        slotId: slotId,
        name: 'Jane Doe',
        phone: '1234567890',
      );
      final entryId = addResult['entryId'] as String;
      final original = (await service.getAllEntries(sheetId).first).single;

      final updatedEntry = original.copyWith(
        name: 'Jane Smith',
        note: 'Updated note',
      );
      await service.updateEntry(sheetId, updatedEntry);

      final fetched = (await service.getAllEntries(sheetId).first).single;
      expect(fetched.id, entryId);
      expect(fetched.name, 'Jane Smith');
      expect(fetched.note, 'Updated note');
      expect(fetched.phone, '1234567890');
    });

    test('throws ArgumentError when entry.id is null', () async {
      final entry = SignupEntry(
        slotId: 'slot_1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      );
      expect(() => service.updateEntry('sheet_1', entry), throwsArgumentError);
    });

    test(
      'ignores a changed slotId, preserving the original slot and claimedCount',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final slotAId = await service.addSlot(
          sheetId,
          buildSlot(labelEn: 'Slot A', capacity: 3),
        );
        final slotBId = await service.addSlot(
          sheetId,
          buildSlot(labelEn: 'Slot B', capacity: 3),
        );
        final addResult = await service.adminAddEntry(
          sheetId: sheetId,
          slotId: slotAId,
          name: 'Jane Doe',
        );
        final original = (await service.getAllEntries(sheetId).first).single;

        // A caller attempts to move the entry to a different slot via
        // updateEntry, which is not transactional and has no capacity
        // check — this must be a no-op on slotId/claimedCount, not a
        // silent desync.
        await service.updateEntry(
          sheetId,
          original.copyWith(slotId: slotBId, name: 'Jane Smith'),
        );

        final fetched = (await service.getAllEntries(sheetId).first).single;
        expect(fetched.id, addResult['entryId']);
        expect(fetched.name, 'Jane Smith');
        expect(fetched.slotId, slotAId);

        final slots = await service.getSlots(sheetId).first;
        final slotA = slots.firstWhere((s) => s.id == slotAId);
        final slotB = slots.firstWhere((s) => s.id == slotBId);
        expect(slotA.claimedCount, 1);
        expect(slotB.claimedCount, 0);
      },
    );
  });

  group('SignupService header image', () {
    test(
      'uploadHeaderImage stores the bytes and returns a download URL',
      () async {
        final sheetId = await service.createSheet(buildSheet());

        final url = await service.uploadHeaderImage(
          sheetId: sheetId,
          bytes: Uint8List.fromList(List.filled(1024, 1)),
          contentType: 'image/jpeg',
        );

        expect(url, isNotEmpty);
        expect(
          mockStorage.storedDataMap.containsKey('signups/$sheetId/header'),
          true,
        );
      },
    );

    test(
      'uploadHeaderImage rejects a file larger than maxHeaderImageBytes',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        final oversized = Uint8List(SignupService.maxHeaderImageBytes + 1);

        expect(
          () => service.uploadHeaderImage(
            sheetId: sheetId,
            bytes: oversized,
            contentType: 'image/jpeg',
          ),
          throwsArgumentError,
        );
        expect(
          mockStorage.storedDataMap.containsKey('signups/$sheetId/header'),
          false,
        );
      },
    );

    test('updateHeaderImageUrl sets the field on the sheet', () async {
      final sheetId = await service.createSheet(buildSheet());

      await service.updateHeaderImageUrl(
        sheetId,
        'https://example.com/header.jpg',
      );

      final sheet = await service.getSheetById(sheetId).first;
      expect(sheet!.headerImageUrl, 'https://example.com/header.jpg');
    });

    test('updateHeaderImageUrl clears the field when passed null', () async {
      final sheetId = await service.createSheet(buildSheet());
      await service.updateHeaderImageUrl(
        sheetId,
        'https://example.com/header.jpg',
      );

      await service.updateHeaderImageUrl(sheetId, null);

      final sheet = await service.getSheetById(sheetId).first;
      expect(sheet!.headerImageUrl, isNull);
    });

    test(
      'removeHeaderImage deletes the Storage object and clears the field',
      () async {
        final sheetId = await service.createSheet(buildSheet());
        await service.uploadHeaderImage(
          sheetId: sheetId,
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
        );
        await service.updateHeaderImageUrl(
          sheetId,
          'https://example.com/header.jpg',
        );

        await service.removeHeaderImage(sheetId);

        final sheet = await service.getSheetById(sheetId).first;
        expect(sheet!.headerImageUrl, isNull);
        expect(
          mockStorage.storedDataMap.containsKey('signups/$sheetId/header'),
          false,
        );
      },
    );

    test(
      'removeHeaderImage does not throw when no image was ever uploaded',
      () async {
        final sheetId = await service.createSheet(buildSheet());

        await service.removeHeaderImage(sheetId);

        final sheet = await service.getSheetById(sheetId).first;
        expect(sheet!.headerImageUrl, isNull);
      },
    );

    test(
      'removeHeaderImage rethrows a Storage error that is not object-not-found',
      () async {
        final throwingService = SignupService(
          firestore: fakeFirestore,
          storage: _ThrowingHeaderImageStorage(),
        );
        final sheetId = await service.createSheet(buildSheet());

        expect(
          () => throwingService.removeHeaderImage(sheetId),
          throwsA(isA<FirebaseException>()),
        );
      },
    );

    test(
      'deleteHeaderImageFile swallows an object-not-found Storage error',
      () async {
        final throwingService = SignupService(
          firestore: fakeFirestore,
          storage: _ThrowingHeaderImageStorage(code: 'object-not-found'),
        );
        final sheetId = await service.createSheet(buildSheet());

        await expectLater(
          throwingService.deleteHeaderImageFile(sheetId),
          completes,
        );
      },
    );

    test(
      'deleteHeaderImageFile rethrows a Storage error that is not object-not-found',
      () async {
        final throwingService = SignupService(
          firestore: fakeFirestore,
          storage: _ThrowingHeaderImageStorage(code: 'unauthorized'),
        );
        final sheetId = await service.createSheet(buildSheet());

        expect(
          () => throwingService.deleteHeaderImageFile(sheetId),
          throwsA(isA<FirebaseException>()),
        );
      },
    );
  });
}
