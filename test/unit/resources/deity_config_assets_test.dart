import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _configDir = 'resources/config';
const _requiredTextKeys = ['title_mr', 'title_en', 'content_mr', 'content_en'];
const _kavachamFile =
    'resources/texts/datta_maharaj/stotras/dattatreya_kavacham.json';
const _kavachamVerseCount = 12;
const _prasadFile =
    'resources/texts/other/other_stotras/prasad_ha_maja_dyava.json';
const _prasadVideoId = 'UGMN4_6Ozq4';
const _prasadStanzaCount = 5;

Map<String, dynamic> _readJson(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Every text file a deity config lists under `nityopasana`, as a path.
List<String> _listedTextFiles(Map<String, dynamic> config) {
  final nityopasana = config['nityopasana'] as Map<String, dynamic>?;
  if (nityopasana == null) return const [];
  final paths = <String>[];
  for (final section in nityopasana.values) {
    if (section is! Map<String, dynamic>) continue;
    final dir = section['textResourceDirectory'] as String?;
    final files = section['files'] as List<dynamic>?;
    if (dir == null || files == null) continue;
    for (final entry in files) {
      paths.add('$dir/${(entry as Map<String, dynamic>)['file']}');
    }
  }
  return paths;
}

void main() {
  final deityConfigs = Directory(_configDir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => json.decode(f.readAsStringSync()))
      .whereType<Map<String, dynamic>>()
      .where((c) => c.containsKey('nityopasana'))
      .toList();

  group('deity config text files', () {
    test('there are deity configs to check', () {
      expect(deityConfigs, isNotEmpty);
    });

    for (final config in deityConfigs) {
      final deityId = config['id'];
      for (final path in _listedTextFiles(config)) {
        test('$deityId: $path exists and has the required text', () {
          expect(File(path).existsSync(), isTrue, reason: '$path is missing');

          final data = _readJson(path);
          for (final key in _requiredTextKeys) {
            expect(
              (data[key] as String?)?.trim() ?? '',
              isNotEmpty,
              reason: '$path has no $key',
            );
          }
        });
      }
    }
  });

  group('Datta Maharaj stotras', () {
    test('lists the Dattatreya Kavacham stotra', () {
      final datta = deityConfigs.firstWhere((c) => c['id'] == 'datta_maharaj');

      expect(_listedTextFiles(datta), contains(_kavachamFile));
    });

    test('Dattatreya Kavacham has verses 1..12 in order, in both scripts', () {
      final data = _readJson(_kavachamFile);
      const devanagariDigits = '०१२३४५६७८९';

      final marathiNumbers = RegExp(r'॥ ([०-९]+)॥')
          .allMatches(data['content_mr'] as String)
          .map((m) => int.parse(
                m.group(1)!.split('').map(devanagariDigits.indexOf).join(),
              ))
          .toList();
      final englishNumbers = RegExp(r'\|\| (\d+) \|\|')
          .allMatches(data['content_en'] as String)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      final expected = List.generate(_kavachamVerseCount, (i) => i + 1);

      expect(marathiNumbers, expected);
      expect(englishNumbers, expected);
    });
  });

  group('Other stotras', () {
    test('lists Prasad Ha Maja Dyava', () {
      final other = deityConfigs.firstWhere((c) => c['id'] == 'other');

      expect(_listedTextFiles(other), contains(_prasadFile));
    });

    test('Prasad Ha Maja Dyava has its video, refrain and stanzas 1..5', () {
      final data = _readJson(_prasadFile);
      final marathi = data['content_mr'] as String;

      expect(data['youtube_video_id'], _prasadVideoId);
      expect(marathi, contains('धृ.'));
      expect(
        RegExp(r'॥ ([१-५]) ॥').allMatches(marathi).map((m) => m.group(1)),
        ['१', '२', '३', '४', '५'],
      );
      expect(
        RegExp(r'\|\| (\d) \|\|')
            .allMatches(data['content_en'] as String)
            .length,
        _prasadStanzaCount,
      );
    });
  });
}
