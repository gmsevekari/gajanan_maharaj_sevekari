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
      expect(playlist.name, 'Daily Aarti');
      expect(playlist.isDefault, true);
      expect(playlist.aartiIds, ['a1', 'a2']);
      expect(playlist.createdAt, DateTime.parse('2024-05-01T12:00:00.000Z'));
    });

    test('toJson should correctly serialize the playlist', () {
      final dateTime = DateTime.now();
      final playlist = Playlist(
        name: 'My Custom Playlist',
        isDefault: false,
        aartiIds: ['a1'],
        createdAt: dateTime,
      );

      final json = playlist.toJson();

      expect(json['name'], 'My Custom Playlist');
      expect(json['isDefault'], false);
      expect(json['aartiIds'], ['a1']);
      expect(json['createdAt'], dateTime.toIso8601String());
    });

    test('copyWith should only update changed fields', () {
      final playlist = Playlist(name: 'Initial Name', aartiIds: ['1']);
      final updatedPlaylist = playlist.copyWith(name: 'New Name');

      expect(updatedPlaylist.id, playlist.id);
      expect(updatedPlaylist.name, 'New Name');
      expect(updatedPlaylist.aartiIds, ['1']);
    });
  });
}
