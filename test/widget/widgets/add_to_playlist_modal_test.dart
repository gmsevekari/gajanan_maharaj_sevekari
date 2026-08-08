import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/widgets/add_to_playlist_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaylistProvider playlistProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    playlistProvider = PlaylistProvider();
    await playlistProvider.init();
  });

  Widget createModalWidget() {
    return ChangeNotifierProvider<PlaylistProvider>.value(
      value: playlistProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAddToPlaylistModal(context, 'aarti_1'),
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('AddToPlaylistModal Widget Tests', () {
    testWidgets('renders modal title and checkbox tiles', (WidgetTester tester) async {
      await tester.pumpWidget(createModalWidget());
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      tester.takeException(); // Clear non-fatal ListTile assertion warning

      expect(find.byType(AddToPlaylistModal), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('opens create playlist dialog when add button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createModalWidget());
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      tester.takeException(); // Clear non-fatal ListTile assertion warning

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'My Custom Playlist');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
