import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TypoReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String typoNotifPrefKey = 'admin_typo_notifications_enabled';
  static const String typoTopic = 'admin_typo_reports';

  CollectionReference get _typoReportsRef => _db.collection('typo_reports');

  Future<void> submitReport(TypoReport report) async {
    await _typoReportsRef.doc(report.id).set(report.toFirestore());
  }

  Stream<List<TypoReport>> getPendingReports() {
    return _typoReportsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TypoReport.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> deleteReport(String reportId) async {
    await _typoReportsRef.doc(reportId).delete();
  }

  // Admin Notification Toggle Logic
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(typoNotifPrefKey) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(typoNotifPrefKey, enabled);

    if (enabled) {
      await FirebaseMessaging.instance.subscribeToTopic(typoTopic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(typoTopic);
    }
  }
}
