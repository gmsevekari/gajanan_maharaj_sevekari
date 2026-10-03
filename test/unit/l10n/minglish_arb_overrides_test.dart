import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Tests for the Minglish (en_MR) locale.
///
/// en_MR shows English UI strings everywhere; Marathi appears only as content
/// on the content detail screen, which reads the item's own Marathi fields
/// rather than ARB strings.
void main() {
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

    group('content titles stay English', () {
      test('granthTitle', () {
        expect(enMr.granthTitle, en.granthTitle);
        expect(enMr.granthTitle, isNot(mr.granthTitle));
      });

      test('aartiTitle', () {
        expect(enMr.aartiTitle, en.aartiTitle);
        expect(enMr.aartiTitle, isNot(mr.aartiTitle));
      });

      test('parayanTitle', () {
        expect(enMr.parayanTitle, en.parayanTitle);
        expect(enMr.parayanTitle, isNot(mr.parayanTitle));
      });

      test('aboutMaharajTitle', () {
        expect(enMr.aboutMaharajTitle, en.aboutMaharajTitle);
        expect(enMr.aboutMaharajTitle, isNot(mr.aboutMaharajTitle));
      });
    });

    group('UI chrome stays English', () {
      test('appName', () {
        expect(enMr.appName, en.appName);
      });

      test('searchHint', () {
        expect(enMr.searchHint, en.searchHint);
      });

      test('settings', () {
        expect(enMr.settings, 'Settings');
      });

      test('language', () {
        expect(enMr.language, 'Language');
      });

      test('cancel', () {
        expect(enMr.cancel, 'Cancel');
      });
    });
  });
}
