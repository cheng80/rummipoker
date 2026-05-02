import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ML sweep dataset preserves boss package metadata', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_sweep_dataset_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPrefix = '${dir.path}/sweep';
    final result = await Process.run('python3', [
      'tools/sim/ml_sweep_dataset.py',
      '--mode',
      'boss_package',
      '--runs',
      '1',
      '--seed',
      '77',
      '--bot',
      'greedy_v1',
      '--stations',
      '1',
      '--difficulty',
      'standard',
      '--experiment-id',
      'station_curve_125',
      '--loadout-id',
      's1_entry_bridge_build',
      '--market-profile',
      's1_buy_sly',
      '--packages',
      '0.75:0.80:0.80',
      '--out-prefix',
      outPrefix,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('[sweep] start 1/1'));
    expect(result.stdout.toString(), contains('[sweep] done 1/1'));

    final jsonl = File('$outPrefix.jsonl');
    final summaryFile = File('${outPrefix}_summary.json');
    final report = File('${outPrefix}_report.md');
    expect(jsonl.existsSync(), true);
    expect(summaryFile.existsSync(), true);
    expect(report.existsSync(), true);

    final rows = jsonl
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
    expect(rows, isNotEmpty);
    expect(
      rows.every(
        (row) => row['experiment_id'] == 'sweep_s1_0p75_s2_0p8_s3_0p8',
      ),
      true,
    );
    expect(rows.first['s1_boss_target_multiplier'], 0.75);
    expect(rows.first['s2_boss_target_multiplier'], 0.8);
    expect(rows.first['s3_boss_target_multiplier'], 0.8);

    final summary =
        jsonDecode(summaryFile.readAsStringSync()) as Map<String, dynamic>;
    expect(summary['schema_version'], 1);
    expect(summary['source_path'], jsonl.path);
    expect(summary['sweep'], isA<Map<String, dynamic>>());
    expect((summary['sweep'] as Map<String, dynamic>)['candidate_count'], 1);
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(groups, isNotEmpty);
    expect(
      groups.every(
        (group) => group['experiment_id'] == 'sweep_s1_0p75_s2_0p8_s3_0p8',
      ),
      true,
    );
    expect(groups.first['sweep_candidate_id'], 's1_0p75_s2_0p8_s3_0p8');

    final markdown = report.readAsStringSync();
    expect(markdown, contains('# ML 레벨링 Sweep Dataset'));
    expect(markdown, contains('mode: `boss_package`'));
    expect(markdown, contains('sweep_s1_0p75_s2_0p8_s3_0p8'));
  });

  test('ML sweep dataset creates progression curve candidates', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_sweep_dataset_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPrefix = '${dir.path}/curve';
    final result = await Process.run('python3', [
      'tools/sim/ml_sweep_dataset.py',
      '--mode',
      'progression_curve',
      '--runs',
      '1',
      '--seed',
      '78',
      '--bot',
      'greedy_v1',
      '--stations',
      '1',
      '--difficulty',
      'standard',
      '--station-growth-experiments',
      'station_curve_125',
      '--loadout-ids',
      'baseline',
      '--market-profiles',
      'none',
      '--small-multipliers',
      '1.0',
      '--big-multipliers',
      '0.95',
      '--boss-multipliers',
      '0.85',
      '--out-prefix',
      outPrefix,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('[sweep] mode=progression_curve'));
    expect(result.stdout.toString(), contains('[sweep] merged candidates=1'));

    final summaryFile = File('${outPrefix}_summary.json');
    expect(summaryFile.existsSync(), true);
    final summary =
        jsonDecode(summaryFile.readAsStringSync()) as Map<String, dynamic>;
    expect((summary['sweep'] as Map<String, dynamic>)['kind'], 'progression_curve');
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(groups, isNotEmpty);
    expect(groups.first['sweep_mode'], 'progression_curve');
    expect(groups.first['station_growth_experiment_id'], 'station_curve_125');
    expect(groups.first['small_target_multiplier'], 1.0);
    expect(groups.first['big_target_multiplier'], 0.95);
    expect(groups.first['boss_target_multiplier'], 0.85);

    final report = File('${outPrefix}_report.md').readAsStringSync();
    expect(report, contains('mode: `progression_curve`'));
    expect(report, contains('v4_pacing_baseline_1'));
  });

  test('ML sweep dataset can keep only summary artifacts', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_sweep_dataset_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPrefix = '${dir.path}/summary_only';
    final result = await Process.run('python3', [
      'tools/sim/ml_sweep_dataset.py',
      '--mode',
      'progression_curve',
      '--runs',
      '1',
      '--seed',
      '79',
      '--bot',
      'greedy_v1',
      '--stations',
      '1',
      '--difficulty',
      'standard',
      '--station-growth-experiments',
      'station_curve_125',
      '--loadout-ids',
      'baseline',
      '--market-profiles',
      'none',
      '--small-multipliers',
      '1.0',
      '--big-multipliers',
      '1.0',
      '--boss-multipliers',
      '1.0',
      '--summary-only',
      '--out-prefix',
      outPrefix,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('Sweep JSONL: skipped'));
    expect(File('$outPrefix.jsonl').existsSync(), false);

    final summary =
        jsonDecode(File('${outPrefix}_summary.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(summary['source_path'], isNull);
    expect((summary['sweep'] as Map<String, dynamic>)['summary_only'], true);
    expect((summary['groups'] as List<dynamic>), isNotEmpty);
  });

  test('ML sweep dataset can compare experiment presets', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_sweep_dataset_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPrefix = '${dir.path}/experiment_matrix';
    final result = await Process.run('python3', [
      'tools/sim/ml_sweep_dataset.py',
      '--mode',
      'experiment_matrix',
      '--runs',
      '1',
      '--seed',
      '80',
      '--bot',
      'greedy_v1',
      '--stations',
      '2',
      '--difficulty',
      'standard',
      '--experiment-ids',
      'station_curve_125,s2_boss_resource_boost',
      '--loadout-ids',
      'baseline',
      '--market-profiles',
      'none',
      '--summary-only',
      '--out-prefix',
      outPrefix,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('[sweep] mode=experiment_matrix'));
    expect(result.stdout.toString(), contains('[sweep] merged candidates=2'));

    final summary =
        jsonDecode(File('${outPrefix}_summary.json').readAsStringSync())
            as Map<String, dynamic>;
    expect((summary['sweep'] as Map<String, dynamic>)['kind'], 'experiment_matrix');
    final groups = (summary['groups'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      groups.map((group) => group['experiment_matrix_id']).toSet(),
      containsAll(['station_curve_125', 's2_boss_resource_boost']),
    );
    expect(
      groups.map((group) => group['sweep_mode']).toSet(),
      {'experiment_matrix'},
    );
  });
}
