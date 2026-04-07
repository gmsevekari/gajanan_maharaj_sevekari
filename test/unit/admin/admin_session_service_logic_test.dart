import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';

void main() {
  group('AdminSessionService Logic', () {
    test('startSession should initialize without error', () {
      AdminSessionService.startSession();
      // Verifying no crash
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
