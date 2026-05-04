import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rummipoker/logic/rummi_poker_grid/hand_rank.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/line_ref.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

import '../../../tools/sim/run_balance_sim.dart';

void main() {
  test('sim single rank pressure follows runtime A안 semantics', () {
    const constraint = BalanceSimBossConstraint(
      id: 'single_rank_pressure',
      family: 'single_hand_rank_pressure',
      sourceReference: 'test',
      singleRankScoreMultiplier: 0.7,
    );
    final firstRankLine = ConfirmedLineBreakdown(
      ref: LineRef.row(0),
      rank: RummiHandRank.twoPair,
      baseScore: 25,
      finalScore: 25,
      jesterBonus: 0,
      hasScoringFaceCard: false,
      effects: [],
    );
    final otherRankLine = ConfirmedLineBreakdown(
      ref: LineRef.row(1),
      rank: RummiHandRank.straight,
      baseScore: 70,
      finalScore: 70,
      jesterBonus: 0,
      hasScoringFaceCard: false,
      effects: [],
    );

    final repeatFirstRankPenalty = simBossConstraintPenalty(
      constraint: constraint,
      lineBreakdowns: [firstRankLine],
      usedRanks: const {},
      firstRank: RummiHandRank.twoPair.name,
      confirmActionIndex: 1,
    );
    final otherRankPenalty = simBossConstraintPenalty(
      constraint: constraint,
      lineBreakdowns: [otherRankLine],
      usedRanks: const {},
      firstRank: RummiHandRank.twoPair.name,
      confirmActionIndex: 1,
    );

    expect(repeatFirstRankPenalty.scorePenalty, 8);
    expect(repeatFirstRankPenalty.triggerCount, 1);
    expect(otherRankPenalty.scorePenalty, 0);
    expect(otherRankPenalty.triggerCount, 0);
  });

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
      expect(startState['gold'], RummiEconomyConfig.startingGold);
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

  test(
    'CLI accepts planner v2 and keeps policy output deterministic',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final plannerV1Out = '${dir.path}/planner_v1.jsonl';
      final firstPlannerV2Out = '${dir.path}/planner_v2_first.jsonl';
      final secondPlannerV2Out = '${dir.path}/planner_v2_second.jsonl';
      final baseArgs = ['--runs', '1', '--seed', '42'];

      final plannerV1Code = await runBalanceSim([
        ...baseArgs,
        '--bot',
        'planner_v1',
        '--out',
        plannerV1Out,
      ]);
      final firstPlannerV2Code = await runBalanceSim([
        ...baseArgs,
        '--bot',
        'planner_v2',
        '--out',
        firstPlannerV2Out,
      ]);
      final secondPlannerV2Code = await runBalanceSim([
        ...baseArgs,
        '--bot',
        'planner_v2',
        '--out',
        secondPlannerV2Out,
      ]);

      expect(plannerV1Code, 0);
      expect(firstPlannerV2Code, 0);
      expect(secondPlannerV2Code, 0);
      expect(
        File(firstPlannerV2Out).readAsStringSync(),
        File(secondPlannerV2Out).readAsStringSync(),
      );

      final plannerV1Row =
          jsonDecode(File(plannerV1Out).readAsStringSync())
              as Map<String, dynamic>;
      final plannerV2Row =
          jsonDecode(File(firstPlannerV2Out).readAsStringSync())
              as Map<String, dynamic>;
      final plannerV1Result = plannerV1Row['result'] as Map<String, dynamic>;
      final plannerV2Result = plannerV2Row['result'] as Map<String, dynamic>;

      _expectBalanceSimRowContract(plannerV2Row);
      expect(plannerV2Row['bot_policy'], 'planner_v2');
      expect(plannerV1Row['bot_policy'], 'planner_v1');
      expect(plannerV2Result['cleared'], isTrue);
      expect(plannerV2Result['stop_reason'], 'cleared');
      expect(plannerV2Result['discarded_board_count'], 0);
      expect(
        plannerV2Result['confirm_action_count'] as int,
        lessThan(plannerV1Result['confirm_action_count'] as int),
      );
      expect(
        plannerV2Result['max_single_confirm_score'] as int,
        greaterThan(plannerV1Result['max_single_confirm_score'] as int),
      );
    },
  );

  test('CLI planner v2 matrix avoids invalid/turn-cap outcomes', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/planner_v2_matrix.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,big,boss',
      '--difficulties',
      'relaxed,standard,pressure',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final allowedOutcomeLabels = {
      'clear',
      'score_shortfall',
      'board_locked',
      'deck_exhausted',
    };

    expect(rows, hasLength(18));
    expect(rows.map((row) => row['run_id']).toSet(), hasLength(18));

    var clearCount = 0;
    var highImpactConfirmCount = 0;
    var lateScoreCount = 0;
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['matrix_size'], 18);
      expect(row['bot_policy'], 'planner_v2');

      final startState = row['start_state'] as Map<String, dynamic>;
      final result = row['result'] as Map<String, dynamic>;
      final outcomeLabel = result['outcome_label'] as String;
      final stopReason = result['stop_reason'] as String;
      final discardedBoardCount = result['discarded_board_count'] as int;
      final maxSingleConfirmScore = result['max_single_confirm_score'] as int;
      final firstScoreTurn = result['first_score_turn'] as int?;
      final lastScoreTurn = result['last_score_turn'] as int?;

      expect(allowedOutcomeLabels, contains(outcomeLabel));
      expect(stopReason, isNot(startsWith('invalid_')));
      expect(stopReason, isNot('turn_cap'));
      expect(
        discardedBoardCount,
        lessThanOrEqualTo(startState['board_discards'] as int),
      );
      expect(result['confirm_action_count'], greaterThan(0));
      expect(result['confirmed_line_count'], greaterThan(0));
      expect(maxSingleConfirmScore, greaterThan(0));
      expect(firstScoreTurn, isA<int>());
      expect(lastScoreTurn, isA<int>());
      expect(lastScoreTurn!, greaterThanOrEqualTo(firstScoreTurn!));

      if (result['cleared'] as bool) clearCount++;
      if (maxSingleConfirmScore >= 100) highImpactConfirmCount++;
      if (lastScoreTurn >= 70) lateScoreCount++;
    }

    // 밸런스 분석용 bot은 단순 클리어율보다 큰 확정/후반 확정 신호를 남겨야 한다.
    expect(clearCount, greaterThan(0));
    expect(highImpactConfirmCount, greaterThan(0));
    expect(lateScoreCount, greaterThan(0));
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
    expect(row['boss_modifier_id'], 'row_line_dampener_v1');
    expect(row['boss_modifier_category'], 'lineKindWeaken');
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
      '1',
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
    expect(bossRow['target_score'], 285);
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
    expect(bossRow['boss_modifier_id'], 'row_line_dampener_v1');
    expect(bossRow['boss_modifier_category'], 'lineKindWeaken');
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

  test(
    'CLI sequence mode writes station path battle rows and summary',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/sequence_path.jsonl';
      final summaryPath = '${dir.path}/sequence_path_summary.json';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2',
        '--experiment-id',
        'station_curve_125',
        '--loadout-id',
        's2_foundation_build',
        '--summary-out',
        summaryPath,
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );

      expect(rows.length, greaterThan(1));
      expect(battleRows.length, lessThanOrEqualTo(6));
      expect(battleRows.length, sequenceSummary['attempted_step_count']);
      expect(sequenceSummary['sequence_mode'], 'stationPath');
      expect(sequenceSummary['station_path'], [1, 2]);
      expect(sequenceSummary['tier_path'], ['small', 'big', 'boss']);
      expect(sequenceSummary['sequence_step_count'], 6);
      expect(sequenceSummary['matrix_size'], 1);
      expect(sequenceSummary['cleared_step_count'], isA<int>());
      expect(sequenceSummary['path_cleared'], isA<bool>());
      expect(sequenceSummary['last_step_resource_state'], isA<Map>());

      for (var index = 0; index < battleRows.length; index++) {
        final row = battleRows[index];
        _expectBalanceSimRowContract(row);
        expect(row['sequence_mode'], 'stationPath');
        expect(row['sequence_run_id'], sequenceSummary['sequence_run_id']);
        expect(row['sequence_step_index'], index);
        expect(row['sequence_step_count'], 6);
        expect(row['sequence_station_path'], [1, 2]);
        expect(row['sequence_tier_path'], ['small', 'big', 'boss']);
      }

      final summary =
          jsonDecode(File(summaryPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(summary['run_count'], battleRows.length);
      expect(summary['groups'], hasLength(battleRows.length));

      final lastBattle = battleRows.last;
      final lastBattleResult = lastBattle['result'] as Map<String, dynamic>;
      final lastResourceState =
          sequenceSummary['last_step_resource_state'] as Map<String, dynamic>;
      expect(lastResourceState['station'], lastBattle['station']);
      expect(lastResourceState['blind_tier'], lastBattle['blind_tier']);
      expect(
        lastResourceState['remaining_deck'],
        lastBattleResult['remaining_deck'],
      );
      expect(
        lastResourceState['remaining_board_discards'],
        lastBattleResult['remaining_board_discards'],
      );
      expect(
        lastResourceState['remaining_hand_discards'],
        lastBattleResult['remaining_hand_discards'],
      );
      if (sequenceSummary['path_cleared'] == false) {
        expect(sequenceSummary['failed_step_resource_state'], isA<Map>());
      }
    },
  );

  test('CLI sequence market profiles apply after S1 only', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/sequence_market_profile.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1,2',
      '--experiment-id',
      'early_boss_target_075',
      '--market-profile',
      's1_buy_sly',
      '--loadout-id',
      's1_entry_bridge_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final battleRows = rows
        .where((row) => row['row_type'] == 'battle')
        .toList(growable: false);
    final sequenceSummary = rows.singleWhere(
      (row) => row['row_type'] == 'sequence_summary',
    );
    final s1Rows = battleRows
        .where((row) => row['station'] == 1)
        .toList(growable: false);
    final s2Rows = battleRows
        .where((row) => row['station'] == 2)
        .toList(growable: false);

    expect(sequenceSummary['market_profile'], 's1_buy_sly');
    final purchaseEvents =
        (sequenceSummary['market_purchase_events'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    expect(purchaseEvents, hasLength(1));
    expect(purchaseEvents.single['after_station'], 1);
    expect(purchaseEvents.single['category'], 'jester');
    expect(purchaseEvents.single['content_id'], 'sly_jester');
    expect(purchaseEvents.single['cost'], isA<int>());
    expect(purchaseEvents.single['simulated'], isTrue);

    expect(s1Rows, isNotEmpty);
    expect(s1Rows.first['loadout_id'], 's1_entry_bridge_build');
    expect(
      (s1Rows.first['start_state'] as Map<String, dynamic>)['jester_ids'],
      ['jolly_jester'],
    );
    if (s2Rows.isNotEmpty) {
      expect(s2Rows.first['loadout_id'], 's1_entry_bridge_build__s1_buy_sly');
      expect(
        (s2Rows.first['start_state'] as Map<String, dynamic>)['jester_ids'],
        ['jolly_jester', 'sly_jester'],
      );
    }
  });

  test(
    'CLI sequence tile pack market profiles add deck tiles after S1',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/sequence_tile_pack_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2',
        '--experiment-id',
        'early_boss_target_075',
        '--market-profile',
        's1_pair_seed_pack',
        '--loadout-id',
        's1_entry_bridge_build',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final s1Rows = battleRows
          .where((row) => row['station'] == 1)
          .toList(growable: false);
      final s2Rows = battleRows
          .where((row) => row['station'] == 2)
          .toList(growable: false);
      final purchaseEvents =
          (sequenceSummary['market_purchase_events'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

      expect(sequenceSummary['market_profile'], 's1_pair_seed_pack');
      expect(purchaseEvents.single['category'], 'pack');
      expect(purchaseEvents.single['content_id'], 'pair_seed_pack');
      expect(purchaseEvents.single['deck_tiles_added'], 2);
      expect(
        (s1Rows.first['start_state']
            as Map<String, dynamic>)['sim_added_deck_tile_count'],
        0,
      );
      if (s2Rows.isNotEmpty) {
        final s2Start = s2Rows.first['start_state'] as Map<String, dynamic>;
        expect(s2Start['sim_added_deck_tile_count'], 2);
        expect(s2Start['sim_added_deck_tiles'], hasLength(2));
        expect(s2Start['hands_remaining'], greaterThan(52));
      }
    },
  );

  test('CLI sequence tile pack size profiles add configured counts', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/sequence_tile_pack_size_profile.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1,2',
      '--experiment-id',
      'early_boss_target_075',
      '--market-profile',
      's1_tile_pack_plus5',
      '--loadout-id',
      's1_entry_bridge_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final battleRows = rows
        .where((row) => row['row_type'] == 'battle')
        .toList(growable: false);
    final sequenceSummary = rows.singleWhere(
      (row) => row['row_type'] == 'sequence_summary',
    );
    final s2Rows = battleRows
        .where((row) => row['station'] == 2)
        .toList(growable: false);
    final purchaseEvent =
        (sequenceSummary['market_purchase_events'] as List<dynamic>).single
            as Map<String, dynamic>;

    expect(sequenceSummary['market_profile'], 's1_tile_pack_plus5');
    expect(purchaseEvent['category'], 'pack');
    expect(purchaseEvent['content_id'], 'tile_pack_plus5');
    expect(purchaseEvent['deck_tiles_added'], 5);
    expect(purchaseEvent['cost'], 8);
    if (s2Rows.isNotEmpty) {
      final s2Start = s2Rows.first['start_state'] as Map<String, dynamic>;
      expect(s2Start['sim_added_deck_tile_count'], 5);
      expect(s2Start['sim_added_deck_tiles'], hasLength(5));
      expect(s2Start['hands_remaining'], greaterThan(55));
    }
  });

  test('CLI sequence build-aware pack follows loadout incentives', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/sequence_build_aware_pack_profile.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1,2',
      '--experiment-id',
      'early_boss_target_075',
      '--market-profile',
      's1_build_aware_pack_plus3',
      '--loadout-id',
      'rare_jester_engine',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final battleRows = rows
        .where((row) => row['row_type'] == 'battle')
        .toList(growable: false);
    final sequenceSummary = rows.singleWhere(
      (row) => row['row_type'] == 'sequence_summary',
    );
    final purchaseEvent =
        (sequenceSummary['market_purchase_events'] as List<dynamic>).single
            as Map<String, dynamic>;
    final s2Rows = battleRows
        .where((row) => row['station'] == 2)
        .toList(growable: false);

    expect(sequenceSummary['market_profile'], 's1_build_aware_pack_plus3');
    expect(purchaseEvent['content_id'], 'build_aware_pack_plus3');
    expect(purchaseEvent['deck_tiles_added'], 3);
    if (s2Rows.isNotEmpty) {
      final s2Start = s2Rows.first['start_state'] as Map<String, dynamic>;
      final addedTiles = (s2Start['sim_added_deck_tiles'] as List<dynamic>)
          .cast<String>();
      final addedNumbers = addedTiles
          .map((code) => int.parse(code.substring(1)))
          .toList(growable: false);
      expect(addedNumbers, everyElement(isIn([2, 3, 5, 8, 13])));
    }
  });

  test(
    'CLI sequence random candidate market profile resolves per run',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/sequence_random_market_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2',
        '--experiment-id',
        'early_boss_target_075',
        '--market-profile',
        's1_random_candidate_pool',
        '--loadout-id',
        's1_entry_bridge_build',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final resolvedProfile =
          sequenceSummary['resolved_market_profile'] as String;
      final purchaseEvents =
          (sequenceSummary['market_purchase_events'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

      expect(sequenceSummary['market_profile'], 's1_random_candidate_pool');
      expect(
        resolvedProfile,
        isIn([
          's1_buy_jolly',
          's1_buy_sly',
          's1_buy_discard_glove',
          's1_tile_pack_small',
          's1_pair_seed_pack',
          's1_color_seed_pack',
          's1_face_seed_pack',
        ]),
      );
      expect(purchaseEvents.single['category'], isNot('sim_pool'));
      expect(purchaseEvents.single['simulated'], isTrue);
      expect(battleRows.map((row) => row['resolved_market_profile']).toSet(), {
        resolvedProfile,
      });
      final s2Rows = battleRows
          .where((row) => row['station'] == 2)
          .toList(growable: false);
      if (s2Rows.isNotEmpty) {
        expect(
          s2Rows.first['loadout_id'],
          's1_entry_bridge_build__s1_random_candidate_pool',
        );
      }
    },
  );

  test(
    'CLI sequence probabilistic candidate pool records simulated proxy',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/sequence_probabilistic_market_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2',
        '--experiment-id',
        'early_boss_target_075',
        '--market-profile',
        's1_probabilistic_candidate_pool',
        '--loadout-id',
        's5_power_build',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final resolvedProfile =
          sequenceSummary['resolved_market_profile'] as String;
      final purchaseEvent =
          (sequenceSummary['market_purchase_events'] as List<dynamic>).single
              as Map<String, dynamic>;

      expect(
        sequenceSummary['market_profile'],
        's1_probabilistic_candidate_pool',
      );
      expect(
        resolvedProfile,
        isIn([
          's1_candidate_common_color_jester',
          's1_candidate_common_rank_jester',
          's1_buy_jolly',
          's1_buy_sly',
          's1_candidate_uncommon_build_jester',
          's1_tile_pack_plus5',
          's1_build_aware_pack_plus5',
          's1_candidate_tarot_build_pack',
          's1_candidate_planet_rank_level',
          's1_buy_discard_glove',
          's1_candidate_voucher_resource',
          's1_candidate_rare_xmult_jester',
          's1_candidate_legendary_bridge',
        ]),
      );
      expect(purchaseEvent['simulated'], isTrue);
      expect(purchaseEvent['category'], isNot('sim_pool'));
      expect(battleRows.map((row) => row['resolved_market_profile']).toSet(), {
        resolvedProfile,
      });
      final s2Rows = battleRows
          .where((row) => row['station'] == 2)
          .toList(growable: false);
      if (s2Rows.isNotEmpty) {
        expect(
          s2Rows.first['loadout_id'],
          's5_power_build__s1_probabilistic_candidate_pool',
        );
      }
    },
  );

  test(
    'CLI sequence station weighted candidate pool resolves per battle step',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath =
          '${dir.path}/sequence_station_weighted_market_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '2,5',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
        '--market-profile',
        's1_station_weighted_candidate_pool',
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final resolvedProfiles = battleRows
          .map((row) => row['resolved_market_profile'] as String)
          .toSet();

      expect(
        sequenceSummary['market_profile'],
        's1_station_weighted_candidate_pool',
      );
      expect(
        sequenceSummary['resolved_market_profile'],
        's1_station_weighted_candidate_pool',
      );
      expect(resolvedProfiles, isNotEmpty);
      expect(
        resolvedProfiles,
        isNot(contains('s1_station_weighted_candidate_pool')),
      );
      expect(battleRows.map((row) => row['market_profile']).toSet(), {
        's1_station_weighted_candidate_pool',
      });
    },
  );

  test(
    'CLI sequence state weighted candidate pool resolves per battle step',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath =
          '${dir.path}/sequence_state_weighted_market_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '2,5',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
        '--market-profile',
        's1_state_weighted_candidate_pool',
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final resolvedProfiles = battleRows
          .map((row) => row['resolved_market_profile'] as String)
          .toSet();

      expect(
        sequenceSummary['market_profile'],
        's1_state_weighted_candidate_pool',
      );
      expect(
        sequenceSummary['resolved_market_profile'],
        's1_state_weighted_candidate_pool',
      );
      expect(resolvedProfiles, isNotEmpty);
      expect(
        resolvedProfiles,
        isNot(contains('s1_state_weighted_candidate_pool')),
      );
      expect(battleRows.map((row) => row['market_profile']).toSet(), {
        's1_state_weighted_candidate_pool',
      });
      expect(
        battleRows.any((row) => row['last_step_resource_state'] != null),
        isFalse,
      );
    },
  );

  test('CLI sequence banded candidate pools resolve per battle band', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    for (final marketProfile in [
      'banded_candidate_pool_v1',
      'banded_candidate_pool_v2',
    ]) {
      final outPath = '${dir.path}/sequence_$marketProfile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '3',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '2,4,7',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
        '--market-profile',
        marketProfile,
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final sequenceRows = rows
          .where((row) => row['row_type'] == 'sequence_summary')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final resolvedProfiles = battleRows
          .map((row) => row['resolved_market_profile'] as String)
          .toSet();

      expect(sequenceRows, hasLength(3));
      expect(sequenceRows.map((row) => row['market_profile']).toSet(), {
        marketProfile,
      });
      expect(
        sequenceRows.map((row) => row['resolved_market_profile']).toSet(),
        {marketProfile},
      );
      expect(battleRows.map((row) => row['market_profile']).toSet(), {
        marketProfile,
      });
      expect(resolvedProfiles, isNotEmpty);
      expect(resolvedProfiles, isNot(contains(marketProfile)));
      expect(battleRows.map((row) => row['station']).toSet(), {2, 4, 7});
      expect(
        resolvedProfiles.difference({
          's1_candidate_common_color_jester',
          's1_candidate_common_rank_jester',
          's1_candidate_uncommon_build_jester',
          's1_candidate_rare_xmult_jester',
          's1_candidate_legendary_bridge',
          's1_candidate_planet_rank_level',
          's1_candidate_tarot_build_pack',
          's1_candidate_voucher_resource',
          's1_buy_discard_glove',
          's1_tile_pack_plus5',
          's1_build_aware_pack_plus5',
        }),
        isEmpty,
      );
    }
  });

  test('CLI sequence shop slot market records rolled slots', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final allowedResolvedProfiles = {
      's1_candidate_common_color_jester',
      's1_candidate_common_rank_jester',
      's1_candidate_uncommon_build_jester',
      's1_candidate_rare_xmult_jester',
      's1_candidate_legendary_bridge',
      's1_candidate_planet_rank_level',
      's1_candidate_tarot_build_pack',
      's1_candidate_voucher_resource',
      's1_buy_discard_glove',
      's1_tile_pack_plus5',
      's1_build_aware_pack_plus5',
    };

    for (final marketProfile in [
      'shop_slot_market_v1',
      'shop_slot_market_v2',
      'shop_slot_market_v3',
      'shop_slot_market_v4',
      'shop_slot_market_v5',
      'shop_slot_market_v6',
      'shop_slot_market_v7',
      'shop_slot_market_v10',
      'shop_slot_market_v11',
    ]) {
      final outPath = '${dir.path}/sequence_$marketProfile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '3',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '2,4,7',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
        '--market-profile',
        marketProfile,
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final battleRows = rows
          .where((row) => row['row_type'] == 'battle')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final sequenceRows = rows
          .where((row) => row['row_type'] == 'sequence_summary')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);

      expect(sequenceRows, hasLength(3));
      expect(sequenceRows.map((row) => row['market_profile']).toSet(), {
        marketProfile,
      });
      expect(
        sequenceRows.map((row) => row['resolved_market_profile']).toSet(),
        {marketProfile},
      );
      expect(battleRows.map((row) => row['market_profile']).toSet(), {
        marketProfile,
      });
      for (final row in battleRows) {
        final resolvedProfile = row['resolved_market_profile'] as String;
        final shopSlots = row['market_shop_slots'] as List<dynamic>;
        final station = row['station'] as int;

        expect(resolvedProfile, isNot(marketProfile));
        expect(resolvedProfile, isIn(allowedResolvedProfiles));
        expect(shopSlots, contains(resolvedProfile));
        expect(
          shopSlots.length,
          station <= 2
              ? 3
              : marketProfile == 'shop_slot_market_v10'
              ? 5
              : marketProfile == 'shop_slot_market_v11' && station <= 5
              ? 5
              : station <= 5
              ? 4
              : 4 + (marketProfile == 'shop_slot_market_v1' ? 1 : 0),
        );
        expect(shopSlots.toSet().difference(allowedResolvedProfiles), isEmpty);
      }
    }
  });

  test(
    'CLI sequence full safe candidate pool records source backlog candidate',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/sequence_full_safe_market_profile.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2',
        '--experiment-id',
        'early_boss_target_075',
        '--market-profile',
        's1_full_safe_candidate_pool',
        '--loadout-id',
        's5_power_build',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final sequenceSummary = rows.singleWhere(
        (row) => row['row_type'] == 'sequence_summary',
      );
      final resolvedCandidate =
          sequenceSummary['resolved_market_candidate'] as Map<String, dynamic>;
      final purchaseEvent =
          (sequenceSummary['market_purchase_events'] as List<dynamic>).single
              as Map<String, dynamic>;
      final sourceCandidate =
          purchaseEvent['source_candidate'] as Map<String, dynamic>;

      expect(sequenceSummary['market_profile'], 's1_full_safe_candidate_pool');
      expect(sequenceSummary['resolved_market_profile'], isA<String>());
      expect(resolvedCandidate['adapted_id'], isA<String>());
      expect(resolvedCandidate['priority'], isIn([1, 2]));
      expect(resolvedCandidate['proxy_profile'], isA<String>());
      expect(purchaseEvent['simulated'], isTrue);
      expect(sourceCandidate['adapted_id'], resolvedCandidate['adapted_id']);
      expect(
        sourceCandidate['proxy_profile'],
        resolvedCandidate['proxy_profile'],
      );
    },
  );

  test(
    'CLI sequence role candidate pools keep source backlog context',
    () async {
      final roleExpectations = <String, Set<String>>{
        's1_role_deck_sustain_pool': {
          's1_build_aware_pack_plus5',
          's1_candidate_tarot_build_pack',
          's1_candidate_voucher_resource',
        },
        's1_role_score_growth_pool': {
          's1_candidate_common_color_jester',
          's1_candidate_common_rank_jester',
          's1_candidate_uncommon_build_jester',
          's1_candidate_rare_xmult_jester',
          's1_candidate_legendary_bridge',
          's1_candidate_planet_rank_level',
        },
        's1_role_shape_fix_pool': {
          's1_build_aware_pack_plus5',
          's1_candidate_tarot_build_pack',
          's1_candidate_common_color_jester',
          's1_candidate_common_rank_jester',
          's1_candidate_uncommon_build_jester',
        },
        's1_role_weak_flavor_pool': {
          's1_candidate_common_color_jester',
          's1_candidate_common_rank_jester',
          's1_candidate_tarot_build_pack',
          's1_candidate_voucher_resource',
        },
      };

      for (final entry in roleExpectations.entries) {
        final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
        addTearDown(() => dir.deleteSync(recursive: true));

        final outPath = '${dir.path}/${entry.key}.jsonl';
        final code = await runBalanceSim([
          '--runs',
          '1',
          '--bot',
          'planner_v2',
          '--seed',
          '42',
          '--sequence-mode',
          'station_path',
          '--stations',
          '1,2',
          '--experiment-id',
          'early_boss_target_075',
          '--market-profile',
          entry.key,
          '--loadout-id',
          's5_power_build',
          '--out',
          outPath,
        ]);

        expect(code, 0);

        final rows = File(outPath)
            .readAsLinesSync()
            .map((line) => jsonDecode(line) as Map<String, dynamic>)
            .toList();
        final sequenceSummary = rows.singleWhere(
          (row) => row['row_type'] == 'sequence_summary',
        );
        final resolvedCandidate =
            sequenceSummary['resolved_market_candidate']
                as Map<String, dynamic>;
        final purchaseEvent =
            (sequenceSummary['market_purchase_events'] as List<dynamic>).single
                as Map<String, dynamic>;

        expect(sequenceSummary['market_profile'], entry.key);
        expect(sequenceSummary['resolved_market_profile'], isIn(entry.value));
        expect(resolvedCandidate['priority'], isIn([1, 2]));
        expect(
          resolvedCandidate['proxy_profile'],
          sequenceSummary['resolved_market_profile'],
        );
        expect(purchaseEvent['simulated'], isTrue);
        expect(purchaseEvent['source_candidate'], isA<Map<String, dynamic>>());
      }
    },
  );

  test('CLI rejects market profiles outside sequence mode', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--market-profile',
      's1_buy_sly',
      '--out',
      '${dir.path}/market_profile_without_sequence.jsonl',
    ]);

    expect(code, 64);
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

  test('CLI applies sim-only progression loadout presets', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/progression_loadouts.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '3',
      '--blind-tier',
      'boss',
      '--experiment-id',
      'station_curve_125',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      's1_entry_bridge_build',
      '--loadout-id',
      's2_foundation_build',
      '--loadout-id',
      's3_hand_growth_build',
      '--loadout-id',
      's4_resource_build',
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
      expect(row['experiment_id'], 'station_curve_125');
    }

    final baselineStart = rows[0]['start_state'] as Map<String, dynamic>;
    final s1Start = rows[1]['start_state'] as Map<String, dynamic>;
    final s2Start = rows[2]['start_state'] as Map<String, dynamic>;
    final s3Start = rows[3]['start_state'] as Map<String, dynamic>;
    final s4Start = rows[4]['start_state'] as Map<String, dynamic>;
    final baselineEffects = rows[0]['loadout_effects'] as Map<String, dynamic>;
    final s1Effects = rows[1]['loadout_effects'] as Map<String, dynamic>;
    final s3Effects = rows[3]['loadout_effects'] as Map<String, dynamic>;
    final s4Effects = rows[4]['loadout_effects'] as Map<String, dynamic>;

    expect(rows.map((row) => row['loadout_id']).toList(), [
      'baseline',
      's1_entry_bridge_build',
      's2_foundation_build',
      's3_hand_growth_build',
      's4_resource_build',
    ]);
    expect(baselineEffects['sim_only'], isFalse);
    expect(s1Start['jester_ids'], ['jolly_jester']);
    expect(s1Start['board_moves'], baselineStart['board_moves'] + 1);
    expect(s1Effects['board_moves_delta'], 1);
    expect(s2Start['board_moves'], baselineStart['board_moves'] + 1);
    expect(s3Start['max_hand_size'], baselineStart['max_hand_size'] + 1);
    expect(s3Start['hand_discards'], baselineStart['hand_discards'] + 1);
    expect(s3Start['board_moves'], baselineStart['board_moves'] + 1);
    expect(s3Effects['max_hand_size_delta'], 1);
    expect(s4Start['max_hand_size'], baselineStart['max_hand_size'] + 1);
    expect(
      s4Start['board_discards'],
      greaterThan(baselineStart['board_discards']),
    );
    expect(
      s4Start['hand_discards'],
      greaterThan(baselineStart['hand_discards']),
    );
    expect(s4Start['board_moves'], greaterThan(baselineStart['board_moves']));
    expect(s4Effects['sim_only'], isTrue);
  });

  test('CLI sequence progression route changes loadout by station', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/progression_route_sequence.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1,2',
      '--market-profile',
      'none',
      '--loadout-id',
      'progression_route_balanced',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final battleRows = rows
        .where((row) => row['row_type'] == 'battle')
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    final sequenceSummary = rows.singleWhere(
      (row) => row['row_type'] == 'sequence_summary',
    );

    expect(sequenceSummary['loadout_id'], 'progression_route_balanced');
    expect(battleRows.first['base_loadout_id'], 'progression_route_balanced');
    expect(
      battleRows
          .where((row) => row['station'] == 1)
          .map((row) => row['loadout_id'])
          .toSet(),
      {'s1_entry_bridge_build'},
    );
    expect(
      battleRows
          .where((row) => row['station'] == 2)
          .map((row) => row['loadout_id'])
          .toSet(),
      anyOf(isEmpty, {'s2_foundation_build'}),
    );
  });

  test(
    'CLI sequence supports delayed and sustain progression routes',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      Future<Set<String>> loadoutsFor({
        required String routeId,
        required int station,
      }) async {
        final outPath = '${dir.path}/${routeId}_s$station.jsonl';
        final code = await runBalanceSim([
          '--runs',
          '1',
          '--bot',
          'planner_v2',
          '--seed',
          '42',
          '--sequence-mode',
          'station_path',
          '--stations',
          '$station',
          '--market-profile',
          'none',
          '--loadout-id',
          routeId,
          '--out',
          outPath,
        ]);

        expect(code, 0);

        return File(outPath)
            .readAsLinesSync()
            .map((line) => jsonDecode(line) as Map<String, dynamic>)
            .where((row) => row['row_type'] == 'battle')
            .map((row) => row['loadout_id'] as String)
            .toSet();
      }

      expect(
        await loadoutsFor(routeId: 'progression_route_delayed', station: 3),
        {'s2_foundation_build'},
      );
      expect(
        await loadoutsFor(routeId: 'progression_route_delayed', station: 5),
        {'s4_resource_build'},
      );
      expect(
        await loadoutsFor(routeId: 'progression_route_sustain', station: 5),
        {'s5_sustain_build'},
      );
    },
  );

  test('CLI applies late-run progression loadout presets', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/late_progression_loadouts.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '8',
      '--blind-tier',
      'boss',
      '--experiment-id',
      'station_curve_125',
      '--loadout-id',
      's5_power_build',
      '--loadout-id',
      's5_sustain_build',
      '--loadout-id',
      's5_boss_bridge_build',
      '--loadout-id',
      's6_boss_breaker_build',
      '--loadout-id',
      's8_finale_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    expect(code, 0);
    expect(rows, hasLength(5));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['station'], 8);
      expect(row['blind_tier'], 'boss');
      expect(row['experiment_id'], 'station_curve_125');
    }

    final s5Start = rows[0]['start_state'] as Map<String, dynamic>;
    final sustainStart = rows[1]['start_state'] as Map<String, dynamic>;
    final bridgeStart = rows[2]['start_state'] as Map<String, dynamic>;
    final s6Start = rows[3]['start_state'] as Map<String, dynamic>;
    final s8Start = rows[4]['start_state'] as Map<String, dynamic>;
    final s5Effects = rows[0]['loadout_effects'] as Map<String, dynamic>;
    final sustainEffects = rows[1]['loadout_effects'] as Map<String, dynamic>;
    final bridgeEffects = rows[2]['loadout_effects'] as Map<String, dynamic>;
    final s8Effects = rows[4]['loadout_effects'] as Map<String, dynamic>;

    expect(rows.map((row) => row['loadout_id']).toList(), [
      's5_power_build',
      's5_sustain_build',
      's5_boss_bridge_build',
      's6_boss_breaker_build',
      's8_finale_build',
    ]);
    expect(s5Effects['sim_only'], isTrue);
    expect(sustainEffects['sim_only'], isTrue);
    expect(bridgeEffects['sim_only'], isTrue);
    expect(s8Effects['sim_only'], isTrue);
    expect(
      sustainStart['hand_discards'],
      greaterThan(s5Start['hand_discards']),
    );
    expect(
      sustainStart['max_hand_size'],
      greaterThan(s5Start['max_hand_size']),
    );
    expect(bridgeStart['jester_ids'], contains('banner'));
    expect(
      bridgeStart['board_discards'],
      greaterThan(s5Start['board_discards']),
    );
    expect(s6Start['board_discards'], greaterThan(s5Start['board_discards']));
    expect(s8Start['max_hand_size'], greaterThan(s6Start['max_hand_size']));
    expect(s8Start['board_moves'], greaterThan(s6Start['board_moves']));
    expect(s8Start['hand_discards'], greaterThan(s6Start['hand_discards']));
    expect(s8Start['jester_ids'], hasLength(5));
    expect(s8Start['item_ids'], containsAll(['travel_pouch', 'echo_bell']));
  });

  test('CLI applies virtual enhancement loadout presets', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/virtual_enhancement_loadouts.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '5',
      '--blind-tier',
      'boss',
      '--experiment-id',
      'station_curve_125',
      '--loadout-id',
      'planet_like_rank_level',
      '--loadout-id',
      'tarot_like_tile_shape',
      '--loadout-id',
      'enhanced_line_score',
      '--loadout-id',
      'rare_jester_engine',
      '--loadout-id',
      'rare_xmult_engine',
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
      expect(row['station'], 5);
      expect(row['blind_tier'], 'boss');
      expect(row['experiment_id'], 'station_curve_125');
      final effects = row['loadout_effects'] as Map<String, dynamic>;
      expect(effects['sim_only'], isTrue);
    }

    expect(rows.map((row) => row['loadout_id']).toList(), [
      'planet_like_rank_level',
      'tarot_like_tile_shape',
      'enhanced_line_score',
      'rare_jester_engine',
      'rare_xmult_engine',
    ]);

    final planetStart = rows[0]['start_state'] as Map<String, dynamic>;
    final tarotStart = rows[1]['start_state'] as Map<String, dynamic>;
    final enhanceStart = rows[2]['start_state'] as Map<String, dynamic>;
    final rareStart = rows[3]['start_state'] as Map<String, dynamic>;
    final xmultStart = rows[4]['start_state'] as Map<String, dynamic>;

    expect(
      planetStart['jester_ids'],
      containsAll(['supernova', 'ride_the_bus']),
    );
    expect(tarotStart['jester_ids'], containsAll(['fibonacci', 'even_steven']));
    expect(
      tarotStart['item_ids'],
      containsAll(['travel_pouch', 'mulligan_sleeve']),
    );
    expect(enhanceStart['jester_ids'], contains('gros_michel'));
    expect(
      enhanceStart['item_ids'],
      containsAll(['echo_bell', 'tile_polisher']),
    );
    expect(rareStart['jester_ids'], containsAll(['green_jester', 'banner']));
    expect(
      rareStart['item_ids'],
      containsAll(['organizer_glove', 'travel_pouch']),
    );
    expect(
      xmultStart['jester_ids'],
      containsAll(['the_duo', 'the_trio', 'the_order', 'the_tribe']),
    );
    expect(
      xmultStart['item_ids'],
      containsAll(['organizer_glove', 'travel_pouch']),
    );
  });

  test('CLI expands S2 boss experiment presets for bottleneck checks', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/s2_boss_experiment_matrix.jsonl';
    final summaryPath = '${dir.path}/s2_boss_experiment_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '2',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'baseline,s2_boss_target_soften,s2_boss_modifier_soften,s2_boss_resource_boost',
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
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(rows, hasLength(20));
    expect(groups, hasLength(20));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['matrix_size'], 20);
      expect(row['station'], 2);
      expect(row['blind_tier'], 'boss');
      expect(row['difficulty'], 'standard');
    }

    Map<String, dynamic> rowFor(String experimentId, String loadoutId) {
      return rows.singleWhere(
        (row) =>
            row['experiment_id'] == experimentId &&
            row['loadout_id'] == loadoutId,
      );
    }

    final baseline = rowFor('baseline', 'baseline');
    final targetSoften = rowFor('s2_boss_target_soften', 'baseline');
    final modifierSoften = rowFor('s2_boss_modifier_soften', 'baseline');
    final resourceBoost = rowFor('s2_boss_resource_boost', 'baseline');
    final baselineStart = baseline['start_state'] as Map<String, dynamic>;
    final resourceStart = resourceBoost['start_state'] as Map<String, dynamic>;
    final targetEffects =
        targetSoften['experiment_effects'] as Map<String, dynamic>;
    final modifierEffects =
        modifierSoften['experiment_effects'] as Map<String, dynamic>;
    final resourceEffects =
        resourceBoost['experiment_effects'] as Map<String, dynamic>;

    expect(baseline['experiment_applied'], false);
    expect(baseline['target_score'], baseline['base_target_score']);
    expect(targetSoften['experiment_applied'], true);
    expect(targetSoften['target_score'], lessThan(baseline['target_score']));
    expect(targetEffects['target_score_multiplier'], 0.9);
    expect(modifierSoften['experiment_applied'], true);
    expect(
      modifierSoften['boss_modifier_id'],
      'row_line_dampener_v1_sim_soften',
    );
    expect(modifierEffects['boss_score_multiplier'], 0.9);
    expect(resourceBoost['experiment_applied'], true);
    expect(
      resourceStart['board_discards'],
      (baselineStart['board_discards'] as int) + 1,
    );
    expect(
      resourceStart['hand_discards'],
      (baselineStart['hand_discards'] as int) + 1,
    );
    expect(resourceEffects['board_discards_delta'], 1);
    expect(resourceEffects['hand_discards_delta'], 1);

    expect(groups.map((group) => group['experiment_id']).toSet(), {
      'baseline',
      's2_boss_target_soften',
      's2_boss_modifier_soften',
      's2_boss_resource_boost',
    });
  });

  test('CLI keeps S2 boss experiments inactive outside target slice', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final baselineOut = '${dir.path}/s1_baseline.jsonl';
    final experimentOut = '${dir.path}/s1_experiment.jsonl';
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
      'boss',
      '--difficulty',
      'standard',
    ];
    final baselineCode = await runBalanceSim([
      ...baseArgs,
      '--out',
      baselineOut,
    ]);
    final experimentCode = await runBalanceSim([
      ...baseArgs,
      '--experiment-id',
      's2_boss_target_soften',
      '--out',
      experimentOut,
    ]);

    expect(baselineCode, 0);
    expect(experimentCode, 0);
    expect(
      File(baselineOut).readAsStringSync(),
      isNot(File(experimentOut).readAsStringSync()),
    );

    final baseline =
        jsonDecode(File(baselineOut).readAsStringSync())
            as Map<String, dynamic>;
    final experiment =
        jsonDecode(File(experimentOut).readAsStringSync())
            as Map<String, dynamic>;

    _expectBalanceSimRowContract(baseline);
    _expectBalanceSimRowContract(experiment);
    expect(experiment['experiment_id'], 's2_boss_target_soften');
    expect(experiment['experiment_applied'], false);
    expect(experiment['experiment_effects'], isEmpty);
    expect(experiment['target_score'], baseline['target_score']);
    expect(experiment['base_target_score'], baseline['base_target_score']);
    expect(experiment['boss_modifier_id'], baseline['boss_modifier_id']);
    expect(experiment['start_state'], baseline['start_state']);
    expect(experiment['result'], baseline['result']);
  });

  test('CLI applies early boss bridge only to S1/S2 boss', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/early_boss_bridge.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125,early_boss_target_085,early_boss_target_080,early_boss_target_075,early_boss_resource_1',
      '--loadout-id',
      's1_entry_bridge_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    expect(rows, hasLength(20));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['difficulty'], 'standard');
      expect(row['loadout_id'], 's1_entry_bridge_build');
    }

    Map<String, dynamic> rowFor(String experimentId, int station, String tier) {
      return rows.singleWhere(
        (row) =>
            row['experiment_id'] == experimentId &&
            row['station'] == station &&
            row['blind_tier'] == tier,
      );
    }

    for (final station in [1, 2]) {
      final curveSmall = rowFor('station_curve_125', station, 'small');
      final targetSmall = rowFor('early_boss_target_085', station, 'small');
      final target080Small = rowFor('early_boss_target_080', station, 'small');
      final target075Small = rowFor('early_boss_target_075', station, 'small');
      final resourceSmall = rowFor('early_boss_resource_1', station, 'small');
      final curveBoss = rowFor('station_curve_125', station, 'boss');
      final targetBoss = rowFor('early_boss_target_085', station, 'boss');
      final target080Boss = rowFor('early_boss_target_080', station, 'boss');
      final target075Boss = rowFor('early_boss_target_075', station, 'boss');
      final resourceBoss = rowFor('early_boss_resource_1', station, 'boss');
      final curveBossStart = curveBoss['start_state'] as Map<String, dynamic>;
      final resourceBossStart =
          resourceBoss['start_state'] as Map<String, dynamic>;
      final targetBossEffects =
          targetBoss['experiment_effects'] as Map<String, dynamic>;
      final resourceBossEffects =
          resourceBoss['experiment_effects'] as Map<String, dynamic>;

      expect(targetSmall['experiment_applied'], false);
      expect(target080Small['experiment_applied'], false);
      expect(target075Small['experiment_applied'], false);
      expect(resourceSmall['experiment_applied'], false);
      expect(targetSmall['target_score'], curveSmall['target_score']);
      expect(target080Small['target_score'], curveSmall['target_score']);
      expect(target075Small['target_score'], curveSmall['target_score']);
      expect(resourceSmall['target_score'], curveSmall['target_score']);
      expect(
        (targetSmall['experiment_effects']
            as Map<String, dynamic>)['early_boss_bridge'],
        false,
      );
      expect(targetBoss['experiment_applied'], true);
      expect(target080Boss['experiment_applied'], true);
      expect(target075Boss['experiment_applied'], true);
      expect(resourceBoss['experiment_applied'], true);
      expect(
        targetBoss['target_score'],
        ((curveBoss['target_score'] as int) * 0.85).round(),
      );
      expect(targetBossEffects['target_score_multiplier'], 0.85);
      expect(targetBossEffects['early_boss_bridge'], true);
      expect(
        target080Boss['target_score'],
        ((curveBoss['target_score'] as int) * 0.8).round(),
      );
      expect(
        (target080Boss['experiment_effects']
            as Map<String, dynamic>)['target_score_multiplier'],
        0.8,
      );
      expect(
        target075Boss['target_score'],
        ((curveBoss['target_score'] as int) * 0.75).round(),
      );
      expect(
        (target075Boss['experiment_effects']
            as Map<String, dynamic>)['target_score_multiplier'],
        0.75,
      );
      expect(resourceBoss['target_score'], curveBoss['target_score']);
      expect(
        resourceBossStart['board_discards'],
        (curveBossStart['board_discards'] as int) + 1,
      );
      expect(
        resourceBossStart['hand_discards'],
        (curveBossStart['hand_discards'] as int) + 1,
      );
      expect(resourceBossEffects['board_discards_delta'], 1);
      expect(resourceBossEffects['hand_discards_delta'], 1);
      expect(resourceBossEffects['early_boss_bridge'], true);
    }
  });

  test('CLI applies S1 boss safety only to first boss', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/s1_boss_safety.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125,s1_boss_target_070',
      '--loadout-id',
      's1_entry_bridge_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    Map<String, dynamic> rowFor(String experimentId, int station, String tier) {
      return rows.singleWhere(
        (row) =>
            row['experiment_id'] == experimentId &&
            row['station'] == station &&
            row['blind_tier'] == tier,
      );
    }

    final curveS1Small = rowFor('station_curve_125', 1, 'small');
    final curveS1Boss = rowFor('station_curve_125', 1, 'boss');
    final curveS2Boss = rowFor('station_curve_125', 2, 'boss');
    final safetyS1Small = rowFor('s1_boss_target_070', 1, 'small');
    final safetyS1Boss = rowFor('s1_boss_target_070', 1, 'boss');
    final safetyS2Boss = rowFor('s1_boss_target_070', 2, 'boss');
    final s1BossEffects =
        safetyS1Boss['experiment_effects'] as Map<String, dynamic>;

    for (final row in rows) {
      _expectBalanceSimRowContract(row);
    }
    expect(safetyS1Small['experiment_applied'], false);
    expect(safetyS2Boss['experiment_applied'], false);
    expect(safetyS1Boss['experiment_applied'], true);
    expect(safetyS1Small['target_score'], curveS1Small['target_score']);
    expect(safetyS2Boss['target_score'], curveS2Boss['target_score']);
    expect(
      safetyS1Boss['target_score'],
      ((curveS1Boss['target_score'] as int) * 0.7).round(),
    );
    expect(s1BossEffects['s1_boss_safety'], true);
    expect(s1BossEffects['target_score_multiplier'], 0.7);
  });

  test(
    'CLI applies dynamic target multiplier only to matching blind',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/target_multiplier.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--stations',
        '2,3',
        '--blind-tiers',
        'big,boss',
        '--difficulty',
        'standard',
        '--experiment-id',
        's1_boss_target_070',
        '--target-multiplier',
        'S3:boss:0.8',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();

      Map<String, dynamic> rowFor(int station, String tier) {
        return rows.singleWhere(
          (row) => row['station'] == station && row['blind_tier'] == tier,
        );
      }

      final s3Boss = rowFor(3, 'boss');
      final s3BossEffects =
          s3Boss['experiment_effects'] as Map<String, dynamic>;

      for (final row in rows) {
        _expectBalanceSimRowContract(row);
        if (row['station'] == 3 && row['blind_tier'] == 'boss') {
          continue;
        }
        expect(row['experiment_applied'], false);
        expect(
          (row['experiment_effects']
              as Map<String, dynamic>)['target_multiplier_override'],
          isNot(true),
        );
      }
      expect(s3Boss['experiment_applied'], true);
      expect(s3BossEffects['target_multiplier_override'], true);
      expect(s3BossEffects['target_multiplier_override_station'], 3);
      expect(s3BossEffects['target_multiplier_override_tier'], 'boss');
      expect(s3BossEffects['target_multiplier_override_value'], 0.8);
      expect(s3Boss['target_score'], isA<int>());
    },
  );

  test('CLI expands S2 boss target sweep presets in target order', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/s2_boss_target_sweep.jsonl';
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
      '--difficulty',
      'standard',
      '--experiment-ids',
      'baseline,s2_boss_target_085,s2_boss_target_080,s2_boss_target_075',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

    expect(rows, hasLength(4));
    for (final row in rows) {
      _expectBalanceSimRowContract(row);
      expect(row['station'], 2);
      expect(row['blind_tier'], 'boss');
      expect(row['difficulty'], 'standard');
    }
    expect(rows.map((row) => row['experiment_id']).toList(), [
      'baseline',
      's2_boss_target_085',
      's2_boss_target_080',
      's2_boss_target_075',
    ]);
    expect(rows.map((row) => row['target_score']).toList(), [
      rows.first['base_target_score'],
      ((rows.first['base_target_score'] as int) * 0.85).round(),
      ((rows.first['base_target_score'] as int) * 0.80).round(),
      ((rows.first['base_target_score'] as int) * 0.75).round(),
    ]);
    expect(
      (rows[1]['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.85,
    );
    expect(
      (rows[2]['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.8,
    );
    expect(
      (rows[3]['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.75,
    );
  });

  test(
    'CLI applies station curve experiments against runtime baseline',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/station_curve.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'greedy_v1',
        '--seed',
        '42',
        '--station',
        '4',
        '--blind-tier',
        'boss',
        '--difficulty',
        'standard',
        '--experiment-ids',
        'baseline,baseline_curve_160,station_curve_145,station_curve_135,station_curve_125',
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
        expect(row['station'], 4);
        expect(row['blind_tier'], 'boss');
        expect(row['difficulty'], 'standard');
      }
      expect(rows.map((row) => row['experiment_id']).toList(), [
        'baseline',
        'baseline_curve_160',
        'station_curve_145',
        'station_curve_135',
        'station_curve_125',
      ]);

      final baseline = rows[0];
      final curve160 = rows[1];
      final curve145 = rows[2];
      final curve135 = rows[3];
      final curve125 = rows[4];
      final curve145Effects =
          curve145['experiment_effects'] as Map<String, dynamic>;

      expect(baseline['target_score'], baseline['base_target_score']);
      expect(baseline['base_target_score'], 685);
      expect(curve160['target_score'], 2210);
      expect(curve160['experiment_applied'], false);
      expect(curve145['experiment_applied'], true);
      expect(curve145Effects['station_growth_base'], 1.45);
      expect(
        curve145Effects['runtime_base_target_score'],
        baseline['base_target_score'],
      );
      expect(
        curve145['target_score'] as int,
        lessThan(curve160['target_score'] as int),
      );
      expect(
        curve135['target_score'] as int,
        lessThan(curve145['target_score'] as int),
      );
      expect(
        curve125['target_score'] as int,
        lessThan(curve135['target_score'] as int),
      );
    },
  );

  test('CLI applies sim-only boss constraint pool experiment', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/boss_constraint_pool.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '3',
      '--blind-tier',
      'boss',
      '--experiment-id',
      'station_curve_125_boss_constraint_pool_v1',
      '--loadout-id',
      'rare_jester_engine',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final effects = row['experiment_effects'] as Map<String, dynamic>;
    final result = row['result'] as Map<String, dynamic>;

    expect(row['experiment_applied'], isTrue);
    expect(effects['boss_constraint_pool'], isTrue);
    expect(effects['sim_boss_constraint_id'], isA<String>());
    expect(row['sim_boss_constraint'], anyOf(isNull, isA<Map>()));
    expect(result['sim_constraint_trigger_count'], isA<int>());
    expect(result['sim_constraint_score_penalty'], isA<int>());
  });

  test(
    'CLI ordered boss experiment covers every boss proxy and keeps boss above big',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/ordered_boss_pool.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--stations',
        '1,2,3,4,5,6,7,8,9,10',
        '--blind-tiers',
        'big,boss',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_ordered_boss_v1',
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final bigRows = {
        for (final row in rows.where((row) => row['blind_tier'] == 'big'))
          row['station'] as int: row,
      };
      final bossRows = rows
          .where((row) => row['blind_tier'] == 'boss')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);

      expect(bossRows, hasLength(10));
      expect(
        bossRows
            .map(
              (row) =>
                  (row['experiment_effects']
                      as Map<String, dynamic>)['sim_boss_constraint_id'],
            )
            .toSet(),
        {
          'color_dampener_cycle',
          'line_kind_dampener_cycle',
          'face_tile_dampener',
          'repeat_rank_pressure_v4',
          'single_rank_pressure',
          'confirm_count_tax_v2',
          'all_score_dampener',
          'first_confirm_tax',
          'target_spike_wall',
          'resource_squeeze',
        },
      );
      for (final bossRow in bossRows) {
        final station = bossRow['station'] as int;
        final effects = bossRow['experiment_effects'] as Map<String, dynamic>;
        final bigRow = bigRows[station]!;

        expect(effects['ordered_boss_targets'], isTrue);
        expect(
          bossRow['target_score'] as int,
          greaterThan(bigRow['target_score'] as int),
          reason: 'S$station boss target must stay above big',
        );
      }
    },
  );

  test(
    'CLI weighted boss experiment rolls banded boss pool and records proxy ids',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/weighted_boss_pool.jsonl';
      final summaryPath = '${dir.path}/weighted_boss_pool_summary.json';
      final code = await runBalanceSim([
        '--runs',
        '24',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2,3,4,5,6,7,8',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v1',
        '--market-profile',
        'shop_slot_market_v7',
        '--loadout-id',
        'progression_route_power',
        '--summary-out',
        summaryPath,
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .where((row) => row['row_type'] == 'battle')
          .toList();
      final bossRows = rows
          .where((row) => row['blind_tier'] == 'boss')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final rolledIds = bossRows
          .map(
            (row) =>
                (row['experiment_effects']
                    as Map<String, dynamic>)['sim_boss_constraint_id'],
          )
          .toSet();

      expect(rolledIds.length, greaterThan(4));
      expect(rolledIds, contains('target_spike_wall'));
      expect(rolledIds, contains('confirm_count_tax_v2'));
      for (final bossRow in bossRows) {
        final effects = bossRow['experiment_effects'] as Map<String, dynamic>;
        expect(
          effects['sim_boss_pool_profile'],
          'early_mid_late_final_weighted_v1',
        );
        expect(effects['ordered_boss_targets'], isTrue);
        expect(
          bossRow['sim_boss_constraint_id'],
          effects['sim_boss_constraint_id'],
        );
      }

      final summary =
          jsonDecode(File(summaryPath).readAsStringSync())
              as Map<String, dynamic>;
      final groups = summary['groups'] as List<dynamic>;
      expect(
        groups.any(
          (group) =>
              group is Map<String, dynamic> &&
              group['sim_boss_constraint_id'] == 'target_spike_wall',
        ),
        isTrue,
      );
    },
  );

  test(
    'CLI weighted boss v3 pairs shop slot market v9 with softened banded boss pool',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/weighted_boss_v3_market_v9.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '24',
        '--bot',
        'planner_v2',
        '--seed',
        '77',
        '--sequence-mode',
        'station_path',
        '--stations',
        '1,2,3,4,5,6,7,8',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_weighted_boss_v3',
        '--market-profile',
        'shop_slot_market_v9',
        '--loadout-id',
        'progression_route_power',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final rows = File(outPath)
          .readAsLinesSync()
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .where((row) => row['row_type'] == 'battle')
          .toList();
      final stationTwoRows = rows
          .where((row) => row['station'] == 2)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final finalBossRows = rows
          .where((row) => row['station'] == 8 && row['blind_tier'] == 'boss')
          .cast<Map<String, dynamic>>()
          .toList(growable: false);

      expect(stationTwoRows, isNotEmpty);
      expect(stationTwoRows.map((row) => row['market_profile']).toSet(), {
        'shop_slot_market_v9',
      });
      expect(
        stationTwoRows
            .map((row) => row['resolved_market_profile'])
            .toSet()
            .contains('shop_slot_market_v9'),
        isFalse,
      );
      expect(finalBossRows, isNotEmpty);
      for (final row in finalBossRows) {
        final effects = row['experiment_effects'] as Map<String, dynamic>;
        expect(
          effects['sim_boss_pool_profile'],
          'early_mid_late_final_weighted_v3',
        );
        expect(effects['ordered_boss_targets'], isTrue);
      }
    },
  );

  test('CLI applies sim-only target curve v5 boss resource bridge', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/target_curve_v5.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '5',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125,station_curve_125_target_v5',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final base = rows[0];
    final v5 = rows[1];
    final effects = v5['experiment_effects'] as Map<String, dynamic>;
    final baseStartState = base['start_state'] as Map<String, dynamic>;
    final startState = v5['start_state'] as Map<String, dynamic>;

    expect(v5['experiment_id'], 'station_curve_125_target_v5');
    expect(effects['target_curve_v5'], isTrue);
    expect(effects['target_score_multiplier'], 0.65);
    expect(effects['board_discards_delta'], 1);
    expect(effects['hand_discards_delta'], 1);
    expect(effects['max_hand_size_delta'], 1);
    expect(v5['target_score'] as int, lessThan(base['target_score'] as int));
    expect(
      startState['board_discards'],
      (baseStartState['board_discards'] as int) + 1,
    );
    expect(
      startState['hand_discards'],
      (baseStartState['hand_discards'] as int) + 1,
    );
    expect(
      startState['max_hand_size'],
      (baseStartState['max_hand_size'] as int) + 1,
    );
  });

  test(
    'CLI applies boss constraint pool v2 without hard confirm stop',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/boss_constraint_pool_v2.jsonl';
      final code = await runBalanceSim([
        '--runs',
        '1',
        '--bot',
        'planner_v2',
        '--seed',
        '42',
        '--station',
        '6',
        '--blind-tier',
        'boss',
        '--experiment-id',
        'station_curve_125_boss_constraint_pool_v2',
        '--loadout-id',
        's5_power_build',
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final row =
          jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
      final effects = row['experiment_effects'] as Map<String, dynamic>;
      final constraint = row['sim_boss_constraint'] as Map<String, dynamic>;

      expect(effects['boss_constraint_pool_severity'], 'v2');
      expect(effects['sim_boss_constraint_id'], 'confirm_count_tax_v2');
      expect(constraint['id'], 'confirm_count_tax_v2');
      expect(constraint.containsKey('max_confirm_actions'), isFalse);
      expect(constraint['confirm_after_limit_action_count'], 2);
      expect(constraint['confirm_after_limit_score_multiplier'], 0.65);
    },
  );

  test('CLI applies target curve v6 S5 without resource bridge', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/target_curve_v6_s5.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '5',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125,station_curve_125_target_v6_s5_070,station_curve_125_target_v6_s5_075',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final base = rows[0];
    final v6S5Target070 = rows[1];
    final v6S5Target075 = rows[2];
    final baseStartState = base['start_state'] as Map<String, dynamic>;
    final startState = v6S5Target070['start_state'] as Map<String, dynamic>;
    final effects070 =
        v6S5Target070['experiment_effects'] as Map<String, dynamic>;
    final effects075 =
        v6S5Target075['experiment_effects'] as Map<String, dynamic>;

    expect(effects070['target_curve_v6'], isTrue);
    expect(effects070['target_score_multiplier'], 0.70);
    expect(effects075['target_score_multiplier'], 0.75);
    expect(effects070['board_discards_delta'], 0);
    expect(effects070['hand_discards_delta'], 0);
    expect(effects070['max_hand_size_delta'], 0);
    expect(startState['board_discards'], baseStartState['board_discards']);
    expect(startState['hand_discards'], baseStartState['hand_discards']);
    expect(startState['max_hand_size'], baseStartState['max_hand_size']);
    expect(
      v6S5Target070['target_score'] as int,
      lessThan(v6S5Target075['target_score'] as int),
    );
  });

  test('CLI applies S4 boss constraint v3 and target v7 relief', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/s4_constraint_v3_target_v7.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '4',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125_target_v6_s5_070_boss_constraint_pool_v2,station_curve_125_target_v6_s5_070_boss_constraint_pool_v4,station_curve_125_target_v6_s5_070_boss_constraint_pool_v3,station_curve_125_target_v7_s4_080_s5_070_boss_constraint_pool_v3',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final v2 = rows[0];
    final v4 = rows[1];
    final v3 = rows[2];
    final v7 = rows[3];
    final v4Effects = v4['experiment_effects'] as Map<String, dynamic>;
    final v3Effects = v3['experiment_effects'] as Map<String, dynamic>;
    final v7Effects = v7['experiment_effects'] as Map<String, dynamic>;
    final v2Constraint = v2['sim_boss_constraint'] as Map<String, dynamic>;
    final v4Constraint = v4['sim_boss_constraint'] as Map<String, dynamic>;
    final v3Constraint = v3['sim_boss_constraint'] as Map<String, dynamic>;
    final v7Constraint = v7['sim_boss_constraint'] as Map<String, dynamic>;

    expect(v4Effects['boss_constraint_pool_severity'], 'v4');
    expect(v4Effects['sim_boss_constraint_id'], 'repeat_rank_pressure_v4');
    expect(v4Constraint['repeat_rank_score_multiplier'], 0.80);
    expect(v3Effects['boss_constraint_pool_severity'], 'v3');
    expect(v3Effects['sim_boss_constraint_id'], 'repeat_rank_pressure_v3');
    expect(v3Constraint['repeat_rank_score_multiplier'], 0.85);
    expect(
      v4Constraint['repeat_rank_score_multiplier'] as double,
      greaterThan(v2Constraint['repeat_rank_score_multiplier'] as double),
    );
    expect(
      v3Constraint['repeat_rank_score_multiplier'] as double,
      greaterThan(v4Constraint['repeat_rank_score_multiplier'] as double),
    );
    expect(v7Effects['target_curve_v7'], isTrue);
    expect(v7Effects['target_score_multiplier'], 0.80);
    expect(v7Constraint['repeat_rank_score_multiplier'], 0.85);
    expect(v7['target_score'] as int, lessThan(v3['target_score'] as int));
  });

  test('CLI keeps v3 S6 boss on confirm tax instead of hard limit', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/s6_constraint_v3.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--station',
      '6',
      '--blind-tier',
      'boss',
      '--experiment-id',
      'station_curve_125_target_v6_s5_070_boss_constraint_pool_v3',
      '--loadout-id',
      's5_power_build',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final row =
        jsonDecode(File(outPath).readAsStringSync()) as Map<String, dynamic>;
    final effects = row['experiment_effects'] as Map<String, dynamic>;
    final constraint = row['sim_boss_constraint'] as Map<String, dynamic>;

    expect(effects['boss_constraint_pool_severity'], 'v3');
    expect(effects['sim_boss_constraint_id'], 'confirm_count_tax_v2');
    expect(constraint['id'], 'confirm_count_tax_v2');
    expect(constraint.containsKey('max_confirm_actions'), isFalse);
    expect(constraint['confirm_after_limit_action_count'], 2);
    expect(constraint['confirm_after_limit_score_multiplier'], 0.65);
  });

  test('CLI aliases candidate baseline v1 to current sim baseline', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/candidate_baseline_v1.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '4',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'candidate_baseline_v1,station_curve_125_target_v6_s5_070_boss_constraint_pool_v4',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final alias = rows[0];
    final canonical = rows[1];
    final aliasEffects = alias['experiment_effects'] as Map<String, dynamic>;
    final aliasConstraint =
        alias['sim_boss_constraint'] as Map<String, dynamic>;
    final canonicalConstraint =
        canonical['sim_boss_constraint'] as Map<String, dynamic>;

    expect(alias['experiment_id'], 'candidate_baseline_v1');
    expect(aliasEffects['candidate_baseline_v1'], isTrue);
    expect(aliasEffects['target_curve_v6'], isTrue);
    expect(aliasEffects['boss_constraint_pool_severity'], 'v4');
    expect(aliasEffects['target_score_multiplier'], 0.85);
    expect(aliasConstraint['id'], 'repeat_rank_pressure_v4');
    expect(aliasConstraint['repeat_rank_score_multiplier'], 0.80);
    expect(alias['target_score'], canonical['target_score']);
    expect(
      aliasConstraint['repeat_rank_score_multiplier'],
      canonicalConstraint['repeat_rank_score_multiplier'],
    );
  });

  test('CLI applies base score curve v2 without constraint layer', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/base_score_curve_v2.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '1',
      '--blind-tiers',
      'small,big,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'base_score_curve_v2,station_curve_125',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final baseRows = rows
        .where((row) => row['experiment_id'] == 'base_score_curve_v2')
        .toList(growable: false);
    final curveRows = rows
        .where((row) => row['experiment_id'] == 'station_curve_125')
        .toList(growable: false);

    expect(baseRows, hasLength(3));
    expect(curveRows, hasLength(3));

    final baseByTier = {
      for (final row in baseRows) row['blind_tier'] as String: row,
    };
    final curveByTier = {
      for (final row in curveRows) row['blind_tier'] as String: row,
    };
    final expectedMultipliers = {'small': 1.10, 'big': 0.85, 'boss': 0.65};

    for (final entry in expectedMultipliers.entries) {
      final row = baseByTier[entry.key]!;
      final curveRow = curveByTier[entry.key]!;
      final effects = row['experiment_effects'] as Map<String, dynamic>;

      expect(effects['base_score_curve_v2'], isTrue);
      expect(effects['target_score_multiplier'], entry.value);
      expect(effects['board_discards_delta'], 0);
      expect(effects['hand_discards_delta'], 0);
      expect(effects['max_hand_size_delta'], 0);
      expect(
        row['target_score'],
        ((curveRow['target_score'] as int) * entry.value).round(),
      );
      expect(row['sim_boss_constraint'], isNull);
    }
  });

  test('CLI layers boss constraints on base score curve v2', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/base_score_curve_v2_constraints.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '4',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'base_score_curve_v2,base_score_curve_v2_boss_constraint_pool_v2,base_score_curve_v2_boss_constraint_pool_v4',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    final base = rows.singleWhere(
      (row) => row['experiment_id'] == 'base_score_curve_v2',
    );
    final v2 = rows.singleWhere(
      (row) =>
          row['experiment_id'] == 'base_score_curve_v2_boss_constraint_pool_v2',
    );
    final v4 = rows.singleWhere(
      (row) =>
          row['experiment_id'] == 'base_score_curve_v2_boss_constraint_pool_v4',
    );
    final v2Effects = v2['experiment_effects'] as Map<String, dynamic>;
    final v4Effects = v4['experiment_effects'] as Map<String, dynamic>;
    final v2Constraint = v2['sim_boss_constraint'] as Map<String, dynamic>;
    final v4Constraint = v4['sim_boss_constraint'] as Map<String, dynamic>;

    expect(v2Effects['base_score_curve_v2'], isTrue);
    expect(v2Effects['boss_constraint_pool_severity'], 'v2');
    expect(v2Effects['target_score_multiplier'], 0.65);
    expect(v2['target_score'], base['target_score']);
    expect(v2Constraint['id'], 'repeat_rank_pressure_v2');
    expect(v2Constraint['repeat_rank_score_multiplier'], 0.72);

    expect(v4Effects['base_score_curve_v2'], isTrue);
    expect(v4Effects['boss_constraint_pool_severity'], 'v4');
    expect(v4Effects['target_score_multiplier'], 0.65);
    expect(v4['target_score'], base['target_score']);
    expect(v4Constraint['id'], 'repeat_rank_pressure_v4');
    expect(v4Constraint['repeat_rank_score_multiplier'], 0.80);
  });

  test('CLI applies S1 onboarding variants on base score curve v2', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/base_score_curve_v2_s1_onboarding.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--station',
      '1',
      '--blind-tiers',
      'small,big,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'base_score_curve_v2_boss_constraint_pool_v4,base_score_curve_v2_boss_constraint_pool_v4_s1_soft,base_score_curve_v2_boss_constraint_pool_v4_s1_resource,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource,base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    Map<String, dynamic> rowFor(String experimentId, String tier) =>
        rows.singleWhere(
          (row) =>
              row['experiment_id'] == experimentId && row['blind_tier'] == tier,
        );

    final baseSmall = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4',
      'small',
    );
    final softSmall = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
      'small',
    );
    final resourceSmall = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_resource',
      'small',
    );
    final softResourceBoss = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_resource',
      'boss',
    );
    final boss052Small = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052',
      'small',
    );
    final boss052Boss = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_boss_052',
      'boss',
    );
    final softV2Small = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
      'small',
    );
    final softV2Big = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
      'big',
    );
    final softV2Boss = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2',
      'boss',
    );
    final softSmallEffects =
        softSmall['experiment_effects'] as Map<String, dynamic>;
    final resourceSmallEffects =
        resourceSmall['experiment_effects'] as Map<String, dynamic>;
    final softResourceBossEffects =
        softResourceBoss['experiment_effects'] as Map<String, dynamic>;

    expect(softSmallEffects['boss_constraint_pool_severity'], 'v4');
    expect(softSmallEffects['target_score_multiplier'], 1.0);
    expect(softSmall['target_score'], lessThan(baseSmall['target_score']));
    expect(resourceSmallEffects['board_discards_delta'], 1);
    expect(resourceSmallEffects['hand_discards_delta'], 1);
    expect(resourceSmallEffects['max_hand_size_delta'], 1);
    expect(
      (resourceSmall['start_state'] as Map<String, dynamic>)['max_hand_size'],
      greaterThan(
        (baseSmall['start_state'] as Map<String, dynamic>)['max_hand_size'],
      ),
    );
    expect(softResourceBossEffects['target_score_multiplier'], 0.58);
    expect(softResourceBossEffects['board_discards_delta'], 1);
    expect(softResourceBossEffects['boss_constraint_pool_severity'], 'v4');
    expect(softResourceBoss['sim_boss_constraint'], anyOf(isNull, isA<Map>()));
    expect(boss052Small['target_score'], baseSmall['target_score']);
    expect(
      boss052Boss['target_score'],
      lessThan(softResourceBoss['target_score']),
    );
    expect(softV2Small['target_score'], lessThan(softSmall['target_score']));
    expect(
      softV2Big['target_score'],
      lessThan(
        rowFor(
          'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
          'big',
        )['target_score'],
      ),
    );
    expect(
      softV2Boss['target_score'],
      lessThan(softResourceBoss['target_score']),
    );
  });

  test('CLI applies S1 soft plus S2 boss tuning on base curve v2', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/base_score_curve_v2_s1_s2_bridge.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tier',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    Map<String, dynamic> rowFor(String experimentId, int station) =>
        rows.singleWhere(
          (row) =>
              row['experiment_id'] == experimentId && row['station'] == station,
        );

    final s1Soft = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
      1,
    );
    final s1S2Boss090 = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090',
      1,
    );
    final s2Soft = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft',
      2,
    );
    final s2Boss090 = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_090',
      2,
    );
    final s2Boss085 = rowFor(
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_s2_boss_085',
      2,
    );

    expect(s1S2Boss090['target_score'], s1Soft['target_score']);
    expect(s2Boss090['target_score'], lessThan(s2Soft['target_score']));
    expect(s2Boss085['target_score'], lessThan(s2Boss090['target_score']));
    expect(
      (s2Boss090['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.65 * 0.90,
    );
    expect(
      (s2Boss085['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.65 * 0.85,
    );
  });

  test('CLI applies three-band curve variants on base curve v2', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/base_score_curve_v2_three_band.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,3,6',
      '--blind-tiers',
      'small,big,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1,base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2,base_score_curve_v2_boss_constraint_pool_v4_three_band_v1,base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1,base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1',
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    Map<String, dynamic> rowFor(
      String experimentId,
      int station,
      String tier,
    ) => rows.singleWhere(
      (row) =>
          row['experiment_id'] == experimentId &&
          row['station'] == station &&
          row['blind_tier'] == tier,
    );
    double multiplierFor(String experimentId, int station, String tier) {
      final effects =
          rowFor(experimentId, station, tier)['experiment_effects']
              as Map<String, dynamic>;
      return (effects['target_score_multiplier'] as num).toDouble();
    }

    const s1SoftV2 = 'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2';
    const s1SoftV2LateGuard =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1';
    const s1SoftV2LateGuardV2 =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v2';
    const threeBand =
        'base_score_curve_v2_boss_constraint_pool_v4_three_band_v1';
    const midGate = 'base_score_curve_v2_boss_constraint_pool_v4_mid_gate_v1';
    const lateGate = 'base_score_curve_v2_boss_constraint_pool_v4_late_gate_v1';

    expect(multiplierFor(threeBand, 1, 'small'), 0.95);
    expect(multiplierFor(threeBand, 1, 'big'), 0.70);
    expect(multiplierFor(threeBand, 1, 'boss'), 0.52);
    expect(multiplierFor(s1SoftV2LateGuard, 1, 'small'), 0.95);
    expect(multiplierFor(s1SoftV2LateGuard, 1, 'big'), 0.70);
    expect(multiplierFor(s1SoftV2LateGuard, 1, 'boss'), 0.52);
    expect(multiplierFor(s1SoftV2LateGuardV2, 1, 'small'), 0.95);
    expect(multiplierFor(s1SoftV2LateGuardV2, 1, 'big'), 0.70);
    expect(multiplierFor(s1SoftV2LateGuardV2, 1, 'boss'), 0.52);

    expect(multiplierFor(s1SoftV2, 3, 'boss'), 0.65);
    expect(multiplierFor(s1SoftV2LateGuard, 3, 'boss'), 0.65);
    expect(multiplierFor(s1SoftV2LateGuardV2, 3, 'boss'), 0.65);
    expect(multiplierFor(threeBand, 3, 'boss'), 0.70);
    expect(multiplierFor(midGate, 3, 'small'), 1.14);
    expect(multiplierFor(midGate, 3, 'big'), 0.92);
    expect(multiplierFor(midGate, 3, 'boss'), 0.74);

    expect(multiplierFor(threeBand, 6, 'small'), 1.14);
    expect(multiplierFor(threeBand, 6, 'big'), 0.92);
    expect(multiplierFor(threeBand, 6, 'boss'), 0.76);
    expect(multiplierFor(s1SoftV2LateGuard, 6, 'small'), 1.12);
    expect(multiplierFor(s1SoftV2LateGuard, 6, 'big'), 0.90);
    expect(multiplierFor(s1SoftV2LateGuard, 6, 'boss'), 0.74);
    expect(multiplierFor(s1SoftV2LateGuardV2, 6, 'small'), 1.08);
    expect(multiplierFor(s1SoftV2LateGuardV2, 6, 'big'), 0.88);
    expect(multiplierFor(s1SoftV2LateGuardV2, 6, 'boss'), 0.74);
    expect(
      rowFor(s1SoftV2LateGuard, 6, 'boss')['target_score'],
      greaterThan(rowFor(s1SoftV2, 6, 'boss')['target_score']),
    );
    expect(multiplierFor(lateGate, 6, 'small'), 1.18);
    expect(multiplierFor(lateGate, 6, 'big'), 0.96);
    expect(multiplierFor(lateGate, 6, 'boss'), 0.80);
    expect(
      rowFor(lateGate, 6, 'boss')['target_score'],
      greaterThan(rowFor(threeBand, 6, 'boss')['target_score']),
    );
  });

  test('CLI applies v64 late boss target and resource variants', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/v64_late_boss_variants.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '4,5,8',
      '--blind-tiers',
      'big,boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      [
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1',
      ].join(','),
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    Map<String, dynamic> rowFor(
      String experimentId,
      int station,
      String tier,
    ) => rows.singleWhere(
      (row) =>
          row['experiment_id'] == experimentId &&
          row['station'] == station &&
          row['blind_tier'] == tier,
    );

    const base =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3';
    const target070 =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070';
    const target068 =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068';
    const resource =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_resource_1';
    const target070Resource =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1';

    final baseS5Boss = rowFor(base, 5, 'boss');
    final target070S5Boss = rowFor(target070, 5, 'boss');
    final baseS8Boss = rowFor(base, 8, 'boss');
    final target070S8Boss = rowFor(target070, 8, 'boss');
    final target068S8Boss = rowFor(target068, 8, 'boss');
    final resourceS5Boss = rowFor(resource, 5, 'boss');
    final target070ResourceS5Boss = rowFor(target070Resource, 5, 'boss');
    final target070S4Boss = rowFor(target070, 4, 'boss');
    final target070S5Big = rowFor(target070, 5, 'big');

    expect(
      (target070S5Boss['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      (baseS5Boss['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
    );
    expect(
      (target070S8Boss['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.70,
    );
    expect(
      (target068S8Boss['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      0.68,
    );
    expect(
      target068S8Boss['target_score'] as int,
      lessThan(target070S8Boss['target_score'] as int),
    );
    expect(
      target070S8Boss['target_score'] as int,
      lessThan(baseS8Boss['target_score'] as int),
    );
    expect(
      (target070S4Boss['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
      (rowFor(base, 4, 'boss')['experiment_effects']
          as Map<String, dynamic>)['target_score_multiplier'],
    );
    expect(
      target070S5Big['target_score'],
      rowFor(base, 5, 'big')['target_score'],
    );

    final baseStart = baseS5Boss['start_state'] as Map<String, dynamic>;
    final resourceStart = resourceS5Boss['start_state'] as Map<String, dynamic>;
    final targetResourceStart =
        target070ResourceS5Boss['start_state'] as Map<String, dynamic>;
    final resourceEffects =
        resourceS5Boss['experiment_effects'] as Map<String, dynamic>;

    expect(resourceEffects['board_discards_delta'], 1);
    expect(resourceEffects['hand_discards_delta'], 1);
    expect(resourceEffects['max_hand_size_delta'], 1);
    expect(
      resourceStart['board_discards'] as int,
      (baseStart['board_discards'] as int) + 1,
    );
    expect(
      resourceStart['hand_discards'] as int,
      (baseStart['hand_discards'] as int) + 1,
    );
    expect(
      resourceStart['max_hand_size'] as int,
      (baseStart['max_hand_size'] as int) + 1,
    );
    expect(
      target070ResourceS5Boss['target_score'],
      target070S5Boss['target_score'],
    );
    expect(
      targetResourceStart['max_hand_size'] as int,
      (baseStart['max_hand_size'] as int) + 1,
    );
  });

  test('CLI applies v65 early and mid boss variants on v64 best', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/v65_early_mid_variants.jsonl';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '42',
      '--stations',
      '1,4,8',
      '--blind-tiers',
      'boss',
      '--difficulty',
      'standard',
      '--experiment-ids',
      [
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_boss_050',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_060',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_resource_1',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_050_s4_060_resource_1',
      ].join(','),
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final rows = File(outPath)
        .readAsLinesSync()
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    Map<String, dynamic> rowFor(String experimentId, int station) =>
        rows.singleWhere(
          (row) =>
              row['experiment_id'] == experimentId && row['station'] == station,
        );

    const base =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1';
    const s1 =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_boss_050';
    const s4 =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_060';
    const s4Resource =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s4_boss_resource_1';
    const combo =
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_070_resource_1_early_mid_s1_050_s4_060_resource_1';

    Map<String, dynamic> effects(String experimentId, int station) =>
        rowFor(experimentId, station)['experiment_effects']
            as Map<String, dynamic>;
    Map<String, dynamic> start(String experimentId, int station) =>
        rowFor(experimentId, station)['start_state'] as Map<String, dynamic>;

    expect(effects(s1, 1)['target_score_multiplier'], 0.50);
    expect(effects(s4, 4)['target_score_multiplier'], 0.60);
    expect(effects(combo, 1)['target_score_multiplier'], 0.50);
    expect(effects(combo, 4)['target_score_multiplier'], 0.60);
    expect(effects(combo, 8)['target_score_multiplier'], 0.70);
    expect(effects(s4Resource, 4)['board_discards_delta'], 1);
    expect(effects(combo, 4)['max_hand_size_delta'], 1);
    expect(
      start(combo, 4)['max_hand_size'] as int,
      (start(base, 4)['max_hand_size'] as int) + 1,
    );
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
    expect(summary['sequence_run_count'], 0);
    expect(summary['group_by'], [
      'experiment_id',
      'market_profile',
      'resolved_market_profile',
      'loadout_id',
      'station',
      'blind_tier',
      'difficulty',
      'sim_boss_constraint_id',
    ]);
    expect(summary['sequence_group_by'], [
      'experiment_id',
      'market_profile',
      'resolved_market_profile',
      'loadout_id',
      'difficulty',
      'station_path',
      'tier_path',
    ]);
    expect(summary['sequence_groups'], isEmpty);
    expect(groups, hasLength(2));

    final baseline = groups.cast<Map<String, dynamic>>().singleWhere(
      (group) => group['loadout_id'] == 'baseline',
    );
    final pairMult = groups.cast<Map<String, dynamic>>().singleWhere(
      (group) => group['loadout_id'] == 'pair_mult',
    );

    expect(baseline['run_count'], 2);
    expect(pairMult['run_count'], 2);
    expect(baseline['experiment_id'], 'baseline');
    expect(baseline['market_profile'], 'none');
    expect(baseline['resolved_market_profile'], 'none');
    expect(baseline['station'], 1);
    expect(baseline['blind_tier'], 'small');
    expect(baseline['difficulty'], 'standard');
    expect(baseline['clear_count'], isA<int>());
    expect(baseline['slow_clear_count'], isA<int>());
    expect(baseline['clear_rate'], isA<num>());
    expect(baseline['slow_clear_rate'], isA<num>());
    expect(baseline['slow_clear_share_of_clears'], isA<num>());
    expect(baseline['slow_clear_turn_threshold'], 130);
    expect(baseline['tempo_risk_label'], isA<String>());
    expect(baseline['ml_label_version'], 'ml_label_v1');
    expect(baseline['ml_labels'], isA<List<dynamic>>());
    expect(baseline['needs_balance_attention'], isA<bool>());
    expect(baseline['ml_label_v2_version'], 'ml_label_v2');
    expect(baseline['ml_target_labels_v2'], isA<Map<String, dynamic>>());
    expect(baseline['needs_balance_attention_v2'], isA<bool>());
    expect(baseline['avg_score_ratio'], isA<num>());
    expect(baseline['avg_turn_count'], isA<num>());
    expect(baseline['avg_confirm_action_count'], isA<num>());
    expect(baseline['avg_discarded_board_count'], isA<num>());
    expect(baseline['avg_max_single_confirm_score'], isA<num>());
    expect(baseline['scored_run_count'], isA<int>());
    expect(baseline['avg_first_score_turn'], anyOf(isNull, isA<num>()));
    expect(baseline['avg_last_score_turn'], anyOf(isNull, isA<num>()));
    expect(baseline['avg_remaining_deck'], isA<num>());
    expect(baseline['avg_remaining_hand_size'], isA<num>());
    expect(baseline['avg_remaining_board_discards'], isA<num>());
    expect(baseline['avg_remaining_hand_discards'], isA<num>());
    expect(baseline['avg_remaining_board_moves'], isA<num>());
    expect(baseline['avg_board_occupancy'], isA<num>());
    expect(baseline['outcome_counts'], isA<Map<String, dynamic>>());
    expect(baseline['clear_tempo_label_counts'], isA<Map<String, dynamic>>());
  });

  test('CLI summary keeps market profiles as explicit grouping keys', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/market_summary_source.jsonl';
    final summaryPath = '${dir.path}/market_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1',
      '--market-profile',
      'none',
      '--market-profile',
      's1_build_aware_pack_plus5',
      '--loadout-id',
      'baseline',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final marketProfiles = groups
        .map((group) => group['market_profile'] as String)
        .toSet();

    expect(marketProfiles, containsAll(['none', 's1_build_aware_pack_plus5']));
    expect(
      groups.where(
        (group) =>
            group['station'] == 1 &&
            group['blind_tier'] == 'small' &&
            group['market_profile'] == 's1_build_aware_pack_plus5',
      ),
      isNotEmpty,
    );
  });

  test('CLI summary records market shop slot appearance counts', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/market_slot_summary_source.jsonl';
    final summaryPath = '${dir.path}/market_slot_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '2',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '3',
      '--market-profile',
      'shop_slot_market_v10',
      '--loadout-id',
      'progression_route_delayed',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final battleGroups = groups.where(
      (group) =>
          group['market_profile'] == 'shop_slot_market_v10' &&
          group['station'] == 3,
    );

    expect(battleGroups, isNotEmpty);
    for (final group in battleGroups) {
      final slotCounts =
          group['market_shop_slot_counts'] as Map<String, dynamic>;
      expect(slotCounts, isNotEmpty);
      expect(
        slotCounts.keys.any(
          {
            's1_candidate_voucher_resource',
            's1_buy_discard_glove',
            's1_candidate_tarot_build_pack',
            's1_build_aware_pack_plus5',
            's1_tile_pack_plus5',
          }.contains,
        ),
        isTrue,
      );
    }
  });

  test(
    'CLI shop slot market v9 keeps final band shape proxies visible',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final outPath = '${dir.path}/market_v9_final_shape_source.jsonl';
      final summaryPath = '${dir.path}/market_v9_final_shape_summary.json';
      final code = await runBalanceSim([
        '--runs',
        '12',
        '--bot',
        'planner_v2',
        '--seed',
        '87200',
        '--sequence-mode',
        'station_path',
        '--stations',
        '7,8',
        '--experiment-id',
        'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068',
        '--market-profile',
        'shop_slot_market_v9',
        '--loadout-id',
        'progression_route_balanced',
        '--summary-out',
        summaryPath,
        '--out',
        outPath,
      ]);

      expect(code, 0);

      final summary =
          jsonDecode(File(summaryPath).readAsStringSync())
              as Map<String, dynamic>;
      final groups = (summary['groups'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final shapeProxyIds = {
        's1_candidate_tarot_build_pack',
        's1_build_aware_pack_plus5',
        's1_tile_pack_plus5',
      };
      final scoreBreakerIds = {
        's1_candidate_rare_xmult_jester',
        's1_candidate_planet_rank_level',
      };
      var shapeProxyAppearances = 0;
      var scoreBreakerAppearances = 0;

      for (final group in groups) {
        if (group['market_profile'] != 'shop_slot_market_v9') continue;
        final station = group['station'] as int;
        if (station < 7 || station > 8) continue;
        final slotCounts =
            group['market_shop_slot_counts'] as Map<String, dynamic>;
        for (final entry in slotCounts.entries) {
          final count = (entry.value as num).toInt();
          if (shapeProxyIds.contains(entry.key)) {
            shapeProxyAppearances += count;
          }
          if (scoreBreakerIds.contains(entry.key)) {
            scoreBreakerAppearances += count;
          }
        }
      }

      expect(shapeProxyAppearances, greaterThan(0));
      expect(scoreBreakerAppearances, greaterThan(shapeProxyAppearances));
    },
  );

  test('CLI summary records sequence path survival groups', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/sequence_path_summary_source.jsonl';
    final summaryPath = '${dir.path}/sequence_path_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '3',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1,2',
      '--market-profile',
      's1_build_aware_pack_plus5',
      '--loadout-id',
      's3_hand_growth_build',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final sequenceGroups = (summary['sequence_groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final sequenceGroup = sequenceGroups.single;

    expect(summary['sequence_run_count'], 3);
    expect(sequenceGroup['market_profile'], 's1_build_aware_pack_plus5');
    expect(sequenceGroup['resolved_market_profile'], isA<String>());
    expect(sequenceGroup['loadout_id'], 's3_hand_growth_build');
    expect(sequenceGroup['station_path'], [1, 2]);
    expect(sequenceGroup['tier_path'], ['small', 'big', 'boss']);
    expect(sequenceGroup['run_count'], 3);
    expect(sequenceGroup['path_clear_count'], isA<int>());
    expect(sequenceGroup['path_clear_rate'], isA<num>());
    expect(sequenceGroup['avg_attempted_step_count'], isA<num>());
    expect(sequenceGroup['avg_cleared_step_count'], isA<num>());
    expect(sequenceGroup['avg_total_turn_count'], isA<num>());
    expect(sequenceGroup['avg_clear_path_turn_count'], isA<num>());
    expect(sequenceGroup['avg_failed_path_turn_count'], isA<num>());
    expect(sequenceGroup['avg_turn_per_attempted_step'], isA<num>());
    expect(sequenceGroup['avg_turn_per_cleared_step'], isA<num>());
    expect(sequenceGroup['avg_total_score_ratio'], isA<num>());
    expect(sequenceGroup['failure_counts'], isA<Map<String, dynamic>>());
    expect(
      sequenceGroup['failure_stop_reason_counts'],
      isA<Map<String, dynamic>>(),
    );
  });

  test('CLI summary records planner v2 play-feel signals', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/planner_v2_quality_source.jsonl';
    final summaryPath = '${dir.path}/planner_v2_quality_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '2',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,big,boss',
      '--difficulties',
      'relaxed,standard,pressure',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);
    expect(File(outPath).readAsLinesSync(), hasLength(36));

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(summary['run_count'], 36);
    expect(groups, hasLength(18));
    expect(groups.any((group) => (group['clear_count'] as int) > 0), isTrue);
    expect(
      groups.any(
        (group) => (group['avg_max_single_confirm_score'] as num) >= 100,
      ),
      isTrue,
    );
    expect(
      groups.any((group) => (group['avg_last_score_turn'] as num?) != null),
      isTrue,
    );

    for (final group in groups) {
      expect(group['slow_clear_count'], isA<int>());
      expect(group['slow_clear_rate'], isA<num>());
      expect(group['slow_clear_share_of_clears'], isA<num>());
      expect(group['slow_clear_turn_threshold'], 130);
      expect(group['tempo_risk_label'], isA<String>());
      expect(group['ml_label_version'], 'ml_label_v1');
      expect(group['ml_labels'], isA<List<dynamic>>());
      expect(group['needs_balance_attention'], isA<bool>());
      expect(group['ml_label_v2_version'], 'ml_label_v2');
      expect(group['ml_target_labels_v2'], isA<Map<String, dynamic>>());
      expect(group['needs_balance_attention_v2'], isA<bool>());
      expect(group['avg_confirm_action_count'], isA<num>());
      expect(group['avg_discarded_board_count'], isA<num>());
      expect(group['avg_max_single_confirm_score'], isA<num>());
      expect(group['scored_run_count'], isA<int>());
      expect(group['avg_first_score_turn'], anyOf(isNull, isA<num>()));
      expect(group['avg_last_score_turn'], anyOf(isNull, isA<num>()));
      expect(group['avg_remaining_deck'], isA<num>());
      expect(group['avg_remaining_board_discards'], isA<num>());
      expect(group['avg_remaining_hand_discards'], isA<num>());
      expect(group['avg_remaining_board_moves'], isA<num>());
      expect(group['avg_board_occupancy'], isA<num>());
      expect(group['clear_tempo_label_counts'], isA<Map<String, dynamic>>());
    }
  });

  test('CLI summary assigns ML label v1 for balance interpretation', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/ml_label_source.jsonl';
    final summaryPath = '${dir.path}/ml_label_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '8',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,big,boss',
      '--difficulties',
      'standard,pressure',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      'pair_mult',
      '--loadout-id',
      'safety_item',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final labelSets = groups
        .map((group) => (group['ml_labels'] as List<dynamic>).cast<String>())
        .toList();

    expect(labelSets.any((labels) => labels.contains('too_hard')), isTrue);
    expect(labelSets.any((labels) => labels.contains('spiky_fun')), isTrue);
    expect(labelSets.any((labels) => labels.contains('tempo_drag')), isTrue);
    expect(
      groups.any((group) => group['needs_balance_attention'] == true),
      isTrue,
    );

    final tempoDragGroups = groups.where(
      (group) => ((group['ml_labels'] as List<dynamic>).cast<String>())
          .contains('tempo_drag'),
    );
    for (final group in tempoDragGroups) {
      final labels = (group['ml_labels'] as List<dynamic>).cast<String>();
      expect(labels, isNot(contains('good_playfeel')));
      expect(labels, contains('needs_balance_attention'));
    }
  });

  test('CLI summary assigns ML label v2 target diagnostics', () async {
    final dir = Directory.systemTemp.createTempSync('balance_sim_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/ml_label_v2_source.jsonl';
    final summaryPath = '${dir.path}/ml_label_v2_summary.json';
    final code = await runBalanceSim([
      '--runs',
      '8',
      '--bot',
      'planner_v2',
      '--seed',
      '42',
      '--stations',
      '1,2',
      '--blind-tiers',
      'small,big,boss',
      '--difficulty',
      'standard',
      '--loadout-id',
      'baseline',
      '--loadout-id',
      's1_entry_bridge_build',
      '--loadout-id',
      's2_foundation_build',
      '--summary-out',
      summaryPath,
      '--out',
      outPath,
    ]);

    expect(code, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(groups, isNotEmpty);
    for (final group in groups) {
      final labels = group['ml_target_labels_v2'] as Map<String, dynamic>;
      expect(group['ml_label_v2_version'], 'ml_label_v2');
      expect(
        labels.keys,
        containsAll([
          'difficulty',
          'tempo',
          'resource_pressure',
          'score_spike',
          'decision_density',
        ]),
      );
      expect(labels['difficulty'], isA<String>());
      expect(labels['tempo'], isA<String>());
      expect(labels['resource_pressure'], isA<String>());
      expect(labels['score_spike'], isA<String>());
      expect(labels['decision_density'], isA<String>());
      expect(group['needs_balance_attention_v2'], isA<bool>());
    }

    expect(
      groups.any(
        (group) =>
            (group['ml_target_labels_v2']
                as Map<String, dynamic>)['difficulty'] ==
            'too_hard',
      ),
      isTrue,
    );
    expect(
      groups.any(
        (group) =>
            (group['ml_target_labels_v2']
                as Map<String, dynamic>)['score_spike'] !=
            'spike_flat',
      ),
      isTrue,
    );
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
    'row_type',
    'sim_id',
    'run_id',
    'matrix_index',
    'matrix_size',
    'experiment_id',
    'experiment_applied',
    'experiment_effects',
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
    'base_target_score',
    'turn_cap',
    'start_state',
    'loadout_summary',
    'result',
  ];
  for (final field in requiredTopLevelFields) {
    expect(row, contains(field), reason: 'missing top-level field $field');
  }

  expect(row['schema_version'], 1);
  expect(row['row_type'], 'battle');
  expect(row['sim_id'], isA<String>());
  expect(row['run_id'], isA<String>());
  expect(row['matrix_index'], isA<int>());
  expect(row['matrix_size'], isA<int>());
  expect(row['experiment_id'], isA<String>());
  expect(row['experiment_applied'], isA<bool>());
  expect(row['experiment_effects'], isA<Map<String, dynamic>>());
  expect(row['loadout_effects'], isA<Map<String, dynamic>>());
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
  expect(row['base_target_score'], isA<int>());
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
    'max_hand_size',
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
  expect(startState['max_hand_size'], isA<int>());
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
    'clear_tempo_label',
    'is_slow_clear',
    'slow_clear_turn_threshold',
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
  expect(result['clear_tempo_label'], isA<String>());
  expect(result['is_slow_clear'], isA<bool>());
  expect(result['slow_clear_turn_threshold'], 130);
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
