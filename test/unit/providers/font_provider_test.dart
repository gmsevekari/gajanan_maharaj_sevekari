import 'package:flutter/material.dart';
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

    test(
      'setFont should update English font and save to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = FontProvider();

        await provider.setFont('Lato', 'en');

        expect(provider.englishFontFamily, 'Lato');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('englishFontFamily'), 'Lato');
      },
    );

    test('setFont should not update invalid font family', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FontProvider();

      await provider.setFont('InvalidFont', 'en');
      await provider.setFont('InvalidFont', 'mr');

      expect(provider.englishFontFamily, 'Roboto');
      expect(provider.marathiFontFamily, 'Noto Sans Devanagari');
    });

    test('marathiTextStyle and englishTextStyle return GoogleFonts styles', () {
      SharedPreferences.setMockInitialValues({});
      final provider = FontProvider();

      expect(
        provider.marathiTextStyle.fontFamily,
        contains('NotoSansDevanagari'),
      );
      expect(provider.englishTextStyle.fontFamily, contains('Roboto'));
    });

    test('getTextTheme applies font family to all TextTheme styles', () {
      const baseTheme = TextTheme(
        displayLarge: TextStyle(fontSize: 57),
        bodyMedium: TextStyle(fontSize: 14),
      );

      final themed = FontProvider.getTextTheme('Roboto', baseTheme);

      expect(themed.displayLarge?.fontSize, 57);
      expect(themed.displayLarge?.fontFamily, contains('Roboto'));
      expect(themed.bodyMedium?.fontSize, 14);
      expect(themed.bodyMedium?.fontFamily, contains('Roboto'));
      expect(themed.labelSmall?.fontFamily, contains('Roboto'));
    });

    test('getTextTheme falls back to light TextTheme when base is null', () {
      final themed = FontProvider.getTextTheme('Lato');

      expect(themed.bodyLarge?.fontFamily, contains('Lato'));
      expect(themed.titleMedium?.fontFamily, contains('Lato'));
    });
  });
}
