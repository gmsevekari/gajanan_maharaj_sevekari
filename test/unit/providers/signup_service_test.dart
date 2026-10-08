import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/models/claim_entries_result.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/providers/signup_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

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

  Signup buildSignup({
    String? id,
    String titleEn = 'Sunday Prasad Seva',
    String titleMr = 'रविवार प्रसाद सेवा',
    String groupId = 'group_1',
    SignupStatus status = SignupStatus.draft,
    bool requiresJoinCode = false,
    String? joinCode,
  }) {
    final now = DateTime.now();
    return Signup(
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

  group('SignupService signup CRUD', () {
    test(
      'createSignup writes a new document and returns its auto-id',
      () async {
        final id = await service.createSignup(buildSignup());

        expect(id, isNotEmpty);
        final doc = await fakeFirestore.collection('signups').doc(id).get();
        expect(doc.exists, true);
        expect(doc.data()?['titleEn'], 'Sunday Prasad Seva');
      },
    );

    test(
      'createSignup writes to a pre-set id instead of auto-generating one',
      () async {
        final preGeneratedId = service.newSignupId();

        final id = await service.createSignup(buildSignup(id: preGeneratedId));

        expect(id, preGeneratedId);
        final doc = await fakeFirestore
            .collection('signups')
            .doc(preGeneratedId)
            .get();
        expect(doc.exists, true);
      },
    );

    test('getSignupById streams the created signup', () async {
      final id = await service.createSignup(buildSignup());

      final signup = await service.getSignupById(id).first;

      expect(signup, isNotNull);
      expect(signup!.id, id);
      expect(signup.titleEn, 'Sunday Prasad Seva');
    });

    test('getSignupById emits null when the signup does not exist', () async {
      final signup = await service.getSignupById('missing').first;

      expect(signup, isNull);
    });

    test(
      'getActiveSignups returns only published signups for the group',
      () async {
        final publishedId = await service.createSignup(
          buildSignup(status: SignupStatus.published),
        );
        await service.createSignup(buildSignup(status: SignupStatus.draft));
        await service.createSignup(
          buildSignup(status: SignupStatus.published, groupId: 'group_2'),
        );

        final signups = await service.getActiveSignups('group_1').first;

        expect(signups.length, 1);
        expect(signups.single.id, publishedId);
      },
    );

    test('getAllSignups returns every status for the group', () async {
      await service.createSignup(buildSignup(status: SignupStatus.draft));
      await service.createSignup(buildSignup(status: SignupStatus.published));
      await service.createSignup(buildSignup(status: SignupStatus.closed));
      await service.createSignup(buildSignup(groupId: 'group_2'));

      final signups = await service.getAllSignups('group_1').first;

      expect(signups.length, 3);
    });

    test('updateSignup overwrites the stored fields', () async {
      final id = await service.createSignup(buildSignup());
      final updated = (await service.getSignupById(id).first)!.copyWith(
        titleEn: 'Updated Title',
      );

      await service.updateSignup(updated);

      final signup = await service.getSignupById(id).first;
      expect(signup!.titleEn, 'Updated Title');
    });

    test(
      'updateSignup throws when signup.id is null instead of writing a stray doc',
      () async {
        await expectLater(
          service.updateSignup(buildSignup()),
          throwsArgumentError,
        );

        final signups = await service.getAllSignups('group_1').first;
        expect(signups, isEmpty);
      },
    );

    test('updateSignupStatus changes only the status and updatedAt', () async {
      final id = await service.createSignup(buildSignup());
      final before = (await service.getSignupById(id).first)!;

      await service.updateSignupStatus(id, SignupStatus.published);

      final after = await service.getSignupById(id).first;
      expect(after!.status, SignupStatus.published);
      expect(after.titleEn, before.titleEn);
      expect(
        after.updatedAt.isAfter(before.updatedAt) ||
            after.updatedAt.isAtSameMomentAs(before.updatedAt),
        isTrue,
      );
    });
  });

  group('SignupService updateSignupDetails', () {
    late String id;

    setUp(() async {
      id = await service.createSignup(
        buildSignup(
          titleEn: 'Old title',
          titleMr: 'जुने',
          groupId: 'group_9',
          status: SignupStatus.published,
        ).copyWith(
          descriptionEn: 'Old description',
          descriptionMr: 'जुने वर्णन',
        ),
      );
      await fakeFirestore.doc('signups/$id').update({
        'headerImageUrl': 'https://example.com/header.png',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2000)),
      });
    });

    DocumentReference<Map<String, dynamic>> ref() =>
        fakeFirestore.doc('signups/$id');

    Future<Map<String, dynamic>> stored() async => (await ref().get()).data()!;

    /// What another admin does while a form is open.
    Future<void> elsewhere(Map<String, dynamic> change) => ref().update(change);

    test('writes only the fields it is given', () async {
      await service.updateSignupDetails(id, titleEn: 'New title');

      final data = await stored();
      expect(data['titleEn'], 'New title');
      expect(data['titleMr'], 'जुने');
      expect(data['descriptionEn'], 'Old description');
      expect(data['descriptionMr'], 'जुने वर्णन');
      expect(data['requiresJoinCode'], false);
    });

    test('can write all four text fields', () async {
      await service.updateSignupDetails(
        id,
        titleEn: 'New title',
        titleMr: 'नवे',
        descriptionEn: 'New description',
        descriptionMr: 'नवे वर्णन',
      );

      final data = await stored();
      expect(data['titleEn'], 'New title');
      expect(data['titleMr'], 'नवे');
      expect(data['descriptionEn'], 'New description');
      expect(data['descriptionMr'], 'नवे वर्णन');
    });

    test('can empty a field, which is different from leaving it', () async {
      await service.updateSignupDetails(id, titleMr: '', descriptionEn: '');

      final data = await stored();
      expect(data['titleMr'], '');
      expect(data['descriptionEn'], '');
      expect(data['titleEn'], 'Old title');
    });

    test('does not undo what another admin changed in a field it was not '
        'given', () async {
      await elsewhere({'titleMr': 'दुसऱ्याचे', 'descriptionEn': 'Theirs'});

      await service.updateSignupDetails(id, titleEn: 'Mine');

      final data = await stored();
      expect(data['titleEn'], 'Mine');
      expect(data['titleMr'], 'दुसऱ्याचे');
      expect(data['descriptionEn'], 'Theirs');
    });

    test(
      'leaves the status, group, image, creator and creation time alone',
      () async {
        final before = await stored();

        await service.updateSignupDetails(id, titleEn: 'New title');

        final after = await stored();
        for (final key in [
          'status',
          'groupId',
          'headerImageUrl',
          'createdBy',
          'createdAt',
        ]) {
          expect(after[key], before[key], reason: key);
        }
      },
    );

    test('stamps updatedAt when it writes something', () async {
      await service.updateSignupDetails(id, titleEn: 'New title');

      final updatedAt = ((await stored())['updatedAt'] as Timestamp).toDate();
      expect(
        updatedAt.difference(DateTime.now()).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });

    test('writes nothing, not even updatedAt, when given nothing', () async {
      await service.updateSignupDetails(id);

      expect(
        (await stored())['updatedAt'],
        Timestamp.fromDate(DateTime.utc(2000)),
      );
    });

    group('join code', () {
      test('is not touched when the requirement is not given, even if '
          'another admin changed it', () async {
        await elsewhere({'requiresJoinCode': true, 'joinCode': 'THEIRS1'});

        await service.updateSignupDetails(id, titleEn: 'Mine');

        final data = await stored();
        expect(data['requiresJoinCode'], true);
        expect(data['joinCode'], 'THEIRS1');
      });

      test('is made when the requirement is switched on', () async {
        await service.updateSignupDetails(
          id,
          requiresJoinCode: true,
          newJoinCode: 'ABC123',
        );

        final data = await stored();
        expect(data['requiresJoinCode'], true);
        expect(data['joinCode'], 'ABC123');
      });

      test(
        'keeps the code another admin already made when switched on',
        () async {
          await elsewhere({'requiresJoinCode': true, 'joinCode': 'THEIRS1'});

          await service.updateSignupDetails(
            id,
            requiresJoinCode: true,
            newJoinCode: 'ABC123',
          );

          expect((await stored())['joinCode'], 'THEIRS1');
        },
      );

      test('does not bring back a code left behind from before the requirement '
          'was switched off', () async {
        await elsewhere({'requiresJoinCode': false, 'joinCode': 'LEFT999'});

        await service.updateSignupDetails(
          id,
          requiresJoinCode: true,
          newJoinCode: 'ABC123',
        );

        expect((await stored())['joinCode'], 'ABC123');
      });

      test(
        'replaces a blank code when switched on over a broken one',
        () async {
          await elsewhere({'requiresJoinCode': true, 'joinCode': ''});

          await service.updateSignupDetails(
            id,
            requiresJoinCode: true,
            newJoinCode: 'ABC123',
          );

          expect((await stored())['joinCode'], 'ABC123');
        },
      );

      test('is removed when the requirement is switched off', () async {
        await elsewhere({'requiresJoinCode': true, 'joinCode': 'ABC123'});

        await service.updateSignupDetails(id, requiresJoinCode: false);

        final data = await stored();
        expect(data['requiresJoinCode'], false);
        expect(data['joinCode'], isNull);
      });

      test('can be switched on and off together with text changes', () async {
        await service.updateSignupDetails(
          id,
          titleEn: 'Both',
          requiresJoinCode: true,
          newJoinCode: 'ABC123',
        );

        final data = await stored();
        expect(data['titleEn'], 'Both');
        expect(data['joinCode'], 'ABC123');
        expect(
          data['updatedAt'],
          isNot(Timestamp.fromDate(DateTime.utc(2000))),
        );
      });

      test('refuses to switch on without a code, writing nothing', () async {
        for (final code in [null, '', '  ']) {
          await expectLater(
            service.updateSignupDetails(
              id,
              titleEn: 'Changed',
              requiresJoinCode: true,
              newJoinCode: code,
            ),
            throwsArgumentError,
          );
        }
        expect((await stored())['titleEn'], 'Old title');
      });

      test(
        'refuses a code when the requirement is not being switched on',
        () async {
          await expectLater(
            service.updateSignupDetails(id, newJoinCode: 'ABC123'),
            throwsArgumentError,
          );
          await expectLater(
            service.updateSignupDetails(
              id,
              requiresJoinCode: false,
              newJoinCode: 'ABC123',
            ),
            throwsArgumentError,
          );
        },
      );

      test('reads back as a valid Signup', () async {
        await service.updateSignupDetails(
          id,
          titleEn: 'New title',
          requiresJoinCode: true,
          newJoinCode: 'ABC123',
        );

        // Read with get(): the fake's snapshot stream can lag a transaction.
        final signup = Signup.fromMap(id, (await stored()));
        expect(signup.titleEn, 'New title');
        expect(signup.requiresJoinCode, isTrue);
        expect(signup.joinCode, 'ABC123');
        expect(signup.status, SignupStatus.published);
      });
    });

    test('throws when the signup no longer exists', () async {
      await expectLater(
        service.updateSignupDetails('missing', titleEn: 'T'),
        throwsA(isA<FirebaseException>()),
      );
      await expectLater(
        service.updateSignupDetails(
          'missing',
          requiresJoinCode: true,
          newJoinCode: 'ABC123',
        ),
        throwsA(isA<FirebaseException>()),
      );
      expect(
        (await fakeFirestore.doc('signups/missing').get()).exists,
        isFalse,
      );
    });
  });

  group('SignupService slot CRUD', () {
    test(
      'addSlot writes a new slot document and returns its auto-id',
      () async {
        final signupId = await service.createSignup(buildSignup());

        final slotId = await service.addSlot(signupId, buildSlot());

        expect(slotId, isNotEmpty);
        final doc = await fakeFirestore
            .collection('signups')
            .doc(signupId)
            .collection('slots')
            .doc(slotId)
            .get();
        expect(doc.exists, true);
        expect(doc.data()?['labelEn'], 'Week 1');
      },
    );

    test('getSlots streams slots ordered by sortOrder ascending', () async {
      final signupId = await service.createSignup(buildSignup());
      await service.addSlot(
        signupId,
        buildSlot(labelEn: 'Third', sortOrder: 2),
      );
      await service.addSlot(
        signupId,
        buildSlot(labelEn: 'First', sortOrder: 0),
      );
      await service.addSlot(
        signupId,
        buildSlot(labelEn: 'Second', sortOrder: 1),
      );

      final slots = await service.getSlots(signupId).first;

      expect(slots.map((s) => s.labelEn).toList(), [
        'First',
        'Second',
        'Third',
      ]);
    });

    test('updateSlot overwrites the stored fields', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot());
      final slot = (await service.getSlots(signupId).first).single;

      await service.updateSlot(signupId, slot.copyWith(capacity: 10));

      final updated = (await service.getSlots(signupId).first).single;
      expect(updated.id, slotId);
      expect(updated.capacity, 10);
    });

    test(
      'updateSlot throws when slot.id is null instead of writing a stray doc',
      () async {
        final signupId = await service.createSignup(buildSignup());

        await expectLater(
          service.updateSlot(signupId, buildSlot()),
          throwsArgumentError,
        );

        final slots = await service.getSlots(signupId).first;
        expect(slots, isEmpty);
      },
    );

    test('deleteSlot removes the slot document', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot());

      await service.deleteSlot(signupId, slotId);

      final slots = await service.getSlots(signupId).first;
      expect(slots, isEmpty);
    });

    test('reorderSlots rewrites sortOrder to match the given order', () async {
      final signupId = await service.createSignup(buildSignup());
      final firstId = await service.addSlot(
        signupId,
        buildSlot(labelEn: 'A', sortOrder: 0),
      );
      final secondId = await service.addSlot(
        signupId,
        buildSlot(labelEn: 'B', sortOrder: 1),
      );

      await service.reorderSlots(signupId, [secondId, firstId]);

      final slots = await service.getSlots(signupId).first;
      expect(slots.map((s) => s.id).toList(), [secondId, firstId]);
      expect(slots[0].sortOrder, 0);
      expect(slots[1].sortOrder, 1);
    });
  });

  group('SignupService createSignupWithSlots', () {
    test('creates the signup and every slot in one batch', () async {
      final signupId = await service.createSignupWithSlots(buildSignup(), [
        buildSlot(labelEn: 'Week 1', sortOrder: 0),
        buildSlot(labelEn: 'Week 2', sortOrder: 1),
      ]);

      final signup = await service.getSignupById(signupId).first;
      expect(signup, isNotNull);

      final slots = await service.getSlots(signupId).first;
      expect(slots.map((s) => s.labelEn).toList(), ['Week 1', 'Week 2']);
    });

    test('rejects an empty slot list without writing a signup', () async {
      await expectLater(
        service.createSignupWithSlots(buildSignup(), []),
        throwsArgumentError,
      );

      final signups = await service.getAllSignups('group_1').first;
      expect(signups, isEmpty);
    });

    test('writes to a pre-set id instead of auto-generating one', () async {
      final preGeneratedId = service.newSignupId();

      final signupId = await service.createSignupWithSlots(
        buildSignup(id: preGeneratedId),
        [buildSlot()],
      );

      expect(signupId, preGeneratedId);
      final signup = await service.getSignupById(preGeneratedId).first;
      expect(signup, isNotNull);
    });
  });

  group('SignupService claimSlot', () {
    test('happy path creates an entry and increments claimedCount', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Doe',
        phone: '+911234567890',
      );

      expect(result['success'], true);
      expect(result['entryId'], isNotEmpty);

      final entries = await service.getAllEntries(signupId).first;
      expect(entries.single.name, 'Jane Doe');

      final myEntries = await service
          .getEntriesByDevice(signupId, 'no_such_device')
          .first;
      expect(myEntries, isEmpty);

      final slot = (await service.getSlots(signupId).first).single;
      expect(slot.claimedCount, 1);
    });

    test('getEntriesByDevice returns only that device\'s entries', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_1',
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'John',
        deviceId: 'device_2',
      );

      final myEntries = await service
          .getEntriesByDevice(signupId, 'device_1')
          .first;

      expect(myEntries.map((e) => e.name).toList(), ['Jane']);
    });

    test(
      'rejects with slot_full when capacity is reached, without creating an entry',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 1));
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'First',
        );

        final result = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Second',
        );

        expect(result, {'success': false, 'error': 'slot_full'});
        final entries = await service.getAllEntries(signupId).first;
        expect(entries.length, 1);
        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 1);
      },
    );

    test(
      'rejects a missing/wrong join code when the signup requires one',
      () async {
        final signupId = await service.createSignup(
          buildSignup(requiresJoinCode: true, joinCode: 'ABC123'),
        );
        final slotId = await service.addSlot(signupId, buildSlot());

        final missing = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );
        final wrong = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
          joinCode: 'WRONG',
        );

        expect(missing, {'success': false, 'error': 'invalid_join_code'});
        expect(wrong, {'success': false, 'error': 'invalid_join_code'});
        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'succeeds without a join code when the signup does not require one',
      () async {
        final signupId = await service.createSignup(
          buildSignup(requiresJoinCode: false),
        );
        final slotId = await service.addSlot(signupId, buildSlot());

        final result = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );

        expect(result['success'], true);
      },
    );

    test('returns not_found when the slot does not exist', () async {
      final signupId = await service.createSignup(buildSignup());

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: 'missing',
        name: 'Jane',
      );

      expect(result, {'success': false, 'error': 'not_found'});
    });

    test('returns not_found when the signup does not exist', () async {
      final result = await service.claimSlot(
        signupId: 'missing',
        slotId: 'also_missing',
        name: 'Jane',
      );

      expect(result, {'success': false, 'error': 'not_found'});
    });

    test('rejects a second claim on the same slot with the same email, '
        'without creating an entry', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        email: 'jane@example.com',
      );

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Again',
        email: 'JANE@EXAMPLE.COM', // case-insensitive match
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
      final entries = await service.getAllEntries(signupId).first;
      expect(entries, hasLength(1));
    });

    test('rejects a second claim on the same slot with the same phone '
        'regardless of formatting, without creating an entry', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        phone: '(123) 456-7890',
      );

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Again',
        phone: '123-456-7890',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
      final entries = await service.getAllEntries(signupId).first;
      expect(entries, hasLength(1));
    });

    test('treats a phone saved with a country code as the same as one saved '
        'without it', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        phone: '5851234567', // saved before country codes were added
      );

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Again',
        phone: '+15851234567',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
    });

    test('lets two different numbers claim the same slot', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        phone: '+15851234567',
      );

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Joe',
        phone: '+15851234568',
      );

      expect(result['success'], true);
    });

    test('allows the same email/phone to claim a different slot on the same '
        'signup', () async {
      final signupId = await service.createSignup(buildSignup());
      final slot1 = await service.addSlot(signupId, buildSlot(capacity: 5));
      final slot2 = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slot1,
        name: 'Jane',
        email: 'jane@example.com',
        phone: '1234567890',
      );

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slot2,
        name: 'Jane',
        email: 'jane@example.com',
        phone: '1234567890',
      );

      expect(result['success'], true);
      final entries = await service.getAllEntries(signupId).first;
      expect(entries, hasLength(2));
    });

    test('allows two claims on the same slot when neither has an email or '
        'phone to match on', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'A');

      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'B',
      );

      expect(result['success'], true);
      final entries = await service.getAllEntries(signupId).first;
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
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 1));

        final first = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'First',
        );
        final second = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Second',
        );

        final results = [first, second];
        expect(results.where((r) => r['success'] == true).length, 1);
        expect(results.where((r) => r['error'] == 'slot_full').length, 1);
        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 1);
      },
    );
  });

  group('SignupService cancelEntry / adminRemoveEntry', () {
    test('cancelEntry deletes the entry and decrements claimedCount', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      final claim = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
      );

      await service.cancelEntry(signupId, claim['entryId'] as String);

      final entries = await service.getAllEntries(signupId).first;
      expect(entries, isEmpty);
      final slot = (await service.getSlots(signupId).first).single;
      expect(slot.claimedCount, 0);
    });

    test(
      'cancelEntry is a no-op if called twice (never goes below 0)',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );
        final entryId = claim['entryId'] as String;

        await service.cancelEntry(signupId, entryId);
        await service.cancelEntry(signupId, entryId);

        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'adminRemoveEntry deletes the entry and decrements claimedCount',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );

        await service.adminRemoveEntry(signupId, claim['entryId'] as String);

        final entries = await service.getAllEntries(signupId).first;
        expect(entries, isEmpty);
        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 0);
      },
    );

    test(
      'cancelEntry deletes the entry without error when its slot is already gone',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        final claim = await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );
        // Simulate the slot having been removed some other way (e.g. a
        // manual console edit) while an entry still references it.
        await fakeFirestore
            .collection('signups')
            .doc(signupId)
            .collection('slots')
            .doc(slotId)
            .delete();

        await service.cancelEntry(signupId, claim['entryId'] as String);

        final entries = await service.getAllEntries(signupId).first;
        expect(entries, isEmpty);
      },
    );
  });

  group('SignupService reads that must come from the server', () {
    Future<List<String>> slotIds(String signupId, int count) async => [
      for (var i = 0; i < count; i++)
        await service.addSlot(signupId, buildSlot(sortOrder: i)),
    ];

    test('fetchEntriesByDevice returns only that device\'s entries', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Mine',
        deviceId: 'device_1',
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Theirs',
        deviceId: 'device_2',
      );
      await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Phoned in',
      );

      final mine = await service.fetchEntriesByDevice(signupId, 'device_1');

      expect(mine.map((e) => e.name), ['Mine']);
    });

    test(
      'fetchEntriesByDevice is empty for a device with no entries',
      () async {
        final signupId = await service.createSignup(buildSignup());

        expect(await service.fetchEntriesByDevice(signupId, 'nobody'), isEmpty);
      },
    );

    test('fetchSlots returns every slot of the sign-up, by id', () async {
      final signupId = await service.createSignup(buildSignup());
      final ids = await slotIds(signupId, 3);
      final other = await service.createSignup(buildSignup());
      await service.addSlot(other, buildSlot());

      final slots = await service.fetchSlots(signupId);

      expect(slots.map((s) => s.id), unorderedEquals(ids));
    });

    test(
      'fetchEntriesForDevice finds the device\'s entries on every sign-up',
      () async {
        final one = await service.createSignup(buildSignup());
        final two = await service.createSignup(buildSignup());
        final three = await service.createSignup(buildSignup());
        for (final signupId in [one, two]) {
          final slotId = await service.addSlot(signupId, buildSlot());
          await service.claimSlot(
            signupId: signupId,
            slotId: slotId,
            name: 'Mine',
            deviceId: 'device_1',
          );
        }
        final slotId = await service.addSlot(three, buildSlot());
        await service.claimSlot(
          signupId: three,
          slotId: slotId,
          name: 'Theirs',
          deviceId: 'device_2',
        );

        final found = await service.fetchEntriesForDevice('device_1');

        expect(found.map((e) => e.signupId), unorderedEquals([one, two]));
        expect(found.every((e) => e.entry.deviceId == 'device_1'), isTrue);
      },
    );

    test(
      'fetchEntriesForDevice is empty for a device with no entries',
      () async {
        await service.createSignup(buildSignup());

        expect(await service.fetchEntriesForDevice('nobody'), isEmpty);
      },
    );
  });

  group('SignupService duplicateSignup', () {
    test(
      'copies title/description/requiresJoinCode and resets status to draft',
      () async {
        final signupId = await service.createSignup(
          buildSignup(
            titleEn: 'Original Title',
            requiresJoinCode: false,
            status: SignupStatus.closed,
          ),
        );

        final newId = await service.duplicateSignup(signupId);

        final copy = await service.getSignupById(newId).first;
        expect(copy!.titleEn, 'Original Title');
        expect(copy.requiresJoinCode, false);
        expect(copy.joinCode, isNull);
        expect(copy.status, SignupStatus.draft);
      },
    );

    test('generates a fresh join code when requiresJoinCode is true', () async {
      final signupId = await service.createSignup(
        buildSignup(requiresJoinCode: true, joinCode: 'ORIGINAL'),
      );

      final newId = await service.duplicateSignup(signupId);

      final copy = await service.getSignupById(newId).first;
      expect(copy!.requiresJoinCode, true);
      expect(copy.joinCode, isNotNull);
      expect(copy.joinCode, isNot('ORIGINAL'));
    });

    test('copies every slot with claimedCount reset to 0', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      final newId = await service.duplicateSignup(signupId);

      final newSlots = await service.getSlots(newId).first;
      expect(newSlots.single.labelEn, 'Week 1');
      expect(newSlots.single.claimedCount, 0);
    });

    test('copies each slot\'s start, end and timezone', () async {
      final signupId = await service.createSignup(buildSignup());
      await service.addSlot(
        signupId,
        SignupSlot(
          labelEn: 'Evening',
          labelMr: 'संध्याकाळ',
          startAt: DateTime.utc(2026, 7, 2, 1),
          endAt: DateTime.utc(2026, 7, 2, 2, 30),
          timezone: EventTimezone.india,
          capacity: 3,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      );

      final newId = await service.duplicateSignup(signupId);

      final copied = (await service.getSlots(newId).first).single;
      expect(copied.startAt, DateTime.utc(2026, 7, 2, 1));
      expect(copied.endAt, DateTime.utc(2026, 7, 2, 2, 30));
      expect(copied.timezone, EventTimezone.india);
    });

    test('does not copy a slot\'s reminder records', () async {
      // The reminder function records, on the slot, which reminders it has
      // sent for its start time. A copy keeps that start time, so a copied
      // record would silence the new sign-up's reminders.
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await fakeFirestore
          .collection('signups')
          .doc(signupId)
          .collection('slots')
          .doc(slotId)
          .update({
            'reminders': {'day': 1, 'hour': 2},
            'reminderAttempts': {
              'day': {'start': 1, 'at': 2},
            },
          });

      final newId = await service.duplicateSignup(signupId);

      final copied = await fakeFirestore
          .collection('signups')
          .doc(newId)
          .collection('slots')
          .get();
      final copy = copied.docs.single.data();
      expect(copy.containsKey('reminders'), isFalse);
      expect(copy.containsKey('reminderAttempts'), isFalse);
    });

    test('does not copy entries', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      final newId = await service.duplicateSignup(signupId);

      final newEntries = await service.getAllEntries(newId).first;
      expect(newEntries, isEmpty);
    });

    test('throws when the source signup does not exist', () async {
      await expectLater(
        service.duplicateSignup('missing'),
        throwsArgumentError,
      );
    });
  });

  group('SignupService adminAddEntry', () {
    test(
      'creates an entry and increments claimedCount, bypassing the join code',
      () async {
        final signupId = await service.createSignup(
          buildSignup(requiresJoinCode: true, joinCode: 'ABC123'),
        );
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));

        final result = await service.adminAddEntry(
          signupId: signupId,
          slotId: slotId,
          name: 'Phoned-in Devotee',
          phone: '+911234567890',
        );

        expect(result['success'], true);
        expect(result['entryId'], isNotEmpty);
        final entries = await service.getAllEntries(signupId).first;
        expect(entries.single.name, 'Phoned-in Devotee');
        final slot = (await service.getSlots(signupId).first).single;
        expect(slot.claimedCount, 1);
      },
    );

    test(
      'rejects with slot_full when capacity is reached, without creating an entry',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 1));
        await service.adminAddEntry(
          signupId: signupId,
          slotId: slotId,
          name: 'First',
        );

        final result = await service.adminAddEntry(
          signupId: signupId,
          slotId: slotId,
          name: 'Second',
        );

        expect(result, {'success': false, 'error': 'slot_full'});
        final entries = await service.getAllEntries(signupId).first;
        expect(entries.length, 1);
      },
    );

    test('returns not_found when the slot does not exist', () async {
      final signupId = await service.createSignup(buildSignup());

      final result = await service.adminAddEntry(
        signupId: signupId,
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
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        final staleSlot = (await service.getSlots(signupId).first).single;

        // A devotee claims the slot after the admin loaded it for editing.
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );

        // Admin saves an edit built from the stale (pre-claim) slot object.
        await service.updateSlot(signupId, staleSlot.copyWith(capacity: 10));

        final updated = (await service.getSlots(signupId).first).single;
        expect(updated.capacity, 10);
        expect(updated.claimedCount, 1);
      },
    );
  });

  group('SignupService updateSlot preserves reminder records', () {
    test('an admin edit does not make reminders go out again', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      final slotRef = fakeFirestore
          .collection('signups')
          .doc(signupId)
          .collection('slots')
          .doc(slotId);
      await slotRef.update({
        'reminders': {'day': 1},
        'reminderAttempts': {
          'hour': {'start': 1, 'at': 2},
        },
      });
      final loaded = (await service.getSlots(signupId).first).single;

      await service.updateSlot(signupId, loaded.copyWith(capacity: 4));

      final data = (await slotRef.get()).data()!;
      expect(data['capacity'], 4);
      expect(data['reminders'], {'day': 1});
      expect(data['reminderAttempts'], {
        'hour': {'start': 1, 'at': 2},
      });
    });
  });

  group('SignupService updateSlot capacity guard', () {
    late String signupId;
    late String slotId;

    setUp(() async {
      signupId = await service.createSignup(buildSignup());
      slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      for (final name in ['Jane', 'Amit', 'Priya']) {
        await service.claimSlot(signupId: signupId, slotId: slotId, name: name);
      }
    });

    Future<SignupSlot> current() async =>
        (await service.getSlots(signupId).first).single;

    test('refuses a capacity below the number already claimed, and writes '
        'nothing', () async {
      final slot = await current();

      await expectLater(
        service.updateSlot(
          signupId,
          slot.copyWith(capacity: 2, labelEn: 'Renamed'),
        ),
        throwsA(
          isA<SlotCapacityBelowClaimedException>().having(
            (e) => e.claimedCount,
            'claimedCount',
            3,
          ),
        ),
      );

      final after = await current();
      expect(after.capacity, 5);
      expect(after.labelEn, slot.labelEn);
    });

    test('allows a capacity equal to the number claimed', () async {
      final slot = await current();

      await service.updateSlot(signupId, slot.copyWith(capacity: 3));

      expect((await current()).capacity, 3);
    });

    test(
      'checks the live count, not the count the form was opened with',
      () async {
        final stale = await current(); // 3 claimed
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Ravi',
        );
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Sita',
        );

        // Fits the 3 claimed when the form opened, not the 5 claimed now.
        await expectLater(
          service.updateSlot(signupId, stale.copyWith(capacity: 4)),
          throwsA(isA<SlotCapacityBelowClaimedException>()),
        );
        expect((await current()).capacity, 5);
      },
    );

    test('can clear the suggested amount', () async {
      final slot = await current();
      await service.updateSlot(
        signupId,
        SignupSlot(
          id: slot.id,
          labelEn: slot.labelEn,
          labelMr: slot.labelMr,
          startAt: slot.startAt,
          endAt: slot.endAt,
          timezone: slot.timezone,
          capacity: slot.capacity,
          suggestedAmount: 25,
          sortOrder: slot.sortOrder,
          createdAt: slot.createdAt,
        ),
      );
      expect((await current()).suggestedAmount, 25);

      await service.updateSlot(
        signupId,
        SignupSlot(
          id: slot.id,
          labelEn: slot.labelEn,
          labelMr: slot.labelMr,
          startAt: slot.startAt,
          endAt: slot.endAt,
          timezone: slot.timezone,
          capacity: slot.capacity,
          sortOrder: slot.sortOrder,
          createdAt: slot.createdAt,
        ),
      );

      expect((await current()).suggestedAmount, isNull);
    });

    test('throws not-found when the slot no longer exists', () async {
      final slot = await current();
      await fakeFirestore.doc('signups/$signupId/slots/$slotId').delete();

      await expectLater(
        service.updateSlot(signupId, slot.copyWith(capacity: 9)),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('treats a claimed count that is not a number as zero', () async {
      await fakeFirestore.doc('signups/$signupId/slots/$slotId').update({
        'claimedCount': 'three',
      });
      final slot = await current();

      await service.updateSlot(signupId, slot.copyWith(capacity: 1));

      expect((await current()).capacity, 1);
    });

    test(
      'does not undo a reorder made while the slot was being edited',
      () async {
        final stale = await current(); // sortOrder as it was when opened
        await fakeFirestore.doc('signups/$signupId/slots/$slotId').update({
          'sortOrder': 7,
        });

        await service.updateSlot(signupId, stale.copyWith(labelEn: 'Renamed'));

        final after = await current();
        expect(after.labelEn, 'Renamed');
        expect(after.sortOrder, 7);
      },
    );

    test('never rewrites when the slot was created', () async {
      final slot = await current();

      await service.updateSlot(
        signupId,
        slot.copyWith(createdAt: DateTime.utc(2000)),
      );

      expect((await current()).createdAt, slot.createdAt);
    });

    test('the exception names how many have signed up', () {
      expect(
        const SlotCapacityBelowClaimedException(4).toString(),
        contains('4'),
      );
    });
  });

  group('SignupService deleteSlot claimed-entry guard', () {
    test(
      'throws and does not delete when the slot has claimed entries',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        await service.claimSlot(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane',
        );

        await expectLater(
          service.deleteSlot(signupId, slotId),
          throwsA(isA<SlotHasClaimedEntriesException>()),
        );

        final slots = await service.getSlots(signupId).first;
        expect(slots, isNotEmpty);
      },
    );

    test('says how many entries are on the slot, and keeps the slot and its '
        'entries', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      for (final name in ['Jane', 'Amit']) {
        await service.claimSlot(signupId: signupId, slotId: slotId, name: name);
      }

      await expectLater(
        service.deleteSlot(signupId, slotId),
        throwsA(
          isA<SlotHasClaimedEntriesException>().having(
            (e) => e.claimedCount,
            'claimedCount',
            2,
          ),
        ),
      );

      expect(await service.getSlots(signupId).first, hasLength(1));
      expect(await service.getAllEntries(signupId).first, hasLength(2));
    });

    test('is an Exception, not an Error', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await expectLater(
        service.deleteSlot(signupId, slotId),
        throwsA(allOf(isA<Exception>(), isNot(isA<Error>()))),
      );
    });

    test('refuses when entries exist even though the counter says none, and '
        'reports the real number', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      // The counter drifted to 0 (an old client, a console edit): two
      // entries are still on the slot.
      for (final name in ['Jane', 'Amit']) {
        await fakeFirestore.collection('signups/$signupId/entries').add({
          'slotId': slotId,
          'name': name,
          'joinedAt': Timestamp.now(),
        });
      }

      await expectLater(
        service.deleteSlot(signupId, slotId),
        throwsA(
          isA<SlotHasClaimedEntriesException>().having(
            (e) => e.claimedCount,
            'claimedCount',
            2,
          ),
        ),
      );
      expect(await service.getSlots(signupId).first, hasLength(1));
    });

    test('reports the larger of the counter and the entries found', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      await fakeFirestore.doc('signups/$signupId/slots/$slotId').update({
        'claimedCount': 4,
      });
      await fakeFirestore.collection('signups/$signupId/entries').add({
        'slotId': slotId,
        'name': 'Jane',
        'joinedAt': Timestamp.now(),
      });

      await expectLater(
        service.deleteSlot(signupId, slotId),
        throwsA(
          isA<SlotHasClaimedEntriesException>().having(
            (e) => e.claimedCount,
            'claimedCount',
            4,
          ),
        ),
      );
    });

    test('ignores entries that belong to other slots', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
      final otherId = await service.addSlot(
        signupId,
        buildSlot(labelEn: 'Other', capacity: 5),
      );
      await service.claimSlot(
        signupId: signupId,
        slotId: otherId,
        name: 'Jane',
      );

      await service.deleteSlot(signupId, slotId);

      final left = await service.getSlots(signupId).first;
      expect(left.map((s) => s.id), [otherId]);
    });

    test('allows deleting after the entries are removed', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      final claimed = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
      );
      await service.adminRemoveEntry(signupId, claimed['entryId'] as String);

      await service.deleteSlot(signupId, slotId);

      expect(await service.getSlots(signupId).first, isEmpty);
    });

    test('treats a claimed count that is not a number as none', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await fakeFirestore.doc('signups/$signupId/slots/$slotId').update({
        'claimedCount': 'many',
      });

      await service.deleteSlot(signupId, slotId);

      expect(await service.getSlots(signupId).first, isEmpty);
    });

    test('does nothing when the slot is already gone', () async {
      final signupId = await service.createSignup(buildSignup());

      await service.deleteSlot(signupId, 'missing');
    });

    test('the exception message names the count', () {
      expect(
        SlotHasClaimedEntriesException('s1', 1).toString(),
        allOf(contains('s1'), contains('1 claimed entry')),
      );
      expect(
        SlotHasClaimedEntriesException('s1', 3).toString(),
        contains('3 claimed entries'),
      );
    });

    test('succeeds when the slot has no claims', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));

      await service.deleteSlot(signupId, slotId);

      final slots = await service.getSlots(signupId).first;
      expect(slots, isEmpty);
    });
  });

  group('SignupService updateEntry', () {
    test('updates an existing entry fields', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      final addResult = await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Doe',
        phone: '1234567890',
      );
      final entryId = addResult['entryId'] as String;
      final original = (await service.getAllEntries(signupId).first).single;

      final updatedEntry = original.copyWith(
        name: 'Jane Smith',
        note: 'Updated note',
      );
      await service.updateEntry(signupId, updatedEntry);

      final fetched = (await service.getAllEntries(signupId).first).single;
      expect(fetched.id, entryId);
      expect(fetched.name, 'Jane Smith');
      expect(fetched.note, 'Updated note');
      expect(fetched.phone, '1234567890');
    });

    test(
      'does not undo a claim made while the admin had the entry open',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
        final added = await service.adminAddEntry(
          signupId: signupId,
          slotId: slotId,
          name: 'Jane Doe',
          phone: '+14255551234',
        );
        final stale = (await service.getAllEntries(signupId).first).single;
        // The devotee claims it (the Cloud Function sets deviceId) ...
        await fakeFirestore
            .doc('signups/$signupId/entries/${added['entryId']}')
            .update({'deviceId': 'device_a'});

        // ... and the admin then saves the form they opened before that.
        await service.updateEntry(signupId, stale.copyWith(name: 'Jane Smith'));

        final saved = (await service.getAllEntries(signupId).first).single;
        expect(saved.name, 'Jane Smith');
        expect(saved.deviceId, 'device_a');
      },
    );

    test('does not restore a link released while the admin had the entry '
        'open', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      final claimed = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Doe',
        deviceId: 'device_a',
      );
      final stale = (await service.getAllEntries(signupId).first).single;
      await service.releaseEntryDevice(signupId, claimed['entryId'] as String);

      await service.updateEntry(signupId, stale.copyWith(name: 'Jane Smith'));

      final saved = (await service.getAllEntries(signupId).first).single;
      expect(saved.name, 'Jane Smith');
      expect(saved.deviceId, isNull);
    });

    test('never rewrites the join time', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot(capacity: 3));
      await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane Doe',
      );
      final original = (await service.getAllEntries(signupId).first).single;

      await service.updateEntry(
        signupId,
        original.copyWith(joinedAt: DateTime.utc(2000)),
      );

      final saved = (await service.getAllEntries(signupId).first).single;
      expect(saved.joinedAt, original.joinedAt);
    });

    test('throws ArgumentError when entry.id is null', () async {
      final entry = SignupEntry(
        slotId: 'slot_1',
        name: 'Jane',
        joinedAt: DateTime.now(),
      );
      expect(() => service.updateEntry('signup_1', entry), throwsArgumentError);
    });

    test(
      'ignores a changed slotId, preserving the original slot and claimedCount',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final slotAId = await service.addSlot(
          signupId,
          buildSlot(labelEn: 'Slot A', capacity: 3),
        );
        final slotBId = await service.addSlot(
          signupId,
          buildSlot(labelEn: 'Slot B', capacity: 3),
        );
        final addResult = await service.adminAddEntry(
          signupId: signupId,
          slotId: slotAId,
          name: 'Jane Doe',
        );
        final original = (await service.getAllEntries(signupId).first).single;

        // A caller attempts to move the entry to a different slot via
        // updateEntry, which is not transactional and has no capacity
        // check — this must be a no-op on slotId/claimedCount, not a
        // silent desync.
        await service.updateEntry(
          signupId,
          original.copyWith(slotId: slotBId, name: 'Jane Smith'),
        );

        final fetched = (await service.getAllEntries(signupId).first).single;
        expect(fetched.id, addResult['entryId']);
        expect(fetched.name, 'Jane Smith');
        expect(fetched.slotId, slotAId);

        final slots = await service.getSlots(signupId).first;
        final slotA = slots.firstWhere((s) => s.id == slotAId);
        final slotB = slots.firstWhere((s) => s.id == slotBId);
        expect(slotA.claimedCount, 1);
        expect(slotB.claimedCount, 0);
      },
    );
  });

  group('SignupService updateOwnEntry', () {
    late String signupId;
    late String slotId;

    /// A device's own entry in [slot] (defaults to the shared slot).
    Future<String> claim({
      String name = 'Jane Doe',
      String? phone,
      String? email,
      String? slot,
      double? pledgeAmount,
      String? note,
    }) async {
      final result = await service.claimSlot(
        signupId: signupId,
        slotId: slot ?? slotId,
        name: name,
        phone: phone,
        email: email,
        deviceId: 'device_1',
        pledgeAmount: pledgeAmount,
        note: note,
      );
      expect(result['success'], true);
      return result['entryId'] as String;
    }

    Future<SignupEntry> entry(String id) async =>
        (await service.getAllEntries(signupId).first).firstWhere(
          (e) => e.id == id,
        );

    setUp(() async {
      signupId = await service.createSignup(buildSignup());
      slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
    });

    test('updates name, phone, email, pledge and note', () async {
      final id = await claim(phone: '+14255550000');

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
        phone: '+14255551234',
        email: 'jane@example.com',
        pledgeAmount: 25,
        note: 'Bringing sweets',
      );

      expect(result, {'success': true});
      final saved = await entry(id);
      expect(saved.name, 'Jane Smith');
      expect(saved.phone, '+14255551234');
      expect(saved.email, 'jane@example.com');
      expect(saved.pledgeAmount, 25);
      expect(saved.note, 'Bringing sweets');
    });

    test('leaves the slot, device, join time and slot count alone', () async {
      final id = await claim();
      final before = await entry(id);

      await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
      );

      final after = await entry(id);
      expect(after.slotId, before.slotId);
      expect(after.deviceId, 'device_1');
      expect(after.joinedAt, before.joinedAt);
      final slot = (await service.getSlots(signupId).first).single;
      expect(slot.claimedCount, 1);
    });

    test('trims text and stores blank phone, email and note as null', () async {
      final id = await claim(
        phone: '+14255550000',
        email: 'jane@example.com',
        note: 'old',
      );

      await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: '  Jane Smith  ',
        phone: '   ',
        email: '',
        note: ' ',
      );

      final saved = await entry(id);
      expect(saved.name, 'Jane Smith');
      expect(saved.phone, isNull);
      expect(saved.email, isNull);
      expect(saved.note, isNull);
    });

    test('clears the pledge when none is given', () async {
      final id = await claim(pledgeAmount: 50);

      await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Doe',
      );

      expect((await entry(id)).pledgeAmount, isNull);
    });

    test('is not a duplicate of the entry\'s own phone and email', () async {
      final id = await claim(phone: '+14255550000', email: 'jane@example.com');

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
        phone: '+14255550000',
        email: 'JANE@example.com',
      );

      expect(result, {'success': true});
    });

    test('rejects a phone another entry in the same slot already has, '
        'even without a country code, and changes nothing', () async {
      await claim(name: 'Amit', phone: '4255551234');
      final id = await claim(phone: '+14255550000');

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
        phone: '+14255551234',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
      final saved = await entry(id);
      expect(saved.name, 'Jane Doe');
      expect(saved.phone, '+14255550000');
    });

    test('rejects an email another entry in the same slot already has '
        '(ignoring case)', () async {
      await claim(name: 'Amit', email: 'amit@example.com');
      final id = await claim(email: 'jane@example.com');

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Doe',
        email: ' AMIT@example.com ',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
    });

    test('lets an entry that shares an unchanged phone with another entry '
        'in its slot still save other changes', () async {
      // An admin can add two entries with the same phone to one slot, and
      // numbers saved without a country code can collide with ones that
      // have one; the devotee must still be able to fix their own name.
      final id = await claim(
        phone: '+14255551234',
        email: 'shared@example.com',
      );
      await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Amit',
        phone: '4255551234',
        email: 'shared@example.com',
      );

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
        phone: '+14255551234',
        email: ' Shared@Example.com ',
        pledgeAmount: 10,
        note: 'Sweets',
      );

      expect(result, {'success': true});
      final saved = await entry(id);
      expect(saved.name, 'Jane Smith');
      expect(saved.pledgeAmount, 10);
      expect(saved.note, 'Sweets');
    });

    test('still refuses changing only the phone to a taken one when the '
        'email is shared and unchanged', () async {
      await claim(name: 'Amit', phone: '+14255559999');
      final id = await claim(phone: '+14255550000', email: 'jane@example.com');

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Doe',
        phone: '+14255559999',
        email: 'jane@example.com',
      );

      expect(result, {'success': false, 'error': 'duplicate_entry'});
    });

    test('allows a phone another entry has in a different slot', () async {
      final otherSlot = await service.addSlot(
        signupId,
        buildSlot(labelEn: 'Week 2', capacity: 5),
      );
      await claim(name: 'Amit', phone: '+14255551234', slot: otherSlot);
      final id = await claim();

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Doe',
        phone: '+14255551234',
      );

      expect(result, {'success': true});
    });

    test('returns not_found when the entry no longer exists', () async {
      final id = await claim();
      await service.cancelEntry(signupId, id);

      final result = await service.updateOwnEntry(
        signupId: signupId,
        entryId: id,
        name: 'Jane Smith',
      );

      expect(result, {'success': false, 'error': 'not_found'});
      expect(await service.getAllEntries(signupId).first, isEmpty);
    });
  });

  group('SignupService claimMyEntries', () {
    late MockFirebaseFunctions functions;
    late MockHttpsCallable callable;
    late MockHttpsCallableResult callableResult;
    late SignupService claimingService;

    setUp(() {
      functions = MockFirebaseFunctions();
      callable = MockHttpsCallable();
      callableResult = MockHttpsCallableResult();
      when(() => functions.httpsCallable(any())).thenReturn(callable);
      when(() => callable.call(any())).thenAnswer((_) async => callableResult);
      when(
        () => callableResult.data,
      ).thenReturn({'status': 'SUCCESS', 'count': 2});
      claimingService = SignupService(
        firestore: fakeFirestore,
        storage: mockStorage,
        functions: functions,
      );
    });

    Future<ClaimEntriesResult> claim({String? joinCode}) =>
        claimingService.claimMyEntries(
          signupId: 'signup_1',
          phone: '+14255551234',
          deviceId: 'device_a',
          joinCode: joinCode,
        );

    test('calls claimSignupEntries with the sign-up, phone, device and join '
        'code', () async {
      await claim(joinCode: 'ABC123');

      verify(() => functions.httpsCallable('claimSignupEntries')).called(1);
      verify(
        () => callable.call({
          'signupId': 'signup_1',
          'phone': '+14255551234',
          'deviceId': 'device_a',
          'joinCode': 'ABC123',
        }),
      ).called(1);
    });

    test('leaves the join code out when there is none', () async {
      await claim();

      verify(
        () => callable.call({
          'signupId': 'signup_1',
          'phone': '+14255551234',
          'deviceId': 'device_a',
        }),
      ).called(1);
    });

    test('maps a success with its count', () async {
      final result = await claim();

      expect(result.status, ClaimEntriesStatus.success);
      expect(result.count, 2);
    });

    test('maps every refusal', () async {
      for (final (wire, status) in [
        ('NOT_FOUND', ClaimEntriesStatus.notFound),
        ('ALREADY_CLAIMED', ClaimEntriesStatus.alreadyClaimed),
        ('INVALID_JOIN_CODE', ClaimEntriesStatus.invalidJoinCode),
      ]) {
        when(() => callableResult.data).thenReturn({'status': wire});

        final result = await claim();

        expect(result.status, status, reason: wire);
        expect(result.count, 0, reason: wire);
      }
    });

    test('treats a missing count on success as zero', () async {
      when(() => callableResult.data).thenReturn({'status': 'SUCCESS'});

      expect((await claim()).count, 0);
    });

    test('throws on a status it does not know rather than claiming '
        'success', () async {
      when(() => callableResult.data).thenReturn({'status': 'SOMETHING_NEW'});

      expect(claim, throwsStateError);
    });

    test('throws on a response with no status', () async {
      when(() => callableResult.data).thenReturn(<String, dynamic>{});

      expect(claim, throwsStateError);
    });

    test('lets a failed call through', () async {
      when(() => callable.call(any())).thenThrow(
        FirebaseFunctionsException(message: 'boom', code: 'internal'),
      );

      expect(claim, throwsA(isA<FirebaseFunctionsException>()));
    });
  });

  group('SignupService releaseEntryDevice', () {
    late String signupId;
    late String slotId;

    setUp(() async {
      signupId = await service.createSignup(buildSignup());
      slotId = await service.addSlot(signupId, buildSlot(capacity: 5));
    });

    DocumentReference<Map<String, dynamic>> entryRef(String id) =>
        fakeFirestore.doc('signups/$signupId/entries/$id');

    test('clears the device and the claim time, and nothing else', () async {
      final claimed = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        phone: '+14255551234',
        email: 'jane@example.com',
        deviceId: 'device_a',
        pledgeAmount: 10,
        note: 'Sweets',
      );
      final id = claimed['entryId'] as String;
      await entryRef(id).update({'claimedAt': Timestamp.now()});

      await service.releaseEntryDevice(signupId, id);

      final data = (await entryRef(id).get()).data()!;
      expect(data['deviceId'], isNull);
      expect(data.containsKey('claimedAt'), isFalse);
      expect(data['name'], 'Jane');
      expect(data['phone'], '+14255551234');
      expect(data['email'], 'jane@example.com');
      expect(data['pledgeAmount'], 10);
      expect(data['note'], 'Sweets');
      expect(data['slotId'], slotId);
    });

    test('keeps the entry in its slot, so claimedCount is unchanged', () async {
      final claimed = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_a',
      );

      await service.releaseEntryDevice(signupId, claimed['entryId'] as String);

      final slot = (await service.getSlots(signupId).first).single;
      expect(slot.claimedCount, 1);
    });

    test('is a no-op on an entry that has no device', () async {
      final added = await service.adminAddEntry(
        signupId: signupId,
        slotId: slotId,
        name: 'Amit',
      );
      final id = added['entryId'] as String;

      await service.releaseEntryDevice(signupId, id);

      final data = (await entryRef(id).get()).data()!;
      expect(data['deviceId'], isNull);
      expect(data['name'], 'Amit');
    });

    test('takes the entry off the old device\'s My Sign Ups', () async {
      final claimed = await service.claimSlot(
        signupId: signupId,
        slotId: slotId,
        name: 'Jane',
        deviceId: 'device_a',
      );
      final id = claimed['entryId'] as String;

      await service.releaseEntryDevice(signupId, id);

      final mine = await service.getEntriesByDevice(signupId, 'device_a').first;
      expect(mine, isEmpty);
    });

    test('throws when the entry does not exist', () async {
      expect(
        () => service.releaseEntryDevice(signupId, 'missing'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  group('SignupService header image', () {
    test(
      'uploadHeaderImage stores the bytes and returns a download URL',
      () async {
        final signupId = await service.createSignup(buildSignup());

        final url = await service.uploadHeaderImage(
          signupId: signupId,
          bytes: Uint8List.fromList(List.filled(1024, 1)),
          contentType: 'image/jpeg',
        );

        expect(url, isNotEmpty);
        expect(
          mockStorage.storedDataMap.containsKey('signups/$signupId/header'),
          true,
        );
      },
    );

    test(
      'uploadHeaderImage rejects a file larger than maxHeaderImageBytes',
      () async {
        final signupId = await service.createSignup(buildSignup());
        final oversized = Uint8List(SignupService.maxHeaderImageBytes + 1);

        expect(
          () => service.uploadHeaderImage(
            signupId: signupId,
            bytes: oversized,
            contentType: 'image/jpeg',
          ),
          throwsArgumentError,
        );
        expect(
          mockStorage.storedDataMap.containsKey('signups/$signupId/header'),
          false,
        );
      },
    );

    test('updateHeaderImageUrl sets the field on the signup', () async {
      final signupId = await service.createSignup(buildSignup());

      await service.updateHeaderImageUrl(
        signupId,
        'https://example.com/header.jpg',
      );

      final signup = await service.getSignupById(signupId).first;
      expect(signup!.headerImageUrl, 'https://example.com/header.jpg');
    });

    test('updateHeaderImageUrl clears the field when passed null', () async {
      final signupId = await service.createSignup(buildSignup());
      await service.updateHeaderImageUrl(
        signupId,
        'https://example.com/header.jpg',
      );

      await service.updateHeaderImageUrl(signupId, null);

      final signup = await service.getSignupById(signupId).first;
      expect(signup!.headerImageUrl, isNull);
    });

    test(
      'removeHeaderImage deletes the Storage object and clears the field',
      () async {
        final signupId = await service.createSignup(buildSignup());
        await service.uploadHeaderImage(
          signupId: signupId,
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
        );
        await service.updateHeaderImageUrl(
          signupId,
          'https://example.com/header.jpg',
        );

        await service.removeHeaderImage(signupId);

        final signup = await service.getSignupById(signupId).first;
        expect(signup!.headerImageUrl, isNull);
        expect(
          mockStorage.storedDataMap.containsKey('signups/$signupId/header'),
          false,
        );
      },
    );

    test(
      'removeHeaderImage does not throw when no image was ever uploaded',
      () async {
        final signupId = await service.createSignup(buildSignup());

        await service.removeHeaderImage(signupId);

        final signup = await service.getSignupById(signupId).first;
        expect(signup!.headerImageUrl, isNull);
      },
    );

    test(
      'removeHeaderImage rethrows a Storage error that is not object-not-found',
      () async {
        final throwingService = SignupService(
          firestore: fakeFirestore,
          storage: _ThrowingHeaderImageStorage(),
        );
        final signupId = await service.createSignup(buildSignup());

        expect(
          () => throwingService.removeHeaderImage(signupId),
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
        final signupId = await service.createSignup(buildSignup());

        await expectLater(
          throwingService.deleteHeaderImageFile(signupId),
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
        final signupId = await service.createSignup(buildSignup());

        expect(
          () => throwingService.deleteHeaderImageFile(signupId),
          throwsA(isA<FirebaseException>()),
        );
      },
    );
  });

  group('SignupService deleteSignup', () {
    test('removes the signup with all of its slots and entries', () async {
      final signupId = await service.createSignup(buildSignup());
      final slotId = await service.addSlot(signupId, buildSlot());
      await service.addSlot(signupId, buildSlot(labelEn: 'Week 2'));
      await service.claimSlot(signupId: signupId, slotId: slotId, name: 'Jane');

      await service.deleteSignup(signupId);

      expect(await service.getSignupById(signupId).first, isNull);
      final slots = await fakeFirestore
          .collection('signups')
          .doc(signupId)
          .collection('slots')
          .get();
      final entries = await fakeFirestore
          .collection('signups')
          .doc(signupId)
          .collection('entries')
          .get();
      expect(slots.docs, isEmpty);
      expect(entries.docs, isEmpty);
    });

    test('deletes the header image from Storage', () async {
      final signupId = await service.createSignup(buildSignup());
      await service.uploadHeaderImage(
        signupId: signupId,
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
      );

      await service.deleteSignup(signupId);

      expect(
        mockStorage.storedDataMap.containsKey('signups/$signupId/header'),
        false,
      );
    });

    test('succeeds for a signup that never had an image', () async {
      final signupId = await service.createSignup(buildSignup());

      await service.deleteSignup(signupId);

      expect(await service.getSignupById(signupId).first, isNull);
    });

    test('leaves other signups untouched', () async {
      final keepId = await service.createSignup(buildSignup(titleEn: 'Keep'));
      await service.addSlot(keepId, buildSlot());
      final deleteId = await service.createSignup(buildSignup());

      await service.deleteSignup(deleteId);

      expect((await service.getSignupById(keepId).first)!.titleEn, 'Keep');
      expect(await service.getSlots(keepId).first, hasLength(1));
    });

    test('deletes more slots than fit in one batch', () async {
      final signupId = await service.createSignup(buildSignup());
      for (var i = 0; i < 450; i++) {
        await service.addSlot(signupId, buildSlot(labelEn: 'Slot $i'));
      }

      await service.deleteSignup(signupId);

      final slots = await fakeFirestore
          .collection('signups')
          .doc(signupId)
          .collection('slots')
          .get();
      expect(slots.docs, isEmpty);
    });

    test('keeps the signup when the Storage delete fails', () async {
      final throwingService = SignupService(
        firestore: fakeFirestore,
        storage: _ThrowingHeaderImageStorage(),
      );
      final signupId = await service.createSignup(buildSignup());

      await expectLater(
        throwingService.deleteSignup(signupId),
        throwsA(isA<FirebaseException>()),
      );

      expect(await service.getSignupById(signupId).first, isNotNull);
    });
  });
}
