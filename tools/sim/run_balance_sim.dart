import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/new_run_setup.dart';

import 'bot_policy.dart';
import 'greedy_bot.dart';
import 'planner_bot.dart';

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
    final summary = config.summaryOutPath == null
        ? null
        : BalanceSimSummaryAccumulator(sourcePath: config.outPath);
    try {
      final specs = config.runSpecs;
      for (final spec in specs) {
        for (var index = 0; index < config.runs; index++) {
          final row = _runSingleBattle(
            config: config,
            spec: spec,
            runIndex: index,
            bot: bot,
            jesterCatalog: jesterCatalog,
            itemCatalog: itemCatalog,
          );
          sink.writeln(jsonEncode(row));
          summary?.add(row);
        }
      }
    } finally {
      await sink.close();
    }
    final summaryOutPath = config.summaryOutPath;
    if (summaryOutPath != null && summary != null) {
      final summaryOutput = File(summaryOutPath);
      summaryOutput.parent.createSync(recursive: true);
      summaryOutput.writeAsStringSync(jsonEncode(summary.toJson()));
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

class BalanceSimSummaryAccumulator {
  BalanceSimSummaryAccumulator({required this.sourcePath});

  final String sourcePath;
  final Map<String, BalanceSimSummaryGroup> _groups = {};
  int _runCount = 0;

  void add(Map<String, Object?> row) {
    final result = row['result'] as Map<String, Object?>;
    final group = BalanceSimSummaryGroup(
      loadoutId: row['loadout_id'] as String,
      station: row['station'] as int,
      blindTier: row['blind_tier'] as String,
      difficulty: row['difficulty'] as String,
    );
    _runCount++;
    _groups
        .putIfAbsent(group.key, () => group)
        .addResult(
          cleared: result['cleared'] as bool,
          scoreRatio: result['score_ratio'] as num,
          turnCount: result['turn_count'] as int,
          outcomeLabel: result['outcome_label'] as String,
        );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': 1,
      'source_path': sourcePath,
      'run_count': _runCount,
      'group_by': ['loadout_id', 'station', 'blind_tier', 'difficulty'],
      'groups': _groups.values.map((group) => group.toJson()).toList(),
    };
  }
}

class BalanceSimSummaryGroup {
  BalanceSimSummaryGroup({
    required this.loadoutId,
    required this.station,
    required this.blindTier,
    required this.difficulty,
  });

  final String loadoutId;
  final int station;
  final String blindTier;
  final String difficulty;
  int runCount = 0;
  int clearCount = 0;
  double scoreRatioSum = 0;
  int turnCountSum = 0;
  final Map<String, int> outcomeCounts = {};

  String get key => '$loadoutId|$station|$blindTier|$difficulty';

  void addResult({
    required bool cleared,
    required num scoreRatio,
    required int turnCount,
    required String outcomeLabel,
  }) {
    runCount++;
    if (cleared) clearCount++;
    scoreRatioSum += scoreRatio.toDouble();
    turnCountSum += turnCount;
    outcomeCounts[outcomeLabel] = (outcomeCounts[outcomeLabel] ?? 0) + 1;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'loadout_id': loadoutId,
      'station': station,
      'blind_tier': blindTier,
      'difficulty': difficulty,
      'run_count': runCount,
      'clear_count': clearCount,
      'clear_rate': runCount == 0 ? 0 : clearCount / runCount,
      'avg_score_ratio': runCount == 0 ? 0 : scoreRatioSum / runCount,
      'avg_turn_count': runCount == 0 ? 0 : turnCountSum / runCount,
      'outcome_counts': outcomeCounts,
    };
  }
}

Map<String, Object?> _runSingleBattle({
  required BalanceSimCliConfig config,
  required BalanceSimRunSpec spec,
  required int runIndex,
  required BalanceSimBotPolicy bot,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final runSeed = config.seed + spec.matrixIndex * config.runs + runIndex;
  final station = spec.station;
  final tier = spec.blindTier;
  final blindSpec = BlindSelectionSpecBuilder.resolveSpec(
    tier: tier,
    stationIndex: station,
    difficulty: spec.difficulty,
    ruleset: RummiRuleset.currentDefaults,
  );
  final session = RummiPokerGridSession(runSeed: runSeed);
  final runProgress = RummiRunProgress();
  final ownedJesters = _resolveJesters(jesterCatalog, spec.loadout.jesterIds);
  final inventory = _buildInventory(itemCatalog, spec.loadout.itemIds);
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
  session.blind.bossModifier = blindSpec.bossModifier;
  ItemEffectRuntime.applyOwnedStationStartItems(
    catalog: itemCatalog,
    session: session,
    runProgress: runProgress,
  );

  final startState = <String, Object?>{
    'gold': runProgress.gold,
    'hands_remaining': session.deck.remaining,
    'board_discards': session.blind.boardDiscardsRemaining,
    'hand_discards': session.blind.handDiscardsRemaining,
    'board_moves': session.blind.boardMovesRemaining,
    'jester_ids': spec.loadout.jesterIds,
    'item_ids': spec.loadout.itemIds,
    'deck_size': session.totalDeckSize,
  };
  final loadoutSummary = _buildLoadoutSummary(
    jesters: ownedJesters,
    inventory: inventory,
    itemCatalog: itemCatalog,
  );

  final result = _runBattleLoop(
    session,
    turnCap: config.turnCap,
    runProgress: runProgress,
    bot: bot,
    jesters: ownedJesters,
    itemCatalog: itemCatalog,
  );
  final finalScore = session.blind.scoreTowardBlind;

  return <String, Object?>{
    'schema_version': 1,
    'sim_id': 'local',
    'run_id': _runId(
      runIndex: runIndex,
      matrixIndex: spec.matrixIndex,
      isMatrix: config.isMatrix,
    ),
    'matrix_index': spec.matrixIndex,
    'matrix_size': config.matrixSize,
    'loadout_id': spec.loadout.id,
    'seed': runSeed,
    'bot_policy': bot.id,
    'app_version': 'dev',
    'balance_version': _balanceVersion,
    'difficulty': spec.difficulty.name,
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
    'boss_modifier_id': blindSpec.bossModifier?.id,
    'boss_modifier_category': blindSpec.bossModifier?.category.name,
    'target_score': blindSpec.targetScore,
    'turn_cap': config.turnCap,
    'start_state': startState,
    'loadout_summary': loadoutSummary,
    'result': <String, Object?>{
      'cleared': result.cleared,
      'final_score': finalScore,
      'score_ratio': finalScore / blindSpec.targetScore,
      'score_margin': finalScore - blindSpec.targetScore,
      'turn_count': result.turnCount,
      'stop_reason': result.stopReason,
      'outcome_label': _outcomeLabel(
        cleared: result.cleared,
        stopReason: result.stopReason,
        finalScore: finalScore,
        targetScore: blindSpec.targetScore,
      ),
      'remaining_deck': session.deck.remaining,
      'remaining_hand_size': session.hand.length,
      'remaining_board_discards': session.blind.boardDiscardsRemaining,
      'remaining_hand_discards': session.blind.handDiscardsRemaining,
      'remaining_board_moves': session.blind.boardMovesRemaining,
      'board_occupancy': RummiPokerGridSession.countTilesOnBoard(session.board),
      'confirm_action_count': result.confirmActionCount,
      'confirmed_line_count': result.confirmedLineCount,
      'discarded_board_count': result.discardedBoardCount,
      'draw_count': result.drawCount,
      'place_count': result.placeCount,
      'max_single_confirm_score': result.maxSingleConfirmScore,
      'first_score_turn': result.firstScoreTurn,
      'last_score_turn': result.lastScoreTurn,
    },
  };
}

String _runId({
  required int runIndex,
  required int matrixIndex,
  required bool isMatrix,
}) {
  final runPart = runIndex.toString().padLeft(6, '0');
  if (!isMatrix) return 'run_$runPart';
  final matrixPart = matrixIndex.toString().padLeft(3, '0');
  return 'matrix_${matrixPart}_run_$runPart';
}

Map<String, Object?> _buildLoadoutSummary({
  required List<RummiJesterCard> jesters,
  required RunInventoryState inventory,
  required ItemCatalog itemCatalog,
}) {
  return <String, Object?>{
    'jester_count': jesters.length,
    'item_count': inventory.ownedItems.fold<int>(
      0,
      (sum, entry) => sum + entry.count,
    ),
    'jester_rarity_counts': _countBy(jesters, (jester) => jester.rarity.name),
    'jester_effect_type_counts': _countBy(
      jesters,
      (jester) => jester.effectType,
    ),
    'jester_trigger_counts': _countBy(jesters, (jester) => jester.trigger),
    'jester_condition_type_counts': _countBy(
      jesters,
      (jester) => jester.conditionType,
    ),
    'item_type_counts': _countByWeighted(
      inventory.ownedItems,
      (entry) => itemCatalog.findById(entry.itemId)?.type.name ?? 'unknown',
      (entry) => entry.count,
    ),
    'item_rarity_counts': _countByWeighted(
      inventory.ownedItems,
      (entry) => itemCatalog.findById(entry.itemId)?.rarity.name ?? 'unknown',
      (entry) => entry.count,
    ),
    'item_placement_counts': _countByWeighted(
      inventory.ownedItems,
      (entry) => entry.placement.name,
      (entry) => entry.count,
    ),
    'item_effect_timing_counts': _countByWeighted(
      inventory.ownedItems,
      (entry) => itemCatalog.findById(entry.itemId)?.effect.timing ?? 'unknown',
      (entry) => entry.count,
    ),
    'item_effect_op_counts': _countByWeighted(
      inventory.ownedItems,
      (entry) => itemCatalog.findById(entry.itemId)?.effect.op ?? 'unknown',
      (entry) => entry.count,
    ),
    'item_tag_counts': _countTags(inventory, itemCatalog),
  };
}

Map<String, int> _countBy<T>(
  Iterable<T> values,
  String Function(T value) keyOf,
) {
  final counts = <String, int>{};
  for (final value in values) {
    final key = keyOf(value);
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> _countByWeighted<T>(
  Iterable<T> values,
  String Function(T value) keyOf,
  int Function(T value) weightOf,
) {
  final counts = <String, int>{};
  for (final value in values) {
    final key = keyOf(value);
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + weightOf(value);
  }
  return counts;
}

Map<String, int> _countTags(
  RunInventoryState inventory,
  ItemCatalog itemCatalog,
) {
  final counts = <String, int>{};
  for (final entry in inventory.ownedItems) {
    final item = itemCatalog.findById(entry.itemId);
    if (item == null) continue;
    for (final tag in item.tags) {
      counts[tag] = (counts[tag] ?? 0) + entry.count;
    }
  }
  return counts;
}

BalanceSimBattleResult _runBattleLoop(
  RummiPokerGridSession session, {
  required int turnCap,
  required RummiRunProgress runProgress,
  required BalanceSimBotPolicy bot,
  required List<RummiJesterCard> jesters,
  required ItemCatalog itemCatalog,
}) {
  var confirmedLineCount = 0;
  var confirmActionCount = 0;
  var discardedBoardCount = 0;
  var drawCount = 0;
  var placeCount = 0;
  var maxSingleConfirmScore = 0;
  int? firstScoreTurn;
  int? lastScoreTurn;

  BalanceSimBattleResult finish({
    required bool cleared,
    required int turnCount,
    required String stopReason,
  }) {
    return BalanceSimBattleResult(
      cleared: cleared,
      turnCount: turnCount,
      stopReason: stopReason,
      confirmActionCount: confirmActionCount,
      confirmedLineCount: confirmedLineCount,
      discardedBoardCount: discardedBoardCount,
      drawCount: drawCount,
      placeCount: placeCount,
      maxSingleConfirmScore: maxSingleConfirmScore,
      firstScoreTurn: firstScoreTurn,
      lastScoreTurn: lastScoreTurn,
    );
  }

  for (var turn = 0; turn < turnCap; turn++) {
    if (session.blind.isTargetMet) {
      return finish(cleared: true, turnCount: turn, stopReason: 'cleared');
    }
    final expiry = session.evaluateExpirySignals();
    if (expiry.isNotEmpty) {
      final guardResults = ItemEffectRuntime.applyOwnedExpiryGuardItems(
        catalog: itemCatalog,
        session: session,
        runProgress: runProgress,
        signals: expiry,
      );
      final rescued = guardResults.any(
        (result) =>
            result.isSuccess &&
            result.events.any(
              (event) => event.kind == ItemEffectEventKind.expiryGuardTriggered,
            ),
      );
      if (rescued) continue;
      return finish(
        cleared: false,
        turnCount: turn,
        stopReason: expiry.map((signal) => signal.name).join(','),
      );
    }

    final action = bot.chooseAction(
      session,
      jesters: jesters,
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
    );
    switch (action.type) {
      case BalanceSimActionType.draw:
        if (session.drawToHand() != null) {
          drawCount++;
        }
      case BalanceSimActionType.place:
        final handIndex = action.handIndex;
        final row = action.row;
        final col = action.col;
        if (handIndex == null || row == null || col == null) {
          return finish(
            cleared: false,
            turnCount: turn,
            stopReason: 'invalid_place_action',
          );
        }
        final tile = session.hand[handIndex];
        if (session.tryPlaceFromHand(tile, row, col)) {
          placeCount++;
        }
      case BalanceSimActionType.confirm:
        final scoreBefore = session.blind.scoreTowardBlind;
        final out = session.confirmAllFullLines(
          jesters: jesters,
          runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
        );
        if (out.result.ok) {
          confirmActionCount++;
          confirmedLineCount += out.result.lineBreakdowns.length;
          final scoreDelta = session.blind.scoreTowardBlind - scoreBefore;
          if (scoreDelta > 0) {
            maxSingleConfirmScore = scoreDelta > maxSingleConfirmScore
                ? scoreDelta
                : maxSingleConfirmScore;
            firstScoreTurn ??= turn;
            lastScoreTurn = turn;
          }
          runProgress.onConfirmedLines(out.result.lineBreakdowns);
        }
      case BalanceSimActionType.discardBoard:
        final row = action.row;
        final col = action.col;
        if (row == null || col == null) {
          return finish(
            cleared: false,
            turnCount: turn,
            stopReason: 'invalid_discard_action',
          );
        }
        final discard = session.tryDiscardFromBoard(row, col);
        if (discard.fail == null) {
          discardedBoardCount++;
        }
      case BalanceSimActionType.stop:
        return finish(
          cleared: false,
          turnCount: turn,
          stopReason: action.reason ?? 'stopped',
        );
    }
  }
  return finish(
    cleared: session.blind.isTargetMet,
    turnCount: turnCap,
    stopReason: 'turn_cap',
  );
}

String _outcomeLabel({
  required bool cleared,
  required String stopReason,
  required int finalScore,
  required int targetScore,
}) {
  if (cleared) return 'clear';
  if (stopReason.contains(RummiExpirySignal.boardFullAfterDcExhausted.name)) {
    return 'board_locked';
  }
  if (stopReason.contains(RummiExpirySignal.drawPileExhausted.name)) {
    return 'deck_exhausted';
  }
  if (stopReason == 'turn_cap') return 'turn_cap';
  if (stopReason.startsWith('invalid_')) return 'invalid_action';
  if (finalScore < targetScore) return 'score_shortfall';
  return 'stopped';
}

class BalanceSimBattleResult {
  const BalanceSimBattleResult({
    required this.cleared,
    required this.turnCount,
    required this.stopReason,
    required this.confirmActionCount,
    required this.confirmedLineCount,
    required this.discardedBoardCount,
    required this.drawCount,
    required this.placeCount,
    required this.maxSingleConfirmScore,
    required this.firstScoreTurn,
    required this.lastScoreTurn,
  });

  final bool cleared;
  final int turnCount;
  final String stopReason;
  final int confirmActionCount;
  final int confirmedLineCount;
  final int discardedBoardCount;
  final int drawCount;
  final int placeCount;
  final int maxSingleConfirmScore;
  final int? firstScoreTurn;
  final int? lastScoreTurn;
}

class BalanceSimRunSpec {
  const BalanceSimRunSpec({
    required this.matrixIndex,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.loadout,
  });

  final int matrixIndex;
  final int station;
  final BlindTier blindTier;
  final NewRunDifficulty difficulty;
  final BalanceSimLoadoutSpec loadout;
}

class BalanceSimLoadoutSpec {
  const BalanceSimLoadoutSpec({
    required this.id,
    required this.jesterIds,
    required this.itemIds,
  });

  final String id;
  final List<String> jesterIds;
  final List<String> itemIds;
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
        throw FormatException('Unknown Jester id: $id'),
  ];
}

RunInventoryState _buildInventory(ItemCatalog catalog, List<String> ids) {
  var inventory = const RunInventoryState();
  for (final id in ids) {
    final item = catalog.findById(id);
    if (item == null) throw FormatException('Unknown Item id: $id');
    if (!inventory.canAcquire(
      item,
      quickSlotCapacity: RunInventoryState.maxQuickSlotCapacity,
      passiveRelicCapacity: RunInventoryState.maxPassiveRelicCapacity,
    )) {
      throw FormatException('Cannot add Item id due to inventory limits: $id');
    }
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
    'planner_v1' => const PlannerBotPolicy(),
    _ => throw FormatException('Unknown bot: $id'),
  };
}

class BalanceSimCliConfig {
  const BalanceSimCliConfig({
    required this.runs,
    required this.bot,
    required this.seed,
    required this.outPath,
    required this.summaryOutPath,
    required this.turnCap,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.stations,
    required this.blindTiers,
    required this.difficulties,
    required this.loadouts,
    required this.jesterIds,
    required this.itemIds,
  });

  factory BalanceSimCliConfig.parse(List<String> args) {
    int? runs;
    String? bot;
    int? seed;
    String? outPath;
    String? summaryOutPath;
    var turnCap = 300;
    var station = 1;
    var blindTier = BlindTier.small;
    var difficulty = NewRunDifficulty.standard;
    List<int>? stations;
    List<BlindTier>? blindTiers;
    List<NewRunDifficulty>? difficulties;
    final loadoutIds = <String>[];
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
        case '--summary-out':
          summaryOutPath = readValue();
        case '--turn-cap':
          final parsed = int.tryParse(readValue());
          if (parsed == null || parsed <= 0) {
            throw const FormatException(
              '--turn-cap must be a positive integer',
            );
          }
          turnCap = parsed;
        case '--station':
          final parsed = int.tryParse(readValue());
          if (parsed == null || parsed <= 0) {
            throw const FormatException('--station must be a positive integer');
          }
          station = parsed;
        case '--stations':
          stations = _parseStationList(readValue());
        case '--blind-tier':
          blindTier = _parseBlindTier(readValue());
        case '--blind-tiers':
          blindTiers = _parseBlindTierList(readValue());
        case '--difficulty':
          difficulty = _parseDifficulty(readValue());
        case '--difficulties':
          difficulties = _parseDifficultyList(readValue());
        case '--loadout-id':
          loadoutIds.add(readValue());
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
    if (summaryOutPath != null && summaryOutPath.isEmpty) {
      throw const FormatException('--summary-out cannot be empty');
    }
    if (loadoutIds.isNotEmpty && (jesterIds.isNotEmpty || itemIds.isNotEmpty)) {
      throw const FormatException(
        '--loadout-id cannot be combined with --jester or --item',
      );
    }

    return BalanceSimCliConfig(
      runs: runs,
      bot: bot,
      seed: seed,
      outPath: outPath,
      summaryOutPath: summaryOutPath,
      turnCap: turnCap,
      station: station,
      blindTier: blindTier,
      difficulty: difficulty,
      stations: List<int>.unmodifiable(stations ?? [station]),
      blindTiers: List<BlindTier>.unmodifiable(blindTiers ?? [blindTier]),
      difficulties: List<NewRunDifficulty>.unmodifiable(
        difficulties ?? [difficulty],
      ),
      loadouts: List<BalanceSimLoadoutSpec>.unmodifiable(
        loadoutIds.isEmpty
            ? [_manualLoadout(jesterIds: jesterIds, itemIds: itemIds)]
            : loadoutIds.map(_parseLoadoutPreset),
      ),
      jesterIds: List<String>.unmodifiable(jesterIds),
      itemIds: List<String>.unmodifiable(itemIds),
    );
  }

  static const usage =
      'Usage: dart run tools/sim/run_balance_sim.dart --runs 10 --bot greedy_v1|planner_v1 --seed 42 --out logs/sim_balance.jsonl [--summary-out logs/sim_summary.json] [--turn-cap n] [--station n|--stations 1,2] [--blind-tier small|--blind-tiers small,big,boss] [--difficulty standard|--difficulties relaxed,standard,pressure] [--loadout-id baseline|pair_mult|safety_item|score_abacus|mobility_item] [--jester id] [--item id]';

  static BlindTier _parseBlindTier(String raw) {
    return switch (raw) {
      'small' => BlindTier.small,
      'big' => BlindTier.big,
      'boss' => BlindTier.boss,
      _ => throw FormatException('Unknown blind tier: $raw'),
    };
  }

  static NewRunDifficulty _parseDifficulty(String raw) {
    return switch (raw) {
      'relaxed' => NewRunDifficulty.relaxed,
      'standard' => NewRunDifficulty.standard,
      'pressure' => NewRunDifficulty.pressure,
      _ => throw FormatException('Unknown difficulty: $raw'),
    };
  }

  static List<int> _parseStationList(String raw) {
    return _parseCommaSeparated(raw, '--stations')
        .map((value) {
          final parsed = int.tryParse(value);
          if (parsed == null || parsed <= 0) {
            throw FormatException('Invalid station in --stations: $value');
          }
          return parsed;
        })
        .toList(growable: false);
  }

  static List<BlindTier> _parseBlindTierList(String raw) {
    return _parseCommaSeparated(
      raw,
      '--blind-tiers',
    ).map(_parseBlindTier).toList(growable: false);
  }

  static List<NewRunDifficulty> _parseDifficultyList(String raw) {
    return _parseCommaSeparated(
      raw,
      '--difficulties',
    ).map(_parseDifficulty).toList(growable: false);
  }

  static List<String> _parseCommaSeparated(String raw, String argName) {
    final values = raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) {
      throw FormatException('$argName must include at least one value');
    }
    return values;
  }

  static BalanceSimLoadoutSpec _manualLoadout({
    required List<String> jesterIds,
    required List<String> itemIds,
  }) {
    final id = jesterIds.isEmpty && itemIds.isEmpty ? 'baseline' : 'manual';
    return BalanceSimLoadoutSpec(
      id: id,
      jesterIds: List<String>.unmodifiable(jesterIds),
      itemIds: List<String>.unmodifiable(itemIds),
    );
  }

  static BalanceSimLoadoutSpec _parseLoadoutPreset(String raw) {
    return switch (raw) {
      'baseline' => const BalanceSimLoadoutSpec(
        id: 'baseline',
        jesterIds: [],
        itemIds: [],
      ),
      'pair_mult' => const BalanceSimLoadoutSpec(
        id: 'pair_mult',
        jesterIds: ['jolly_jester', 'zany_jester'],
        itemIds: [],
      ),
      'safety_item' => const BalanceSimLoadoutSpec(
        id: 'safety_item',
        jesterIds: [],
        itemIds: ['safety_net'],
      ),
      'score_abacus' => const BalanceSimLoadoutSpec(
        id: 'score_abacus',
        jesterIds: [],
        itemIds: ['score_abacus'],
      ),
      'mobility_item' => const BalanceSimLoadoutSpec(
        id: 'mobility_item',
        jesterIds: [],
        itemIds: ['move_token', 'slide_wax'],
      ),
      _ => throw FormatException('Unknown loadout id: $raw'),
    };
  }

  final int runs;
  final String bot;
  final int seed;
  final String outPath;
  final String? summaryOutPath;
  final int turnCap;
  final int station;
  final BlindTier blindTier;
  final NewRunDifficulty difficulty;
  final List<int> stations;
  final List<BlindTier> blindTiers;
  final List<NewRunDifficulty> difficulties;
  final List<BalanceSimLoadoutSpec> loadouts;
  final List<String> jesterIds;
  final List<String> itemIds;

  int get matrixSize =>
      stations.length *
      blindTiers.length *
      difficulties.length *
      loadouts.length;

  bool get isMatrix => matrixSize > 1;

  List<BalanceSimRunSpec> get runSpecs {
    final specs = <BalanceSimRunSpec>[];
    var matrixIndex = 0;
    for (final station in stations) {
      for (final blindTier in blindTiers) {
        for (final difficulty in difficulties) {
          for (final loadout in loadouts) {
            specs.add(
              BalanceSimRunSpec(
                matrixIndex: matrixIndex++,
                station: station,
                blindTier: blindTier,
                difficulty: difficulty,
                loadout: loadout,
              ),
            );
          }
        }
      }
    }
    return List<BalanceSimRunSpec>.unmodifiable(specs);
  }
}
