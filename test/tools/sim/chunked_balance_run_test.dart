import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/run_balance_sim.dart';
import '../../../tools/sim/summarize_balance_jsonl.dart';

void main() {
  test('summarizeBalanceJsonl rebuilds summary from raw rows', () async {
    final dir = Directory.systemTemp.createTempSync('balance_summary_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPath = '${dir.path}/raw.jsonl';
    final summaryPath = '${dir.path}/summary.json';
    final code = await runBalanceSim([
      '--runs',
      '1',
      '--bot',
      'greedy_v1',
      '--seed',
      '101',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1',
      '--difficulty',
      'standard',
      '--experiment-id',
      'station_curve_125',
      '--market-profile',
      'none',
      '--loadout-id',
      's1_entry_bridge_build',
      '--out',
      outPath,
    ]);
    expect(code, 0);

    final summaryCode = await summarizeBalanceJsonl([
      outPath,
      '--out',
      summaryPath,
    ]);
    expect(summaryCode, 0);

    final summary =
        jsonDecode(File(summaryPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(summary['source_path'], outPath);
    expect(summary['run_count'], greaterThan(0));
    expect(summary['sequence_run_count'], 1);
    expect(summary['groups'], isA<List<dynamic>>());
    expect(summary['sequence_groups'], isA<List<dynamic>>());
  });

  test('chunked balance runner merges chunks and writes manifest', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('chunked_balance_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final outPrefix = '${dir.path}/chunked';
    final result = await Process.run('python3', [
      'tools/sim/chunked_balance_run.py',
      '--chunks',
      '2',
      '--runs-per-chunk',
      '1',
      '--seed',
      '202',
      '--out-prefix',
      outPrefix,
      '--dart',
      '/Users/cheng80/flutter/bin/dart',
      '--flush-every-rows',
      '1',
      '--',
      '--bot',
      'greedy_v1',
      '--sequence-mode',
      'station_path',
      '--stations',
      '1',
      '--difficulty',
      'standard',
      '--experiment-id',
      'station_curve_125',
      '--market-profile',
      'none',
      '--loadout-id',
      's1_entry_bridge_build',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('[chunked] start 1/2'));
    expect(result.stdout.toString(), contains('[chunked] complete chunks=2'));

    final mergedJsonl = File('$outPrefix.jsonl');
    final mergedSummary = File('${outPrefix}_summary.json');
    final manifest = File('${outPrefix}_manifest.json');
    expect(mergedJsonl.existsSync(), true);
    expect(mergedSummary.existsSync(), true);
    expect(manifest.existsSync(), true);

    final rows = mergedJsonl
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList(growable: false);
    expect(
      rows.where((row) => row['row_type'] == 'sequence_summary'),
      hasLength(2),
    );

    final summary =
        jsonDecode(mergedSummary.readAsStringSync()) as Map<String, dynamic>;
    expect(summary['sequence_run_count'], 2);

    final manifestJson =
        jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
    expect(manifestJson['complete'], true);
    expect(manifestJson['completed_chunks'], ['0000', '0001']);
  });
}
