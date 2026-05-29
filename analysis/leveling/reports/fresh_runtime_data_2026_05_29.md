# Fresh Runtime Data 2026-05-29

## 목적

기존 archive ML/시뮬레이션 산출물을 현재 판단 근거로 재사용하지 않고, 현재 runtime/catalog/ruleset/bot policy 기준 fresh row를 다시 쌓기 시작한다.

## 실행

- command: `dart run tools/sim/run_balance_sim.dart --runs 200 --bot planner_v2 --seed 93300 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic`
- raw JSONL: `logs/sim/fresh_runtime_20260529_planner_r200.jsonl`
- summary: `logs/sim/fresh_runtime_20260529_planner_r200_summary.json`
- economy audit: `logs/sim/fresh_runtime_20260529_planner_r200_economy_audit.json`

`logs/`는 git ignored 산출물이다. 이 리포트만 tracked 요약으로 남긴다.

## 결과

- JSONL rows: 5,049
- battle run count: 4,249
- sequence run count: 800
- matrix:
  - loadout: `progression_route_balanced`, `progression_route_power`
  - market: `none`, `shop_slot_market_v9`
  - run modifier: `basic`
  - difficulty: `standard`

Sequence path clear rate:

| Loadout | Market | Runs | Clear rate |
|---|---|---:|---:|
| `progression_route_balanced` | `none` | 200 | 0.0% |
| `progression_route_power` | `none` | 200 | 0.0% |
| `progression_route_balanced` | `shop_slot_market_v9` | 200 | 0.0% |
| `progression_route_power` | `shop_slot_market_v9` | 200 | 0.0% |

Economy audit highlights:

- offered slots: 3,609
- purchase events: 2,595
- missing cost events: 1,542
- known spend: 14,017G
- reroll spend: 6,406G
- final gold average:
  - `none`: 24.86G
  - `shop_slot_market_v9`: 7.86G
- immediate economy warning: none
- weak point: raw JSONL 구매 이벤트 절반 이상이 `cost=null`이라 실제 가격 산정 근거로는 아직 약하다.

## 해석

- 5000행 이상 fresh data 축적 조건은 충족했다.
- 단, `planner_v2` 기반 수집은 빠른 fresh data bootstrap이다. 사용자가 말한 “기존 풀런봇 수준의 런타임 진행 계약”을 완전히 대체하지 않는다.
- 중단한 `contest_policy_v1 --runs 160`은 15분 이상 CPU를 계속 사용했지만 종료 파일을 만들지 못했다. 장기 데이터 축적용 runner는 chunk 단위 flush/progress 출력 또는 병렬 chunk runner가 필요하다.

## Trace 보강

- `market_purchase_events`에서 `shop_slot_market_v9` 같은 sim policy container는 실제 구매가 아니므로 제외한다.
- 실제 후보 이벤트에는 `selected_profile`, `scaled_cost`, `effective_cost`, `gold_before_market`, `gold_after_market`, `affordable`, `blocked_reason`을 남긴다.
- source backlog 후보가 있는 이벤트는 `source_candidate_id`, `source_candidate_profile`을 평탄 필드로 함께 남긴다.
- smoke command: `dart run tools/sim/run_balance_sim.dart --runs 20 --bot planner_v2 --seed 93400 --sequence-mode station_path --stations 1,2,3,4,5,6,7,8 --blind-tiers small,big,boss --difficulty standard --experiment-id base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_runtime_station_pool_v1 --market-profiles none,shop_slot_market_v9 --loadout-id progression_route_balanced --loadout-id progression_route_power --sim-economy-mode gated_known_cost --sim-reward-scale 0.40 --sim-price-scale 2.2 --sim-market-spend-mode reroll_slot_sell_v1 --sim-market-choice-mode affordable_alternative_v1 --sim-price-band-mode catalog_normalized_v1 --run-modifier basic`
- smoke audit: rows 510, purchase events 128, missing cost events 0, known spend 1,584G.
- top purchased content에서 `shop_slot_market_v9`가 제거되고 실제 proxy/item/pack/planet/voucher id만 남는다.

## 외부 검토 자료 반영

사용자가 제공한 `rummipoker_leveling_ml_final_recommendations.md`의 결론은 현재 방향과 일치한다.

- 외부 카드/RL 데이터셋을 직접 붙이지 않고, 현재 Dart simulator와 bot policy로 fresh JSONL을 만든다.
- 첫 단계는 ML이 아니라 station/blind/bot/loadout/market별 통계 리포트다.
- 초기 supervised target은 `score_ratio = final_score / target_score`와 `cleared`가 적합하다.
- 강화학습은 legal action mask와 env 동기화 비용이 크므로 후순위다.
- 모델은 candidate JSON과 보고서만 만들고, runtime balance는 사람 검토 후 별도 반영한다.

이에 맞춰 `run_balance_sim.dart --flush-every-rows`, `tools/sim/chunked_balance_run.py`, `tools/sim/summarize_balance_jsonl.dart`를 fresh data runner 기반으로 둔다.

## Contest Policy Fresh Dataset

trace 보강 후 `contest_policy_v1` 기준 fresh data를 chunk runner로 다시 쌓았다.

- command shape: `python3 tools/sim/chunked_balance_run.py --resume --chunks 30 --runs-per-chunk 5 --seed 94600 --out-prefix logs/sim/fresh_runtime_20260529_contest_policy_chunked_r200 --dart /Users/cheng80/flutter/bin/dart -- ...`
- raw JSONL: `logs/sim/fresh_runtime_20260529_contest_policy_chunked_r200.jsonl`
- summary: `logs/sim/fresh_runtime_20260529_contest_policy_chunked_r200_summary.json`
- manifest: `logs/sim/fresh_runtime_20260529_contest_policy_chunked_r200_manifest.json`
- economy audit: `logs/sim/fresh_runtime_20260529_contest_policy_chunked_r200_economy_audit.json`
- rows: 5,133
- sequence runs: 600
- completed chunks: 30 / 30
- purchase events: 1,458
- missing cost events: 0
- sequence groups: 4

Feature table 연결:

- battle preoutcome metadata: `analysis/leveling/data/features/fresh_contest_policy_20260529_preoutcome_battle.metadata.json`
- battle outcome metadata: `analysis/leveling/data/features/fresh_contest_policy_20260529_outcome_summary.metadata.json`
- sequence preoutcome metadata: `analysis/leveling/data/features/fresh_contest_policy_20260529_preoutcome_sequence.metadata.json`
- generated CSV는 `analysis/leveling/generated/features/` 아래에 있으며 git 추적 대상이 아니다.

Preoutcome model smoke:

- `clear_rate` regression:
  - report: `analysis/leveling/reports/fresh_contest_policy_v1_20260529_clear_rate_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_20260529_preoutcome/clear_rate/clear_rate_preoutcome_metrics.json`
  - model: `ExtraTreesRegressor`
  - rows after min-run-count filter: 151
  - MAE 0.1693, RMSE 0.2377, R2 0.3730
- `avg_score_ratio` regression:
  - report: `analysis/leveling/reports/fresh_contest_policy_v1_20260529_avg_score_ratio_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_20260529_preoutcome/avg_score_ratio/avg_score_ratio_preoutcome_metrics.json`
  - model: `RandomForestRegressor`
  - rows after min-run-count filter: 151
  - MAE 0.0458, RMSE 0.0603, R2 0.4467
- `cleared_majority` classifier:
  - report: `analysis/leveling/reports/fresh_contest_policy_v1_20260529_cleared_majority_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_20260529_preoutcome/cleared_majority/cleared_majority_preoutcome_metrics.json`
  - model: `ExtraTreesClassifier`
  - rows after min-run-count filter: 151
  - accuracy 0.9211, balanced accuracy 0.9516, F1 0.9492, ROC-AUC 0.9862
- judgment: `avg_score_ratio` is a better regression target than raw `clear_rate` for this dataset, and `cleared_majority` is promising as a classifier. Runtime balance recommendation still requires wider candidate grid and fresh resimulation validation.

## 다음 작업

## Grid Fresh Dataset

`MODE=grid`로 market/loadout axis를 넓힌 fresh data를 다시 쌓았다.

- command shape: `MODE=grid CHUNKS=9 RUNS_PER_CHUNK=5 SEED=95600 OUT_PREFIX=logs/sim/fresh_runtime_20260529_contest_policy_grid_r200 ... run_fresh_leveling_pipeline.sh`
- raw JSONL: `logs/sim/fresh_runtime_20260529_contest_policy_grid_r200.jsonl`
- summary: `logs/sim/fresh_runtime_20260529_contest_policy_grid_r200_summary.json`
- manifest: `logs/sim/fresh_runtime_20260529_contest_policy_grid_r200_manifest.json`
- economy audit: `logs/sim/fresh_runtime_20260529_contest_policy_grid_r200_economy_audit.json`
- rows: 5,655
- completed chunks: 9 / 9
- purchase events: 2,439
- missing cost events: 0
- market profiles: `none`, `shop_slot_market_v9`, `shop_slot_market_v12`, `shop_slot_market_v13`, `shop_slot_market_v16`
- loadouts: `progression_route_balanced`, `progression_route_power`, `progression_route_delayed`

Grid feature/model 산출물:

- battle preoutcome metadata: `analysis/leveling/data/features/fresh_contest_policy_grid_20260529_preoutcome_battle.metadata.json`
- battle outcome metadata: `analysis/leveling/data/features/fresh_contest_policy_grid_20260529_outcome_summary.metadata.json`
- sequence preoutcome metadata: `analysis/leveling/data/features/fresh_contest_policy_grid_20260529_preoutcome_sequence.metadata.json`
- candidate CSV: `analysis/leveling/models/fresh_contest_policy_grid_20260529_candidate_recommendations.csv`
- candidate report: `analysis/leveling/reports/fresh_contest_policy_grid_20260529_candidate_probe_report.md`

Grid model smoke:

- `clear_rate` regression:
  - report: `analysis/leveling/reports/fresh_contest_policy_grid_20260529_clear_rate_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_grid_20260529_preoutcome/clear_rate/clear_rate_preoutcome_metrics.json`
  - model: `RandomForestRegressor`
  - rows after min-run-count filter: 323
  - MAE 0.1289, RMSE 0.1921, R2 0.4958
- `avg_score_ratio` regression:
  - report: `analysis/leveling/reports/fresh_contest_policy_grid_20260529_avg_score_ratio_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_grid_20260529_preoutcome/avg_score_ratio/avg_score_ratio_preoutcome_metrics.json`
  - model: `RandomForestRegressor`
  - rows after min-run-count filter: 323
  - MAE 0.0354, RMSE 0.0509, R2 0.6030
- `cleared_majority` classifier:
  - report: `analysis/leveling/reports/fresh_contest_policy_grid_20260529_cleared_majority_preoutcome_model_report.md`
  - metrics: `analysis/leveling/models/fresh_contest_policy_grid_20260529_preoutcome/cleared_majority/cleared_majority_preoutcome_metrics.json`
  - model: `RandomForestClassifier`
  - rows after min-run-count filter: 323
  - accuracy 0.8395, balanced accuracy 0.6649, F1 0.9065, ROC-AUC 0.7319

Judgment:

- grid data에서 `clear_rate`와 `avg_score_ratio` 회귀는 이전보다 좋아졌다.
- `avg_score_ratio`가 여전히 더 안정적인 regression target이다.
- `cleared_majority` classifier는 class imbalance가 커져 balanced accuracy가 낮아졌으므로 gate 후보 선별용으로 쓰기에는 아직 약하다.
- candidate probe 상위권도 market delta가 음수라 자동 적용 후보가 아니다. 다음은 상위 economy/target 후보를 분리해 fresh resimulation으로 실제 hit-rate를 검증한다.

## 다음 작업

1. Grid candidate report의 상위 economy/target 후보를 small fresh resimulation으로 분리 검증한다.
2. classifier는 class balance와 candidate resimulation hit-rate를 같이 본다.
3. `contest_policy_v1` raw action trace를 imitation learning용 schema로 분리할지 검토한다.
4. LLM autoplay P0 scaffold에서 만든 state/action request를 decision cache runner와 연결한다.
5. archive row는 섞지 않고, 필요한 경우 historical prior로만 비교한다.
