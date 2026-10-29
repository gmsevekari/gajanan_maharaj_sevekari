part of 'signup_service.dart';

mixin _SignupServiceEntries {
  FirebaseFirestore get _db;
  FirebaseFunctions get _functions;
  DateTime Function() get _now;
  CollectionReference<Map<String, dynamic>> get _signupsRef;
  CollectionReference<Map<String, dynamic>> _slotsRef(String signupId);

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

  /// A device's own entries on a signup, read from the server (never the
  /// local cache) so a stale or empty cached copy can't pass for the truth.
  /// Throws if the server can't be reached.
  Future<List<SignupEntry>> fetchEntriesByDevice(
    String signupId,
    String deviceId,
  ) async {
    final snapshot = await _entriesRef(signupId)
        .where('deviceId', isEqualTo: deviceId)
        .get(const GetOptions(source: Source.server));
    return [
      for (final doc in snapshot.docs) SignupEntry.fromMap(doc.id, doc.data()),
    ];
  }

  /// Every slot of a signup, read from the server (never the local cache).
  /// Throws if the server can't be reached.
  Future<List<SignupSlot>> fetchSlots(String signupId) async {
    final snapshot = await _slotsRef(
      signupId,
    ).get(const GetOptions(source: Source.server));
    return [
      for (final doc in snapshot.docs) SignupSlot.fromMap(doc.id, doc.data()),
    ];
  }

  /// Every entry linked to [deviceId], on any signup, read from the server.
  /// Throws if the server can't be reached.
  Future<List<({String signupId, SignupEntry entry})>> fetchEntriesForDevice(
    String deviceId,
  ) async {
    final snapshot = await _db
        .collectionGroup('entries')
        .where('deviceId', isEqualTo: deviceId)
        .get(const GetOptions(source: Source.server));
    return [
      for (final doc in snapshot.docs)
        (
          signupId: doc.reference.parent.parent!.id,
          entry: SignupEntry.fromMap(doc.id, doc.data()),
        ),
    ];
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
  /// `{'success': false, 'error': 'not_found' | 'signup_closed' |
  /// 'invalid_join_code' | 'slot_full' | 'duplicate_entry'}`.
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
      final now = _now();

      if (signup.status == SignupStatus.closed ||
          signup.isPast(now) ||
          slot.isPast(now)) {
        return {'success': false, 'error': 'signup_closed'};
      }

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
        joinedAt: now,
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
        joinedAt: _now(),
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
}
