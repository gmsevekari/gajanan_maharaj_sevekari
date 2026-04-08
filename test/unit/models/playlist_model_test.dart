import 'package:flutter_test/flutter_test.dart';
import 'package:gajanan_maharaj_sevekari/models/playlist.dart';

void main() {
  group('Playlist Model', () {
    test('Playlist serialization', () {
      final playlist = Playlist(
        id: 'p1',
        name: 'My Morning Aartis',
        isDefault: true,
        aartiIds: ['a1', 'a2'],
        createdAt: DateTime(2023, 1, 1),
      );

      final json = playlist.toJson();
      expect(json['id'], 'p1');
      expect(json['name'], 'My Morning Aartis');
      expect(json['isDefault'], true);
      expect(json['aartiIds'], ['a1', 'a2']);
      expect(json['createdAt'], '2023-01-01T00:00:00.000');

      final fromJson = Playlist.fromJson(json);
      expect(fromJson.id, 'p1');
      expect(fromJson.name, 'My Morning Aartis');
      expect(fromJson.isDefault, true);
      expect(fromJson.aartiIds, contains('a1'));
      expect(fromJson.createdAt.year, 2023);
    });

    test('Playlist copyWith', () {
      final playlist = Playlist(name: 'Test');
      final updated = playlist.copyWith(name: 'Updated', aartiIds: ['new_id']);

      expect(updated.id, playlist.id);
      expect(updated.name, 'Updated');
      expect(updated.aartiIds, ['new_id']);
    });
  });
}
