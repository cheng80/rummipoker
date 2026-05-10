import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/run_balance_sim.dart';

void main() {
  test(
    'economy choice comparison probe writes summary matrix',
    () async {
      const outDir = 'logs/sim/economy_choice_comparison_20260511_r20';
      final rows = <Map<String, Object?>>[];

      for (final bot in const ['planner_v2', 'contest_policy_v1']) {
        for (final difficulty in const ['standard', 'challenge']) {
          for (final choiceMode in const [
            'none',
            'affordable_alternative_v1',
            'affordable_alternative_v2',
          ]) {
            final id = '${bot}_${difficulty}_$choiceMode';
            final outPath = '$outDir/$id.jsonl';
            final summaryPath = '$outDir/${id}_summary.json';
            if (!File(summaryPath).existsSync()) {
              final code = await runBalanceSim([
                '--runs',
                '20',
                '--bot',
                bot,
                '--seed',
                '92300',
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
                choiceMode,
                '--loadout-id',
                'progression_route_power',
                '--summary-out',
                summaryPath,
                '--out',
                outPath,
              ]);

              expect(code, 0);
            }
            rows.add(_readSequenceSummary(outPath));
          }
        }
      }

      final summaryOut = File('$outDir/summary_matrix.json');
      summaryOut.parent.createSync(recursive: true);
      summaryOut.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(rows),
      );
      summaryOut.writeAsStringSync('\n', mode: FileMode.append);

      expect(rows.length, 12);
    },
    timeout: const Timeout(Duration(minutes: 40)),
    skip: 'Manual long-running leveling probe; use only when refreshing docs.',
  );
}

Map<String, Object?> _readSequenceSummary(String path) {
  final summaries = File(path)
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .where((row) => row['row_type'] == 'sequence_summary')
      .toList(growable: false);
  final attempted = summaries.fold<int>(
    0,
    (sum, row) => sum + (row['attempted_step_count'] as num).toInt(),
  );
  final clearedSteps = summaries.fold<int>(
    0,
    (sum, row) => sum + (row['cleared_step_count'] as num).toInt(),
  );
  final clearedPaths = summaries
      .where((row) => row['path_cleared'] == true)
      .length;
  final economyRows = summaries
      .map((row) => row['sim_economy_summary'])
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList(growable: false);
  final unaffordable = economyRows.fold<int>(
    0,
    (sum, row) => sum + (row['unaffordable_event_count'] as num).toInt(),
  );
  final finalGold = economyRows
      .map((row) => (row['final_gold'] as num).toDouble())
      .toList(growable: false);
  final first = summaries.first;
  return <String, Object?>{
    'bot_policy': first['bot_policy'],
    'difficulty': first['difficulty'],
    'market_choice_mode': economyRows.first['market_choice_mode'],
    'run_count': summaries.length,
    'path_clear_rate': clearedPaths / summaries.length,
    'step_clear_rate': attempted == 0 ? 0 : clearedSteps / attempted,
    'unaffordable_event_count': unaffordable,
    'final_gold_avg': _avg(finalGold),
    'failed_at': [
      for (final row in summaries.where((row) => row['path_cleared'] != true))
        '${row['failed_at_station']}:${row['failed_at_tier']}',
    ],
  };
}

double _avg(List<double> values) {
  if (values.isEmpty) return 0;
  final sum = values.fold<double>(0, (total, value) => total + value);
  return double.parse((sum / values.length).toStringAsFixed(2));
}
