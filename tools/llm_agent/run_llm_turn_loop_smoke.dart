import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../sim/balance_action_executor.dart';
import '../sim/bot_policy.dart';
import '../sim/llm_action_schema.dart';
import '../sim/planner_bot.dart';
import 'llm_policy_guidance.dart';
import 'llm_policy_client.dart';
import 'smoke_session_factory.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final out = File(config.outPath)..parent.createSync(recursive: true);
  final report = File(config.reportOutPath)..parent.createSync(recursive: true);
  final rows = <Map<String, Object?>>[];

  for (var runIndex = 0; runIndex < config.runs; runIndex++) {
    final seed = config.seed + runIndex;
    final llmSession = buildLlmSmokeSession(seed, runIndex);
    final baselineSession = buildLlmSmokeSession(seed, runIndex);
    for (var turn = 0; turn < config.turnCap; turn++) {
      if (_isTerminal(llmSession)) break;
      final requestId = 'llm_loop_${config.seed}_${runIndex}_$turn';
      final request = applyFullRunPolicyGuidance(
        buildLimitedLlmSmokeRequest(
          session: llmSession,
          requestId: requestId,
          index: runIndex,
          turnCount: turn,
          maxLegalActions: config.maxLegalActions * 2,
        ),
        maxActions: config.maxLegalActions,
      );
      final responseResult = await requestLocalLlmAction(
        request: request,
        config: config.clientConfig(
          requestDir: 'logs/llm/turn_loop_requests',
          responseDir: 'logs/llm/turn_loop_responses',
        ),
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
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );
      final selectedAction = validation.balanceAction ?? fallbackAction;
      final llmExecute = executeBalanceAction(llmSession, selectedAction);
      final baselineAction = const FullRunPolicyV1BotPolicy().chooseAction(
        baselineSession,
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
      );
      final baselineExecute = executeBalanceAction(
        baselineSession,
        baselineAction,
      );
      rows.add({
        'schema_version': 1,
        'run_index': runIndex,
        'turn': turn,
        'request_id': requestId,
        'model': config.model,
        'is_valid': validation.isValid,
        'invalid_reason': validation.invalidReason,
        'used_fallback': !validation.isValid,
        'selected_action_id': validation.selectedAction?.id,
        'selected_action_type': validation.selectedAction?.type,
        'executed_action_type': selectedAction.type.name,
        'fallback_action_type': validation.isValid
            ? null
            : fallbackAction.type.name,
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
        'llm_reached_target':
            llmExecute.scoreAfter >= llmSession.blind.targetScore,
        'baseline_reached_target':
            baselineExecute.scoreAfter >= baselineSession.blind.targetScore,
        'llm_score_delta': llmExecute.scoreDelta,
        'baseline_score_delta': baselineExecute.scoreDelta,
        'llm_hand_size_after': llmExecute.handSizeAfter,
        'llm_deck_remaining_after': llmExecute.deckRemainingAfter,
        'llm_board_occupancy_after': llmExecute.boardOccupancyAfter,
        'latency_ms': responseResult.latencyMs,
        'llm_error': responseResult.error,
      });
      if (selectedAction.type == BalanceSimActionType.stop ||
          baselineAction.type == BalanceSimActionType.stop) {
        break;
      }
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

bool _isTerminal(RummiPokerGridSession session) {
  return session.blind.scoreTowardBlind >= session.blind.targetScore;
}

String _buildReport(List<Map<String, Object?>> rows, _Config config) {
  final total = rows.length;
  final valid = rows.where((row) => row['is_valid'] == true).length;
  final fallback = rows.where((row) => row['used_fallback'] == true).length;
  final diverged = rows
      .where((row) => row['diverged_from_baseline'] == true)
      .length;
  final llmExecFail = rows.where((row) => row['llm_execute_ok'] != true).length;
  final baselineExecFail = rows
      .where((row) => row['baseline_execute_ok'] != true)
      .length;
  final finalRows = _lastRowByRun(rows);
  final llmTargetReached = finalRows.values
      .where((row) => (row['llm_reached_target'] as bool?) == true)
      .length;
  final baselineTargetReached = finalRows.values
      .where((row) => (row['baseline_reached_target'] as bool?) == true)
      .length;
  final actionTypes = _countBy(rows, 'executed_action_type');
  final baselineTypes = _countBy(rows, 'baseline_action_type');
  final avgLatency = total == 0
      ? 0.0
      : rows.fold<int>(
              0,
              (sum, row) => sum + ((row['latency_ms'] as num?)?.toInt() ?? 0),
            ) /
            total;
  final finalScoreDelta = finalRows.values.fold<int>(
    0,
    (sum, row) =>
        sum +
        ((row['llm_score_after'] as num?)?.toInt() ?? 0) -
        ((row['baseline_score_after'] as num?)?.toInt() ?? 0),
  );
  return [
    '# LLM Turn Loop Smoke',
    '',
    '## Summary',
    '',
    '- model: ${config.model}',
    '- runs: ${config.runs}',
    '- turn_cap: ${config.turnCap}',
    '- decisions: $total',
    '- valid responses: $valid',
    '- fallback executions: $fallback',
    '- fallback_rate: ${_rate(fallback, total)}',
    '- diverged_from_baseline: $diverged',
    '- divergence_rate: ${_rate(diverged, total)}',
    '- llm_execute_failures: $llmExecFail',
    '- baseline_execute_failures: $baselineExecFail',
    '- avg_latency_ms: ${avgLatency.toStringAsFixed(1)}',
    '- llm_target_reached_runs: $llmTargetReached',
    '- baseline_target_reached_runs: $baselineTargetReached',
    '- final_score_delta_vs_baseline: $finalScoreDelta',
    '',
    '## LLM/Fallback Executed Action Types',
    '',
    for (final entry in actionTypes.entries) '- ${entry.key}: ${entry.value}',
    '',
    '## Baseline Action Types',
    '',
    for (final entry in baselineTypes.entries) '- ${entry.key}: ${entry.value}',
    '',
    '## Scope',
    '',
    'This is a short turn-loop smoke. It validates multi-turn wiring, fallback behavior, and baseline divergence only.',
    'It is not yet a balance recommendation source.',
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
  final int maxLegalActions;
  final String model;
  final double temperature;
  final double topP;
  final int timeoutSeconds;

  LlmPolicyClientConfig clientConfig({
    required String requestDir,
    required String responseDir,
  }) {
    return LlmPolicyClientConfig(
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
      requestDir: requestDir,
      responseDir: responseDir,
    );
  }

  static _Config parse(List<String> args) {
    var outPath = 'logs/llm/turn_loop_smoke_20260529.jsonl';
    var reportOutPath =
        'analysis/leveling/reports/llm_turn_loop_smoke_20260529.md';
    var runs = 2;
    var turnCap = 3;
    var seed = 20260529;
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
    if (maxLegalActions <= 0) {
      throw const FormatException('--max-legal-actions must be positive');
    }
    return _Config(
      outPath: outPath,
      reportOutPath: reportOutPath,
      runs: runs,
      turnCap: turnCap,
      seed: seed,
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
    'Usage: dart run tools/llm_agent/run_llm_turn_loop_smoke.dart '
    '--runs 2 --turn-cap 3 --model gemma4:e4b',
  );
  exit(0);
}
