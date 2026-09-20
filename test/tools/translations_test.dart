// Guards the translation fragment workflow described in docs/core/I18N.md:
// the committed assets/translations/<locale>.json files are merged output, and
// every locale must carry the same keys with a value in each.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/merge_translations.dart' as merge;

const _sourceRoot = 'assets/translations/src';
const _outputRoot = 'assets/translations';

List<String> _locales() =>
    Directory('$_sourceRoot/_base')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.json', ''))
        .toList()
      ..sort();

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('merged translation files match the fragments', () async {
    final result = await Process.run('dart', [
      'run',
      'tools/merge_translations.dart',
      '--check',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('every locale has the same keys with a non-empty value', () {
    final locales = _locales();
    expect(locales, contains('ko'));
    final reference = _read('$_outputRoot/ko.json').keys.toSet();
    expect(reference, isNotEmpty);
    for (final locale in locales) {
      final entries = _read('$_outputRoot/$locale.json');
      expect(
        entries.keys.toSet(),
        reference,
        reason: '$locale has a different key set than ko',
      );
      for (final entry in entries.entries) {
        expect(
          entry.value,
          isA<String>(),
          reason: '$locale key ${entry.key} is not a string',
        );
        expect(
          (entry.value as String).trim(),
          isNotEmpty,
          reason: '$locale key ${entry.key} is empty',
        );
      }
    }
  });

  // The 2026-09-20 terminology decision: Chinese puts a half-width space
  // between a Han character and a Latin letter or digit, the Chinese tile word
  // is 牌, and Japanese says バトル rather than 戦闘. See
  // docs/tools/I18N_GLOSSARY.md.
  group('the 5-locale terminology and spacing decision holds', () {
    // Every string a locale ships, fragments and data files alike.
    List<({String file, String key, String value})> valuesFor(String locale) {
      final out = <({String file, String key, String value})>[];
      void walk(String file, String key, Object? node) {
        if (node is Map) {
          for (final entry in node.entries) {
            walk(file, key.isEmpty ? '${entry.key}' : '$key.${entry.key}',
                entry.value);
          }
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            walk(file, '$key[$i]', node[i]);
          }
        } else if (node is String) {
          out.add((file: file, key: key, value: node));
        }
      }

      for (final dir in Directory(_sourceRoot).listSync().whereType<Directory>()) {
        final file = File('${dir.path}/$locale.json');
        if (file.existsSync()) walk(file.path, '', jsonDecode(file.readAsStringSync()));
      }
      final dataDir = Directory('$_outputRoot/data/$locale');
      if (dataDir.existsSync()) {
        for (final file in dataDir.listSync().whereType<File>()) {
          if (file.path.endsWith('.json')) {
            walk(file.path, '', jsonDecode(file.readAsStringSync()));
          }
        }
      }
      return out;
    }

    // A placeholder is not Latin by itself, so what decides the spacing is the
    // value the code passes. These names always carry a translated Chinese
    // term, read off the namedArgs call sites in lib/, so they sit tight
    // against a Han character. Every other name holds a number or an English
    // proper noun, or can hold either, and keeps its space.
    const chineseValue = <String>{
      'rank',
      'line',
      'color',
      'mode',
      'difficulty',
      'modifier',
      'action',
      'effect',
      'status',
      'summary',
    };

    test('Chinese keeps a space between a Han character and Latin', () {
      // A measure word or a percent sign stays against its number, and the
      // decision left `run` in the subtitle as it was.
      final allowed = RegExp(r'[0-9}][张張个個条條次种種局回%％]');
      final tight = RegExp(
        r'([㐀-䶿一-鿿][A-Za-z0-9{])'
        r'|([A-Za-z0-9}][㐀-䶿一-鿿])',
      );
      final offenders = <String>[];
      for (final locale in ['zh-CN', 'zh-TW']) {
        for (final row in valuesFor(locale)) {
          // Blank out the placeholders whose value is a Chinese term, so the
          // Han characters around them read as one run.
          var text = row.value;
          for (final name in chineseValue) {
            text = text.replaceAll('{$name}', '');
          }
          for (final match in tight.allMatches(text)) {
            if (allowed.hasMatch(match.group(0)!)) continue;
            offenders.add('$locale ${row.key}: ...${match.group(0)}...');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Chinese puts a half-width space between a Han character and a '
            'Latin letter or digit. See docs/tools/I18N_GLOSSARY.md.',
      );
    });

    test('Chinese keeps a term placeholder tight against a Han character', () {
      final offenders = <String>[];
      for (final locale in ['zh-CN', 'zh-TW']) {
        for (final row in valuesFor(locale)) {
          for (final name in chineseValue) {
            final loose = RegExp('([㐀-䶿一-鿿] \\{$name\\})|(\\{$name\\} [㐀-䶿一-鿿])');
            for (final match in loose.allMatches(row.value)) {
              offenders.add('$locale ${row.key}: ...${match.group(0)}...');
            }
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'These placeholders always hold a Chinese term, so no space sits '
            'between them and a Han character. See docs/tools/I18N_GLOSSARY.md.',
      );
    });

    test('Chinese calls a tile 牌, not 牌块 or 牌塊', () {
      final offenders = <String>[];
      for (final locale in ['zh-CN', 'zh-TW']) {
        for (final row in valuesFor(locale)) {
          if (row.value.contains('牌块') || row.value.contains('牌塊')) {
            offenders.add('$locale ${row.key}');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'The Chinese word for a tile is 牌.');
    });

    test('Japanese calls a battle バトル, not 戦闘', () {
      final offenders = [
        for (final row in valuesFor('ja'))
          if (row.value.contains('戦闘')) row.key,
      ];
      expect(offenders, isEmpty, reason: 'Japanese says バトル.');
    });
  });

  test('the per-locale data files carry the same ids', () {
    for (final name in ['items', 'jesters']) {
      final reference =
          _read('$_outputRoot/data/ko/$name.json')['data']
              as Map<String, dynamic>;
      final referenceIds = (reference.values.single as Map).keys.toSet();
      for (final locale in _locales()) {
        final entries =
            _read('$_outputRoot/data/$locale/$name.json')['data']
                as Map<String, dynamic>;
        expect(
          (entries.values.single as Map).keys.toSet(),
          referenceIds,
          reason: '$locale $name.json has a different id set than ko',
        );
      }
    }
  });

  group('the merge tool refuses a fragment it cannot trust', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('translations'));
    tearDown(() => root.deleteSync(recursive: true));

    void writeFragment(
      String area,
      String locale,
      Map<String, String> entries,
    ) {
      final file = File('${root.path}/$area/$locale.json')
        ..parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(entries));
    }

    Map<String, String> build() =>
        merge.buildMergedTranslations(sourceRoot: root.path, outputRoot: 'out');

    test('an empty value is an error, not a placeholder', () {
      writeFragment('_base', 'ko', {'greeting': '안녕'});
      writeFragment('_base', 'en', {'greeting': '   '});
      expect(
        build,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('is empty'),
          ),
        ),
      );
    });

    test('two areas cannot define the same key', () {
      writeFragment('_base', 'ko', {'greeting': '안녕'});
      writeFragment('battle', 'ko', {'greeting': '반가워'});
      expect(
        build,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Duplicate translation key'),
          ),
        ),
      );
    });

    test('a healthy fragment set merges', () {
      writeFragment('_base', 'ko', {'greeting': '안녕'});
      writeFragment('_base', 'en', {'greeting': 'Hi'});
      expect(build().keys, containsAll(['out/ko.json', 'out/en.json']));
    });
  });

  test('the fragment sources are not declared as bundled assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec.contains('$_sourceRoot/'),
      isFalse,
      reason:
          'assets/translations/src/ is the build input and must stay out of '
          'the app bundle. A directory entry in pubspec covers only its direct '
          'children, so "assets/translations/" alone is correct.',
    );
  });
}
