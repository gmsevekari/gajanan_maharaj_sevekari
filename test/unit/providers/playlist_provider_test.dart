import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/playlist.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlaylistProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = PlaylistProvider();
  });

  group('PlaylistProvider - Initialization', () {
    test(
      'init should create default "My Favorites" and prepopulate favorites.json playlists if none exists',
      () async {
        await provider.init();
        expect(provider.playlists.length, greaterThanOrEqualTo(2));
        expect(provider.playlists.first.name_en, 'My Favorites');
        expect(provider.playlists.first.isDefault, true);
        expect(provider.playlists[1].name_en, 'Sunday Prarthana');
        expect(provider.playlists[1].isDefault, false);
        expect(provider.defaultPlaylist, isNotNull);
      },
    );

    test(
      'init should load existing playlists from SharedPreferences and merge favorites.json except deleted ones',
      () async {
        final existingPlaylists = [
          Playlist(
            id: '1',
            name_en: 'Existing',
            name_mr: 'Existing',
            isDefault: true,
            aartiIds: ['a1'],
          ),
        ];
        SharedPreferences.setMockInitialValues({
          'user_playlists': json.encode(
            existingPlaylists.map((p) => p.toJson()).toList(),
          ),
          'deleted_default_playlist_ids': ['sunday_prarthana'],
        });

        await provider.init();
        expect(provider.playlists.length, 1);
        expect(provider.playlists.first.name_en, 'Existing');
        expect(provider.playlists.first.aartiIds, ['a1']);
        expect(
          provider.playlists.any((p) => p.name_en == 'Sunday Prarthana'),
          false,
        );
      },
    );

    test(
      'init should force-reorder and force-update existing default config playlist if it exists elsewhere or is stale',
      () async {
        final stalePlaylists = [
          Playlist(
            id: '1',
            name_en: 'My Favorites',
            name_mr: 'माझे फेव्हरेट्स',
            isDefault: true,
            aartiIds: [],
          ),
          Playlist(
            id: 'custom_1',
            name_en: 'Custom',
            name_mr: 'Custom',
            isDefault: false,
            aartiIds: [],
          ),
          Playlist(
            id: 'sunday_prarthana',
            name_en: 'OLD NAME', // Stale name
            name_mr: 'OLD NAME',
            isDefault: false,
            aartiIds: ['OLD PATH'], // Stale path
          ),
        ];

        SharedPreferences.setMockInitialValues({
          'user_playlists': json.encode(
            stalePlaylists.map((p) => p.toJson()).toList(),
          ),
        });

        await provider.init();

        // 1. Should be at index 1 now (not index 2)
        expect(provider.playlists[1].id, 'sunday_prarthana');
        // 2. Should have fresh name from config
        expect(provider.playlists[1].name_en, 'Sunday Prarthana');
        // 3. Should preserve local aartiIds (but migrate them if they matches the pattern)
        // In this test case, 'OLD PATH' doesn't match the pattern so it stays as is.
        expect(provider.playlists[1].aartiIds, contains('OLD PATH'));
        // 4. "Custom" should be pushed to index 2
        expect(provider.playlists[2].id, 'custom_1');
      },
    );
    test(
      'init should preserve user deletions in default config playlist',
      () async {
        final existingPlaylists = [
          Playlist(
            id: '1',
            name_en: 'My Favorites',
            name_mr: 'माझे फेव्हरेट्स',
            isDefault: true,
            aartiIds: [],
          ),
          Playlist(
            id: 'sunday_prarthana',
            name_en: 'Sunday Prarthana',
            name_mr: 'रविवार प्रार्थना',
            isDefault: false,
            // User has already deleted some items
            aartiIds: ['resources/texts/datta_maharaj/stotras/guru_geeta.json'],
          ),
        ];

        SharedPreferences.setMockInitialValues({
          'user_playlists': json.encode(
            existingPlaylists.map((p) => p.toJson()).toList(),
          ),
        });

        await provider.init();

        final sundayPl = provider.playlists[1];
        expect(sundayPl.id, 'sunday_prarthana');

        // 1. Should preserve the items exactly as they were (no config overwrite)
        expect(
          sundayPl.aartiIds.first,
          'resources/texts/datta_maharaj/stotras/guru_geeta.json',
        );

        // 2. Should NOT have brought back the other items from favorites.json (length should still be 1)
        expect(sundayPl.aartiIds.length, 1);
      },
    );
  });

  group('PlaylistProvider - CRUD Operations', () {
    setUp(() async {
      await provider.init();
    });

    test('createPlaylist should add new playlist', () async {
      final initialLength = provider.playlists.length;
      await provider.createPlaylist('New List');
      expect(provider.playlists.length, initialLength + 1);
      expect(provider.playlists.any((p) => p.name_en == 'New List'), true);
    });

    test('createPlaylist should throw if name is duplicate', () async {
      expect(
        () => provider.createPlaylist('My Favorites'),
        throwsA(isA<Exception>()),
      );
    });

    test('renamePlaylist should update name correctly', () async {
      await provider.createPlaylist('Old Name');
      final pl = provider.playlists.firstWhere((p) => p.name_en == 'Old Name');

      await provider.renamePlaylist(pl.id, 'New Name');
      expect(provider.playlists.any((p) => p.name_en == 'New Name'), true);
      expect(provider.playlists.any((p) => p.name_en == 'Old Name'), false);
    });

    test(
      'deletePlaylist should remove playlist, track deleted IDs, and prevent default deletion',
      () async {
        final initialLength = provider.playlists.length;
        await provider.createPlaylist('To Delete');
        final pl = provider.playlists.firstWhere(
          (p) => p.name_en == 'To Delete',
        );

        await provider.deletePlaylist(pl.id);
        expect(provider.playlists.length, initialLength);
        expect(provider.playlists.any((p) => p.name_en == 'To Delete'), false);

        final prefs = await SharedPreferences.getInstance();
        final deletedIds =
            prefs.getStringList('deleted_default_playlist_ids') ?? [];
        expect(deletedIds.contains(pl.id), true);

        final defaultId = provider.defaultPlaylist!.id;
        expect(
          () => provider.deletePlaylist(defaultId),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('PlaylistProvider - Item Management', () {
    setUp(() async {
      await provider.init();
    });

    test('addAarti and removeAarti should work correctly', () async {
      final plId = provider.defaultPlaylist!.id;

      await provider.addAarti(plId, 'a1');
      expect(provider.isAddedToPlaylist(plId, 'a1'), true);

      await provider.removeAarti(plId, 'a1');
      expect(provider.isAddedToPlaylist(plId, 'a1'), false);
    });

    test(
      'toggleFavorite should add/remove item from default playlist',
      () async {
        await provider.toggleFavorite('a1');
        expect(provider.isFavorite('a1'), true);

        await provider.toggleFavorite('a1');
        expect(provider.isFavorite('a1'), false);
      },
    );

    test('reorderAartis should change order correctly', () async {
      final plId = provider.defaultPlaylist!.id;
      await provider.addAarti(plId, 'a1');
      await provider.addAarti(plId, 'a2');
      await provider.addAarti(plId, 'a3');

      expect(provider.defaultPlaylist!.aartiIds, ['a1', 'a2', 'a3']);

      await provider.reorderAartis(
        plId,
        0,
        2,
      ); // Move a1 to index 1 (between a2 and a3)
      // oldIndex 0, newIndex 2. item = remove(0) -> [a2, a3], insert(1, a1) -> [a2, a1, a3]
      expect(provider.defaultPlaylist!.aartiIds, ['a2', 'a1', 'a3']);
    });
  });
}
