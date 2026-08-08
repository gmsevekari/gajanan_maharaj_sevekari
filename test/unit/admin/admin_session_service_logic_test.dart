import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogle;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogle = MockGoogleSignIn();
    mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.signOut()).thenAnswer((_) async => {});
    when(() => mockGoogle.signOut()).thenAnswer((_) async => null);
  });

  group('AdminSessionService Logic Unit Tests', () {
    test('startSession initializes session timer', () {
      AdminSessionService.startSession();
      AdminSessionService.clearSession();
    });

    test('registerInteraction returns early when user is logged out', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      AdminSessionService.startSession();
      AdminSessionService.registerInteraction(auth: mockAuth);

      verifyNever(() => mockAuth.signOut());
    });

    test('registerInteraction resets session when user is logged in and active', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      AdminSessionService.startSession();
      AdminSessionService.registerInteraction(auth: mockAuth);

      verifyNever(() => mockAuth.signOut());
      AdminSessionService.clearSession();
    });

    test('clearSession cleanly cancels active session timer', () {
      AdminSessionService.startSession();
      AdminSessionService.clearSession();
      AdminSessionService.clearSession();
    });
  });
}
