import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';

/// Tests for the Minglish (en_MR) selective ARB migration.
///
/// Verifies that:
/// - Religious/spiritual content titles are overridden to Marathi in en_MR.
/// - UI chrome strings (settings, theme, etc.) remain in English for en_MR.
/// - All overrides are still correct for the pure Marathi (mr) locale.
void main() {
  group('AppLocalizationsEnMr selective ARB overrides', () {
    late AppLocalizations enMr;
    late AppLocalizations en;
    late AppLocalizations mr;

    setUpAll(() async {
      enMr = await AppLocalizations.delegate.load(const Locale('en', 'MR'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
      mr = await AppLocalizations.delegate.load(const Locale('mr'));
    });

    group('Religious content titles — Marathi in en_MR', () {
      test('granthTitle is Marathi in en_MR', () {
        expect(enMr.granthTitle, 'गजानन विजय ग्रंथ');
        expect(enMr.granthTitle, isNot(en.granthTitle));
        expect(enMr.granthTitle, mr.granthTitle);
      });

      test('guruCharitraTitle is Marathi in en_MR', () {
        expect(enMr.guruCharitraTitle, 'श्री गुरु चरित्र');
        expect(enMr.guruCharitraTitle, isNot(en.guruCharitraTitle));
        expect(enMr.guruCharitraTitle, mr.guruCharitraTitle);
      });

      test('stotraTitle is Marathi in en_MR', () {
        expect(enMr.stotraTitle, 'स्तोत्र संग्रह');
        expect(enMr.stotraTitle, isNot(en.stotraTitle));
        expect(enMr.stotraTitle, mr.stotraTitle);
      });

      test('namavaliTitle is Marathi in en_MR', () {
        expect(enMr.namavaliTitle, 'अष्टोत्तरशत नामावली');
        expect(enMr.namavaliTitle, isNot(en.namavaliTitle));
        expect(enMr.namavaliTitle, mr.namavaliTitle);
      });

      test('aartiTitle is Marathi in en_MR', () {
        expect(enMr.aartiTitle, 'आरती संग्रह');
        expect(enMr.aartiTitle, isNot(en.aartiTitle));
        expect(enMr.aartiTitle, mr.aartiTitle);
      });

      test('bhajanTitle is Marathi in en_MR', () {
        expect(enMr.bhajanTitle, 'भजन संग्रह');
        expect(enMr.bhajanTitle, isNot(en.bhajanTitle));
        expect(enMr.bhajanTitle, mr.bhajanTitle);
      });

      test('sankalpTitle is Marathi in en_MR', () {
        expect(enMr.sankalpTitle, 'साप्ताहिक अभिषेक आणि पूजा संकल्प');
        expect(enMr.sankalpTitle, isNot(en.sankalpTitle));
        expect(enMr.sankalpTitle, mr.sankalpTitle);
      });

      test('parayanTitle is Marathi in en_MR', () {
        expect(enMr.parayanTitle, 'पारायण');
        expect(enMr.parayanTitle, isNot(en.parayanTitle));
        expect(enMr.parayanTitle, mr.parayanTitle);
      });

      test('parayanListTitle is Marathi in en_MR', () {
        expect(enMr.parayanListTitle, 'पारायण सूची');
        expect(enMr.parayanListTitle, isNot(en.parayanListTitle));
        expect(enMr.parayanListTitle, mr.parayanListTitle);
      });

      test('songTitle is Marathi in en_MR', () {
        expect(enMr.songTitle, 'गाणी');
        expect(enMr.songTitle, isNot(en.songTitle));
        expect(enMr.songTitle, mr.songTitle);
      });

      test('aboutMaharajTitle is Marathi in en_MR', () {
        expect(enMr.aboutMaharajTitle, 'महाराजांविषयी');
        expect(enMr.aboutMaharajTitle, isNot(en.aboutMaharajTitle));
        expect(enMr.aboutMaharajTitle, mr.aboutMaharajTitle);
      });

      test('aboutGanapatiTitle is Marathi in en_MR', () {
        expect(enMr.aboutGanapatiTitle, 'गणपती बाप्पाविषयी');
        expect(enMr.aboutGanapatiTitle, isNot(en.aboutGanapatiTitle));
        expect(enMr.aboutGanapatiTitle, mr.aboutGanapatiTitle);
      });

      test('aboutShriramTitle is Marathi in en_MR', () {
        expect(enMr.aboutShriramTitle, 'प्रभु श्रीरामांविषयी');
        expect(enMr.aboutShriramTitle, isNot(en.aboutShriramTitle));
        expect(enMr.aboutShriramTitle, mr.aboutShriramTitle);
      });

      test('aboutBabaTitle is Marathi in en_MR', () {
        expect(enMr.aboutBabaTitle, 'बाबांविषयी');
        expect(enMr.aboutBabaTitle, isNot(en.aboutBabaTitle));
        expect(enMr.aboutBabaTitle, mr.aboutBabaTitle);
      });

      test('aboutHanumanTitle is Marathi in en_MR', () {
        expect(enMr.aboutHanumanTitle, 'श्री हनुमानाविषयी');
        expect(enMr.aboutHanumanTitle, isNot(en.aboutHanumanTitle));
        expect(enMr.aboutHanumanTitle, mr.aboutHanumanTitle);
      });

      test('aboutDattaMaharajTitle is Marathi in en_MR', () {
        expect(enMr.aboutDattaMaharajTitle, 'श्री दत्त महाराजांविषयी');
        expect(enMr.aboutDattaMaharajTitle, isNot(en.aboutDattaMaharajTitle));
        expect(enMr.aboutDattaMaharajTitle, mr.aboutDattaMaharajTitle);
      });
    });

    group('UI chrome — English preserved in en_MR', () {
      test('settings remains English in en_MR', () {
        expect(enMr.settings, en.settings);
        expect(enMr.settings, 'Settings');
      });

      test('language remains English in en_MR', () {
        expect(enMr.language, en.language);
        expect(enMr.language, 'Language');
      });

      test('theme remains English in en_MR', () {
        expect(enMr.theme, en.theme);
        expect(enMr.theme, 'Theme');
      });

      test('disclaimer remains English in en_MR', () {
        expect(enMr.disclaimer, en.disclaimer);
        expect(enMr.disclaimer, 'Disclaimer');
      });

      test('cancel remains English in en_MR', () {
        expect(enMr.cancel, en.cancel);
        expect(enMr.cancel, 'Cancel');
      });
    });
  });
}
