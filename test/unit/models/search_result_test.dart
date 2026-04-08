import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/search_result.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';

void main() {
  group('SearchResult', () {
    test('SearchResult should initialize correct fields', () {
      final deity = DeityConfig(
        id: 'd1', nameEn: 'D1', nameMr: 'डी१', imagePath: '', configFile: '', aboutFile: '', aboutTitleKey: '',
        nityopasana: NityopasanaConfig(order: []), socialMediaLinks: [],
      );
      final result = SearchResult(
        deity: deity,
        contentType: ContentType.aarti,
        titleEn: 'Aarti Title En',
        titleMr: 'आरती मराठी',
        imagePath: 'path/to/img',
        textResourcePath: 'path/to/text',
        youtubeVideoId: 'video123',
      );

      expect(result.deity.id, 'd1');
      expect(result.contentType, ContentType.aarti);
      expect(result.titleEn, 'Aarti Title En');
      expect(result.titleMr, 'आरती मराठी');
    });
  });
}
