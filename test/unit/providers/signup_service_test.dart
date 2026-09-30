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
  }) {
    final now = DateTime.now();
    return SignupSheet(
      titleEn: titleEn,
      titleMr: titleMr,
      groupId: groupId,
      status: status,
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
}
