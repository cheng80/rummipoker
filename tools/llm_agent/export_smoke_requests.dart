import 'dart:convert';
import 'dart:io';

import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../sim/llm_action_schema.dart';
import '../sim/llm_state_exporter.dart';

Future<void> main(List<String> args) async {
  final config = _Config.parse(args);
  final out = File(config.outPath);
  out.parent.createSync(recursive: true);
  final sink = out.openWrite();
  try {
    for (var index = 0; index < config.count; index++) {
      final session = _buildSmokeSession(config.seed + index, index);
      final request = buildLlmActionRequest(
        session,
        requestId: 'llm_smoke_${config.seed}_$index',
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        station: 1 + (index % 4),
        blindTier: switch (index % 3) {
          0 => 'small',
          1 => 'big',
          _ => 'boss',
        },
        turnCount: index * 3,
      );
      sink.writeln(jsonEncode(request.copyWithLegalActionsLimit(32).toJson()));
    }
  } finally {
    await sink.close();
  }
  stdout.writeln('requests: ${out.path}');
  stdout.writeln('count: ${config.count}');
}

extension _LimitedLlmRequest on LlmActionRequest {
  LlmActionRequest copyWithLegalActionsLimit(int maxActions) {
    if (legalActions.length <= maxActions) return this;
    final sorted = List<LlmLegalAction>.from(legalActions)
      ..sort((a, b) {
        final clearCompare = _boolRank(
          b.clearsTarget,
        ).compareTo(_boolRank(a.clearsTarget));
        if (clearCompare != 0) return clearCompare;
        final previewCompare = (b.previewScore ?? -1).compareTo(
          a.previewScore ?? -1,
        );
        if (previewCompare != 0) return previewCompare;
        return _typeRank(a.type).compareTo(_typeRank(b.type));
      });
    return LlmActionRequest(
      requestId: requestId,
      botPolicy: botPolicy,
      state: state,
      legalActions: sorted.take(maxActions).toList(growable: false),
    );
  }
}

int _boolRank(bool? value) => value == true ? 1 : 0;

int _typeRank(String type) => switch (type) {
  'confirm' => 0,
  'place' => 1,
  'draw' => 2,
  'discardBoard' => 3,
  'moveBoard' => 4,
  'discardHand' => 5,
  _ => 6,
};

RummiPokerGridSession _buildSmokeSession(int seed, int index) {
  final session = RummiPokerGridSession(
    runSeed: seed,
    blind: RummiBlindState(
      targetScore: 300 + index * 20,
      scoreTowardBlind: index.isEven ? 0 : 220 + index * 7,
      boardDiscardsRemaining: 2 + (index % 3),
      handDiscardsRemaining: 1 + (index % 2),
      boardMovesRemaining: 1 + (index % 2),
    ),
  );
  session.setDebugMaxHandSize(2);
  session.drawToHand();
  if (index % 2 == 0) {
    session.drawToHand();
  }

  // Build a few deterministic board shapes so the legal action set includes
  // placement, discard, move, and occasional confirm candidates.
  final color = TileColor.values[index % TileColor.values.length];
  final row = index % 5;
  for (var col = 0; col < 3; col++) {
    session.board.setCell(
      row,
      col,
      Tile(color: color, number: col + 3, id: index + col + 1),
    );
  }
  if (index % 3 == 0) {
    session.board.setCell(
      row,
      3,
      Tile(color: color, number: 6, id: index + 20),
    );
    session.board.setCell(
      row,
      4,
      Tile(color: color, number: 7, id: index + 30),
    );
  }
  return session;
}

class _Config {
  const _Config({
    required this.outPath,
    required this.count,
    required this.seed,
  });

  final String outPath;
  final int count;
  final int seed;

  static _Config parse(List<String> args) {
    var outPath = 'logs/llm/requests_smoke.jsonl';
    var count = 10;
    var seed = 20260529;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--out':
          outPath = args[++i];
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
    if (count <= 0) {
      throw const FormatException('--count must be positive');
    }
    return _Config(outPath: outPath, count: count, seed: seed);
  }
}

Never _printUsageAndExit() {
  stdout.writeln(
    'Usage: dart run tools/llm_agent/export_smoke_requests.dart '
    '--out logs/llm/requests_smoke.jsonl [--count 10] [--seed 20260529]',
  );
  exit(0);
}
