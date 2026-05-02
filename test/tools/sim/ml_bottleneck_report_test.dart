import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ML bottleneck report summarizes station and loadout pressure', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_bottleneck_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final summaryPath = '${dir.path}/summary.json';
    final reportPath = '${dir.path}/bottleneck.md';
    File(summaryPath).writeAsStringSync(
      jsonEncode({
        'schema_version': 1,
        'source_path': null,
        'run_count': 600,
        'group_by': [
          'experiment_id',
          'loadout_id',
          'station',
          'blind_tier',
          'difficulty',
        ],
        'groups': [
          _group(
            experimentId: 'sweep_experiment_station_curve_125',
            experimentMatrixId: 'station_curve_125',
            loadoutId: 'baseline__s1_buy_sly',
            station: 5,
            tier: 'small',
            runCount: 300,
            clearRate: 0.10,
            deckExhausted: 240,
            boardLocked: 20,
            maxHit: 92,
            scoreRatio: 0.55,
            attention: true,
          ),
          _group(
            experimentId: 'sweep_experiment_s2_boss_resource_boost',
            experimentMatrixId: 's2_boss_resource_boost',
            loadoutId: 's6_boss_breaker_build__s1_buy_discard_glove',
            station: 6,
            tier: 'boss',
            runCount: 300,
            clearRate: 0.75,
            deckExhausted: 60,
            boardLocked: 10,
            maxHit: 210,
            scoreRatio: 1.03,
            attention: false,
          ),
        ],
      }),
    );

    final result = await Process.run('python3', [
      'tools/sim/ml_bottleneck_report.py',
      summaryPath,
      '--out',
      reportPath,
      '--stations',
      '5,6',
      '--top-n',
      '5',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('병목 리포트:'));

    final markdown = File(reportPath).readAsStringSync();
    expect(markdown, contains('# ML 병목 분해 리포트'));
    expect(markdown, contains('## 한줄 판정'));
    expect(markdown, contains('덱 고갈'));
    expect(markdown, contains('## Experiment 비교'));
    expect(markdown, contains('`station_curve_125`'));
    expect(markdown, contains('## Station/Tier 비교'));
    expect(markdown, contains('`S5 small`'));
    expect(markdown, contains('## Loadout 비교'));
    expect(markdown, contains('baseline__s1_buy_sly'));
    expect(markdown, contains('## Market 비교'));
    expect(markdown, contains('s1_buy_sly'));
    expect(markdown, contains('## 다음 액션'));
  });
}

Map<String, dynamic> _group({
  required String experimentId,
  required String experimentMatrixId,
  required String loadoutId,
  required int station,
  required String tier,
  required int runCount,
  required double clearRate,
  required int deckExhausted,
  required int boardLocked,
  required int maxHit,
  required double scoreRatio,
  required bool attention,
}) {
  final clearCount = (runCount * clearRate).round();
  return {
    'experiment_id': experimentId,
    'experiment_matrix_id': experimentMatrixId,
    'loadout_id': loadoutId,
    'station': station,
    'blind_tier': tier,
    'difficulty': 'standard',
    'run_count': runCount,
    'clear_count': clearCount,
    'clear_rate': clearRate,
    'avg_score_ratio': scoreRatio,
    'avg_turn_count': attention ? 113.0 : 91.0,
    'avg_confirm_action_count': 4.0,
    'avg_max_single_confirm_score': maxHit,
    'avg_remaining_deck': attention ? 0.2 : 5.0,
    'needs_balance_attention_v2': attention,
    'ml_target_labels_v2': {
      'difficulty': attention ? 'too_hard' : 'difficulty_ok',
      'tempo': 'tempo_ok',
      'resource_pressure': attention ? 'deck_pressure_high' : 'resource_ok',
      'score_spike': 'spike_ok',
      'decision_density': 'agency_ok',
    },
    'outcome_counts': {
      'clear': clearCount,
      'deck_exhausted': deckExhausted,
      'board_locked': boardLocked,
    },
  };
}
