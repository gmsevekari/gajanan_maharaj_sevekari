import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
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
          throwsStateError,
        );

        final slots = await service.getSlots(signupId).first;
        expect(slots, isNotEmpty);
      },
    );

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
