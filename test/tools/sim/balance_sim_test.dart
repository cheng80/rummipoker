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
      _expectBalanceSimRowContract(rows.first);
      expect(rows.first['bot_policy'], 'greedy_v1');
      expect(rows.first['balance_version'], 'v4_pacing_baseline_1');
      expect(rows.first['loadout_id'], 'manual');
      expect(rows.first['matrix_index'], 0);
      expect(rows.first['matrix_size'], 1);
      expect(rows.first['difficulty'], 'standard');
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
      expect(result['stop_reason'], isA<String>());
      expect(result['outcome_label'], isA<String>());
      expect(result['remaining_deck'], isA<int>());
      expect(result['remaining_hand_size'], isA<int>());
      expect(result['remaining_board_discards'], isA<int>());
      expect(result['remaining_hand_discards'], isA<int>());
      expect(result['remaining_board_moves'], isA<int>());
      expect(result['board_occupancy'], isA<int>());
      expect(result['confirm_action_count'], isA<int>());
      expect(result['confirmed_line_count'], isA<int>());
      expect(result['discarded_board_count'], isA<int>());
      expect(result['draw_count'], isA<int>());
      expect(result['place_count'], isA<int>());
      expect(result['max_single_confirm_score'], isA<int>());
      expect(result['first_score_turn'], anyOf(isNull, isA<int>()));
      expect(result['last_score_turn'], anyOf(isNull, isA<int>()));
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

  test('CLI accepts planner bot and repeats deterministically', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final greedyOut = '${dir.path}/greedy.jsonl';
    final firstPlannerOut = '${dir.path}/planner_first.jsonl';
    final secondPlannerOut = '${dir.path}/planner_second.jsonl';
    final baseArgs = ['--runs', '1', '--seed', '42'];

    final greedyCode = await runBalanceSim([
      ...baseArgs,
      '--bot',
      'greedy_v1',
      '--out',
      greedyOut,
    ]);
    final firstPlannerCode = await runBalanceSim([
      ...baseArgs,
      '--bot',
      'planner_v1',
      '--out',
      firstPlannerOut,
    ]);
    final secondPlannerCode = await runBalanceSim([
      ...baseArgs,
      '--bot',
      'planner_v1',
      '--out',
      secondPlannerOut,
    ]);

    expect(greedyCode, 0);
    expect(firstPlannerCode, 0);
    expect(secondPlannerCode, 0);
    expect(
      File(firstPlannerOut).readAsStringSync(),
      File(secondPlannerOut).readAsStringSync(),
    );

    final greedyRow =
        jsonDecode(File(greedyOut).readAsStringSync()) as Map<String, dynamic>;
    final plannerRow =
        jsonDecode(File(firstPlannerOut).readAsStringSync())
            as Map<String, dynamic>;
    final plannerStartState = plannerRow['start_state'] as Map<String, dynamic>;
    final greedyResult = greedyRow['result'] as Map<String, dynamic>;
    final plannerResult = plannerRow['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(greedyRow);
    _expectBalanceSimRowContract(plannerRow);
    expect(greedyRow['bot_policy'], 'greedy_v1');
    expect(plannerRow['bot_policy'], 'planner_v1');
    expect(plannerResult['cleared'], isTrue);
    expect(plannerResult['stop_reason'], 'cleared');
    expect(plannerResult['confirm_action_count'], greaterThan(0));
    expect(plannerResult['discarded_board_count'], 0);
    expect(
      plannerResult['remaining_board_discards'],
      plannerStartState['board_discards'],
    );
    expect(
      plannerResult['discarded_board_count'] as int,
      lessThan(greedyResult['discarded_board_count'] as int),
    );
  });

  test('CLI records loadout feature summary for ML grouping', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/loadout_summary.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--jester',
      'jolly_jester',
      '--jester',
      'zany_jester',
      '--item',
      'move_token',
      '--item',
      'slide_wax',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final summary = row['loadout_summary'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(row['loadout_id'], 'manual');
    expect(summary['jester_count'], 2);
    expect(summary['item_count'], 2);
    expect(summary['jester_rarity_counts'], {'common': 2});
    expect(summary['jester_effect_type_counts'], {'mult_bonus': 2});
    expect(summary['jester_trigger_counts'], {'onScore': 2});
    expect(summary['jester_condition_type_counts'], {
      'pair': 1,
      'three_of_a_kind': 1,
    });
    expect(summary['item_type_counts'], {'consumable': 2});
    expect(summary['item_rarity_counts'], {'common': 1, 'uncommon': 1});
    expect(summary['item_placement_counts'], {'quickSlot': 2});
    expect(summary['item_effect_timing_counts'], {'use_battle': 2});
    expect(summary['item_effect_op_counts'], {
      'add_board_move': 1,
      'mark_next_board_move_bonus': 1,
    });
    expect(summary['item_tag_counts'], {
      'battle': 2,
      'move': 2,
      'safety': 1,
      'trigger': 1,
    });
  });

  test('CLI records baseline loadout id for empty direct loadout', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/baseline_loadout.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final startState = row['start_state'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(row['loadout_id'], 'baseline');
    expect(row['matrix_index'], 0);
    expect(row['matrix_size'], 1);
    expect(startState['jester_ids'], isEmpty);
    expect(startState['item_ids'], isEmpty);
  });

  test('CLI accepts station and boss blind tier args', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/boss.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '2',
      '--blind-tier',
      'boss',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final startState = row['start_state'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(row['station'], 2);
    expect(row['blind_tier'], 'boss');
    expect(row['boss_modifier_id'], 'red_dampener_v1');
    expect(row['boss_modifier_category'], 'tileColorWeaken');
    expect(row['target_score'], greaterThan(270));
    expect(startState['hand_discards'], 1);
  });

  test('CLI boss tier changes target and applies runtime modifier', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final smallOut = '${dir.path}/small.jsonl';
    final bossOut = '${dir.path}/boss.jsonl';

    final baseArgs = [
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '2',
    ];
    final smallCode = await runBalanceSim([
      ...baseArgs,
      '--blind-tier',
      'small',
      '--out',
      smallOut,
    ]);
    final bossCode = await runBalanceSim([
      ...baseArgs,
      '--blind-tier',
      'boss',
      '--out',
      bossOut,
    ]);

    expect(smallCode, 0);
    expect(bossCode, 0);

    final smallRow =
        jsonDecode(File(smallOut).readAsStringSync()) as Map<String, dynamic>;
    final bossRow =
        jsonDecode(File(bossOut).readAsStringSync()) as Map<String, dynamic>;
    final smallResult = smallRow['result'] as Map<String, dynamic>;
    final bossResult = bossRow['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(smallRow);
    _expectBalanceSimRowContract(bossRow);
    expect(smallRow['boss_modifier_id'], isNull);
    expect(bossRow['boss_modifier_id'], 'red_dampener_v1');
    expect(bossRow['target_score'], greaterThan(smallRow['target_score']));
    expect(bossResult['final_score'], lessThan(smallResult['final_score']));
    expect(bossResult['score_ratio'], lessThan(smallResult['score_ratio']));
  });

  test('CLI logs boss modifier fields only for boss tier', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final smallOut = '${dir.path}/small.jsonl';
    final bigOut = '${dir.path}/big.jsonl';
    final bossOut = '${dir.path}/boss.jsonl';

    final baseArgs = [
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '2',
    ];
    final smallCode = await runBalanceSim([
      ...baseArgs,
      '--blind-tier',
      'small',
      '--out',
      smallOut,
    ]);
    final bigCode = await runBalanceSim([
      ...baseArgs,
      '--blind-tier',
      'big',
      '--out',
      bigOut,
    ]);
    final bossCode = await runBalanceSim([
      ...baseArgs,
      '--blind-tier',
      'boss',
      '--out',
      bossOut,
    ]);

    expect(smallCode, 0);
    expect(bigCode, 0);
    expect(bossCode, 0);

    final smallRow =
        jsonDecode(File(smallOut).readAsStringSync()) as Map<String, dynamic>;
    final bigRow =
        jsonDecode(File(bigOut).readAsStringSync()) as Map<String, dynamic>;
    final bossRow =
        jsonDecode(File(bossOut).readAsStringSync()) as Map<String, dynamic>;

    _expectBalanceSimRowContract(smallRow);
    _expectBalanceSimRowContract(bigRow);
    _expectBalanceSimRowContract(bossRow);
    expect(smallRow['boss_modifier_id'], isNull);
    expect(smallRow['boss_modifier_category'], isNull);
    expect(bigRow['boss_modifier_id'], isNull);
    expect(bigRow['boss_modifier_category'], isNull);
    expect(bossRow['boss_modifier_id'], 'red_dampener_v1');
    expect(bossRow['boss_modifier_category'], 'tileColorWeaken');
  });

  test('CLI accepts difficulty args and records them in JSONL', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final relaxedOut = '${dir.path}/relaxed.jsonl';
    final standardOut = '${dir.path}/standard.jsonl';
    final pressureOut = '${dir.path}/pressure.jsonl';

    final baseArgs = [
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '1',
      '--blind-tier',
      'small',
    ];
    final relaxedCode = await runBalanceSim([
      ...baseArgs,
      '--difficulty',
      'relaxed',
      '--out',
      relaxedOut,
    ]);
    final standardCode = await runBalanceSim([
      ...baseArgs,
      '--difficulty',
      'standard',
      '--out',
      standardOut,
    ]);
    final pressureCode = await runBalanceSim([
      ...baseArgs,
      '--difficulty',
      'pressure',
      '--out',
      pressureOut,
    ]);

    expect(relaxedCode, 0);
    expect(standardCode, 0);
    expect(pressureCode, 0);

    final relaxedRow =
        jsonDecode(File(relaxedOut).readAsStringSync()) as Map<String, dynamic>;
    final standardRow =
        jsonDecode(File(standardOut).readAsStringSync())
            as Map<String, dynamic>;
    final pressureRow =
        jsonDecode(File(pressureOut).readAsStringSync())
            as Map<String, dynamic>;
    final relaxedStartState = relaxedRow['start_state'] as Map<String, dynamic>;
    final standardStartState =
        standardRow['start_state'] as Map<String, dynamic>;
    final pressureStartState =
        pressureRow['start_state'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(relaxedRow);
    _expectBalanceSimRowContract(standardRow);
    _expectBalanceSimRowContract(pressureRow);
    expect(relaxedRow['difficulty'], 'relaxed');
    expect(standardRow['difficulty'], 'standard');
    expect(pressureRow['difficulty'], 'pressure');
    expect(relaxedRow['target_score'], lessThan(standardRow['target_score']));
    expect(
      pressureRow['target_score'],
      greaterThan(standardRow['target_score']),
    );
    expect(relaxedStartState['board_discards'], 5);
    expect(standardStartState['board_discards'], 4);
    expect(pressureStartState['board_discards'], 3);
  });

  test('CLI expands station tier difficulty matrix args', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/matrix.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,boss',
      '--difficulties',
      'relaxed,pressure',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    expect(rows, hasLength(8));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['matrix_size'], 8);
    }
    expect(rows.map((row) => row['matrix_index']).toList(), [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(rows.map((row) => row['seed']).toList(), [
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
    ]);
    expect(rows.map((row) => row['run_id']).toSet(), hasLength(8));
    expect(rows.first['run_id'], 'matrix_000_run_000000');
    expect(rows.last['run_id'], 'matrix_007_run_000000');
    expect(rows.first['station'], 1);
    expect(rows.first['blind_tier'], 'small');
    expect(rows.first['difficulty'], 'relaxed');
    expect(rows.last['station'], 2);
    expect(rows.last['blind_tier'], 'boss');
    expect(rows.last['difficulty'], 'pressure');
  });

  test('CLI expands loadout id matrix presets', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/loadout_matrix.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      'pair_mult',
      '--loadout-id',
      'safety_item',
      '--loadout-id',
      'score_abacus',
      '--loadout-id',
      'mobility_item',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    expect(rows, hasLength(5));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['matrix_size'], 5);
    }
    expect(rows.map((row) => row['loadout_id']).toList(), [
      'baseline',
      'pair_mult',
      'safety_item',
      'score_abacus',
      'mobility_item',
    ]);
    expect(rows.map((row) => row['seed']).toList(), [42, 43, 44, 45, 46]);

    final baselineStart = rows[0]['start_state'] as Map<String, dynamic>;
    final pairStart = rows[1]['start_state'] as Map<String, dynamic>;
    final safetyStart = rows[2]['start_state'] as Map<String, dynamic>;
    final scoreAbacusStart = rows[3]['start_state'] as Map<String, dynamic>;
    final mobilityStart = rows[4]['start_state'] as Map<String, dynamic>;
    final pairSummary = rows[1]['loadout_summary'] as Map<String, dynamic>;
    final safetySummary = rows[2]['loadout_summary'] as Map<String, dynamic>;
    final scoreAbacusSummary =
        rows[3]['loadout_summary'] as Map<String, dynamic>;
    final mobilitySummary = rows[4]['loadout_summary'] as Map<String, dynamic>;

    expect(baselineStart['jester_ids'], isEmpty);
    expect(baselineStart['item_ids'], isEmpty);
    expect(pairStart['jester_ids'], ['jolly_jester', 'zany_jester']);
    expect(pairSummary['jester_effect_type_counts'], {'mult_bonus': 2});
    expect(safetyStart['item_ids'], ['safety_net']);
    expect(safetySummary['item_tag_counts'], containsPair('safety', 1));
    expect(scoreAbacusStart['item_ids'], ['score_abacus']);
    expect(scoreAbacusSummary['item_effect_op_counts'], {'chips_bonus': 1});
    expect(mobilityStart['item_ids'], ['move_token', 'slide_wax']);
    expect(mobilitySummary['item_effect_op_counts'], {
      'add_board_move': 1,
      'mark_next_board_move_bonus': 1,
    });
  });

  test('CLI writes optional aggregate summary output', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/summary_source.jsonl';
    final summaryPath = '${dir.path}/summary.json';
    final code = await runBalanceSim([
      '--runs',
      '2',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      'pair_mult',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);
    expect(File(outPath).readAsLinesSync(), hasLength(4));
    expect(File(summaryPath).existsSync(), true);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = summary['groups'] as List<dynamic>;

    expect(summary['schema_version'], 1);
    expect(summary['source_path'], outPath);
    expect(summary['run_count'], 4);
    expect(summary['group_by'], [
      'loadout_id',
      'station',
      'blind_tier',
      'difficulty',
    ]);
    expect(groups, hasLength(2));

    final baseline = groups.cast<Map<String, dynamic>>().singleWhere(
      (group) => group['loadout_id'] == 'baseline',
    );
    final pairMult = groups.cast<Map<String, dynamic>>().singleWhere(
      (group) => group['loadout_id'] == 'pair_mult',
    );

    expect(baseline['run_count'], 2);
    expect(pairMult['run_count'], 2);
    expect(baseline['station'], 1);
    expect(baseline['blind_tier'], 'small');
    expect(baseline['difficulty'], 'standard');
    expect(baseline['clear_count'], isA<int>());
    expect(baseline['clear_rate'], isA<num>());
    expect(baseline['avg_score_ratio'], isA<num>());
    expect(baseline['avg_turn_count'], isA<num>());
    expect(baseline['outcome_counts'], isA<Map<String, dynamic>>());
  });

  test('CLI accepts turn cap arg and records capped runs', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/turn_cap.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--turn-cap',
      '1',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final result = row['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(row['turn_cap'], 1);
    expect(result['turn_count'], 1);
    expect(result['stop_reason'], 'turn_cap');
    expect(result['outcome_label'], 'turn_cap');
  });

  test('CLI repeats matrix raw and summary output deterministically', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/repeat_source.jsonl';
    final summaryPath = '${dir.path}/repeat_summary.json';
    final args = [
      '--runs',
      '2',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,boss',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      'pair_mult',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ];

    final firstCode = await runBalanceSim(args);
    final firstRaw = File(outPath).readAsStringSync();
    final firstSummary = File(summaryPath).readAsStringSync();
    final secondCode = await runBalanceSim(args);
    final secondRaw = File(outPath).readAsStringSync();
    final secondSummary = File(summaryPath).readAsStringSync();

    expect(firstCode, 0);
    expect(secondCode, 0);
    expect(firstRaw, secondRaw);
    expect(firstSummary, secondSummary);

    final rows = firstRaw
        .trim()
        .split('\n')
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final summary = jsonDecode(firstSummary) as Map<String, dynamic>;

    expect(rows, hasLength(16));
    expect(summary['run_count'], 16);
    expect(summary['groups'], hasLength(8));
  });

  test(
    'CLI applies stateful Jester runtime snapshot deterministically',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final baseOut = '${dir.path}/base.jsonl';
      final firstOut = '${dir.path}/supernova_first.jsonl';
      final secondOut = '${dir.path}/supernova_second.jsonl';

      final baseArgs = [
        '--runs',
        '1',
        '--bot',
        'greedy_v1',
        '--seed',
        '42',
        '--station',
        '1',
        '--blind-tier',
        'small',
      ];
      final baseCode = await runBalanceSim([...baseArgs, '--out', baseOut]);
      final firstCode = await runBalanceSim([
        ...baseArgs,
        '--jester',
        'supernova',
        '--out',
        firstOut,
      ]);
      final secondCode = await runBalanceSim([
        ...baseArgs,
        '--jester',
        'supernova',
        '--out',
        secondOut,
      ]);

      expect(baseCode, 0);
      expect(firstCode, 0);
      expect(secondCode, 0);
      expect(
        File(firstOut).readAsStringSync(),
        File(secondOut).readAsStringSync(),
      );

      final baseRow =
          jsonDecode(File(baseOut).readAsStringSync()) as Map<String, dynamic>;
      final jesterRow =
          jsonDecode(File(firstOut).readAsStringSync()) as Map<String, dynamic>;
      final baseResult = baseRow['result'] as Map<String, dynamic>;
      final jesterResult = jesterRow['result'] as Map<String, dynamic>;
      final startState = jesterRow['start_state'] as Map<String, dynamic>;

      _expectBalanceSimRowContract(baseRow);
      _expectBalanceSimRowContract(jesterRow);
      expect(startState['jester_ids'], ['supernova']);
      expect(
        jesterResult['final_score'],
        greaterThan(baseResult['final_score']),
      );
    },
  );

  test('CLI rejects invalid station and blind tier args', () async {
    final invalidStationCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '0',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final invalidTierCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--blind-tier',
      'huge',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(invalidStationCode, 64);
    expect(invalidTierCode, 64);
  });

  test('CLI rejects invalid turn cap arg', () async {
    final invalidTurnCapCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--turn-cap',
      '0',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(invalidTurnCapCode, 64);
  });

  test('CLI rejects invalid matrix list args', () async {
    final invalidStationsCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,0',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final invalidTiersCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--blind-tiers',
      'small,huge',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final invalidDifficultiesCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--difficulties',
      'relaxed,nightmare',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(invalidStationsCode, 64);
    expect(invalidTiersCode, 64);
    expect(invalidDifficultiesCode, 64);
  });

  test('CLI rejects invalid loadout matrix args', () async {
    final unknownLoadoutCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--loadout-id',
      'missing_loadout',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final mixedLoadoutCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--loadout-id',
      'baseline',
      '--jester',
      'jolly_jester',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(unknownLoadoutCode, 64);
    expect(mixedLoadoutCode, 64);
  });

  test('CLI rejects invalid difficulty arg', () async {
    final invalidDifficultyCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--difficulty',
      'nightmare',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(invalidDifficultyCode, 64);
  });

  test('CLI rejects unknown loadout ids', () async {
    final unknownJesterCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--jester',
      'missing_jester',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final unknownItemCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--item',
      'missing_item',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(unknownJesterCode, 64);
    expect(unknownItemCode, 64);
  });

  test('CLI rejects item loadouts that exceed inventory limits', () async {
    final tooManyQuickSlotItemsCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--item',
      'move_token',
      '--item',
      'slide_wax',
      '--item',
      'board_scrap',
      '--item',
      'hand_scrap',
      '--out',
      'logs/ignored.jsonl',
    ]);
    final duplicateNonStackableItemCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--item',
      'score_abacus',
      '--item',
      'score_abacus',
      '--out',
      'logs/ignored.jsonl',
    ]);

    expect(tooManyQuickSlotItemsCode, 64);
    expect(duplicateNonStackableItemCode, 64);
  });

  test('CLI applies station start confirm modifier items', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final baseOut = '${dir.path}/base.jsonl';
    final itemOut = '${dir.path}/item.jsonl';

    final baseCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--out',
      baseOut,
    ]);
    final itemCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--item',
      'score_abacus',
      '--out',
      itemOut,
    ]);

    expect(baseCode, 0);
    expect(itemCode, 0);

    final baseRow =
        jsonDecode(File(baseOut).readAsStringSync()) as Map<String, dynamic>;
    final itemRow =
        jsonDecode(File(itemOut).readAsStringSync()) as Map<String, dynamic>;
    final baseResult = baseRow['result'] as Map<String, dynamic>;
    final itemResult = itemRow['result'] as Map<String, dynamic>;

    expect(itemResult['final_score'], greaterThan(baseResult['final_score']));
  });

  test('CLI lets owned expiry guard items affect battle termination', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final baseOut = '${dir.path}/base.jsonl';
    final guardOut = '${dir.path}/guard.jsonl';

    final baseCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--out',
      baseOut,
    ]);
    final guardCode = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--item',
      'safety_net',
      '--out',
      guardOut,
    ]);

    expect(baseCode, 0);
    expect(guardCode, 0);

    final baseRow =
        jsonDecode(File(baseOut).readAsStringSync()) as Map<String, dynamic>;
    final guardRow =
        jsonDecode(File(guardOut).readAsStringSync()) as Map<String, dynamic>;
    final baseResult = baseRow['result'] as Map<String, dynamic>;
    final guardResult = guardRow['result'] as Map<String, dynamic>;

    expect(guardResult['turn_count'], greaterThan(baseResult['turn_count']));
  });

  test('CLI records clear before expiry outcome labels', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/clear_priority.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '3',
      '--difficulty',
      'relaxed',
      '--loadout-id',
      'pair_mult',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final result = row['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(result['cleared'], isTrue);
    expect(result['stop_reason'], 'cleared');
    expect(result['outcome_label'], 'clear');
    expect(result['score_margin'], greaterThanOrEqualTo(0));
  });

  test('CLI records balance outcome and resource end-state fields', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/result_fields.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final result = row['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(result['outcome_label'], 'board_locked');
    expect(result['remaining_deck'], isA<int>());
    expect(result['remaining_hand_size'], isA<int>());
    expect(result['remaining_board_discards'], 0);
    expect(result['remaining_hand_discards'], isA<int>());
    expect(result['remaining_board_moves'], isA<int>());
    expect(result['board_occupancy'], 25);
    expect(result['confirm_action_count'], greaterThan(0));
    expect(result['confirmed_line_count'], greaterThan(0));
    expect(result['discarded_board_count'], greaterThan(0));
    expect(result['draw_count'], greaterThan(0));
    expect(result['place_count'], greaterThan(0));
  });

  test('CLI records score progression summary fields', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/score_progression.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final result = row['result'] as Map<String, dynamic>;

    _expectBalanceSimRowContract(row);
    expect(result['confirm_action_count'], greaterThan(0));
    expect(
      result['confirmed_line_count'],
      greaterThanOrEqualTo(result['confirm_action_count'] as int),
    );
    expect(result['max_single_confirm_score'], greaterThan(0));
    expect(result['first_score_turn'], isA<int>());
    expect(result['last_score_turn'], isA<int>());
    expect(
      result['last_score_turn'] as int,
      greaterThanOrEqualTo(result['first_score_turn'] as int),
    );
  });
}

void _expectBalanceSimRowContract(Map<String, dynamic> row) {
  const requiredTopLevelFields = [
    'schema_version',
    'sim_id',
    'run_id',
    'matrix_index',
    'matrix_size',
    'loadout_id',
    'seed',
    'bot_policy',
    'app_version',
    'balance_version',
    'difficulty',
    'ruleset_id',
    'catalog_versions',
    'run_archetype_id',
    'tile_deck_composition_id',
    'tile_modifier_pool_id',
    'is_debug_run',
    'is_fixture',
    'station',
    'blind_tier',
    'boss_modifier_id',
    'boss_modifier_category',
    'target_score',
    'turn_cap',
    'start_state',
    'loadout_summary',
    'result',
  ];
  for (final field in requiredTopLevelFields) {
    expect(row, contains(field), reason: 'missing top-level field $field');
  }

  expect(row['schema_version'], 1);
  expect(row['sim_id'], isA<String>());
  expect(row['run_id'], isA<String>());
  expect(row['matrix_index'], isA<int>());
  expect(row['matrix_size'], isA<int>());
  expect(row['loadout_id'], isA<String>());
  expect(row['seed'], isA<int>());
  expect(row['bot_policy'], isA<String>());
  expect(row['app_version'], isA<String>());
  expect(row['balance_version'], isA<String>());
  expect(row['difficulty'], isA<String>());
  expect(row['ruleset_id'], isA<String>());
  expect(row['run_archetype_id'], isA<String>());
  expect(row['tile_deck_composition_id'], isA<String>());
  expect(row['is_debug_run'], isA<bool>());
  expect(row['is_fixture'], isA<bool>());
  expect(row['station'], isA<int>());
  expect(row['blind_tier'], isA<String>());
  expect(row['target_score'], isA<int>());
  expect(row['turn_cap'], isA<int>());

  final catalogVersions = row['catalog_versions'] as Map<String, dynamic>;
  expect(catalogVersions, contains('jester'));
  expect(catalogVersions, contains('item'));
  expect(catalogVersions['jester'], isA<String>());
  expect(catalogVersions['item'], isA<String>());

  final startState = row['start_state'] as Map<String, dynamic>;
  const requiredStartStateFields = [
    'gold',
    'hands_remaining',
    'board_discards',
    'hand_discards',
    'board_moves',
    'jester_ids',
    'item_ids',
    'deck_size',
  ];
  for (final field in requiredStartStateFields) {
    expect(startState, contains(field), reason: 'missing start_state.$field');
  }
  expect(startState['gold'], isA<int>());
  expect(startState['hands_remaining'], isA<int>());
  expect(startState['board_discards'], isA<int>());
  expect(startState['hand_discards'], isA<int>());
  expect(startState['board_moves'], isA<int>());
  expect(startState['jester_ids'], isA<List<dynamic>>());
  expect(startState['item_ids'], isA<List<dynamic>>());
  expect(startState['deck_size'], isA<int>());

  final loadoutSummary = row['loadout_summary'] as Map<String, dynamic>;
  const requiredLoadoutSummaryFields = [
    'jester_count',
    'item_count',
    'jester_rarity_counts',
    'jester_effect_type_counts',
    'jester_trigger_counts',
    'jester_condition_type_counts',
    'item_type_counts',
    'item_rarity_counts',
    'item_placement_counts',
    'item_effect_timing_counts',
    'item_effect_op_counts',
    'item_tag_counts',
  ];
  for (final field in requiredLoadoutSummaryFields) {
    expect(
      loadoutSummary,
      contains(field),
      reason: 'missing loadout_summary.$field',
    );
  }
  expect(loadoutSummary['jester_count'], isA<int>());
  expect(loadoutSummary['item_count'], isA<int>());
  expect(loadoutSummary['jester_rarity_counts'], isA<Map<String, dynamic>>());
  expect(
    loadoutSummary['jester_effect_type_counts'],
    isA<Map<String, dynamic>>(),
  );
  expect(loadoutSummary['jester_trigger_counts'], isA<Map<String, dynamic>>());
  expect(
    loadoutSummary['jester_condition_type_counts'],
    isA<Map<String, dynamic>>(),
  );
  expect(loadoutSummary['item_type_counts'], isA<Map<String, dynamic>>());
  expect(loadoutSummary['item_rarity_counts'], isA<Map<String, dynamic>>());
  expect(loadoutSummary['item_placement_counts'], isA<Map<String, dynamic>>());
  expect(
    loadoutSummary['item_effect_timing_counts'],
    isA<Map<String, dynamic>>(),
  );
  expect(loadoutSummary['item_effect_op_counts'], isA<Map<String, dynamic>>());
  expect(loadoutSummary['item_tag_counts'], isA<Map<String, dynamic>>());

  final result = row['result'] as Map<String, dynamic>;
  const requiredResultFields = [
    'cleared',
    'final_score',
    'score_ratio',
    'score_margin',
    'turn_count',
    'stop_reason',
    'outcome_label',
    'remaining_deck',
    'remaining_hand_size',
    'remaining_board_discards',
    'remaining_hand_discards',
    'remaining_board_moves',
    'board_occupancy',
    'confirm_action_count',
    'confirmed_line_count',
    'discarded_board_count',
    'draw_count',
    'place_count',
    'max_single_confirm_score',
    'first_score_turn',
    'last_score_turn',
  ];
  for (final field in requiredResultFields) {
    expect(result, contains(field), reason: 'missing result.$field');
  }
  expect(result['cleared'], isA<bool>());
  expect(result['final_score'], isA<int>());
  expect(result['score_ratio'], isA<num>());
  expect(result['score_margin'], isA<int>());
  expect(
    result['score_margin'],
    (result['final_score'] as int) - (row['target_score'] as int),
  );
  expect(result['turn_count'], isA<int>());
  expect(result['stop_reason'], isA<String>());
  expect(result['outcome_label'], isA<String>());
  expect(result['remaining_deck'], isA<int>());
  expect(result['remaining_hand_size'], isA<int>());
  expect(result['remaining_board_discards'], isA<int>());
  expect(result['remaining_hand_discards'], isA<int>());
  expect(result['remaining_board_moves'], isA<int>());
  expect(result['board_occupancy'], isA<int>());
  expect(result['confirm_action_count'], isA<int>());
  expect(result['confirmed_line_count'], isA<int>());
  expect(result['discarded_board_count'], isA<int>());
  expect(result['draw_count'], isA<int>());
  expect(result['place_count'], isA<int>());
  expect(result['max_single_confirm_score'], isA<int>());
  expect(result['first_score_turn'], anyOf(isNull, isA<int>()));
  expect(result['last_score_turn'], anyOf(isNull, isA<int>()));
}
