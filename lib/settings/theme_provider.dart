import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/app_theme.dart';
import 'package:gajanan_maharaj_sevekari/models/festival.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'theme_mode';
  static const String _presetPrefKey = 'theme_preset';
  static const String _customColorPrefKey = 'custom_theme_color';
  static const String _savedThemesPrefKey = 'saved_custom_themes';
  static const String _lastFestivalIdKey = 'last_festival_id';
  ThemeMode _themeMode = ThemeMode.light;
  ThemePreset _themePreset = ThemePreset.saffron;
  Color? _customColor;
  List<Color> _savedCustomColors = [];
  String? _lastFestivalId;

  ThemeMode get themeMode => _themeMode;
  ThemePreset get themePreset => _themePreset;
  Color? get customColor => _customColor;
  List<Color> get savedCustomColors => _savedCustomColors;

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

    final savedThemesValues = prefs.getStringList(_savedThemesPrefKey) ?? [];
    _savedCustomColors =
        savedThemesValues.map((v) => Color(int.parse(v))).toList();
    _lastFestivalId = prefs.getString(_lastFestivalIdKey);

    notifyListeners();
  }

  /// Automatically applies the festival theme if it hasn't been applied yet
  /// for this specific festival in a previous session.
  Future<void> checkAndApplyFestivalTheme(Festival? activeFestival) async {
    final prefs = await SharedPreferences.getInstance();

    if (activeFestival != null) {
      // If this is a new festival we haven't auto-applied yet
      if (_lastFestivalId != activeFestival.id) {
        _lastFestivalId = activeFestival.id;
        await prefs.setString(_lastFestivalIdKey, _lastFestivalId!);
        
        // Auto-apply the theme preset
        setPreset(activeFestival.themePreset);
      }
    } else {
      // If no festival is active, but we are still on a festival-only theme,
      // revert to default (Saffron).
      if (_themePreset == ThemePreset.diwali || _themePreset == ThemePreset.ganeshChaturthi) {
        setPreset(ThemePreset.saffron);
      }
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, themeMode.index);
  }

  Future<void> setPreset(ThemePreset preset) async {
    if (_themePreset == preset && preset != ThemePreset.custom) return;

    _themePreset = preset;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, preset.index);
  }

  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    _themePreset = ThemePreset.custom;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, ThemePreset.custom.index);
    await prefs.setInt(_customColorPrefKey, color.value);
  }

  Future<bool> saveCurrentCustomColor() async {
    if (_customColor == null) return false;

    // Avoid exact duplicates
    if (_savedCustomColors.any((c) => c.value == _customColor!.value)) {
      return false;
    }

    _savedCustomColors.add(_customColor!);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedThemesPrefKey,
      _savedCustomColors.map((c) => c.value.toString()).toList(),
    );
    return true;
  }

  Future<void> deleteSavedColor(Color color) async {
    _savedCustomColors.removeWhere((c) => c.value == color.value);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedThemesPrefKey,
      _savedCustomColors.map((c) => c.value.toString()).toList(),
    );
  }

  Future<void> applySavedColor(Color color) async {
    _customColor = color;
    _themePreset = ThemePreset.custom;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_presetPrefKey, ThemePreset.custom.index);
    await prefs.setInt(_customColorPrefKey, color.value);
  }
}
