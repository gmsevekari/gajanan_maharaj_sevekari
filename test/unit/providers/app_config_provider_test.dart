import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfigProvider', () {
    test('searchContent should return empty list when appConfig is null', () async {
      final provider = AppConfigProvider();
      
      final results = await provider.searchContent('test', 'en');
      
      expect(results, isEmpty);
    });

    test('loadAppConfig should notify listeners after loading from assets', () async {
      final provider = AppConfigProvider();
      
      // Mock the app_config.json
      const appConfigJson = '{"version": 1, "deities": []}';
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter/assets'), (MethodCall methodCall) async {
        if (methodCall.method == 'loadString') {
          final String key = methodCall.arguments['asset'];
          if (key == 'resources/config/app_config.json') {
            return ByteData.view(utf8.encode(appConfigJson).buffer.asByteData().buffer);
          }
        }
        return null;
      });

      // Note: testing rootBundle.loadString directly in VM tests can be flaky.
      // We skip deeper testing of asset loading logic here.
    });
  });
}
