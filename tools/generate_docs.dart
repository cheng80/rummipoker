import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';

const _contentOutputPath = 'docs/generated/CONTENT_CATALOG.md';
const _bossOutputPath = 'docs/generated/BOSS_PATTERNS.md';
const _sourcePaths = <String>[
  'data/common/jesters_common_phase5.json',
  'data/common/items_common_v1.json',
  'assets/translations/data/ko/jesters.json',
  'assets/translations/data/ko/items.json',
  'lib/logic/rummi_poker_grid/boss_modifier.dart',
];
const _usage = '''Usage: dart run tools/generate_docs.dart [--check]

  no flag   Regenerate both documentation files.
  --check   Exit nonzero when either generated file is stale; write nothing.
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

  final sourceHashes = {
    for (final path in _sourcePaths)
      path: sha256.convert(File(path).readAsBytesSync()).toString(),
  };
  final sourceDirty = _sourceDirtyNote();
  final jesters = _readJesters();
  final items = _readItems();
  final bosses = _readBosses();
  final outputs = <String, String>{
    _contentOutputPath: _renderContentCatalog(
      jesters: jesters,
      items: items,
      sourceHashes: sourceHashes,
      sourceDirty: sourceDirty,
    ),
    _bossOutputPath: _renderBossPatterns(
      bosses: bosses,
      sourceHashes: sourceHashes,
      sourceDirty: sourceDirty,
    ),
  };

  if (args.singleOrNull == '--check') {
    var stale = false;
    for (final entry in outputs.entries) {
      final file = File(entry.key);
      final actual = file.existsSync()
          ? _normalizeDirtyNote(file.readAsStringSync())
          : null;
      final expected = _normalizeDirtyNote(entry.value);
      if (actual != expected) {
        stderr.writeln('STALE: ${entry.key}');
        stale = true;
      }
    }
    if (stale) exitCode = 1;
    return;
  }

  for (final entry in outputs.entries) {
    final file = File(entry.key)..parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
    stdout.writeln('WROTE: ${entry.key}');
  }
}

List<Map<String, dynamic>> _readJesters() {
  final source = (jsonDecode(File(_sourcePaths[0]).readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final translations = _translationEntries(_sourcePaths[2], 'jesters');
  _requireUniqueIds(source, 'Jester');
  return source
      .map((entry) => {...entry, ..._translatedFields(entry, translations)})
      .toList(growable: false);
}

List<Map<String, dynamic>> _readItems() {
  final document =
      jsonDecode(File(_sourcePaths[1]).readAsStringSync())
          as Map<String, dynamic>;
  final source = (document['items']! as List).cast<Map<String, dynamic>>();
  final translations = _translationEntries(_sourcePaths[3], 'items');
  _requireUniqueIds(source, 'Item');
  return source
      .map((entry) => {...entry, ..._translatedFields(entry, translations)})
      .toList(growable: false);
}

Map<String, Map<String, dynamic>> _translationEntries(
  String path,
  String collection,
) {
  final document =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final data = document['data']! as Map<String, dynamic>;
  return (data[collection]! as Map<String, dynamic>).map(
    (key, value) => MapEntry(key, (value as Map).cast<String, dynamic>()),
  );
}

Map<String, String> _translatedFields(
  Map<String, dynamic> entry,
  Map<String, Map<String, dynamic>> translations,
) {
  final id = entry['id']! as String;
  final translated = translations[id];
  if (translated == null) {
    throw FormatException('Missing Korean translation for $id');
  }
  return {
    'koDisplayName': translated['displayName']! as String,
    'koEffectText': translated['effectText']! as String,
  };
}

void _requireUniqueIds(List<Map<String, dynamic>> entries, String label) {
  final ids = entries.map((entry) => entry['id']! as String).toList();
  if (ids.toSet().length != ids.length) {
    throw FormatException('$label catalog contains duplicate IDs');
  }
}

List<RummiBossModifier> _readBosses() {
  final bosses = RummiBossModifier.allKnownModifiers
      .where(
        (modifier) =>
            modifier.category == RummiBossModifierCategory.boardCellBlock,
      )
      .toList(growable: false);
  if (bosses.length != 14 ||
      bosses.map((boss) => boss.id).toSet().length != bosses.length) {
    throw const FormatException('Expected 14 unique boardCellBlock Boss IDs');
  }
  for (final boss in bosses) {
    if (boss.blockedCells.isEmpty || boss.blockedCells.length > 5) {
      throw FormatException('${boss.id} must block 1..5 cells');
    }
    if (boss.blockedCells.toSet().length != boss.blockedCells.length ||
        boss.blockedCells.any(
          (cell) => cell.$1 < 0 || cell.$1 > 4 || cell.$2 < 0 || cell.$2 > 4,
        )) {
      throw FormatException('${boss.id} contains invalid blocked cells');
    }
  }
  return bosses;
}

String _renderContentCatalog({
  required List<Map<String, dynamic>> jesters,
  required List<Map<String, dynamic>> items,
  required Map<String, String> sourceHashes,
  required String sourceDirty,
}) {
  final buffer = StringBuffer()
    ..writeln('# Current Content Catalog')
    ..writeln()
    ..write(
      _header(
        sourceHashes: sourceHashes,
        sourceDirty: sourceDirty,
        selfCheck:
            'PASS: ${jesters.length} unique Jesters; ${items.length} unique Items; Korean translation present for every ID.',
      ),
    )
    ..writeln('## Jesters (${jesters.length})')
    ..writeln()
    ..writeln('| ID | 이름 | 희귀도 | 가격 | 트리거 | 효과 타입 | 효과 |')
    ..writeln('|---|---|---|---:|---|---|---|');
  for (final entry in jesters) {
    buffer.writeln(
      '| `${entry['id']}` | ${_cell(entry['koDisplayName'])} | '
      '${_cell(entry['rarity'])} | ${entry['baseCost']} | '
      '${_cell(entry['trigger'])} | ${_cell(entry['effectType'])} | '
      '${_cell(entry['koEffectText'])} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Items (${items.length})')
    ..writeln()
    ..writeln('| ID | 이름 | 타입 | 희귀도 | 가격 | 판매가 | 위치 | timing | op | 효과 |')
    ..writeln('|---|---|---|---|---:|---:|---|---|---|---|');
  for (final entry in items) {
    final effect = (entry['effect']! as Map).cast<String, dynamic>();
    buffer.writeln(
      '| `${entry['id']}` | ${_cell(entry['koDisplayName'])} | '
      '${_cell(entry['type'])} | ${_cell(entry['rarity'])} | '
      '${entry['basePrice']} | ${entry['sellPrice']} | '
      '${_cell(entry['placement'])} | ${_cell(effect['timing'])} | '
      '${_cell(effect['op'])} | ${_cell(entry['koEffectText'])} |',
    );
  }
  return '${buffer.toString().trimRight()}\n';
}

String _renderBossPatterns({
  required List<RummiBossModifier> bosses,
  required Map<String, String> sourceHashes,
  required String sourceDirty,
}) {
  final buffer = StringBuffer()
    ..writeln('# Current Boss Board Cell Block Patterns')
    ..writeln()
    ..write(
      _header(
        sourceHashes: sourceHashes,
        sourceDirty: sourceDirty,
        selfCheck:
            'PASS: ${bosses.length} unique boardCellBlock IDs; coordinates 0..4; unique cells; at most 5 blocked cells per pattern.',
      ),
    )
    ..writeln('`1`은 배치 가능, `0`은 배치 금지 칸이다.')
    ..writeln();
  for (final boss in bosses) {
    final cells = boss.blockedCells
        .map((cell) => '(${cell.$1}, ${cell.$2})')
        .join(', ');
    buffer
      ..writeln('### `${boss.id}`')
      ..writeln()
      ..writeln('- Title: ${boss.title}')
      ..writeln('- Rule: ${boss.ruleText}')
      ..writeln('- Blocked cells: $cells')
      ..writeln()
      ..writeln('```text');
    for (var row = 0; row < 5; row++) {
      buffer.writeln(
        List.generate(
          5,
          (col) => boss.blocksBoardCell(row, col) ? '0' : '1',
        ).join(),
      );
    }
    buffer
      ..writeln('```')
      ..writeln();
  }
  return '${buffer.toString().trimRight()}\n';
}

String _header({
  required Map<String, String> sourceHashes,
  required String sourceDirty,
  required String selfCheck,
}) {
  final buffer = StringBuffer()
    ..writeln('> DO NOT EDIT. Generated by `tools/generate_docs.dart`.')
    ..writeln()
    ..writeln('- Command: `dart run tools/generate_docs.dart`')
    ..writeln('- Check: `dart run tools/generate_docs.dart --check`')
    ..writeln('- Generation-time source dirty: $sourceDirty')
    ..writeln('- Self-check: $selfCheck')
    ..writeln()
    ..writeln('## Sources')
    ..writeln();
  for (final entry in sourceHashes.entries) {
    buffer.writeln('- `${entry.key}`: `${entry.value}`');
  }
  buffer.writeln();
  return '$buffer';
}

String _sourceDirtyNote() {
  final result = Process.runSync('git', [
    'status',
    '--porcelain',
    '--',
    ..._sourcePaths,
  ]);
  if (result.exitCode != 0) return 'unknown';
  final paths = result.stdout
      .toString()
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.substring(3))
      .toList(growable: false);
  return paths.isEmpty ? 'clean' : 'dirty: ${paths.join(', ')}';
}

String _normalizeDirtyNote(String value) => value
    .split('\n')
    .map(
      (line) => line.startsWith('- Generation-time source dirty: ')
          ? '- Generation-time source dirty: <normalized>'
          : line,
    )
    .join('\n');

String _cell(Object? value) => value
    .toString()
    .replaceAll('|', r'\|')
    .replaceAll('\r', ' ')
    .replaceAll('\n', ' ');

extension on List<String> {
  String? get singleOrNull => length == 1 ? single : null;
}
