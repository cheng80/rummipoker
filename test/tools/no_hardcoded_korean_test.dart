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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files that still hold Korean text. Remove a line when its file is done.
/// Never add one.
const _allowList = <String>{
  'lib/app_config.dart',
  'lib/logic/rummi_poker_grid/boss_modifier.dart',
  'lib/logic/rummi_poker_grid/item_effect_handlers.dart',
  'lib/logic/rummi_poker_grid/item_effect_runtime.dart',
  'lib/logic/rummi_poker_grid/item_presentation_event.dart',
  'lib/logic/rummi_poker_grid/jester_catalog_models.dart',
  'lib/logic/rummi_poker_grid/jester_scoring_models.dart',
  'lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart',
  'lib/logic/rummi_poker_grid/rummi_market_facade_views.dart',
  'lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart',
  'lib/logic/rummi_poker_grid/rummi_settlement_facade.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_battle_commands.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_market_commands.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_models.dart',
  'lib/providers/features/rummi_poker_grid/game_session_notifier_station_commands.dart',
  'lib/router.dart',
  'lib/services/active_run_save_codec.dart',
  'lib/services/active_run_save_facade.dart',
  'lib/services/blind_selection_spec.dart',
  'lib/services/new_run_setup.dart',
  'lib/utils/common_ui.dart',
  'lib/views/archive/archive_collection_widgets.dart',
  'lib/views/archive/archive_detail_widgets.dart',
  'lib/views/archive/archive_memory_cards.dart',
  'lib/views/archive_view.dart',
  'lib/views/blind_select_view.dart',
  'lib/views/game/game_view_battle_actions.dart',
  'lib/views/game/game_view_battle_widgets.dart',
  'lib/views/game/game_view_dialog_routes.dart',
  'lib/views/game/game_view_fate_selection_preview.dart',
  'lib/views/game/game_view_fate_selection_widgets.dart',
  'lib/views/game/game_view_item_effect_widgets.dart',
  'lib/views/game/game_view_layout_widgets.dart',
  'lib/views/game/game_view_run_end_flow.dart',
  'lib/views/game/game_view_stage_flow.dart',
  'lib/views/game/game_view_transition_overlays.dart',
  'lib/views/game/widgets/game_bookmark_slot_dialog.dart',
  'lib/views/game/widgets/game_cashout_presentation_widgets.dart',
  'lib/views/game/widgets/game_cashout_sheet_widgets.dart',
  'lib/views/game/widgets/game_cashout_widgets.dart',
  'lib/views/game/widgets/game_hand_zone.dart',
  'lib/views/game/widgets/game_jester_info_overlay.dart',
  'lib/views/game/widgets/game_jester_widgets.dart',
  'lib/views/game/widgets/game_options_dialog.dart',
  'lib/views/game/widgets/game_shared_battle_hud_widgets.dart',
  'lib/views/game/widgets/game_shared_game_over_widgets.dart',
  'lib/views/game/widgets/game_shared_hud_widgets.dart',
  'lib/views/game/widgets/game_shared_item_overlays.dart',
  'lib/views/game/widgets/game_shared_item_widgets.dart',
  'lib/views/game/widgets/game_shared_modal_widgets.dart',
  'lib/views/game/widgets/game_shared_tile_widgets.dart',
  'lib/views/game/widgets/game_shared_widgets.dart',
  'lib/views/game/widgets/game_shop_build_flow.dart',
  'lib/views/game/widgets/game_shop_control_widgets.dart',
  'lib/views/game/widgets/game_shop_detail_widgets.dart',
  'lib/views/game/widgets/game_shop_item_action_flow.dart',
  'lib/views/game/widgets/game_shop_offer_widgets.dart',
  'lib/views/game/widgets/game_shop_options_flow.dart',
  'lib/views/game/widgets/game_shop_purchase_flow.dart',
  'lib/views/game/widgets/game_shop_screen.dart',
  'lib/views/game/widgets/game_shop_text_helpers.dart',
  'lib/views/game/widgets/game_tile_choice_dialog.dart',
  'lib/views/game_view.dart',
  'lib/views/new_run_view.dart',
  'lib/views/title_view.dart',
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
}
