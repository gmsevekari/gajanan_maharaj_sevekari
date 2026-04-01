import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'theme_mode';
  static const String _presetPrefKey = 'theme_preset';
  static const String _customColorPrefKey = 'custom_theme_color';
  ThemeMode _themeMode = ThemeMode.light;
  ThemePreset _themePreset = ThemePreset.saffron;
  Color? _customColor;

  ThemeMode get themeMode => _themeMode;
  ThemePreset get themePreset => _themePreset;
  Color? get customColor => _customColor;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey) ?? 1; // Default to light (1)
    _themeMode = ThemeMode.values[themeIndex];

    final presetIndex = prefs.getInt(_presetPrefKey) ?? 0; // Default to saffron
    if (presetIndex < ThemePreset.values.length) {
      _themePreset = ThemePreset.values[presetIndex];
    }

    final customColorValue = prefs.getInt(_customColorPrefKey);
    if (customColorValue != null) {
      _customColor = Color(customColorValue);
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
    if (_themePreset == preset && preset != ThemePreset.custom) return;

    _themePreset = preset;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, preset.index);
  }

  void setCustomColor(Color color) async {
    _customColor = color;
    _themePreset = ThemePreset.custom;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, ThemePreset.custom.index);
    await prefs.setInt(_customColorPrefKey, color.value);
  }
}
