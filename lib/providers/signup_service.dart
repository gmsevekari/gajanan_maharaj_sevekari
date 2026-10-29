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

part 'signup_service_entries.dart';

/// An admin tried to save a slot with a capacity below the number of people
/// who have already signed up for it. [claimedCount] is that live number.
class SlotCapacityBelowClaimedException implements Exception {
  final int claimedCount;

  const SlotCapacityBelowClaimedException(this.claimedCount);

  @override
  String toString() =>
      'SlotCapacityBelowClaimedException: $claimedCount already signed up';
}

/// An admin tried to delete a slot that people have signed up for. Deleting it
/// would orphan their entries. [claimedCount] is the larger of the slot's
/// counter and the entries actually found on it.
class SlotHasClaimedEntriesException implements Exception {
  final String slotId;
  final int claimedCount;

  const SlotHasClaimedEntriesException(this.slotId, this.claimedCount);

  @override
  String toString() =>
      'SlotHasClaimedEntriesException: cannot delete slot $slotId, it still '
      'has $claimedCount claimed entr${claimedCount == 1 ? 'y' : 'ies'}.';
}

class SignupService with _SignupServiceEntries {
  /// Header images larger than this are rejected before an upload is even
  /// attempted - the UI can check this up front, and storage.rules enforces
  /// the same bound server-side as the real security boundary.
  static const int maxHeaderImageBytes = 2 * 1024 * 1024;

  static const int _batchLimit = 400;

  @override
  final FirebaseFirestore _db;
  final FirebaseStorage? _storageOverride;
  final FirebaseFunctions? _functionsOverride;
  @override
  final DateTime Function() _now;

  SignupService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    DateTime Function()? now,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storageOverride = storage,
       _functionsOverride = functions,
       _now = now ?? DateTime.now;

  /// Resolved lazily (not in the constructor) so that call sites which
  /// never touch header-image methods - including every existing test
  /// that injects only a fake Firestore - don't need Firebase initialized
  /// just to construct a SignupService.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  /// Resolved lazily for the same reason as [_storage].
  @override
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
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

  /// Active (upcoming) published signups for a group, most recently created
  /// first. Excludes any signup whose [Signup.endDate] has already passed.
  Stream<List<Signup>> getActiveSignups(String groupId) {
    return _signupsRef
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: SignupStatus.published.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = _now();
          return _mapSignups(snapshot).where((s) => !s.isPast(now)).toList();
        });
  }

  /// Past signups for a group (devotee "Past" tab), most recently created
  /// first: includes `closed` signups and any `published` signup whose
  /// [Signup.endDate] has passed.
  Stream<List<Signup>> getPastSignups(String groupId) {
    return _signupsRef
        .where('groupId', isEqualTo: groupId)
        .where(
          'status',
          whereIn: [SignupStatus.closed.name, SignupStatus.published.name],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = _now();
          return _mapSignups(snapshot)
              .where(
                (s) =>
                    s.status == SignupStatus.closed ||
                    (s.status == SignupStatus.published && s.isPast(now)),
              )
              .toList();
        });
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

  /// Changes a signup's title, description and join-code requirement - and
  /// nothing else. Only the fields given are written (plus `updatedAt`), so a
  /// form opened before another admin changed something, or before the status
  /// or header image changed, can't undo it; unlike [updateSignup], which
  /// overwrites the whole document. A null field is left as it is; an empty
  /// string empties it. Given nothing, nothing is written.
  ///
  /// [requiresJoinCode] null leaves the join code alone. True switches it on:
  /// [newJoinCode] (required, non-blank) becomes the code - unless the signup
  /// already requires a non-blank code, which is kept, so two admins switching
  /// it on don't replace each other's code. False switches it off and clears
  /// the code. The requirement is read in the same transaction as the write.
  /// [newJoinCode] is refused unless the requirement is being switched on.
  /// Throws if the signup is gone.
  Future<void> updateSignupDetails(
    String signupId, {
    String? titleEn,
    String? titleMr,
    String? descriptionEn,
    String? descriptionMr,
    bool? requiresJoinCode,
    String? newJoinCode,
  }) async {
    final switchingOn = requiresJoinCode == true;
    if (switchingOn && (newJoinCode == null || newJoinCode.trim().isEmpty)) {
      throw ArgumentError.value(
        newJoinCode,
        'newJoinCode',
        'is required when switching the join code on',
      );
    }
    if (!switchingOn && newJoinCode != null) {
      throw ArgumentError.value(
        newJoinCode,
        'newJoinCode',
        'is only for switching the join code on',
      );
    }

    final fields = <String, dynamic>{
      'titleEn': ?titleEn,
      'titleMr': ?titleMr,
      'descriptionEn': ?descriptionEn,
      'descriptionMr': ?descriptionMr,
    };
    if (fields.isEmpty && requiresJoinCode == null) return;

    final signupRef = _signupsRef.doc(signupId);
    if (requiresJoinCode == null) {
      await signupRef.update({...fields, 'updatedAt': Timestamp.now()});
      return;
    }

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(signupRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Signup $signupId does not exist.',
        );
      }
      final current = snapshot.data()?['joinCode'];
      final alreadyHasCode =
          snapshot.data()?['requiresJoinCode'] == true &&
          current is String &&
          current.trim().isNotEmpty;
      transaction.update(signupRef, {
        ...fields,
        'requiresJoinCode': requiresJoinCode,
        'joinCode': switchingOn
            ? (alreadyHasCode ? current : newJoinCode)
            : null,
        'updatedAt': Timestamp.now(),
      });
    });
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

  @override
  CollectionReference<Map<String, dynamic>> _slotsRef(String signupId) =>
      _signupsRef.doc(signupId).collection('slots');

  /// Adds a slot with a Firestore auto-generated ID and returns it.
  Future<String> addSlot(String signupId, SignupSlot slot) async {
    final docRef = await _slotsRef(signupId).add(slot.toMap());
    await _syncSignupDateRange(signupId);
    return docRef.id;
  }

  /// Recomputes `startDate` and `endDate` on [signupId] from its current
  /// slots so the parent signup's expiry span stays in sync with slot edits.
  Future<void> _syncSignupDateRange(String signupId) async {
    final signupRef = _signupsRef.doc(signupId);
    final signupSnap = await signupRef.get();
    if (!signupSnap.exists) return;

    final slotsSnap = await _slotsRef(signupId).get();
    final slots = [
      for (final doc in slotsSnap.docs) SignupSlot.fromMap(doc.id, doc.data()),
    ];
    final range = SignupSlot.deriveDateRange(slots);
    await signupRef.update({
      'startDate': range.startDate != null
          ? Timestamp.fromDate(range.startDate!)
          : null,
      'endDate': range.endDate != null
          ? Timestamp.fromDate(range.endDate!)
          : null,
      'updatedAt': Timestamp.now(),
    });
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

  /// Overwrites a slot's admin-editable fields (label, start/end, timezone,
  /// capacity, suggestedAmount). `claimedCount` is deliberately excluded —
  /// it's owned by claimSlot/cancelEntry's transactions, so an admin
  /// saving a slot loaded before a concurrent claim/cancel can never
  /// clobber it - and so are `sortOrder` (see [reorderSlots]) and
  /// `createdAt`. Throws if [slot.id] is null — passing a null id to
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
    // Not written: claimedCount (owned by the claim transactions), sortOrder
    // (owned by reorderSlots) and createdAt (never changes) - a form opened
    // earlier must not undo a claim or a reorder made since.
    final fields = slot.toMap()
      ..remove('claimedCount')
      ..remove('sortOrder')
      ..remove('createdAt');
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
      final claimedValue = snapshot.data()?['claimedCount'];
      final claimed = claimedValue is num ? claimedValue.toInt() : 0;
      if (slot.capacity < claimed) {
        throw SlotCapacityBelowClaimedException(claimed);
      }
      transaction.update(slotRef, fields);
    });
    await _syncSignupDateRange(signupId);
  }

  /// Deletes a slot, refusing with [SlotHasClaimedEntriesException] if people
  /// have signed up for it — deleting it anyway would orphan those entries
  /// (pointing at a missing slot).
  ///
  /// The slot's claimed counter is read in the same transaction as the delete,
  /// so a claim that lands at the same moment can't be orphaned. The counter
  /// can also drift from the entries (the rules don't tie them together), so
  /// the entries themselves are looked up first; the client transaction API
  /// can't run that query, which leaves only a very small window. Deleting a
  /// slot that is already gone does nothing.
  Future<void> deleteSlot(String signupId, String slotId) async {
    final entries = await _entriesRef(
      signupId,
    ).where('slotId', isEqualTo: slotId).get();
    final slotRef = _slotsRef(signupId).doc(slotId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(slotRef);
      final claimedValue = snapshot.data()?['claimedCount'];
      final counter = claimedValue is num ? claimedValue.toInt() : 0;
      final claimed = counter > entries.size ? counter : entries.size;
      if (claimed > 0) throw SlotHasClaimedEntriesException(slotId, claimed);
      transaction.delete(slotRef);
    });
    await _syncSignupDateRange(signupId);
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
    final range = SignupSlot.deriveDateRange(slots);
    final signupMap = signup.toMap()
      ..['startDate'] = range.startDate != null
          ? Timestamp.fromDate(range.startDate!)
          : null
      ..['endDate'] = range.endDate != null
          ? Timestamp.fromDate(range.endDate!)
          : null;
    final batch = _db.batch();
    batch.set(signupRef, signupMap);

    final slotsRef = _slotsRef(signupRef.id);
    for (final slot in slots) {
      batch.set(slotsRef.doc(), slot.toMap());
    }

    await batch.commit();
    return signupRef.id;
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
    final sourceSlots = await _slotsRef(signupId).get();
    final parsedSlots = [
      for (final doc in sourceSlots.docs)
        SignupSlot.fromMap(doc.id, doc.data()).copyWith(claimedCount: 0),
    ];
    final range = SignupSlot.deriveDateRange(parsedSlots);
    final now = _now();
    final duplicate = Signup(
      titleEn: source.titleEn,
      titleMr: source.titleMr,
      descriptionEn: source.descriptionEn,
      descriptionMr: source.descriptionMr,
      groupId: source.groupId,
      status: SignupStatus.draft,
      requiresJoinCode: source.requiresJoinCode,
      joinCode: source.requiresJoinCode ? generateJoinCode() : null,
      startDate: parsedSlots.isNotEmpty ? range.startDate : source.startDate,
      endDate: parsedSlots.isNotEmpty ? range.endDate : source.endDate,
      createdAt: now,
      updatedAt: now,
      createdBy: source.createdBy,
    );

    final newSignupRef = _signupsRef.doc();
    final batch = _db.batch();
    batch.set(newSignupRef, duplicate.toMap());

    final newSlotsRef = _slotsRef(newSignupRef.id);
    for (final slot in parsedSlots) {
      batch.set(newSlotsRef.doc(), slot.toMap());
    }

    await batch.commit();
    return newSignupRef.id;
  }
}
