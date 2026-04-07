import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('loadTheme should load default values when no prefs exist', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      
      await provider.loadTheme();
      
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.themePreset, ThemePreset.saffron);
    });

    test('loadTheme should load saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.index,
        'theme_preset': ThemePreset.maroon.index,
      });
      final provider = ThemeProvider();
      
      await provider.loadTheme();
      
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.themePreset, ThemePreset.maroon);
    });

    test('setTheme should update state and save to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      
      await provider.setTheme(ThemeMode.dark);
      
      expect(provider.themeMode, ThemeMode.dark);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);
    });

    test('setCustomColor should update preset to custom', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      const testColor = Colors.teal;
      
      await provider.setCustomColor(testColor);
      
      expect(provider.themePreset, ThemePreset.custom);
      expect(provider.customColor, testColor);
    });

    test('saveCurrentCustomColor should persist the color', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();
      const testColor = Colors.purple;
      
      await provider.setCustomColor(testColor);
      final saved = await provider.saveCurrentCustomColor();
      
      expect(saved, true);
      expect(provider.savedCustomColors, contains(testColor));
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('saved_custom_themes'), contains(testColor.value.toString()));
    });
  });
}
