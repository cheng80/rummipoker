import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/run_balance_sim.dart';

void main() {
  test(
    'CLI writes deterministic JSONL rows with repeated loadout args',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final firstOut = '${dir.path}/first.jsonl';
      final secondOut = '${dir.path}/second.jsonl';
      final args = [
        '--runs',
        '2',
        '--bot',
        'greedy_v1',
        '--seed',
        '42',
        '--jester',
        'jolly_jester',
        '--jester',
        'zany_jester',
        '--item',
        'slide_wax',
        '--item',
        'move_token',
      ];

      final firstCode = await runBalanceSim([...args, '--out', firstOut]);
      final secondCode = await runBalanceSim([...args, '--out', secondOut]);

      expect(firstCode, 0);
      expect(secondCode, 0);
      expect(
        File(firstOut).readAsStringSync(),
        File(secondOut).readAsStringSync(),
      );

      final rows = File(firstOut)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      expect(rows, hasLength(2));
      expect(rows.first['schema_version'], 1);
      expect(rows.first['bot_policy'], 'greedy_v1');
      expect(rows.first['balance_version'], 'v4_pacing_baseline_1');
      expect(rows.first['ruleset_id'], 'current_defaults_v1');
      expect(rows.first['is_debug_run'], false);
      expect(rows.first['is_fixture'], false);
      expect(rows.first['blind_tier'], 'small');
      expect(rows.first['target_score'], isA<int>());

      final startState = rows.first['start_state'] as Map<String, dynamic>;
      expect(startState['jester_ids'], ['jolly_jester', 'zany_jester']);
      expect(startState['item_ids'], ['slide_wax', 'move_token']);
      expect(startState['gold'], 10);
      expect(startState['board_discards'], isA<int>());
      expect(startState['hand_discards'], isA<int>());
      expect(startState['board_moves'], isA<int>());
      expect(startState['deck_size'], 52);

      final result = rows.first['result'] as Map<String, dynamic>;
      expect(result['cleared'], isA<bool>());
      expect(result['final_score'], isA<int>());
      expect(result['score_ratio'], isA<num>());
      expect(result['turn_count'], isA<int>());
    },
  );

  test('CLI rejects unknown bot and missing output path', () async {
    final unknownBotCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'unknown_bot',
      '--seed',
      '42',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final missingOutCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
    ]);

    expect(unknownBotCode, 64);
    expect(missingOutCode, 64);
  });
}
