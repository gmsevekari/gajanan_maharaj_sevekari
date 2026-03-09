import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';

class SearchResult {
  final DeityConfig deity;
  final ContentType contentType;
  final String titleEn;
  final String titleMr;
  final String imagePath;
  final String textResourcePath;
  final String youtubeVideoId;
  final ContentContainer? contentContainer;

  SearchResult({
    required this.deity,
    required this.contentType,
    required this.titleEn,
    required this.titleMr,
    required this.imagePath,
    required this.textResourcePath,
    required this.youtubeVideoId,
    this.contentContainer,
  });
}
