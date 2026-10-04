import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/utils/event_timezone.dart';
import 'package:gajanan_maharaj_sevekari/utils/group_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig & Nested Models Tests', () {
    test('AppConfig.fromJson and getDefaultCountryCode work correctly', () {
      final json = {
        'appName': {'en': 'Sevekari', 'mr': 'सेवेकरी'},
        'updateMessage': {'en': 'Update available'},
        'latestVersion': '1.2.0',
        'forceUpdate': 'true',
        'playStoreUrl': 'https://play.store',
        'appStoreUrl': 'https://app.store',
        'gajanan_maharaj_groups': [
          {
            'id': 'seattle',
            'name_en': 'Seattle Group',
            'name_mr': 'सिॲटल ग्रुप',
            'default_country_code': '+1',
          },
        ],
        'social_media_links': [
          {'platform': 'youtube', 'url': 'https://youtube.com'},
        ],
        'signup_links': {
          'regions': ['us'],
          'links': [
            {
              'platform_key': 'parayan',
              'description_key': 'Parayan Signup',
              'icon': 'link',
              'url': 'https://parayan.link',
              'color': 'orange',
            },
          ],
        },
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName['en'], equals('Sevekari'));
      expect(config.latestVersion, equals('1.2.0'));
      expect(config.forceUpdate, equals('true'));
      expect(config.gajananMaharajGroups.length, equals(1));
      expect(config.socialMediaLinks.length, equals(1));
      expect(
        config.signupInfo?.links.first.url,
        equals('https://parayan.link'),
      );

      // Test getDefaultCountryCode
      expect(config.getDefaultCountryCode('seattle'), equals('+1'));
      expect(
        config.getDefaultCountryCode('unknown'),
        equals(GroupConstants.defaultCountryCode),
      );
      expect(
        config.getDefaultCountryCode(null),
        equals(GroupConstants.defaultCountryCode),
      );
    });

    group('default timezone per group', () {
      Map<String, dynamic> groupJson({Object? timezone, bool include = true}) =>
          {
            'id': 'g',
            'name_en': 'G',
            'name_mr': 'ग',
            if (include) 'default_timezone': timezone,
          };

      AppConfig configWith(List<Map<String, dynamic>> groups) =>
          AppConfig.fromJson({
            'appName': {'en': 'S'},
            'updateMessage': {},
            'latestVersion': '1.0.0',
            'forceUpdate': 'false',
            'playStoreUrl': '',
            'appStoreUrl': '',
            'gajanan_maharaj_groups': groups,
          });

      test('GajananMaharajGroup reads default_timezone', () {
        final group = GajananMaharajGroup.fromJson(
          groupJson(timezone: EventTimezone.india),
        );
        expect(group.defaultTimezone, EventTimezone.india);
      });

      test('defaults to Pacific when default_timezone is missing', () {
        final group = GajananMaharajGroup.fromJson(groupJson(include: false));
        expect(group.defaultTimezone, EventTimezone.pacific);
      });

      test('falls back to Pacific for a zone the app does not support', () {
        expect(
          GajananMaharajGroup.fromJson(
            groupJson(timezone: 'Europe/London'),
          ).defaultTimezone,
          EventTimezone.pacific,
        );
        expect(
          GajananMaharajGroup.fromJson(groupJson(timezone: 42)).defaultTimezone,
          EventTimezone.pacific,
        );
      });

      test('the constructor defaults to Pacific', () {
        expect(
          GajananMaharajGroup(
            id: 'g',
            nameEn: 'G',
            nameMr: 'ग',
          ).defaultTimezone,
          EventTimezone.pacific,
        );
      });

      test('getDefaultTimezone finds the group, else falls back', () {
        final config = configWith([
          {...groupJson(timezone: EventTimezone.india), 'id': 'india'},
          {...groupJson(timezone: EventTimezone.pacific), 'id': 'seattle'},
        ]);

        expect(config.getDefaultTimezone('india'), EventTimezone.india);
        expect(config.getDefaultTimezone('seattle'), EventTimezone.pacific);
        expect(config.getDefaultTimezone('unknown'), EventTimezone.pacific);
        expect(config.getDefaultTimezone(null), EventTimezone.pacific);
      });

      test('the bundled app_config.json sets Seattle to Pacific and Gunjan to '
          'India', () {
        final json =
            jsonDecode(
                  File('resources/config/app_config.json').readAsStringSync(),
                )
                as Map<String, dynamic>;
        final config = AppConfig.fromJson(json);

        expect(
          config.getDefaultTimezone(GroupConstants.seattle),
          EventTimezone.pacific,
        );
        expect(
          config.getDefaultTimezone(GroupConstants.gunjan),
          EventTimezone.india,
        );
        // Every group says so explicitly rather than relying on the fallback.
        for (final group in (json['gajanan_maharaj_groups'] as List)) {
          expect(
            (group as Map)['default_timezone'],
            isIn(EventTimezone.supported),
            reason: '${group['id']}',
          );
        }
      });
    });

    test('DeityConfig.fromJson parses nested configs', () {
      final json = {
        'id': 'gajanan',
        'name_en': 'Gajanan Maharaj',
        'name_mr': 'गजानन महाराज',
        'imagePath': 'assets/images/gajanan.jpg',
        'configFile': 'gajanan.json',
        'about_file': 'about.json',
        'about_title_key': 'aboutKey',
        'nityopasana': {
          'order': ['granth', 'stotras'],
          'granth': {
            'title_key': 'granthKey',
            'contentType': 'granth',
            'regions': ['us', 'in'],
            'textResourceDirectory': 'dir',
            'imageResourceDirectory': 'imgDir',
            'files': [
              {'file': 'adhyay1.json', 'image': 'cover.jpg'},
            ],
          },
        },
        'social_media_links': [
          {'platform': 'facebook', 'url': 'https://fb.com'},
        ],
        'songs': {
          'title_key': 'songsKey',
          'contentType': 'audio',
          'regions': [],
          'textResourceDirectory': '',
          'imageResourceDirectory': '',
          'files': [],
        },
      };

      final deity = DeityConfig.fromJson(json);

      expect(deity.id, equals('gajanan'));
      expect(deity.nameEn, equals('Gajanan Maharaj'));
      expect(deity.nityopasana.order, equals(['granth', 'stotras']));
      expect(
        deity.nityopasana.granth?.files.first.file,
        equals('adhyay1.json'),
      );
      expect(deity.songs, isNotNull);
      expect(deity.socialMediaLinks.length, equals(1));
    });

    test('AboutDeity and AboutSection fromJson work', () {
      final sectionJson = {
        'title_en': 'Life',
        'title_mr': 'जीवन',
        'content_en': 'Story',
        'content_mr': 'कथा',
      };
      final section = AboutSection.fromJson(sectionJson);
      expect(section.titleEn, equals('Life'));

      final aboutJson = {
        'title_en': 'About Gajanan Maharaj',
        'title_mr': 'श्री गजानन महाराज',
        'location_en': 'Shegaon',
        'location_mr': 'शेगाव',
        'pragat_din_en': 'Magh Vadya 7',
        'pragat_din_mr': 'माघ वद्य ७',
        'chant_en': 'Jai Gajanan',
        'chant_mr': 'जय गजानन',
        'sections': [sectionJson],
        'footer_quote_en': 'Gan Gan Ganat Bote',
        'footer_quote_mr': 'गण गण गणांत बोते',
      };

      final about = AboutDeity.fromJson(aboutJson);
      expect(about.titleEn, equals('About Gajanan Maharaj'));
      expect(about.sections.length, equals(1));
    });

    test('StoryItem extracts ID automatically from YouTube URLs', () {
      final itemShort = StoryItem.fromJson({
        'url': 'https://youtube.com/shorts/abcd123',
      });
      expect(itemShort.id, equals('abcd123'));
      expect(itemShort.isShort, isTrue);

      final itemStandard = StoryItem.fromJson({
        'url': 'https://youtube.com/watch?v=efgh456',
      });
      expect(itemStandard.id, equals('efgh456'));
      expect(itemStandard.isShort, isFalse);

      final itemYoutubeBe = StoryItem.fromJson({
        'url': 'https://youtu.be/ijkl789',
      });
      expect(itemYoutubeBe.id, equals('ijkl789'));
    });
  });
}
