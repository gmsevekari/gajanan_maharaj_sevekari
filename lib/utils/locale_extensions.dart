import 'package:flutter/material.dart';

extension LocaleContent on Locale {
  bool get useMarathiContent =>
      languageCode == 'mr' || (languageCode == 'en' && countryCode == 'MR');
}
