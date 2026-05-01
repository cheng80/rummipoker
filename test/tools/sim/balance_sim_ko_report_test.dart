import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Korean Python report writes markdown and guards chart font setup',
    () async {
      final pythonCheck = await Process.run('python3', ['--version']);
      if (pythonCheck.exitCode != 0) {
        markTestSkipped('python3 is not available in this environment');
        return;
      }

      final script = File('tools/sim/report_balance_summary_ko.py');
      final source = script.readAsStringSync();
      expect(source, contains('axes.unicode_minus'));
      expect(source, contains('AppleGothic'));
      expect(source, contains('NanumGothic'));
      expect(source, contains('Noto Sans KR'));
      expect(source, contains('![{title}]'));

      final dir = Directory.systemTemp.createTempSync(
        'balance_ko_report_test_',
      );
      addTearDown(() => dir.deleteSync(recursive: true));

      final summaryPath = '${dir.path}/planner_v2_summary.json';
      File(summaryPath).writeAsStringSync(
        jsonEncode({
          'schema_version': 1,
          'source_path': 'planner_v2.jsonl',
          'run_count': 4,
          'group_by': ['loadout_id', 'station', 'blind_tier', 'difficulty'],
          'groups': [
            {
              'loadout_id': 'baseline',
              'station': 1,
              'blind_tier': 'small',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 2,
              'clear_rate': 1.0,
              'avg_turn_count': 61.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 106.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 40.0,
              'avg_last_score_turn': 60.0,
              'outcome_counts': {'clear': 2},
            },
            {
              'loadout_id': 'baseline',
              'station': 1,
              'blind_tier': 'boss',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 0,
              'clear_rate': 0.0,
              'avg_turn_count': 109.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 90.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 40.0,
              'avg_last_score_turn': 102.0,
              'outcome_counts': {'deck_exhausted': 2},
            },
            {
              'loadout_id': 'pair_mult',
              'station': 1,
              'blind_tier': 'small',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 2,
              'clear_rate': 1.0,
              'avg_turn_count': 65.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 120.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 30.0,
              'avg_last_score_turn': 64.0,
              'outcome_counts': {'clear': 2},
            },
            {
              'loadout_id': 'pair_mult',
              'station': 1,
              'blind_tier': 'big',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 2,
              'clear_rate': 1.0,
              'avg_turn_count': 80.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 125.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 32.0,
              'avg_last_score_turn': 79.0,
              'outcome_counts': {'clear': 2},
            },
            {
              'loadout_id': 'pair_mult',
              'station': 1,
              'blind_tier': 'boss',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 0,
              'clear_rate': 0.0,
              'avg_turn_count': 107.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 110.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 38.0,
              'avg_last_score_turn': 101.0,
              'outcome_counts': {'deck_exhausted': 2},
            },
            {
              'loadout_id': 'safety_item',
              'station': 2,
              'blind_tier': 'big',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 1,
              'slow_clear_count': 1,
              'clear_rate': 0.5,
              'slow_clear_rate': 0.5,
              'slow_clear_share_of_clears': 1.0,
              'slow_clear_turn_threshold': 130,
              'tempo_risk_label': 'clear_but_too_slow',
              'avg_turn_count': 156.0,
              'avg_discarded_board_count': 1.0,
              'avg_max_single_confirm_score': 116.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 40.0,
              'avg_last_score_turn': 151.0,
              'outcome_counts': {'clear': 1, 'board_locked': 1},
              'clear_tempo_label_counts': {'clear_slow': 1, 'not_cleared': 1},
            },
            {
              'loadout_id': 'mobility_item',
              'station': 1,
              'blind_tier': 'small',
              'difficulty': 'standard',
              'run_count': 2,
              'clear_count': 2,
              'clear_rate': 1.0,
              'avg_turn_count': 62.0,
              'avg_discarded_board_count': 0.0,
              'avg_max_single_confirm_score': 108.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 35.0,
              'avg_last_score_turn': 61.0,
              'outcome_counts': {'clear': 2},
            },
            {
              'loadout_id': 'baseline',
              'station': 2,
              'blind_tier': 'boss',
              'difficulty': 'pressure',
              'run_count': 2,
              'clear_count': 0,
              'clear_rate': 0.0,
              'avg_turn_count': 109.0,
              'avg_discarded_board_count': 1.0,
              'avg_max_single_confirm_score': 102.0,
              'scored_run_count': 2,
              'avg_first_score_turn': 45.0,
              'avg_last_score_turn': 92.0,
              'outcome_counts': {'deck_exhausted': 2},
            },
          ],
        }),
      );

      final result = await Process.run('python3', [
        script.path,
        summaryPath,
        '--out-dir',
        dir.path,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final report = File('${dir.path}/planner_v2_summary_report.md');
      expect(report.existsSync(), true);

      final markdown = report.readAsStringSync();
      expect(markdown, contains('# 밸런스 시뮬레이션 요약'));
      expect(markdown, contains('## 한줄 해석'));
      expect(markdown, contains('## 위험 구간'));
      expect(markdown, contains('## 느린 클리어'));
      expect(markdown, contains('## 재미 신호'));
      expect(markdown, contains('## 유입/조합 기준 평가'));
      expect(markdown, contains('## 차트'));
      expect(markdown, contains('## 상세 표'));
      if (!markdown.contains('matplotlib이 없어')) {
        expect(markdown, contains('![클리어율 차트]'));
        expect(markdown, contains('![평균 턴 차트]'));
        expect(markdown, contains('![평균 큰 한방 차트]'));
      }
      expect(markdown, contains('클리어율 높음'));
      expect(markdown, contains('덱 소진'));
      expect(markdown, contains('큰 한방'));
      expect(markdown, contains('클리어는 되지만 너무 느림'));
      expect(markdown, contains('느린 클리어 1/1'));
      expect(markdown, contains('후반 점수는 있으나 템포 위험'));
      expect(markdown, contains('느린 클리어 위험 1개'));
      expect(markdown, contains('최소 Jester 유입: 안정권'));
      expect(markdown, contains('첫 Boss 벽: 너무 높습니다'));
      expect(markdown, contains('무장해제 기준: 초반 유입과 build 필요성'));
      expect(markdown, contains('Safety Item 템포: 늘어짐 위험'));
      expect(markdown, contains('Mobility Item 가치: 약합니다'));
    },
  );

  test(
    'Korean Python report returns readable error for malformed summary',
    () async {
      final pythonCheck = await Process.run('python3', ['--version']);
      if (pythonCheck.exitCode != 0) {
        markTestSkipped('python3 is not available in this environment');
        return;
      }

      final dir = Directory.systemTemp.createTempSync(
        'balance_ko_report_test_',
      );
      addTearDown(() => dir.deleteSync(recursive: true));

      final summaryPath = '${dir.path}/bad_summary.json';
      File(summaryPath).writeAsStringSync(jsonEncode({'groups': 'bad'}));

      final result = await Process.run('python3', [
        'tools/sim/report_balance_summary_ko.py',
        summaryPath,
        '--out-dir',
        dir.path,
      ]);

      expect(result.exitCode, 64);
      expect(result.stderr.toString(), contains('오류:'));
      expect(result.stderr.toString(), contains('groups list'));
    },
  );
}
