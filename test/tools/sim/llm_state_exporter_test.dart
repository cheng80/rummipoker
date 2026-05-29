import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/models/tile.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_blind_state.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../../../tools/sim/llm_action_schema.dart';
import '../../../tools/sim/llm_state_exporter.dart';

void main() {
  test(
    'buildLlmActionRequest exports state and deterministic legal actions',
    () {
      final session = RummiPokerGridSession(
        runSeed: 42,
        blind: RummiBlindState(targetScore: 300),
      );
      final drew = session.drawToHand();
      expect(drew, isNotNull);
      session.setDebugMaxHandSize(2);

      final request = buildLlmActionRequest(
        session,
        requestId: 'req_1',
        jesters: const [],
        runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
        station: 1,
        blindTier: 'small',
        turnCount: 3,
      );

      final json = request.toJson();
      expect(json['schema_version'], kLlmActionSchemaVersion);
      expect(json['request_id'], 'req_1');
      expect((json['state'] as Map<String, dynamic>)['station'], 1);
      expect((json['state'] as Map<String, dynamic>)['deck_remaining'], 51);
      expect(
        request.legalActions.map((action) => action.id),
        contains('draw_deck'),
      );
      expect(
        request.legalActions.map((action) => action.id),
        contains('place_h0_r0_c0'),
      );
    },
  );

  test('validateLlmActionResponse accepts only listed action ids', () {
    final session = RummiPokerGridSession(
      runSeed: 7,
      blind: RummiBlindState(targetScore: 300),
    );
    session.drawToHand();
    final request = buildLlmActionRequest(
      session,
      requestId: 'req_2',
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );

    final valid = validateLlmActionResponse(
      response: LlmActionResponse.fromJson({
        'schema_version': kLlmActionSchemaVersion,
        'status': 'ok',
        'selected_action_id': 'place_h0_r0_c0',
        'confidence': 0.7,
        'reason': 'best available opening',
      }),
      legalActions: request.legalActions,
    );
    expect(valid.isValid, isTrue);
    expect(valid.selectedAction?.type, 'place');
    expect(valid.confidence, 0.7);

    final invalid = validateLlmActionResponse(
      response: LlmActionResponse.fromJson({
        'schema_version': kLlmActionSchemaVersion,
        'status': 'ok',
        'selected_action_id': 'place_h9_r9_c9',
      }),
      legalActions: request.legalActions,
    );
    expect(invalid.isValid, isFalse);
    expect(invalid.invalidReason, 'unknown_action_id');
  });

  test('tile modifiers are preserved in LLM state export', () {
    final session = RummiPokerGridSession(
      runSeed: 11,
      blind: RummiBlindState(targetScore: 300),
    );
    session.hand.add(
      const Tile(
        color: TileColor.red,
        number: 8,
        enhancement: TileEnhancement.chipInlaid,
        seal: TileSeal.blueSeal,
        edition: TileEdition.glowEdition,
      ),
    );

    final state = exportLlmState(
      session,
      botPolicy: kLlmGemmaPolicyId,
      jesters: const [],
      runtimeSnapshot: const RummiJesterRuntimeSnapshot(),
    );
    final hand = state['hand'] as List<dynamic>;
    final first = hand.first as Map<String, dynamic>;
    expect(first['code'], 'R8');
    expect(first['enhancement'], 'chip_inlaid');
    expect(first['seal'], 'blue_seal');
    expect(first['edition'], 'glow_edition');
  });
}
