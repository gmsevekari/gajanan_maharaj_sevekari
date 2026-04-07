import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FontProvider', () {
    test('loadFonts should load default values when no prefs exist', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FontProvider();
      
      await provider.loadFonts();
      
      expect(provider.marathiFontFamily, 'Noto Sans Devanagari');
      expect(provider.englishFontFamily, 'Roboto');
    });

    test('loadFonts should load saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'marathiFontFamily': 'Mukta',
        'englishFontFamily': 'Lato',
      });
      final provider = FontProvider();
      
      await provider.loadFonts();
      
      expect(provider.marathiFontFamily, 'Mukta');
      expect(provider.englishFontFamily, 'Lato');
    });

    test('setFont should update state and save to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FontProvider();
      
      await provider.setFont('Gotu', 'mr');
      
      expect(provider.marathiFontFamily, 'Gotu');
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('marathiFontFamily'), 'Gotu');
    });

    test('setFont should not update invalid font family', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FontProvider();
      
      await provider.setFont('InvalidFont', 'en');
      
      expect(provider.englishFontFamily, 'Roboto');
    });
  });
}
