import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/providers/typo_report_service.dart';
import 'package:gajanan_maharaj_sevekari/models/typo_report.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();

    when(() => mockFirestore.collection('typo_reports')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('TypoReportService', () {
    test('submitReport should set data in firestore', () async {
      final service = TypoReportService(firestore: mockFirestore);
      final report = TypoReport(
        id: 'r123',
        contentPath: 'path',
        contentTitle: 'Title',
        contentType: 'aarti',
        deityId: 'd1',
        typoText: 'error',
        suggestedCorrection: 'fix',
        deviceId: 'device1',
        timestamp: DateTime.now(),
      );

      when(() => mockDocument.set(any())).thenAnswer((_) async => {});

      await service.submitReport(report);

      verify(() => mockFirestore.collection('typo_reports')).called(1);
      verify(() => mockCollection.doc('r123')).called(1);
      verify(() => mockDocument.set(any())).called(1);
    });

    test('deleteReport should call delete in firestore', () async {
      final service = TypoReportService(firestore: mockFirestore);
      when(() => mockDocument.delete()).thenAnswer((_) async => {});

      await service.deleteReport('r123');

      verify(() => mockDocument.delete()).called(1);
    });
  });
}
