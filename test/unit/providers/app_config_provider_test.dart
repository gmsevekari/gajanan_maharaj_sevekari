import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/providers/app_config_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppConfigProvider provider;

  final mockAppConfigJson = {
    "deities": [
      {
        "id": "gajanan",
        "name_mr": "श्री गजानन महाराज",
        "name_en": "Gajanan Maharaj",
        "configFile": "resources/config/gajanan.json",
      },
    ],
  };

  final mockDeityJson = {
    "id": "gajanan",
    "name_mr": "श्री गजानन महाराज",
    "name_en": "Gajanan Maharaj",
    "nityopasana": {
      "stotras": {
        "textResourceDirectory": "resources/texts/gajanan/stotras",
        "files": [
          {"file": "stotra1.json", "title_en": "Stotra 1"},
        ],
      },
    },
  };

  final mockStotraContent = {
    "title_en": "Stotra 1",
    "title_mr": "स्तोत्र १",
    "content_en": "Content of Stotra 1",
    "content_mr": "स्तोत्र १ मजकूर",
  };

  setUp(() {
    provider = AppConfigProvider();

    // Set up mock binary messenger handler for rootBundle
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final String? key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'resources/config/app_config.json') {
            return ByteData.view(
              utf8.encode(json.encode(mockAppConfigJson)).buffer,
            );
          } else if (key == 'resources/config/gajanan.json') {
            return ByteData.view(
              utf8.encode(json.encode(mockDeityJson)).buffer,
            );
          } else if (key == 'resources/texts/gajanan/stotras/stotra1.json') {
            return ByteData.view(
              utf8.encode(json.encode(mockStotraContent)).buffer,
            );
          }
          return null;
        });
  });

  group('AppConfigProvider', () {
    test('loadAppConfig should load global and deity configs', () async {
      await provider.loadAppConfig();
      expect(provider.appConfig, isNotNull);
      expect(provider.appConfig!.deities.length, 1);
      expect(provider.appConfig!.deities.first.id, 'gajanan');
      expect(
        provider.appConfig!.deities.first.nityopasana.stotras!.files.length,
        1,
      );
    });

    test('searchContent should find items in stotras', () async {
      await provider.loadAppConfig();

      final results = await provider.searchContent('stotra', 'en');
      expect(results.length, 1);
      expect(results.first.titleEn, 'Stotra 1');
    });

    test('searchContent should return empty if no match', () async {
      await provider.loadAppConfig();

      final results = await provider.searchContent('nonexistent', 'en');
      expect(results.length, 0);
    });
  });
}
