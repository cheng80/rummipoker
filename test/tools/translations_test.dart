// Guards the translation fragment workflow described in docs/core/I18N.md:
// the committed assets/translations/<locale>.json files are merged output, and
// every locale must carry the same keys with a value in each.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
