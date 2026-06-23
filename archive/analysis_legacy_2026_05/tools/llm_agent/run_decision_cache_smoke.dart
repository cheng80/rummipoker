import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';

import '../../../../tools/sim/balance_action_executor.dart';
import '../../../../tools/sim/llm_action_schema.dart';
import '../../../../tools/sim/planner_bot.dart';
import 'smoke_session_factory.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final responses = _readJsonl(config.responsesPath);
  final responseById = {
    for (final response in responses)
      response['request_id'] as String: response,
  };
  final out = File(config.outPath)..parent.createSync(recursive: true);
  final rows = <Map<String, Object?>>[];

  for (var index = 0; index < config.count; index++) {
    final requestId = 'llm_smoke_${config.seed}_$index';
    final session = buildLlmSmokeSession(config.seed + index, index);
    final request = buildLimitedLlmSmokeRequest(
      session: session,
      requestId: requestId,
      index: index,
    );
    final scoreBefore = session.blind.scoreTowardBlind;
    final responseJson = responseById[requestId];
    final validation = responseJson == null
        ? LlmActionValidationResult.invalid('missing_response')
        : validateLlmActionResponse(
            response: LlmActionResponse.fromJson(responseJson),
            legalActions: request.legalActions,
          );
    final fallbackAction = const FullRunPolicyV1BotPolicy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );
    final selectedAction = validation.balanceAction ?? fallbackAction;
    final execute = executeBalanceAction(session, selectedAction);
    rows.add({
      'schema_version': 1,
      'request_id': requestId,
      'model': responseJson?['model'],
      'is_valid': validation.isValid,
      'invalid_reason': validation.invalidReason,
      'used_fallback': !validation.isValid,
      'selected_action_id': validation.selectedAction?.id,
      'selected_action_type': validation.selectedAction?.type,
      'executed_action_type': selectedAction.type.name,
      'fallback_action_type': validation.isValid
          ? null
          : fallbackAction.type.name,
      'execute_ok': execute.ok,
      'execute_reason': execute.reason,
      'score_before': scoreBefore,
      'score_after': execute.scoreAfter,
      'score_delta': execute.scoreDelta,
      'hand_size_after': execute.handSizeAfter,
      'deck_remaining_after': execute.deckRemainingAfter,
      'board_occupancy_after': execute.boardOccupancyAfter,
    });
  }

  final sink = out.openWrite();
  try {
    for (final row in rows) {
      sink.writeln(jsonEncode(row));
    }
  } finally {
    await sink.close();
  }

  final report = File(config.reportOutPath)..parent.createSync(recursive: true);
  report.writeAsStringSync(_buildReport(rows));
  stdout.writeln('out: ${out.path}');
  stdout.writeln('report: ${report.path}');
}

String _buildReport(List<Map<String, Object?>> rows) {
  final total = rows.length;
  final valid = rows.where((row) => row['is_valid'] == true).length;
  final fallback = rows.where((row) => row['used_fallback'] == true).length;
  final executed = <String, int>{};
  for (final row in rows) {
    final type = row['executed_action_type'] as String? ?? 'unknown';
    executed[type] = (executed[type] ?? 0) + 1;
  }
  return [
    '# LLM Decision Cache One-Step Smoke',
    '',
    '## Summary',
    '',
    '- requests: $total',
    '- valid responses: $valid',
    '- fallback executions: $fallback',
    '- fallback_rate: ${total == 0 ? '0.0000' : (fallback / total).toStringAsFixed(4)}',
    '',
    '## Executed Action Types',
    '',
    for (final entry in executed.entries) '- ${entry.key}: ${entry.value}',
    '',
    '## Scope',
    '',
    'This is a one-step decision-cache execution smoke, not a full autoplay run.',
  ].join('\n');
}

List<Map<String, dynamic>> _readJsonl(String path) {
  return File(path)
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .toList(growable: false);
}

class _Config {
  const _Config({
    required this.responsesPath,
    required this.outPath,
    required this.reportOutPath,
    required this.count,
    required this.seed,
  });

  final String responsesPath;
  final String outPath;
  final String reportOutPath;
  final int count;
  final int seed;

  static _Config parse(List<String> args) {
    var responsesPath = 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/responses_smoke_20260529_schema.jsonl';
    var outPath = 'archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/decision_cache_one_step_20260529.jsonl';
    var reportOutPath =
        'archive/analysis_legacy_2026_05/analysis/leveling/reports/llm_decision_cache_one_step_20260529.md';
    var count = 10;
    var seed = 20260529;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--responses':
          responsesPath = args[++i];
        case '--out':
          outPath = args[++i];
        case '--report-out':
          reportOutPath = args[++i];
        case '--count':
          count = int.parse(args[++i]);
        case '--seed':
          seed = int.parse(args[++i]);
        case '--help':
          _printUsageAndExit();
        default:
          throw FormatException('Unknown arg: ${args[i]}');
      }
    }
    return _Config(
      responsesPath: responsesPath,
      outPath: outPath,
      reportOutPath: reportOutPath,
      count: count,
      seed: seed,
    );
  }
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run archive/analysis_legacy_2026_05/tools/llm_agent/run_decision_cache_smoke.dart '
    '--responses archive/analysis_legacy_2026_05/local_ignored_generated/logs/llm/responses_smoke_20260529_schema.jsonl',
  );
  exit(0);
}
