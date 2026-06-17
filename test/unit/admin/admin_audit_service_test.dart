import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_audit_service.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockFirestore = MockFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(
      () => mockFirestore.collection('admin_audit_logs'),
    ).thenReturn(mockCollection);
    when(() => mockCollection.add(any())).thenAnswer((_) async => mockDocument);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.email).thenReturn('admin@test.com');
  });

  group('AdminAuditService', () {
    // Note: AdminAuditService uses static instances and DateTime.now()
    // It's hard to test purely without refactoring to inject dependencies.
    // We'll skip deep functional testing here for the same reason as other static services
    // but document the intent.

    test(
      'logAction should attempt to add data to Firestore with Timestamps',
      () async {
        when(
          () => mockCollection.add(any()),
        ).thenAnswer((_) async => mockDocument);

        await AdminAuditService.logAction(
          action: 'TEST_ACTION',
          details: {'key': 'value'},
          auth: mockAuth,
          firestore: mockFirestore,
        );

        final captured = verify(
          () => mockCollection.add(captureAny()),
        ).captured;
        expect(captured.length, 1);

        final Map<String, dynamic> data =
            captured.first as Map<String, dynamic>;
        expect(data['admin_email'], 'admin@test.com');
        expect(data['action'], 'TEST_ACTION');
        expect(data['details'], {'key': 'value'});
        expect(data['timestamp'], isA<Timestamp>());
        expect(data['expires_at'], isA<Timestamp>());
      },
    );
  });
}
