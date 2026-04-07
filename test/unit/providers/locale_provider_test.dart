import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/settings/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider', () {
    test('loadLocale should default to Marathi (mr)', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      
      await provider.loadLocale();
      
      expect(provider.locale.languageCode, 'mr');
    });

    test('loadLocale should load saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'locale_code': 'en'});
      final provider = LocaleProvider();
      
      await provider.loadLocale();
      
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale should update state and save to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      
      await provider.setLocale(const Locale('en'));
      
      expect(provider.locale.languageCode, 'en');
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_code'), 'en');
    });
  });
}
