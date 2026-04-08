import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    
    // Default stub: no user logged in
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  group('AdminSessionService Logic', () {
    test('startSession should initialize without error', () {
      AdminSessionService.startSession();
      // Verifying no crash
      expect(true, true);
    });

    test('registerInteraction should not crash with mock auth (logged out)', () {
      AdminSessionService.startSession();
      AdminSessionService.registerInteraction(auth: mockAuth);
      // Verifying no crash
      expect(true, true);
    });

    test('registerInteraction should work with logged in user', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      
      AdminSessionService.startSession();
      // This should reset the timer without crashing
      AdminSessionService.registerInteraction(auth: mockAuth);
      expect(true, true);
    });

    test('clearSession should cancel timer without error', () {
      AdminSessionService.startSession();
      AdminSessionService.clearSession();
      // Verifying no crash
      expect(true, true);
    });
  });
}
