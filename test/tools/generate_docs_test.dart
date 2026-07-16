import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _sourcePaths = <String>[
  'data/common/jesters_common_phase5.json',
  'data/common/items_common_v1.json',
  'assets/translations/data/ko/jesters.json',
  'assets/translations/data/ko/items.json',
  'lib/logic/rummi_poker_grid/boss_modifier.dart',
];

void main() {
  group('generate_docs', () {
    test(
      'Given current sources, when checked, then generated docs are fresh',
      () async {
        final result = await Process.run('dart', [
          'run',
          'tools/generate_docs.dart',
          '--check',
        ]);

        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      },
    );

    test(
      'Given current catalogs, when read, then every ID is generated once',
      () {
        final jesterSource =
            jsonDecode(File(_sourcePaths[0]).readAsStringSync())
                as List<dynamic>;
        final itemSource =
            jsonDecode(File(_sourcePaths[1]).readAsStringSync())
                as Map<String, dynamic>;
        final expectedJesters = jesterSource
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']! as String)
            .toSet();
        final expectedItems = (itemSource['items']! as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['id']! as String)
            .toSet();
        final generated = File(
          'docs/generated/CONTENT_CATALOG.md',
        ).readAsStringSync();

        expect(_tableIds(generated, 'Jesters'), expectedJesters);
        expect(_tableIds(generated, 'Items'), expectedItems);
        expect(generated, isNot(contains('boss_memory')));
        expect(generated, isNot(contains('thin_memory')));
        expect(generated, isNot(contains('minor_memory')));
      },
    );

    test(
      'Given generated headers, when read, then every source hash matches',
      () {
        for (final generatedPath in const [
          'docs/generated/CONTENT_CATALOG.md',
          'docs/generated/BOSS_PATTERNS.md',
        ]) {
          final generated = File(generatedPath).readAsStringSync();
          for (final sourcePath in _sourcePaths) {
            final digest = sha256.convert(File(sourcePath).readAsBytesSync());
            expect(generated, contains('`$sourcePath`: `$digest`'));
          }
        }
      },
    );

    test('Given Boss patterns, when parsed, then IDs and cells are valid', () {
      final generated = File(
        'docs/generated/BOSS_PATTERNS.md',
      ).readAsStringSync();
      final sections = RegExp(
        r'^### `([^`]+)`\n(?:.|\n)*?^- Blocked cells: ([^\n]+)$',
        multiLine: true,
      ).allMatches(generated).toList(growable: false);
      final ids = sections.map((match) => match.group(1)!).toSet();

      expect(sections, hasLength(14));
      expect(ids, hasLength(14));
      for (final section in sections) {
        final cells = RegExp(r'\(([0-4]), ([0-4])\)')
            .allMatches(section.group(2)!)
            .map(
              (match) =>
                  (int.parse(match.group(1)!), int.parse(match.group(2)!)),
            )
            .toList(growable: false);
        expect(cells, isNotEmpty);
        expect(cells.length, lessThanOrEqualTo(5));
        expect(cells.toSet(), hasLength(cells.length));
      }
    });

    test(
      'Given an unknown flag, when run, then help is printed and it fails',
      () async {
        final result = await Process.run('dart', [
          'run',
          'tools/generate_docs.dart',
          '--unknown',
        ]);
        final output = '${result.stdout}${result.stderr}';

        expect(result.exitCode, isNot(0));
        expect(output, contains('Usage: dart run tools/generate_docs.dart'));
      },
    );
  });
}

Set<String> _tableIds(String markdown, String section) {
  final lines = markdown.split('\n');
  final start = lines.indexWhere((line) => line.startsWith('## $section ('));
  final end = lines.indexWhere((line) => line.startsWith('## '), start + 1);
  final body = lines
      .sublist(start + 1, end < 0 ? lines.length : end)
      .join('\n');
  return RegExp(
    r'^\| `([^`]+)` \|',
    multiLine: true,
  ).allMatches(body).map((match) => match.group(1)!).toSet();
}
