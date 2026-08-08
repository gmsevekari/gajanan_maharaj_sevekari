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

    test('UpdateType enum contains expected values', () {
      expect(UpdateType.values, contains(UpdateType.none));
      expect(UpdateType.values, contains(UpdateType.recommended));
      expect(UpdateType.values, contains(UpdateType.forced));
      expect(UpdateType.values.length, equals(3));
    });

    test('checkForUpdate fails gracefully on uninitialized Firebase and returns UpdateType.none', () async {
      final service = UpdateService();
      final result = await service.checkForUpdate();

      expect(result.type, equals(UpdateType.none));
      expect(result.currentVersion, equals('1.0.0'));
    });

    test('UpdateResult storeUrl is accessible', () {
      final result = UpdateResult(
        type: UpdateType.recommended,
        latestVersion: '2.0.0',
        currentVersion: '1.5.0',
        storeUrl: 'https://apps.apple.com/app/id123456',
      );
      expect(result.storeUrl, equals('https://apps.apple.com/app/id123456'));
      expect(result.latestVersion, equals('2.0.0'));
      expect(result.currentVersion, equals('1.5.0'));
    });

    test('UpdateService factory returns singleton instance', () {
      final s1 = UpdateService();
      final s2 = UpdateService();
      expect(identical(s1, s2), isTrue);
    });

    test('UpdateResult with empty strings is valid', () {
      final result = UpdateResult(
        type: UpdateType.none,
        latestVersion: '',
        currentVersion: '',
        storeUrl: '',
      );
      expect(result.latestVersion, equals(''));
      expect(result.currentVersion, equals(''));
      expect(result.storeUrl, equals(''));
      expect(result.type, equals(UpdateType.none));
    });

    test('checkForUpdate called multiple times returns consistent type', () async {
      final service = UpdateService();
      final result1 = await service.checkForUpdate();
      final result2 = await service.checkForUpdate();
      // Both should be none since Firebase is not initialized
      expect(result1.type, equals(UpdateType.none));
      expect(result2.type, equals(UpdateType.none));
    });
  });
}
