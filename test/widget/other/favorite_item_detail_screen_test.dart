import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/models/app_config.dart';
import 'package:gajanan_maharaj_sevekari/other/favorite_item_detail_screen.dart';
import 'package:gajanan_maharaj_sevekari/providers/festival_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/font_provider.dart';
import 'package:gajanan_maharaj_sevekari/settings/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const contentAsset = 'resources/test/favorite_content.json';

  final deity = DeityConfig.fromJson(<String, dynamic>{
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

  /// Serves a bilingual content item for [contentAsset], since the screen
  /// reads its content straight from rootBundle.
  void mockContentAsset() {
    final payload = utf8.encode(
      jsonEncode({'content_en': 'English body', 'content_mr': 'मराठी मजकूर'}),
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      return key == contentAsset
          ? ByteData.sublistView(Uint8List.fromList(payload))
          : null;
    });
    addTearDown(() {
      // rootBundle caches the load future, which is tied to this test's
      // fake-async zone; evict so the next test loads afresh.
      rootBundle.evict(contentAsset);
      messenger.setMockMessageHandler('flutter/assets', null);
    });
  }

  Widget buildScreen(Locale locale) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FontProvider>(create: (_) => FontProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<FestivalProvider>(
          create: (_) => FestivalProvider(),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FavoriteItemDetailScreen(
          deity: deity,
          contentList: const [
            {
              'title_en': 'Gajanan Bavanni',
              'title_mr': 'गजानन बावनन्नी',
              'assetPath': contentAsset,
            },
          ],
          initialIndex: 0,
          playlistName: 'Favorites',
          mode: PlaybackMode.reading,
        ),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    mockContentAsset();
    await tester.pumpWidget(buildScreen(locale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('en_MR shows the Marathi title and body', (tester) async {
    await pumpScreen(tester, const Locale('en', 'MR'));

    expect(find.text('गजानन बावनन्नी'), findsWidgets);
    expect(find.text('मराठी मजकूर'), findsOneWidget);
    expect(find.text('Gajanan Bavanni'), findsNothing);
    expect(find.text('English body'), findsNothing);
  });

  testWidgets('mr shows the Marathi title and body', (tester) async {
    await pumpScreen(tester, const Locale('mr'));

    expect(find.text('गजानन बावनन्नी'), findsWidgets);
    expect(find.text('मराठी मजकूर'), findsOneWidget);
  });

  testWidgets('en shows the English title and body', (tester) async {
    await pumpScreen(tester, const Locale('en'));

    expect(find.text('Gajanan Bavanni'), findsWidgets);
    expect(find.text('English body'), findsOneWidget);
    expect(find.text('गजानन बावनन्नी'), findsNothing);
  });
}
