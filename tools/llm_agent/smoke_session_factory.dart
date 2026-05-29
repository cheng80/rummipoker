import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../sim/llm_action_schema.dart';
import '../sim/llm_state_exporter.dart';

RummiPokerGridSession buildLlmSmokeSession(int seed, int index) {
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
  if (index.isEven) {
    session.drawToHand();
  }

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

LlmActionRequest buildLimitedLlmSmokeRequest({
  required RummiPokerGridSession session,
  required String requestId,
  required int index,
  int? turnCount,
  int maxLegalActions = 32,
}) {
  final request = buildLlmActionRequest(
    session,
    requestId: requestId,
    jesters: const [],
    runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    station: 1 + (index % 4),
    blindTier: switch (index % 3) {
      0 => 'small',
      1 => 'big',
      _ => 'boss',
    },
    turnCount: turnCount ?? index * 3,
  );
  return limitLlmActionRequest(request, maxLegalActions);
}

LlmActionRequest limitLlmActionRequest(
  LlmActionRequest request,
  int maxActions,
) {
  if (request.legalActions.length <= maxActions) return request;
  final sorted = List<LlmLegalAction>.from(request.legalActions)
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
    requestId: request.requestId,
    botPolicy: request.botPolicy,
    state: request.state,
    legalActions: sorted.take(maxActions).toList(growable: false),
  );
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
