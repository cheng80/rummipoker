import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/run_balance_sim.dart';

void main() {
  test(
    'contest policy v1 clears standard S1-S8 path',
    () async {
      final paths = _SimPaths(
        out: 'logs/sim/contest_policy_v1_standard_20260511_053831.jsonl',
        summary:
            'logs/sim/contest_policy_v1_standard_20260511_053831_summary.json',
      );

      final code = await runBalanceSim(
        _contestPolicyArgs(difficulty: 'standard', paths: paths),
      );

      expect(code, 0);
      _expectPathCleared(paths.out);
    },
    skip: _legacyContestGateSkipReason,
  );

  test(
    'contest policy v1 clears challenge S1-S8 path',
    () async {
      final paths = _SimPaths(
        out: 'logs/sim/contest_policy_v1_challenge_20260511_053831.jsonl',
        summary:
            'logs/sim/contest_policy_v1_challenge_20260511_053831_summary.json',
      );

      final code = await runBalanceSim(
        _contestPolicyArgs(difficulty: 'challenge', paths: paths),
      );

      expect(code, 0);
      _expectPathCleared(paths.out);
    },
    skip: _legacyContestGateSkipReason,
  );
}

const _legacyContestGateSkipReason =
    'Legacy contest fixed-seed gate is archived after post-contest balance/data reset.';

List<String> _contestPolicyArgs({
  required String difficulty,
  required _SimPaths paths,
}) {
  return [
    '--runs',
    '1',
    '--bot',
    'contest_policy_v1',
    '--seed',
    '91460',
    '--sequence-mode',
    'station_path',
    '--stations',
    '1,2,3,4,5,6,7,8',
    '--difficulty',
    difficulty,
    '--experiment-id',
    'base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_s4_rank_weight_v1',
    '--market-profile',
    'shop_slot_market_v9',
    '--sim-economy-mode',
    'gated_known_cost',
    '--sim-reward-scale',
    '0.40',
    '--sim-price-scale',
    '2.2',
    '--sim-market-budget-mode',
    'station_band_v1',
    '--sim-market-spend-mode',
    'first_reroll_free_v1',
    '--sim-price-band-mode',
    'growth_access_v1',
    '--sim-market-choice-mode',
    'affordable_alternative_v2',
    '--loadout-id',
    'progression_route_power',
    '--summary-out',
    paths.summary,
    '--out',
    paths.out,
  ];
}

void _expectPathCleared(String outPath) {
  final rows = File(outPath)
      .readAsLinesSync()
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .toList(growable: false);
  final summary = rows.singleWhere(
    (row) => row['row_type'] == 'sequence_summary',
  );
  expect(summary['path_cleared'], isTrue);
  expect(summary['attempted_step_count'], 24);
  expect(summary['cleared_step_count'], 24);
  expect(summary['failed_at_station'], isNull);
  expect(summary['failed_at_tier'], isNull);
}

class _SimPaths {
  const _SimPaths({required this.out, required this.summary});

  final String out;
  final String summary;
}
