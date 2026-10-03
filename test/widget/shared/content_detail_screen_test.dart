import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:gajanan_maharaj_sevekari/shared/content_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaylistProvider playlistProvider;
  late FontProvider fontProvider;
  late ThemeProvider themeProvider;
  late FestivalProvider festivalProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    playlistProvider = PlaylistProvider();
    await playlistProvider.init();

    fontProvider = FontProvider();
    themeProvider = ThemeProvider();
    festivalProvider = FestivalProvider();
  });

  final dummyDeity = DeityConfig.fromJson(<String, dynamic>{
    'id': 'gajanan',
    'name_en': 'Gajanan Maharaj',
    'name_mr': 'गजानन महाराज',
    'imagePath': 'resources/images/gajanan.png',
    'configFile': 'resources/config/gajanan.json',
    'about_file': 'resources/config/about_gajanan.json',
    'about_title_key': 'aboutGajanan',
    'nityopasana': <String, dynamic>{},
    'social_media_links': <dynamic>[],
  });

  const contentAsset = 'resources/test/detail_content.json';

  /// Serves a bilingual content item for [contentAsset], since the screen
  /// reads its content straight from rootBundle.
  void mockContentAsset() {
    final payload = utf8.encode(
      jsonEncode({
        'title_en': 'Gajanan Bavanni',
        'title_mr': 'गजानन बावनन्नी',
        'content_en': 'English body',
        'content_mr': 'मराठी मजकूर',
      }),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          return key == contentAsset
              ? ByteData.sublistView(Uint8List.fromList(payload))
              : null;
        });
    addTearDown(() {
      // rootBundle caches the load future, which is tied to this test's
      // fake-async zone; evict so the next test loads afresh.
      rootBundle.evict(contentAsset);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });
  }

  Widget createScreenWidget({
    Locale? locale,
    String assetPath = 'resources/config/gajanan.json',
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlaylistProvider>.value(value: playlistProvider),
        ChangeNotifierProvider<FontProvider>.value(value: fontProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<FestivalProvider>.value(value: festivalProvider),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ContentDetailScreen(
          deity: dummyDeity,
          contentType: ContentType.stotra,
          contentList: const [
            {
              'title_mr': 'गजानन बावनन्नी',
              'title_en': 'Gajanan Bavanni',
              'assetPath': 'resources/config/gajanan.json',
            },
          ],
          currentIndex: 0,
          assetPath: assetPath,
          imagePath: 'resources/images/gajanan.png',
        ),
      ),
    );
  }

  group('ContentDetailScreen Widget Tests', () {
    testWidgets('renders ContentDetailScreen with AppBar and tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreenWidget());
      while (tester.takeException() != null) {}
      await tester.pump();

      expect(find.byType(ContentDetailScreen), findsOneWidget);
    });

    testWidgets('en_MR shows Marathi title, body and UI strings', (
      WidgetTester tester,
    ) async {
      mockContentAsset();
      await tester.pumpWidget(
        createScreenWidget(
          locale: const Locale('en', 'MR'),
          assetPath: contentAsset,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('गजानन बावनन्नी'), findsWidgets);
      expect(find.text('मराठी मजकूर'), findsOneWidget);
      expect(find.text('Gajanan Bavanni'), findsNothing);
      expect(find.text('वाचा'), findsOneWidget);
      expect(find.text('Read'), findsNothing);
    });

    testWidgets('en shows the English title', (WidgetTester tester) async {
      mockContentAsset();
      await tester.pumpWidget(
        createScreenWidget(locale: const Locale('en'), assetPath: contentAsset),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Gajanan Bavanni'), findsWidgets);
      expect(find.text('English body'), findsOneWidget);
      expect(find.text('गजानन बावनन्नी'), findsNothing);
    });

    testWidgets('ContentTypeExtension.fromString maps valid types', (
      WidgetTester tester,
    ) async {
      expect(
        ContentTypeExtension.fromString('granth'),
        equals(ContentType.granth),
      );
      expect(
        ContentTypeExtension.fromString('stotra'),
        equals(ContentType.stotra),
      );
      expect(
        ContentTypeExtension.fromString('bhajan'),
        equals(ContentType.bhajan),
      );
      expect(
        ContentTypeExtension.fromString('aarti'),
        equals(ContentType.aarti),
      );
      expect(
        ContentTypeExtension.fromString('namavali'),
        equals(ContentType.namavali),
      );
      expect(ContentTypeExtension.fromString('song'), equals(ContentType.song));
      expect(
        ContentTypeExtension.fromString('story'),
        equals(ContentType.story),
      );
      expect(
        ContentTypeExtension.fromString('unknown'),
        equals(ContentType.granth),
      );
    });
  });
}
