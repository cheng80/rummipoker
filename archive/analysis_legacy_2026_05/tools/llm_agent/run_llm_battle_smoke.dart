import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../../../../tools/sim/balance_action_executor.dart';
import '../../../../tools/sim/bot_policy.dart';
import '../../../../tools/sim/llm_action_schema.dart';
import '../../../../tools/sim/llm_state_exporter.dart';
import '../../../../tools/sim/planner_bot.dart';
import 'llm_policy_guidance.dart';
import 'llm_policy_client.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final out = File(config.outPath)..parent.createSync(recursive: true);
  final report = File(config.reportOutPath)..parent.createSync(recursive: true);
  final rows = <Map<String, Object?>>[];

  for (var runIndex = 0; runIndex < config.runs; runIndex++) {
    final seed = config.seed + runIndex;
    final llmSession = _buildBattleSession(config, seed);
    final baselineSession = _buildBattleSession(config, seed);
    final runProgress = RummiRunProgress();
    final baselineRunProgress = RummiRunProgress();
    _startBattle(runProgress, llmSession, config, seed);
    _startBattle(baselineRunProgress, baselineSession, config, seed);

    for (var turn = 0; turn < config.turnCap; turn++) {
      final expiry = llmSession.evaluateExpirySignals();
      if (llmSession.blind.isTargetMet || expiry.isNotEmpty) {
        rows.add(
          _terminalRow(
            config: config,
            runIndex: runIndex,
            turn: turn,
            session: llmSession,
            baselineSession: baselineSession,
            stopReason: llmSession.blind.isTargetMet
                ? 'cleared'
                : expiry.map((signal) => signal.name).join(','),
          ),
        );
        break;
      }

      final requestId = 'llm_battle_${config.seed}_${runIndex}_$turn';
      final request = applyFullRunPolicyGuidance(
        buildLlmActionRequest(
          llmSession,
          requestId: requestId,
          jesters: const [],
          runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
          station: config.station,
          blindTier: config.blindTier,
          turnCount: turn,
        ),
        maxActions: config.maxLegalActions,
      );
      final responseResult = await requestLocalLlmAction(
        request: request,
        config: config.clientConfig,
      );
      final validation = responseResult.response == null
          ? LlmActionValidationResult.invalid(responseResult.error ?? 'no_llm')
          : validateLlmActionResponse(
              response: LlmActionResponse.fromJson(responseResult.response!),
              legalActions: request.legalActions,
            );
      final fallbackAction = const FullRunPolicyV1BotPolicy().chooseAction(
        llmSession,
        jesters: const [],
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      );
      final selectedAction = validation.balanceAction ?? fallbackAction;
      final llmExecute = executeBalanceAction(
        llmSession,
        selectedAction,
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      );
      _applyRunProgressAfterAction(runProgress, llmExecute);

      final baselineAction = const FullRunPolicyV1BotPolicy().chooseAction(
        baselineSession,
        jesters: const [],
        runtimeSnapshot: baselineRunProgress.buildRuntimeSnapshot(),
      );
      final baselineExecute = executeBalanceAction(
        baselineSession,
        baselineAction,
        runtimeSnapshot: baselineRunProgress.buildRuntimeSnapshot(),
      );
      _applyRunProgressAfterAction(baselineRunProgress, baselineExecute);

      rows.add({
        'schema_version': 1,
        'row_type': 'llm_battle_turn',
        'run_index': runIndex,
        'turn': turn,
        'seed': seed,
        'station': config.station,
        'blind_tier': config.blindTier,
        'target_score': config.targetScore,
        'request_id': requestId,
        'model': config.model,
        'is_valid': validation.isValid,
        'invalid_reason': validation.invalidReason,
        'used_fallback': !validation.isValid,
        'selected_action_id': validation.selectedAction?.id,
        'selected_action_type': validation.selectedAction?.type,
        'executed_action_type': selectedAction.type.name,
        'baseline_action_type': baselineAction.type.name,
        'diverged_from_baseline':
            selectedAction.type != baselineAction.type ||
            selectedAction.handIndex != baselineAction.handIndex ||
            selectedAction.row != baselineAction.row ||
            selectedAction.col != baselineAction.col ||
            selectedAction.toRow != baselineAction.toRow ||
            selectedAction.toCol != baselineAction.toCol,
        'llm_execute_ok': llmExecute.ok,
        'llm_execute_reason': llmExecute.reason,
        'baseline_execute_ok': baselineExecute.ok,
        'baseline_execute_reason': baselineExecute.reason,
        'llm_score_after': llmExecute.scoreAfter,
        'baseline_score_after': baselineExecute.scoreAfter,
        'llm_reached_target': llmSession.blind.isTargetMet,
        'baseline_reached_target': baselineSession.blind.isTargetMet,
        'llm_score_delta': llmExecute.scoreDelta,
        'baseline_score_delta': baselineExecute.scoreDelta,
        'llm_hand_size_after': llmExecute.handSizeAfter,
        'llm_deck_remaining_after': llmExecute.deckRemainingAfter,
        'llm_board_occupancy_after': llmExecute.boardOccupancyAfter,
        'latency_ms': responseResult.latencyMs,
        'llm_error': responseResult.error,
      });
      if (selectedAction.type == BalanceSimActionType.stop) break;
    }
  }

  final sink = out.openWrite();
  try {
    for (final row in rows) {
      sink.writeln(jsonEncode(row));
    }
  } finally {
    await sink.close();
  }
  report.writeAsStringSync(_buildReport(rows, config));
  stdout.writeln('out: ${out.path}');
  stdout.writeln('report: ${report.path}');
}

RummiPokerGridSession _buildBattleSession(_Config config, int seed) {
  final session = RummiPokerGridSession(runSeed: seed);
  session.setDebugMaxHandSize(config.maxHandSize);
  return session;
}

void _startBattle(
  RummiRunProgress runProgress,
  RummiPokerGridSession session,
  _Config config,
  int seed,
) {
  runProgress.startBlind(
    session,
    stationIndex: config.station,
    blindTierIndex: _blindTierIndex(config.blindTier),
    shuffleSeed: RummiPokerGridSession.deriveStageShuffleSeed(
      seed,
      config.station,
    ),
    targetScore: config.targetScore,
    boardDiscards: config.boardDiscards,
    handDiscards: config.handDiscards,
    maxHandSize: config.maxHandSize,
    applyRoundEndDecay: false,
  );
}

void _applyRunProgressAfterAction(
  RummiRunProgress runProgress,
  BalanceActionExecutionResult result,
) {
  // The shared executor intentionally returns compact action results. Full
  // line-breakdown growth sync belongs in the eventual production runner.
  if (result.scoreDelta > 0) {
    runProgress.gold += 0;
  }
}

Map<String, Object?> _terminalRow({
  required _Config config,
  required int runIndex,
  required int turn,
  required RummiPokerGridSession session,
  required RummiPokerGridSession baselineSession,
  required String stopReason,
}) {
  return {
    'schema_version': 1,
    'row_type': 'llm_battle_terminal',
    'run_index': runIndex,
    'turn': turn,
    'station': config.station,
    'blind_tier': config.blindTier,
    'target_score': config.targetScore,
    'stop_reason': stopReason,
    'llm_score_after': session.blind.scoreTowardBlind,
    'baseline_score_after': baselineSession.blind.scoreTowardBlind,
    'llm_reached_target': session.blind.isTargetMet,
    'baseline_reached_target': baselineSession.blind.isTargetMet,
  };
}

int _blindTierIndex(String tier) {
  return switch (tier) {
    'small' => 0,
    'big' => 1,
    'boss' => 2,
    _ => 0,
  };
}

String _buildReport(List<Map<String, Object?>> rows, _Config config) {
  final decisions = rows
      .where((row) => row['row_type'] == 'llm_battle_turn')
      .toList(growable: false);
  final finalRows = _lastRowByRun(rows);
  final valid = decisions.where((row) => row['is_valid'] == true).length;
  final fallback = decisions
      .where((row) => row['used_fallback'] == true)
      .length;
  final diverged = decisions
      .where((row) => row['diverged_from_baseline'] == true)
      .length;
  final llmExecFail = decisions
      .where((row) => row['llm_execute_ok'] != true)
      .length;
  final avgLatency = decisions.isEmpty
      ? 0.0
      : decisions.fold<int>(
              0,
              (sum, row) => sum + ((row['latency_ms'] as num?)?.toInt() ?? 0),
            ) /
            decisions.length;
  final finalScoreDelta = finalRows.values.fold<int>(
    0,
    (sum, row) =>
        sum +
        ((row['llm_score_after'] as num?)?.toInt() ?? 0) -
        ((row['baseline_score_after'] as num?)?.toInt() ?? 0),
  );
  return [
    '# LLM Battle Smoke',
    '',
    '## Summary',
    '',
    '- model: ${config.model}',
    '- runs: ${config.runs}',
    '- turn_cap: ${config.turnCap}',
    '- station: ${config.station}',
    '- blind_tier: ${config.blindTier}',
    '- target_score: ${config.targetScore}',
    '- decisions: ${decisions.length}',
    '- valid responses: $valid',
    '- fallback executions: $fallback',
    '- fallback_rate: ${_rate(fallback, decisions.length)}',
    '- diverged_from_baseline: $diverged',
    '- divergence_rate: ${_rate(diverged, decisions.length)}',
    '- llm_execute_failures: $llmExecFail',
    '- avg_latency_ms: ${avgLatency.toStringAsFixed(1)}',
    '- final_score_delta_vs_baseline: $finalScoreDelta',
    '',
    '## LLM/Fallback Executed Action Types',
    '',
    for (final entry in _countBy(decisions, 'executed_action_type').entries)
      '- ${entry.key}: ${entry.value}',
    '',
    '## Scope',
    '',
    'This runner starts real blind sessions and uses the same session/action APIs as the simulator.',
    'It is still a short smoke: no shop path, item inventory, or full run economy is applied yet.',
  ].join('\n');
}

Map<int, Map<String, Object?>> _lastRowByRun(List<Map<String, Object?>> rows) {
  final byRun = <int, Map<String, Object?>>{};
  for (final row in rows) {
    final runIndex = (row['run_index'] as num?)?.toInt();
    if (runIndex == null) continue;
    byRun[runIndex] = row;
  }
  return byRun;
}

Map<String, int> _countBy(List<Map<String, Object?>> rows, String key) {
  final counts = <String, int>{};
  for (final row in rows) {
    final value = row[key] as String? ?? 'unknown';
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

String _rate(int numerator, int denominator) {
  if (denominator == 0) return '0.0000';
  return (numerator / denominator).toStringAsFixed(4);
}

class _Config {
  const _Config({
    required this.outPath,
    required this.reportOutPath,
    required this.runs,
    required this.turnCap,
    required this.seed,
    required this.station,
    required this.blindTier,
    required this.targetScore,
    required this.boardDiscards,
    required this.handDiscards,
    required this.maxHandSize,
    required this.maxLegalActions,
    required this.model,
    required this.temperature,
    required this.topP,
    required this.timeoutSeconds,
  });

  final String outPath;
  final String reportOutPath;
  final int runs;
  final int turnCap;
  final int seed;
  final int station;
  final String blindTier;
  final int targetScore;
  final int boardDiscards;
  final int handDiscards;
  final int maxHandSize;
  final int maxLegalActions;
  final String model;
  final double temperature;
  final double topP;
  final int timeoutSeconds;

  LlmPolicyClientConfig get clientConfig {
    return LlmPolicyClientConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
      requestDir: 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/battle_smoke_requests',
      responseDir: 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/battle_smoke_responses',
    );
  }

  static _Config parse(List<String> args) {
    var outPath = 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/battle_smoke_20260529.jsonl';
    var reportOutPath =
        'archive/analysis_legacy_2026_05/analysis/leveling/reports/llm_battle_smoke_20260529.md';
    var runs = 1;
    var turnCap = 4;
    var seed = 20260529;
    var station = 1;
    var blindTier = 'small';
    var targetScore = 300;
    var boardDiscards = 4;
    var handDiscards = 2;
    var maxHandSize = 2;
    var maxLegalActions = 24;
    var model = 'gemma4:e4b';
    var temperature = 0.2;
    var topP = 0.9;
    var timeoutSeconds = 60;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--out':
          outPath = args[++i];
        case '--report-out':
          reportOutPath = args[++i];
        case '--runs':
          runs = int.parse(args[++i]);
        case '--turn-cap':
          turnCap = int.parse(args[++i]);
        case '--seed':
          seed = int.parse(args[++i]);
        case '--station':
          station = int.parse(args[++i]);
        case '--blind-tier':
          blindTier = args[++i];
        case '--target-score':
          targetScore = int.parse(args[++i]);
        case '--board-discards':
          boardDiscards = int.parse(args[++i]);
        case '--hand-discards':
          handDiscards = int.parse(args[++i]);
        case '--max-hand-size':
          maxHandSize = int.parse(args[++i]);
        case '--max-legal-actions':
          maxLegalActions = int.parse(args[++i]);
        case '--model':
          model = args[++i];
        case '--temperature':
          temperature = double.parse(args[++i]);
        case '--top-p':
          topP = double.parse(args[++i]);
        case '--timeout-seconds':
          timeoutSeconds = int.parse(args[++i]);
        case '--help':
          _printUsageAndExit();
        default:
          throw FormatException('Unknown arg: ${args[i]}');
      }
    }
    if (runs <= 0) throw const FormatException('--runs must be positive');
    if (turnCap <= 0) {
      throw const FormatException('--turn-cap must be positive');
    }
    if (!const {'small', 'big', 'boss'}.contains(blindTier)) {
      throw const FormatException('--blind-tier must be small, big, or boss');
    }
    return _Config(
      outPath: outPath,
      reportOutPath: reportOutPath,
      runs: runs,
      turnCap: turnCap,
      seed: seed,
      station: station,
      blindTier: blindTier,
      targetScore: targetScore,
      boardDiscards: boardDiscards,
      handDiscards: handDiscards,
      maxHandSize: maxHandSize,
      maxLegalActions: maxLegalActions,
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
    );
  }
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run archive/analysis_legacy_2026_05/tools/llm_agent/run_llm_battle_smoke.dart '
    '--runs 1 --turn-cap 4 --model gemma4:e4b',
  );
  exit(0);
}
