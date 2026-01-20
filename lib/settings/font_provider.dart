import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  String _defaultMarathiFontFamily = 'Noto Sans Devanagari';
  String _defaultEnglishFontFamily = 'Roboto';

  String get marathiFontFamily => _defaultMarathiFontFamily;
  String get englishFontFamily => _defaultEnglishFontFamily;

  TextStyle get marathiTextStyle => GoogleFonts.getFont(_defaultMarathiFontFamily);
  TextStyle get englishTextStyle => GoogleFonts.getFont(_defaultEnglishFontFamily);

  final Map<String, String> availableMarathiFonts = {
    'Noto Sans Devanagari': 'नोटो सान्स देवनागरी - जय गजानन',
    'Hind': 'हिंद - जय गजानन',
    'Kalam': 'कलम - जय गजानन',
    'Yantramanav': 'यंत्रमानव - जय गजानन',
    'Laila': 'लैला - जय गजानन',
    'Martel': 'मार्टेल - जय गजानन',
    'Khand': 'खंड - जय गजानन',
    'Amita': 'अमिता - जय गजानन',
    'Akshar': 'अक्षर - जय गजानन',
    'Rozha One': 'रोझा वन - जय गजानन',
    'Amiko': 'अमिको - जय गजानन',
    'Gotu': 'गोटू - जय गजानन',
    'Sarpanch': 'सरपंच - जय गजानन',
    'Sumana': 'सुमाना - जय गजानन',
    'Tillana': 'तिल्लाना - जय गजानन',
    'Ranga': 'रंगा - जय गजानन',
    'Jaini': 'जैनी - जय गजानन',
    'Teko': 'टेको - जय गजानन',
    'Inknut Antiqua': 'इंकनट अँटीक्वा - जय गजानन'
  };

  final Map<String, String> availableEnglishFonts = {
    'Roboto': 'Roboto - Jay Gajanan',
    'Lato': 'Lato - Jay Gajanan',
    'Noto Sans Math': 'Noto Sans Math - Jay Gajanan',
    'Buda': 'Buda - Jay Gajanan',
    'Saira': 'Saira - Jay Gajanan',
    'Dancing Script': 'Dancing Script - Jay Gajanan',
    'Source Code Pro': 'Source Code Pro - Jay Gajanan',
    'Edu SA Hand': 'Edu SA Hand - Jay Gajanan',
    'Sour Gummy': 'Sour Gummy - Jay Gajanan',
    'Story Script': 'Story Script - Jay Gajanan',
    'Macondo': 'Macondo - Jay Gajanan',
    'Quintessential': 'Quintessential - Jay Gajanan'
  };

  FontProvider() {
    loadFonts();
  }

  Future<void> setFont(String newFontFamily, String languageCode) async {
    if (languageCode == 'mr') {
      if (availableMarathiFonts.containsKey(newFontFamily)) {
        _defaultMarathiFontFamily = newFontFamily;
      }
    } else {
      if (availableEnglishFonts.containsKey(newFontFamily)) {
        _defaultEnglishFontFamily = newFontFamily;
      }
    }
    await _saveFonts();
    notifyListeners();
  }

  Future<void> _saveFonts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('marathiFontFamily', _defaultMarathiFontFamily);
    prefs.setString('englishFontFamily', _defaultEnglishFontFamily);
  }

  Future<void> loadFonts() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultMarathiFontFamily = prefs.getString('marathiFontFamily') ?? _defaultMarathiFontFamily;
    _defaultEnglishFontFamily = prefs.getString('englishFontFamily') ?? _defaultEnglishFontFamily;
    notifyListeners();
  }
}
