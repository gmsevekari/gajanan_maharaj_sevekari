import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/playlist.dart';

void main() {
  group('Playlist', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'test-uuid',
        'name': 'Daily Aarti',
        'isDefault': true,
        'aartiIds': ['a1', 'a2'],
        'createdAt': '2024-05-01T12:00:00.000Z'
      };

      final playlist = Playlist.fromJson(json);

      expect(playlist.id, 'test-uuid');
      expect(playlist.name_en, 'Daily Aarti');
      expect(playlist.name_mr, 'Daily Aarti');
      expect(playlist.isDefault, true);
      expect(playlist.aartiIds, ['a1', 'a2']);
      expect(playlist.createdAt, DateTime.parse('2024-05-01T12:00:00.000Z'));
    });

    test('toJson should correctly serialize the playlist', () {
      final dateTime = DateTime.now();
      final playlist = Playlist(
        name_en: 'My Custom Playlist',
        name_mr: 'My Custom Playlist',
        isDefault: false,
        aartiIds: ['a1'],
        createdAt: dateTime,
      );

      final json = playlist.toJson();

      expect(json['name_en'], 'My Custom Playlist');
      expect(json['name_mr'], 'My Custom Playlist');
      expect(json['isDefault'], false);
      expect(json['aartiIds'], ['a1']);
      expect(json['createdAt'], dateTime.toIso8601String());
    });

    test('copyWith should only update changed fields', () {
      final playlist = Playlist(name_en: 'Initial Name', name_mr: 'Initial Name', aartiIds: ['1']);
      final updatedPlaylist = playlist.copyWith(name_en: 'New Name', name_mr: 'New Name');

      expect(updatedPlaylist.id, playlist.id);
      expect(updatedPlaylist.name_en, 'New Name');
      expect(updatedPlaylist.name_mr, 'New Name');
      expect(updatedPlaylist.aartiIds, ['1']);
    });
  });
}
