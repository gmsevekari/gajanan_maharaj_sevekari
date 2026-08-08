import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gajanan_maharaj_sevekari/utils/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Gajanan Maharaj Sevekari',
      packageName: 'com.sevekari.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('UpdateService & UpdateResult Unit Tests', () {
    test('UpdateResult holds properties correctly', () {
      final forcedResult = UpdateResult(
        type: UpdateType.forced,
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        storeUrl: 'https://store.url',
      );
      expect(forcedResult.type, equals(UpdateType.forced));
      expect(forcedResult.latestVersion, equals('2.0.0'));
      expect(forcedResult.currentVersion, equals('1.0.0'));
      expect(forcedResult.storeUrl, equals('https://store.url'));

      final recommendedResult = UpdateResult(
        type: UpdateType.recommended,
        latestVersion: '1.1.0',
        currentVersion: '1.0.0',
        storeUrl: 'https://store.url',
      );
      expect(recommendedResult.type, equals(UpdateType.recommended));

      final noneResult = UpdateResult(
        type: UpdateType.none,
        latestVersion: '1.0.0',
        currentVersion: '1.0.0',
        storeUrl: '',
      );
      expect(noneResult.type, equals(UpdateType.none));
    });

    test('checkForUpdate fails gracefully on uninitialized Firebase and returns UpdateType.none', () async {
      final service = UpdateService();
      final result = await service.checkForUpdate();

      expect(result.type, equals(UpdateType.none));
      expect(result.currentVersion, equals('1.0.0'));
    });
  });
}
