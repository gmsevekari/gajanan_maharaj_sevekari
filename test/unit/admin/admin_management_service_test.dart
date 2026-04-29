import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_management_service.dart';
import 'package:gajanan_maharaj_sevekari/models/admin_user.dart';
import '../../mocks.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQueryDocumentSnapshot mockDocSnapshot;
  late AdminManagementService service;

  setUp(() {
    mockFirestore = MockFirestore();
    mockAuth = MockFirebaseAuth();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocSnapshot = MockQueryDocumentSnapshot();

    service = AdminManagementService(firestore: mockFirestore, auth: mockAuth);

    when(
      () => mockFirestore.collection('admin_allowlist'),
    ).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDoc);
    when(
      () => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo')),
    ).thenReturn(mockCollection);
    when(
      () => mockCollection.snapshots(),
    ).thenAnswer((_) => Stream.value(mockQuerySnapshot));
  });

  group('AdminManagementService Tests', () {
    test('isAdminExists returns true if document exists', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);

      final exists = await service.isAdminExists('test@test.com');

      expect(exists, isTrue);
      verify(() => mockCollection.doc('test@test.com')).called(1);
      verify(() => mockDoc.get()).called(1);
    });

    test('isAdminExists returns false if document does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);

      final exists = await service.isAdminExists('unknown@test.com');

      expect(exists, isFalse);
    });

    test('getAllAdmins returns list of admins', () async {
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.id).thenReturn('admin@test.com');
      when(() => mockDocSnapshot.data()).thenReturn({
        'roles': ['super_admin'],
        'groupId': 'g1',
      });

      final result = await service.getAllAdmins().first;

      expect(result.length, 1);
      expect(result.first.email, 'admin@test.com');
      expect(result.first.groupId, 'g1');
    });

    test('getAdminsForGroup filters by groupId', () async {
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
      when(() => mockDocSnapshot.id).thenReturn('group_admin@test.com');
      when(() => mockDocSnapshot.data()).thenReturn({
        'roles': ['group_admin'],
        'groupId': 'g1',
      });

      final result = await service.getAdminsForGroup('g1').first;

      verify(() => mockCollection.where('groupId', isEqualTo: 'g1')).called(1);
      expect(result.length, 1);
    });

    test('deleteAdmin deletes doc and logs action', () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('super@test.com');
      when(() => mockDoc.delete()).thenAnswer((_) async => {});

      // For logging
      final mockAuditCollection = MockCollectionReference();
      when(
        () => mockFirestore.collection('admin_audit_logs'),
      ).thenReturn(mockAuditCollection);
      when(
        () => mockAuditCollection.add(any()),
      ).thenAnswer((_) async => mockDoc);

      await service.deleteAdmin('target@test.com');

      verify(() => mockCollection.doc('target@test.com')).called(1);
      verify(() => mockDoc.delete()).called(1);
      verify(() => mockFirestore.collection('admin_audit_logs')).called(1);
    });

    test('saveAdmin sets doc and logs action', () async {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('super@test.com');

      final admin = AdminUser(
        email: 'new@test.com',
        roles: ['group_admin'],
        groupId: 'g1',
      );

      when(() => mockDoc.set(any())).thenAnswer((_) async => {});

      final mockAuditCollection = MockCollectionReference();
      when(
        () => mockFirestore.collection('admin_audit_logs'),
      ).thenReturn(mockAuditCollection);
      when(
        () => mockAuditCollection.add(any()),
      ).thenAnswer((_) async => mockDoc);

      await service.saveAdmin(admin);

      verify(() => mockCollection.doc('new@test.com')).called(1);
      verify(
        () => mockDoc.set({
          'roles': ['group_admin'],
          'groupId': 'g1',
          'typoNotificationsEnabled': false,
        }),
      ).called(1);
      verify(() => mockFirestore.collection('admin_audit_logs')).called(1);
    });
  });
}
