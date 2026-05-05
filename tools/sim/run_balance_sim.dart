import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_definition.dart';
import 'package:rummipoker/logic/rummi_poker_grid/item_effect_runtime.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
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
const _balatroBacklogPath =
    'logs/research/rummi_balatro_adaptation_backlog.json';
const _slowClearTurnThreshold = 130;

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
      if (config.sequenceMode == BalanceSimSequenceMode.none) {
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
      } else {
        final specs = config.sequenceRunSpecs;
        for (final spec in specs) {
          for (var index = 0; index < config.runs; index++) {
            final sequence = _runStationPathSequence(
              config: config,
              spec: spec,
              runIndex: index,
              bot: bot,
              jesterCatalog: jesterCatalog,
              itemCatalog: itemCatalog,
            );
            for (final row in sequence.battleRows) {
              sink.writeln(jsonEncode(row));
              summary?.add(row);
            }
            sink.writeln(jsonEncode(sequence.summaryRow));
            summary?.add(sequence.summaryRow);
          }
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
  final Map<String, BalanceSimSequenceSummaryGroup> _sequenceGroups = {};
  int _runCount = 0;
  int _sequenceRunCount = 0;

  void add(Map<String, Object?> row) {
    if (row['row_type'] == 'sequence_summary') {
      final group = BalanceSimSequenceSummaryGroup(
        experimentId: row['experiment_id'] as String,
        marketProfile: (row['market_profile'] as String?) ?? 'none',
        resolvedMarketProfile:
            (row['resolved_market_profile'] as String?) ?? 'none',
        loadoutId: row['loadout_id'] as String,
        runModifierId: row['run_modifier_id'] as String? ?? 'basic',
        difficulty: row['difficulty'] as String,
        stationPath: (row['station_path'] as List<dynamic>)
            .map((station) => station as int)
            .toList(growable: false),
        tierPath: (row['tier_path'] as List<dynamic>)
            .map((tier) => tier as String)
            .toList(growable: false),
      );
      _sequenceRunCount++;
      _sequenceGroups
          .putIfAbsent(group.key, () => group)
          .addResult(
            pathCleared: row['path_cleared'] as bool,
            attemptedStepCount: row['attempted_step_count'] as int,
            clearedStepCount: row['cleared_step_count'] as int,
            failedAtStation: row['failed_at_station'] as int?,
            failedAtTier: row['failed_at_tier'] as String?,
            failureStopReason: row['failure_stop_reason'] as String?,
            totalTurnCount: row['total_turn_count'] as int,
            totalScoreRatio: row['total_score_ratio'] as num,
          );
      return;
    }

    final result = row['result'] as Map<String, Object?>;
    final group = BalanceSimSummaryGroup(
      experimentId: row['experiment_id'] as String,
      marketProfile: (row['market_profile'] as String?) ?? 'none',
      resolvedMarketProfile:
          (row['resolved_market_profile'] as String?) ?? 'none',
      loadoutId: row['loadout_id'] as String,
      runModifierId: row['run_modifier_id'] as String? ?? 'basic',
      station: row['station'] as int,
      blindTier: row['blind_tier'] as String,
      difficulty: row['difficulty'] as String,
      simBossConstraintId: _simBossConstraintIdFromEffects(
        row['experiment_effects'],
      ),
    );
    _runCount++;
    _groups
        .putIfAbsent(group.key, () => group)
        .addResult(
          cleared: result['cleared'] as bool,
          scoreRatio: result['score_ratio'] as num,
          turnCount: result['turn_count'] as int,
          confirmActionCount: result['confirm_action_count'] as int,
          discardedBoardCount: result['discarded_board_count'] as int,
          maxSingleConfirmScore: result['max_single_confirm_score'] as int,
          firstScoreTurn: result['first_score_turn'] as int?,
          lastScoreTurn: result['last_score_turn'] as int?,
          remainingDeck: result['remaining_deck'] as int,
          remainingHandSize: result['remaining_hand_size'] as int,
          remainingBoardDiscards: result['remaining_board_discards'] as int,
          remainingHandDiscards: result['remaining_hand_discards'] as int,
          remainingBoardMoves: result['remaining_board_moves'] as int,
          boardOccupancy: result['board_occupancy'] as int,
          outcomeLabel: result['outcome_label'] as String,
          isSlowClear: result['is_slow_clear'] as bool,
          clearTempoLabel: result['clear_tempo_label'] as String,
          marketShopSlots:
              (row['market_shop_slots'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const [],
        );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': 1,
      'source_path': sourcePath,
      'run_count': _runCount,
      'sequence_run_count': _sequenceRunCount,
      'group_by': [
        'experiment_id',
        'market_profile',
        'resolved_market_profile',
        'loadout_id',
        'run_modifier_id',
        'station',
        'blind_tier',
        'difficulty',
        'sim_boss_constraint_id',
      ],
      'sequence_group_by': [
        'experiment_id',
        'market_profile',
        'resolved_market_profile',
        'loadout_id',
        'run_modifier_id',
        'difficulty',
        'station_path',
        'tier_path',
      ],
      'groups': _groups.values.map((group) => group.toJson()).toList(),
      'sequence_groups': _sequenceGroups.values
          .map((group) => group.toJson())
          .toList(),
    };
  }
}

class BalanceSimSequenceSummaryGroup {
  BalanceSimSequenceSummaryGroup({
    required this.experimentId,
    required this.marketProfile,
    required this.resolvedMarketProfile,
    required this.loadoutId,
    required this.runModifierId,
    required this.difficulty,
    required this.stationPath,
    required this.tierPath,
  });

  final String experimentId;
  final String marketProfile;
  final String resolvedMarketProfile;
  final String loadoutId;
  final String runModifierId;
  final String difficulty;
  final List<int> stationPath;
  final List<String> tierPath;
  int runCount = 0;
  int pathClearCount = 0;
  int attemptedStepCountSum = 0;
  int clearedStepCountSum = 0;
  int totalTurnCountSum = 0;
  int clearPathTurnCountSum = 0;
  int failedPathTurnCountSum = 0;
  double totalScoreRatioSum = 0;
  final Map<String, int> failureCounts = {};
  final Map<String, int> failureStopReasonCounts = {};

  String get key =>
      '$experimentId|$marketProfile|$resolvedMarketProfile|$loadoutId|'
      '$runModifierId|$difficulty|${stationPath.join(',')}|'
      '${tierPath.join(',')}';

  void addResult({
    required bool pathCleared,
    required int attemptedStepCount,
    required int clearedStepCount,
    required int? failedAtStation,
    required String? failedAtTier,
    required String? failureStopReason,
    required int totalTurnCount,
    required num totalScoreRatio,
  }) {
    runCount++;
    if (pathCleared) pathClearCount++;
    attemptedStepCountSum += attemptedStepCount;
    clearedStepCountSum += clearedStepCount;
    totalTurnCountSum += totalTurnCount;
    if (pathCleared) {
      clearPathTurnCountSum += totalTurnCount;
    } else {
      failedPathTurnCountSum += totalTurnCount;
    }
    totalScoreRatioSum += totalScoreRatio.toDouble();
    if (!pathCleared) {
      final failureKey = failedAtStation == null || failedAtTier == null
          ? 'unknown'
          : 'S$failedAtStation $failedAtTier';
      failureCounts[failureKey] = (failureCounts[failureKey] ?? 0) + 1;
      final reasonKey = failureStopReason ?? 'unknown';
      failureStopReasonCounts[reasonKey] =
          (failureStopReasonCounts[reasonKey] ?? 0) + 1;
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'experiment_id': experimentId,
      'market_profile': marketProfile,
      'resolved_market_profile': resolvedMarketProfile,
      'loadout_id': loadoutId,
      'run_modifier_id': runModifierId,
      'difficulty': difficulty,
      'station_path': stationPath,
      'tier_path': tierPath,
      'run_count': runCount,
      'path_clear_count': pathClearCount,
      'path_clear_rate': runCount == 0 ? 0 : pathClearCount / runCount,
      'avg_attempted_step_count': runCount == 0
          ? 0
          : attemptedStepCountSum / runCount,
      'avg_cleared_step_count': runCount == 0
          ? 0
          : clearedStepCountSum / runCount,
      'avg_total_turn_count': runCount == 0 ? 0 : totalTurnCountSum / runCount,
      'avg_clear_path_turn_count': pathClearCount == 0
          ? 0
          : clearPathTurnCountSum / pathClearCount,
      'avg_failed_path_turn_count': runCount == pathClearCount
          ? 0
          : failedPathTurnCountSum / (runCount - pathClearCount),
      'avg_turn_per_attempted_step': attemptedStepCountSum == 0
          ? 0
          : totalTurnCountSum / attemptedStepCountSum,
      'avg_turn_per_cleared_step': clearedStepCountSum == 0
          ? 0
          : totalTurnCountSum / clearedStepCountSum,
      'avg_total_score_ratio': runCount == 0
          ? 0
          : totalScoreRatioSum / runCount,
      'failure_counts': failureCounts,
      'failure_stop_reason_counts': failureStopReasonCounts,
    };
  }
}

String? _simBossConstraintIdFromEffects(Object? rawEffects) {
  if (rawEffects is! Map) return null;
  final id = rawEffects['sim_boss_constraint_id'];
  return id is String ? id : null;
}

class BalanceSimSummaryGroup {
  BalanceSimSummaryGroup({
    required this.experimentId,
    required this.marketProfile,
    required this.resolvedMarketProfile,
    required this.loadoutId,
    required this.runModifierId,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.simBossConstraintId,
  });

  final String experimentId;
  final String marketProfile;
  final String resolvedMarketProfile;
  final String loadoutId;
  final String runModifierId;
  final int station;
  final String blindTier;
  final String difficulty;
  final String? simBossConstraintId;
  int runCount = 0;
  int clearCount = 0;
  double scoreRatioSum = 0;
  int turnCountSum = 0;
  int confirmActionCountSum = 0;
  int discardedBoardCountSum = 0;
  int maxSingleConfirmScoreSum = 0;
  int firstScoreTurnSum = 0;
  int lastScoreTurnSum = 0;
  int scoredRunCount = 0;
  int remainingDeckSum = 0;
  int remainingHandSizeSum = 0;
  int remainingBoardDiscardsSum = 0;
  int remainingHandDiscardsSum = 0;
  int remainingBoardMovesSum = 0;
  int boardOccupancySum = 0;
  int slowClearCount = 0;
  final Map<String, int> outcomeCounts = {};
  final Map<String, int> clearTempoLabelCounts = {};
  final Map<String, int> marketShopSlotCounts = {};

  String get key =>
      '$experimentId|$marketProfile|$resolvedMarketProfile|$loadoutId|'
      '$runModifierId|$station|$blindTier|$difficulty|'
      '${simBossConstraintId ?? 'none'}';

  void addResult({
    required bool cleared,
    required num scoreRatio,
    required int turnCount,
    required int confirmActionCount,
    required int discardedBoardCount,
    required int maxSingleConfirmScore,
    required int? firstScoreTurn,
    required int? lastScoreTurn,
    required int remainingDeck,
    required int remainingHandSize,
    required int remainingBoardDiscards,
    required int remainingHandDiscards,
    required int remainingBoardMoves,
    required int boardOccupancy,
    required String outcomeLabel,
    required bool isSlowClear,
    required String clearTempoLabel,
    required List<String> marketShopSlots,
  }) {
    runCount++;
    if (cleared) clearCount++;
    if (isSlowClear) slowClearCount++;
    scoreRatioSum += scoreRatio.toDouble();
    turnCountSum += turnCount;
    confirmActionCountSum += confirmActionCount;
    discardedBoardCountSum += discardedBoardCount;
    maxSingleConfirmScoreSum += maxSingleConfirmScore;
    if (firstScoreTurn != null && lastScoreTurn != null) {
      scoredRunCount++;
      firstScoreTurnSum += firstScoreTurn;
      lastScoreTurnSum += lastScoreTurn;
    }
    remainingDeckSum += remainingDeck;
    remainingHandSizeSum += remainingHandSize;
    remainingBoardDiscardsSum += remainingBoardDiscards;
    remainingHandDiscardsSum += remainingHandDiscards;
    remainingBoardMovesSum += remainingBoardMoves;
    boardOccupancySum += boardOccupancy;
    outcomeCounts[outcomeLabel] = (outcomeCounts[outcomeLabel] ?? 0) + 1;
    clearTempoLabelCounts[clearTempoLabel] =
        (clearTempoLabelCounts[clearTempoLabel] ?? 0) + 1;
    for (final slot in marketShopSlots) {
      marketShopSlotCounts[slot] = (marketShopSlotCounts[slot] ?? 0) + 1;
    }
  }

  Map<String, Object?> toJson() {
    final avgTurnCount = runCount == 0 ? 0 : turnCountSum / runCount;
    final clearRate = runCount == 0 ? 0 : clearCount / runCount;
    final slowClearRate = runCount == 0 ? 0 : slowClearCount / runCount;
    final slowClearShareOfClears = clearCount == 0
        ? 0
        : slowClearCount / clearCount;
    final avgScoreRatio = runCount == 0 ? 0 : scoreRatioSum / runCount;
    final avgMaxSingleConfirmScore = runCount == 0
        ? 0
        : maxSingleConfirmScoreSum / runCount;
    final avgConfirmActionCount = runCount == 0
        ? 0
        : confirmActionCountSum / runCount;
    final avgDiscardedBoardCount = runCount == 0
        ? 0
        : discardedBoardCountSum / runCount;
    final avgLastScoreTurn = scoredRunCount == 0
        ? null
        : lastScoreTurnSum / scoredRunCount;
    final avgRemainingDeck = runCount == 0 ? 0 : remainingDeckSum / runCount;
    final avgRemainingBoardDiscards = runCount == 0
        ? 0
        : remainingBoardDiscardsSum / runCount;
    final avgRemainingHandDiscards = runCount == 0
        ? 0
        : remainingHandDiscardsSum / runCount;
    final avgRemainingBoardMoves = runCount == 0
        ? 0
        : remainingBoardMovesSum / runCount;
    final tempoRiskLabel = _tempoRiskLabel(
      slowClearCount: slowClearCount,
      clearCount: clearCount,
      avgTurnCount: avgTurnCount,
    );
    final mlLabels = _mlLabelV1(
      clearRate: clearRate,
      avgScoreRatio: avgScoreRatio,
      avgTurnCount: avgTurnCount,
      avgMaxSingleConfirmScore: avgMaxSingleConfirmScore,
      avgLastScoreTurn: avgLastScoreTurn,
      tempoRiskLabel: tempoRiskLabel,
      outcomeCounts: outcomeCounts,
    );
    final mlTargetLabelsV2 = _mlTargetLabelsV2(
      clearRate: clearRate,
      avgScoreRatio: avgScoreRatio,
      avgTurnCount: avgTurnCount,
      avgConfirmActionCount: avgConfirmActionCount,
      avgMaxSingleConfirmScore: avgMaxSingleConfirmScore,
      avgLastScoreTurn: avgLastScoreTurn,
      avgRemainingDeck: avgRemainingDeck,
      avgRemainingBoardDiscards: avgRemainingBoardDiscards,
      avgRemainingHandDiscards: avgRemainingHandDiscards,
      avgRemainingBoardMoves: avgRemainingBoardMoves,
      tempoRiskLabel: tempoRiskLabel,
      outcomeCounts: outcomeCounts,
    );
    return <String, Object?>{
      'experiment_id': experimentId,
      'market_profile': marketProfile,
      'resolved_market_profile': resolvedMarketProfile,
      'loadout_id': loadoutId,
      'run_modifier_id': runModifierId,
      'station': station,
      'blind_tier': blindTier,
      'difficulty': difficulty,
      'sim_boss_constraint_id': simBossConstraintId,
      'run_count': runCount,
      'clear_count': clearCount,
      'slow_clear_count': slowClearCount,
      'clear_rate': clearRate,
      'slow_clear_rate': slowClearRate,
      'slow_clear_share_of_clears': slowClearShareOfClears,
      'slow_clear_turn_threshold': _slowClearTurnThreshold,
      'tempo_risk_label': tempoRiskLabel,
      'ml_label_version': 'ml_label_v1',
      'ml_labels': mlLabels,
      'needs_balance_attention': mlLabels.contains('needs_balance_attention'),
      'ml_label_v2_version': 'ml_label_v2',
      'ml_target_labels_v2': mlTargetLabelsV2,
      'needs_balance_attention_v2': _needsBalanceAttentionV2(mlTargetLabelsV2),
      'avg_score_ratio': avgScoreRatio,
      'avg_turn_count': avgTurnCount,
      'avg_confirm_action_count': avgConfirmActionCount,
      'avg_discarded_board_count': avgDiscardedBoardCount,
      'avg_max_single_confirm_score': avgMaxSingleConfirmScore,
      'scored_run_count': scoredRunCount,
      'avg_first_score_turn': scoredRunCount == 0
          ? null
          : firstScoreTurnSum / scoredRunCount,
      'avg_last_score_turn': avgLastScoreTurn,
      'avg_remaining_deck': avgRemainingDeck,
      'avg_remaining_hand_size': runCount == 0
          ? 0
          : remainingHandSizeSum / runCount,
      'avg_remaining_board_discards': avgRemainingBoardDiscards,
      'avg_remaining_hand_discards': avgRemainingHandDiscards,
      'avg_remaining_board_moves': avgRemainingBoardMoves,
      'avg_board_occupancy': runCount == 0 ? 0 : boardOccupancySum / runCount,
      'outcome_counts': outcomeCounts,
      'clear_tempo_label_counts': clearTempoLabelCounts,
      'market_shop_slot_counts': marketShopSlotCounts,
    };
  }
}

BalanceSimSequenceOutput _runStationPathSequence({
  required BalanceSimCliConfig config,
  required BalanceSimSequenceRunSpec spec,
  required int runIndex,
  required BalanceSimBotPolicy bot,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final battleRows = <Map<String, Object?>>[];
  final stationPath = spec.stations;
  final tierPath = const [BlindTier.small, BlindTier.big, BlindTier.boss];
  final sequenceStepCount = stationPath.length * tierPath.length;
  final sequenceRunId = _sequenceRunId(
    matrixIndex: spec.matrixIndex,
    runIndex: runIndex,
  );
  final baseMarketSelection = _resolveSequenceMarketSelection(
    marketProfile: spec.marketProfile,
    seed: config.seed + spec.matrixIndex * config.runs + runIndex,
    loadout: spec.loadout,
  );
  var stepIndex = 0;
  Map<String, Object?>? previousStepResourceState;
  var clearedStepCount = 0;
  var totalTurnCount = 0;
  var totalScore = 0;
  var totalTargetScore = 0;
  var simEconomyGold = 0;
  var simEconomyCashoutGold = 0;
  var simEconomyKnownMarketSpend = 0;
  var simEconomyRerollSpend = 0;
  var simEconomySellRecovery = 0;
  var simEconomyMissingCostEvents = 0;
  var simEconomyUnaffordableEvents = 0;
  var simEconomySlotReplaceEvents = 0;
  int? failedAtStation;
  String? failedAtTier;
  int? failedStepIndex;
  String? failureStopReason;

  for (final station in stationPath) {
    for (final tier in tierPath) {
      final marketSelection = _resolveSequenceStepMarketSelection(
        baseSelection: baseMarketSelection,
        marketProfile: spec.marketProfile,
        runModifier: config.runModifier,
        seed:
            config.seed +
            spec.matrixIndex * config.runs +
            runIndex +
            stepIndex * 37,
        loadout: spec.loadout,
        station: station,
        tier: tier,
        previousStepResourceState: previousStepResourceState,
      );
      var resolvedMarketProfile = marketSelection.profile;
      final stationBaseLoadout = _stationRouteLoadout(
        baseLoadout: spec.loadout,
        station: station,
      );
      final economyBeforeMarket = simEconomyGold;
      var economyKnownSpendThisStep = 0;
      var economyRerollSpendThisStep = 0;
      var economySellRecoveryThisStep = 0;
      var economyMissingCostThisStep = 0;
      var economyUnaffordableThisStep = 0;
      var economySlotReplaceThisStep = 0;
      var marketEventsAffordable = true;
      final marketBudget = _simMarketBudgetForStep(
        mode: config.simMarketBudgetMode,
        station: station,
        currentGold: simEconomyGold,
      );
      var remainingMarketBudget = marketBudget;
      final rerollSpend = _simMarketRerollSpendForStep(
        mode: config.simMarketSpendMode,
        station: station,
        tier: tier,
      );
      if (rerollSpend > 0) {
        final resolvedRerollSpend = min(simEconomyGold, rerollSpend);
        simEconomyGold -= resolvedRerollSpend;
        economyRerollSpendThisStep += resolvedRerollSpend;
        economyKnownSpendThisStep += resolvedRerollSpend;
      }
      resolvedMarketProfile = _resolveAffordableMarketProfile(
        mode: config.simMarketChoiceMode,
        currentProfile: resolvedMarketProfile,
        shopSlots: marketSelection.shopSlots,
        station: station,
        tier: tier,
        loadout: stationBaseLoadout,
        currentGold: simEconomyGold,
        remainingMarketBudget: remainingMarketBudget,
        simPriceScale: config.simPriceScale,
        simPriceBandMode: config.simPriceBandMode,
        simMarketSpendMode: config.simMarketSpendMode,
        jesterCatalog: jesterCatalog,
        itemCatalog: itemCatalog,
      );
      final marketPurchaseEvents = _sequenceMarketPurchaseEvents(
        marketProfile: resolvedMarketProfile,
        sourceCandidate: marketSelection.sourceCandidate,
        jesterCatalog: jesterCatalog,
        itemCatalog: itemCatalog,
        loadout: stationBaseLoadout,
      );
      for (final event in marketPurchaseEvents) {
        final cost = event['cost'];
        if (cost is! num) {
          economyMissingCostThisStep += 1;
          marketEventsAffordable = false;
          continue;
        }
        final resolvedCost = (cost * config.simPriceScale).round();
        final bandedCost = _simPriceBandCostForEvent(
          mode: config.simPriceBandMode,
          event: event,
          fallbackCost: resolvedCost,
        );
        if (bandedCost <= 0) continue;
        final slotReplacement = _simMarketSlotReplacementForEvent(
          mode: config.simMarketSpendMode,
          event: event,
          loadout: stationBaseLoadout,
          jesterCatalog: jesterCatalog,
          itemCatalog: itemCatalog,
        );
        if (slotReplacement.replaced) {
          simEconomyGold += slotReplacement.sellRecovery;
          economySellRecoveryThisStep += slotReplacement.sellRecovery;
          economySlotReplaceThisStep += 1;
        }
        final withinBudget =
            remainingMarketBudget == null ||
            remainingMarketBudget >= bandedCost;
        if (simEconomyGold >= bandedCost && withinBudget) {
          simEconomyGold -= bandedCost;
          if (remainingMarketBudget != null) {
            remainingMarketBudget -= bandedCost;
          }
          economyKnownSpendThisStep += bandedCost;
        } else {
          economyUnaffordableThisStep += 1;
          marketEventsAffordable = false;
        }
      }
      simEconomyKnownMarketSpend += economyKnownSpendThisStep;
      simEconomyRerollSpend += economyRerollSpendThisStep;
      simEconomySellRecovery += economySellRecoveryThisStep;
      simEconomyMissingCostEvents += economyMissingCostThisStep;
      simEconomyUnaffordableEvents += economyUnaffordableThisStep;
      simEconomySlotReplaceEvents += economySlotReplaceThisStep;
      final appliedMarketProfile =
          config.simEconomyMode == BalanceSimEconomyMode.gatedKnownCost &&
              !marketEventsAffordable
          ? BalanceSimMarketProfile.none
          : resolvedMarketProfile;
      final effectiveLoadout = _sequenceEffectiveLoadout(
        baseLoadout: spec.loadout,
        station: station,
        marketProfile: appliedMarketProfile,
        loadoutIdMarketProfile: spec.marketProfile,
        enforceSlotCaps:
            config.simMarketSpendMode ==
            BalanceSimMarketSpendMode.rerollSlotSellV1,
      );
      final battleSpec = BalanceSimRunSpec(
        matrixIndex: spec.matrixIndex,
        matrixSize: config.sequenceMatrixSize,
        seedOffset: spec.matrixIndex * sequenceStepCount + stepIndex,
        experimentId: spec.experimentId,
        station: station,
        blindTier: tier,
        difficulty: spec.difficulty,
        loadout: effectiveLoadout,
        marketProfile: resolvedMarketProfile,
      );
      final row = _runSingleBattle(
        config: config,
        spec: battleSpec,
        runIndex: runIndex,
        bot: bot,
        jesterCatalog: jesterCatalog,
        itemCatalog: itemCatalog,
      );
      final result = row['result'] as Map<String, Object?>;
      final cleared = result['cleared'] as bool;
      totalTurnCount += result['turn_count'] as int;
      totalScore += result['final_score'] as int;
      totalTargetScore += row['target_score'] as int;
      if (cleared) clearedStepCount++;
      final cashoutGold = cleared
          ? _simCashoutGoldForBattleRow(
              row,
              station: station,
              tier: tier,
              rewardScale: config.effectiveSimRewardScale,
            )
          : 0;
      simEconomyGold += cashoutGold;
      simEconomyCashoutGold += cashoutGold;

      row['row_type'] = 'battle';
      row['run_id'] =
          '${sequenceRunId}_step_${stepIndex.toString().padLeft(2, '0')}';
      row['sequence_mode'] = config.sequenceMode.name;
      row['sequence_run_id'] = sequenceRunId;
      row['sequence_step_index'] = stepIndex;
      row['sequence_step_count'] = sequenceStepCount;
      row['sequence_station_path'] = stationPath;
      row['sequence_tier_path'] = tierPath.map((tier) => tier.name).toList();
      row['market_profile'] = spec.marketProfile.id;
      row['resolved_market_profile'] = resolvedMarketProfile.id;
      row['run_modifier_market_pressure'] = _hasRunModifierMarketPressure(
        config.runModifier,
        spec.marketProfile,
      );
      if (marketSelection.sourceCandidate case final sourceCandidate?) {
        row['resolved_market_candidate'] = sourceCandidate.toJson();
      }
      if (marketSelection.shopSlots.isNotEmpty) {
        row['market_shop_slots'] = marketSelection.shopSlots
            .map((profile) => profile.id)
            .toList(growable: false);
      }
      row['base_loadout_id'] = spec.loadout.id;
      row['market_purchase_events'] = marketPurchaseEvents;
      row['sim_economy_trace'] = <String, Object?>{
        'schema_version': 1,
        'mode': config.simEconomyMode.id,
        'reward_scale': config.effectiveSimRewardScale,
        'base_reward_scale': config.simRewardScale,
        'run_modifier_id': config.runModifier.id,
        'run_modifier_reward_multiplier': config.runModifier.rewardMultiplier,
        'price_scale': config.simPriceScale,
        'market_budget_mode': config.simMarketBudgetMode.id,
        'market_spend_mode': config.simMarketSpendMode.id,
        'price_band_mode': config.simPriceBandMode.id,
        'market_choice_mode': config.simMarketChoiceMode.id,
        'market_budget': marketBudget,
        'gold_before_market': economyBeforeMarket,
        'known_market_spend': economyKnownSpendThisStep,
        'reroll_spend': economyRerollSpendThisStep,
        'sell_recovery': economySellRecoveryThisStep,
        'missing_cost_event_count': economyMissingCostThisStep,
        'unaffordable_event_count': economyUnaffordableThisStep,
        'slot_replace_event_count': economySlotReplaceThisStep,
        'gold_after_market': simEconomyGold,
        'cashout_gold': cashoutGold,
        'gold_after_cashout': simEconomyGold,
        'applied_market_profile': appliedMarketProfile.id,
        'behavior_gated':
            config.simEconomyMode == BalanceSimEconomyMode.gatedKnownCost,
      };
      battleRows.add(row);
      previousStepResourceState = _sequenceResourceStateFromRow(row);

      if (!cleared) {
        failedAtStation = station;
        failedAtTier = tier.name;
        failedStepIndex = stepIndex;
        failureStopReason = result['stop_reason'] as String;
        return BalanceSimSequenceOutput(
          battleRows: battleRows,
          summaryRow: _buildSequenceSummaryRow(
            spec: spec,
            config: config,
            bot: bot,
            runIndex: runIndex,
            sequenceRunId: sequenceRunId,
            stationPath: stationPath,
            tierPath: tierPath,
            sequenceStepCount: sequenceStepCount,
            attemptedStepCount: battleRows.length,
            clearedStepCount: clearedStepCount,
            failedAtStation: failedAtStation,
            failedAtTier: failedAtTier,
            failedStepIndex: failedStepIndex,
            failureStopReason: failureStopReason,
            lastStepResourceState: previousStepResourceState,
            failedStepResourceState: previousStepResourceState,
            jesterCatalog: jesterCatalog,
            itemCatalog: itemCatalog,
            totalTurnCount: totalTurnCount,
            totalScore: totalScore,
            totalTargetScore: totalTargetScore,
            marketSelection: baseMarketSelection,
            simEconomySummary: _simEconomySummary(
              finalGold: simEconomyGold,
              totalCashoutGold: simEconomyCashoutGold,
              knownMarketSpend: simEconomyKnownMarketSpend,
              rerollSpend: simEconomyRerollSpend,
              sellRecovery: simEconomySellRecovery,
              missingCostEvents: simEconomyMissingCostEvents,
              unaffordableEvents: simEconomyUnaffordableEvents,
              slotReplaceEvents: simEconomySlotReplaceEvents,
              economyMode: config.simEconomyMode,
              rewardScale: config.simRewardScale,
              priceScale: config.simPriceScale,
              marketBudgetMode: config.simMarketBudgetMode,
              marketSpendMode: config.simMarketSpendMode,
              priceBandMode: config.simPriceBandMode,
              marketChoiceMode: config.simMarketChoiceMode,
            ),
          ),
        );
      }
      stepIndex++;
    }
  }

  return BalanceSimSequenceOutput(
    battleRows: battleRows,
    summaryRow: _buildSequenceSummaryRow(
      spec: spec,
      config: config,
      bot: bot,
      runIndex: runIndex,
      sequenceRunId: sequenceRunId,
      stationPath: stationPath,
      tierPath: tierPath,
      sequenceStepCount: sequenceStepCount,
      attemptedStepCount: battleRows.length,
      clearedStepCount: clearedStepCount,
      failedAtStation: failedAtStation,
      failedAtTier: failedAtTier,
      failedStepIndex: failedStepIndex,
      failureStopReason: failureStopReason,
      lastStepResourceState: battleRows.isEmpty
          ? null
          : _sequenceResourceStateFromRow(battleRows.last),
      failedStepResourceState: null,
      jesterCatalog: jesterCatalog,
      itemCatalog: itemCatalog,
      totalTurnCount: totalTurnCount,
      totalScore: totalScore,
      totalTargetScore: totalTargetScore,
      marketSelection: baseMarketSelection,
      simEconomySummary: _simEconomySummary(
        finalGold: simEconomyGold,
        totalCashoutGold: simEconomyCashoutGold,
        knownMarketSpend: simEconomyKnownMarketSpend,
        rerollSpend: simEconomyRerollSpend,
        sellRecovery: simEconomySellRecovery,
        missingCostEvents: simEconomyMissingCostEvents,
        unaffordableEvents: simEconomyUnaffordableEvents,
        slotReplaceEvents: simEconomySlotReplaceEvents,
        economyMode: config.simEconomyMode,
        rewardScale: config.effectiveSimRewardScale,
        priceScale: config.simPriceScale,
        marketBudgetMode: config.simMarketBudgetMode,
        marketSpendMode: config.simMarketSpendMode,
        priceBandMode: config.simPriceBandMode,
        marketChoiceMode: config.simMarketChoiceMode,
      ),
    ),
  );
}

Map<String, Object?> _buildSequenceSummaryRow({
  required BalanceSimSequenceRunSpec spec,
  required BalanceSimCliConfig config,
  required BalanceSimBotPolicy bot,
  required int runIndex,
  required String sequenceRunId,
  required List<int> stationPath,
  required List<BlindTier> tierPath,
  required int sequenceStepCount,
  required int attemptedStepCount,
  required int clearedStepCount,
  required int? failedAtStation,
  required String? failedAtTier,
  required int? failedStepIndex,
  required String? failureStopReason,
  required Map<String, Object?>? lastStepResourceState,
  required Map<String, Object?>? failedStepResourceState,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
  required int totalTurnCount,
  required int totalScore,
  required int totalTargetScore,
  required BalanceSimMarketSelection marketSelection,
  required Map<String, Object?> simEconomySummary,
}) {
  final resolvedMarketProfile = marketSelection.profile;
  return <String, Object?>{
    'schema_version': 1,
    'row_type': 'sequence_summary',
    'sim_id': 'local',
    'run_id': sequenceRunId,
    'sequence_mode': config.sequenceMode.name,
    'sequence_run_id': sequenceRunId,
    'matrix_index': spec.matrixIndex,
    'matrix_size': config.sequenceMatrixSize,
    'experiment_id': spec.experimentId,
    'market_profile': spec.marketProfile.id,
    'resolved_market_profile': resolvedMarketProfile.id,
    if (marketSelection.sourceCandidate case final sourceCandidate?)
      'resolved_market_candidate': sourceCandidate.toJson(),
    if (marketSelection.shopSlots.isNotEmpty)
      'market_shop_slots': marketSelection.shopSlots
          .map((profile) => profile.id)
          .toList(growable: false),
    'loadout_id': spec.loadout.id,
    'loadout_effects': spec.loadout.effectsJson(),
    'run_modifier_id': config.runModifier.id,
    'run_modifier_target_multiplier': config.runModifier.targetScoreMultiplier,
    'run_modifier_reward_multiplier': config.runModifier.rewardMultiplier,
    'run_modifier_market_pressure': _hasRunModifierMarketPressure(
      config.runModifier,
      spec.marketProfile,
    ),
    'seed': config.seed + spec.matrixIndex * config.runs + runIndex,
    'bot_policy': bot.id,
    'app_version': 'dev',
    'balance_version': _balanceVersion,
    'difficulty': spec.difficulty.name,
    'ruleset_id': RummiRuleset.currentDefaults.persistenceId,
    'station_path': stationPath,
    'tier_path': tierPath.map((tier) => tier.name).toList(growable: false),
    'sequence_step_count': sequenceStepCount,
    'attempted_step_count': attemptedStepCount,
    'cleared_step_count': clearedStepCount,
    'path_cleared': clearedStepCount == sequenceStepCount,
    'failed_at_station': failedAtStation,
    'failed_at_tier': failedAtTier,
    'failed_step_index': failedStepIndex,
    'failure_stop_reason': failureStopReason,
    'last_step_resource_state': lastStepResourceState,
    'failed_step_resource_state': failedStepResourceState,
    'market_purchase_events': _sequenceMarketPurchaseEvents(
      marketProfile: resolvedMarketProfile,
      sourceCandidate: marketSelection.sourceCandidate,
      jesterCatalog: jesterCatalog,
      itemCatalog: itemCatalog,
      loadout: spec.loadout,
    ),
    'sim_economy_summary': simEconomySummary,
    'total_turn_count': totalTurnCount,
    'turn_per_attempted_step': attemptedStepCount == 0
        ? 0
        : totalTurnCount / attemptedStepCount,
    'turn_per_cleared_step': clearedStepCount == 0
        ? 0
        : totalTurnCount / clearedStepCount,
    'total_score': totalScore,
    'total_target_score': totalTargetScore,
    'total_score_ratio': totalTargetScore == 0
        ? 0
        : totalScore / totalTargetScore,
  };
}

Map<String, Object?> _simEconomySummary({
  required int finalGold,
  required int totalCashoutGold,
  required int knownMarketSpend,
  required int rerollSpend,
  required int sellRecovery,
  required int missingCostEvents,
  required int unaffordableEvents,
  required int slotReplaceEvents,
  required BalanceSimEconomyMode economyMode,
  required double rewardScale,
  required double priceScale,
  required BalanceSimMarketBudgetMode marketBudgetMode,
  required BalanceSimMarketSpendMode marketSpendMode,
  required BalanceSimPriceBandMode priceBandMode,
  required BalanceSimMarketChoiceMode marketChoiceMode,
}) {
  return <String, Object?>{
    'schema_version': 1,
    'mode': economyMode.id,
    'reward_scale': rewardScale,
    'price_scale': priceScale,
    'market_budget_mode': marketBudgetMode.id,
    'market_spend_mode': marketSpendMode.id,
    'price_band_mode': priceBandMode.id,
    'market_choice_mode': marketChoiceMode.id,
    'final_gold': finalGold,
    'total_cashout_gold': totalCashoutGold,
    'known_market_spend': knownMarketSpend,
    'reroll_spend': rerollSpend,
    'sell_recovery': sellRecovery,
    'missing_cost_event_count': missingCostEvents,
    'unaffordable_event_count': unaffordableEvents,
    'slot_replace_event_count': slotReplaceEvents,
    'behavior_gated': economyMode == BalanceSimEconomyMode.gatedKnownCost,
  };
}

String _sequenceRunId({required int matrixIndex, required int runIndex}) {
  final matrixPart = matrixIndex.toString().padLeft(3, '0');
  final runPart = runIndex.toString().padLeft(6, '0');
  return 'sequence_${matrixPart}_run_$runPart';
}

class BalanceSimSequenceOutput {
  const BalanceSimSequenceOutput({
    required this.battleRows,
    required this.summaryRow,
  });

  final List<Map<String, Object?>> battleRows;
  final Map<String, Object?> summaryRow;
}

Map<String, Object?> _sequenceResourceStateFromRow(
  Map<String, Object?> battleRow,
) {
  final startState = battleRow['start_state'] as Map<String, Object?>;
  final result = battleRow['result'] as Map<String, Object?>;
  final resourceState = <String, Object?>{
    'station': battleRow['station'],
    'blind_tier': battleRow['blind_tier'],
    'target_score': battleRow['target_score'],
    'final_score': result['final_score'],
    'score_ratio': result['score_ratio'],
    'score_margin': result['score_margin'],
    'cleared': result['cleared'],
    'outcome_label': result['outcome_label'],
    'stop_reason': result['stop_reason'],
    'turn_count': result['turn_count'],
    'start_deck': startState['hands_remaining'],
    'remaining_deck': result['remaining_deck'],
    'start_board_discards': startState['board_discards'],
    'remaining_board_discards': result['remaining_board_discards'],
    'start_hand_discards': startState['hand_discards'],
    'remaining_hand_discards': result['remaining_hand_discards'],
    'start_board_moves': startState['board_moves'],
    'remaining_board_moves': result['remaining_board_moves'],
    'board_occupancy': result['board_occupancy'],
    'confirm_action_count': result['confirm_action_count'],
    'discarded_board_count': result['discarded_board_count'],
    'max_single_confirm_score': result['max_single_confirm_score'],
  };
  final economyTrace = battleRow['sim_economy_trace'];
  if (economyTrace != null) {
    resourceState['sim_economy_trace'] = economyTrace;
  }
  return resourceState;
}

int _simCashoutGoldForBattleRow(
  Map<String, Object?> battleRow, {
  required int station,
  required BlindTier tier,
  required double rewardScale,
}) {
  final result = battleRow['result'] as Map<String, Object?>;
  final remainingBoardDiscards =
      (result['remaining_board_discards'] as num?)?.toInt() ?? 0;
  final remainingHandDiscards =
      (result['remaining_hand_discards'] as num?)?.toInt() ?? 0;
  final firstBlindClearBonus = station == 1 && tier == BlindTier.small
      ? RummiEconomyConfig.firstBlindClearBonusGold
      : 0;
  final baseGold =
      RummiEconomyConfig.stageClearGoldBase +
      firstBlindClearBonus +
      remainingBoardDiscards *
          RummiEconomyConfig.remainingBoardDiscardGoldBonus +
      remainingHandDiscards * RummiEconomyConfig.remainingHandDiscardGoldBonus;
  return (baseGold * rewardScale).round();
}

int? _simMarketBudgetForStep({
  required BalanceSimMarketBudgetMode mode,
  required int station,
  required int currentGold,
}) {
  if (mode == BalanceSimMarketBudgetMode.none) return null;
  final bandBudget = station <= 2
      ? 10
      : station <= 5
      ? 14
      : 18;
  return currentGold < bandBudget ? currentGold : bandBudget;
}

int _simMarketRerollSpendForStep({
  required BalanceSimMarketSpendMode mode,
  required int station,
  required BlindTier tier,
}) {
  if (mode == BalanceSimMarketSpendMode.none) return 0;
  if (tier == BlindTier.small) return 0;
  final rerollCount = station >= 6 && tier == BlindTier.boss ? 2 : 1;
  final rerollCost = station <= 2
      ? 2
      : station <= 5
      ? 4
      : 6;
  return rerollCount * rerollCost;
}

BalanceSimMarketProfile _resolveAffordableMarketProfile({
  required BalanceSimMarketChoiceMode mode,
  required BalanceSimMarketProfile currentProfile,
  required List<BalanceSimMarketProfile> shopSlots,
  required int station,
  required BlindTier tier,
  required BalanceSimLoadoutSpec loadout,
  required int currentGold,
  required int? remainingMarketBudget,
  required double simPriceScale,
  required BalanceSimPriceBandMode simPriceBandMode,
  required BalanceSimMarketSpendMode simMarketSpendMode,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  if (mode == BalanceSimMarketChoiceMode.none || shopSlots.isEmpty) {
    return currentProfile;
  }
  var bestProfile = currentProfile;
  var bestScore = -1 << 30;
  for (final profile in shopSlots) {
    final events = _sequenceMarketPurchaseEvents(
      marketProfile: profile,
      sourceCandidate: null,
      jesterCatalog: jesterCatalog,
      itemCatalog: itemCatalog,
      loadout: loadout,
    );
    if (events.isEmpty) continue;
    var affordable = true;
    var projectedGold = currentGold;
    var projectedBudget = remainingMarketBudget;
    for (final event in events) {
      final cost = event['cost'];
      if (cost is! num) {
        affordable = false;
        break;
      }
      final scaledCost = (cost * simPriceScale).round();
      final resolvedCost = _simPriceBandCostForEvent(
        mode: simPriceBandMode,
        event: event,
        fallbackCost: scaledCost,
      );
      final replacement = _simMarketSlotReplacementForEvent(
        mode: simMarketSpendMode,
        event: event,
        loadout: loadout,
        jesterCatalog: jesterCatalog,
        itemCatalog: itemCatalog,
      );
      projectedGold += replacement.sellRecovery;
      final withinBudget =
          projectedBudget == null || projectedBudget >= resolvedCost;
      if (projectedGold < resolvedCost || !withinBudget) {
        affordable = false;
        break;
      }
      projectedGold -= resolvedCost;
      if (projectedBudget != null) {
        projectedBudget -= resolvedCost;
      }
    }
    if (!affordable) continue;
    final score = _shopSlotUtilityForProfile(
      loadout: loadout,
      station: station,
      tier: tier,
      profile: profile,
    );
    if (score > bestScore) {
      bestProfile = profile;
      bestScore = score;
    }
  }
  return bestScore == -1 << 30 ? currentProfile : bestProfile;
}

int _shopSlotUtilityForProfile({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required BalanceSimMarketProfile profile,
}) {
  final late = station >= 6;
  final boss = tier == BlindTier.boss;
  var score = _buildAwareMarketWeight(loadout, profile) * 2;
  if (boss) score += _bossMarketWeight(profile);
  if (late) {
    score += switch (profile) {
      BalanceSimMarketProfile.s1CandidateRareXmultJester => 18,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 12,
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 10,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge => 6,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack ||
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
      BalanceSimMarketProfile.s1TilePackPlus5 => 4,
      BalanceSimMarketProfile.s1BuyDiscardGlove ||
      BalanceSimMarketProfile.s1CandidateVoucherResource => 3,
      _ => 0,
    };
  } else if (station <= 2) {
    score += switch (profile) {
      BalanceSimMarketProfile.s1CandidateCommonColorJester ||
      BalanceSimMarketProfile.s1CandidateCommonRankJester => 8,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 7,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
      BalanceSimMarketProfile.s1TilePackPlus5 => 5,
      BalanceSimMarketProfile.s1BuyDiscardGlove => 4,
      _ => 0,
    };
  } else {
    score += switch (profile) {
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester ||
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 10,
      BalanceSimMarketProfile.s1CandidateRareXmultJester => 8,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack ||
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 6,
      BalanceSimMarketProfile.s1BuyDiscardGlove ||
      BalanceSimMarketProfile.s1CandidateVoucherResource => 5,
      _ => 0,
    };
  }
  if (_isFinalBandShapeCorrectionProxy(profile) && station >= 7) {
    score += 6;
  }
  return score;
}

int _simPriceBandCostForEvent({
  required BalanceSimPriceBandMode mode,
  required Map<String, Object?> event,
  required int fallbackCost,
}) {
  if (mode == BalanceSimPriceBandMode.none) return fallbackCost;
  if (mode == BalanceSimPriceBandMode.catalogValueFlagsV1) {
    return _simCatalogValueFlagCostForEvent(
      event: event,
      fallbackCost: fallbackCost,
    );
  }
  if (mode == BalanceSimPriceBandMode.catalogNormalizedV1) {
    return _simCatalogNormalizedCostForEvent(
      event: event,
      fallbackCost: fallbackCost,
    );
  }
  final soft = mode == BalanceSimPriceBandMode.rarityCategorySoftV1;
  final category = event['category'];
  final contentId = event['content_id'];
  if (category == 'planet') return max(fallbackCost, soft ? 8 : 12);
  if (category == 'tarot') return max(fallbackCost, soft ? 8 : 12);
  if (category == 'voucher') return max(fallbackCost, soft ? 12 : 18);
  if (category == 'pack') {
    final addedTiles = event['deck_tiles_added'];
    final addedTileCount = addedTiles is num ? addedTiles.toInt() : 0;
    return max(fallbackCost, (soft ? 6 : 8) + addedTileCount);
  }
  if (category == 'item') {
    return max(fallbackCost, (fallbackCost * (soft ? 1.25 : 1.5)).round());
  }
  if (category == 'jester' && contentId is String) {
    if (contentId.contains('legendary')) {
      return max(fallbackCost, soft ? 22 : 30);
    }
    if (contentId.contains('rare_xmult')) {
      return max(fallbackCost, soft ? 14 : 20);
    }
    if (contentId.contains('uncommon')) return max(fallbackCost, soft ? 9 : 12);
    if (contentId.contains('common')) return max(fallbackCost, soft ? 6 : 8);
  }
  return fallbackCost;
}

int _simCatalogNormalizedCostForEvent({
  required Map<String, Object?> event,
  required int fallbackCost,
}) {
  final category = event['category'];
  final contentId = event['content_id'];
  if (category == 'item' && contentId is String) {
    return switch (contentId) {
      'reroll_token' => max(fallbackCost, 5),
      'coin_cache' => max(fallbackCost, 4),
      'thin_wallet' => max(fallbackCost, 7),
      _ => fallbackCost,
    };
  }
  if (category != 'jester') return fallbackCost;
  final proxyIds = event['proxy_jester_ids'];
  final ids = proxyIds is List
      ? proxyIds.whereType<String>().toSet()
      : <String>{if (contentId is String) contentId};
  var cost = fallbackCost;
  if (ids.contains('green_jester')) cost = max(cost, 8);
  if (ids.contains('popcorn')) cost = max(cost, 6);
  if (ids.contains('ice_cream')) cost = max(cost, 7);
  if (ids.contains('banner')) cost = max(cost, 7);
  if (ids.contains('gros_michel')) cost = max(cost, 7);
  if (ids.contains('supernova')) cost = max(cost, 8);
  return cost;
}

int _simCatalogValueFlagCostForEvent({
  required Map<String, Object?> event,
  required int fallbackCost,
}) {
  final category = event['category'];
  final contentId = event['content_id'];
  if (category == 'item' && contentId is String) {
    return switch (contentId) {
      'reroll_token' => max(fallbackCost, 5),
      'coin_cache' => max(fallbackCost, 4),
      'thin_wallet' => max(fallbackCost, 7),
      _ => fallbackCost,
    };
  }
  if (category != 'jester') return fallbackCost;
  final proxyIds = event['proxy_jester_ids'];
  final ids = proxyIds is List
      ? proxyIds.whereType<String>().toSet()
      : <String>{if (contentId is String) contentId};
  var cost = fallbackCost;
  if (ids.contains('green_jester')) cost = max(cost, 6);
  if (ids.contains('popcorn')) cost = max(cost, 6);
  if (ids.contains('ice_cream')) cost = max(cost, 7);
  if (ids.contains('supernova')) cost = max(cost, 7);
  return cost;
}

_SimMarketSlotReplacement _simMarketSlotReplacementForEvent({
  required BalanceSimMarketSpendMode mode,
  required Map<String, Object?> event,
  required BalanceSimLoadoutSpec loadout,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  if (mode == BalanceSimMarketSpendMode.none) {
    return const _SimMarketSlotReplacement.none();
  }
  final family = _simMarketSlotFamilyForEvent(event);
  if (family == _SimMarketSlotFamily.none) {
    return const _SimMarketSlotReplacement.none();
  }
  if (family == _SimMarketSlotFamily.jester &&
      loadout.jesterIds.length >= RummiRunProgress.maxJesterSlots) {
    return _SimMarketSlotReplacement(
      replaced: true,
      sellRecovery: _simCheapestJesterSellRecovery(
        loadout.jesterIds,
        jesterCatalog,
      ),
    );
  }
  if (family == _SimMarketSlotFamily.item) {
    final contentId = event['content_id'];
    if (contentId is! String) return const _SimMarketSlotReplacement.none();
    final item = itemCatalog.findById(contentId);
    if (item == null ||
        !_simItemSlotIsFull(loadout.itemIds, item, itemCatalog)) {
      return const _SimMarketSlotReplacement.none();
    }
    return _SimMarketSlotReplacement(
      replaced: true,
      sellRecovery: _simCheapestItemSellRecovery(
        loadout.itemIds,
        item,
        itemCatalog,
      ),
    );
  }
  return const _SimMarketSlotReplacement.none();
}

_SimMarketSlotFamily _simMarketSlotFamilyForEvent(Map<String, Object?> event) {
  final category = event['category'];
  return switch (category) {
    'jester' || 'planet' => _SimMarketSlotFamily.jester,
    'item' || 'voucher' => _SimMarketSlotFamily.item,
    _ => _SimMarketSlotFamily.none,
  };
}

int _simCheapestJesterSellRecovery(
  List<String> jesterIds,
  RummiJesterCatalog catalog,
) {
  var cheapest = 1 << 30;
  for (final id in jesterIds) {
    final card = catalog.findById(id);
    if (card == null) continue;
    cheapest = min(cheapest, max(1, card.baseCost ~/ 2));
  }
  return cheapest == 1 << 30 ? 0 : cheapest;
}

bool _simItemSlotIsFull(
  List<String> itemIds,
  ItemDefinition item,
  ItemCatalog catalog,
) {
  final capacity = switch (item.placement) {
    ItemPlacement.quickSlot => RunInventoryState.defaultQuickSlotCapacity,
    ItemPlacement.passiveRack => RunInventoryState.defaultPassiveRelicCapacity,
    ItemPlacement.equipped when item.slotHint == 'gear' => 2,
    ItemPlacement.equipped => 3,
    ItemPlacement.inventory => 99,
  };
  if (capacity >= 99) return false;
  final occupied = itemIds
      .map(catalog.findById)
      .whereType<ItemDefinition>()
      .where((owned) => _simSameItemSlotFamily(owned, item))
      .length;
  return occupied >= capacity;
}

bool _simSameItemSlotFamily(ItemDefinition a, ItemDefinition b) {
  if (a.placement != b.placement) return false;
  if (a.placement == ItemPlacement.equipped) {
    return (a.slotHint == 'gear') == (b.slotHint == 'gear');
  }
  return true;
}

int _simCheapestItemSellRecovery(
  List<String> itemIds,
  ItemDefinition incoming,
  ItemCatalog catalog,
) {
  var cheapest = 1 << 30;
  for (final id in itemIds) {
    final owned = catalog.findById(id);
    if (owned == null || !_simSameItemSlotFamily(owned, incoming)) continue;
    cheapest = min(cheapest, max(0, owned.sellPrice));
  }
  return cheapest == 1 << 30 ? 0 : cheapest;
}

BalanceSimLoadoutSpec _sequenceEffectiveLoadout({
  required BalanceSimLoadoutSpec baseLoadout,
  required int station,
  required BalanceSimMarketProfile marketProfile,
  required BalanceSimMarketProfile loadoutIdMarketProfile,
  bool enforceSlotCaps = false,
}) {
  final stationBaseLoadout = _stationRouteLoadout(
    baseLoadout: baseLoadout,
    station: station,
  );
  if (station <= 1 || loadoutIdMarketProfile == BalanceSimMarketProfile.none) {
    return stationBaseLoadout;
  }
  final jesterIds = [...stationBaseLoadout.jesterIds];
  final itemIds = [...stationBaseLoadout.itemIds];
  switch (marketProfile) {
    case BalanceSimMarketProfile.none:
      break;
    case BalanceSimMarketProfile.s1BuyJolly:
      _addUnique(jesterIds, 'jolly_jester');
    case BalanceSimMarketProfile.s1BuySly:
      _addUnique(jesterIds, 'sly_jester');
    case BalanceSimMarketProfile.s1BuyDiscardGlove:
      _addUnique(itemIds, 'discard_glove');
    case BalanceSimMarketProfile.s1TilePackSmall:
    case BalanceSimMarketProfile.s1TilePackPlus3:
    case BalanceSimMarketProfile.s1TilePackPlus4:
    case BalanceSimMarketProfile.s1TilePackPlus5:
    case BalanceSimMarketProfile.s1BuildAwarePackPlus3:
    case BalanceSimMarketProfile.s1BuildAwarePackPlus5:
    case BalanceSimMarketProfile.s1PairSeedPack:
    case BalanceSimMarketProfile.s1ColorSeedPack:
    case BalanceSimMarketProfile.s1FaceSeedPack:
    case BalanceSimMarketProfile.s1RandomCandidatePool:
    case BalanceSimMarketProfile.s1ProbabilisticCandidatePool:
    case BalanceSimMarketProfile.s1FullSafeCandidatePool:
    case BalanceSimMarketProfile.s1RoleDeckSustainPool:
    case BalanceSimMarketProfile.s1RoleScoreGrowthPool:
    case BalanceSimMarketProfile.s1RoleShapeFixPool:
    case BalanceSimMarketProfile.s1RoleWeakFlavorPool:
    case BalanceSimMarketProfile.s1StationWeightedCandidatePool:
    case BalanceSimMarketProfile.s1StateWeightedCandidatePool:
    case BalanceSimMarketProfile.bandedCandidatePoolV1:
    case BalanceSimMarketProfile.bandedCandidatePoolV2:
    case BalanceSimMarketProfile.shopSlotMarketV1:
    case BalanceSimMarketProfile.shopSlotMarketV2:
    case BalanceSimMarketProfile.shopSlotMarketV3:
    case BalanceSimMarketProfile.shopSlotMarketV4:
    case BalanceSimMarketProfile.shopSlotMarketV5:
    case BalanceSimMarketProfile.shopSlotMarketV6:
    case BalanceSimMarketProfile.shopSlotMarketV7:
    case BalanceSimMarketProfile.shopSlotMarketV8:
    case BalanceSimMarketProfile.shopSlotMarketV9:
    case BalanceSimMarketProfile.shopSlotMarketV10:
    case BalanceSimMarketProfile.shopSlotMarketV11:
    case BalanceSimMarketProfile.shopSlotMarketV12:
    case BalanceSimMarketProfile.shopSlotMarketV13:
      break;
    case BalanceSimMarketProfile.s1CandidateCommonColorJester:
      _addUnique(jesterIds, _colorJesterForLoadout(stationBaseLoadout));
    case BalanceSimMarketProfile.s1CandidateCommonRankJester:
      _addUnique(jesterIds, _rankJesterForLoadout(stationBaseLoadout));
    case BalanceSimMarketProfile.s1CandidateUncommonBuildJester:
      _addUnique(jesterIds, _buildJesterForLoadout(stationBaseLoadout));
    case BalanceSimMarketProfile.s1CandidateRareXmultJester:
      _addUnique(jesterIds, _rareXmultJesterForLoadout(stationBaseLoadout));
    case BalanceSimMarketProfile.s1CandidateLegendaryBridge:
      _addUnique(jesterIds, 'the_tribe');
      _addUnique(jesterIds, 'the_order');
    case BalanceSimMarketProfile.s1CandidatePlanetRankLevel:
      _addUnique(jesterIds, 'supernova');
      _addUnique(itemIds, 'echo_bell');
    case BalanceSimMarketProfile.s1CandidateTarotBuildPack:
      break;
    case BalanceSimMarketProfile.s1CandidateVoucherResource:
      break;
  }
  final growth = _simMarketLoadoutGrowth(marketProfile);
  if (enforceSlotCaps && jesterIds.length > RummiRunProgress.maxJesterSlots) {
    jesterIds.removeRange(
      0,
      jesterIds.length - RummiRunProgress.maxJesterSlots,
    );
  }
  return BalanceSimLoadoutSpec(
    id: '${stationBaseLoadout.id}__${loadoutIdMarketProfile.id}',
    jesterIds: List<String>.unmodifiable(jesterIds),
    itemIds: List<String>.unmodifiable(itemIds),
    maxHandSizeDelta:
        stationBaseLoadout.maxHandSizeDelta + growth.maxHandSizeDelta,
    boardMovesDelta:
        stationBaseLoadout.boardMovesDelta + growth.boardMovesDelta,
    boardDiscardsDelta:
        stationBaseLoadout.boardDiscardsDelta + growth.boardDiscardsDelta,
    handDiscardsDelta:
        stationBaseLoadout.handDiscardsDelta + growth.handDiscardsDelta,
  );
}

BalanceSimLoadoutSpec _stationRouteLoadout({
  required BalanceSimLoadoutSpec baseLoadout,
  required int station,
}) {
  return switch (baseLoadout.id) {
    'progression_route_slow' => _progressionRouteSlow(station),
    'progression_route_balanced' => _progressionRouteBalanced(station),
    'progression_route_delayed' => _progressionRouteDelayed(station),
    'progression_route_sustain' => _progressionRouteSustain(station),
    'progression_route_power' => _progressionRoutePower(station),
    _ => baseLoadout,
  };
}

BalanceSimLoadoutSpec _progressionRouteSlow(int station) {
  final id = switch (station) {
    <= 1 => 's1_entry_bridge_build',
    2 => 's2_foundation_build',
    3 => 's3_hand_growth_build',
    4 => 's4_resource_build',
    5 || 6 => 's5_power_build',
    7 => 's5_boss_bridge_build',
    _ => 's6_boss_breaker_build',
  };
  return BalanceSimCliConfig.parseLoadoutPresetForInternalUse(id);
}

BalanceSimLoadoutSpec _progressionRouteBalanced(int station) {
  final id = switch (station) {
    <= 1 => 's1_entry_bridge_build',
    2 => 's2_foundation_build',
    3 => 's3_hand_growth_build',
    4 => 's4_resource_build',
    5 => 's5_power_build',
    6 => 's5_boss_bridge_build',
    7 => 's6_boss_breaker_build',
    _ => 's8_finale_build',
  };
  return BalanceSimCliConfig.parseLoadoutPresetForInternalUse(id);
}

BalanceSimLoadoutSpec _progressionRouteDelayed(int station) {
  final id = switch (station) {
    <= 1 => 's1_entry_bridge_build',
    2 || 3 => 's2_foundation_build',
    4 => 's3_hand_growth_build',
    5 => 's4_resource_build',
    6 => 's5_power_build',
    7 => 's5_boss_bridge_build',
    _ => 's6_boss_breaker_build',
  };
  return BalanceSimCliConfig.parseLoadoutPresetForInternalUse(id);
}

BalanceSimLoadoutSpec _progressionRouteSustain(int station) {
  final id = switch (station) {
    <= 1 => 's1_entry_bridge_build',
    2 => 's2_foundation_build',
    3 => 's3_hand_growth_build',
    4 => 's4_resource_build',
    5 => 's5_sustain_build',
    6 => 's5_boss_bridge_build',
    7 => 's6_boss_breaker_build',
    _ => 's8_finale_build',
  };
  return BalanceSimCliConfig.parseLoadoutPresetForInternalUse(id);
}

BalanceSimLoadoutSpec _progressionRoutePower(int station) {
  final id = switch (station) {
    <= 1 => 's1_entry_bridge_build',
    2 => 's3_hand_growth_build',
    3 => 's4_resource_build',
    4 => 's5_power_build',
    5 => 's5_boss_bridge_build',
    6 => 's6_boss_breaker_build',
    _ => 's8_finale_build',
  };
  return BalanceSimCliConfig.parseLoadoutPresetForInternalUse(id);
}

List<Map<String, Object?>> _sequenceMarketPurchaseEvents({
  required BalanceSimMarketProfile marketProfile,
  required BalanceSimBacklogCandidate? sourceCandidate,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
  required BalanceSimLoadoutSpec loadout,
}) {
  if (marketProfile == BalanceSimMarketProfile.none) return const [];
  final contentId = switch (marketProfile) {
    BalanceSimMarketProfile.none => '',
    BalanceSimMarketProfile.s1BuyJolly => 'jolly_jester',
    BalanceSimMarketProfile.s1BuySly => 'sly_jester',
    BalanceSimMarketProfile.s1BuyDiscardGlove => 'discard_glove',
    BalanceSimMarketProfile.s1TilePackSmall => 'tile_pack_small',
    BalanceSimMarketProfile.s1TilePackPlus3 => 'tile_pack_plus3',
    BalanceSimMarketProfile.s1TilePackPlus4 => 'tile_pack_plus4',
    BalanceSimMarketProfile.s1TilePackPlus5 => 'tile_pack_plus5',
    BalanceSimMarketProfile.s1BuildAwarePackPlus3 => 'build_aware_pack_plus3',
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 'build_aware_pack_plus5',
    BalanceSimMarketProfile.s1PairSeedPack => 'pair_seed_pack',
    BalanceSimMarketProfile.s1ColorSeedPack => 'color_seed_pack',
    BalanceSimMarketProfile.s1FaceSeedPack => 'face_seed_pack',
    BalanceSimMarketProfile.s1RandomCandidatePool => 'random_candidate_pool',
    BalanceSimMarketProfile.s1ProbabilisticCandidatePool =>
      'probabilistic_candidate_pool',
    BalanceSimMarketProfile.s1FullSafeCandidatePool =>
      'full_safe_candidate_pool',
    BalanceSimMarketProfile.s1RoleDeckSustainPool => 'role_deck_sustain_pool',
    BalanceSimMarketProfile.s1RoleScoreGrowthPool => 'role_score_growth_pool',
    BalanceSimMarketProfile.s1RoleShapeFixPool => 'role_shape_fix_pool',
    BalanceSimMarketProfile.s1RoleWeakFlavorPool => 'role_weak_flavor_pool',
    BalanceSimMarketProfile.s1StationWeightedCandidatePool =>
      'station_weighted_candidate_pool',
    BalanceSimMarketProfile.s1StateWeightedCandidatePool =>
      'state_weighted_candidate_pool',
    BalanceSimMarketProfile.bandedCandidatePoolV1 => 'banded_candidate_pool_v1',
    BalanceSimMarketProfile.bandedCandidatePoolV2 => 'banded_candidate_pool_v2',
    BalanceSimMarketProfile.shopSlotMarketV1 => 'shop_slot_market_v1',
    BalanceSimMarketProfile.shopSlotMarketV2 => 'shop_slot_market_v2',
    BalanceSimMarketProfile.shopSlotMarketV3 => 'shop_slot_market_v3',
    BalanceSimMarketProfile.shopSlotMarketV4 => 'shop_slot_market_v4',
    BalanceSimMarketProfile.shopSlotMarketV5 => 'shop_slot_market_v5',
    BalanceSimMarketProfile.shopSlotMarketV6 => 'shop_slot_market_v6',
    BalanceSimMarketProfile.shopSlotMarketV7 => 'shop_slot_market_v7',
    BalanceSimMarketProfile.shopSlotMarketV8 => 'shop_slot_market_v8',
    BalanceSimMarketProfile.shopSlotMarketV9 => 'shop_slot_market_v9',
    BalanceSimMarketProfile.shopSlotMarketV10 => 'shop_slot_market_v10',
    BalanceSimMarketProfile.shopSlotMarketV11 => 'shop_slot_market_v11',
    BalanceSimMarketProfile.shopSlotMarketV12 => 'shop_slot_market_v12',
    BalanceSimMarketProfile.shopSlotMarketV13 => 'shop_slot_market_v13',
    BalanceSimMarketProfile.s1CandidateCommonColorJester =>
      'common_color_jester_proxy',
    BalanceSimMarketProfile.s1CandidateCommonRankJester =>
      'common_rank_jester_proxy',
    BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
      'uncommon_build_jester_proxy',
    BalanceSimMarketProfile.s1CandidateRareXmultJester =>
      'rare_xmult_jester_proxy',
    BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
      'legendary_bridge_proxy',
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
      'planet_rank_level_proxy',
    BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
      'tarot_build_pack_proxy',
    BalanceSimMarketProfile.s1CandidateVoucherResource =>
      'voucher_resource_proxy',
  };
  final category = switch (marketProfile) {
    BalanceSimMarketProfile.s1BuyDiscardGlove => 'item',
    _ when _isSimPackProfile(marketProfile) => 'pack',
    BalanceSimMarketProfile.s1RandomCandidatePool => 'sim_pool',
    BalanceSimMarketProfile.s1ProbabilisticCandidatePool => 'sim_pool',
    BalanceSimMarketProfile.s1FullSafeCandidatePool => 'sim_pool',
    BalanceSimMarketProfile.s1RoleDeckSustainPool => 'sim_pool',
    BalanceSimMarketProfile.s1RoleScoreGrowthPool => 'sim_pool',
    BalanceSimMarketProfile.s1RoleShapeFixPool => 'sim_pool',
    BalanceSimMarketProfile.s1RoleWeakFlavorPool => 'sim_pool',
    BalanceSimMarketProfile.s1StationWeightedCandidatePool => 'sim_policy',
    BalanceSimMarketProfile.s1StateWeightedCandidatePool => 'sim_policy',
    BalanceSimMarketProfile.bandedCandidatePoolV1 => 'sim_policy',
    BalanceSimMarketProfile.bandedCandidatePoolV2 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV1 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV2 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV3 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV4 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV5 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV6 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV7 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV8 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV9 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV10 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV11 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV12 => 'sim_policy',
    BalanceSimMarketProfile.shopSlotMarketV13 => 'sim_policy',
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 'planet',
    BalanceSimMarketProfile.s1CandidateTarotBuildPack => 'tarot',
    BalanceSimMarketProfile.s1CandidateVoucherResource => 'voucher',
    _ => 'jester',
  };
  final cost = switch (category) {
    'jester' => _simJesterProxyCost(
      marketProfile: marketProfile,
      contentId: contentId,
      loadout: loadout,
      catalog: jesterCatalog,
    ),
    'item' => itemCatalog.findById(contentId)?.basePrice,
    'pack' => _simPackCost(marketProfile),
    'sim_pool' => null,
    'sim_policy' => null,
    'planet' => 4,
    'tarot' => 4,
    'voucher' => 8,
    _ => null,
  };
  final proxyJesterIds = category == 'jester'
      ? _simJesterProxyIds(
          marketProfile: marketProfile,
          contentId: contentId,
          loadout: loadout,
        )
      : const <String>[];
  return [
    <String, Object?>{
      'after_station': 1,
      'category': category,
      'content_id': contentId,
      'cost': cost,
      'simulated': true,
      if (proxyJesterIds.isNotEmpty) 'proxy_jester_ids': proxyJesterIds,
      if (category == 'pack')
        'deck_tiles_added': _simPackAddedTileCount(marketProfile),
      if (marketProfile.id.startsWith('s1_candidate_'))
        'proxy_effect': _simCandidateProxyEffect(marketProfile),
      if (sourceCandidate != null) 'source_candidate': sourceCandidate.toJson(),
    },
  ];
}

List<String> _simJesterProxyIds({
  required BalanceSimMarketProfile marketProfile,
  required String contentId,
  required BalanceSimLoadoutSpec loadout,
}) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1CandidateCommonColorJester => [
      _colorJesterForLoadout(loadout),
    ],
    BalanceSimMarketProfile.s1CandidateCommonRankJester => [
      _rankJesterForLoadout(loadout),
    ],
    BalanceSimMarketProfile.s1CandidateUncommonBuildJester => [
      _buildJesterForLoadout(loadout),
    ],
    BalanceSimMarketProfile.s1CandidateRareXmultJester => [
      _rareXmultJesterForLoadout(loadout),
    ],
    BalanceSimMarketProfile.s1CandidateLegendaryBridge => [
      'the_tribe',
      'the_order',
    ],
    _ => contentId.isEmpty ? const <String>[] : [contentId],
  };
}

int? _simJesterProxyCost({
  required BalanceSimMarketProfile marketProfile,
  required String contentId,
  required BalanceSimLoadoutSpec loadout,
  required RummiJesterCatalog catalog,
}) {
  final ids = _simJesterProxyIds(
    marketProfile: marketProfile,
    contentId: '',
    loadout: loadout,
  );
  if (ids.isEmpty) {
    return catalog.findById(contentId)?.baseCost;
  }
  var total = 0;
  for (final id in ids) {
    final card = catalog.findById(id);
    if (card == null) return null;
    total += card.baseCost;
  }
  return total;
}

BalanceSimMarketSelection _resolveSequenceMarketSelection({
  required BalanceSimMarketProfile marketProfile,
  required int seed,
  required BalanceSimLoadoutSpec loadout,
}) {
  if (marketProfile != BalanceSimMarketProfile.s1RandomCandidatePool &&
      marketProfile != BalanceSimMarketProfile.s1ProbabilisticCandidatePool &&
      marketProfile != BalanceSimMarketProfile.s1StationWeightedCandidatePool &&
      marketProfile != BalanceSimMarketProfile.s1StateWeightedCandidatePool &&
      marketProfile != BalanceSimMarketProfile.bandedCandidatePoolV1 &&
      marketProfile != BalanceSimMarketProfile.bandedCandidatePoolV2 &&
      marketProfile != BalanceSimMarketProfile.shopSlotMarketV1 &&
      marketProfile != BalanceSimMarketProfile.shopSlotMarketV2 &&
      marketProfile != BalanceSimMarketProfile.shopSlotMarketV3 &&
      marketProfile != BalanceSimMarketProfile.s1FullSafeCandidatePool &&
      !_isBacklogRolePool(marketProfile)) {
    return BalanceSimMarketSelection(profile: marketProfile);
  }

  final rng = Random(seed * 1009 + marketProfile.index * 9173);
  if (marketProfile == BalanceSimMarketProfile.s1FullSafeCandidatePool ||
      _isBacklogRolePool(marketProfile)) {
    final sourceCandidate = _pickWeightedBacklogCandidate(
      rng: rng,
      loadout: loadout,
      rolePool: marketProfile,
    );
    return BalanceSimMarketSelection(
      profile: sourceCandidate.proxyProfile,
      sourceCandidate: sourceCandidate,
    );
  }

  if (marketProfile == BalanceSimMarketProfile.s1ProbabilisticCandidatePool) {
    return BalanceSimMarketSelection(
      profile: _pickWeightedMarketCandidate(
        rng: rng,
        candidates: _probabilisticMarketCandidates(loadout),
      ),
    );
  }

  if (marketProfile == BalanceSimMarketProfile.s1StationWeightedCandidatePool ||
      marketProfile == BalanceSimMarketProfile.s1StateWeightedCandidatePool ||
      marketProfile == BalanceSimMarketProfile.bandedCandidatePoolV1 ||
      marketProfile == BalanceSimMarketProfile.bandedCandidatePoolV2 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV1 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV2 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV3) {
    return BalanceSimMarketSelection(profile: marketProfile);
  }

  const weightedCandidates = <BalanceSimMarketProfile>[
    BalanceSimMarketProfile.s1BuyJolly,
    BalanceSimMarketProfile.s1BuySly,
    BalanceSimMarketProfile.s1BuyDiscardGlove,
    BalanceSimMarketProfile.s1TilePackSmall,
    BalanceSimMarketProfile.s1PairSeedPack,
    BalanceSimMarketProfile.s1ColorSeedPack,
    BalanceSimMarketProfile.s1FaceSeedPack,
    BalanceSimMarketProfile.s1TilePackSmall,
    BalanceSimMarketProfile.s1PairSeedPack,
    BalanceSimMarketProfile.s1ColorSeedPack,
    BalanceSimMarketProfile.s1FaceSeedPack,
  ];
  return BalanceSimMarketSelection(
    profile: weightedCandidates[rng.nextInt(weightedCandidates.length)],
  );
}

BalanceSimMarketSelection _resolveSequenceStepMarketSelection({
  required BalanceSimMarketSelection baseSelection,
  required BalanceSimMarketProfile marketProfile,
  required NewRunModifier runModifier,
  required int seed,
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required Map<String, Object?>? previousStepResourceState,
}) {
  final isStationWeighted =
      marketProfile == BalanceSimMarketProfile.s1StationWeightedCandidatePool;
  final isStateWeighted =
      marketProfile == BalanceSimMarketProfile.s1StateWeightedCandidatePool;
  final isBanded =
      marketProfile == BalanceSimMarketProfile.bandedCandidatePoolV1 ||
      marketProfile == BalanceSimMarketProfile.bandedCandidatePoolV2;
  final isShopSlot =
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV1 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV2 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV3 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV4 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV5 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV6 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV7 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
  if (!isStationWeighted && !isStateWeighted && !isBanded && !isShopSlot) {
    return baseSelection;
  }
  if (station <= 1) return baseSelection;
  final rng = Random(seed * 1009 + station * 313 + tier.index * 9173);
  if (isShopSlot) {
    final runModifierMarketPressure = _hasRunModifierMarketPressure(
      runModifier,
      marketProfile,
    );
    final tempoBias = marketProfile != BalanceSimMarketProfile.shopSlotMarketV1;
    final lateTempoBias =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV4 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV5 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV6 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV7 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final lateTempoBiasStrong =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV4 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV6 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV7 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final lateStaticGuard =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV6 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV7 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final lateStaticGuardStrong =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV7 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final earlyFunBias =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV8 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final lateBreakerBias =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV9 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV13;
    final finalShapeFloorStrong =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV12 ||
        (marketProfile == BalanceSimMarketProfile.shopSlotMarketV13 &&
            station >= 8);
    final missingGrowthBias =
        runModifierMarketPressure ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10 ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV11;
    final missingGrowthBiasStrong =
        runModifierMarketPressure ||
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV10;
    final boardLockRelief =
        marketProfile == BalanceSimMarketProfile.shopSlotMarketV3 &&
        _hasPreviousBoardLockPressure(previousStepResourceState);
    final candidates = _shopSlotMarketCandidates(
      loadout: loadout,
      station: station,
      tier: tier,
      tempoBias: tempoBias,
      lateTempoBias: lateTempoBias,
      lateTempoBiasStrong: lateTempoBiasStrong,
      lateStaticGuard: lateStaticGuard,
      lateStaticGuardStrong: lateStaticGuardStrong,
      boardLockRelief: boardLockRelief,
      earlyFunBias: earlyFunBias,
      lateBreakerBias: lateBreakerBias,
      finalShapeFloorStrong: finalShapeFloorStrong,
      missingGrowthBias: missingGrowthBias,
      missingGrowthBiasStrong: missingGrowthBiasStrong,
    );
    final slots = _rollMarketShopSlots(
      rng: rng,
      candidates: candidates,
      slotCount: _shopSlotCountForStation(
        station,
        tempoBias: tempoBias,
        missingGrowthBias: missingGrowthBias,
        missingGrowthBiasStrong: missingGrowthBiasStrong,
      ),
    );
    return BalanceSimMarketSelection(
      profile: _chooseMarketShopSlot(
        loadout: loadout,
        station: station,
        tier: tier,
        slots: slots,
        tempoBias: tempoBias,
        lateTempoBias: lateTempoBias,
        lateTempoBiasStrong: lateTempoBiasStrong,
        lateStaticGuard: lateStaticGuard,
        lateStaticGuardStrong: lateStaticGuardStrong,
        boardLockRelief: boardLockRelief,
        earlyFunBias: earlyFunBias,
        lateBreakerBias: lateBreakerBias,
        finalShapeFloorStrong: finalShapeFloorStrong,
        missingGrowthBias: missingGrowthBias,
        missingGrowthBiasStrong: missingGrowthBiasStrong,
      ),
      shopSlots: slots.map((slot) => slot.profile).toList(growable: false),
    );
  }
  final candidates = isBanded
      ? _bandedMarketCandidates(
          loadout: loadout,
          station: station,
          tier: tier,
          fastBurstBias:
              marketProfile == BalanceSimMarketProfile.bandedCandidatePoolV2,
        )
      : isStateWeighted
      ? _stateWeightedMarketCandidates(
          loadout: loadout,
          station: station,
          tier: tier,
          previousStepResourceState: previousStepResourceState,
        )
      : _stationWeightedMarketCandidates(
          loadout: loadout,
          station: station,
          tier: tier,
        );
  return BalanceSimMarketSelection(
    profile: _pickWeightedMarketCandidate(rng: rng, candidates: candidates),
  );
}

bool _hasRunModifierMarketPressure(
  NewRunModifier runModifier,
  BalanceSimMarketProfile marketProfile,
) {
  return runModifier == NewRunModifier.highStakes &&
      marketProfile == BalanceSimMarketProfile.shopSlotMarketV9;
}

List<_WeightedMarketCandidate> _probabilisticMarketCandidates(
  BalanceSimLoadoutSpec loadout,
) {
  final candidates = <_WeightedMarketCandidate>[
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonColorJester,
      16,
      category: 'common_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonRankJester,
      16,
      category: 'common_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuyJolly,
      10,
      category: 'common_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuySly,
      10,
      category: 'common_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester,
      8,
      category: 'uncommon_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1TilePackPlus5,
      9,
      category: 'pack',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuildAwarePackPlus5,
      9,
      category: 'pack',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateTarotBuildPack,
      8,
      category: 'tarot',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel,
      7,
      category: 'planet',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuyDiscardGlove,
      6,
      category: 'item',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateVoucherResource,
      4,
      category: 'voucher',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateRareXmultJester,
      3,
      category: 'rare_jester',
    ),
    const _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateLegendaryBridge,
      1,
      category: 'legendary_proxy',
    ),
  ];
  return candidates
      .map(
        (candidate) => candidate.withWeight(
          candidate.weight +
              _buildAwareMarketWeight(loadout, candidate.profile),
        ),
      )
      .toList(growable: false);
}

List<_WeightedMarketCandidate> _stationWeightedMarketCandidates({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
}) {
  final isBoss = tier == BlindTier.boss;
  final early = station <= 3;
  final mid = station >= 4 && station <= 5;
  final candidates = <_WeightedMarketCandidate>[
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonColorJester,
      early ? 18 : (mid ? 10 : 7),
      category: 'common_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonRankJester,
      early ? 18 : (mid ? 12 : 8),
      category: 'common_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester,
      early ? 8 : (mid ? 12 : 10),
      category: 'uncommon_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1TilePackPlus5,
      early ? 8 : (mid ? 11 : 7),
      category: 'pack',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuildAwarePackPlus5,
      early ? 5 : (mid ? 9 : 6),
      category: 'pack',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateTarotBuildPack,
      early ? 9 : (mid ? 12 : 8),
      category: 'tarot',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel,
      early ? 6 : (mid ? 10 : 13),
      category: 'planet',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuyDiscardGlove,
      early ? 5 : (mid ? 7 : 4),
      category: 'item',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateVoucherResource,
      early ? 3 : (mid ? 5 : 4),
      category: 'voucher',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateRareXmultJester,
      early ? 2 : (mid ? 4 : 6),
      category: 'rare_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateLegendaryBridge,
      station >= 6 || isBoss ? 2 : 1,
      category: 'legendary_proxy',
    ),
  ];
  return candidates
      .map(
        (candidate) => candidate.withWeight(
          candidate.weight +
              (isBoss ? _bossMarketWeight(candidate.profile) : 0) +
              _buildAwareMarketWeight(loadout, candidate.profile),
        ),
      )
      .toList(growable: false);
}

List<_WeightedMarketCandidate> _bandedMarketCandidates({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required bool fastBurstBias,
}) {
  final isBoss = tier == BlindTier.boss;
  final early = station <= 2;
  final mid = station >= 3 && station <= 5;
  final candidates = <_WeightedMarketCandidate>[
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonColorJester,
      early ? (fastBurstBias ? 24 : 22) : (mid ? 8 : (fastBurstBias ? 4 : 5)),
      category: 'common_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateCommonRankJester,
      early ? (fastBurstBias ? 24 : 22) : (mid ? 10 : (fastBurstBias ? 5 : 7)),
      category: 'common_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester,
      early ? (fastBurstBias ? 7 : 5) : (mid ? (fastBurstBias ? 20 : 18) : 12),
      category: 'uncommon_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1TilePackPlus5,
      early ? 10 : (mid ? (fastBurstBias ? 5 : 8) : (fastBurstBias ? 3 : 4)),
      category: 'pack',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuildAwarePackPlus5,
      early ? 6 : (mid ? (fastBurstBias ? 8 : 11) : (fastBurstBias ? 5 : 6)),
      category: 'pack',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateTarotBuildPack,
      early ? (fastBurstBias ? 13 : 12) : (mid ? (fastBurstBias ? 12 : 14) : 4),
      category: 'tarot',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel,
      early ? 4 : (mid ? (fastBurstBias ? 12 : 14) : (fastBurstBias ? 8 : 18)),
      category: 'planet',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1BuyDiscardGlove,
      early ? 5 : (mid ? 5 : (fastBurstBias ? 2 : 3)),
      category: 'item',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateVoucherResource,
      early ? 3 : (mid ? 3 : (fastBurstBias ? 1 : 2)),
      category: 'voucher',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateRareXmultJester,
      early ? 2 : (mid ? (fastBurstBias ? 7 : 5) : (fastBurstBias ? 16 : 9)),
      category: 'rare_jester',
    ),
    _WeightedMarketCandidate(
      BalanceSimMarketProfile.s1CandidateLegendaryBridge,
      early ? 1 : (mid ? 1 : (fastBurstBias ? 5 : 3)),
      category: 'legendary_proxy',
    ),
  ];
  return candidates
      .map(
        (candidate) => candidate.withWeight(
          candidate.weight +
              (isBoss ? _bossMarketWeight(candidate.profile) : 0) +
              _buildAwareMarketWeight(loadout, candidate.profile),
        ),
      )
      .toList(growable: false);
}

List<_WeightedMarketCandidate> _stateWeightedMarketCandidates({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required Map<String, Object?>? previousStepResourceState,
}) {
  final baseCandidates = _stationWeightedMarketCandidates(
    loadout: loadout,
    station: station,
    tier: tier,
  );
  if (previousStepResourceState == null) return baseCandidates;

  final targetScore = _stateInt(previousStepResourceState, 'target_score');
  final finalScore = _stateInt(previousStepResourceState, 'final_score');
  final remainingDeck = _stateInt(previousStepResourceState, 'remaining_deck');
  final remainingBoardDiscards = _stateInt(
    previousStepResourceState,
    'remaining_board_discards',
  );
  final remainingHandDiscards = _stateInt(
    previousStepResourceState,
    'remaining_hand_discards',
  );
  final remainingBoardMoves = _stateInt(
    previousStepResourceState,
    'remaining_board_moves',
  );
  final boardOccupancy = _stateDouble(
    previousStepResourceState,
    'board_occupancy',
  );
  final scoreRatio = targetScore <= 0 ? 1.0 : finalScore / targetScore;

  return baseCandidates
      .map((candidate) {
        var bonus = 0;
        // 직전 전투의 자원 신호만 사용한다. 실제 런 저장/상점 상태는 아직 만들지 않는다.
        if (remainingDeck <= 10) {
          bonus += switch (candidate.profile) {
            BalanceSimMarketProfile.s1TilePackPlus5 ||
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
            BalanceSimMarketProfile.s1CandidateTarotBuildPack => 5,
            BalanceSimMarketProfile.s1CandidateVoucherResource => 3,
            _ => 0,
          };
        } else if (remainingDeck <= 16) {
          bonus += switch (candidate.profile) {
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
            BalanceSimMarketProfile.s1CandidateTarotBuildPack => 3,
            BalanceSimMarketProfile.s1TilePackPlus5 ||
            BalanceSimMarketProfile.s1CandidateVoucherResource => 2,
            _ => 0,
          };
        }

        if (scoreRatio < 0.90) {
          bonus += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 5,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 3,
            BalanceSimMarketProfile.s1CandidateRareXmultJester => 3,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge => 1,
            _ => 0,
          };
        } else if (scoreRatio < 1.08) {
          bonus += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel ||
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 2,
            BalanceSimMarketProfile.s1CandidateRareXmultJester => 1,
            _ => 0,
          };
        }

        final discardPressure =
            remainingBoardDiscards <= 0 || remainingHandDiscards <= 0;
        final boardLockPressure =
            boardOccupancy >= 18 || remainingBoardMoves <= 0 || discardPressure;
        if (boardLockPressure) {
          bonus += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateTarotBuildPack => 4,
            BalanceSimMarketProfile.s1BuyDiscardGlove => 3,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 2,
            BalanceSimMarketProfile.s1CandidateCommonColorJester ||
            BalanceSimMarketProfile.s1CandidateCommonRankJester => 1,
            _ => 0,
          };
        }

        return candidate.withWeight(candidate.weight + bonus);
      })
      .toList(growable: false);
}

List<_WeightedMarketCandidate> _shopSlotMarketCandidates({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required bool tempoBias,
  required bool lateTempoBias,
  required bool lateTempoBiasStrong,
  required bool lateStaticGuard,
  required bool lateStaticGuardStrong,
  required bool boardLockRelief,
  required bool earlyFunBias,
  required bool lateBreakerBias,
  required bool finalShapeFloorStrong,
  required bool missingGrowthBias,
  required bool missingGrowthBiasStrong,
}) {
  final base = _bandedMarketCandidates(
    loadout: loadout,
    station: station,
    tier: tier,
    fastBurstBias: false,
  );
  final late = station >= 6;
  final isBoss = tier == BlindTier.boss;
  final isProgressionRoute = _isProgressionRouteLoadout(loadout);
  return base
      .map((candidate) {
        var weight = candidate.weight;
        // 슬롯형 market은 오래 버티는 후보보다 즉시 방향을 바꾸는 후보를 조금 더 노출한다.
        if (late) {
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateRareXmultJester =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? 6
                        : 4
                  : tempoBias
                  ? 3
                  : 5,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
              lateTempoBias
                  ? 1
                  : tempoBias
                  ? 1
                  : 2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? 1
                        : -1
                  : tempoBias
                  ? -2
                  : -5,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? 3
                        : 2
                  : 0,
            BalanceSimMarketProfile.s1CandidateVoucherResource =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? -7
                        : -5
                  : tempoBias
                  ? -4
                  : -2,
            BalanceSimMarketProfile.s1TilePackPlus5 =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? -7
                        : -5
                  : tempoBias
                  ? -4
                  : -2,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? -5
                        : -4
                  : tempoBias
                  ? -3
                  : 0,
            BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
              lateTempoBias
                  ? lateTempoBiasStrong
                        ? -4
                        : -3
                  : tempoBias
                  ? -2
                  : 0,
            _ => 0,
          };
        }
        if (late && !isProgressionRoute) {
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateRareXmultJester =>
              lateStaticGuardStrong
                  ? -22
                  : lateStaticGuard
                  ? -11
                  : -4,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
              lateStaticGuardStrong
                  ? -16
                  : lateStaticGuard
                  ? -8
                  : -3,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
              lateStaticGuardStrong
                  ? -10
                  : lateStaticGuard
                  ? -5
                  : -2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
              lateStaticGuardStrong
                  ? -9
                  : lateStaticGuard
                  ? -4
                  : 0,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
              lateStaticGuardStrong
                  ? -5
                  : lateStaticGuard
                  ? -2
                  : 0,
            _ => 0,
          };
        }
        if (isBoss) {
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateRareXmultJester =>
              tempoBias ? 3 : 2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
              tempoBias ? 2 : 1,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
              tempoBias ? 1 : 0,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 => tempoBias ? 0 : 1,
            _ => 0,
          };
        }
        if (earlyFunBias && station <= 2) {
          // v8은 초반 재미와 S1~S2 병목 완화를 위해 형상 보정/자원 후보를 더 자주 노출한다.
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateCommonColorJester ||
            BalanceSimMarketProfile.s1CandidateCommonRankJester => 6,
            BalanceSimMarketProfile.s1CandidateTarotBuildPack => 7,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 4,
            BalanceSimMarketProfile.s1TilePackPlus5 => 3,
            BalanceSimMarketProfile.s1BuyDiscardGlove => 3,
            BalanceSimMarketProfile.s1CandidateVoucherResource => 2,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 2,
            BalanceSimMarketProfile.s1CandidateRareXmultJester => 1,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge => 1,
            _ => 0,
          };
        }
        if (lateBreakerBias && station >= 7) {
          // v9는 S7~S8에서 늦게 실패하는 경로를 줄이기 위해 후반 돌파 후보를 더 노출한다.
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateRareXmultJester => 8,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 5,
            BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 4,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge => 2,
            BalanceSimMarketProfile.s1CandidateVoucherResource => 1,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 => -2,
            BalanceSimMarketProfile.s1TilePackPlus5 => -3,
            _ => 0,
          };
        }
        if (lateBreakerBias &&
            station >= 7 &&
            _isFinalBandShapeCorrectionProxy(candidate.profile)) {
          // runtime final band의 shape floor와 같은 의도다.
          // 후보가 마켓에 남도록만 하고, 구매/지급/슬롯 수는 바꾸지 않는다.
          weight += finalShapeFloorStrong ? 12 : 6;
        }
        if (missingGrowthBias && station >= 3 && station <= 5) {
          // v10은 해당 구간까지 성장 축을 못 얻은 경우를 가정해
          // 직접 지급이 아니라 마켓 노출 확률만 보정한다.
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateVoucherResource =>
              missingGrowthBiasStrong ? 10 : 5,
            BalanceSimMarketProfile.s1BuyDiscardGlove =>
              missingGrowthBiasStrong ? 8 : 6,
            BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
              missingGrowthBiasStrong ? 7 : 4,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
              missingGrowthBiasStrong ? 6 : 4,
            BalanceSimMarketProfile.s1TilePackPlus5 =>
              missingGrowthBiasStrong ? 4 : 2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
              missingGrowthBiasStrong ? 3 : 2,
            BalanceSimMarketProfile.s1CandidateRareXmultJester =>
              missingGrowthBiasStrong ? -1 : 0,
            _ => 0,
          };
        }
        if (missingGrowthBias && late) {
          // 후반에는 고갈/락 해소 후보를 완전히 밀어내지 않고 다시 보정한다.
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1CandidateVoucherResource =>
              missingGrowthBiasStrong ? 11 : 5,
            BalanceSimMarketProfile.s1BuyDiscardGlove =>
              missingGrowthBiasStrong ? 7 : 5,
            BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
              missingGrowthBiasStrong ? 6 : 4,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
              missingGrowthBiasStrong ? 5 : 3,
            BalanceSimMarketProfile.s1TilePackPlus5 =>
              missingGrowthBiasStrong ? 4 : 2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 2,
            BalanceSimMarketProfile.s1CandidateRareXmultJester => 2,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge => 1,
            _ => 0,
          };
        }
        if (boardLockRelief) {
          final reliefScale = isProgressionRoute ? 1 : 0;
          weight += switch (candidate.profile) {
            BalanceSimMarketProfile.s1BuyDiscardGlove => 5 + reliefScale,
            BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
              4 + reliefScale,
            BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 1 + reliefScale,
            BalanceSimMarketProfile.s1CandidateCommonColorJester ||
            BalanceSimMarketProfile.s1CandidateCommonRankJester => reliefScale,
            BalanceSimMarketProfile.s1CandidateRareXmultJester => -3,
            BalanceSimMarketProfile.s1CandidateLegendaryBridge => -2,
            BalanceSimMarketProfile.s1CandidatePlanetRankLevel => -2,
            _ => 0,
          };
        }
        return candidate.withWeight(weight.clamp(1, 99));
      })
      .toList(growable: false);
}

int _shopSlotCountForStation(
  int station, {
  required bool tempoBias,
  required bool missingGrowthBias,
  required bool missingGrowthBiasStrong,
}) {
  if (station <= 2) return 3;
  if (station <= 5) return missingGrowthBias ? 5 : 4;
  if (missingGrowthBiasStrong) return 5;
  if (tempoBias) return 4;
  return 5;
}

bool _isProgressionRouteLoadout(BalanceSimLoadoutSpec loadout) {
  return loadout.id.startsWith('progression_route_');
}

bool _hasPreviousBoardLockPressure(Map<String, Object?>? state) {
  if (state == null) return false;
  final remainingBoardDiscards = _stateInt(state, 'remaining_board_discards');
  final remainingHandDiscards = _stateInt(state, 'remaining_hand_discards');
  final remainingBoardMoves = _stateInt(state, 'remaining_board_moves');
  final boardOccupancy = _stateDouble(state, 'board_occupancy');
  return boardOccupancy >= 18 ||
      remainingBoardMoves <= 0 ||
      remainingBoardDiscards <= 0 ||
      remainingHandDiscards <= 0;
}

List<_WeightedMarketCandidate> _rollMarketShopSlots({
  required Random rng,
  required List<_WeightedMarketCandidate> candidates,
  required int slotCount,
}) {
  final remaining = [...candidates];
  final slots = <_WeightedMarketCandidate>[];
  while (slots.length < slotCount && remaining.isNotEmpty) {
    final picked = _pickWeightedMarketCandidate(
      rng: rng,
      candidates: remaining,
    );
    final index = remaining.indexWhere(
      (candidate) => candidate.profile == picked,
    );
    slots.add(remaining.removeAt(index < 0 ? 0 : index));
  }
  return List<_WeightedMarketCandidate>.unmodifiable(slots);
}

BalanceSimMarketProfile _chooseMarketShopSlot({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required List<_WeightedMarketCandidate> slots,
  required bool tempoBias,
  required bool lateTempoBias,
  required bool lateTempoBiasStrong,
  required bool lateStaticGuard,
  required bool lateStaticGuardStrong,
  required bool boardLockRelief,
  required bool earlyFunBias,
  required bool lateBreakerBias,
  required bool finalShapeFloorStrong,
  required bool missingGrowthBias,
  required bool missingGrowthBiasStrong,
}) {
  if (slots.isEmpty) return BalanceSimMarketProfile.none;
  var best = slots.first;
  var bestScore = _shopSlotUtility(
    loadout: loadout,
    station: station,
    tier: tier,
    candidate: best,
    tempoBias: tempoBias,
    lateTempoBias: lateTempoBias,
    lateTempoBiasStrong: lateTempoBiasStrong,
    lateStaticGuard: lateStaticGuard,
    lateStaticGuardStrong: lateStaticGuardStrong,
    boardLockRelief: boardLockRelief,
    earlyFunBias: earlyFunBias,
    lateBreakerBias: lateBreakerBias,
    finalShapeFloorStrong: finalShapeFloorStrong,
    missingGrowthBias: missingGrowthBias,
    missingGrowthBiasStrong: missingGrowthBiasStrong,
  );
  for (final candidate in slots.skip(1)) {
    final score = _shopSlotUtility(
      loadout: loadout,
      station: station,
      tier: tier,
      candidate: candidate,
      tempoBias: tempoBias,
      lateTempoBias: lateTempoBias,
      lateTempoBiasStrong: lateTempoBiasStrong,
      lateStaticGuard: lateStaticGuard,
      lateStaticGuardStrong: lateStaticGuardStrong,
      boardLockRelief: boardLockRelief,
      earlyFunBias: earlyFunBias,
      lateBreakerBias: lateBreakerBias,
      finalShapeFloorStrong: finalShapeFloorStrong,
      missingGrowthBias: missingGrowthBias,
      missingGrowthBiasStrong: missingGrowthBiasStrong,
    );
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best.profile;
}

int _shopSlotUtility({
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required BlindTier tier,
  required _WeightedMarketCandidate candidate,
  required bool tempoBias,
  required bool lateTempoBias,
  required bool lateTempoBiasStrong,
  required bool lateStaticGuard,
  required bool lateStaticGuardStrong,
  required bool boardLockRelief,
  required bool earlyFunBias,
  required bool lateBreakerBias,
  required bool finalShapeFloorStrong,
  required bool missingGrowthBias,
  required bool missingGrowthBiasStrong,
}) {
  final late = station >= 6;
  final boss = tier == BlindTier.boss;
  final isProgressionRoute = _isProgressionRouteLoadout(loadout);
  var score = candidate.weight;
  score += _buildAwareMarketWeight(loadout, candidate.profile) * 2;
  if (boss) score += _bossMarketWeight(candidate.profile);
  if (late) {
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateRareXmultJester =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? 14
                  : 12
            : tempoBias
            ? 10
            : 8,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
        lateTempoBias
            ? 1
            : tempoBias
            ? 2
            : 4,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? 5
                  : 4
            : tempoBias
            ? 3
            : -3,
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? 5
                  : 4
            : tempoBias
            ? 3
            : 0,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? -5
                  : -4
            : tempoBias
            ? -3
            : 0,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? -7
                  : -5
            : tempoBias
            ? -4
            : 0,
      BalanceSimMarketProfile.s1TilePackPlus5 =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? -8
                  : -6
            : tempoBias
            ? -5
            : 0,
      BalanceSimMarketProfile.s1CandidateVoucherResource =>
        lateTempoBias
            ? lateTempoBiasStrong
                  ? -9
                  : -7
            : tempoBias
            ? -6
            : -4,
      _ => 0,
    };
  }
  if (missingGrowthBiasStrong && station >= 3 && station <= 5) {
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateVoucherResource => 9,
      BalanceSimMarketProfile.s1BuyDiscardGlove => 7,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 6,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 5,
      BalanceSimMarketProfile.s1TilePackPlus5 => 3,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 2,
      _ => 0,
    };
  }
  if (missingGrowthBiasStrong && late) {
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateVoucherResource => 10,
      BalanceSimMarketProfile.s1BuyDiscardGlove => 7,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 5,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 5,
      BalanceSimMarketProfile.s1TilePackPlus5 => 3,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 2,
      _ => 0,
    };
  }
  if (late && !isProgressionRoute) {
    // 고정 단일 빌드가 후반 rare 한 번으로 전체 경로를 뚫는 현상을 막는다.
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateRareXmultJester =>
        lateStaticGuardStrong
            ? -60
            : lateStaticGuard
            ? -34
            : -16,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
        lateStaticGuardStrong
            ? -42
            : lateStaticGuard
            ? -22
            : -10,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
        lateStaticGuardStrong
            ? -28
            : lateStaticGuard
            ? -14
            : -6,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
        lateStaticGuardStrong
            ? -24
            : lateStaticGuard
            ? -12
            : -4,
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
        lateStaticGuardStrong
            ? -14
            : lateStaticGuard
            ? -7
            : 0,
      _ => 0,
    };
  }
  if (boardLockRelief) {
    final reliefScale = isProgressionRoute ? 1 : 0;
    // 직전 전투가 잠겼을 때만 형상 보정 후보를 우선한다.
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1BuyDiscardGlove => 10 + reliefScale * 2,
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 8 + reliefScale * 2,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 3 + reliefScale,
      BalanceSimMarketProfile.s1CandidateCommonColorJester ||
      BalanceSimMarketProfile.s1CandidateCommonRankJester => reliefScale,
      BalanceSimMarketProfile.s1CandidateRareXmultJester => -7,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge => -5,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => -4,
      _ => 0,
    };
  }
  if (station <= 2) {
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateCommonColorJester ||
      BalanceSimMarketProfile.s1CandidateCommonRankJester ||
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 3,
      _ => 0,
    };
  }
  if (earlyFunBias && station <= 2) {
    // bot proxy도 초반에는 막히지 않는 선택을 조금 더 선호한다.
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateTarotBuildPack => 10,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 7,
      BalanceSimMarketProfile.s1CandidateCommonColorJester ||
      BalanceSimMarketProfile.s1CandidateCommonRankJester => 6,
      BalanceSimMarketProfile.s1BuyDiscardGlove => 5,
      BalanceSimMarketProfile.s1TilePackPlus5 => 4,
      BalanceSimMarketProfile.s1CandidateVoucherResource => 3,
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 2,
      BalanceSimMarketProfile.s1CandidateRareXmultJester => 1,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge => 1,
      _ => 0,
    };
  }
  if (lateBreakerBias && station >= 7) {
    // 후반은 오래 버티기보다 돌파 기대값이 높은 후보를 bot proxy가 고른다.
    score += switch (candidate.profile) {
      BalanceSimMarketProfile.s1CandidateRareXmultJester => 16,
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel => 8,
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester => 7,
      BalanceSimMarketProfile.s1CandidateLegendaryBridge => 4,
      BalanceSimMarketProfile.s1CandidateVoucherResource => 2,
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 => -4,
      BalanceSimMarketProfile.s1TilePackPlus5 => -5,
      _ => 0,
    };
  }
  if (lateBreakerBias &&
      station >= 7 &&
      _isFinalBandShapeCorrectionProxy(candidate.profile)) {
    // slot 노출 floor와 bot 선택 proxy를 같은 방향으로 맞춘다.
    // rare/xmult/boss 후보보다 우선시키는 값은 아니다.
    score += finalShapeFloorStrong ? 14 : 8;
  }
  return score;
}

bool _isFinalBandShapeCorrectionProxy(BalanceSimMarketProfile profile) {
  return switch (profile) {
    BalanceSimMarketProfile.s1TilePackPlus5 ||
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
    BalanceSimMarketProfile.s1CandidateTarotBuildPack => true,
    _ => false,
  };
}

int _stateInt(Map<String, Object?> state, String key) {
  final value = state[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}

double _stateDouble(Map<String, Object?> state, String key) {
  final value = state[key];
  if (value is num) return value.toDouble();
  return 0;
}

BalanceSimBacklogCandidate _pickWeightedBacklogCandidate({
  required Random rng,
  required BalanceSimLoadoutSpec loadout,
  BalanceSimMarketProfile? rolePool,
}) {
  final candidates = _safeBacklogCandidates()
      .where((candidate) => _matchesBacklogRolePool(candidate, rolePool))
      .map(
        (candidate) => candidate.withWeight(
          candidate.weight +
              _buildAwareMarketWeight(loadout, candidate.proxyProfile),
        ),
      )
      .toList(growable: false);
  if (candidates.isEmpty) {
    throw StateError(
      'No safe Balatro adaptation candidates for ${rolePool?.id}.',
    );
  }
  final totalWeight = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  var roll = rng.nextInt(totalWeight);
  for (final candidate in candidates) {
    roll -= candidate.weight;
    if (roll < 0) return candidate;
  }
  return candidates.last;
}

bool _isBacklogRolePool(BalanceSimMarketProfile marketProfile) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1RoleDeckSustainPool ||
    BalanceSimMarketProfile.s1RoleScoreGrowthPool ||
    BalanceSimMarketProfile.s1RoleShapeFixPool ||
    BalanceSimMarketProfile.s1RoleWeakFlavorPool => true,
    _ => false,
  };
}

bool _matchesBacklogRolePool(
  BalanceSimBacklogCandidate candidate,
  BalanceSimMarketProfile? rolePool,
) {
  if (rolePool == null ||
      rolePool == BalanceSimMarketProfile.s1FullSafeCandidatePool) {
    return true;
  }

  final profile = candidate.proxyProfile;
  return switch (rolePool) {
    // 덱 압박을 줄이는 축이다. 타일 추가, 선택지 보정, 자원 보강 proxy만 본다.
    BalanceSimMarketProfile.s1RoleDeckSustainPool =>
      profile == BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
          profile == BalanceSimMarketProfile.s1CandidateTarotBuildPack ||
          profile == BalanceSimMarketProfile.s1CandidateVoucherResource,

    // 점수 성장 축이다. Jester/Planet 계열 성장을 모아 승률과 과성장을 분리해서 본다.
    BalanceSimMarketProfile.s1RoleScoreGrowthPool =>
      profile == BalanceSimMarketProfile.s1CandidateCommonColorJester ||
          profile == BalanceSimMarketProfile.s1CandidateCommonRankJester ||
          profile == BalanceSimMarketProfile.s1CandidateUncommonBuildJester ||
          profile == BalanceSimMarketProfile.s1CandidateRareXmultJester ||
          profile == BalanceSimMarketProfile.s1CandidateLegendaryBridge ||
          profile == BalanceSimMarketProfile.s1CandidatePlanetRankLevel,

    // 형태 보정 축이다. 족보/색/숫자 모양을 맞추는 proxy만 묶는다.
    BalanceSimMarketProfile.s1RoleShapeFixPool =>
      profile == BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
          profile == BalanceSimMarketProfile.s1CandidateTarotBuildPack ||
          profile == BalanceSimMarketProfile.s1CandidateCommonColorJester ||
          profile == BalanceSimMarketProfile.s1CandidateCommonRankJester ||
          profile == BalanceSimMarketProfile.s1CandidateUncommonBuildJester,

    // 약한 후보도 실제 마켓에는 필요하므로 강한 rare/legendary와 Pack 상한선을 뺀다.
    BalanceSimMarketProfile.s1RoleWeakFlavorPool =>
      profile == BalanceSimMarketProfile.s1CandidateCommonColorJester ||
          profile == BalanceSimMarketProfile.s1CandidateCommonRankJester ||
          profile == BalanceSimMarketProfile.s1CandidateTarotBuildPack ||
          profile == BalanceSimMarketProfile.s1CandidateVoucherResource,
    _ => true,
  };
}

List<BalanceSimBacklogCandidate>? _cachedSafeBacklogCandidates;

List<BalanceSimBacklogCandidate> _safeBacklogCandidates() {
  final cached = _cachedSafeBacklogCandidates;
  if (cached != null) return cached;

  final file = File(_balatroBacklogPath);
  if (!file.existsSync()) {
    throw StateError(
      'Missing Balatro adaptation backlog: $_balatroBacklogPath',
    );
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final items = (json['items'] as List<dynamic>).cast<Map<String, Object?>>();
  final candidates = <BalanceSimBacklogCandidate>[];
  for (final item in items) {
    final candidate = _safeBacklogCandidateFromJson(item);
    if (candidate != null) candidates.add(candidate);
  }
  if (candidates.isEmpty) {
    throw StateError('No safe Balatro adaptation candidates were resolved.');
  }
  _cachedSafeBacklogCandidates = List.unmodifiable(candidates);
  return _cachedSafeBacklogCandidates!;
}

BalanceSimBacklogCandidate? _safeBacklogCandidateFromJson(
  Map<String, Object?> item,
) {
  final priority = item['priority']?.toString();
  if (priority != '1' && priority != '2') return null;

  final adaptedId = item['adapted_id']?.toString() ?? '';
  final category = item['adapted_category']?.toString() ?? '';
  final rarity = item['adapted_rarity']?.toString();
  final effectFamily = item['effect_family']?.toString() ?? '';
  final runtimeStatus = item['runtime_status']?.toString() ?? '';
  final mappingStatus = item['mapping_status']?.toString() ?? '';
  final sourceName = item['source_en_name']?.toString() ?? '';
  final notes = ((item['notes'] as List<dynamic>?) ?? const [])
      .map((note) => note.toString())
      .join(' ');
  final haystack =
      '$adaptedId $category $rarity $effectFamily $runtimeStatus '
              '$mappingStatus $sourceName $notes'
          .toLowerCase();

  const blockedTokens = [
    'copy',
    'destroy',
    'sell',
    'rental',
    'eternal',
    'negative',
    'unlock',
    'collection',
    'duplicate',
    'remove',
    'edition',
    'seal',
    'spectral',
    'high_card',
    'high card',
  ];
  if (blockedTokens.any(haystack.contains)) return null;
  if (mappingStatus == 'defer') return null;

  final proxyProfile = _proxyProfileForBacklogCandidate(
    category: category,
    rarity: rarity,
    effectFamily: effectFamily,
    runtimeStatus: runtimeStatus,
    adaptedId: adaptedId,
  );
  if (proxyProfile == null) return null;

  return BalanceSimBacklogCandidate(
    adaptedId: adaptedId,
    sourceName: sourceName,
    category: category,
    rarity: rarity,
    priority: int.parse(priority!),
    effectFamily: effectFamily,
    runtimeStatus: runtimeStatus,
    proxyProfile: proxyProfile,
    weight: _backlogCandidateBaseWeight(
      category: category,
      rarity: rarity,
      effectFamily: effectFamily,
      proxyProfile: proxyProfile,
    ),
  );
}

BalanceSimMarketProfile? _proxyProfileForBacklogCandidate({
  required String category,
  required String? rarity,
  required String effectFamily,
  required String runtimeStatus,
  required String adaptedId,
}) {
  final family = effectFamily.toLowerCase();
  final id = adaptedId.toLowerCase();

  if (category == 'item_planet') {
    return BalanceSimMarketProfile.s1CandidatePlanetRankLevel;
  }
  if (category == 'item_tarot') {
    if (family.contains('economy')) {
      return BalanceSimMarketProfile.s1CandidateVoucherResource;
    }
    if (family.contains('content_generation')) {
      return BalanceSimMarketProfile.s1BuildAwarePackPlus5;
    }
    return BalanceSimMarketProfile.s1CandidateTarotBuildPack;
  }
  if (category == 'item_voucher') {
    if (family.contains('rarity') || id.contains('pack')) {
      return BalanceSimMarketProfile.s1BuildAwarePackPlus5;
    }
    return BalanceSimMarketProfile.s1CandidateVoucherResource;
  }
  if (category != 'jester') return null;

  if (family.contains('tile_color')) {
    return BalanceSimMarketProfile.s1CandidateCommonColorJester;
  }
  if (family.contains('tile_number')) {
    return BalanceSimMarketProfile.s1CandidateUncommonBuildJester;
  }
  if (family.contains('hand_rank_chips') || family.contains('hand_rank_mult')) {
    return rarity == 'rare'
        ? BalanceSimMarketProfile.s1CandidateRareXmultJester
        : BalanceSimMarketProfile.s1CandidateCommonRankJester;
  }
  if (family.contains('xmult')) {
    return BalanceSimMarketProfile.s1CandidateRareXmultJester;
  }
  if (family.contains('resource_capacity') ||
      family.contains('resource_scaled') ||
      family.contains('economy')) {
    return BalanceSimMarketProfile.s1CandidateVoucherResource;
  }
  if (family.contains('stateful_growth')) {
    return BalanceSimMarketProfile.s1CandidatePlanetRankLevel;
  }
  if (runtimeStatus.contains('small_system_extension')) {
    return BalanceSimMarketProfile.s1CandidateUncommonBuildJester;
  }
  if (rarity == 'rare') {
    return BalanceSimMarketProfile.s1CandidateRareXmultJester;
  }
  if (rarity == 'uncommon') {
    return BalanceSimMarketProfile.s1CandidateUncommonBuildJester;
  }
  return BalanceSimMarketProfile.s1CandidateCommonRankJester;
}

int _backlogCandidateBaseWeight({
  required String category,
  required String? rarity,
  required String effectFamily,
  required BalanceSimMarketProfile proxyProfile,
}) {
  if (proxyProfile == BalanceSimMarketProfile.s1CandidateLegendaryBridge) {
    return 1;
  }
  if (category == 'jester') {
    return switch (rarity) {
      'common' => 12,
      'uncommon' => 6,
      'rare' => 2,
      _ => 4,
    };
  }
  if (category == 'item_voucher') return 3;
  if (category == 'item_planet') return 7;
  if (category == 'item_tarot') return 7;
  return 1;
}

class BalanceSimMarketSelection {
  const BalanceSimMarketSelection({
    required this.profile,
    this.sourceCandidate,
    this.shopSlots = const [],
  });

  final BalanceSimMarketProfile profile;
  final BalanceSimBacklogCandidate? sourceCandidate;
  final List<BalanceSimMarketProfile> shopSlots;
}

class BalanceSimBacklogCandidate {
  const BalanceSimBacklogCandidate({
    required this.adaptedId,
    required this.sourceName,
    required this.category,
    required this.rarity,
    required this.priority,
    required this.effectFamily,
    required this.runtimeStatus,
    required this.proxyProfile,
    required this.weight,
  });

  final String adaptedId;
  final String sourceName;
  final String category;
  final String? rarity;
  final int priority;
  final String effectFamily;
  final String runtimeStatus;
  final BalanceSimMarketProfile proxyProfile;
  final int weight;

  BalanceSimBacklogCandidate withWeight(int value) {
    return BalanceSimBacklogCandidate(
      adaptedId: adaptedId,
      sourceName: sourceName,
      category: category,
      rarity: rarity,
      priority: priority,
      effectFamily: effectFamily,
      runtimeStatus: runtimeStatus,
      proxyProfile: proxyProfile,
      weight: value,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'adapted_id': adaptedId,
      'source_name': sourceName,
      'category': category,
      'rarity': rarity,
      'priority': priority,
      'effect_family': effectFamily,
      'runtime_status': runtimeStatus,
      'proxy_profile': proxyProfile.id,
      'weight': weight,
    };
  }
}

class _WeightedMarketCandidate {
  const _WeightedMarketCandidate(
    this.profile,
    this.weight, {
    required this.category,
  });

  final BalanceSimMarketProfile profile;
  final int weight;
  final String category;

  _WeightedMarketCandidate withWeight(int value) {
    return _WeightedMarketCandidate(profile, value, category: category);
  }
}

int _buildAwareMarketWeight(
  BalanceSimLoadoutSpec loadout,
  BalanceSimMarketProfile profile,
) {
  final jesterIds = loadout.jesterIds.toSet();
  final itemIds = loadout.itemIds.toSet();
  final likesRankHands = jesterIds.any(
    (id) =>
        id == 'jolly_jester' ||
        id == 'zany_jester' ||
        id == 'sly_jester' ||
        id == 'the_duo' ||
        id == 'the_trio' ||
        id == 'the_family',
  );
  final likesNumberShape = jesterIds.any(
    (id) => id == 'fibonacci' || id == 'even_steven' || id == 'odd_todd',
  );
  final hasScoreEngine = jesterIds.any(
    (id) => id == 'supernova' || id == 'green_jester' || id == 'banner',
  );
  final hasResourceSupport = itemIds.any(
    (id) => id == 'travel_pouch' || id == 'organizer_glove',
  );

  return switch (profile) {
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
    BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
      likesRankHands || likesNumberShape ? 5 : 1,
    BalanceSimMarketProfile.s1CandidateCommonRankJester =>
      likesRankHands ? 4 : 0,
    BalanceSimMarketProfile.s1CandidateCommonColorJester =>
      likesNumberShape ? 0 : 2,
    BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
      hasScoreEngine ? 2 : 4,
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
      hasScoreEngine ? 5 : 2,
    BalanceSimMarketProfile.s1CandidateVoucherResource =>
      hasResourceSupport ? 1 : 4,
    BalanceSimMarketProfile.s1CandidateRareXmultJester =>
      likesRankHands ? 3 : 1,
    BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
      likesRankHands ? 1 : 0,
    _ => 0,
  };
}

int _bossMarketWeight(BalanceSimMarketProfile profile) {
  return switch (profile) {
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
    BalanceSimMarketProfile.s1TilePackPlus5 ||
    BalanceSimMarketProfile.s1CandidateTarotBuildPack => 2,
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel ||
    BalanceSimMarketProfile.s1CandidateRareXmultJester => 3,
    BalanceSimMarketProfile.s1CandidateVoucherResource ||
    BalanceSimMarketProfile.s1CandidateLegendaryBridge => 1,
    _ => 0,
  };
}

BalanceSimMarketProfile _pickWeightedMarketCandidate({
  required Random rng,
  required List<_WeightedMarketCandidate> candidates,
}) {
  final totalWeight = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  var roll = rng.nextInt(totalWeight);
  for (final candidate in candidates) {
    roll -= candidate.weight;
    if (roll < 0) return candidate.profile;
  }
  return candidates.last.profile;
}

String _colorJesterForLoadout(BalanceSimLoadoutSpec loadout) {
  final idHash = loadout.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
  const candidates = [
    'greedy_jester',
    'lusty_jester',
    'wrathful_jester',
    'gluttonous_jester',
  ];
  return candidates[idHash % candidates.length];
}

String _rankJesterForLoadout(BalanceSimLoadoutSpec loadout) {
  final ids = loadout.jesterIds.toSet();
  if (ids.contains('zany_jester')) return 'zany_jester';
  if (ids.contains('sly_jester')) return 'sly_jester';
  return 'jolly_jester';
}

String _buildJesterForLoadout(BalanceSimLoadoutSpec loadout) {
  final ids = loadout.jesterIds.toSet();
  if (ids.contains('fibonacci')) return 'even_steven';
  if (ids.contains('even_steven')) return 'odd_todd';
  if (ids.contains('banner')) return 'green_jester';
  if (ids.contains('supernova')) return 'banner';
  return 'fibonacci';
}

String _rareXmultJesterForLoadout(BalanceSimLoadoutSpec loadout) {
  final ids = loadout.jesterIds.toSet();
  if (ids.contains('the_duo')) return 'the_trio';
  if (ids.contains('the_trio')) return 'the_family';
  if (ids.contains('the_order')) return 'the_tribe';
  if (ids.contains('fibonacci')) return 'the_order';
  return 'the_duo';
}

BalanceSimLoadoutSpec _simMarketLoadoutGrowth(
  BalanceSimMarketProfile marketProfile,
) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1CandidateVoucherResource =>
      const BalanceSimLoadoutSpec(
        id: 'sim_voucher_resource_growth',
        jesterIds: [],
        itemIds: [],
        maxHandSizeDelta: 1,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 1,
      ),
    _ => const BalanceSimLoadoutSpec(id: 'none', jesterIds: [], itemIds: []),
  };
}

String _simCandidateProxyEffect(BalanceSimMarketProfile marketProfile) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1CandidateCommonColorJester =>
      'priority_1_common_jester_color_scored_mult',
    BalanceSimMarketProfile.s1CandidateCommonRankJester =>
      'priority_1_common_jester_hand_rank_score',
    BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
      'priority_1_2_uncommon_jester_build_score',
    BalanceSimMarketProfile.s1CandidateRareXmultJester =>
      'priority_1_2_rare_jester_xmult',
    BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
      'very_low_probability_strong_rare_legendary_proxy',
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
      'planet_like_rank_level_growth',
    BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
      'tarot_like_build_aware_tile_shape',
    BalanceSimMarketProfile.s1CandidateVoucherResource =>
      'voucher_like_run_wide_resource_growth',
    _ => 'none',
  };
}

int? _simPackCost(BalanceSimMarketProfile marketProfile) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1TilePackSmall => 4,
    BalanceSimMarketProfile.s1TilePackPlus3 => 6,
    BalanceSimMarketProfile.s1TilePackPlus4 => 7,
    BalanceSimMarketProfile.s1TilePackPlus5 => 8,
    BalanceSimMarketProfile.s1BuildAwarePackPlus3 => 7,
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 9,
    BalanceSimMarketProfile.s1PairSeedPack => 5,
    BalanceSimMarketProfile.s1ColorSeedPack => 5,
    BalanceSimMarketProfile.s1FaceSeedPack => 5,
    BalanceSimMarketProfile.s1CandidateTarotBuildPack => 4,
    _ => null,
  };
}

int _simPackAddedTileCount(BalanceSimMarketProfile marketProfile) {
  return switch (marketProfile) {
    BalanceSimMarketProfile.s1TilePackSmall => 2,
    BalanceSimMarketProfile.s1TilePackPlus3 => 3,
    BalanceSimMarketProfile.s1TilePackPlus4 => 4,
    BalanceSimMarketProfile.s1TilePackPlus5 => 5,
    BalanceSimMarketProfile.s1BuildAwarePackPlus3 => 3,
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 => 5,
    BalanceSimMarketProfile.s1PairSeedPack ||
    BalanceSimMarketProfile.s1ColorSeedPack ||
    BalanceSimMarketProfile.s1FaceSeedPack => 2,
    BalanceSimMarketProfile.s1CandidateTarotBuildPack => 3,
    _ => 0,
  };
}

List<Tile> _applySimMarketPackDeckTiles({
  required RummiPokerGridSession session,
  required BalanceSimMarketProfile marketProfile,
  required BalanceSimLoadoutSpec loadout,
  required int station,
  required int runSeed,
}) {
  if (station <= 1) return const [];
  final count = _simPackAddedTileCount(marketProfile);
  if (count <= 0) return const [];

  final rng = Random(runSeed + station * 9973 + marketProfile.index * 7919);
  final addedTiles = _buildSimPackAddedTiles(
    marketProfile: marketProfile,
    loadout: loadout,
    rng: rng,
    count: count,
  );
  if (addedTiles.isEmpty) return const [];

  final source = [...session.deck.snapshotPile(), ...addedTiles];
  session.deck.resetShuffled(random: rng, source: source);
  return List<Tile>.unmodifiable(addedTiles);
}

List<Tile> _buildSimPackAddedTiles({
  required BalanceSimMarketProfile marketProfile,
  required BalanceSimLoadoutSpec loadout,
  required Random rng,
  required int count,
}) {
  const colors = TileColor.values;
  Tile tileAt({
    required int index,
    required TileColor color,
    required int number,
  }) {
    return Tile(color: color, number: number, id: 1000 + index);
  }

  return switch (marketProfile) {
    BalanceSimMarketProfile.s1TilePackSmall ||
    BalanceSimMarketProfile.s1TilePackPlus3 ||
    BalanceSimMarketProfile.s1TilePackPlus4 ||
    BalanceSimMarketProfile.s1TilePackPlus5 => List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: 1 + rng.nextInt(13),
      ),
      growable: false,
    ),
    BalanceSimMarketProfile.s1BuildAwarePackPlus3 ||
    BalanceSimMarketProfile.s1BuildAwarePackPlus5 ||
    BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
      _buildSimBuildAwareTiles(loadout: loadout, rng: rng, count: count),
    BalanceSimMarketProfile.s1PairSeedPack => () {
      final number = 1 + rng.nextInt(13);
      return List<Tile>.generate(
        count,
        (index) => tileAt(
          index: index,
          color: colors[(rng.nextInt(colors.length) + index) % colors.length],
          number: number,
        ),
        growable: false,
      );
    }(),
    BalanceSimMarketProfile.s1ColorSeedPack => () {
      final color = colors[rng.nextInt(colors.length)];
      return List<Tile>.generate(
        count,
        (index) =>
            tileAt(index: index, color: color, number: 1 + rng.nextInt(13)),
        growable: false,
      );
    }(),
    BalanceSimMarketProfile.s1FaceSeedPack => List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: 11 + rng.nextInt(3),
      ),
      growable: false,
    ),
    BalanceSimMarketProfile.s1RandomCandidatePool ||
    BalanceSimMarketProfile.s1ProbabilisticCandidatePool ||
    BalanceSimMarketProfile.bandedCandidatePoolV1 ||
    BalanceSimMarketProfile.bandedCandidatePoolV2 ||
    BalanceSimMarketProfile.shopSlotMarketV1 ||
    BalanceSimMarketProfile.shopSlotMarketV2 ||
    BalanceSimMarketProfile.shopSlotMarketV3 ||
    BalanceSimMarketProfile.shopSlotMarketV10 ||
    BalanceSimMarketProfile.shopSlotMarketV11 ||
    BalanceSimMarketProfile.shopSlotMarketV12 ||
    BalanceSimMarketProfile.shopSlotMarketV13 ||
    BalanceSimMarketProfile.s1CandidateCommonColorJester ||
    BalanceSimMarketProfile.s1CandidateCommonRankJester ||
    BalanceSimMarketProfile.s1CandidateUncommonBuildJester ||
    BalanceSimMarketProfile.s1CandidateRareXmultJester ||
    BalanceSimMarketProfile.s1CandidateLegendaryBridge ||
    BalanceSimMarketProfile.s1CandidatePlanetRankLevel ||
    BalanceSimMarketProfile.s1CandidateVoucherResource => const [],
    _ => const [],
  };
}

List<Tile> _buildSimBuildAwareTiles({
  required BalanceSimLoadoutSpec loadout,
  required Random rng,
  required int count,
}) {
  const colors = TileColor.values;
  Tile tileAt({
    required int index,
    required TileColor color,
    required int number,
  }) {
    return Tile(color: color, number: number, id: 2000 + index);
  }

  final jesterIds = loadout.jesterIds.toSet();
  if (jesterIds.contains('the_tribe') ||
      jesterIds.any((id) => id.contains('flush'))) {
    final color = colors[rng.nextInt(colors.length)];
    return List<Tile>.generate(
      count,
      (index) =>
          tileAt(index: index, color: color, number: 1 + rng.nextInt(13)),
      growable: false,
    );
  }

  if (jesterIds.contains('the_order')) {
    final start = 1 + rng.nextInt(14 - count);
    return List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: start + index,
      ),
      growable: false,
    );
  }

  if (jesterIds.contains('fibonacci')) {
    const numbers = [2, 3, 5, 8, 13];
    return List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: numbers[(rng.nextInt(numbers.length) + index) % numbers.length],
      ),
      growable: false,
    );
  }

  if (jesterIds.contains('even_steven')) {
    const numbers = [2, 4, 6, 8, 10, 12];
    return List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: numbers[(rng.nextInt(numbers.length) + index) % numbers.length],
      ),
      growable: false,
    );
  }

  if (jesterIds.contains('odd_todd')) {
    const numbers = [1, 3, 5, 7, 9, 11, 13];
    return List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[rng.nextInt(colors.length)],
        number: numbers[(rng.nextInt(numbers.length) + index) % numbers.length],
      ),
      growable: false,
    );
  }

  if (jesterIds.any(
    (id) =>
        id == 'the_duo' ||
        id == 'the_trio' ||
        id == 'the_family' ||
        id == 'jolly_jester' ||
        id == 'zany_jester' ||
        id == 'sly_jester',
  )) {
    final number = 1 + rng.nextInt(13);
    return List<Tile>.generate(
      count,
      (index) => tileAt(
        index: index,
        color: colors[(rng.nextInt(colors.length) + index) % colors.length],
        number: number,
      ),
      growable: false,
    );
  }

  final anchorNumber = 1 + rng.nextInt(13);
  final anchorColor = colors[rng.nextInt(colors.length)];
  return List<Tile>.generate(
    count,
    (index) => tileAt(
      index: index,
      color: index.isEven ? anchorColor : colors[rng.nextInt(colors.length)],
      number: index.isEven ? anchorNumber : 1 + rng.nextInt(13),
    ),
    growable: false,
  );
}

bool _isSimPackProfile(BalanceSimMarketProfile marketProfile) {
  return _simPackAddedTileCount(marketProfile) > 0;
}

void _addUnique(List<String> values, String value) {
  if (!values.contains(value)) values.add(value);
}

String _tempoRiskLabel({
  required int slowClearCount,
  required int clearCount,
  required num avgTurnCount,
}) {
  if (slowClearCount == 0 || clearCount == 0) return 'none';
  if (avgTurnCount > _slowClearTurnThreshold) return 'clear_but_too_slow';
  return 'some_slow_clears';
}

List<String> _mlLabelV1({
  required num clearRate,
  required num avgScoreRatio,
  required num avgTurnCount,
  required num avgMaxSingleConfirmScore,
  required num? avgLastScoreTurn,
  required String tempoRiskLabel,
  required Map<String, int> outcomeCounts,
}) {
  final labels = <String>[];
  final tempoDrag = tempoRiskLabel == 'clear_but_too_slow';
  final tooHard =
      clearRate < 0.25 ||
      outcomeCounts.containsKey('deck_exhausted') && avgScoreRatio < 0.85;
  final tooEasy = clearRate > 0.85 && avgTurnCount < 90 && !tempoDrag;
  final spikyFun =
      !tempoDrag &&
      (avgMaxSingleConfirmScore >= 110 || (avgLastScoreTurn ?? 0) >= 85);
  final goodPlayfeel =
      !tooHard && !tooEasy && !tempoDrag && spikyFun && clearRate >= 0.35;

  if (tooHard) labels.add('too_hard');
  if (tooEasy) labels.add('too_easy');
  if (tempoDrag) labels.add('tempo_drag');
  if (spikyFun) labels.add('spiky_fun');
  if (goodPlayfeel) labels.add('good_playfeel');
  if (tooHard || tooEasy || tempoDrag) {
    labels.add('needs_balance_attention');
  }
  if (labels.isEmpty) labels.add('neutral');
  return List.unmodifiable(labels);
}

Map<String, String> _mlTargetLabelsV2({
  required num clearRate,
  required num avgScoreRatio,
  required num avgTurnCount,
  required num avgConfirmActionCount,
  required num avgMaxSingleConfirmScore,
  required num? avgLastScoreTurn,
  required num avgRemainingDeck,
  required num avgRemainingBoardDiscards,
  required num avgRemainingHandDiscards,
  required num avgRemainingBoardMoves,
  required String tempoRiskLabel,
  required Map<String, int> outcomeCounts,
}) {
  return <String, String>{
    'difficulty': _difficultyTargetV2(
      clearRate: clearRate,
      avgScoreRatio: avgScoreRatio,
      outcomeCounts: outcomeCounts,
    ),
    'tempo': _tempoTargetV2(
      clearRate: clearRate,
      avgTurnCount: avgTurnCount,
      tempoRiskLabel: tempoRiskLabel,
    ),
    'resource_pressure': _resourcePressureTargetV2(
      clearRate: clearRate,
      avgRemainingDeck: avgRemainingDeck,
      avgRemainingBoardDiscards: avgRemainingBoardDiscards,
      avgRemainingHandDiscards: avgRemainingHandDiscards,
      avgRemainingBoardMoves: avgRemainingBoardMoves,
    ),
    'score_spike': _scoreSpikeTargetV2(
      avgMaxSingleConfirmScore: avgMaxSingleConfirmScore,
      avgLastScoreTurn: avgLastScoreTurn,
    ),
    'decision_density': _decisionDensityTargetV2(
      avgConfirmActionCount: avgConfirmActionCount,
      avgTurnCount: avgTurnCount,
    ),
  };
}

String _difficultyTargetV2({
  required num clearRate,
  required num avgScoreRatio,
  required Map<String, int> outcomeCounts,
}) {
  if (clearRate < 0.25 ||
      (outcomeCounts.containsKey('deck_exhausted') && avgScoreRatio < 0.85)) {
    return 'too_hard';
  }
  if (clearRate > 0.9 && avgScoreRatio > 1.35) return 'too_easy';
  if (clearRate >= 0.45 && clearRate <= 0.85) return 'difficulty_ok';
  return 'difficulty_watch';
}

String _tempoTargetV2({
  required num clearRate,
  required num avgTurnCount,
  required String tempoRiskLabel,
}) {
  if (tempoRiskLabel == 'clear_but_too_slow' || avgTurnCount > 125) {
    return 'tempo_drag';
  }
  if (clearRate > 0.85 && avgTurnCount < 70) return 'tempo_too_fast';
  if (avgTurnCount >= 80 && avgTurnCount <= 115) return 'tempo_ok';
  return 'tempo_watch';
}

String _resourcePressureTargetV2({
  required num clearRate,
  required num avgRemainingDeck,
  required num avgRemainingBoardDiscards,
  required num avgRemainingHandDiscards,
  required num avgRemainingBoardMoves,
}) {
  final remainingActionResources =
      avgRemainingBoardDiscards +
      avgRemainingHandDiscards +
      avgRemainingBoardMoves;
  if (clearRate < 0.35 && avgRemainingDeck < 4) return 'deck_pressure_high';
  if (clearRate < 0.35 && remainingActionResources < 1.5) {
    return 'resource_starved';
  }
  if (clearRate > 0.85 &&
      avgRemainingDeck > 12 &&
      remainingActionResources > 4) {
    return 'resource_too_loose';
  }
  return 'resource_ok';
}

String _scoreSpikeTargetV2({
  required num avgMaxSingleConfirmScore,
  required num? avgLastScoreTurn,
}) {
  if (avgMaxSingleConfirmScore >= 150) return 'spike_high';
  if (avgMaxSingleConfirmScore >= 110 || (avgLastScoreTurn ?? 0) >= 85) {
    return 'spike_ok';
  }
  return 'spike_flat';
}

String _decisionDensityTargetV2({
  required num avgConfirmActionCount,
  required num avgTurnCount,
}) {
  if (avgConfirmActionCount < 2 && avgTurnCount > 90) return 'low_agency';
  if (avgConfirmActionCount > 8 && avgTurnCount > 120) return 'too_many_steps';
  return 'agency_ok';
}

bool _needsBalanceAttentionV2(Map<String, String> labels) {
  const attentionLabels = {
    'too_hard',
    'too_easy',
    'tempo_drag',
    'tempo_too_fast',
    'deck_pressure_high',
    'resource_starved',
    'resource_too_loose',
    'spike_flat',
    'low_agency',
    'too_many_steps',
  };
  return labels.values.any(attentionLabels.contains);
}

Map<String, Object?> _runSingleBattle({
  required BalanceSimCliConfig config,
  required BalanceSimRunSpec spec,
  required int runIndex,
  required BalanceSimBotPolicy bot,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  final runSeed = config.seed + spec.seedOffset * config.runs + runIndex;
  final station = spec.station;
  final tier = spec.blindTier;
  final blindSpec = BlindSelectionSpecBuilder.resolveSpec(
    tier: tier,
    stationIndex: station,
    difficulty: spec.difficulty,
    ruleset: RummiRuleset.currentDefaults,
  );
  final experimentBase = _resolveExperiment(
    id: spec.experimentId,
    runSeed: runSeed,
    station: station,
    tier: tier,
    difficulty: spec.difficulty,
    baseTargetScore: blindSpec.targetScore,
    baseBoardDiscards: blindSpec.boardDiscards,
    baseHandDiscards: blindSpec.handDiscards,
    baseBossModifier: blindSpec.bossModifier,
  );
  final experimentWithOverrides = _applyTargetMultiplierOverrides(
    experiment: experimentBase,
    overrides: config.targetMultiplierOverrides,
    station: station,
    tier: tier,
    difficulty: spec.difficulty,
  );
  final experiment = _applyRunModifier(
    experiment: experimentWithOverrides,
    runModifier: config.runModifier,
  );
  final session = RummiPokerGridSession(runSeed: runSeed);
  final runProgress = RummiRunProgress();
  final ownedJesters = _resolveJesters(jesterCatalog, spec.loadout.jesterIds);
  final inventory = _buildInventory(itemCatalog, spec.loadout.itemIds);
  runProgress.ownedJesters.addAll(ownedJesters);
  runProgress.itemInventory = inventory;
  final maxHandSize = max(
    1,
    blindSpec.maxHandSize + experiment.maxHandSizeDelta,
  );
  runProgress.startBlind(
    session,
    stationIndex: station,
    blindTierIndex: tier.index,
    shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(runSeed, station),
    targetScore: experiment.targetScore,
    boardDiscards: experiment.boardDiscards,
    handDiscards: experiment.handDiscards,
    maxHandSize: maxHandSize,
    applyRoundEndDecay: false,
  );
  final simAddedDeckTiles = _applySimMarketPackDeckTiles(
    session: session,
    marketProfile: spec.marketProfile,
    loadout: spec.loadout,
    station: station,
    runSeed: runSeed,
  );
  session.blind.bossModifier = experiment.bossModifier;
  _applySimOnlyLoadoutGrowth(session, spec.loadout);
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
    'max_hand_size': session.maxHandSize,
    'jester_ids': spec.loadout.jesterIds,
    'item_ids': spec.loadout.itemIds,
    'deck_size': session.totalDeckSize,
    'sim_added_deck_tile_count': simAddedDeckTiles.length,
    if (simAddedDeckTiles.isNotEmpty)
      'sim_added_deck_tiles': simAddedDeckTiles
          .map((tile) => tile.code)
          .toList(growable: false),
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
    simBossConstraint: experiment.simBossConstraint,
  );
  final finalScore = session.blind.scoreTowardBlind;
  final isSlowClear =
      result.cleared && result.turnCount > _slowClearTurnThreshold;
  final clearTempoLabel = result.cleared
      ? (isSlowClear ? 'clear_slow' : 'clear_normal')
      : 'not_cleared';

  return <String, Object?>{
    'schema_version': 1,
    'row_type': 'battle',
    'sim_id': 'local',
    'run_id': _runId(
      runIndex: runIndex,
      matrixIndex: spec.matrixIndex,
      isMatrix: config.isMatrix,
    ),
    'matrix_index': spec.matrixIndex,
    'matrix_size': spec.matrixSize,
    'experiment_id': spec.experimentId,
    'experiment_applied': experiment.applied,
    'experiment_effects': experiment.effects,
    'run_modifier_id': config.runModifier.id,
    'run_modifier_target_multiplier': config.runModifier.targetScoreMultiplier,
    'run_modifier_reward_multiplier': config.runModifier.rewardMultiplier,
    'loadout_id': spec.loadout.id,
    'loadout_effects': spec.loadout.effectsJson(),
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
    'boss_modifier_id': experiment.bossModifier?.id,
    'boss_modifier_category': experiment.bossModifier?.category.name,
    'sim_boss_constraint_id': _simBossConstraintIdFromEffects(
      experiment.effects,
    ),
    'sim_boss_constraint': experiment.simBossConstraint?.toJson(),
    'target_score': experiment.targetScore,
    'base_target_score': blindSpec.targetScore,
    'turn_cap': config.turnCap,
    'start_state': startState,
    'loadout_summary': loadoutSummary,
    'result': <String, Object?>{
      'cleared': result.cleared,
      'final_score': finalScore,
      'score_ratio': finalScore / experiment.targetScore,
      'score_margin': finalScore - experiment.targetScore,
      'turn_count': result.turnCount,
      'stop_reason': result.stopReason,
      'outcome_label': _outcomeLabel(
        cleared: result.cleared,
        stopReason: result.stopReason,
        finalScore: finalScore,
        targetScore: experiment.targetScore,
      ),
      'clear_tempo_label': clearTempoLabel,
      'is_slow_clear': isSlowClear,
      'slow_clear_turn_threshold': _slowClearTurnThreshold,
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
      'sim_constraint_trigger_count': result.simConstraintTriggerCount,
      'sim_constraint_score_penalty': result.simConstraintScorePenalty,
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
  required BalanceSimBossConstraint? simBossConstraint,
}) {
  var confirmedLineCount = 0;
  var confirmActionCount = 0;
  var discardedBoardCount = 0;
  var drawCount = 0;
  var placeCount = 0;
  var maxSingleConfirmScore = 0;
  var simConstraintTriggerCount = 0;
  var simConstraintScorePenalty = 0;
  final simConstraintUsedRanks = <String>{};
  String? simConstraintFirstRank;
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
      simConstraintTriggerCount: simConstraintTriggerCount,
      simConstraintScorePenalty: simConstraintScorePenalty,
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
        if (simBossConstraint?.maxConfirmActions case final maxConfirmActions?
            when confirmActionCount >= maxConfirmActions) {
          simConstraintTriggerCount++;
          return finish(
            cleared: session.blind.isTargetMet,
            turnCount: turn,
            stopReason: 'sim_boss_confirm_limit',
          );
        }
        final scoreBefore = session.blind.scoreTowardBlind;
        final out = session.confirmAllFullLines(
          jesters: jesters,
          runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
        );
        if (out.result.ok) {
          final simPenalty = simBossConstraintPenalty(
            constraint: simBossConstraint,
            lineBreakdowns: out.result.lineBreakdowns,
            usedRanks: simConstraintUsedRanks,
            firstRank: simConstraintFirstRank,
            confirmActionIndex: confirmActionCount,
          );
          if (simPenalty.scorePenalty > 0) {
            session.blind.scoreTowardBlind = max(
              scoreBefore,
              session.blind.scoreTowardBlind - simPenalty.scorePenalty,
            );
            simConstraintTriggerCount += simPenalty.triggerCount;
            simConstraintScorePenalty += simPenalty.scorePenalty;
          }
          simConstraintUsedRanks.addAll(
            out.result.lineBreakdowns.map((line) => line.rank.name),
          );
          simConstraintFirstRank ??= out.result.lineBreakdowns.isEmpty
              ? null
              : out.result.lineBreakdowns.first.rank.name;
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

({int scorePenalty, int triggerCount}) simBossConstraintPenalty({
  required BalanceSimBossConstraint? constraint,
  required List<ConfirmedLineBreakdown> lineBreakdowns,
  required Set<String> usedRanks,
  required String? firstRank,
  required int confirmActionIndex,
}) {
  if (constraint == null || lineBreakdowns.isEmpty) {
    return (scorePenalty: 0, triggerCount: 0);
  }

  var scorePenalty = 0;
  var triggerCount = 0;
  for (final line in lineBreakdowns) {
    final penalties = <double>[];
    if (constraint.allLineScoreMultiplier case final multiplier?) {
      penalties.add(1 - multiplier);
    }
    if (constraint.faceLineScoreMultiplier case final multiplier?
        when line.hasScoringFaceCard) {
      penalties.add(1 - multiplier);
    }
    if (constraint.repeatRankScoreMultiplier case final multiplier?
        when usedRanks.contains(line.rank.name)) {
      penalties.add(1 - multiplier);
    }
    if (constraint.singleRankScoreMultiplier case final multiplier?
        when firstRank != null && firstRank == line.rank.name) {
      penalties.add(1 - multiplier);
    }
    if (constraint.firstConfirmScoreMultiplier case final multiplier?
        when confirmActionIndex == 0) {
      penalties.add(1 - multiplier);
    }
    if (constraint.confirmAfterLimitScoreMultiplier case final multiplier?
        when constraint.confirmAfterLimitActionCount != null &&
            confirmActionIndex >= constraint.confirmAfterLimitActionCount!) {
      penalties.add(1 - multiplier);
    }
    if (penalties.isEmpty) continue;
    final strongestPenalty = penalties.reduce(max).clamp(0.0, 1.0);
    final linePenalty = (line.finalScore * strongestPenalty).round();
    if (linePenalty > 0) {
      scorePenalty += linePenalty;
      triggerCount++;
    }
  }
  return (scorePenalty: scorePenalty, triggerCount: triggerCount);
}

BalanceSimExperimentSpec _resolveExperiment({
  required String id,
  required int runSeed,
  required int station,
  required BlindTier tier,
  required NewRunDifficulty difficulty,
  required int baseTargetScore,
  required int baseBoardDiscards,
  required int baseHandDiscards,
  required RummiBossModifier? baseBossModifier,
}) {
  final appliesToS2BossStandard =
      station == 2 &&
      tier == BlindTier.boss &&
      difficulty == NewRunDifficulty.standard;
  final effects = <String, Object?>{};

  // 실험값은 시뮬레이터 안에서만 쓰고, 실제 블라인드 spec에는 쓰지 않는다.
  switch (id) {
    case 'baseline':
      return BalanceSimExperimentSpec(
        id: id,
        applied: false,
        targetScore: baseTargetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: baseBossModifier,
        effects: const {},
      );
    case 'baseline_curve_160':
    case 'station_curve_145':
    case 'station_curve_135':
    case 'station_curve_125':
    case 'station_curve_125_target_v5':
    case 'station_curve_125_target_v6_s5_070':
    case 'station_curve_125_target_v6_s5_075':
    case 'station_curve_125_target_v7_s4_080_s5_070':
    case 'base_score_curve_v2':
      final stationGrowthBase = _stationGrowthBaseForExperiment(id);
      var targetScore = _targetScoreForStationCurve(
        station: station,
        tier: tier,
        difficulty: difficulty,
        stationGrowthBase: stationGrowthBase,
      );
      effects['station_growth_base'] = stationGrowthBase;
      effects['runtime_base_target_score'] = baseTargetScore;
      effects.addAll(
        _targetCurveTuningEffects(
          id: id,
          station: station,
          tier: tier,
          difficulty: difficulty,
        ),
      );
      if (_usesTargetCurveTuning(id)) {
        targetScore = (targetScore * _targetCurveMultiplier(id, station, tier))
            .round();
      }
      return BalanceSimExperimentSpec(
        id: id,
        applied: id != 'baseline_curve_160',
        targetScore: targetScore,
        boardDiscards:
            baseBoardDiscards +
            (_usesTargetCurveTuning(id)
                ? _targetCurveBoardDiscardsDelta(id, station, tier)
                : 0),
        handDiscards:
            baseHandDiscards +
            (_usesTargetCurveTuning(id)
                ? _targetCurveHandDiscardsDelta(id, station, tier)
                : 0),
        maxHandSizeDelta: _usesTargetCurveTuning(id)
            ? _targetCurveMaxHandSizeDelta(id, station, tier)
            : 0,
        bossModifier: baseBossModifier,
        effects: effects,
      );
    case 'station_curve_125_boss_constraint_pool_v1':
    case 'station_curve_135_boss_constraint_pool_v1':
    case 'station_curve_125_boss_constraint_pool_soft':
    case 'station_curve_135_boss_constraint_pool_soft':
    case 'station_curve_125_boss_constraint_pool_hard':
    case 'station_curve_135_boss_constraint_pool_hard':
    case 'station_curve_125_boss_constraint_pool_v2':
    case 'station_curve_125_target_v5_boss_constraint_pool_v2':
    case 'station_curve_125_target_v6_s5_070_boss_constraint_pool_v2':
    case 'station_curve_125_target_v6_s5_075_boss_constraint_pool_v2':
    case 'station_curve_125_target_v6_s5_070_boss_constraint_pool_v3':
    case 'station_curve_125_target_v7_s4_080_s5_070_boss_constraint_pool_v3':
    case 'station_curve_125_target_v6_s5_070_boss_constraint_pool_v4':
    case 'candidate_baseline_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v2':
    case 'base_score_curve_v2_boss_constraint_pool_v4':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_resource':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v2':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v3':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_rank_cycle_probe_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_probe_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_repeat_only_probe_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_single_only_probe_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_soft_probe_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1':
    case _
        when id.startsWith(
          'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_',
        ):
    case 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2':
    case 'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1':
    case 'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1':
      return _resolveBossConstraintPoolExperiment(
        id: id,
        station: station,
        tier: tier,
        difficulty: difficulty,
        baseTargetScore: baseTargetScore,
        baseBoardDiscards: baseBoardDiscards,
        baseHandDiscards: baseHandDiscards,
        baseBossModifier: baseBossModifier,
        runSeed: runSeed,
      );
    case 's1_boss_target_070':
      final stationGrowthBase = 1.25;
      final curveTargetScore = _targetScoreForStationCurve(
        station: station,
        tier: tier,
        difficulty: difficulty,
        stationGrowthBase: stationGrowthBase,
      );
      final appliesToS1Boss =
          station == 1 &&
          tier == BlindTier.boss &&
          difficulty == NewRunDifficulty.standard;
      effects['station_growth_base'] = stationGrowthBase;
      effects['runtime_base_target_score'] = baseTargetScore;
      effects['s1_boss_safety'] = appliesToS1Boss;
      if (appliesToS1Boss) {
        effects['target_score_multiplier'] = 0.7;
        return BalanceSimExperimentSpec(
          id: id,
          applied: true,
          targetScore: (curveTargetScore * 0.7).round(),
          boardDiscards: baseBoardDiscards,
          handDiscards: baseHandDiscards,
          bossModifier: baseBossModifier,
          effects: effects,
        );
      }
      return BalanceSimExperimentSpec(
        id: id,
        applied: false,
        targetScore: curveTargetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: baseBossModifier,
        effects: effects,
      );
    case 'early_boss_target_085':
    case 'early_boss_target_080':
    case 'early_boss_target_075':
    case 'early_boss_resource_1':
      final stationGrowthBase = 1.25;
      final curveTargetScore = _targetScoreForStationCurve(
        station: station,
        tier: tier,
        difficulty: difficulty,
        stationGrowthBase: stationGrowthBase,
      );
      final appliesToEarlyBoss =
          station <= 2 &&
          tier == BlindTier.boss &&
          difficulty == NewRunDifficulty.standard;
      effects['station_growth_base'] = stationGrowthBase;
      effects['runtime_base_target_score'] = baseTargetScore;
      effects['early_boss_bridge'] = appliesToEarlyBoss;
      if (id.startsWith('early_boss_target_') && appliesToEarlyBoss) {
        final targetScoreMultiplier = _earlyBossTargetMultiplier(id);
        effects['target_score_multiplier'] = targetScoreMultiplier;
        return BalanceSimExperimentSpec(
          id: id,
          applied: true,
          targetScore: (curveTargetScore * targetScoreMultiplier).round(),
          boardDiscards: baseBoardDiscards,
          handDiscards: baseHandDiscards,
          bossModifier: baseBossModifier,
          effects: effects,
        );
      }
      if (id == 'early_boss_resource_1' && appliesToEarlyBoss) {
        effects['board_discards_delta'] = 1;
        effects['hand_discards_delta'] = 1;
        return BalanceSimExperimentSpec(
          id: id,
          applied: true,
          targetScore: curveTargetScore,
          boardDiscards: baseBoardDiscards + 1,
          handDiscards: baseHandDiscards + 1,
          bossModifier: baseBossModifier,
          effects: effects,
        );
      }
      return BalanceSimExperimentSpec(
        id: id,
        applied: false,
        targetScore: curveTargetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: baseBossModifier,
        effects: effects,
      );
    case 's2_boss_target_soften':
    case 's2_boss_target_085':
    case 's2_boss_target_080':
    case 's2_boss_target_075':
      if (!appliesToS2BossStandard) {
        return BalanceSimExperimentSpec.inactive(
          id: id,
          targetScore: baseTargetScore,
          boardDiscards: baseBoardDiscards,
          handDiscards: baseHandDiscards,
          bossModifier: baseBossModifier,
        );
      }
      final targetScoreMultiplier = _targetScoreMultiplierForExperiment(id);
      final targetScore = (baseTargetScore * targetScoreMultiplier).round();
      effects['target_score_multiplier'] = targetScoreMultiplier;
      return BalanceSimExperimentSpec(
        id: id,
        applied: true,
        targetScore: targetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: baseBossModifier,
        effects: effects,
      );
    case 's2_boss_modifier_soften':
      if (!appliesToS2BossStandard || baseBossModifier == null) {
        return BalanceSimExperimentSpec.inactive(
          id: id,
          targetScore: baseTargetScore,
          boardDiscards: baseBoardDiscards,
          handDiscards: baseHandDiscards,
          bossModifier: baseBossModifier,
        );
      }
      final bossModifier = RummiBossModifier(
        id: '${baseBossModifier.id}_sim_soften',
        category: baseBossModifier.category,
        title: baseBossModifier.title,
        ruleText: baseBossModifier.ruleText,
        markerText: baseBossModifier.markerText,
        affectedTileColors: baseBossModifier.affectedTileColors,
        affectedLineKinds: baseBossModifier.affectedLineKinds,
        scoreMultiplier: 0.9,
      );
      effects['boss_score_multiplier'] = 0.9;
      effects['base_boss_score_multiplier'] = baseBossModifier.scoreMultiplier;
      return BalanceSimExperimentSpec(
        id: id,
        applied: true,
        targetScore: baseTargetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: bossModifier,
        effects: effects,
      );
    case 's2_boss_resource_boost':
      if (!appliesToS2BossStandard) {
        return BalanceSimExperimentSpec.inactive(
          id: id,
          targetScore: baseTargetScore,
          boardDiscards: baseBoardDiscards,
          handDiscards: baseHandDiscards,
          bossModifier: baseBossModifier,
        );
      }
      effects['board_discards_delta'] = 1;
      effects['hand_discards_delta'] = 1;
      return BalanceSimExperimentSpec(
        id: id,
        applied: true,
        targetScore: baseTargetScore,
        boardDiscards: baseBoardDiscards + 1,
        handDiscards: baseHandDiscards + 1,
        bossModifier: baseBossModifier,
        effects: effects,
      );
    default:
      throw FormatException('Unknown experiment id: $id');
  }
}

double _stationGrowthBaseForExperiment(String id) {
  return switch (id) {
    'baseline_curve_160' => 1.6,
    'station_curve_145' => 1.45,
    'station_curve_135' => 1.35,
    'station_curve_125' => 1.25,
    'station_curve_125_target_v5' => 1.25,
    'station_curve_125_target_v6_s5_070' => 1.25,
    'station_curve_125_target_v6_s5_075' => 1.25,
    'station_curve_125_target_v7_s4_080_s5_070' => 1.25,
    'station_curve_125_target_v5_boss_constraint_pool_v2' => 1.25,
    'station_curve_125_target_v6_s5_070_boss_constraint_pool_v2' => 1.25,
    'station_curve_125_target_v6_s5_075_boss_constraint_pool_v2' => 1.25,
    'station_curve_125_target_v6_s5_070_boss_constraint_pool_v3' => 1.25,
    'station_curve_125_target_v7_s4_080_s5_070_boss_constraint_pool_v3' => 1.25,
    'station_curve_125_target_v6_s5_070_boss_constraint_pool_v4' => 1.25,
    'candidate_baseline_v1' => 1.25,
    'base_score_curve_v2' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v2' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_resource' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v2' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v3' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_rank_cycle_probe_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_probe_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_repeat_only_probe_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_single_only_probe_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_soft_probe_v1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1' =>
      1.25,
    _
        when id.startsWith(
          'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_',
        ) =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2' =>
      1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1' => 1.25,
    'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1' => 1.25,
    _ when id.startsWith('station_curve_135_boss_constraint_pool') => 1.35,
    _ when id.startsWith('station_curve_125_boss_constraint_pool') => 1.25,
    _ => throw FormatException('Unknown station curve experiment id: $id'),
  };
}

bool _usesTargetCurveTuning(String id) =>
    id.contains('target_v5') ||
    id.contains('target_v6') ||
    id.contains('target_v7') ||
    id == 'candidate_baseline_v1' ||
    id == 'base_score_curve_v2' ||
    id.startsWith('base_score_curve_v2_boss_constraint_pool');

Map<String, Object?> _targetCurveTuningEffects({
  required String id,
  required int station,
  required BlindTier tier,
  required NewRunDifficulty difficulty,
}) {
  if (!_usesTargetCurveTuning(id) || difficulty != NewRunDifficulty.standard) {
    return const {};
  }
  return <String, Object?>{
    'target_curve_tuning': id.contains('target_v7')
        ? 'v7'
        : id == 'base_score_curve_v2' ||
              id.startsWith('base_score_curve_v2_boss_constraint_pool')
        ? 'base_score_curve_v2'
        : id == 'candidate_baseline_v1'
        ? 'candidate_baseline_v1'
        : id.contains('target_v6')
        ? 'v6'
        : 'v5',
    if (id == 'base_score_curve_v2' ||
        id.startsWith('base_score_curve_v2_boss_constraint_pool'))
      'base_score_curve_v2': true,
    if (id.contains('target_v5')) 'target_curve_v5': true,
    if (id.contains('target_v6') || id == 'candidate_baseline_v1')
      'target_curve_v6': true,
    if (id == 'candidate_baseline_v1') 'candidate_baseline_v1': true,
    if (id.contains('target_v7')) 'target_curve_v7': true,
    'target_score_multiplier': _targetCurveMultiplier(id, station, tier),
    'board_discards_delta': _targetCurveBoardDiscardsDelta(id, station, tier),
    'hand_discards_delta': _targetCurveHandDiscardsDelta(id, station, tier),
    'max_hand_size_delta': _targetCurveMaxHandSizeDelta(id, station, tier),
  };
}

double _targetCurveMultiplier(String id, int station, BlindTier tier) {
  if (id == 'base_score_curve_v2' ||
      id.startsWith('base_score_curve_v2_boss_constraint_pool')) {
    final lateBossMultiplier = _baseScoreCurveV2LateBossMultiplier(
      id,
      station,
      tier,
    );
    if (lateBossMultiplier != null) {
      return lateBossMultiplier;
    }
    final earlyMidBossMultiplier = _baseScoreCurveV2EarlyMidBossMultiplier(
      id,
      station,
      tier,
    );
    if (earlyMidBossMultiplier != null) {
      return earlyMidBossMultiplier;
    }
    final s1Multiplier = _baseScoreCurveV2S1Multiplier(id, tier);
    if (station == 1 && s1Multiplier != null) {
      return s1Multiplier;
    }
    final bandMultiplier = _baseScoreCurveV2BandMultiplier(id, station, tier);
    if (bandMultiplier != null) {
      return bandMultiplier;
    }
    final s2BossMultiplier = _baseScoreCurveV2S2BossMultiplier(id);
    if (station == 2 && tier == BlindTier.boss && s2BossMultiplier != null) {
      return s2BossMultiplier;
    }
    return switch (tier) {
      BlindTier.small => 1.10,
      BlindTier.big => 0.85,
      BlindTier.boss => 0.65,
    };
  }
  return switch (tier) {
    BlindTier.small => 1.05,
    BlindTier.big => 1.0,
    BlindTier.boss => switch (station) {
      2 => 0.95,
      4 when id.contains('target_v7_s4_080') => 0.80,
      4 => 0.85,
      5 when id.contains('target_v6_s5_075') => 0.75,
      5
          when id.contains('target_v6_s5_070') ||
              id.contains('target_v7_s4_080_s5_070') ||
              id == 'candidate_baseline_v1' =>
        0.70,
      5 => 0.65,
      6 => 0.75,
      _ => 0.85,
    },
  };
}

double? _baseScoreCurveV2EarlyMidBossMultiplier(
  String id,
  int station,
  BlindTier tier,
) {
  if (!id.contains('_early_mid_') || tier != BlindTier.boss) return null;
  if (station == 1 &&
      (id.contains('_early_mid_s1_boss_050') ||
          id.contains('_early_mid_s1_050_s4_060_resource_1'))) {
    return 0.50;
  }
  if (station == 4 &&
      (id.contains('_early_mid_s4_boss_060') ||
          id.contains('_early_mid_s1_050_s4_060_resource_1'))) {
    return 0.60;
  }
  return null;
}

double? _baseScoreCurveV2LateBossMultiplier(
  String id,
  int station,
  BlindTier tier,
) {
  if (!id.contains('_late_boss_') ||
      station < 6 ||
      station > 8 ||
      tier != BlindTier.boss) {
    return null;
  }
  if (id.contains('_late_boss_068')) return 0.68;
  if (id.contains('_late_boss_070')) return 0.70;
  return 0.74;
}

double? _baseScoreCurveV2S1Multiplier(String id, BlindTier tier) {
  return switch (id) {
    'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1' ||
    'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1' ||
    'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1' =>
      switch (tier) {
        BlindTier.small => 0.95,
        BlindTier.big => 0.70,
        BlindTier.boss => 0.52,
      },
    'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052' => switch (tier) {
      BlindTier.small => 1.10,
      BlindTier.big => 0.85,
      BlindTier.boss => 0.52,
    },
    _
        when id.startsWith(
          'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
        ) =>
      switch (tier) {
        BlindTier.small => 0.95,
        BlindTier.big => 0.70,
        BlindTier.boss => 0.52,
      },
    _ when id.contains('_s1_soft') => switch (tier) {
      BlindTier.small => 1.00,
      BlindTier.big => 0.78,
      BlindTier.boss => 0.58,
    },
    _ => null,
  };
}

double? _baseScoreCurveV2BandMultiplier(
  String id,
  int station,
  BlindTier tier,
) {
  final threeBand =
      id == 'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1';
  final midGate =
      id == 'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1';
  final lateGate =
      id == 'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1';
  final lateGuard =
      id.contains('_s1_soft_v2_late_guard_v1') ||
      id.contains('_s1_soft_v2_late_guard_v2');
  final lateGuardV2 = id.contains('_s1_soft_v2_late_guard_v2');
  if (!threeBand && !midGate && !lateGate && !lateGuard) return null;

  // 구간형 curve는 초반 빌드가 다음 구간 보스에서 막히도록
  // S3~S5와 S6~S8의 요구치를 별도 계단으로 둔다.
  if (station >= 3 && station <= 5 && !lateGuard) {
    return switch (tier) {
      BlindTier.small => midGate ? 1.14 : 1.10,
      BlindTier.big => midGate ? 0.92 : 0.88,
      BlindTier.boss => midGate ? 0.74 : 0.70,
    };
  }
  if (station >= 6 && station <= 8) {
    return switch (tier) {
      BlindTier.small =>
        lateGate
            ? 1.18
            : lateGuard
            ? lateGuardV2
                  ? 1.08
                  : 1.12
            : 1.14,
      BlindTier.big =>
        lateGate
            ? 0.96
            : lateGuard
            ? lateGuardV2
                  ? 0.88
                  : 0.90
            : 0.92,
      BlindTier.boss =>
        lateGate
            ? 0.80
            : lateGuard
            ? 0.74
            : 0.76,
    };
  }
  return null;
}

bool _baseScoreCurveV2UsesS1Resource(String id) {
  return id.contains('_s1_resource') || id.contains('_s1_soft_resource');
}

double? _baseScoreCurveV2S2BossMultiplier(String id) {
  return switch (id) {
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090' =>
      0.65 * 0.90,
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085' =>
      0.65 * 0.85,
    _ => null,
  };
}

int _targetCurveBoardDiscardsDelta(String id, int station, BlindTier tier) {
  if (id == 'base_score_curve_v2' ||
      id.startsWith('base_score_curve_v2_boss_constraint_pool')) {
    if (station == 1 && _baseScoreCurveV2UsesS1Resource(id)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesLateBossResource(id, station, tier)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesEarlyMidBossResource(id, station, tier)) {
      return 1;
    }
    return 0;
  }
  if (tier != BlindTier.boss) return 0;
  if ((id.contains('target_v6') ||
          id.contains('target_v7') ||
          id == 'candidate_baseline_v1') &&
      station == 5) {
    return 0;
  }
  return switch (station) {
    5 || 6 => 1,
    _ => 0,
  };
}

int _targetCurveHandDiscardsDelta(String id, int station, BlindTier tier) {
  if (id == 'base_score_curve_v2' ||
      id.startsWith('base_score_curve_v2_boss_constraint_pool')) {
    if (station == 1 && _baseScoreCurveV2UsesS1Resource(id)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesLateBossResource(id, station, tier)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesEarlyMidBossResource(id, station, tier)) {
      return 1;
    }
    return 0;
  }
  if (tier != BlindTier.boss) return 0;
  if ((id.contains('target_v6') ||
          id.contains('target_v7') ||
          id == 'candidate_baseline_v1') &&
      station == 5) {
    return 0;
  }
  return switch (station) {
    5 || 6 => 1,
    _ => 0,
  };
}

int _targetCurveMaxHandSizeDelta(String id, int station, BlindTier tier) {
  if (id == 'base_score_curve_v2' ||
      id.startsWith('base_score_curve_v2_boss_constraint_pool')) {
    if (station == 1 && _baseScoreCurveV2UsesS1Resource(id)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesLateBossResource(id, station, tier)) {
      return 1;
    }
    if (_baseScoreCurveV2UsesEarlyMidBossResource(id, station, tier)) {
      return 1;
    }
    return 0;
  }
  if (tier != BlindTier.boss) return 0;
  if ((id.contains('target_v6') ||
          id.contains('target_v7') ||
          id == 'candidate_baseline_v1') &&
      station == 5) {
    return 0;
  }
  return switch (station) {
    5 || 6 => 1,
    _ => 0,
  };
}

bool _baseScoreCurveV2UsesLateBossResource(
  String id,
  int station,
  BlindTier tier,
) =>
    (id.contains('_late_boss_resource_1') ||
        id.contains('_late_boss_070_resource_1') ||
        id.contains('_late_boss_068_resource_1')) &&
    station >= 5 &&
    station <= 8 &&
    tier == BlindTier.boss;

bool _baseScoreCurveV2UsesEarlyMidBossResource(
  String id,
  int station,
  BlindTier tier,
) =>
    (id.contains('_early_mid_s4_boss_resource_1') ||
        id.contains('_early_mid_s1_050_s4_060_resource_1')) &&
    station == 4 &&
    tier == BlindTier.boss;

BalanceSimExperimentSpec _resolveBossConstraintPoolExperiment({
  required String id,
  required int runSeed,
  required int station,
  required BlindTier tier,
  required NewRunDifficulty difficulty,
  required int baseTargetScore,
  required int baseBoardDiscards,
  required int baseHandDiscards,
  required RummiBossModifier? baseBossModifier,
}) {
  final stationGrowthBase = _stationGrowthBaseForExperiment(id);
  final targetScore = _targetScoreForStationCurve(
    station: station,
    tier: tier,
    difficulty: difficulty,
    stationGrowthBase: stationGrowthBase,
  );
  final targetCurveMultiplier = _targetCurveMultiplier(id, station, tier);
  final curveTargetScore = _usesTargetCurveTuning(id)
      ? (targetScore * targetCurveMultiplier).round()
      : targetScore;
  final targetCurveBoardDiscardsDelta = _usesTargetCurveTuning(id)
      ? _targetCurveBoardDiscardsDelta(id, station, tier)
      : 0;
  final targetCurveHandDiscardsDelta = _usesTargetCurveTuning(id)
      ? _targetCurveHandDiscardsDelta(id, station, tier)
      : 0;
  final targetCurveMaxHandSizeDelta = _usesTargetCurveTuning(id)
      ? _targetCurveMaxHandSizeDelta(id, station, tier)
      : 0;
  final effects = <String, Object?>{
    'station_growth_base': stationGrowthBase,
    'runtime_base_target_score': baseTargetScore,
    'boss_constraint_pool': tier == BlindTier.boss,
    'boss_constraint_pool_severity': _bossConstraintPoolSeverity(id),
    ..._targetCurveTuningEffects(
      id: id,
      station: station,
      tier: tier,
      difficulty: difficulty,
    ),
    if (_usesRankCycleProbe(id)) 'rank_cycle_probe': true,
  };
  if (tier != BlindTier.boss) {
    return BalanceSimExperimentSpec(
      id: id,
      applied: true,
      targetScore: curveTargetScore,
      boardDiscards: baseBoardDiscards + targetCurveBoardDiscardsDelta,
      handDiscards: baseHandDiscards + targetCurveHandDiscardsDelta,
      maxHandSizeDelta: targetCurveMaxHandSizeDelta,
      bossModifier: null,
      effects: effects,
    );
  }

  final severity = _bossConstraintPoolSeverity(id);
  final constraint = _usesRankCycleProbe(id)
      ? _rankCycleProbeConstraintForStationPool(
          id: id,
          station: station,
          severity: severity,
          baseBossModifier: baseBossModifier,
        )
      : _usesWeightedBossPool(id)
      ? _weightedBossConstraintForStationPool(
          station: station,
          severity: severity,
          baseBossModifier: baseBossModifier,
          runSeed: runSeed,
          poolVersion: _weightedBossPoolVersion(id),
        )
      : _bossConstraintForStationPool(
          station: station,
          severity: severity,
          baseBossModifier: baseBossModifier,
        );
  final rawBossTargetScore =
      (curveTargetScore * constraint.targetScoreMultiplier).round();
  final bossTargetScore = _usesOrderedBossTargets(id)
      ? _orderedBossTargetScore(
          rawBossTargetScore: rawBossTargetScore,
          id: id,
          station: station,
          difficulty: difficulty,
          stationGrowthBase: stationGrowthBase,
        )
      : rawBossTargetScore;
  if (_usesOrderedBossTargets(id)) {
    effects['ordered_boss_targets'] = true;
    effects['raw_boss_target_score'] = rawBossTargetScore;
  }
  effects.addAll(constraint.effects);
  return BalanceSimExperimentSpec(
    id: id,
    applied: true,
    targetScore: bossTargetScore,
    boardDiscards: max(
      0,
      baseBoardDiscards +
          targetCurveBoardDiscardsDelta +
          constraint.boardDiscardsDelta,
    ),
    handDiscards: max(
      0,
      baseHandDiscards +
          targetCurveHandDiscardsDelta +
          constraint.handDiscardsDelta,
    ),
    maxHandSizeDelta: targetCurveMaxHandSizeDelta + constraint.maxHandSizeDelta,
    bossModifier: constraint.bossModifier,
    simBossConstraint: constraint.simConstraint,
    effects: effects,
  );
}

bool _usesOrderedBossTargets(String id) =>
    id.endsWith('_ordered_boss_v1') ||
    id.endsWith('_weighted_boss_v1') ||
    id.endsWith('_weighted_boss_v2') ||
    id.endsWith('_weighted_boss_v3') ||
    _usesRankCycleProbe(id) ||
    id.contains('_weighted_boss_v3_late_boss_');

bool _usesRankCycleProbe(String id) =>
    id.endsWith('_rank_cycle_probe_v1') ||
    id.endsWith('_rank_cycle_repeat_only_probe_v1') ||
    id.endsWith('_rank_cycle_single_only_probe_v1') ||
    id.endsWith('_rank_cycle_soft_probe_v1');

bool _usesWeightedBossPool(String id) =>
    id.endsWith('_weighted_boss_v1') ||
    id.endsWith('_weighted_boss_v2') ||
    id.endsWith('_weighted_boss_v3') ||
    id.contains('_weighted_boss_v3_late_boss_');

int _weightedBossPoolVersion(String id) {
  if (id.endsWith('_weighted_boss_v3') ||
      id.contains('_weighted_boss_v3_late_boss_')) {
    return 3;
  }
  if (id.endsWith('_weighted_boss_v2')) return 2;
  return 1;
}

BalanceSimBossConstraintChoice _rankCycleProbeConstraintForStationPool({
  required String id,
  required int station,
  required String severity,
  required RummiBossModifier? baseBossModifier,
}) {
  final slots = _rankCycleProbeSlotsForExperiment(id);
  final normalizedStation = station < 1 ? 1 : station;
  final slot = slots[(normalizedStation - 1) % slots.length];
  final choice = _bossConstraintChoiceForSlot(
    slot: slot,
    severity: severity,
    baseBossModifier: baseBossModifier,
  );
  return choice.withExtraEffects(<String, Object?>{
    'sim_boss_pool_profile': _rankCycleProbeProfileId(id),
    'sim_boss_pool_slot': slot,
  });
}

String _rankCycleProbeProfileId(String id) {
  if (id.endsWith('_rank_cycle_repeat_only_probe_v1')) {
    return 'rank_cycle_repeat_only_probe_v1';
  }
  if (id.endsWith('_rank_cycle_single_only_probe_v1')) {
    return 'rank_cycle_single_only_probe_v1';
  }
  if (id.endsWith('_rank_cycle_soft_probe_v1')) {
    return 'rank_cycle_soft_probe_v1';
  }
  return 'rank_cycle_probe_v1';
}

List<int> _rankCycleProbeSlotsForExperiment(String id) {
  if (id.endsWith('_rank_cycle_repeat_only_probe_v1')) {
    return const [0, 1, 2, 3, 6, 11, 7, 5];
  }
  if (id.endsWith('_rank_cycle_single_only_probe_v1')) {
    return const [0, 1, 2, 10, 6, 4, 7, 5];
  }
  if (id.endsWith('_rank_cycle_soft_probe_v1')) {
    return const [0, 1, 2, 12, 6, 13, 7, 5];
  }
  return const [0, 1, 2, 3, 6, 4, 7, 5];
}

int _orderedBossTargetScore({
  required int rawBossTargetScore,
  required String id,
  required int station,
  required NewRunDifficulty difficulty,
  required double stationGrowthBase,
}) {
  final bigTargetScore = _targetScoreForStationCurve(
    station: station,
    tier: BlindTier.big,
    difficulty: difficulty,
    stationGrowthBase: stationGrowthBase,
  );
  final tunedBigTargetScore = _usesTargetCurveTuning(id)
      ? (bigTargetScore * _targetCurveMultiplier(id, station, BlindTier.big))
            .round()
      : bigTargetScore;
  return rawBossTargetScore <= tunedBigTargetScore
      ? tunedBigTargetScore + 1
      : rawBossTargetScore;
}

String _bossConstraintPoolSeverity(String id) {
  if (id.startsWith('base_score_curve_v2_boss_constraint_pool_v4')) return 'v4';
  if (id.endsWith('_soft')) return 'soft';
  if (id.endsWith('_hard')) return 'hard';
  if (id == 'base_score_curve_v2_boss_constraint_pool_v4') return 'v4';
  if (id == 'base_score_curve_v2_boss_constraint_pool_v2') return 'v2';
  if (id == 'candidate_baseline_v1') return 'v4';
  if (id.endsWith('_v4')) return 'v4';
  if (id.endsWith('_v3')) return 'v3';
  if (id.endsWith('_v2')) return 'v2';
  return 'v1';
}

BalanceSimBossConstraintChoice _bossConstraintForStationPool({
  required int station,
  required String severity,
  required RummiBossModifier? baseBossModifier,
}) {
  final normalizedStation = station < 1 ? 1 : station;
  final slot = (normalizedStation - 1) % 10;
  return _bossConstraintChoiceForSlot(
    slot: slot,
    severity: severity,
    baseBossModifier: baseBossModifier,
  );
}

BalanceSimBossConstraintChoice _weightedBossConstraintForStationPool({
  required int station,
  required String severity,
  required RummiBossModifier? baseBossModifier,
  required int runSeed,
  required int poolVersion,
}) {
  final candidates = _weightedBossConstraintSlots(
    station,
    poolVersion: poolVersion,
  );
  final totalWeight = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  final rng = Random(runSeed * 1009 + station * 7919);
  var roll = rng.nextInt(totalWeight);
  var selected = candidates.last.slot;
  for (final candidate in candidates) {
    roll -= candidate.weight;
    if (roll < 0) {
      selected = candidate.slot;
      break;
    }
  }
  final choice = _bossConstraintChoiceForSlot(
    slot: selected,
    severity: severity,
    baseBossModifier: baseBossModifier,
  );
  return choice.withExtraEffects(<String, Object?>{
    'sim_boss_pool_profile': switch (poolVersion) {
      3 => 'early_mid_late_final_weighted_v3',
      2 => 'early_mid_late_final_weighted_v2',
      _ => 'early_mid_late_final_weighted_v1',
    },
    'sim_boss_pool_slot': selected,
  });
}

List<({int slot, int weight})> _weightedBossConstraintSlots(
  int station, {
  required int poolVersion,
}) {
  if (station <= 2) {
    return poolVersion >= 3
        ? const [
            (slot: 2, weight: 18),
            (slot: 1, weight: 16),
            (slot: 0, weight: 14),
            (slot: 7, weight: 12),
            (slot: 9, weight: 10),
            (slot: 3, weight: 6),
            (slot: 5, weight: 4),
            (slot: 4, weight: 3),
            (slot: 6, weight: 2),
            (slot: 8, weight: 1),
          ]
        : const [
            (slot: 0, weight: 24),
            (slot: 1, weight: 20),
            (slot: 2, weight: 14),
            (slot: 7, weight: 8),
            (slot: 9, weight: 6),
            (slot: 3, weight: 4),
            (slot: 5, weight: 2),
          ];
  }
  if (station <= 5) {
    return const [
      (slot: 3, weight: 20),
      (slot: 4, weight: 18),
      (slot: 5, weight: 14),
      (slot: 6, weight: 12),
      (slot: 2, weight: 10),
      (slot: 7, weight: 8),
      (slot: 8, weight: 4),
      (slot: 9, weight: 4),
      (slot: 0, weight: 3),
      (slot: 1, weight: 3),
    ];
  }
  if (station <= 7) {
    return const [
      (slot: 5, weight: 22),
      (slot: 6, weight: 20),
      (slot: 8, weight: 14),
      (slot: 9, weight: 12),
      (slot: 3, weight: 10),
      (slot: 7, weight: 8),
      (slot: 4, weight: 6),
      (slot: 2, weight: 4),
    ];
  }
  return poolVersion >= 3
      ? const [
          (slot: 6, weight: 20),
          (slot: 9, weight: 18),
          (slot: 5, weight: 16),
          (slot: 7, weight: 10),
          (slot: 3, weight: 8),
          (slot: 8, weight: 8),
          (slot: 4, weight: 5),
          (slot: 2, weight: 4),
          (slot: 0, weight: 2),
          (slot: 1, weight: 2),
        ]
      : poolVersion >= 2
      ? const [
          (slot: 8, weight: 14),
          (slot: 6, weight: 20),
          (slot: 9, weight: 18),
          (slot: 5, weight: 16),
          (slot: 7, weight: 10),
          (slot: 3, weight: 8),
          (slot: 4, weight: 4),
          (slot: 2, weight: 2),
        ]
      : const [
          (slot: 8, weight: 24),
          (slot: 6, weight: 18),
          (slot: 9, weight: 16),
          (slot: 5, weight: 14),
          (slot: 7, weight: 10),
          (slot: 3, weight: 8),
          (slot: 4, weight: 4),
          (slot: 2, weight: 2),
        ];
}

BalanceSimBossConstraintChoice _bossConstraintChoiceForSlot({
  required int slot,
  required String severity,
  required RummiBossModifier? baseBossModifier,
}) {
  final scale = switch (severity) {
    'soft' => 0.75,
    'v4' => 0.5,
    'v3' => 0.45,
    'v2' => 0.55,
    'hard' => 1.25,
    _ => 1.0,
  };
  double soften(double multiplier) {
    return (1 - ((1 - multiplier) * scale)).clamp(0.05, 1.0).toDouble();
  }

  BalanceSimBossConstraintChoice choice({
    required String id,
    required String family,
    required String sourceReference,
    double targetScoreMultiplier = 1.0,
    int boardDiscardsDelta = 0,
    int handDiscardsDelta = 0,
    int maxHandSizeDelta = 0,
    RummiBossModifier? bossModifier,
    BalanceSimBossConstraint? simConstraint,
  }) {
    return BalanceSimBossConstraintChoice(
      id: id,
      targetScoreMultiplier: targetScoreMultiplier,
      boardDiscardsDelta: boardDiscardsDelta,
      handDiscardsDelta: handDiscardsDelta,
      maxHandSizeDelta: maxHandSizeDelta,
      bossModifier: bossModifier,
      simConstraint: simConstraint,
      effects: <String, Object?>{
        'sim_boss_constraint_id': id,
        'sim_boss_constraint_family': family,
        'sim_boss_constraint_source': sourceReference,
      },
    );
  }

  return switch (slot) {
    0 => choice(
      id: 'color_dampener_cycle',
      family: 'tile_color_weaken',
      sourceReference: 'Balatro suit debuff boss blinds',
      bossModifier: baseBossModifier ?? RummiBossModifier.redDampener,
    ),
    1 => choice(
      id: 'line_kind_dampener_cycle',
      family: 'line_kind_weaken',
      sourceReference: 'Balatro hand-shape pressure analog',
      bossModifier: RummiBossModifier.rowDampener,
    ),
    10 => choice(
      id: 'column_line_dampener_cycle',
      family: 'line_kind_weaken',
      sourceReference: 'Runtime column line dampener',
      bossModifier: RummiBossModifier.columnDampener,
    ),
    11 => choice(
      id: 'diagonal_line_dampener_cycle',
      family: 'line_kind_weaken',
      sourceReference: 'Runtime diagonal line dampener',
      bossModifier: RummiBossModifier.diagonalDampener,
    ),
    12 => choice(
      id: 'repeat_rank_pressure_soft',
      family: 'repeat_hand_rank_weaken',
      sourceReference: 'Soft repeat hand rank pressure probe',
      simConstraint: const BalanceSimBossConstraint(
        id: 'repeat_rank_pressure_soft',
        family: 'repeat_hand_rank_weaken',
        sourceReference: 'Soft repeat hand rank pressure probe',
        repeatRankScoreMultiplier: 0.90,
      ),
    ),
    13 => choice(
      id: 'single_rank_pressure_soft',
      family: 'single_hand_rank_pressure',
      sourceReference: 'Soft single hand rank pressure probe',
      simConstraint: const BalanceSimBossConstraint(
        id: 'single_rank_pressure_soft',
        family: 'single_hand_rank_pressure',
        sourceReference: 'Soft single hand rank pressure probe',
        singleRankScoreMultiplier: 0.85,
      ),
    ),
    2 => choice(
      id: 'face_tile_dampener',
      family: 'face_tile_weaken',
      sourceReference: 'The Plant face cards debuffed',
      simConstraint: BalanceSimBossConstraint(
        id: 'face_tile_dampener',
        family: 'face_tile_weaken',
        sourceReference: 'The Plant face cards debuffed',
        faceLineScoreMultiplier: soften(0.5),
      ),
    ),
    3 => choice(
      id: severity == 'v4'
          ? 'repeat_rank_pressure_v4'
          : severity == 'v3'
          ? 'repeat_rank_pressure_v3'
          : severity == 'v2'
          ? 'repeat_rank_pressure_v2'
          : 'repeat_rank_limit',
      family: 'repeat_hand_rank_weaken',
      sourceReference: 'The Eye no repeat hand types',
      simConstraint: BalanceSimBossConstraint(
        id: severity == 'v4'
            ? 'repeat_rank_pressure_v4'
            : severity == 'v3'
            ? 'repeat_rank_pressure_v3'
            : severity == 'v2'
            ? 'repeat_rank_pressure_v2'
            : 'repeat_rank_limit',
        family: 'repeat_hand_rank_weaken',
        sourceReference: 'The Eye no repeat hand types',
        repeatRankScoreMultiplier: severity == 'v4'
            ? 0.80
            : severity == 'v3'
            ? 0.85
            : severity == 'v2'
            ? 0.72
            : soften(0.25),
      ),
    ),
    4 => choice(
      id: 'single_rank_pressure',
      family: 'single_hand_rank_pressure',
      sourceReference: 'A안 first confirmed hand type repeat pressure',
      simConstraint: BalanceSimBossConstraint(
        id: 'single_rank_pressure',
        family: 'single_hand_rank_pressure',
        sourceReference: 'A안 first confirmed hand type repeat pressure',
        singleRankScoreMultiplier: soften(0.4),
      ),
    ),
    5 => choice(
      id: severity == 'v2' || severity == 'v3' || severity == 'v4'
          ? 'confirm_count_tax_v2'
          : 'confirm_limit_pressure',
      family: severity == 'v2' || severity == 'v3' || severity == 'v4'
          ? 'confirm_count_tax'
          : 'confirm_count_limit',
      sourceReference: 'The Needle one hand only',
      targetScoreMultiplier:
          severity == 'v2' || severity == 'v3' || severity == 'v4'
          ? 0.75
          : severity == 'hard'
          ? 0.9
          : 0.8,
      simConstraint: BalanceSimBossConstraint(
        id: severity == 'v2' || severity == 'v3' || severity == 'v4'
            ? 'confirm_count_tax_v2'
            : 'confirm_limit_pressure',
        family: severity == 'v2' || severity == 'v3' || severity == 'v4'
            ? 'confirm_count_tax'
            : 'confirm_count_limit',
        sourceReference: 'The Needle one hand only',
        maxConfirmActions:
            severity == 'v2' || severity == 'v3' || severity == 'v4'
            ? null
            : severity == 'hard'
            ? 1
            : 2,
        confirmAfterLimitActionCount:
            severity == 'v2' || severity == 'v3' || severity == 'v4' ? 2 : null,
        confirmAfterLimitScoreMultiplier:
            severity == 'v2' || severity == 'v3' || severity == 'v4'
            ? 0.75
            : null,
      ),
    ),
    6 => choice(
      id: 'all_score_dampener',
      family: 'base_score_and_mult_weaken',
      sourceReference: 'The Flint base chips and mult reduced',
      simConstraint: BalanceSimBossConstraint(
        id: 'all_score_dampener',
        family: 'base_score_and_mult_weaken',
        sourceReference: 'The Flint base chips and mult reduced',
        allLineScoreMultiplier: soften(0.75),
      ),
    ),
    7 => choice(
      id: 'first_confirm_tax',
      family: 'forced_selection_or_opening_tax',
      sourceReference: 'The Hook / forced selection pressure proxy',
      simConstraint: BalanceSimBossConstraint(
        id: 'first_confirm_tax',
        family: 'forced_selection_or_opening_tax',
        sourceReference: 'The Hook / forced selection pressure proxy',
        firstConfirmScoreMultiplier: soften(0.5),
      ),
    ),
    8 => choice(
      id: 'target_spike_wall',
      family: 'large_target_spike',
      sourceReference: 'The Wall / Violet Vessel large blind',
      targetScoreMultiplier: severity == 'soft'
          ? 1.15
          : severity == 'hard'
          ? 1.5
          : 1.3,
    ),
    _ => choice(
      id: 'resource_squeeze',
      family: 'hand_size_and_discard_pressure',
      sourceReference: 'The Water / The Manacle resource pressure',
      boardDiscardsDelta: severity == 'soft' ? 0 : -1,
      handDiscardsDelta: -1,
      maxHandSizeDelta: -1,
    ),
  };
}

int _targetScoreForStationCurve({
  required int station,
  required BlindTier tier,
  required NewRunDifficulty difficulty,
  required double stationGrowthBase,
}) {
  final normalizedStation = station < 1 ? 1 : station;
  final rawStationTarget = normalizedStation <= 1
      ? 300
      : (300 * _pow(stationGrowthBase, normalizedStation - 1)).floor();
  final scaledStationTarget =
      (rawStationTarget *
              AppConfig.stationTargetScoreScale *
              _difficultyTargetMultiplier(difficulty))
          .round();
  return (scaledStationTarget * _tierTargetMultiplier(tier, normalizedStation))
      .round();
}

double _difficultyTargetMultiplier(NewRunDifficulty difficulty) {
  return switch (difficulty) {
    NewRunDifficulty.relaxed => 0.8,
    NewRunDifficulty.standard => 1.0,
    NewRunDifficulty.pressure => 1.2,
  };
}

double _tierTargetMultiplier(BlindTier tier, int station) {
  return switch (tier) {
    BlindTier.small => 1.0,
    BlindTier.big => 1.5,
    BlindTier.boss => station == 1 ? 1.6 : 2.0,
  };
}

double _pow(double base, int exponent) {
  var value = 1.0;
  for (var index = 0; index < exponent; index++) {
    value *= base;
  }
  return value;
}

double _targetScoreMultiplierForExperiment(String id) {
  return switch (id) {
    's2_boss_target_soften' => 0.9,
    's2_boss_target_085' => 0.85,
    's2_boss_target_080' => 0.8,
    's2_boss_target_075' => 0.75,
    _ => throw FormatException('Unknown target experiment id: $id'),
  };
}

double _earlyBossTargetMultiplier(String id) {
  return switch (id) {
    'early_boss_target_085' => 0.85,
    'early_boss_target_080' => 0.8,
    'early_boss_target_075' => 0.75,
    _ => throw FormatException('Unknown early boss target experiment id: $id'),
  };
}

BalanceSimExperimentSpec _applyTargetMultiplierOverrides({
  required BalanceSimExperimentSpec experiment,
  required List<BalanceSimTargetMultiplierOverride> overrides,
  required int station,
  required BlindTier tier,
  required NewRunDifficulty difficulty,
}) {
  BalanceSimTargetMultiplierOverride? matched;
  for (final override in overrides) {
    if (override.matches(
      station: station,
      tier: tier,
      difficulty: difficulty,
    )) {
      matched = override;
    }
  }
  if (matched == null) return experiment;

  final effects = Map<String, Object?>.of(experiment.effects);
  effects['target_multiplier_override'] = true;
  effects['target_multiplier_override_station'] = matched.station;
  effects['target_multiplier_override_tier'] = matched.tier.name;
  effects['target_multiplier_override_value'] = matched.multiplier;
  return BalanceSimExperimentSpec(
    id: experiment.id,
    applied: true,
    targetScore: (experiment.targetScore * matched.multiplier).round(),
    boardDiscards: experiment.boardDiscards,
    handDiscards: experiment.handDiscards,
    bossModifier: experiment.bossModifier,
    effects: effects,
    maxHandSizeDelta: experiment.maxHandSizeDelta,
    simBossConstraint: experiment.simBossConstraint,
  );
}

BalanceSimExperimentSpec _applyRunModifier({
  required BalanceSimExperimentSpec experiment,
  required NewRunModifier runModifier,
}) {
  if (runModifier == NewRunModifier.basic) return experiment;
  final effects = Map<String, Object?>.of(experiment.effects);
  effects['run_modifier_id'] = runModifier.id;
  effects['run_modifier_target_multiplier'] = runModifier.targetScoreMultiplier;
  effects['run_modifier_reward_multiplier'] = runModifier.rewardMultiplier;
  return BalanceSimExperimentSpec(
    id: experiment.id,
    applied: true,
    targetScore: (experiment.targetScore * runModifier.targetScoreMultiplier)
        .round(),
    boardDiscards: experiment.boardDiscards,
    handDiscards: experiment.handDiscards,
    bossModifier: experiment.bossModifier,
    effects: effects,
    maxHandSizeDelta: experiment.maxHandSizeDelta,
    simBossConstraint: experiment.simBossConstraint,
  );
}

class BalanceSimExperimentSpec {
  const BalanceSimExperimentSpec({
    required this.id,
    required this.applied,
    required this.targetScore,
    required this.boardDiscards,
    required this.handDiscards,
    required this.bossModifier,
    required this.effects,
    this.maxHandSizeDelta = 0,
    this.simBossConstraint,
  });

  factory BalanceSimExperimentSpec.inactive({
    required String id,
    required int targetScore,
    required int boardDiscards,
    required int handDiscards,
    required RummiBossModifier? bossModifier,
  }) {
    return BalanceSimExperimentSpec(
      id: id,
      applied: false,
      targetScore: targetScore,
      boardDiscards: boardDiscards,
      handDiscards: handDiscards,
      bossModifier: bossModifier,
      effects: const {},
    );
  }

  final String id;
  final bool applied;
  final int targetScore;
  final int boardDiscards;
  final int handDiscards;
  final RummiBossModifier? bossModifier;
  final Map<String, Object?> effects;
  final int maxHandSizeDelta;
  final BalanceSimBossConstraint? simBossConstraint;
}

class BalanceSimBossConstraint {
  const BalanceSimBossConstraint({
    required this.id,
    required this.family,
    required this.sourceReference,
    this.allLineScoreMultiplier,
    this.faceLineScoreMultiplier,
    this.repeatRankScoreMultiplier,
    this.singleRankScoreMultiplier,
    this.firstConfirmScoreMultiplier,
    this.maxConfirmActions,
    this.confirmAfterLimitActionCount,
    this.confirmAfterLimitScoreMultiplier,
  });

  final String id;
  final String family;
  final String sourceReference;
  final double? allLineScoreMultiplier;
  final double? faceLineScoreMultiplier;
  final double? repeatRankScoreMultiplier;
  final double? singleRankScoreMultiplier;
  final double? firstConfirmScoreMultiplier;
  final int? maxConfirmActions;
  final int? confirmAfterLimitActionCount;
  final double? confirmAfterLimitScoreMultiplier;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'family': family,
      'source_reference': sourceReference,
      if (allLineScoreMultiplier != null)
        'all_line_score_multiplier': allLineScoreMultiplier,
      if (faceLineScoreMultiplier != null)
        'face_line_score_multiplier': faceLineScoreMultiplier,
      if (repeatRankScoreMultiplier != null)
        'repeat_rank_score_multiplier': repeatRankScoreMultiplier,
      if (singleRankScoreMultiplier != null)
        'single_rank_score_multiplier': singleRankScoreMultiplier,
      if (firstConfirmScoreMultiplier != null)
        'first_confirm_score_multiplier': firstConfirmScoreMultiplier,
      if (maxConfirmActions != null) 'max_confirm_actions': maxConfirmActions,
      if (confirmAfterLimitActionCount != null)
        'confirm_after_limit_action_count': confirmAfterLimitActionCount,
      if (confirmAfterLimitScoreMultiplier != null)
        'confirm_after_limit_score_multiplier':
            confirmAfterLimitScoreMultiplier,
    };
  }
}

class BalanceSimBossConstraintChoice {
  const BalanceSimBossConstraintChoice({
    required this.id,
    required this.targetScoreMultiplier,
    required this.boardDiscardsDelta,
    required this.handDiscardsDelta,
    required this.maxHandSizeDelta,
    required this.bossModifier,
    required this.simConstraint,
    required this.effects,
  });

  final String id;
  final double targetScoreMultiplier;
  final int boardDiscardsDelta;
  final int handDiscardsDelta;
  final int maxHandSizeDelta;
  final RummiBossModifier? bossModifier;
  final BalanceSimBossConstraint? simConstraint;
  final Map<String, Object?> effects;

  BalanceSimBossConstraintChoice withExtraEffects(
    Map<String, Object?> extraEffects,
  ) {
    return BalanceSimBossConstraintChoice(
      id: id,
      targetScoreMultiplier: targetScoreMultiplier,
      boardDiscardsDelta: boardDiscardsDelta,
      handDiscardsDelta: handDiscardsDelta,
      maxHandSizeDelta: maxHandSizeDelta,
      bossModifier: bossModifier,
      simConstraint: simConstraint,
      effects: <String, Object?>{...effects, ...extraEffects},
    );
  }
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
    required this.simConstraintTriggerCount,
    required this.simConstraintScorePenalty,
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
  final int simConstraintTriggerCount;
  final int simConstraintScorePenalty;
}

enum BalanceSimSequenceMode {
  none,
  stationPath;

  static BalanceSimSequenceMode parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimSequenceMode.none,
      'station_path' => BalanceSimSequenceMode.stationPath,
      _ => throw FormatException('Unknown sequence mode: $raw'),
    };
  }
}

enum BalanceSimEconomyMode {
  traceOnly,
  gatedKnownCost;

  static BalanceSimEconomyMode parse(String raw) {
    return switch (raw) {
      'trace_only' => BalanceSimEconomyMode.traceOnly,
      'gated_known_cost' => BalanceSimEconomyMode.gatedKnownCost,
      _ => throw FormatException('Unknown sim economy mode: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimEconomyMode.traceOnly => 'trace_only',
      BalanceSimEconomyMode.gatedKnownCost => 'gated_known_cost',
    };
  }
}

enum BalanceSimMarketBudgetMode {
  none,
  stationBandV1;

  static BalanceSimMarketBudgetMode parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimMarketBudgetMode.none,
      'station_band_v1' => BalanceSimMarketBudgetMode.stationBandV1,
      _ => throw FormatException('Unknown sim market budget mode: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimMarketBudgetMode.none => 'none',
      BalanceSimMarketBudgetMode.stationBandV1 => 'station_band_v1',
    };
  }
}

enum BalanceSimMarketSpendMode {
  none,
  rerollSlotSellV1;

  static BalanceSimMarketSpendMode parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimMarketSpendMode.none,
      'reroll_slot_sell_v1' => BalanceSimMarketSpendMode.rerollSlotSellV1,
      _ => throw FormatException('Unknown sim market spend mode: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimMarketSpendMode.none => 'none',
      BalanceSimMarketSpendMode.rerollSlotSellV1 => 'reroll_slot_sell_v1',
    };
  }
}

enum BalanceSimPriceBandMode {
  none,
  rarityCategoryV1,
  rarityCategorySoftV1,
  catalogValueFlagsV1,
  catalogNormalizedV1;

  static BalanceSimPriceBandMode parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimPriceBandMode.none,
      'rarity_category_v1' => BalanceSimPriceBandMode.rarityCategoryV1,
      'rarity_category_soft_v1' => BalanceSimPriceBandMode.rarityCategorySoftV1,
      'catalog_value_flags_v1' => BalanceSimPriceBandMode.catalogValueFlagsV1,
      'catalog_normalized_v1' => BalanceSimPriceBandMode.catalogNormalizedV1,
      _ => throw FormatException('Unknown sim price band mode: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimPriceBandMode.none => 'none',
      BalanceSimPriceBandMode.rarityCategoryV1 => 'rarity_category_v1',
      BalanceSimPriceBandMode.rarityCategorySoftV1 => 'rarity_category_soft_v1',
      BalanceSimPriceBandMode.catalogValueFlagsV1 => 'catalog_value_flags_v1',
      BalanceSimPriceBandMode.catalogNormalizedV1 => 'catalog_normalized_v1',
    };
  }
}

enum BalanceSimMarketChoiceMode {
  none,
  affordableAlternativeV1;

  static BalanceSimMarketChoiceMode parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimMarketChoiceMode.none,
      'affordable_alternative_v1' =>
        BalanceSimMarketChoiceMode.affordableAlternativeV1,
      _ => throw FormatException('Unknown sim market choice mode: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimMarketChoiceMode.none => 'none',
      BalanceSimMarketChoiceMode.affordableAlternativeV1 =>
        'affordable_alternative_v1',
    };
  }
}

enum _SimMarketSlotFamily { none, jester, item }

class _SimMarketSlotReplacement {
  const _SimMarketSlotReplacement({
    required this.replaced,
    required this.sellRecovery,
  });

  const _SimMarketSlotReplacement.none() : replaced = false, sellRecovery = 0;

  final bool replaced;
  final int sellRecovery;
}

enum BalanceSimMarketProfile {
  none,
  s1BuyJolly,
  s1BuySly,
  s1BuyDiscardGlove,
  s1TilePackSmall,
  s1TilePackPlus3,
  s1TilePackPlus4,
  s1TilePackPlus5,
  s1BuildAwarePackPlus3,
  s1BuildAwarePackPlus5,
  s1PairSeedPack,
  s1ColorSeedPack,
  s1FaceSeedPack,
  s1RandomCandidatePool,
  s1ProbabilisticCandidatePool,
  s1FullSafeCandidatePool,
  s1RoleDeckSustainPool,
  s1RoleScoreGrowthPool,
  s1RoleShapeFixPool,
  s1RoleWeakFlavorPool,
  s1StationWeightedCandidatePool,
  s1StateWeightedCandidatePool,
  bandedCandidatePoolV1,
  bandedCandidatePoolV2,
  shopSlotMarketV1,
  shopSlotMarketV2,
  shopSlotMarketV3,
  shopSlotMarketV4,
  shopSlotMarketV5,
  shopSlotMarketV6,
  shopSlotMarketV7,
  shopSlotMarketV8,
  shopSlotMarketV9,
  shopSlotMarketV10,
  shopSlotMarketV11,
  shopSlotMarketV12,
  shopSlotMarketV13,
  s1CandidateCommonColorJester,
  s1CandidateCommonRankJester,
  s1CandidateUncommonBuildJester,
  s1CandidateRareXmultJester,
  s1CandidateLegendaryBridge,
  s1CandidatePlanetRankLevel,
  s1CandidateTarotBuildPack,
  s1CandidateVoucherResource;

  static BalanceSimMarketProfile parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimMarketProfile.none,
      's1_buy_jolly' => BalanceSimMarketProfile.s1BuyJolly,
      's1_buy_sly' => BalanceSimMarketProfile.s1BuySly,
      's1_buy_discard_glove' => BalanceSimMarketProfile.s1BuyDiscardGlove,
      's1_tile_pack_small' => BalanceSimMarketProfile.s1TilePackSmall,
      's1_tile_pack_plus3' => BalanceSimMarketProfile.s1TilePackPlus3,
      's1_tile_pack_plus4' => BalanceSimMarketProfile.s1TilePackPlus4,
      's1_tile_pack_plus5' => BalanceSimMarketProfile.s1TilePackPlus5,
      's1_build_aware_pack_plus3' =>
        BalanceSimMarketProfile.s1BuildAwarePackPlus3,
      's1_build_aware_pack_plus5' =>
        BalanceSimMarketProfile.s1BuildAwarePackPlus5,
      's1_pair_seed_pack' => BalanceSimMarketProfile.s1PairSeedPack,
      's1_color_seed_pack' => BalanceSimMarketProfile.s1ColorSeedPack,
      's1_face_seed_pack' => BalanceSimMarketProfile.s1FaceSeedPack,
      's1_random_candidate_pool' =>
        BalanceSimMarketProfile.s1RandomCandidatePool,
      's1_probabilistic_candidate_pool' =>
        BalanceSimMarketProfile.s1ProbabilisticCandidatePool,
      's1_full_safe_candidate_pool' =>
        BalanceSimMarketProfile.s1FullSafeCandidatePool,
      's1_role_deck_sustain_pool' =>
        BalanceSimMarketProfile.s1RoleDeckSustainPool,
      's1_role_score_growth_pool' =>
        BalanceSimMarketProfile.s1RoleScoreGrowthPool,
      's1_role_shape_fix_pool' => BalanceSimMarketProfile.s1RoleShapeFixPool,
      's1_role_weak_flavor_pool' =>
        BalanceSimMarketProfile.s1RoleWeakFlavorPool,
      's1_station_weighted_candidate_pool' =>
        BalanceSimMarketProfile.s1StationWeightedCandidatePool,
      's1_state_weighted_candidate_pool' =>
        BalanceSimMarketProfile.s1StateWeightedCandidatePool,
      'banded_candidate_pool_v1' =>
        BalanceSimMarketProfile.bandedCandidatePoolV1,
      'banded_candidate_pool_v2' =>
        BalanceSimMarketProfile.bandedCandidatePoolV2,
      'shop_slot_market_v1' => BalanceSimMarketProfile.shopSlotMarketV1,
      'shop_slot_market_v2' => BalanceSimMarketProfile.shopSlotMarketV2,
      'shop_slot_market_v3' => BalanceSimMarketProfile.shopSlotMarketV3,
      'shop_slot_market_v4' => BalanceSimMarketProfile.shopSlotMarketV4,
      'shop_slot_market_v5' => BalanceSimMarketProfile.shopSlotMarketV5,
      'shop_slot_market_v6' => BalanceSimMarketProfile.shopSlotMarketV6,
      'shop_slot_market_v7' => BalanceSimMarketProfile.shopSlotMarketV7,
      'shop_slot_market_v8' => BalanceSimMarketProfile.shopSlotMarketV8,
      'shop_slot_market_v9' => BalanceSimMarketProfile.shopSlotMarketV9,
      'shop_slot_market_v10' => BalanceSimMarketProfile.shopSlotMarketV10,
      'shop_slot_market_v11' => BalanceSimMarketProfile.shopSlotMarketV11,
      'shop_slot_market_v12' => BalanceSimMarketProfile.shopSlotMarketV12,
      'shop_slot_market_v13' => BalanceSimMarketProfile.shopSlotMarketV13,
      's1_candidate_common_color_jester' =>
        BalanceSimMarketProfile.s1CandidateCommonColorJester,
      's1_candidate_common_rank_jester' =>
        BalanceSimMarketProfile.s1CandidateCommonRankJester,
      's1_candidate_uncommon_build_jester' =>
        BalanceSimMarketProfile.s1CandidateUncommonBuildJester,
      's1_candidate_rare_xmult_jester' =>
        BalanceSimMarketProfile.s1CandidateRareXmultJester,
      's1_candidate_legendary_bridge' =>
        BalanceSimMarketProfile.s1CandidateLegendaryBridge,
      's1_candidate_planet_rank_level' =>
        BalanceSimMarketProfile.s1CandidatePlanetRankLevel,
      's1_candidate_tarot_build_pack' =>
        BalanceSimMarketProfile.s1CandidateTarotBuildPack,
      's1_candidate_voucher_resource' =>
        BalanceSimMarketProfile.s1CandidateVoucherResource,
      _ => throw FormatException('Unknown market profile: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimMarketProfile.none => 'none',
      BalanceSimMarketProfile.s1BuyJolly => 's1_buy_jolly',
      BalanceSimMarketProfile.s1BuySly => 's1_buy_sly',
      BalanceSimMarketProfile.s1BuyDiscardGlove => 's1_buy_discard_glove',
      BalanceSimMarketProfile.s1TilePackSmall => 's1_tile_pack_small',
      BalanceSimMarketProfile.s1TilePackPlus3 => 's1_tile_pack_plus3',
      BalanceSimMarketProfile.s1TilePackPlus4 => 's1_tile_pack_plus4',
      BalanceSimMarketProfile.s1TilePackPlus5 => 's1_tile_pack_plus5',
      BalanceSimMarketProfile.s1BuildAwarePackPlus3 =>
        's1_build_aware_pack_plus3',
      BalanceSimMarketProfile.s1BuildAwarePackPlus5 =>
        's1_build_aware_pack_plus5',
      BalanceSimMarketProfile.s1PairSeedPack => 's1_pair_seed_pack',
      BalanceSimMarketProfile.s1ColorSeedPack => 's1_color_seed_pack',
      BalanceSimMarketProfile.s1FaceSeedPack => 's1_face_seed_pack',
      BalanceSimMarketProfile.s1RandomCandidatePool =>
        's1_random_candidate_pool',
      BalanceSimMarketProfile.s1ProbabilisticCandidatePool =>
        's1_probabilistic_candidate_pool',
      BalanceSimMarketProfile.s1FullSafeCandidatePool =>
        's1_full_safe_candidate_pool',
      BalanceSimMarketProfile.s1RoleDeckSustainPool =>
        's1_role_deck_sustain_pool',
      BalanceSimMarketProfile.s1RoleScoreGrowthPool =>
        's1_role_score_growth_pool',
      BalanceSimMarketProfile.s1RoleShapeFixPool => 's1_role_shape_fix_pool',
      BalanceSimMarketProfile.s1RoleWeakFlavorPool =>
        's1_role_weak_flavor_pool',
      BalanceSimMarketProfile.s1StationWeightedCandidatePool =>
        's1_station_weighted_candidate_pool',
      BalanceSimMarketProfile.s1StateWeightedCandidatePool =>
        's1_state_weighted_candidate_pool',
      BalanceSimMarketProfile.bandedCandidatePoolV1 =>
        'banded_candidate_pool_v1',
      BalanceSimMarketProfile.bandedCandidatePoolV2 =>
        'banded_candidate_pool_v2',
      BalanceSimMarketProfile.shopSlotMarketV1 => 'shop_slot_market_v1',
      BalanceSimMarketProfile.shopSlotMarketV2 => 'shop_slot_market_v2',
      BalanceSimMarketProfile.shopSlotMarketV3 => 'shop_slot_market_v3',
      BalanceSimMarketProfile.shopSlotMarketV4 => 'shop_slot_market_v4',
      BalanceSimMarketProfile.shopSlotMarketV5 => 'shop_slot_market_v5',
      BalanceSimMarketProfile.shopSlotMarketV6 => 'shop_slot_market_v6',
      BalanceSimMarketProfile.shopSlotMarketV7 => 'shop_slot_market_v7',
      BalanceSimMarketProfile.shopSlotMarketV8 => 'shop_slot_market_v8',
      BalanceSimMarketProfile.shopSlotMarketV9 => 'shop_slot_market_v9',
      BalanceSimMarketProfile.shopSlotMarketV10 => 'shop_slot_market_v10',
      BalanceSimMarketProfile.shopSlotMarketV11 => 'shop_slot_market_v11',
      BalanceSimMarketProfile.shopSlotMarketV12 => 'shop_slot_market_v12',
      BalanceSimMarketProfile.shopSlotMarketV13 => 'shop_slot_market_v13',
      BalanceSimMarketProfile.s1CandidateCommonColorJester =>
        's1_candidate_common_color_jester',
      BalanceSimMarketProfile.s1CandidateCommonRankJester =>
        's1_candidate_common_rank_jester',
      BalanceSimMarketProfile.s1CandidateUncommonBuildJester =>
        's1_candidate_uncommon_build_jester',
      BalanceSimMarketProfile.s1CandidateRareXmultJester =>
        's1_candidate_rare_xmult_jester',
      BalanceSimMarketProfile.s1CandidateLegendaryBridge =>
        's1_candidate_legendary_bridge',
      BalanceSimMarketProfile.s1CandidatePlanetRankLevel =>
        's1_candidate_planet_rank_level',
      BalanceSimMarketProfile.s1CandidateTarotBuildPack =>
        's1_candidate_tarot_build_pack',
      BalanceSimMarketProfile.s1CandidateVoucherResource =>
        's1_candidate_voucher_resource',
    };
  }
}

class BalanceSimRunSpec {
  const BalanceSimRunSpec({
    required this.matrixIndex,
    required this.matrixSize,
    required this.seedOffset,
    required this.experimentId,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.loadout,
    required this.marketProfile,
  });

  final int matrixIndex;
  final int matrixSize;
  final int seedOffset;
  final String experimentId;
  final int station;
  final BlindTier blindTier;
  final NewRunDifficulty difficulty;
  final BalanceSimLoadoutSpec loadout;
  final BalanceSimMarketProfile marketProfile;
}

class BalanceSimSequenceRunSpec {
  const BalanceSimSequenceRunSpec({
    required this.matrixIndex,
    required this.experimentId,
    required this.marketProfile,
    required this.stations,
    required this.difficulty,
    required this.loadout,
  });

  final int matrixIndex;
  final String experimentId;
  final BalanceSimMarketProfile marketProfile;
  final List<int> stations;
  final NewRunDifficulty difficulty;
  final BalanceSimLoadoutSpec loadout;
}

class BalanceSimTargetMultiplierOverride {
  const BalanceSimTargetMultiplierOverride({
    required this.station,
    required this.tier,
    required this.multiplier,
    this.difficulty,
  });

  factory BalanceSimTargetMultiplierOverride.parse(String raw) {
    final parts = raw.split(':').map((part) => part.trim()).toList();
    if (parts.length != 3 && parts.length != 4) {
      throw FormatException('Invalid --target-multiplier value: $raw');
    }
    final stationRaw = parts[0].startsWith('S') || parts[0].startsWith('s')
        ? parts[0].substring(1)
        : parts[0];
    final station = int.tryParse(stationRaw);
    final multiplier = double.tryParse(parts[2]);
    if (station == null || station <= 0) {
      throw FormatException('Invalid target multiplier station: ${parts[0]}');
    }
    if (multiplier == null || multiplier <= 0) {
      throw FormatException('Invalid target multiplier value: ${parts[2]}');
    }
    return BalanceSimTargetMultiplierOverride(
      station: station,
      tier: BalanceSimCliConfig.parseBlindTierForInternalUse(parts[1]),
      multiplier: multiplier,
      difficulty: parts.length == 4
          ? BalanceSimCliConfig.parseDifficultyForInternalUse(parts[3])
          : null,
    );
  }

  final int station;
  final BlindTier tier;
  final double multiplier;
  final NewRunDifficulty? difficulty;

  bool matches({
    required int station,
    required BlindTier tier,
    required NewRunDifficulty difficulty,
  }) {
    return this.station == station &&
        this.tier == tier &&
        (this.difficulty == null || this.difficulty == difficulty);
  }
}

class BalanceSimLoadoutSpec {
  const BalanceSimLoadoutSpec({
    required this.id,
    required this.jesterIds,
    required this.itemIds,
    this.maxHandSizeDelta = 0,
    this.boardMovesDelta = 0,
    this.boardDiscardsDelta = 0,
    this.handDiscardsDelta = 0,
  });

  final String id;
  final List<String> jesterIds;
  final List<String> itemIds;
  final int maxHandSizeDelta;
  final int boardMovesDelta;
  final int boardDiscardsDelta;
  final int handDiscardsDelta;

  Map<String, Object?> effectsJson() {
    return <String, Object?>{
      'sim_only': hasSimOnlyGrowth,
      'max_hand_size_delta': maxHandSizeDelta,
      'board_moves_delta': boardMovesDelta,
      'board_discards_delta': boardDiscardsDelta,
      'hand_discards_delta': handDiscardsDelta,
    };
  }

  bool get hasSimOnlyGrowth =>
      maxHandSizeDelta != 0 ||
      boardMovesDelta != 0 ||
      boardDiscardsDelta != 0 ||
      handDiscardsDelta != 0;
}

void _applySimOnlyLoadoutGrowth(
  RummiPokerGridSession session,
  BalanceSimLoadoutSpec loadout,
) {
  if (!loadout.hasSimOnlyGrowth) return;

  // 실제 런타임 성장 확정 전까지는 시뮬레이터 입력값만 보정한다.
  session.maxHandSize += loadout.maxHandSizeDelta;
  session.blind.boardMovesRemaining += loadout.boardMovesDelta;
  session.blind.boardDiscardsRemaining += loadout.boardDiscardsDelta;
  session.blind.handDiscardsRemaining += loadout.handDiscardsDelta;
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
    'planner_v2' => const PlannerV2BotPolicy(),
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
    required this.sequenceMode,
    required this.station,
    required this.blindTier,
    required this.difficulty,
    required this.stations,
    required this.blindTiers,
    required this.difficulties,
    required this.experimentIds,
    required this.marketProfiles,
    required this.simEconomyMode,
    required this.simRewardScale,
    required this.simPriceScale,
    required this.simMarketBudgetMode,
    required this.simMarketSpendMode,
    required this.simPriceBandMode,
    required this.simMarketChoiceMode,
    required this.runModifier,
    required this.targetMultiplierOverrides,
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
    var sequenceMode = BalanceSimSequenceMode.none;
    var station = 1;
    var blindTier = BlindTier.small;
    var difficulty = NewRunDifficulty.standard;
    var simEconomyMode = BalanceSimEconomyMode.traceOnly;
    var simRewardScale = 1.0;
    var simPriceScale = 1.0;
    var simMarketBudgetMode = BalanceSimMarketBudgetMode.none;
    var simMarketSpendMode = BalanceSimMarketSpendMode.none;
    var simPriceBandMode = BalanceSimPriceBandMode.none;
    var simMarketChoiceMode = BalanceSimMarketChoiceMode.none;
    var runModifier = NewRunModifier.basic;
    List<int>? stations;
    List<BlindTier>? blindTiers;
    List<NewRunDifficulty>? difficulties;
    final experimentIds = <String>[];
    final marketProfiles = <BalanceSimMarketProfile>[];
    final targetMultiplierOverrides = <BalanceSimTargetMultiplierOverride>[];
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
        case '--sequence-mode':
          sequenceMode = BalanceSimSequenceMode.parse(readValue());
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
        case '--experiment-id':
          experimentIds.add(_parseExperimentId(readValue()));
        case '--experiment-ids':
          experimentIds.addAll(_parseExperimentIdList(readValue()));
        case '--market-profile':
          marketProfiles.add(BalanceSimMarketProfile.parse(readValue()));
        case '--market-profiles':
          marketProfiles.addAll(_parseMarketProfileList(readValue()));
        case '--sim-economy-mode':
          simEconomyMode = BalanceSimEconomyMode.parse(readValue());
        case '--sim-reward-scale':
          final parsed = double.tryParse(readValue());
          if (parsed == null || parsed <= 0) {
            throw const FormatException(
              '--sim-reward-scale must be a positive number',
            );
          }
          simRewardScale = parsed;
        case '--sim-price-scale':
          final parsed = double.tryParse(readValue());
          if (parsed == null || parsed <= 0) {
            throw const FormatException(
              '--sim-price-scale must be a positive number',
            );
          }
          simPriceScale = parsed;
        case '--sim-market-budget-mode':
          simMarketBudgetMode = BalanceSimMarketBudgetMode.parse(readValue());
        case '--sim-market-spend-mode':
          simMarketSpendMode = BalanceSimMarketSpendMode.parse(readValue());
        case '--sim-price-band-mode':
          simPriceBandMode = BalanceSimPriceBandMode.parse(readValue());
        case '--sim-market-choice-mode':
          simMarketChoiceMode = BalanceSimMarketChoiceMode.parse(readValue());
        case '--run-modifier':
          runModifier = _parseRunModifier(readValue());
        case '--target-multiplier':
          targetMultiplierOverrides.add(
            BalanceSimTargetMultiplierOverride.parse(readValue()),
          );
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
    if (sequenceMode == BalanceSimSequenceMode.none &&
        marketProfiles.any(
          (profile) => profile != BalanceSimMarketProfile.none,
        )) {
      throw const FormatException(
        '--market-profile requires --sequence-mode station_path',
      );
    }

    return BalanceSimCliConfig(
      runs: runs,
      bot: bot,
      seed: seed,
      outPath: outPath,
      summaryOutPath: summaryOutPath,
      turnCap: turnCap,
      sequenceMode: sequenceMode,
      station: station,
      blindTier: blindTier,
      difficulty: difficulty,
      stations: List<int>.unmodifiable(stations ?? [station]),
      blindTiers: List<BlindTier>.unmodifiable(blindTiers ?? [blindTier]),
      difficulties: List<NewRunDifficulty>.unmodifiable(
        difficulties ?? [difficulty],
      ),
      experimentIds: List<String>.unmodifiable(
        experimentIds.isEmpty ? ['baseline'] : experimentIds,
      ),
      marketProfiles: List<BalanceSimMarketProfile>.unmodifiable(
        marketProfiles.isEmpty
            ? [BalanceSimMarketProfile.none]
            : marketProfiles,
      ),
      simEconomyMode: simEconomyMode,
      simRewardScale: simRewardScale,
      simPriceScale: simPriceScale,
      simMarketBudgetMode: simMarketBudgetMode,
      simMarketSpendMode: simMarketSpendMode,
      simPriceBandMode: simPriceBandMode,
      simMarketChoiceMode: simMarketChoiceMode,
      runModifier: runModifier,
      targetMultiplierOverrides:
          List<BalanceSimTargetMultiplierOverride>.unmodifiable(
            targetMultiplierOverrides,
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
      'Usage: dart run tools/sim/run_balance_sim.dart --runs 10 --bot greedy_v1|planner_v1|planner_v2 --seed 42 --out logs/sim_balance.jsonl [--summary-out logs/sim_summary.json] [--turn-cap n] [--sequence-mode none|station_path] [--station n|--stations 1,2] [--blind-tier small|--blind-tiers small,big,boss] [--difficulty standard|--difficulties relaxed,standard,pressure] [--run-modifier basic|high_stakes] [--experiment-id baseline|candidate_baseline_v1|base_score_curve_v2|base_score_curve_v2_boss_constraint_pool_v2|base_score_curve_v2_boss_constraint_pool_v4|base_score_curve_v2_boss_constraint_pool_v4_s1_soft|base_score_curve_v2_boss_constraint_pool_v4_s1_resource|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085|base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v2|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v3|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3|base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2|base_score_curve_v2_boss_constraint_pool_v4_three_band_v1|base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1|base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1|baseline_curve_160|station_curve_145|station_curve_135|station_curve_125|station_curve_125_target_v5|station_curve_125_target_v6_s5_070|station_curve_125_target_v6_s5_075|station_curve_125_target_v7_s4_080_s5_070|station_curve_125_boss_constraint_pool_v1|station_curve_135_boss_constraint_pool_v1|station_curve_125_boss_constraint_pool_v2|station_curve_125_target_v5_boss_constraint_pool_v2|station_curve_125_target_v6_s5_070_boss_constraint_pool_v2|station_curve_125_target_v6_s5_075_boss_constraint_pool_v2|station_curve_125_target_v6_s5_070_boss_constraint_pool_v3|station_curve_125_target_v7_s4_080_s5_070_boss_constraint_pool_v3|station_curve_125_target_v6_s5_070_boss_constraint_pool_v4|station_curve_125_boss_constraint_pool_soft|station_curve_135_boss_constraint_pool_soft|station_curve_125_boss_constraint_pool_hard|station_curve_135_boss_constraint_pool_hard|s1_boss_target_070|early_boss_target_085|early_boss_target_080|early_boss_target_075|early_boss_resource_1|s2_boss_target_soften|s2_boss_target_085|s2_boss_target_080|s2_boss_target_075|s2_boss_modifier_soften|s2_boss_resource_boost] [--target-multiplier S3:boss:0.85[:standard]] [--market-profile none|s1_buy_jolly|s1_buy_sly|s1_buy_discard_glove|s1_tile_pack_small|s1_tile_pack_plus3|s1_tile_pack_plus4|s1_tile_pack_plus5|s1_build_aware_pack_plus3|s1_build_aware_pack_plus5|s1_pair_seed_pack|s1_color_seed_pack|s1_face_seed_pack|s1_random_candidate_pool|s1_probabilistic_candidate_pool|s1_full_safe_candidate_pool|s1_role_deck_sustain_pool|s1_role_score_growth_pool|s1_role_shape_fix_pool|s1_role_weak_flavor_pool|s1_station_weighted_candidate_pool|s1_state_weighted_candidate_pool|banded_candidate_pool_v1|banded_candidate_pool_v2|shop_slot_market_v1|shop_slot_market_v2|shop_slot_market_v3|shop_slot_market_v4|shop_slot_market_v5|shop_slot_market_v6|shop_slot_market_v7|shop_slot_market_v8|shop_slot_market_v9|shop_slot_market_v10|shop_slot_market_v11] [--loadout-id baseline|pair_mult|safety_item|score_abacus|mobility_item|s1_entry_bridge_build|s2_foundation_build|s3_hand_growth_build|s4_resource_build|s5_power_build|s5_sustain_build|s5_boss_bridge_build|planet_like_rank_level|tarot_like_tile_shape|enhanced_line_score|rare_jester_engine|rare_xmult_engine|s6_boss_breaker_build|s8_finale_build|progression_route_slow|progression_route_balanced|progression_route_delayed|progression_route_sustain|progression_route_power] [--jester id] [--item id]';

  static BlindTier parseBlindTierForInternalUse(String raw) =>
      _parseBlindTier(raw);

  static NewRunDifficulty parseDifficultyForInternalUse(String raw) =>
      _parseDifficulty(raw);

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

  static NewRunModifier _parseRunModifier(String raw) {
    for (final modifier in NewRunModifier.values) {
      if (modifier.id == raw) return modifier;
    }
    throw FormatException('Unknown run modifier: $raw');
  }

  static String _parseExperimentId(String raw) {
    const ids = {
      'baseline',
      'candidate_baseline_v1',
      'base_score_curve_v2',
      'base_score_curve_v2_boss_constraint_pool_v2',
      'base_score_curve_v2_boss_constraint_pool_v4',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_resource',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v2',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v3',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_rank_cycle_probe_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_probe_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_repeat_only_probe_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_single_only_probe_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_rank_cycle_soft_probe_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2',
      'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1',
      'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1',
      'baseline_curve_160',
      'station_curve_145',
      'station_curve_135',
      'station_curve_125',
      'station_curve_125_target_v5',
      'station_curve_125_target_v6_s5_070',
      'station_curve_125_target_v6_s5_075',
      'station_curve_125_target_v7_s4_080_s5_070',
      'station_curve_125_boss_constraint_pool_v1',
      'station_curve_135_boss_constraint_pool_v1',
      'station_curve_125_boss_constraint_pool_v2',
      'station_curve_125_target_v5_boss_constraint_pool_v2',
      'station_curve_125_target_v6_s5_070_boss_constraint_pool_v2',
      'station_curve_125_target_v6_s5_075_boss_constraint_pool_v2',
      'station_curve_125_target_v6_s5_070_boss_constraint_pool_v3',
      'station_curve_125_target_v7_s4_080_s5_070_boss_constraint_pool_v3',
      'station_curve_125_target_v6_s5_070_boss_constraint_pool_v4',
      'station_curve_125_boss_constraint_pool_soft',
      'station_curve_135_boss_constraint_pool_soft',
      'station_curve_125_boss_constraint_pool_hard',
      'station_curve_135_boss_constraint_pool_hard',
      's1_boss_target_070',
      'early_boss_target_085',
      'early_boss_target_080',
      'early_boss_target_075',
      'early_boss_resource_1',
      's2_boss_target_soften',
      's2_boss_target_085',
      's2_boss_target_080',
      's2_boss_target_075',
      's2_boss_modifier_soften',
      's2_boss_resource_boost',
    };
    if (ids.contains(raw)) return raw;
    if (raw.startsWith(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_',
    )) {
      return raw;
    }
    throw FormatException('Unknown experiment id: $raw');
  }

  static List<String> _parseExperimentIdList(String raw) {
    return _parseCommaSeparated(
      raw,
      '--experiment-ids',
    ).map(_parseExperimentId).toList(growable: false);
  }

  static List<BalanceSimMarketProfile> _parseMarketProfileList(String raw) {
    return _parseCommaSeparated(
      raw,
      '--market-profiles',
    ).map(BalanceSimMarketProfile.parse).toList(growable: false);
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
      's1_entry_bridge_build' => const BalanceSimLoadoutSpec(
        id: 's1_entry_bridge_build',
        jesterIds: ['jolly_jester'],
        itemIds: [],
        boardMovesDelta: 1,
      ),
      's2_foundation_build' => const BalanceSimLoadoutSpec(
        id: 's2_foundation_build',
        jesterIds: ['jolly_jester', 'sly_jester'],
        itemIds: ['discard_glove'],
        boardMovesDelta: 1,
      ),
      's3_hand_growth_build' => const BalanceSimLoadoutSpec(
        id: 's3_hand_growth_build',
        jesterIds: ['jolly_jester', 'zany_jester', 'sly_jester'],
        itemIds: ['score_abacus'],
        maxHandSizeDelta: 1,
        boardMovesDelta: 1,
        handDiscardsDelta: 1,
      ),
      's4_resource_build' => const BalanceSimLoadoutSpec(
        id: 's4_resource_build',
        jesterIds: ['jolly_jester', 'zany_jester', 'sly_jester'],
        itemIds: ['score_abacus', 'organizer_glove', 'mulligan_sleeve'],
        maxHandSizeDelta: 1,
        boardMovesDelta: 1,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 1,
      ),
      's5_power_build' => const BalanceSimLoadoutSpec(
        id: 's5_power_build',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'sly_jester',
          'abstract_jester',
        ],
        itemIds: ['score_abacus', 'thin_caliper', 'organizer_glove'],
        maxHandSizeDelta: 1,
        boardMovesDelta: 2,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 1,
      ),
      's5_sustain_build' => const BalanceSimLoadoutSpec(
        id: 's5_sustain_build',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'sly_jester',
          'abstract_jester',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
          'mulligan_sleeve',
        ],
        maxHandSizeDelta: 2,
        boardMovesDelta: 2,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 2,
      ),
      's5_boss_bridge_build' => const BalanceSimLoadoutSpec(
        id: 's5_boss_bridge_build',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'sly_jester',
          'abstract_jester',
          'banner',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
        ],
        maxHandSizeDelta: 2,
        boardMovesDelta: 2,
        boardDiscardsDelta: 2,
        handDiscardsDelta: 1,
      ),
      'planet_like_rank_level' => const BalanceSimLoadoutSpec(
        id: 'planet_like_rank_level',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'sly_jester',
          'supernova',
          'ride_the_bus',
        ],
        itemIds: ['score_abacus', 'thin_caliper', 'echo_bell'],
        maxHandSizeDelta: 1,
        boardMovesDelta: 2,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 1,
      ),
      'tarot_like_tile_shape' => const BalanceSimLoadoutSpec(
        id: 'tarot_like_tile_shape',
        jesterIds: [
          'fibonacci',
          'even_steven',
          'odd_todd',
          'crazy_jester',
          'devious_jester',
        ],
        itemIds: ['organizer_glove', 'mulligan_sleeve', 'travel_pouch'],
        maxHandSizeDelta: 2,
        boardMovesDelta: 2,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 2,
      ),
      'enhanced_line_score' => const BalanceSimLoadoutSpec(
        id: 'enhanced_line_score',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'abstract_jester',
          'gros_michel',
        ],
        itemIds: ['score_abacus', 'thin_caliper', 'echo_bell', 'tile_polisher'],
        maxHandSizeDelta: 1,
        boardMovesDelta: 2,
        boardDiscardsDelta: 1,
        handDiscardsDelta: 1,
      ),
      'rare_jester_engine' => const BalanceSimLoadoutSpec(
        id: 'rare_jester_engine',
        jesterIds: [
          'supernova',
          'green_jester',
          'fibonacci',
          'banner',
          'gros_michel',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
        ],
        maxHandSizeDelta: 2,
        boardMovesDelta: 2,
        boardDiscardsDelta: 2,
        handDiscardsDelta: 1,
      ),
      'rare_xmult_engine' => const BalanceSimLoadoutSpec(
        id: 'rare_xmult_engine',
        jesterIds: [
          'the_duo',
          'the_trio',
          'the_family',
          'the_order',
          'the_tribe',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
        ],
        maxHandSizeDelta: 2,
        boardMovesDelta: 2,
        boardDiscardsDelta: 2,
        handDiscardsDelta: 1,
      ),
      's6_boss_breaker_build' => const BalanceSimLoadoutSpec(
        id: 's6_boss_breaker_build',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'sly_jester',
          'abstract_jester',
          'banner',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
        ],
        maxHandSizeDelta: 1,
        boardMovesDelta: 2,
        boardDiscardsDelta: 2,
        handDiscardsDelta: 1,
      ),
      's8_finale_build' => const BalanceSimLoadoutSpec(
        id: 's8_finale_build',
        jesterIds: [
          'jolly_jester',
          'zany_jester',
          'abstract_jester',
          'banner',
          'supernova',
        ],
        itemIds: [
          'score_abacus',
          'thin_caliper',
          'organizer_glove',
          'travel_pouch',
          'echo_bell',
        ],
        maxHandSizeDelta: 2,
        boardMovesDelta: 3,
        boardDiscardsDelta: 2,
        handDiscardsDelta: 2,
      ),
      'progression_route_slow' => const BalanceSimLoadoutSpec(
        id: 'progression_route_slow',
        jesterIds: [],
        itemIds: [],
      ),
      'progression_route_balanced' => const BalanceSimLoadoutSpec(
        id: 'progression_route_balanced',
        jesterIds: [],
        itemIds: [],
      ),
      'progression_route_delayed' => const BalanceSimLoadoutSpec(
        id: 'progression_route_delayed',
        jesterIds: [],
        itemIds: [],
      ),
      'progression_route_sustain' => const BalanceSimLoadoutSpec(
        id: 'progression_route_sustain',
        jesterIds: [],
        itemIds: [],
      ),
      'progression_route_power' => const BalanceSimLoadoutSpec(
        id: 'progression_route_power',
        jesterIds: [],
        itemIds: [],
      ),
      _ => throw FormatException('Unknown loadout id: $raw'),
    };
  }

  static BalanceSimLoadoutSpec parseLoadoutPresetForInternalUse(String raw) =>
      _parseLoadoutPreset(raw);

  final int runs;
  final String bot;
  final int seed;
  final String outPath;
  final String? summaryOutPath;
  final int turnCap;
  final BalanceSimSequenceMode sequenceMode;
  final int station;
  final BlindTier blindTier;
  final NewRunDifficulty difficulty;
  final List<int> stations;
  final List<BlindTier> blindTiers;
  final List<NewRunDifficulty> difficulties;
  final List<String> experimentIds;
  final List<BalanceSimMarketProfile> marketProfiles;
  final BalanceSimEconomyMode simEconomyMode;
  final double simRewardScale;
  final double simPriceScale;
  final BalanceSimMarketBudgetMode simMarketBudgetMode;
  final BalanceSimMarketSpendMode simMarketSpendMode;
  final BalanceSimPriceBandMode simPriceBandMode;
  final BalanceSimMarketChoiceMode simMarketChoiceMode;
  final NewRunModifier runModifier;
  final List<BalanceSimTargetMultiplierOverride> targetMultiplierOverrides;
  final List<BalanceSimLoadoutSpec> loadouts;
  final List<String> jesterIds;
  final List<String> itemIds;

  int get matrixSize =>
      stations.length *
      blindTiers.length *
      difficulties.length *
      experimentIds.length *
      loadouts.length;

  int get sequenceMatrixSize =>
      difficulties.length *
      experimentIds.length *
      marketProfiles.length *
      loadouts.length;

  double get effectiveSimRewardScale =>
      simRewardScale * runModifier.rewardMultiplier;

  bool get isMatrix => matrixSize > 1;

  List<BalanceSimRunSpec> get runSpecs {
    final specs = <BalanceSimRunSpec>[];
    var matrixIndex = 0;
    for (final station in stations) {
      for (final blindTier in blindTiers) {
        for (final difficulty in difficulties) {
          for (final experimentId in experimentIds) {
            for (final loadout in loadouts) {
              final currentMatrixIndex = matrixIndex++;
              specs.add(
                BalanceSimRunSpec(
                  matrixIndex: currentMatrixIndex,
                  matrixSize: matrixSize,
                  seedOffset: currentMatrixIndex,
                  experimentId: experimentId,
                  station: station,
                  blindTier: blindTier,
                  difficulty: difficulty,
                  loadout: loadout,
                  marketProfile: BalanceSimMarketProfile.none,
                ),
              );
            }
          }
        }
      }
    }
    return List<BalanceSimRunSpec>.unmodifiable(specs);
  }

  List<BalanceSimSequenceRunSpec> get sequenceRunSpecs {
    final specs = <BalanceSimSequenceRunSpec>[];
    final stationPath = stations.toSet().toList()..sort();
    var matrixIndex = 0;
    for (final difficulty in difficulties) {
      for (final experimentId in experimentIds) {
        for (final marketProfile in marketProfiles) {
          for (final loadout in loadouts) {
            specs.add(
              BalanceSimSequenceRunSpec(
                matrixIndex: matrixIndex++,
                experimentId: experimentId,
                marketProfile: marketProfile,
                stations: List<int>.unmodifiable(stationPath),
                difficulty: difficulty,
                loadout: loadout,
              ),
            );
          }
        }
      }
    }
    return List<BalanceSimSequenceRunSpec>.unmodifiable(specs);
  }
}
