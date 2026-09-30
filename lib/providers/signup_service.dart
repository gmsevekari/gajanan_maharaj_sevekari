import 'package:cloud_firestore/cloud_firestore.dart';
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
}
