import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Tests for the Minglish (en_MR) locale.
///
/// en_MR is Marathi by default, except that English words which Marathi
/// writes in Devanagari (delete, group, admin, ...) are written in Latin
/// script instead, e.g. "थीम डिलीट करा" becomes "theme delete करा".
void main() {
  Map<String, dynamic> readArb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  group('AppLocalizationsEnMr', () {
    late AppLocalizations enMr;
    late AppLocalizations en;
    late AppLocalizations mr;

    setUpAll(() async {
      enMr = await AppLocalizations.delegate.load(const Locale('en', 'MR'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
      mr = await AppLocalizations.delegate.load(const Locale('mr'));
    });

    test('keeps its own Minglish language label', () {
      expect(enMr.minglish, 'Minglish (Marathi-English)');
    });

    test('uses Marathi for words that have no English loanword', () {
      expect(enMr.granthTitle, 'गजानन विजय ग्रंथ');
      expect(enMr.granthTitle, mr.granthTitle);
      expect(enMr.aartiTitle, mr.aartiTitle);
      expect(enMr.parayanTitle, mr.parayanTitle);
      expect(enMr.aboutMaharajTitle, mr.aboutMaharajTitle);
      expect(enMr.granthTitle, isNot(en.granthTitle));
    });

    test('writes English loanwords in Latin script', () {
      expect(mr.settings, 'सेटिंग्ज');
      expect(enMr.settings, 'settings');
      expect(mr.deleteTheme, 'थीम डिलीट करा');
      expect(enMr.deleteTheme, 'theme delete करा');
    });

    test('keeps Marathi suffixes in Devanagari after the English word', () {
      expect(enMr.savedThemes, 'माझ्या themes');
    });
  });

  group('app_en_MR.arb', () {
    final enMr = readArb('app_en_MR.arb');
    final mr = readArb('app_mr.arb');
    String stringOf(Map<String, dynamic> arb, String key) => arb[key] as String;

    test('translates every key that the Marathi file does', () {
      final mrKeys = mr.keys.where((k) => !k.startsWith('@'));
      final missing = mrKeys.where((k) => !enMr.containsKey(k)).toList();
      expect(missing, isEmpty);
    });

    test('has no English loanword left in Devanagari', () {
      const loanwords = [
        'ग्रुप',
        'डिलीट',
        'ॲडमिन',
        'अपडेट',
        'स्टेटस',
        'स्लॉट',
        'नोटिफिकेशन',
        'इमेज',
        'थीम',
        'लिस्ट',
        'सेव्ह',
        'ईमेल',
        'कॉपी',
        'शेअर',
        'सबमिट',
        'क्लेम',
        'रिपोर्ट',
        'इव्हेंट',
        'सेटिंग्ज',
        'साइन अप',
        'साईन-अप',
        'डॅशबोर्ड',
      ];
      final offenders = <String>[];
      enMr.forEach((key, value) {
        if (key.startsWith('@') || key == '@@locale' || value is! String) {
          return;
        }
        for (final word in loanwords) {
          if (value.contains(word)) offenders.add('$key: $word');
        }
      });
      expect(offenders, isEmpty);
    });

    test('keeps ICU placeholders intact', () {
      for (final key in ['eventOnDate']) {
        if (!mr.containsKey(key)) continue;
        final placeholders = RegExp(r'\{(\w+)').allMatches(stringOf(mr, key));
        for (final match in placeholders) {
          expect(stringOf(enMr, key), contains('{${match.group(1)}'));
        }
      }
    });
  });
}
