import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../sim/bot_policy.dart';
import '../sim/llm_action_schema.dart';
import '../sim/planner_bot.dart';
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
    final fallbackAction = const ContestPolicyV1BotPolicy().chooseAction(
      session,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );
    final selectedAction = validation.balanceAction ?? fallbackAction;
    final execute = _executeOneStep(session, selectedAction);
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
      'score_after': session.blind.scoreTowardBlind,
      'score_delta': session.blind.scoreTowardBlind - scoreBefore,
      'hand_size_after': session.hand.length,
      'deck_remaining_after': session.deck.remaining,
      'board_occupancy_after': RummiPokerGridSession.countTilesOnBoard(
        session.board,
      ),
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

({bool ok, String reason}) _executeOneStep(
  RummiPokerGridSession session,
  BalanceSimAction action,
) {
  switch (action.type) {
    case BalanceSimActionType.draw:
      return (ok: session.drawToHand() != null, reason: 'draw');
    case BalanceSimActionType.place:
      final handIndex = action.handIndex;
      final row = action.row;
      final col = action.col;
      if (handIndex == null ||
          row == null ||
          col == null ||
          handIndex < 0 ||
          handIndex >= session.hand.length) {
        return (ok: false, reason: 'invalid_place_action');
      }
      final tile = session.hand[handIndex];
      return (ok: session.tryPlaceFromHand(tile, row, col), reason: 'place');
    case BalanceSimActionType.confirm:
      final out = session.confirmAllFullLines();
      return (ok: out.result.ok, reason: 'confirm');
    case BalanceSimActionType.discardHand:
      final handIndex = action.handIndex;
      if (handIndex == null ||
          handIndex < 0 ||
          handIndex >= session.hand.length) {
        return (ok: false, reason: 'invalid_discard_hand_action');
      }
      final discard = session.tryDiscardFromHand(session.hand[handIndex]);
      return (ok: discard.fail == null, reason: 'discardHand');
    case BalanceSimActionType.discardBoard:
      final row = action.row;
      final col = action.col;
      if (row == null || col == null) {
        return (ok: false, reason: 'invalid_discard_board_action');
      }
      final discard = session.tryDiscardFromBoard(row, col);
      return (ok: discard.fail == null, reason: 'discardBoard');
    case BalanceSimActionType.moveBoard:
      final row = action.row;
      final col = action.col;
      final toRow = action.toRow;
      final toCol = action.toCol;
      if (row == null || col == null || toRow == null || toCol == null) {
        return (ok: false, reason: 'invalid_move_board_action');
      }
      final fail = session.tryMoveBoardTile(
        fromRow: row,
        fromCol: col,
        toRow: toRow,
        toCol: toCol,
      );
      return (ok: fail == null, reason: fail?.name ?? 'moveBoard');
    case BalanceSimActionType.stop:
      return (ok: true, reason: action.reason ?? 'stop');
  }
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
    var responsesPath = 'logs/llm/responses_smoke_20260529_schema.jsonl';
    var outPath = 'logs/llm/decision_cache_one_step_20260529.jsonl';
    var reportOutPath =
        'analysis/leveling/reports/llm_decision_cache_one_step_20260529.md';
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
    'Usage: dart run tools/llm_agent/run_decision_cache_smoke.dart '
    '--responses logs/llm/responses_smoke_20260529_schema.jsonl',
  );
  exit(0);
}
