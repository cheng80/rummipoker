// Builds assets/translations/<locale>.json from the per-area fragments in
// assets/translations/src/<area>/<locale>.json.
//
// Why fragments: several people add translation keys at the same time, and a
// single file per locale makes every one of those changes conflict. Each area
// owns its own fragment instead, and this tool merges them.
//
// The merged files are committed, but they are build output. Do not edit them
// by hand; edit the fragment and run this tool. test/tools/translations_test.dart
// fails when the committed output does not match the fragments.
//
//   dart run tools/merge_translations.dart            Rebuild the merged files.
//   dart run tools/merge_translations.dart --check    Report staleness, write nothing.

import 'dart:convert';
import 'dart:io';

const _sourceRoot = 'assets/translations/src';
const _outputRoot = 'assets/translations';
const _usage = '''Usage: dart run tools/merge_translations.dart [--check]

  no flag   Rebuild assets/translations/<locale>.json from the fragments.
  --check   Exit nonzero when a merged file is stale; write nothing.
  --help    Print this help.''';

void main(List<String> args) {
  if (args.length > 1 ||
      (args.isNotEmpty &&
          args.single != '--check' &&
          args.single != '--help')) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  if (args.singleOrNull == '--help') {
    stdout.writeln(_usage);
    return;
  }

  final Map<String, String> outputs;
  try {
    outputs = buildMergedTranslations();
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
    return;
  }

  if (args.singleOrNull == '--check') {
    var stale = false;
    for (final entry in outputs.entries) {
      final file = File(entry.key);
      final actual = file.existsSync() ? file.readAsStringSync() : null;
      if (actual != entry.value) {
        stderr.writeln('STALE: ${entry.key}');
        stale = true;
      }
    }
    if (stale) {
      stderr.writeln('Run: dart run tools/merge_translations.dart');
      exitCode = 1;
    }
    return;
  }

  for (final entry in outputs.entries) {
    File(entry.key).writeAsStringSync(entry.value);
    stdout.writeln('WROTE: ${entry.key}');
  }
}

/// Returns the merged file contents keyed by output path.
///
/// Throws a [FormatException] when two areas define the same key, when an area
/// is missing a locale, or when the locales of one area disagree about which
/// keys exist.
Map<String, String> buildMergedTranslations() {
  final areas = _areaNames();
  if (areas.isEmpty) {
    throw const FormatException(
      'No translation areas found under $_sourceRoot',
    );
  }
  final locales = _localeNames(areas.first);

  final owners = <String, String>{};
  final merged = {for (final locale in locales) locale: <String, String>{}};

  for (final area in areas) {
    final areaLocales = _localeNames(area);
    if (!_sameItems(areaLocales, locales)) {
      throw FormatException(
        'Area "$area" has locales $areaLocales but area "${areas.first}" has $locales',
      );
    }
    Set<String>? areaKeys;
    for (final locale in locales) {
      final entries = _readFragment(area, locale);
      areaKeys ??= entries.keys.toSet();
      if (!_sameItems(
        entries.keys.toList()..sort(),
        areaKeys.toList()..sort(),
      )) {
        throw FormatException(
          'Area "$area" locale "$locale" does not have the same keys as the '
          'other locales of that area',
        );
      }
      for (final entry in entries.entries) {
        final owner = owners[entry.key];
        if (owner != null && owner != area) {
          throw FormatException(
            'Duplicate translation key "${entry.key}" in areas "$owner" and "$area"',
          );
        }
        owners[entry.key] = area;
        merged[locale]![entry.key] = entry.value;
      }
    }
  }

  const encoder = JsonEncoder.withIndent('  ');
  return {
    for (final locale in locales)
      '$_outputRoot/$locale.json':
          '${encoder.convert({for (final key in merged[locale]!.keys.toList()..sort()) key: merged[locale]![key]})}\n',
  };
}

List<String> _areaNames() =>
    Directory(_sourceRoot)
        .listSync()
        .whereType<Directory>()
        .map(
          (directory) =>
              directory.uri.pathSegments[directory.uri.pathSegments.length - 2],
        )
        .toList()
      ..sort();

List<String> _localeNames(String area) =>
    Directory('$_sourceRoot/$area')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.json', ''))
        .toList()
      ..sort();

Map<String, String> _readFragment(String area, String locale) {
  final path = '$_sourceRoot/$area/$locale.json';
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('$path must contain a JSON object');
  }
  final entries = <String, String>{};
  decoded.forEach((key, value) {
    if (value is! String) {
      throw FormatException('$path key "$key" must map to a string');
    }
    entries['$key'] = value;
  });
  return entries;
}

bool _sameItems(List<String> left, List<String> right) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((equal) => equal);
