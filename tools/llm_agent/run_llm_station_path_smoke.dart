import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_ruleset.dart';
import 'package:rummipoker/services/blind_selection_spec.dart';
import 'package:rummipoker/services/new_run_setup.dart';

import '../sim/balance_action_executor.dart';
import '../sim/bot_policy.dart';
import '../sim/llm_action_schema.dart';
import '../sim/llm_state_exporter.dart';
import '../sim/planner_bot.dart';
import 'llm_policy_client.dart';
import 'llm_policy_guidance.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final out = File(config.outPath)..parent.createSync(recursive: true);
  final report = File(config.reportOutPath)..parent.createSync(recursive: true);
  final rows = <Map<String, Object?>>[];

  for (var runIndex = 0; runIndex < config.runs; runIndex++) {
    final seed = config.seed + runIndex;
    final llmSession = RummiPokerGridSession(runSeed: seed);
    final baselineSession = RummiPokerGridSession(runSeed: seed);
    final runProgress = RummiRunProgress();
    final baselineProgress = RummiRunProgress();

    var pathStopped = false;
    for (
      var station = config.stationStart;
      station <= config.stationEnd;
      station++
    ) {
      if (pathStopped) break;
      for (final tier in config.tiers) {
        final spec = BlindSelectionSpecBuilder.resolveSpec(
          tier: tier,
          stationIndex: station,
          difficulty: config.difficulty,
          runModifier: NewRunModifier.basic,
          runSeed: seed,
          ruleset: RummiRuleset.currentDefaults,
        );
        _startBlind(runProgress, llmSession, spec, station, seed);
        _startBlind(baselineProgress, baselineSession, spec, station, seed);
        llmSession.blind.bossModifier = spec.bossModifier;
        baselineSession.blind.bossModifier = spec.bossModifier;

        final blindRows = await _runBlind(
          config: config,
          rows: rows,
          runIndex: runIndex,
          seed: seed,
          station: station,
          tier: tier,
          spec: spec,
          llmSession: llmSession,
          baselineSession: baselineSession,
          runProgress: runProgress,
          baselineProgress: baselineProgress,
        );
        if (!blindRows.cleared) {
          pathStopped = true;
          break;
        }
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

Future<({bool cleared})> _runBlind({
  required _Config config,
  required List<Map<String, Object?>> rows,
  required int runIndex,
  required int seed,
  required int station,
  required BlindTier tier,
  required BlindSelectionSpec spec,
  required RummiPokerGridSession llmSession,
  required RummiPokerGridSession baselineSession,
  required RummiRunProgress runProgress,
  required RummiRunProgress baselineProgress,
}) async {
  for (var turn = 0; turn < config.turnCapPerBlind; turn++) {
    final expiry = llmSession.evaluateExpirySignals();
    if (llmSession.blind.isTargetMet || expiry.isNotEmpty) {
      rows.add(
        _terminalRow(
          config: config,
          runIndex: runIndex,
          station: station,
          tier: tier,
          turn: turn,
          spec: spec,
          llmSession: llmSession,
          baselineSession: baselineSession,
          stopReason: llmSession.blind.isTargetMet
              ? 'cleared'
              : expiry.map((signal) => signal.name).join(','),
        ),
      );
      return (cleared: llmSession.blind.isTargetMet);
    }

    final requestId =
        'llm_path_${config.seed}_${runIndex}_s${station}_${tier.name}_$turn';
    final request = applyFullRunPolicyGuidance(
      buildLlmActionRequest(
        llmSession,
        requestId: requestId,
        jesters: const [],
        runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
        station: station,
        blindTier: tier.name,
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
    final fallbackAction = const ContestPolicyV1BotPolicy().chooseAction(
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
    final baselineAction = const ContestPolicyV1BotPolicy().chooseAction(
      baselineSession,
      jesters: const [],
      runtimeSnapshot: baselineProgress.buildRuntimeSnapshot(),
    );
    final baselineExecute = executeBalanceAction(
      baselineSession,
      baselineAction,
      runtimeSnapshot: baselineProgress.buildRuntimeSnapshot(),
    );

    rows.add({
      'schema_version': 1,
      'row_type': 'llm_station_path_turn',
      'run_index': runIndex,
      'seed': seed,
      'station': station,
      'blind_tier': tier.name,
      'turn': turn,
      'target_score': spec.targetScore,
      'boss_modifier_id': spec.bossModifier?.id,
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
      'llm_board_occupancy_after': llmExecute.boardOccupancyAfter,
      'llm_hand_size_after': llmExecute.handSizeAfter,
      'llm_deck_remaining_after': llmExecute.deckRemainingAfter,
      'latency_ms': responseResult.latencyMs,
      'llm_error': responseResult.error,
    });
    if (selectedAction.type == BalanceSimActionType.stop) {
      return (cleared: false);
    }
  }

  rows.add(
    _terminalRow(
      config: config,
      runIndex: runIndex,
      station: station,
      tier: tier,
      turn: config.turnCapPerBlind,
      spec: spec,
      llmSession: llmSession,
      baselineSession: baselineSession,
      stopReason: 'turn_cap',
    ),
  );
  return (cleared: llmSession.blind.isTargetMet);
}

void _startBlind(
  RummiRunProgress runProgress,
  RummiPokerGridSession session,
  BlindSelectionSpec spec,
  int station,
  int seed,
) {
  runProgress.startBlind(
    session,
    stationIndex: station,
    blindTierIndex: spec.tier.index,
    shuffleSeed: _deriveBlindShuffleSeed(
      runSeed: seed,
      stationIndex: station,
      blindTierIndex: spec.tier.index,
    ),
    targetScore: spec.targetScore,
    boardDiscards: spec.boardDiscards,
    handDiscards: spec.handDiscards,
    maxHandSize: spec.maxHandSize,
    applyRoundEndDecay: false,
  );
}

int _deriveBlindShuffleSeed({
  required int runSeed,
  required int stationIndex,
  required int blindTierIndex,
}) {
  final stageSeed = runSeed * 1103515245 + 12345 + stationIndex * 1013904223;
  final mixed = (stageSeed + (blindTierIndex + 1) * 2654435761) & 0x7fffffff;
  return mixed == 0 ? stationIndex + blindTierIndex + 1 : mixed;
}

Map<String, Object?> _terminalRow({
  required _Config config,
  required int runIndex,
  required int station,
  required BlindTier tier,
  required int turn,
  required BlindSelectionSpec spec,
  required RummiPokerGridSession llmSession,
  required RummiPokerGridSession baselineSession,
  required String stopReason,
}) {
  return {
    'schema_version': 1,
    'row_type': 'llm_station_path_terminal',
    'run_index': runIndex,
    'station': station,
    'blind_tier': tier.name,
    'turn': turn,
    'target_score': spec.targetScore,
    'boss_modifier_id': spec.bossModifier?.id,
    'stop_reason': stopReason,
    'llm_score_after': llmSession.blind.scoreTowardBlind,
    'baseline_score_after': baselineSession.blind.scoreTowardBlind,
    'llm_reached_target': llmSession.blind.isTargetMet,
    'baseline_reached_target': baselineSession.blind.isTargetMet,
  };
}

String _buildReport(List<Map<String, Object?>> rows, _Config config) {
  final decisions = rows
      .where((row) => row['row_type'] == 'llm_station_path_turn')
      .toList(growable: false);
  final terminals = rows
      .where((row) => row['row_type'] == 'llm_station_path_terminal')
      .toList(growable: false);
  final valid = decisions.where((row) => row['is_valid'] == true).length;
  final fallback = decisions
      .where((row) => row['used_fallback'] == true)
      .length;
  final diverged = decisions
      .where((row) => row['diverged_from_baseline'] == true)
      .length;
  final cleared = terminals
      .where((row) => row['llm_reached_target'] == true)
      .length;
  final avgLatency = decisions.isEmpty
      ? 0.0
      : decisions.fold<int>(
              0,
              (sum, row) => sum + ((row['latency_ms'] as num?)?.toInt() ?? 0),
            ) /
            decisions.length;
  return [
    '# LLM Station Path Smoke',
    '',
    '## Summary',
    '',
    '- model: ${config.model}',
    '- runs: ${config.runs}',
    '- station_range: S${config.stationStart}~S${config.stationEnd}',
    '- tiers: ${config.tiers.map((tier) => tier.name).join(', ')}',
    '- turn_cap_per_blind: ${config.turnCapPerBlind}',
    '- decisions: ${decisions.length}',
    '- terminal_blinds: ${terminals.length}',
    '- cleared_blinds: $cleared',
    '- valid responses: $valid',
    '- fallback executions: $fallback',
    '- fallback_rate: ${_rate(fallback, decisions.length)}',
    '- diverged_from_baseline: $diverged',
    '- divergence_rate: ${_rate(diverged, decisions.length)}',
    '- avg_latency_ms: ${avgLatency.toStringAsFixed(1)}',
    '',
    '## Action Types',
    '',
    for (final entry in _countBy(decisions, 'executed_action_type').entries)
      '- ${entry.key}: ${entry.value}',
    '',
    '## Scope',
    '',
    'This is the first S1-S8-capable LLM station path runner.',
    'It uses real blind specs, target scores, resources, and boss modifiers.',
    'Market buy/sell/reroll and item-use choices are still pending before this can be treated as full balance evidence.',
  ].join('\n');
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
    required this.seed,
    required this.stationStart,
    required this.stationEnd,
    required this.tiers,
    required this.turnCapPerBlind,
    required this.maxLegalActions,
    required this.difficulty,
    required this.model,
    required this.temperature,
    required this.topP,
    required this.timeoutSeconds,
  });

  final String outPath;
  final String reportOutPath;
  final int runs;
  final int seed;
  final int stationStart;
  final int stationEnd;
  final List<BlindTier> tiers;
  final int turnCapPerBlind;
  final int maxLegalActions;
  final NewRunDifficulty difficulty;
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
      requestDir: 'logs/llm/station_path_requests',
      responseDir: 'logs/llm/station_path_responses',
    );
  }

  static _Config parse(List<String> args) {
    var outPath = 'logs/llm/station_path_smoke_20260529.jsonl';
    var reportOutPath =
        'analysis/leveling/reports/llm_station_path_smoke_20260529.md';
    var runs = 1;
    var seed = 20260529;
    var stationStart = 1;
    var stationEnd = 8;
    var tiers = const [BlindTier.small, BlindTier.big, BlindTier.boss];
    var turnCapPerBlind = 4;
    var maxLegalActions = 24;
    var difficulty = NewRunDifficulty.standard;
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
        case '--seed':
          seed = int.parse(args[++i]);
        case '--station-start':
          stationStart = int.parse(args[++i]);
        case '--station-end':
          stationEnd = int.parse(args[++i]);
        case '--tiers':
          tiers = _parseTiers(args[++i]);
        case '--turn-cap-per-blind':
          turnCapPerBlind = int.parse(args[++i]);
        case '--max-legal-actions':
          maxLegalActions = int.parse(args[++i]);
        case '--difficulty':
          difficulty = _parseDifficulty(args[++i]);
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
    if (stationStart <= 0 || stationEnd < stationStart) {
      throw const FormatException('station range must be positive and ordered');
    }
    if (turnCapPerBlind <= 0) {
      throw const FormatException('--turn-cap-per-blind must be positive');
    }
    return _Config(
      outPath: outPath,
      reportOutPath: reportOutPath,
      runs: runs,
      seed: seed,
      stationStart: stationStart,
      stationEnd: stationEnd,
      tiers: tiers,
      turnCapPerBlind: turnCapPerBlind,
      maxLegalActions: maxLegalActions,
      difficulty: difficulty,
      model: model,
      temperature: temperature,
      topP: topP,
      timeoutSeconds: timeoutSeconds,
    );
  }
}

List<BlindTier> _parseTiers(String raw) {
  final tiers = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .map(BlindSelectionSpecBuilder.parseTier)
      .toList(growable: false);
  if (tiers.isEmpty) throw const FormatException('--tiers cannot be empty');
  return tiers;
}

NewRunDifficulty _parseDifficulty(String raw) {
  return switch (raw) {
    'relaxed' => NewRunDifficulty.relaxed,
    'challenge' => NewRunDifficulty.challenge,
    _ => NewRunDifficulty.standard,
  };
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run tools/llm_agent/run_llm_station_path_smoke.dart '
    '--station-start 1 --station-end 8 --tiers small,big,boss '
    '--turn-cap-per-blind 4',
  );
  exit(0);
}
