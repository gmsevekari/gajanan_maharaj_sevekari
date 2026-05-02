import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/utils/update_service.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection('app_config')).thenReturn(mockCollection);
    when(() => mockCollection.doc('version')).thenReturn(mockDocument);
    when(() => mockDocument.get()).thenAnswer((_) async => mockSnapshot);
  });

  group('UpdateService', () {
    // Note: UpdateService uses Singleton and PackageInfo.fromPlatform() which is hard to mock in plain test.
    // For unit testing the logic, we should ideally refactor it or test the mapping logic specifically.
    // Since it's a singleton with internal Firestore instance, we'll focus on what's testable.
    
    test('UpdateResult properties', () {
      final result = UpdateResult(
        type: UpdateType.forced,
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        storeUrl: 'http://store',
      );
      expect(result.type, UpdateType.forced);
      expect(result.latestVersion, '2.0.0');
    });
  });
}
