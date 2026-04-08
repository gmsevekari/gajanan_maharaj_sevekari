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
      'init should create default "My Favorites" playlist if none exists',
      () async {
        await provider.init();
        expect(provider.playlists.length, 1);
        expect(provider.playlists.first.name, 'My Favorites');
        expect(provider.playlists.first.isDefault, true);
        expect(provider.defaultPlaylist, isNotNull);
      },
    );

    test(
      'init should load existing playlists from SharedPreferences',
      () async {
        final existingPlaylists = [
          Playlist(
            id: '1',
            name: 'Existing',
            isDefault: true,
            aartiIds: ['a1'],
          ),
        ];
        SharedPreferences.setMockInitialValues({
          'user_playlists': json.encode(
            existingPlaylists.map((p) => p.toJson()).toList(),
          ),
        });

        await provider.init();
        expect(provider.playlists.length, 1);
        expect(provider.playlists.first.name, 'Existing');
        expect(provider.playlists.first.aartiIds, ['a1']);
      },
    );
  });

  group('PlaylistProvider - CRUD Operations', () {
    setUp(() async {
      await provider.init();
    });

    test('createPlaylist should add new playlist', () async {
      await provider.createPlaylist('New List');
      expect(provider.playlists.length, 2);
      expect(provider.playlists.any((p) => p.name == 'New List'), true);
    });

    test('createPlaylist should throw if name is duplicate', () async {
      expect(
        () => provider.createPlaylist('My Favorites'),
        throwsA(isA<Exception>()),
      );
    });

    test('renamePlaylist should update name correctly', () async {
      await provider.createPlaylist('Old Name');
      final pl = provider.playlists.firstWhere((p) => p.name == 'Old Name');

      await provider.renamePlaylist(pl.id, 'New Name');
      expect(provider.playlists.any((p) => p.name == 'New Name'), true);
      expect(provider.playlists.any((p) => p.name == 'Old Name'), false);
    });

    test(
      'deletePlaylist should remove playlist but prevent default deletion',
      () async {
        await provider.createPlaylist('To Delete');
        final pl = provider.playlists.firstWhere((p) => p.name == 'To Delete');

        await provider.deletePlaylist(pl.id);
        expect(provider.playlists.length, 1);
        expect(provider.playlists.any((p) => p.name == 'To Delete'), false);

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
