import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_entry.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_sheet.dart';
import 'package:gajanan_maharaj_sevekari/models/signup_slot.dart';

class SignupService {
  final FirebaseFirestore _db;

  SignupService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sheetsRef =>
      _db.collection('signup_sheets');

  /// Creates a new sheet with a Firestore auto-generated ID and returns it.
  Future<String> createSheet(SignupSheet sheet) async {
    final docRef = await _sheetsRef.add(sheet.toMap());
    return docRef.id;
  }

  /// Streams a single sheet, or `null` if it doesn't exist.
  Stream<SignupSheet?> getSheetById(String sheetId) {
    return _sheetsRef.doc(sheetId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return SignupSheet.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  /// Published sheets for a group, most recently created first.
  Stream<List<SignupSheet>> getActiveSheets(String groupId) {
    return _sheetsRef
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: SignupSheetStatus.published.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSheets);
  }

  /// All sheets for a group regardless of status (admin dashboard).
  Stream<List<SignupSheet>> getAllSheets(String groupId) {
    return _sheetsRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSheets);
  }

  List<SignupSheet> _mapSheets(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => SignupSheet.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Overwrites a sheet's fields. [sheet.id] must be set.
  Future<void> updateSheet(SignupSheet sheet) async {
    await _sheetsRef.doc(sheet.id).set(sheet.toMap());
  }

  Future<void> updateSheetStatus(
    String sheetId,
    SignupSheetStatus newStatus,
  ) async {
    await _sheetsRef.doc(sheetId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
    });
  }

  CollectionReference<Map<String, dynamic>> _slotsRef(String sheetId) =>
      _sheetsRef.doc(sheetId).collection('slots');

  /// Adds a slot with a Firestore auto-generated ID and returns it.
  Future<String> addSlot(String sheetId, SignupSlot slot) async {
    final docRef = await _slotsRef(sheetId).add(slot.toMap());
    return docRef.id;
  }

  /// Slots for a sheet, ordered by their admin-defined sortOrder.
  Stream<List<SignupSlot>> getSlots(String sheetId) {
    return _slotsRef(sheetId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SignupSlot.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Overwrites a slot's fields. [slot.id] must be set.
  Future<void> updateSlot(String sheetId, SignupSlot slot) async {
    await _slotsRef(sheetId).doc(slot.id).set(slot.toMap());
  }

  Future<void> deleteSlot(String sheetId, String slotId) async {
    await _slotsRef(sheetId).doc(slotId).delete();
  }

  /// Rewrites `sortOrder` on each slot to match its position in
  /// [orderedSlotIds], in a single batch.
  Future<void> reorderSlots(String sheetId, List<String> orderedSlotIds) async {
    final batch = _db.batch();
    final slotsRef = _slotsRef(sheetId);
    for (var i = 0; i < orderedSlotIds.length; i++) {
      batch.update(slotsRef.doc(orderedSlotIds[i]), {'sortOrder': i});
    }
    await batch.commit();
  }

  /// Creates a sheet and all of its slots in a single batch, so a sheet
  /// with many slots never ends up partially written. Returns the new
  /// sheet's auto-generated ID.
  Future<String> createSheetWithSlots(
    SignupSheet sheet,
    List<SignupSlot> slots,
  ) async {
    if (slots.isEmpty) {
      throw ArgumentError.value(slots, 'slots', 'must not be empty');
    }

    final sheetRef = _sheetsRef.doc();
    final batch = _db.batch();
    batch.set(sheetRef, sheet.toMap());

    final slotsRef = _slotsRef(sheetRef.id);
    for (final slot in slots) {
      batch.set(slotsRef.doc(), slot.toMap());
    }

    await batch.commit();
    return sheetRef.id;
  }

  CollectionReference<Map<String, dynamic>> _entriesRef(String sheetId) =>
      _sheetsRef.doc(sheetId).collection('entries');

  /// All entries for a sheet (admin entry-management view).
  Stream<List<SignupEntry>> getAllEntries(String sheetId) {
    return _entriesRef(sheetId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SignupEntry.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// A device's own entries on a sheet ("my signups").
  Stream<List<SignupEntry>> getEntriesByDevice(
    String sheetId,
    String deviceId,
  ) {
    return _entriesRef(sheetId)
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SignupEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Claims a slot for a devotee. Runs in a transaction so a slot can
  /// never be over-claimed: reads the sheet (for join-code validation) and
  /// the slot (for capacity), then writes the entry and increments the
  /// slot's `claimedCount` together, or writes nothing at all.
  ///
  /// Returns `{'success': true, 'entryId': ...}` or
  /// `{'success': false, 'error': 'not_found' | 'invalid_join_code' | 'slot_full'}`.
  Future<Map<String, dynamic>> claimSlot({
    required String sheetId,
    required String slotId,
    required String name,
    String? phone,
    String? email,
    String? deviceId,
    double? pledgeAmount,
    String? note,
    String? joinCode,
  }) {
    final sheetRef = _sheetsRef.doc(sheetId);
    final slotRef = _slotsRef(sheetId).doc(slotId);
    final entryRef = _entriesRef(sheetId).doc();

    return _db.runTransaction<Map<String, dynamic>>((transaction) async {
      final sheetSnapshot = await transaction.get(sheetRef);
      final slotSnapshot = await transaction.get(slotRef);

      if (!sheetSnapshot.exists || !slotSnapshot.exists) {
        return {'success': false, 'error': 'not_found'};
      }

      final sheet = SignupSheet.fromMap(
        sheetSnapshot.id,
        sheetSnapshot.data()!,
      );
      final slot = SignupSlot.fromMap(slotSnapshot.id, slotSnapshot.data()!);

      if (sheet.requiresJoinCode && joinCode != sheet.joinCode) {
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
    String sheetId,
    String entryId,
  ) async {
    final entryRef = _entriesRef(sheetId).doc(entryId);

    await _db.runTransaction((transaction) async {
      final entrySnapshot = await transaction.get(entryRef);
      if (!entrySnapshot.exists) return;

      final entry = SignupEntry.fromMap(
        entrySnapshot.id,
        entrySnapshot.data()!,
      );
      final slotRef = _slotsRef(sheetId).doc(entry.slotId);
      final slotSnapshot = await transaction.get(slotRef);

      transaction.delete(entryRef);
      if (slotSnapshot.exists) {
        transaction.update(slotRef, {'claimedCount': FieldValue.increment(-1)});
      }
    });
  }

  /// A devotee cancelling their own entry. A no-op if the entry is already
  /// gone, so calling it twice never decrements `claimedCount` twice.
  Future<void> cancelEntry(String sheetId, String entryId) =>
      _removeEntryAndDecrementSlot(sheetId, entryId);

  /// An admin removing any entry. Same behavior as [cancelEntry] — the
  /// devotee-vs-admin distinction is enforced by Firestore rules/UI, not
  /// by different logic here.
  Future<void> adminRemoveEntry(String sheetId, String entryId) =>
      _removeEntryAndDecrementSlot(sheetId, entryId);
}
