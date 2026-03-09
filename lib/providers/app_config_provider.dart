import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/models/search_result.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';

class AppConfigProvider extends ChangeNotifier {
  AppConfig? _appConfig;
  AppConfig? get appConfig => _appConfig;

  Future<void> loadAppConfig() async {
    // Load the main app config file
    final String appConfigResponse = await rootBundle.loadString(
      'resources/config/app_config.json',
    );
    final appConfigData = json.decode(appConfigResponse);

    // Load the other config file
    final String otherResponse = await rootBundle.loadString(
      appConfigData['other_config'],
    );
    final otherData = json.decode(otherResponse);
    final otherConfig = OtherConfig.fromJson(otherData);

    // Load all deity configurations in parallel
    final List<Future<DeityConfig>> futureDeities =
        (appConfigData['deities'] as List).map((d) async {
          final deityConfigPath = d['configFile']; // Corrected key
          final String deityResponse = await rootBundle.loadString(
            deityConfigPath,
          );
          final deityData = json.decode(deityResponse);
          return DeityConfig.fromJson(deityData);
        }).toList();

    final loadedDeities = await Future.wait(futureDeities);

    // Create the final AppConfig object
    _appConfig = AppConfig(deities: loadedDeities, other: otherConfig);

    notifyListeners();
  }

  Future<List<SearchResult>> searchContent(
    String query,
    String localeCode,
  ) async {
    if (_appConfig == null || query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final List<SearchResult> results = [];

    // Helper function to search within a ContentContainer (NityopasanaContent or AartiCategoryConfig)
    Future<void> searchInContainer(
      DeityConfig deity,
      ContentContainer container,
      ContentType contentType,
    ) async {
      final parentTextDir = container.textResourceDirectory;
      final parentImageDir = container.imageResourceDirectory;

      for (var item in container.files) {
        final textPath =
            '${item.textResourceDirectory ?? parentTextDir}/${item.file}';
        final imagePath =
            '${item.imageResourceDirectory ?? parentImageDir}/${item.image}';

        try {
          final String response = await rootBundle.loadString(textPath);
          final data = json.decode(response);

          final titleEn = data['title_en'] as String? ?? '';
          final titleMr = data['title_mr'] as String? ?? '';
          final contentEn = data['content_en'] as String? ?? '';
          final contentMr = data['content_mr'] as String? ?? '';

          if (titleEn.toLowerCase().contains(lowerQuery) ||
              titleMr.toLowerCase().contains(lowerQuery) ||
              contentEn.toLowerCase().contains(lowerQuery) ||
              contentMr.toLowerCase().contains(lowerQuery)) {
            results.add(
              SearchResult(
                deity: deity,
                contentType: contentType,
                titleEn: titleEn,
                titleMr: titleMr,
                imagePath: imagePath,
                textResourcePath: textPath,
                youtubeVideoId: data['youtube_video_id'] as String? ?? '',
                contentContainer: container,
              ),
            );
          }
        } catch (e) {
          // Ignore files that cannot be read or parsed properly
        }
      }
    }

    for (var deity in _appConfig!.deities) {
      if (deity.nityopasana.granth != null) {
        await searchInContainer(
          deity,
          deity.nityopasana.granth!,
          ContentType.granth,
        );
      }
      if (deity.nityopasana.stotras != null) {
        await searchInContainer(
          deity,
          deity.nityopasana.stotras!,
          ContentType.stotra,
        );
      }
      if (deity.nityopasana.bhajans != null) {
        await searchInContainer(
          deity,
          deity.nityopasana.bhajans!,
          ContentType.bhajan,
        );
      }
      if (deity.nityopasana.aartis != null) {
        if (deity.nityopasana.aartis is AartiContent) {
          for (var category
              in (deity.nityopasana.aartis as AartiContent).categories) {
            await searchInContainer(deity, category, ContentType.aarti);
          }
        } else if (deity.nityopasana.aartis is NityopasanaContent) {
          await searchInContainer(
            deity,
            deity.nityopasana.aartis as NityopasanaContent,
            ContentType.aarti,
          );
        }
      }
      if (deity.nityopasana.namavali != null) {
        final n = deity.nityopasana.namavali!;
        final textPath = '${n.textResourceDirectory}/${n.file}';
        final imagePath = '${n.imageResourceDirectory}/${n.image}';
        try {
          final String response = await rootBundle.loadString(textPath);
          final data = json.decode(response);
          final titleEn = data['title_en'] as String? ?? '';
          final titleMr = data['title_mr'] as String? ?? '';
          final contentEn = data['content_en'] as String? ?? '';
          final contentMr = data['content_mr'] as String? ?? '';

          if (titleEn.toLowerCase().contains(lowerQuery) ||
              titleMr.toLowerCase().contains(lowerQuery) ||
              contentEn.toLowerCase().contains(lowerQuery) ||
              contentMr.toLowerCase().contains(lowerQuery)) {
            results.add(
              SearchResult(
                deity: deity,
                contentType: ContentType.namavali,
                titleEn: titleEn,
                titleMr: titleMr,
                imagePath: imagePath,
                textResourcePath: textPath,
                youtubeVideoId: data['youtube_video_id'] as String? ?? '',
              ),
            );
          }
        } catch (e) {
          // ignore
        }
      }
    }

    // Search in Other section
    if (_appConfig!.deities.isNotEmpty) {
      final defaultDeity = _appConfig!.deities.first;
      final otherConfig = _appConfig!.other;

      final otherMap = {
        'sunday_prarthana': otherConfig.sundayPrarthana,
        'other_aartis': otherConfig.otherAartis,
        'other_stotras': otherConfig.otherStotras,
      };

      for (var key in otherConfig.order) {
        final content = otherMap[key];
        if (content != null) {
          await searchInContainer(
            defaultDeity,
            content,
            ContentTypeExtension.fromString(content.contentType),
          );
        }
      }
    }

    return results;
  }
}
