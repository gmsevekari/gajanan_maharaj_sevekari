import 'package:flutter/material.dart';

extension LocaleContent on Locale {
  /// True only for the Marathi app language. The Minglish locale (en_MR)
  /// keeps English UI and content everywhere except the content detail
  /// screen - see [useMarathiDetailContent].
  bool get useMarathiContent => languageCode == 'mr';

  /// True when the content detail screen should show Marathi text: the
  /// Marathi language and Minglish (en_MR).
  bool get useMarathiDetailContent =>
      useMarathiContent || (languageCode == 'en' && countryCode == 'MR');

  /// Returns [mr] when this locale requires Marathi content and [mr] is
  /// non-empty, otherwise returns [en] (safe English fallback).
  String localizedContent(String en, String mr) =>
      (useMarathiContent && mr.isNotEmpty) ? mr : en;

  /// Like [localizedContent], but also returns [mr] for Minglish (en_MR).
  /// Used only by the content detail screen.
  String localizedDetailContent(String en, String mr) =>
      (useMarathiDetailContent && mr.isNotEmpty) ? mr : en;
}
