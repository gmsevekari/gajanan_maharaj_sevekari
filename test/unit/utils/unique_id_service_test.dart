import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/utils/unique_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UniqueIdService Unit Tests', () {
    test('getUniqueId generates new UUID when no ID is stored and retrieves cached ID', () async {
      SharedPreferences.setMockInitialValues({});

      final id1 = await UniqueIdService.getUniqueId();
      expect(id1, isNotEmpty);

      // Subsequent call returns cached ID
      final id2 = await UniqueIdService.getUniqueId();
      expect(id2, equals(id1));
    });
  });
}
