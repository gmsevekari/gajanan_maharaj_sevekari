import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
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
}
