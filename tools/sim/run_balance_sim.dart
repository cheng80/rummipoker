import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/app_config.dart';
import 'package:rummipoker/logic/rummi_poker_grid/boss_modifier.dart';
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
  int _runCount = 0;

  void add(Map<String, Object?> row) {
    final result = row['result'] as Map<String, Object?>;
    final group = BalanceSimSummaryGroup(
      experimentId: row['experiment_id'] as String,
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
        );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schema_version': 1,
      'source_path': sourcePath,
      'run_count': _runCount,
      'group_by': [
        'experiment_id',
        'loadout_id',
        'station',
        'blind_tier',
        'difficulty',
      ],
      'groups': _groups.values.map((group) => group.toJson()).toList(),
    };
  }
}

class BalanceSimSummaryGroup {
  BalanceSimSummaryGroup({
    required this.experimentId,
    required this.loadoutId,
    required this.station,
    required this.blindTier,
    required this.difficulty,
  });

  final String experimentId;
  final String loadoutId;
  final int station;
  final String blindTier;
  final String difficulty;
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

  String get key => '$experimentId|$loadoutId|$station|$blindTier|$difficulty';

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
      'loadout_id': loadoutId,
      'station': station,
      'blind_tier': blindTier,
      'difficulty': difficulty,
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
  var stepIndex = 0;
  var clearedStepCount = 0;
  var totalTurnCount = 0;
  var totalScore = 0;
  var totalTargetScore = 0;
  int? failedAtStation;
  String? failedAtTier;
  int? failedStepIndex;
  String? failureStopReason;

  for (final station in stationPath) {
    for (final tier in tierPath) {
      final effectiveLoadout = _sequenceEffectiveLoadout(
        baseLoadout: spec.loadout,
        station: station,
        marketProfile: spec.marketProfile,
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
      row['base_loadout_id'] = spec.loadout.id;
      row['market_purchase_events'] = _sequenceMarketPurchaseEvents(
        marketProfile: spec.marketProfile,
        jesterCatalog: jesterCatalog,
        itemCatalog: itemCatalog,
      );
      battleRows.add(row);

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
            lastStepResourceState: _sequenceResourceStateFromRow(row),
            failedStepResourceState: _sequenceResourceStateFromRow(row),
            jesterCatalog: jesterCatalog,
            itemCatalog: itemCatalog,
            totalTurnCount: totalTurnCount,
            totalScore: totalScore,
            totalTargetScore: totalTargetScore,
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
}) {
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
    'loadout_id': spec.loadout.id,
    'loadout_effects': spec.loadout.effectsJson(),
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
      marketProfile: spec.marketProfile,
      jesterCatalog: jesterCatalog,
      itemCatalog: itemCatalog,
    ),
    'total_turn_count': totalTurnCount,
    'total_score': totalScore,
    'total_target_score': totalTargetScore,
    'total_score_ratio': totalTargetScore == 0
        ? 0
        : totalScore / totalTargetScore,
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
  return <String, Object?>{
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
}

BalanceSimLoadoutSpec _sequenceEffectiveLoadout({
  required BalanceSimLoadoutSpec baseLoadout,
  required int station,
  required BalanceSimMarketProfile marketProfile,
}) {
  if (station <= 1 || marketProfile == BalanceSimMarketProfile.none) {
    return baseLoadout;
  }
  final jesterIds = [...baseLoadout.jesterIds];
  final itemIds = [...baseLoadout.itemIds];
  switch (marketProfile) {
    case BalanceSimMarketProfile.none:
      break;
    case BalanceSimMarketProfile.s1BuyJolly:
      _addUnique(jesterIds, 'jolly_jester');
    case BalanceSimMarketProfile.s1BuySly:
      _addUnique(jesterIds, 'sly_jester');
    case BalanceSimMarketProfile.s1BuyDiscardGlove:
      _addUnique(itemIds, 'discard_glove');
  }
  return BalanceSimLoadoutSpec(
    id: '${baseLoadout.id}__${marketProfile.id}',
    jesterIds: List<String>.unmodifiable(jesterIds),
    itemIds: List<String>.unmodifiable(itemIds),
    maxHandSizeDelta: baseLoadout.maxHandSizeDelta,
    boardMovesDelta: baseLoadout.boardMovesDelta,
    boardDiscardsDelta: baseLoadout.boardDiscardsDelta,
    handDiscardsDelta: baseLoadout.handDiscardsDelta,
  );
}

List<Map<String, Object?>> _sequenceMarketPurchaseEvents({
  required BalanceSimMarketProfile marketProfile,
  required RummiJesterCatalog jesterCatalog,
  required ItemCatalog itemCatalog,
}) {
  if (marketProfile == BalanceSimMarketProfile.none) return const [];
  final contentId = switch (marketProfile) {
    BalanceSimMarketProfile.none => '',
    BalanceSimMarketProfile.s1BuyJolly => 'jolly_jester',
    BalanceSimMarketProfile.s1BuySly => 'sly_jester',
    BalanceSimMarketProfile.s1BuyDiscardGlove => 'discard_glove',
  };
  final category = marketProfile == BalanceSimMarketProfile.s1BuyDiscardGlove
      ? 'item'
      : 'jester';
  final cost = category == 'jester'
      ? jesterCatalog.findById(contentId)?.baseCost
      : itemCatalog.findById(contentId)?.basePrice;
  return [
    <String, Object?>{
      'after_station': 1,
      'category': category,
      'content_id': contentId,
      'cost': cost,
      'simulated': true,
    },
  ];
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
    station: station,
    tier: tier,
    difficulty: spec.difficulty,
    baseTargetScore: blindSpec.targetScore,
    baseBoardDiscards: blindSpec.boardDiscards,
    baseHandDiscards: blindSpec.handDiscards,
    baseBossModifier: blindSpec.bossModifier,
  );
  final experiment = _applyTargetMultiplierOverrides(
    experiment: experimentBase,
    overrides: config.targetMultiplierOverrides,
    station: station,
    tier: tier,
    difficulty: spec.difficulty,
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
    targetScore: experiment.targetScore,
    boardDiscards: experiment.boardDiscards,
    handDiscards: experiment.handDiscards,
    maxHandSize: blindSpec.maxHandSize,
    applyRoundEndDecay: false,
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

BalanceSimExperimentSpec _resolveExperiment({
  required String id,
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
      final stationGrowthBase = _stationGrowthBaseForExperiment(id);
      final targetScore = _targetScoreForStationCurve(
        station: station,
        tier: tier,
        difficulty: difficulty,
        stationGrowthBase: stationGrowthBase,
      );
      effects['station_growth_base'] = stationGrowthBase;
      effects['runtime_base_target_score'] = baseTargetScore;
      return BalanceSimExperimentSpec(
        id: id,
        applied: id != 'baseline_curve_160',
        targetScore: targetScore,
        boardDiscards: baseBoardDiscards,
        handDiscards: baseHandDiscards,
        bossModifier: baseBossModifier,
        effects: effects,
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
    _ => throw FormatException('Unknown station curve experiment id: $id'),
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

enum BalanceSimMarketProfile {
  none,
  s1BuyJolly,
  s1BuySly,
  s1BuyDiscardGlove;

  static BalanceSimMarketProfile parse(String raw) {
    return switch (raw) {
      'none' => BalanceSimMarketProfile.none,
      's1_buy_jolly' => BalanceSimMarketProfile.s1BuyJolly,
      's1_buy_sly' => BalanceSimMarketProfile.s1BuySly,
      's1_buy_discard_glove' => BalanceSimMarketProfile.s1BuyDiscardGlove,
      _ => throw FormatException('Unknown market profile: $raw'),
    };
  }

  String get id {
    return switch (this) {
      BalanceSimMarketProfile.none => 'none',
      BalanceSimMarketProfile.s1BuyJolly => 's1_buy_jolly',
      BalanceSimMarketProfile.s1BuySly => 's1_buy_sly',
      BalanceSimMarketProfile.s1BuyDiscardGlove => 's1_buy_discard_glove',
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
  });

  final int matrixIndex;
  final int matrixSize;
  final int seedOffset;
  final String experimentId;
  final int station;
  final BlindTier blindTier;
  final NewRunDifficulty difficulty;
  final BalanceSimLoadoutSpec loadout;
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
      'Usage: dart run tools/sim/run_balance_sim.dart --runs 10 --bot greedy_v1|planner_v1|planner_v2 --seed 42 --out logs/sim_balance.jsonl [--summary-out logs/sim_summary.json] [--turn-cap n] [--sequence-mode none|station_path] [--station n|--stations 1,2] [--blind-tier small|--blind-tiers small,big,boss] [--difficulty standard|--difficulties relaxed,standard,pressure] [--experiment-id baseline|baseline_curve_160|station_curve_145|station_curve_135|station_curve_125|s1_boss_target_070|early_boss_target_085|early_boss_target_080|early_boss_target_075|early_boss_resource_1|s2_boss_target_soften|s2_boss_target_085|s2_boss_target_080|s2_boss_target_075|s2_boss_modifier_soften|s2_boss_resource_boost] [--target-multiplier S3:boss:0.85[:standard]] [--market-profile none|s1_buy_jolly|s1_buy_sly|s1_buy_discard_glove] [--loadout-id baseline|pair_mult|safety_item|score_abacus|mobility_item|s1_entry_bridge_build|s2_foundation_build|s3_hand_growth_build|s4_resource_build|s5_power_build|s6_boss_breaker_build|s8_finale_build] [--jester id] [--item id]';

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

  static String _parseExperimentId(String raw) {
    const ids = {
      'baseline',
      'baseline_curve_160',
      'station_curve_145',
      'station_curve_135',
      'station_curve_125',
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
      _ => throw FormatException('Unknown loadout id: $raw'),
    };
  }

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
