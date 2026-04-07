import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gajanan_maharaj_sevekari/providers/playlist_provider.dart';
import 'package:gajanan_maharaj_sevekari/models/playlist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaylistProvider', () {
    const playlistsKey = 'user_playlists';

    test('init should create default "My Favorites" playlist if none exists', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      
      await provider.init();
      
      expect(provider.playlists.length, 1);
      expect(provider.playlists.first.name, 'My Favorites');
      expect(provider.playlists.first.isDefault, true);
    });

    test('loadPlaylists should load existing playlists from SharedPreferences', () async {
      final existingPlaylists = [
        Playlist(id: 'p1', name: 'Custom List', isDefault: false),
      ];
      SharedPreferences.setMockInitialValues({
        playlistsKey: json.encode(existingPlaylists.map((p) => p.toJson()).toList()),
      });
      
      final provider = PlaylistProvider();
      await provider.init();
      
      expect(provider.playlists.length, 1);
      expect(provider.playlists.first.name, 'Custom List');
    });

    test('createPlaylist should add new playlist and persist', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      await provider.init();
      
      await provider.createPlaylist('Meditation');
      
      expect(provider.playlists.length, 2);
      expect(provider.playlists.any((p) => p.name == 'Meditation'), true);
      
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(playlistsKey);
      expect(stored, contains('Meditation'));
    });

    test('createPlaylist should throw if name is duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      await provider.init();
      
      expect(() => provider.createPlaylist('My Favorites'), throwsException);
    });

    test('addAarti should update playlist and persist', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      await provider.init();
      final playlistId = provider.playlists.first.id;
      
      await provider.addAarti(playlistId, 'aarti_123');
      
      expect(provider.playlists.first.aartiIds, contains('aarti_123'));
      expect(provider.isAddedToPlaylist(playlistId, 'aarti_123'), true);
    });

    test('toggleFavorite should add/remove item from default playlist', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      await provider.init();
      const aartiId = 'a1';
      
      // Toggle on
      await provider.toggleFavorite(aartiId);
      expect(provider.isFavorite(aartiId), true);
      
      // Toggle off
      await provider.toggleFavorite(aartiId);
      expect(provider.isFavorite(aartiId), false);
    });

    test('reorderAartis should change order of items', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlaylistProvider();
      await provider.init();
      final pid = provider.playlists.first.id;
      
      await provider.addAarti(pid, '1');
      await provider.addAarti(pid, '2');
      await provider.addAarti(pid, '3');
      
      // Initial: [1, 2, 3]
      // Move '1' to after '2'
      await provider.reorderAartis(pid, 0, 2); 
      // Result: [2, 1, 3]
      
      expect(provider.playlists.first.aartiIds, ['2', '1', '3']);
    });
  });
}
