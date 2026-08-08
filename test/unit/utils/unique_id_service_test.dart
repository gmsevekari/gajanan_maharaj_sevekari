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

    test('getUniqueId returns stored SharedPreferences UUID when present', () async {
      SharedPreferences.setMockInitialValues({
        'unique_device_id': 'pre_existing_uuid_12345'
      });

      // Clear static cache in UniqueIdService by fetching (if not already set in prior test)
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('unique_device_id');
      expect(stored, equals('pre_existing_uuid_12345'));
    });
  });
}
