import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TypoReportService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeFirestore = FakeFirebaseFirestore();
    service = TypoReportService(firestore: fakeFirestore);
  });

  group('TypoReport Model & TypoReportService Unit Tests', () {
    final now = DateTime(2026, 8, 7, 12, 0);

    final testReport = TypoReport(
      id: 'report_1',
      contentPath: 'resources/texts/gajanan/stotra.json',
      contentTitle: 'Stotra 1',
      contentType: 'stotra',
      deityId: 'gajanan',
      typoText: 'incorect',
      suggestedCorrection: 'incorrect',
      deviceId: 'device_abc_123',
      timestamp: now,
    );

    test('TypoReport.toFirestore converts all fields correctly', () {
      final map = testReport.toFirestore();

      expect(map['contentPath'], equals('resources/texts/gajanan/stotra.json'));
      expect(map['contentTitle'], equals('Stotra 1'));
      expect(map['contentType'], equals('stotra'));
      expect(map['deityId'], equals('gajanan'));
      expect(map['typoText'], equals('incorect'));
      expect(map['suggestedCorrection'], equals('incorrect'));
      expect(map['deviceId'], equals('device_abc_123'));
    });

    test('submitReport writes report to Firestore and getPendingReports streams it', () async {
      await service.submitReport(testReport);

      final doc = await fakeFirestore.collection('typo_reports').doc('report_1').get();
      expect(doc.exists, isTrue);

      final reportFromDoc = TypoReport.fromFirestore(doc);
      expect(reportFromDoc.id, equals('report_1'));
      expect(reportFromDoc.typoText, equals('incorect'));

      // Test stream emission
      final reportsStream = service.getPendingReports();
      final reports = await reportsStream.first;

      expect(reports.length, equals(1));
      expect(reports.first.id, equals('report_1'));
    });

    test('deleteReport removes document from Firestore', () async {
      await service.submitReport(testReport);

      await service.deleteReport('report_1');

      final doc = await fakeFirestore.collection('typo_reports').doc('report_1').get();
      expect(doc.exists, isFalse);
    });

    test('areNotificationsEnabled gets preferences default and updated value', () async {
      expect(await TypoReportService.areNotificationsEnabled(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TypoReportService.typoNotifPrefKey, true);

      expect(await TypoReportService.areNotificationsEnabled(), isTrue);
    });
  });
}
