import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'theme_mode';
  static const String _presetPrefKey = 'theme_preset';
  ThemeMode _themeMode = ThemeMode.light;
  ThemePreset _themePreset = ThemePreset.saffron;

  ThemeMode get themeMode => _themeMode;
  ThemePreset get themePreset => _themePreset;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey) ?? 1; // Default to light (1)
    _themeMode = ThemeMode.values[themeIndex];

    final presetIndex = prefs.getInt(_presetPrefKey) ?? 0; // Default to saffron
    if (presetIndex < ThemePreset.values.length) {
      _themePreset = ThemePreset.values[presetIndex];
    }
    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, themeMode.index);
  }

  void setPreset(ThemePreset preset) async {
    if (_themePreset == preset) return;

    _themePreset = preset;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, preset.index);
  }
}
