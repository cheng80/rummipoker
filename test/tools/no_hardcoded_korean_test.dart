// Fails when a Dart file under lib/ carries Korean text inside a string
// literal, unless that file is still on the allow list below.
//
// The list only shrinks. When a track finishes moving one file's text into
// assets/translations/src/<area>/, it deletes that file's line from the list in
// the same change. A file that is not on the list and grows a Korean literal
// fails this test, which is what stops the work from sliding backwards.
//
// What does not count, and why:
//
// - Comments, both // and /* */. They are for the people reading the code.
// - debugPrint and print arguments, and assert messages. Developers see them,
//   players do not.
// - lib/services/debug_run_fixture_*.dart. QA fixture builders that never
//   reach a player-facing screen.
// - lib/utils/semantic_wrap/ko_title_model.dart. Its Korean characters are the
//   phrase model's feature keys, not text anyone reads.
//
// These are the same exclusions the hardcoded-string survey used, so the count
// here and the count in that report line up.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that still hold Korean text. Remove a line when its file is done.
/// Never add one.
const _allowList = <String>{
  'lib/logic/rummi_poker_grid/boss_modifier.dart',
  'lib/logic/rummi_poker_grid/item_effect_handlers.dart',
  'lib/logic/rummi_poker_grid/item_effect_runtime.dart',
  'lib/logic/rummi_poker_grid/item_presentation_event.dart',
  'lib/logic/rummi_poker_grid/jester_scoring_models.dart',
  'lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart',
  'lib/logic/rummi_poker_grid/rummi_market_facade_views.dart',
  'lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart',
  'lib/logic/rummi_poker_grid/rummi_settlement_facade.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_battle_commands.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_market_commands.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_models.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_station_commands.dart',
  'lib/services/active_run_save_codec.dart',
  'lib/services/active_run_save_facade.dart',
  'lib/services/blind_selection_spec.dart',
  'lib/services/new_run_setup.dart',
  'lib/views/game/widgets/game_cashout_widgets.dart',
};

const _excludedFilePrefixes = <String>[
  'lib/services/debug_run_fixture_',
  // Korean characters here are the phrase model's feature keys, not text.
  'lib/utils/semantic_wrap/ko_title_model.dart',
];

final RegExp _korean = RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]');
final RegExp _developerOnlyCall = RegExp(r'\b(debugPrint|print|assert)\s*\(');

/// Returns the 1-based line numbers whose string literals contain Korean.
List<int> koreanStringLiteralLines(String source) {
  final lines = <int>{};
  var line = 1;
  var index = 0;
  var insideString = false;
  var quote = '';
  var isTriple = false;
  var isRaw = false;

  void recordIfKorean(String character) {
    if (insideString && _korean.hasMatch(character)) lines.add(line);
  }

  while (index < source.length) {
    final character = source[index];
    if (character == '\n') {
      line += 1;
      index += 1;
      if (insideString && !isTriple) insideString = false;
      continue;
    }
    if (!insideString) {
      // Comments never carry player-facing text.
      if (source.startsWith('//', index)) {
        final end = source.indexOf('\n', index);
        index = end < 0 ? source.length : end;
        continue;
      }
      if (source.startsWith('/*', index)) {
        final end = source.indexOf('*/', index + 2);
        final skipped = source.substring(
          index,
          end < 0 ? source.length : end + 2,
        );
        line += '\n'.allMatches(skipped).length;
        index = end < 0 ? source.length : end + 2;
        continue;
      }
      if (character == "'" || character == '"') {
        isRaw = index > 0 && source[index - 1] == 'r';
        isTriple = source.startsWith(character * 3, index);
        quote = isTriple ? character * 3 : character;
        insideString = true;
        index += quote.length;
        continue;
      }
      index += 1;
      continue;
    }
    if (!isRaw && character == r'\') {
      index += 2;
      continue;
    }
    if (source.startsWith(quote, index)) {
      insideString = false;
      index += quote.length;
      continue;
    }
    recordIfKorean(character);
    index += 1;
  }
  return lines.toList()..sort();
}

List<String> _libraryFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path)
        .where((path) => !_excludedFilePrefixes.any(path.startsWith))
        .toList()
      ..sort();

void main() {
  test('no new Korean string literals in lib/', () {
    final offenders = <String, List<int>>{};
    for (final path in _libraryFiles()) {
      final source = File(path).readAsStringSync();
      final sourceLines = source.split('\n');
      final hits = koreanStringLiteralLines(source)
          .where((line) => !_developerOnlyCall.hasMatch(sourceLines[line - 1]))
          .toList();
      if (hits.isNotEmpty) offenders[path] = hits;
    }

    final unexpected = offenders.keys.where(
      (path) => !_allowList.contains(path),
    );
    expect(
      unexpected,
      isEmpty,
      reason:
          'These files hold Korean text that players can see. Move it into '
          'assets/translations/src/<area>/ and read it with context.translate. '
          'See docs/core/I18N.md.',
    );

    final cleared = _allowList.where((path) => !offenders.containsKey(path));
    expect(
      cleared,
      isEmpty,
      reason:
          'These files no longer hold Korean text. Delete their lines from '
          '_allowList in this file.',
    );
  });

  // docs/core/I18N.md asks for whole sentences in one key. Gluing two
  // translated fragments together with a space or a middle dot reads wrong in
  // English ("Row 1 One Pair growth +1") and is simply incorrect in a language
  // that orders the parts differently. The list below only shrinks.
  test('no new sentence built from translated fragments', () {
    const stillAssembling = <String>{
      'lib/logic/rummi_poker_grid/item_presentation_event.dart',
      'lib/logic/rummi_poker_grid/rummi_settlement_facade.dart',
      'lib/providers/features/rummi_poker_grid/game_session_notifier_market_commands.dart',
      'lib/providers/features/rummi_poker_grid/game_session_notifier_station_commands.dart',
      'lib/services/active_run_save_facade.dart',
      'lib/views/archive/archive_detail_widgets.dart',
      'lib/views/game/widgets/game_shared_tile_widgets.dart',
    };
    final assembled = RegExp(
      r"'[^'\n]*\$\{[^}]*(?:context\.translate|\.translate\(|Label\(|displayName)"
      r"[^}]*\}[^'\n]*'",
    );

    final offenders = <String>{};
    for (final path in _libraryFiles()) {
      final lines = File(path).readAsStringSync().split('\n');
      for (final line in lines) {
        if (line.trimLeft().startsWith('//')) continue;
        if (assembled.hasMatch(line)) {
          offenders.add(path);
          break;
        }
      }
    }

    expect(
      offenders.difference(stillAssembling),
      isEmpty,
      reason:
          'These files glue translated fragments into one string. Put the '
          'whole sentence in one key and fill it with namedArgs. '
          'See docs/core/I18N.md.',
    );
    expect(
      stillAssembling.difference(offenders),
      isEmpty,
      reason:
          'These files no longer assemble sentences. Delete their lines from '
          'stillAssembling in this file.',
    );
  });

  // The Korean check above cannot see an English literal. The settlement
  // callout once shipped the bare word 'overlap' as the step title, and the
  // scoring preview bar and the Market tags shipped it too, so it showed in
  // all five languages. The word names a scoring concept that already has
  // keys, so it must never appear as text again.
  test('the word overlap never reaches a screen as a literal', () {
    final offenders = <String>[];

    // Dart: a quoted 'overlap'/'Overlap' that is not an id or an effect op.
    // An op string sits next to `=>` on the left of a switch arm, or inside
    // effect.value(...), so only the right-hand side is display text.
    final displayLiteral = RegExp(r"=>\s*'([^']*[Oo]verlap[^']*)'");
    for (final path in _libraryFiles()) {
      if (!path.startsWith('lib/views/')) continue;
      for (final match in displayLiteral.allMatches(
        File(path).readAsStringSync(),
      )) {
        offenders.add('$path: ${match.group(1)}');
      }
    }

    // Translations: the bare word, not the longer English 'overlapping'.
    final bareWord = RegExp(r'(?<![A-Za-z])[Oo]verlap(?![A-Za-z])');
    for (final locale in ['ko', 'en', 'ja', 'zh-CN', 'zh-TW']) {
      for (final dir in Directory(
        'assets/translations/src',
      ).listSync().whereType<Directory>()) {
        final file = File('${dir.path}/$locale.json');
        if (!file.existsSync()) continue;
        final entries =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final entry in entries.entries) {
          final value = entry.value as String;
          // English may say Overlap, every other language must not.
          if (locale == 'en') continue;
          // A placeholder name is not text anyone reads.
          final text = value.replaceAll(RegExp(r'\{[^{}]*\}'), '');
          if (bareWord.hasMatch(text)) {
            offenders.add('$locale ${entry.key}: $value');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Read the overlap label from coreSettlementOverlap or '
          'marketOverlapTag instead. See docs/core/I18N.md.',
    );
  });

  // Every arm of the settlement step switch has to read its
  // title from a translation key or from the line it describes.
  test('the settlement step titles never hold a bare literal', () {
    const path = 'lib/views/game/game_view_battle_widgets.dart';
    final source = File(path).readAsStringSync();
    const header = 'final (title, value, detail) = switch (step) {';
    final start = source.indexOf(header);
    expect(start, isNot(-1), reason: '$path: the step switch moved');
    final end = source.indexOf('\n    };', start);
    expect(end, isNot(-1), reason: '$path: the step switch has no end');
    final body = source.substring(start + header.length, end);

    // A tuple arm opens with `=> (`, and its first element is the title.
    final titles = RegExp(r'=>\s*\(\s*\n(\s*.+)')
        .allMatches(body)
        .map((match) => match.group(1)!.trim())
        .toList();
    expect(titles, isNotEmpty, reason: '$path: no step arms found');
    final literals = titles.where(
      (title) => title.startsWith("'") || title.startsWith('"'),
    );
    expect(
      literals,
      isEmpty,
      reason:
          'A settlement step title must come from context.translate or from '
          'the line, never from a literal. See docs/core/I18N.md.',
    );
  });
}
