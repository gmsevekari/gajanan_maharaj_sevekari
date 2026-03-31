import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localePrefKey = 'locale_code';
  Locale _locale = const Locale('mr'); // Default to Marathi

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode =
        prefs.getString(_localePrefKey) ?? 'mr'; // Default to Marathi
    _locale = Locale(localeCode);
    notifyListeners();
  }

  void setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale.languageCode);
  }
}
