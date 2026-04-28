import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminAuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log an administrative action to the 'admin_audit_logs' collection.
  /// Standard TTL is 30 days.
  static Future<void> logAction({
    required String action,
    Map<String, dynamic>? details,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    try {
      final authInstance = auth ?? _auth;
      final firestoreInstance = firestore ?? _firestore;
      final user = authInstance.currentUser;
      if (user == null || user.email == null) {
        debugPrint(
          'Warning: Attempted to log admin action without authenticated user.',
        );
        return;
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      await firestoreInstance.collection('admin_audit_logs').add({
        'admin_email': user.email,
        'action': action,
        'details': details,
        'timestamp': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });

      debugPrint('Admin Audit Log: $action by ${user.email}');
    } catch (e) {
      debugPrint('Error writing admin audit log: $e');
      // We don't block the UI if audit logging fails, but we log the error locally.
    }
  }
}
