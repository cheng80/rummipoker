import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rule-based leveling report writes Korean markdown from summary JSON',
    () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_leveling_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final summaryPath = '${dir.path}/summary.json';
    File(summaryPath).writeAsStringSync(
      jsonEncode({
        'schema_version': 1,
        'source_path': 'source.jsonl',
        'run_count': 12,
        'group_by': ['loadout_id', 'station', 'blind_tier', 'difficulty'],
        'groups': [
          _group(
            loadoutId: 'pair_mult',
            station: 1,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.55,
            scoreRatio: 1.05,
            turns: 103.2,
            maxHit: 112.8,
            labels: ['spiky_fun', 'good_playfeel'],
          ),
          _group(
            loadoutId: 'safety_item',
            station: 2,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.60,
            scoreRatio: 1.01,
            turns: 170.7,
            maxHit: 115.0,
            slowShare: 1.0,
            tempoRisk: 'clear_but_too_slow',
            labels: ['tempo_drag', 'needs_balance_attention'],
            attention: true,
          ),
          _group(
            loadoutId: 'baseline',
            station: 2,
            tier: 'boss',
            difficulty: 'challenge',
            clearRate: 0.0,
            scoreRatio: 0.62,
            turns: 109.0,
            maxHit: 102.0,
            labels: ['too_hard', 'needs_balance_attention'],
            attention: true,
          ),
        ],
      }),
    );

    final result = await Process.run('python3', [
      'tools/sim/ml_leveling_report.py',
      summaryPath,
      '--out-dir',
      dir.path,
      '--goal',
      'tempo',
      '--top-n',
      '5',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final report = File('${dir.path}/summary_ml_insights_report.md');
    expect(report.existsSync(), true);

    final markdown = report.readAsStringSync();
    expect(markdown, contains('# 휴리스틱 레벨링 워크벤치 리포트'));
    expect(markdown, contains('레벨링 목표: `tempo`'));
    expect(markdown, contains('## 분석 방식'));
    expect(markdown, contains('train/test split'));
    expect(markdown, contains('leveling_loss'));
    expect(markdown, contains('## 휴리스틱 레벨링 워크벤치'));
    expect(markdown, contains('### 목표/타겟'));
    expect(markdown, contains('### 데이터 충분성'));
    expect(markdown, contains('### 분류 타겟 분포'));
    expect(markdown, contains('### 상관 관계'));
    expect(markdown, contains('### 모델 학습/검증'));
    expect(markdown, contains('### 분류 모델/오차행렬'));
    expect(markdown, contains('### 모델 기반 다음 액션'));
    expect(markdown, contains('leveling_class'));
    expect(markdown, contains('too_hard'));
    expect(markdown, contains('tempo_drag'));
    expect(markdown, contains('## Leveling Coach v1'));
    expect(markdown, contains('현재 등급'));
    expect(markdown, contains('가장 먼저 할 일'));
    expect(markdown, contains('근거'));
    expect(markdown, contains('## Label 분포'));
    expect(markdown, contains('## 실험별 비교'));
    expect(markdown, contains('## 기본 런 곡선 진단'));
    expect(markdown, contains('## Heuristic Target v2 진단'));
    expect(markdown, contains('difficulty `too_hard`'));
    expect(markdown, contains('resource `deck_pressure_high`'));
    expect(markdown, contains('## Good Playfeel 후보'));
    expect(markdown, contains('## Balance Attention 후보'));
    expect(markdown, contains('## Tempo Drag 분석'));
    expect(markdown, contains('## Decision Tree 설명 힌트'));
    expect(markdown, contains('pair_mult S1 boss standard'));
    expect(markdown, contains('safety_item S2 boss standard'));
    expect(markdown, contains('safety_item은 클리어 보조보다 전투 지연'));
    expect(markdown, contains('too_hard'));
    },
  );

  test('heuristic leveling report compares experiment presets by name', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_leveling_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final summaryPath = '${dir.path}/experiment_summary.json';
    File(summaryPath).writeAsStringSync(
      jsonEncode({
        'schema_version': 1,
        'source_path': 'source.jsonl',
        'run_count': 8,
        'group_by': [
          'experiment_id',
          'loadout_id',
          'station',
          'blind_tier',
          'difficulty',
        ],
        'groups': [
          _group(
            experimentId: 'baseline',
            loadoutId: 'baseline',
            station: 2,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.0,
            scoreRatio: 0.62,
            turns: 109.0,
            maxHit: 102.0,
            labels: ['too_hard', 'needs_balance_attention'],
            attention: true,
          ),
          _group(
            experimentId: 's2_boss_target_soften',
            loadoutId: 'baseline',
            station: 2,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.30,
            scoreRatio: 0.91,
            turns: 106.0,
            maxHit: 108.0,
            labels: ['too_hard', 'needs_balance_attention'],
            attention: true,
          ),
        ],
      }),
    );

    final result = await Process.run('python3', [
      'tools/sim/ml_leveling_report.py',
      summaryPath,
      '--out-dir',
      dir.path,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final markdown = File(
      '${dir.path}/experiment_summary_ml_insights_report.md',
    ).readAsStringSync();

    expect(markdown, contains('## 실험별 비교'));
    expect(markdown, contains('`s2_boss_target_soften`'));
    expect(markdown, contains('기준 baseline 대비 평균 clear 개선 후보'));
    expect(
      markdown,
      contains('s2_boss_target_soften baseline S2 boss standard'),
    );
  });

  test('heuristic leveling report summarizes station curve experiments', () async {
    final pythonCheck = await Process.run('python3', ['--version']);
    if (pythonCheck.exitCode != 0) {
      markTestSkipped('python3 is not available in this environment');
      return;
    }

    final dir = Directory.systemTemp.createTempSync('ml_leveling_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final summaryPath = '${dir.path}/curve_summary.json';
    File(summaryPath).writeAsStringSync(
      jsonEncode({
        'schema_version': 1,
        'source_path': 'source.jsonl',
        'run_count': 8,
        'group_by': [
          'experiment_id',
          'loadout_id',
          'station',
          'blind_tier',
          'difficulty',
        ],
        'groups': [
          _group(
            experimentId: 'baseline_curve_160',
            loadoutId: 'pair_mult',
            station: 1,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.50,
            scoreRatio: 1.0,
            turns: 100,
            maxHit: 120,
            labels: ['spiky_fun', 'good_playfeel'],
          ),
          _group(
            experimentId: 'station_curve_135',
            loadoutId: 'pair_mult',
            station: 2,
            tier: 'boss',
            difficulty: 'standard',
            clearRate: 0.35,
            scoreRatio: 0.95,
            turns: 110,
            maxHit: 125,
            labels: ['spiky_fun', 'good_playfeel'],
          ),
        ],
      }),
    );

    final result = await Process.run('python3', [
      'tools/sim/ml_leveling_report.py',
      summaryPath,
      '--out-dir',
      dir.path,
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    final markdown = File(
      '${dir.path}/curve_summary_ml_insights_report.md',
    ).readAsStringSync();

    expect(markdown, contains('## 기본 런 곡선 진단'));
    expect(markdown, contains('`baseline_curve_160`'));
    expect(markdown, contains('`station_curve_135`'));
    expect(markdown, contains('S1:'));
    expect(markdown, contains('S2:'));
  });

  test(
    'heuristic leveling report rejects malformed summary without throwing',
    () async {
      final pythonCheck = await Process.run('python3', ['--version']);
      if (pythonCheck.exitCode != 0) {
        markTestSkipped('python3 is not available in this environment');
        return;
      }

      final dir = Directory.systemTemp.createTempSync('ml_leveling_test_');
      addTearDown(() => dir.deleteSync(recursive: true));

      final summaryPath = '${dir.path}/bad.json';
      File(summaryPath).writeAsStringSync(jsonEncode({'groups': 'bad'}));

      final result = await Process.run('python3', [
        'tools/sim/ml_leveling_report.py',
        summaryPath,
        '--out-dir',
        dir.path,
      ]);

      expect(result.exitCode, 64);
      expect(result.stderr.toString(), contains('오류:'));
      expect(result.stderr.toString(), contains('groups list'));
    },
  );

  test('heuristic leveling notebook keeps a single editable options cell', () {
    final notebook = File('notebooks/sim_ml_leveling.ipynb');
    expect(notebook.existsSync(), true);

    final decoded =
        jsonDecode(notebook.readAsStringSync()) as Map<String, dynamic>;
    final cells = (decoded['cells'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final optionCells = cells.where((cell) {
      final source = (cell['source'] as List<dynamic>).join();
      return source.contains('EDIT_THIS_CELL = True');
    }).toList();

    expect(decoded['nbformat'], 4);
    expect(optionCells, hasLength(1));
    expect(cells.first['cell_type'], 'markdown');
    expect(
      cells.any(
        (cell) => (cell['source'] as List<dynamic>).join().contains(
          'pip", "install"',
        ),
      ),
      true,
    );
    expect(
      cells.any(
        (cell) => (cell['source'] as List<dynamic>).join().contains(
          'run_from_options',
        ),
      ),
      true,
    );
    expect(
      cells.any(
        (cell) => (cell['source'] as List<dynamic>).join().contains(
          'os.path.relpath(chart_path_obj, start=notebook_dir)',
        ),
      ),
      true,
    );
  });
}

Map<String, Object?> _group({
  String experimentId = 'baseline',
  required String loadoutId,
  required int station,
  required String tier,
  required String difficulty,
  required double clearRate,
  required double scoreRatio,
  required double turns,
  required double maxHit,
  required List<String> labels,
  double slowShare = 0.0,
  String tempoRisk = 'none',
  bool attention = false,
  Map<String, String>? targetLabelsV2,
  bool attentionV2 = false,
}) {
  return {
    'experiment_id': experimentId,
    'loadout_id': loadoutId,
    'station': station,
    'blind_tier': tier,
    'difficulty': difficulty,
    'run_count': 4,
    'clear_count': (clearRate * 4).round(),
    'slow_clear_count': (slowShare * 4).round(),
    'clear_rate': clearRate,
    'slow_clear_rate': slowShare,
    'slow_clear_share_of_clears': slowShare,
    'tempo_risk_label': tempoRisk,
    'ml_label_version': 'ml_label_v1',
    'ml_labels': labels,
    'needs_balance_attention': attention,
    'ml_label_v2_version': 'ml_label_v2',
    'ml_target_labels_v2':
        targetLabelsV2 ??
        {
          'difficulty': clearRate < 0.25 ? 'too_hard' : 'difficulty_ok',
          'tempo': tempoRisk == 'clear_but_too_slow'
              ? 'tempo_drag'
              : 'tempo_ok',
          'resource_pressure': clearRate < 0.25
              ? 'deck_pressure_high'
              : 'resource_ok',
          'score_spike': maxHit >= 110 ? 'spike_ok' : 'spike_flat',
          'decision_density': 'agency_ok',
        },
    'needs_balance_attention_v2': attentionV2 || attention,
    'avg_score_ratio': scoreRatio,
    'avg_turn_count': turns,
    'avg_confirm_action_count': 4.0,
    'avg_discarded_board_count': 0.0,
    'avg_max_single_confirm_score': maxHit,
    'scored_run_count': 4,
    'avg_first_score_turn': 38.0,
    'avg_last_score_turn': turns - 5,
    'outcome_counts': {'clear': (clearRate * 4).round()},
    'clear_tempo_label_counts': {'clear_normal': 1},
  };
}
