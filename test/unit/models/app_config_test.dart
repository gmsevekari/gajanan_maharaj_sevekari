import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';

void main() {
  group('AppConfig', () {
    final mockJson = {
      'appName': {'en': 'Test App', 'mr': 'marathi app name'},
      'latestVersion': '1.0.0',
      'forceUpdate': 'true',
      'playStoreUrl': 'https://google.com',
      'appStoreUrl': 'https://apple.com',
      'updateMessage': {'en': 'Test Message', 'mr': 'marathi update msg'},
      'gajanan_maharaj_groups': [
        {'id': 'g1', 'name_en': 'Group 1', 'name_mr': 'गट १'},
        {'id': 'g2', 'name_en': 'Group 2', 'name_mr': 'गट २', 'default_country_code': '+91'}
      ],
      'social_media_links': [
        {'platform': 'Facebook', 'url': 'fb.com', 'icon': 'fbIcon', 'color': 'blue'}
      ],
      'signup_links': {
        'regions': ['us', 'in'],
        'links': [
          {
            'platform_key': 'whatsapp',
            'description_key': 'join_group',
            'url': 'wa.me',
            'icon': 'waIcon',
            'color': 'green'
          }
        ]
      }
    };

    test('fromJson should correctly parse the main config', () {
      final config = AppConfig.fromJson(mockJson);

      expect(config.appName['en'], 'Test App');
      expect(config.latestVersion, '1.0.0');
      expect(config.forceUpdate, 'true');
      expect(config.gajananMaharajGroups.length, 2);
      expect(config.gajananMaharajGroups[0].id, 'g1');
      expect(config.socialMediaLinks.length, 1);
      expect(config.socialMediaLinks[0].platform, 'Facebook');
      expect(config.signupInfo?.regions, ['us', 'in']);
      expect(config.signupInfo?.links.first.platformKey, 'whatsapp');
    });

    test('GajananMaharajGroup fromJson', () {
      final group = GajananMaharajGroup.fromJson({'id': 'test', 'name_en': 'Test', 'name_mr': 'टेस्ट'});
      expect(group.id, 'test');
      expect(group.nameEn, 'Test');
    });

    test('SocialMediaLink fromJson', () {
      final link = SocialMediaLink.fromJson({
        'platform': 'Twitter',
        'url': 'tw.com',
        'icon': 'twIcon',
        'color': 'cyan'
      });
      expect(link.platform, 'Twitter');
      expect(link.color, 'cyan');
    });

    test('getDefaultCountryCode returns correct code or fallback', () {
      final config = AppConfig.fromJson(mockJson);
      
      // Known group (g1) - should return default fallback +1 as it's not in mockJson
      expect(config.getDefaultCountryCode('g1'), '+1');

      // Known group (g2) - should return configured code +91
      expect(config.getDefaultCountryCode('g2'), '+91');
      
      // Unknown group - should return fallback +1
      expect(config.getDefaultCountryCode('unknown'), '+1');
      
      // Null group - should return fallback +1
      expect(config.getDefaultCountryCode(null), '+1');
    });
  });
}
