import 'package:flutter/material.dart';

extension LocaleContent on Locale {
  bool get useMarathiContent =>
      languageCode == 'mr' || (languageCode == 'en' && countryCode == 'MR');

  /// Returns [mr] when this locale requires Marathi content and [mr] is
  /// non-empty, otherwise returns [en] (safe English fallback).
  String localizedContent(String en, String mr) =>
      (useMarathiContent && mr.isNotEmpty) ? mr : en;
}
