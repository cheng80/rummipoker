import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/new_run_setup.dart';

import 'bot_policy.dart';
import 'greedy_bot.dart';

const _balanceVersion = 'v4_pacing_baseline_1';
const _jesterCatalogPath = 'data/common/jesters_common_phase5.json';
const _itemCatalogPath = 'data/common/items_common_v1.json';

Future<void> main(List<String> args) async {
  final code = await runBalanceSim(args);
  if (code != 0) exitCode = code;
}

Future<int> runBalanceSim(List<String> args) async {
  try {
    final config = BalanceSimCliConfig.parse(args);
    final bot = _createBot(config.bot);
    final jesterCatalog = RummiJesterCatalog.fromJsonString(
      File(_jesterCatalogPath).readAsStringSync(),
    );
    final itemCatalog = ItemCatalog.fromJsonString(
      File(_itemCatalogPath).readAsStringSync(),
    );
    final output = File(config.outPath);
    output.parent.createSync(recursive: true);
    final sink = output.openWrite();
    try {
      for (var index = 0; index < config.runs; index++) {
        final row = _runSingleBattle(
          config: config,
          runIndex: index,
          bot: bot,
          jesterCatalog: jesterCatalog,
          itemCatalog: itemCatalog,
        );
        sink.writeln(jsonEncode(row));
      }
    } finally {
      await sink.close();
    }
    return 0;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(BalanceSimCliConfig.usage);
    return 64;
  } on Object catch (error) {
    stderr.writeln(error);
    return 1;
  }
}

Map<String, Object?> _runSingleBattle({
  required BalanceSimCliConfig config,
  required int runIndex,
  required BalanceSimBotPolicy bot,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final runSeed = config.seed + runIndex;
  final station = 1;
  final tier = BlindTier.small;
  final blindSpec = BlindSelectionSpecBuilder.resolveSpec(
    tier: tier,
    stationIndex: station,
    difficulty: NewRunDifficulty.standard,
    ruleset: RummiRuleset.currentDefaults,
  );
  final session = RummiPokerGridSession(runSeed: runSeed);
  final runProgress = RummiRunProgress();
  final ownedJesters = _resolveJesters(jesterCatalog, config.jesterIds);
  final inventory = _buildInventory(itemCatalog, config.itemIds);
  runProgress.ownedJesters.addAll(ownedJesters);
  runProgress.itemInventory = inventory;
  runProgress.startBlind(
    session,
    stationIndex: station,
    blindTierIndex: tier.index,
    shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(runSeed, station),
    targetScore: blindSpec.targetScore,
    boardDiscards: blindSpec.boardDiscards,
    handDiscards: blindSpec.handDiscards,
    maxHandSize: blindSpec.maxHandSize,
    applyRoundEndDecay: false,
  );

  final startState = <String, Object?>{
    'gold': runProgress.gold,
    'hands_remaining': session.deck.remaining,
    'board_discards': session.blind.boardDiscardsRemaining,
    'hand_discards': session.blind.handDiscardsRemaining,
    'board_moves': session.blind.boardMovesRemaining,
    'jester_ids': config.jesterIds,
    'item_ids': config.itemIds,
    'deck_size': session.totalDeckSize,
  };

  final result = _runBattleLoop(session, bot: bot, jesters: ownedJesters);

  return <String, Object?>{
    'schema_version': 1,
    'sim_id': 'local',
    'run_id': 'run_${runIndex.toString().padLeft(6, '0')}',
    'seed': runSeed,
    'bot_policy': bot.id,
    'app_version': 'dev',
    'balance_version': _balanceVersion,
    'ruleset_id': RummiRuleset.currentDefaults.persistenceId,
    'catalog_versions': <String, Object?>{
      'jester': 'jesters_common_phase5',
      'item': itemCatalog.catalogId,
    },
    'run_archetype_id': 'standard_tile_deck_v1',
    'tile_deck_composition_id': 'standard_52_v1',
    'tile_modifier_pool_id': null,
    'is_debug_run': false,
    'is_fixture': false,
    'station': station,
    'blind_tier': tier.name,
    'target_score': blindSpec.targetScore,
    'start_state': startState,
    'result': <String, Object?>{
      'cleared': result.cleared,
      'final_score': session.blind.scoreTowardBlind,
      'score_ratio': session.blind.scoreTowardBlind / blindSpec.targetScore,
      'turn_count': result.turnCount,
      'stop_reason': result.stopReason,
    },
  };
}

({bool cleared, int turnCount, String stopReason}) _runBattleLoop(
  RummiPokerGridSession session, {
  required BalanceSimBotPolicy bot,
  required List<RummiJesterCard> jesters,
}) {
  const turnCap = 300;
  for (var turn = 0; turn < turnCap; turn++) {
    if (session.blind.isTargetMet) {
      return (cleared: true, turnCount: turn, stopReason: 'cleared');
    }
    final expiry = session.evaluateExpirySignals();
    if (expiry.isNotEmpty) {
      return (
        cleared: false,
        turnCount: turn,
        stopReason: expiry.map((signal) => signal.name).join(','),
      );
    }

    final action = bot.chooseAction(session, jesters: jesters);
    switch (action.type) {
      case BalanceSimActionType.draw:
        session.drawToHand();
      case BalanceSimActionType.place:
        final handIndex = action.handIndex;
        final row = action.row;
        final col = action.col;
        if (handIndex == null || row == null || col == null) {
          return (
            cleared: false,
            turnCount: turn,
            stopReason: 'invalid_place_action',
          );
        }
        final tile = session.hand[handIndex];
        session.tryPlaceFromHand(tile, row, col);
      case BalanceSimActionType.confirm:
        session.confirmAllFullLines(jesters: jesters);
      case BalanceSimActionType.discardBoard:
        final row = action.row;
        final col = action.col;
        if (row == null || col == null) {
          return (
            cleared: false,
            turnCount: turn,
            stopReason: 'invalid_discard_action',
          );
        }
        session.tryDiscardFromBoard(row, col);
      case BalanceSimActionType.stop:
        return (
          cleared: false,
          turnCount: turn,
          stopReason: action.reason ?? 'stopped',
        );
    }
  }
  return (
    cleared: session.blind.isTargetMet,
    turnCount: turnCap,
    stopReason: 'turn_cap',
  );
}

List<RummiJesterCard> _resolveJesters(
  RummiJesterCatalog catalog,
  List<String> ids,
) {
  return [
    for (final id in ids)
      if (catalog.findById(id) case final card?)
        card
      else
        throw StateError('Unknown Jester id: $id'),
  ];
}

RunInventoryState _buildInventory(ItemCatalog catalog, List<String> ids) {
  var inventory = const RunInventoryState();
  for (final id in ids) {
    final item = catalog.findById(id);
    if (item == null) throw StateError('Unknown Item id: $id');
    inventory = inventory.withAcquiredItem(
      item,
      quickSlotCapacity: RunInventoryState.maxQuickSlotCapacity,
      passiveRelicCapacity: RunInventoryState.maxPassiveRelicCapacity,
    );
  }
  return inventory;
}

BalanceSimBotPolicy _createBot(String id) {
  return switch (id) {
    'greedy_v1' => const GreedyBotPolicy(),
    _ => throw FormatException('Unknown bot: $id'),
  };
}

class BalanceSimCliConfig {
  const BalanceSimCliConfig({
    required this.runs,
    required this.bot,
    required this.seed,
    required this.outPath,
    required this.jesterIds,
    required this.itemIds,
  });

  factory BalanceSimCliConfig.parse(List<String> args) {
    int? runs;
    String? bot;
    int? seed;
    String? outPath;
    final jesterIds = <String>[];
    final itemIds = <String>[];

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      String readValue() {
        if (index + 1 >= args.length) {
          throw FormatException('Missing value for $arg');
        }
        return args[++index];
      }

      switch (arg) {
        case '--runs':
          runs = int.tryParse(readValue());
        case '--bot':
          bot = readValue();
        case '--seed':
          seed = int.tryParse(readValue());
        case '--out':
          outPath = readValue();
        case '--jester':
          jesterIds.add(readValue());
        case '--item':
          itemIds.add(readValue());
        default:
          throw FormatException('Unknown argument: $arg');
      }
    }

    if (runs == null || runs <= 0) {
      throw const FormatException('--runs must be a positive integer');
    }
    if (bot == null || bot.isEmpty) {
      throw const FormatException('--bot is required');
    }
    if (seed == null) {
      throw const FormatException('--seed must be an integer');
    }
    if (outPath == null || outPath.isEmpty) {
      throw const FormatException('--out is required');
    }

    return BalanceSimCliConfig(
      runs: runs,
      bot: bot,
      seed: seed,
      outPath: outPath,
      jesterIds: List<String>.unmodifiable(jesterIds),
      itemIds: List<String>.unmodifiable(itemIds),
    );
  }

  static const usage =
      'Usage: dart run tools/sim/run_balance_sim.dart --runs 10 --bot greedy_v1 --seed 42 --out logs/sim_balance.jsonl [--jester id] [--item id]';

  final int runs;
  final String bot;
  final int seed;
  final String outPath;
  final List<String> jesterIds;
  final List<String> itemIds;
}
