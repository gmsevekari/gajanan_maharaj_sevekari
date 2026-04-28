import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';

class AdminManagementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminManagementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get a stream of all admins in the system.
  Stream<List<AdminUser>> getAllAdmins() {
    return _firestore.collection('admin_allowlist').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get a stream of admins belonging to a specific group.
  Stream<List<AdminUser>> getAdminsForGroup(String groupId) {
    return _firestore
        .collection('admin_allowlist')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Delete an admin from the allowlist.
  Future<void> deleteAdmin(String email) async {
    await _firestore.collection('admin_allowlist').doc(email).delete();

    await AdminAuditService.logAction(
      action: 'DELETE_ADMIN',
      details: {'deleted_admin_email': email},
      auth: _auth,
      firestore: _firestore,
    );
  }

  /// Add or update an admin in the allowlist.
  Future<void> saveAdmin(AdminUser admin) async {
    await _firestore.collection('admin_allowlist').doc(admin.email).set({
      'roles': admin.roles,
      'groupId': admin.groupId,
      'typoNotificationsEnabled': admin.typoNotificationsEnabled,
    });

    await AdminAuditService.logAction(
      action: 'SAVE_ADMIN',
      details: {
        'target_admin_email': admin.email,
        'roles': admin.roles,
        'groupId': admin.groupId,
      },
      auth: _auth,
      firestore: _firestore,
    );
  }
}
