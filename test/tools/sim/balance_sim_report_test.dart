import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tools/sim/report_balance_summary.dart';

void main() {
  test(
    'report renders sorted balance summary rows with play-feel columns',
    () async {
      final dir = Directory.systemTemp.createTempSync('balance_report_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final summaryPath = '${dir.path}/summary.json';
      File(summaryPath).writeAsStringSync(
        jsonEncode({
          'schema_version': 1,
          'source_path': 'ignored.jsonl',
          'run_count': 4,
          'group_by': ['loadout_id', 'station', 'blind_tier', 'difficulty'],
          'groups': [
            {
              'loadout_id': 'pair_mult',
              'station': 2,
              'blind_tier': 'boss',
              'difficulty': 'challenge',
              'run_count': 2,
              'clear_count': 0,
              'clear_rate': 0,
              'avg_score_ratio': 0.72,
              'avg_turn_count': 108.25,
              'avg_confirm_action_count': 4.5,
              'avg_discarded_board_count': 1.75,
              'avg_max_single_confirm_score': 98.5,
              'scored_run_count': 2,
              'avg_first_score_turn': 43.0,
              'avg_last_score_turn': 91.5,
              'outcome_counts': {'deck_exhausted': 1, 'board_locked': 1},
            },
            {
              'loadout_id': 'baseline',
              'station': 1,
              'blind_tier': 'small',
              'difficulty': 'relaxed',
              'run_count': 2,
              'clear_count': 1,
              'clear_rate': 0.5,
              'avg_score_ratio': 1.02,
              'avg_turn_count': 64.0,
              'avg_confirm_action_count': 3.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 112.4,
              'scored_run_count': 2,
              'avg_first_score_turn': 31.0,
              'avg_last_score_turn': 70.1,
              'outcome_counts': {'clear': 1, 'deck_exhausted': 1},
            },
            {
              'loadout_id': 'baseline',
              'station': 1,
              'blind_tier': 'big',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 0,
              'clear_rate': 0,
              'avg_score_ratio': 0.0,
              'avg_turn_count': 3.0,
              'avg_confirm_action_count': 0.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 0.0,
              'scored_run_count': 0,
              'avg_first_score_turn': null,
              'avg_last_score_turn': null,
              'outcome_counts': {},
            },
          ],
        }),
      );

      final out = StringBuffer();
      final err = StringBuffer();
      final code = await reportBalanceSummary(
        [summaryPath],
        out: out,
        err: err,
      );

      expect(code, 0);
      expect(err.toString(), isEmpty);

      final lines = out.toString().trimRight().split('\n');
      expect(lines, hasLength(4));
      expect(
        lines.first,
        contains('loadout      station tier  diff      clear'),
      );
      expect(lines.first, contains('maxHit'));
      expect(lines.first, contains('discard'));
      expect(lines[1], contains('baseline'));
      expect(lines[1], contains('small'));
      expect(lines[1], contains('relaxed'));
      expect(lines[1], contains('50%'));
      expect(lines[1], contains('112.4'));
      expect(lines[1], contains('clear:1,deck_exhausted:1'));
      expect(lines[2], contains('big'));
      expect(lines[2], contains('standard'));
      expect(lines[2], contains(' - '));
      expect(lines[2], endsWith(' -'));
      expect(lines[3], contains('pair_mult'));
      expect(lines[3], contains('boss'));
      expect(lines[3], contains('board_locked:1,deck_exhausted:1'));
    },
  );

  test('report rejects malformed summary without throwing', () async {
    final dir = Directory.systemTemp.createTempSync('balance_report_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final summaryPath = '${dir.path}/summary.json';
    File(summaryPath).writeAsStringSync(jsonEncode({'groups': 'bad'}));

    final out = StringBuffer();
    final err = StringBuffer();
    final code = await reportBalanceSummary([summaryPath], out: out, err: err);

    expect(code, 64);
    expect(out.toString(), isEmpty);
    expect(err.toString(), contains('Summary JSON missing groups list'));
    expect(err.toString(), contains('Usage:'));
  });

  test('report rejects missing summary file without throwing', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await reportBalanceSummary(
      ['missing_summary.json'],
      out: out,
      err: err,
    );

    expect(code, 64);
    expect(out.toString(), isEmpty);
    expect(err.toString(), contains('Summary file not found'));
  });
}
