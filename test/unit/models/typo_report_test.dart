import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';

void main() {
  group('TypoReport', () {
    final timestamp = DateTime(2024, 6, 1);

    test('toFirestore should correctly serialize the report', () {
      final report = TypoReport(
        id: 'report_1',
        contentPath: 'path/to/content',
        contentTitle: 'Content Title',
        contentType: 'aarti',
        deityId: 'd1',
        typoText: 'misspel',
        suggestedCorrection: 'misspell',
        deviceId: 'device_abc',
        timestamp: timestamp,
      );

      final map = report.toFirestore();

      expect(map['contentPath'], 'path/to/content');
      expect(map['typoText'], 'misspel');
      expect(map['suggestedCorrection'], 'misspell');
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), timestamp);
    });

    test('Manual initialization check', () {
      final report = TypoReport(
        id: 'r2', contentPath: '', contentTitle: '', contentType: '',
        deityId: '', typoText: 'error', suggestedCorrection: 'fix',
        deviceId: '', timestamp: DateTime.now(),
      );
      expect(report.typoText, 'error');
    });
  });
}
