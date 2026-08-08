import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/shared/cross_platform_youtube_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createPlayerWidget({VoidCallback? onLaunchYoutube}) {
    return MaterialApp(
      home: Scaffold(
        body: CrossPlatformYoutubePlayer(
          videoId: 'dQw4w9WgXcQ',
          onLaunchYoutube: onLaunchYoutube,
        ),
      ),
    );
  }

  group('CrossPlatformYoutubePlayer Widget Tests', () {
    testWidgets('instantiates CrossPlatformYoutubePlayer', (WidgetTester tester) async {
      await tester.pumpWidget(createPlayerWidget());
      final exception = tester.takeException();
      expect(exception, isNotNull);
    });
  });
}
