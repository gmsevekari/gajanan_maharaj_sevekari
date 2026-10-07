import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gajanan_maharaj_sevekari/models/claim_entries_result.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';
import 'package:gajanan_maharaj_sevekari/utils/join_code_generator.dart';
import 'package:gajanan_maharaj_sevekari/utils/phone_utils.dart';

/// An admin tried to save a slot with a capacity below the number of people
/// who have already signed up for it. [claimedCount] is that live number.
class SlotCapacityBelowClaimedException implements Exception {
  final int claimedCount;

  const SlotCapacityBelowClaimedException(this.claimedCount);

  @override
  String toString() =>
      'SlotCapacityBelowClaimedException: $claimedCount already signed up';
}

class SignupService {
  /// Header images larger than this are rejected before an upload is even
  /// attempted - the UI can check this up front, and storage.rules enforces
  /// the same bound server-side as the real security boundary.
  static const int maxHeaderImageBytes = 2 * 1024 * 1024;

  static const int _batchLimit = 400;

  final FirebaseFirestore _db;
  final FirebaseStorage? _storageOverride;
  final FirebaseFunctions? _functionsOverride;

  SignupService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storageOverride = storage,
       _functionsOverride = functions;

  /// Resolved lazily (not in the constructor) so that call sites which
  /// never touch header-image methods - including every existing test
  /// that injects only a fake Firestore - don't need Firebase initialized
  /// just to construct a SignupService.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  /// Resolved lazily for the same reason as [_storage].
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _signupsRef =>
      _db.collection('signups');

  /// A fresh Firestore document id, generated without writing anything -
  /// lets the caller know a signup's id (for its Storage header-image path)
  /// before the signup document itself exists.
  String newSignupId() => _signupsRef.doc().id;

  /// Creates a new signup. Writes to [signup.id] when already set (paired
  /// with [newSignupId], so a header image can be uploaded to a known path
  /// before the signup document exists); otherwise auto-generates one via
  /// Firestore, matching this method's original behavior.
  Future<String> createSignup(Signup signup) async {
    if (signup.id != null) {
      await _signupsRef.doc(signup.id).set(signup.toMap());
      return signup.id!;
    }
    final docRef = await _signupsRef.add(signup.toMap());
    return docRef.id;
  }

  Reference _headerImageRef(String signupId) =>
      _storage.ref('signups/$signupId/header');

  /// Uploads a signup's header/display image and returns its download URL.
  /// Throws [ArgumentError] without attempting an upload when [bytes]
  /// exceeds [maxHeaderImageBytes].
  Future<String> uploadHeaderImage({
    required String signupId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > maxHeaderImageBytes) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'exceeds maxHeaderImageBytes ($maxHeaderImageBytes)',
      );
    }
    final normalizedContentType =
        contentType.toLowerCase().trim() == 'image/jpg'
        ? 'image/jpeg'
        : contentType.trim();
    final ref = _headerImageRef(signupId);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: normalizedContentType),
    );
    return ref.getDownloadURL();
  }

  /// Narrow update of just the header image URL field.
  Future<void> updateHeaderImageUrl(String signupId, String? url) async {
    await _signupsRef.doc(signupId).update({
      'headerImageUrl': url,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Deletes a signup's header image object from Storage, tolerating one
  /// that was never uploaded. Does not touch the signup document - used
  /// both by [removeHeaderImage] and to clean up an upload that was never
  /// attached to a signup (e.g. the signup's own creation failed after the
  /// image upload succeeded).
  Future<void> deleteHeaderImageFile(String signupId) async {
    try {
      await _headerImageRef(signupId).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Deletes a signup's header image from Storage (tolerating one that was
  /// never uploaded) and clears the field on the signup document.
  Future<void> removeHeaderImage(String signupId) async {
    await deleteHeaderImageFile(signupId);
    await updateHeaderImageUrl(signupId, null);
  }

  /// Deletes a signup together with its slots, entries and header image.
  ///
  /// Firestore doesn't cascade to subcollections, so they are removed
  /// explicitly, and the signup document goes last: if anything fails
  /// part-way (e.g. the Storage delete), the signup is still listed and
  /// the admin can simply retry.
  Future<void> deleteSignup(String signupId) async {
    await _deleteCollection(_entriesRef(signupId));
    await _deleteCollection(_slotsRef(signupId));
    await deleteHeaderImageFile(signupId);
    await _signupsRef.doc(signupId).delete();
  }

  /// Deletes every document in [collection], in batches under Firestore's
  /// 500-writes-per-batch limit.
  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    for (var start = 0; start < snapshot.docs.length; start += _batchLimit) {
      final batch = _db.batch();
      for (final doc in snapshot.docs.skip(start).take(_batchLimit)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Streams a single signup, or `null` if it doesn't exist.
  Stream<Signup?> getSignupById(String signupId) {
    return _signupsRef.doc(signupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Signup.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  /// Published signups for a group, most recently created first.
  Stream<List<Signup>> getActiveSignups(String groupId) {
    return _signupsRef
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: SignupStatus.published.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSignups);
  }

  /// All signups for a group regardless of status (admin dashboard).
  Stream<List<Signup>> getAllSignups(String groupId) {
    return _signupsRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSignups);
  }

  List<Signup> _mapSignups(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Signup.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Overwrites a signup's fields. Throws if [signup.id] is null — passing a
  /// null id to Firestore's `.doc()` would silently create a new document
  /// instead of updating the intended one.
  Future<void> updateSignup(Signup signup) async {
    if (signup.id == null) {
      throw ArgumentError.value(signup.id, 'signup.id', 'must not be null');
    }
    await _signupsRef.doc(signup.id).set(signup.toMap());
  }

  Future<void> updateSignupStatus(
    String signupId,
    SignupStatus newStatus,
  ) async {
    await _signupsRef.doc(signupId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
    });
  }

  CollectionReference<Map<String, dynamic>> _slotsRef(String signupId) =>
      _signupsRef.doc(signupId).collection('slots');

  /// Adds a slot with a Firestore auto-generated ID and returns it.
  Future<String> addSlot(String signupId, SignupSlot slot) async {
    final docRef = await _slotsRef(signupId).add(slot.toMap());
    return docRef.id;
  }

  /// Slots for a signup, ordered by their admin-defined sortOrder.
  Stream<List<SignupSlot>> getSlots(String signupId) {
    return _slotsRef(signupId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SignupSlot.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Overwrites a slot's admin-editable fields (label, start/end, timezone, capacity,
  /// suggestedAmount, sortOrder). `claimedCount` is deliberately excluded —
  /// it's owned by claimSlot/cancelEntry's transactions, so an admin
  /// saving a slot loaded before a concurrent claim/cancel can never
  /// clobber it. Throws if [slot.id] is null — passing a null id to
  /// Firestore's `.doc()` would silently create a new document instead of
  /// updating the intended one.
  ///
  /// Throws [SlotCapacityBelowClaimedException], writing nothing, if
  /// [slot.capacity] is below the slot's *current* claimed count - read in the
  /// same transaction as the write, so a claim that lands while the admin is
  /// editing can't leave the slot over-full.
  Future<void> updateSlot(String signupId, SignupSlot slot) async {
    if (slot.id == null) {
      throw ArgumentError.value(slot.id, 'slot.id', 'must not be null');
    }
    final fields = slot.toMap()..remove('claimedCount');
    final slotRef = _slotsRef(signupId).doc(slot.id);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(slotRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Slot ${slot.id} does not exist.',
        );
      }
      final claimed = (snapshot.data()?['claimedCount'] as num?)?.toInt() ?? 0;
      if (slot.capacity < claimed) {
        throw SlotCapacityBelowClaimedException(claimed);
      }
      transaction.update(slotRef, fields);
    });
  }

  /// Deletes a slot, refusing if it still has claimed entries — deleting it
  /// anyway would orphan those entries (pointing at a missing slot).
  Future<void> deleteSlot(String signupId, String slotId) async {
    final snapshot = await _slotsRef(signupId).doc(slotId).get();
    if (snapshot.exists) {
      final claimedCount = (snapshot.data()?['claimedCount'] as num?)?.toInt();
      if ((claimedCount ?? 0) > 0) {
        throw StateError(
          'Cannot delete slot $slotId: it still has $claimedCount claimed '
          'entr${claimedCount == 1 ? 'y' : 'ies'}.',
        );
      }
    }
    await _slotsRef(signupId).doc(slotId).delete();
  }

  /// Rewrites `sortOrder` on each slot to match its position in
  /// [orderedSlotIds], in a single batch.
  Future<void> reorderSlots(
    String signupId,
    List<String> orderedSlotIds,
  ) async {
    final batch = _db.batch();
    final slotsRef = _slotsRef(signupId);
    for (var i = 0; i < orderedSlotIds.length; i++) {
      batch.update(slotsRef.doc(orderedSlotIds[i]), {'sortOrder': i});
    }
    await batch.commit();
  }

  /// Creates a signup and all of its slots in a single batch, so a signup
  /// with many slots never ends up partially written. Writes to
  /// [signup.id] when already set (same pre-set-id support as
  /// [createSignup]); otherwise auto-generates one. Returns the signup's ID.
  Future<String> createSignupWithSlots(
    Signup signup,
    List<SignupSlot> slots,
  ) async {
    if (slots.isEmpty) {
      throw ArgumentError.value(slots, 'slots', 'must not be empty');
    }

    final signupRef = signup.id != null
        ? _signupsRef.doc(signup.id)
        : _signupsRef.doc();
    final batch = _db.batch();
    batch.set(signupRef, signup.toMap());

    final slotsRef = _slotsRef(signupRef.id);
    for (final slot in slots) {
      batch.set(slotsRef.doc(), slot.toMap());
    }

    await batch.commit();
    return signupRef.id;
  }

  CollectionReference<Map<String, dynamic>> _entriesRef(String signupId) =>
      _signupsRef.doc(signupId).collection('entries');

  /// All entries for a signup (admin entry-management view).
  Stream<List<SignupEntry>> getAllEntries(String signupId) {
    return _entriesRef(signupId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SignupEntry.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// A device's own entries on a signup ("my signups").
  Stream<List<SignupEntry>> getEntriesByDevice(
    String signupId,
    String deviceId,
  ) {
    return _entriesRef(signupId)
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SignupEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Overwrites an entry's editable fields (admin manual edit: name, phone,
  /// email, pledgeAmount, note). `slotId` is deliberately excluded from the
  /// write, mirroring [updateSlot]'s exclusion of `claimedCount` — moving
  /// an entry to a different slot would need the same capacity check and
  /// claimedCount transaction as [claimSlot], which this method doesn't
  /// perform, so the entry's original slot is always preserved regardless
  /// of what [entry.slotId] holds. `deviceId` is left alone too, because a
  /// devotee's claim (or an admin's release) may have changed it since the
  /// admin opened the entry, and `joinedAt` is never rewritten. Throws if
  /// [entry.id] is null.
  Future<void> updateEntry(String signupId, SignupEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError.value(entry.id, 'entry.id', 'must not be null');
    }
    final fields = entry.toMap()
      ..remove('slotId')
      ..remove('deviceId')
      ..remove('joinedAt');
    await _entriesRef(signupId).doc(entry.id).update(fields);
  }

  /// A devotee correcting their own entry: name, phone, email, pledge amount
  /// and note. Only those five fields are written - never `slotId`,
  /// `deviceId` or `joinedAt` (Firestore rules enforce the same limit) - so
  /// the entry stays in its slot and the slot's `claimedCount` is untouched.
  /// Text is trimmed; a blank phone, email or note is stored as null.
  ///
  /// Returns `{'success': true}` or `{'success': false, 'error':
  /// 'not_found' | 'duplicate_entry'}`; the latter when another entry in the
  /// same slot already has the new phone or email (a best-effort guard, like
  /// [claimSlot]'s). Only a phone or email that actually changed is checked,
  /// so an entry that already shares a number with another (an admin can add
  /// such pairs) can still have its name, pledge or note fixed.
  Future<Map<String, dynamic>> updateOwnEntry({
    required String signupId,
    required String entryId,
    required String name,
    String? phone,
    String? email,
    double? pledgeAmount,
    String? note,
  }) async {
    final entryRef = _entriesRef(signupId).doc(entryId);
    final snapshot = await entryRef.get();
    if (!snapshot.exists) return {'success': false, 'error': 'not_found'};

    final cleanPhone = _blankToNull(phone);
    final cleanEmail = _blankToNull(email);
    final current = SignupEntry.fromMap(snapshot.id, snapshot.data()!);
    final phoneChanged = _digits(cleanPhone) != _digits(current.phone);
    final emailChanged =
        _normalizedEmail(cleanEmail) != _normalizedEmail(current.email);
    if (await _hasDuplicateEntry(
      signupId: signupId,
      slotId: current.slotId,
      email: emailChanged ? cleanEmail : null,
      phone: phoneChanged ? cleanPhone : null,
      excludeEntryId: entryId,
    )) {
      return {'success': false, 'error': 'duplicate_entry'};
    }

    await entryRef.update({
      'name': name.trim(),
      'phone': cleanPhone,
      'email': cleanEmail,
      'pledgeAmount': pledgeAmount,
      'note': _blankToNull(note),
    });
    return {'success': true};
  }

  String _digits(String? phone) => phone?.replaceAll(RegExp(r'\D'), '') ?? '';

  String _normalizedEmail(String? email) => email?.trim().toLowerCase() ?? '';

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// True if [slotId] already has an entry matching [email] or [phone]
  /// (case/format-insensitive), ignoring the entry [excludeEntryId] (the one
  /// being edited). Checked before [claimSlot] opens its
  /// transaction, since Firestore transactions can't run queries - this is
  /// a best-effort UX guard against accidental double sign-up, not a hard
  /// security boundary, so a race between two near-simultaneous claims with
  /// the same contact info could still both succeed.
  Future<bool> _hasDuplicateEntry({
    required String signupId,
    required String slotId,
    String? email,
    String? phone,
    String? excludeEntryId,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final hasEmail = normalizedEmail != null && normalizedEmail.isNotEmpty;
    final hasPhone = (phone?.replaceAll(RegExp(r'\D'), '') ?? '').isNotEmpty;
    if (!hasEmail && !hasPhone) return false;

    final snapshot = await _entriesRef(
      signupId,
    ).where('slotId', isEqualTo: slotId).get();

    for (final doc in snapshot.docs) {
      if (doc.id == excludeEntryId) continue;
      final data = doc.data();
      final existingEmail = (data['email'] as String?)?.trim().toLowerCase();
      if (hasEmail && existingEmail == normalizedEmail) return true;
      if (hasPhone && phonesMatch(data['phone'] as String?, phone)) {
        return true;
      }
    }
    return false;
  }

  /// Claims a slot for a devotee. Runs in a transaction so a slot can
  /// never be over-claimed: reads the signup (for join-code validation) and
  /// the slot (for capacity), then writes the entry and increments the
  /// slot's `claimedCount` together, or writes nothing at all.
  ///
  /// Returns `{'success': true, 'entryId': ...}` or
  /// `{'success': false, 'error': 'not_found' | 'invalid_join_code' |
  /// 'slot_full' | 'duplicate_entry'}`.
  Future<Map<String, dynamic>> claimSlot({
    required String signupId,
    required String slotId,
    required String name,
    String? phone,
    String? email,
    String? deviceId,
    double? pledgeAmount,
    String? note,
    String? joinCode,
  }) async {
    if (await _hasDuplicateEntry(
      signupId: signupId,
      slotId: slotId,
      email: email,
      phone: phone,
    )) {
      return {'success': false, 'error': 'duplicate_entry'};
    }

    final signupRef = _signupsRef.doc(signupId);
    final slotRef = _slotsRef(signupId).doc(slotId);
    final entryRef = _entriesRef(signupId).doc();

    return _db.runTransaction<Map<String, dynamic>>((transaction) async {
      final signupSnapshot = await transaction.get(signupRef);
      final slotSnapshot = await transaction.get(slotRef);

      if (!signupSnapshot.exists || !slotSnapshot.exists) {
        return {'success': false, 'error': 'not_found'};
      }

      final signup = Signup.fromMap(signupSnapshot.id, signupSnapshot.data()!);
      final slot = SignupSlot.fromMap(slotSnapshot.id, slotSnapshot.data()!);

      if (signup.requiresJoinCode && joinCode != signup.joinCode) {
        return {'success': false, 'error': 'invalid_join_code'};
      }

      if (slot.claimedCount >= slot.capacity) {
        return {'success': false, 'error': 'slot_full'};
      }

      final entry = SignupEntry(
        slotId: slotId,
        name: name,
        phone: phone,
        email: email,
        deviceId: deviceId,
        pledgeAmount: pledgeAmount,
        note: note,
        joinedAt: DateTime.now(),
      );

      transaction.set(entryRef, entry.toMap());
      transaction.update(slotRef, {'claimedCount': FieldValue.increment(1)});

      return {'success': true, 'entryId': entryRef.id};
    });
  }

  Future<void> _removeEntryAndDecrementSlot(
    String signupId,
    String entryId,
  ) async {
    final entryRef = _entriesRef(signupId).doc(entryId);

    await _db.runTransaction((transaction) async {
      final entrySnapshot = await transaction.get(entryRef);
      if (!entrySnapshot.exists) return;

      final entry = SignupEntry.fromMap(
        entrySnapshot.id,
        entrySnapshot.data()!,
      );
      final slotRef = _slotsRef(signupId).doc(entry.slotId);
      final slotSnapshot = await transaction.get(slotRef);

      transaction.delete(entryRef);
      if (slotSnapshot.exists) {
        transaction.update(slotRef, {'claimedCount': FieldValue.increment(-1)});
      }
    });
  }

  /// A devotee cancelling their own entry. A no-op if the entry is already
  /// gone, so calling it twice never decrements `claimedCount` twice.
  Future<void> cancelEntry(String signupId, String entryId) =>
      _removeEntryAndDecrementSlot(signupId, entryId);

  /// An admin removing any entry. Same behavior as [cancelEntry] — the
  /// devotee-vs-admin distinction is enforced by Firestore rules/UI, not
  /// by different logic here.
  Future<void> adminRemoveEntry(String signupId, String entryId) =>
      _removeEntryAndDecrementSlot(signupId, entryId);

  /// Admin-initiated manual entry, bypassing the join-code check — the
  /// admin is already authenticated as an admin. Still respects slot
  /// capacity, same as [claimSlot]: an admin who wants to overbook a slot
  /// must raise its capacity first via [updateSlot].
  ///
  /// Returns `{'success': true, 'entryId': ...}` or
  /// `{'success': false, 'error': 'not_found' | 'slot_full'}`.
  Future<Map<String, dynamic>> adminAddEntry({
    required String signupId,
    required String slotId,
    required String name,
    String? phone,
    String? email,
    double? pledgeAmount,
    String? note,
  }) {
    final slotRef = _slotsRef(signupId).doc(slotId);
    final entryRef = _entriesRef(signupId).doc();

    return _db.runTransaction<Map<String, dynamic>>((transaction) async {
      final slotSnapshot = await transaction.get(slotRef);
      if (!slotSnapshot.exists) {
        return {'success': false, 'error': 'not_found'};
      }

      final slot = SignupSlot.fromMap(slotSnapshot.id, slotSnapshot.data()!);
      if (slot.claimedCount >= slot.capacity) {
        return {'success': false, 'error': 'slot_full'};
      }

      final entry = SignupEntry(
        slotId: slotId,
        name: name,
        phone: phone,
        email: email,
        pledgeAmount: pledgeAmount,
        note: note,
        joinedAt: DateTime.now(),
      );

      transaction.set(entryRef, entry.toMap());
      transaction.update(slotRef, {'claimedCount': FieldValue.increment(1)});

      return {'success': true, 'entryId': entryRef.id};
    });
  }

  /// An admin releasing an entry from the device it is linked to, so its
  /// devotee can claim it again (from a new phone, say) with
  /// [claimMyEntries]. Clears `deviceId` and the claim time; the entry stays
  /// in its slot, so `claimedCount` is untouched. Throws if the entry doesn't
  /// exist.
  Future<void> releaseEntryDevice(String signupId, String entryId) {
    return _entriesRef(
      signupId,
    ).doc(entryId).update({'deviceId': null, 'claimedAt': FieldValue.delete()});
  }

  /// "Claim my sign up": links every entry on [signupId] made with [phone]
  /// (country code and number must match exactly) to [deviceId], through the
  /// `claimSignupEntries` Cloud Function, since Firestore rules don't let a
  /// device write its own `deviceId`. [joinCode] is checked by the function
  /// when the sign-up requires one. Nothing changes unless the result is
  /// [ClaimEntriesStatus.success]. A failed call throws, as does a response
  /// this app doesn't understand - never a made-up success.
  Future<ClaimEntriesResult> claimMyEntries({
    required String signupId,
    required String phone,
    required String deviceId,
    String? joinCode,
  }) async {
    final response = await _functions.httpsCallable('claimSignupEntries').call({
      'signupId': signupId,
      'phone': phone,
      'deviceId': deviceId,
      'joinCode': ?joinCode,
    });
    final data = response.data;
    final status = data is Map ? data['status'] : null;
    return switch (status) {
      'SUCCESS' => ClaimEntriesResult(
        ClaimEntriesStatus.success,
        count: data['count'] is num ? (data['count'] as num).toInt() : 0,
      ),
      'NOT_FOUND' => const ClaimEntriesResult(ClaimEntriesStatus.notFound),
      'ALREADY_CLAIMED' => const ClaimEntriesResult(
        ClaimEntriesStatus.alreadyClaimed,
      ),
      'INVALID_JOIN_CODE' => const ClaimEntriesResult(
        ClaimEntriesStatus.invalidJoinCode,
      ),
      _ => throw StateError('Unexpected claimSignupEntries response: $data'),
    };
  }

  /// Copies a signup's title/description/join-code-requirement and every
  /// slot (with `claimedCount` reset to 0) into a new draft signup. Entries
  /// are never copied. A fresh join code is generated if the original
  /// requires one.
  Future<String> duplicateSignup(String signupId) async {
    final sourceSnapshot = await _signupsRef.doc(signupId).get();
    if (!sourceSnapshot.exists) {
      throw ArgumentError.value(signupId, 'signupId', 'signup not found');
    }
    final source = Signup.fromMap(sourceSnapshot.id, sourceSnapshot.data()!);
    final now = DateTime.now();
    final duplicate = Signup(
      titleEn: source.titleEn,
      titleMr: source.titleMr,
      descriptionEn: source.descriptionEn,
      descriptionMr: source.descriptionMr,
      groupId: source.groupId,
      status: SignupStatus.draft,
      requiresJoinCode: source.requiresJoinCode,
      joinCode: source.requiresJoinCode ? generateJoinCode() : null,
      startDate: source.startDate,
      endDate: source.endDate,
      createdAt: now,
      updatedAt: now,
      createdBy: source.createdBy,
    );

    final sourceSlots = await _slotsRef(signupId).get();
    final newSignupRef = _signupsRef.doc();
    final batch = _db.batch();
    batch.set(newSignupRef, duplicate.toMap());

    final newSlotsRef = _slotsRef(newSignupRef.id);
    for (final doc in sourceSlots.docs) {
      final slot = SignupSlot.fromMap(doc.id, doc.data());
      batch.set(newSlotsRef.doc(), slot.copyWith(claimedCount: 0).toMap());
    }

    await batch.commit();
    return newSignupRef.id;
  }
}
