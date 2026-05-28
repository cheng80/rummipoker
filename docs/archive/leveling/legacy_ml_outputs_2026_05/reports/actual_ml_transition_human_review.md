# 실제 ML 전환 진행 상태 리포트

## 최종 결론 요약

- 결론: runtime handoff 후보는 최신 r400과 sequence/path ML gate를 함께 통과했다. station/tier는 source-path split 기준으로 아직 힌트 전용이고, sequence/path는 후보 선별 보조 신호로 쓴다.
- 핵심 점수: station/tier source split MAE 0.0487, RMSE 0.0952, R2 0.7265 / sequence source split MAE 0.0560, RMSE 0.1055, R2 0.8482.
- 사용 가능: sequence/path 후보 선별 보조, station/tier 힌트, fresh r400+ 결과와 묶은 공모전 기준 ML 임시 handoff 판단.
- 사용 금지: production ML 주장, runtime 자동 밸런싱, 모델 예측만 보고 target/boss/market/economy를 변경하는 일.
- 다음 액션: 현재 runtime handoff 후보를 공모전 QA 기준으로 넘기고, 셔플/추가 밸런스 변경 때 같은 runtime+ML+fresh gate를 반복한다.

## 핵심 점수

| 데이터셋 | 지표 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---|---:|---:|---|---|
| station/tier source-path split | MAE | 0.0487 | 0.0000 | target 0~1 기준 낮을수록 좋음 | 힌트 전용 |
| station/tier source-path split | RMSE | 0.0952 | 0.0000 | 큰 오차가 낮을수록 좋음 | 힌트 전용 |
| station/tier source-path split | R2 | 0.7265 | 1.0000 | 새 실험 파일을 가려도 높아야 함 | 단독 gate 금지 |
| sequence/path source-path split | MAE | 0.0560 | 0.0000 | target 0~1 기준 낮을수록 좋음 | 후보 선별 보조 |
| sequence/path source-path split | RMSE | 0.1055 | 0.0000 | 큰 오차가 낮을수록 좋음 | 후보 선별 보조 |
| sequence/path source-path split | R2 | 0.8482 | 1.0000 | 새 실험 파일을 가려도 높아야 함 | fresh r400+와 함께 사용 |
| sequence/path pre-outcome | Row | 3,394 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 후보 선별 보조 가능 |

## 범위

이 리포트는 현재 offline ML transition의 진행 상태와 남은 gate를 사람 검토 기준으로 정리한다. random split은 낙관적이므로 source-path split을 함께 본다.

이 산출물은 production ML, runtime auto-balancing, target/boss/market/economy 자동 patch를 활성화하지 않는다. 모델은 candidate setting 순위를 정하고 fresh resimulation 결과와 함께 적용 후보를 판단하는 용도로만 사용한다.

## 데이터 충분성

| 데이터셋 | Row | Target | Metric | 판단 |
|---|---:|---|---|---|
| station/tier pre-outcome table | 297,051 source / run_count 80+ 46,396 rows | `clear_rate_smoothed` | source split MAE 0.0487, RMSE 0.0952, R2 0.7265 | 구간 힌트 전용 |
| sequence/path pre-outcome table | 3,394 | `path_clear_rate` | source split MAE 0.0560, RMSE 0.1055, R2 0.8482 | 후보 선별 보조 신호 |

기존 heuristic pipeline은 bootstrap source로 사용했다.

- historical simulation summary file을 pre-outcome feature table에 합쳤다.
- `failure_counts`와 `failure_stop_reason_counts`는 heuristic diagnostic으로 유지했다.
- heuristic label은 production ML truth가 아니라 silver-label context로만 남긴다.

target candidate 비교에는 데이터가 아직 부족해서 추가 r80 target grid를 생성했다.

- `logs/sim/ml_actual_target_grid_v1_r80_summary.json`
- `logs/sim/ml_actual_target_grid_v1_r80_report.md`

상위 economy candidate에 대한 fresh economy probe도 생성했다.

- `logs/sim/ml_actual_economy_r040_p220_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p240_v1_r80_summary.json`

boss pool 확장 이후 추가 input을 반영했다.

- `logs/sim/boss_expansion_confirm_limit_v1_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_current_boss_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_expanded_boss_confirm_limit_r400_summary.json`
- `logs/sim/runtime_station_pool_leveling_r400_summary.json`
- `logs/sim/runtime_station_pool_economy_r400_summary.json`
- `logs/sim/runtime_station_pool_market_availability_r80_summary.json`

expanded-boss/runtime-station data는 coverage를 넓혔다. 최신 feature 재생성은 summary에 없던 economy 실행 조건을 sibling audit와 파일명에서 복원해, current handoff 후보가 `growth_access_v1 / price 2.2 / affordable choice`로 올바르게 학습되게 했다. 다음 학습에서도 MAE/RMSE/R2를 모두 비교한다.

## 모델 산출물

| 산출물 | 경로 |
|---|---|
| station/tier feature table | `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv` |
| sequence feature table | `analysis/leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv` |
| station/tier metric | `analysis/leveling/models/clear_rate_preoutcome_metrics.json` |
| smoothed station/tier metric | `analysis/leveling/models/clear_rate_smoothed_preoutcome_metrics.json` |
| sequence metric | `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json` |
| station/tier recommendation CSV | `analysis/leveling/models/preoutcome_candidate_recommendations.csv` |
| station/tier recommendation report | `analysis/leveling/reports/preoutcome_candidate_recommendation_report.md` |
| sequence recommendation CSV | `analysis/leveling/models/preoutcome_sequence_candidate_recommendations.csv` |
| sequence recommendation report | `analysis/leveling/reports/preoutcome_sequence_candidate_recommendation_report.md` |
| sequence model report | `analysis/leveling/reports/preoutcome_sequence_baseline_model_report.md` |

## 후보 재시뮬레이션

현재 runtime handoff 후보는 `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1 + first_reroll_free_v1 + affordable_alternative_v2`다. 쉬운 판단은 아래와 같다.

- 실제 r400: balanced는 none 48.8%에서 v9 60.5%로 오른다.
- 실제 r400: power는 none 54.8%에서 v9 69.8%로 오른다.
- S8 boss 실패와 board/draw 실패가 남아 있어 후반 압박은 사라지지 않았다.
- economy audit: 즉시 경제 경고 없음.
- sequence/path 추천표: `logs/sim/runtime_s4_rank_late_access_growth_price_r400_summary.json`을 fresh gate 1, ML gate 1로 본다.
- runtime 적용: 성장 후보 가격 상한은 이미 runtime에 있었고, 첫 리롤 무료 정책은 기존 `firstRerollDiscount` 필드로 적용했다. save schema 변경 없음.
- 결론: 공모전 기준 ML 임시 handoff는 가능하다. 단 production ML/자동 밸런싱은 아니다.

이전 runtime handoff 후보 `runtime_station_pool_s4_rank_weight_v1 + growth_access_v1`은 최소 gate는 통과했지만 clear 상승폭이 부족했다.

- 실제 r400: balanced는 none 47.5%에서 v9 52.0%로 오른다.
- 실제 r400: power는 none 53.8%에서 v9 57.0%로 오른다.
- 결론: 좋은 마켓 선택이 손해를 보지는 않지만 공모전 목표 체감 상승에는 부족해 보류한다.

추가 상승 후보 `slot_sell_v1`은 같은 boss/price 조건에서 리롤 비용만 빼고 슬롯 교체/판매는 유지한 sim-only 후보이다.

- 실제 r400 seed 91760: none balanced 51.7%, none power 56.2%, v9 balanced 65.2%, v9 power 67.8%.
- 실제 r400 seed 91761: none balanced 51.7%, none power 56.5%, v9 balanced 65.0%, v9 power 67.5%.
- sequence/path 추천표: 두 r400 모두 fresh gate 1, ML gate 1이다.
- 결론: 목표 clear 범위는 통과한다. 다만 v9 final gold가 16~24G로 늘어, runtime 리롤 비용 정책 영향 검토 전에는 적용하지 않는다.

최신 추천표에서도 `reward 0.40 / price 2.4`, `reward 0.38 / price 2.4` 계열 economy 후보가 상위에 남아 있다. 그러나 아래 fresh resimulation에서는 같은 계열 후보가 balanced+v9를 none보다 낮게 만들어 runtime 적용 보류 상태다. 따라서 추천표 점수는 다음 probe 후보를 고르는 참고 신호로만 사용한다.

### Target Grid r80

| Boss target multiplier | Loadout | Market | Path clear | S1 boss fails | S8 boss fails | Stop reasons |
|---:|---|---|---:|---:|---:|---|
| 0.98 | balanced | none | 55.0% | 5 | 2 | board 27, draw 9 |
| 0.98 | balanced | v9 | 63.8% | 4 | 3 | board 20, draw 9 |
| 0.98 | power | none | 63.8% | 2 | 6 | board 19, draw 10 |
| 0.98 | power | v9 | 77.5% | 2 | 2 | board 17, draw 1 |
| 1.00 | balanced | none | 62.5% | 2 | 5 | board 19, draw 10 |
| 1.00 | balanced | v9 | 51.2% | 6 | 4 | board 32, draw 7 |
| 1.00 | power | none | 73.8% | 1 | 2 | board 17, draw 4 |
| 1.00 | power | v9 | 71.2% | 1 | 3 | board 19, draw 4 |
| 1.02 | balanced | none | 65.0% | 4 | 5 | board 16, draw 12 |
| 1.02 | balanced | v9 | 71.2% | 3 | 4 | board 17, draw 6 |
| 1.02 | power | none | 61.3% | 4 | 4 | board 21, draw 10 |
| 1.02 | power | v9 | 67.5% | 2 | 2 | board 20, draw 5 |

해석:

- target grid는 아직 r80이므로 exploratory다.
- `boss 1.02`는 v9를 즉시 무너뜨리지 않고 S8 boss failure를 남긴다.
- `boss 0.98`은 이 seed에서 power+v9를 너무 강하게 만든다.
- balanced+v9가 이 r80 seed에서 내려갔기 때문에 current target이 명확히 지배당한다고 볼 수 없다.
- 더 큰 confirmation run 없이 target 변경을 적용하면 안 된다.

### Economy Fresh r80

| Candidate | Loadout | Market | Path clear | S1 boss fails | S8 boss fails | Stop reasons |
|---|---|---|---:|---:|---:|---|
| reward 0.40 / price 2.2 | balanced | none | 55.0% | 0 | 3 | board 23, draw 12 |
| reward 0.40 / price 2.2 | balanced | v9 | 52.5% | 5 | 6 | board 25, draw 13 |
| reward 0.40 / price 2.2 | power | none | 65.0% | 3 | 4 | board 22, draw 5 |
| reward 0.40 / price 2.2 | power | v9 | 71.2% | 1 | 5 | board 12, draw 11 |
| reward 0.40 / price 2.4 | balanced | none | 58.8% | 2 | 4 | board 25, draw 8 |
| reward 0.40 / price 2.4 | balanced | v9 | 53.8% | 2 | 8 | board 24, draw 12 |
| reward 0.40 / price 2.4 | power | none | 66.2% | 1 | 3 | board 20, draw 5 |
| reward 0.40 / price 2.4 | power | v9 | 75.0% | 3 | 2 | board 12, draw 8 |

해석:

- 두 economy r80 probe 모두에서 balanced+v9가 balanced+none보다 낮다.
- 현재 정책상 좋은 market proxy가 none/control보다 나빠지면 red flag다.
- r80은 economy gate를 닫기에 충분하지 않지만, post lane-reroll economy state를 closed라고 부르지 못하게 하기에는 충분하다.

### Expanded Boss Economy Fresh r120

업데이트된 recommendation table은 `economy_r038_p240_spend_choice`와 `economy_r040_p240_spend_choice`를 current baseline보다 높게 평가했지만, fresh resimulation은 두 후보 적용을 지지하지 않았다.

| Candidate | Loadout | Market | Path clear | Final gold avg | S8 boss start gold |
|---|---|---|---:|---:|---:|
| reward 0.38 / price 2.4 | balanced | none | 54.2% | 47.14G | 66.30G |
| reward 0.38 / price 2.4 | balanced | v9 | 52.5% | 5.72G | 8.77G |
| reward 0.38 / price 2.4 | power | none | 58.3% | 51.34G | 66.30G |
| reward 0.38 / price 2.4 | power | v9 | 60.8% | 6.17G | 8.77G |
| reward 0.40 / price 2.4 | balanced | none | 53.3% | 54.14G | 75.19G |
| reward 0.40 / price 2.4 | balanced | v9 | 51.7% | 6.39G | 8.91G |
| reward 0.40 / price 2.4 | power | none | 57.5% | 58.52G | 75.19G |
| reward 0.40 / price 2.4 | power | v9 | 60.8% | 6.83G | 8.91G |

소스:

- `logs/sim/ml_expanded_boss_economy_r038_p240_v1_r120_summary.json`
- `logs/sim/ml_expanded_boss_economy_r038_p240_v1_r120_economy_audit.json`
- `logs/sim/ml_expanded_boss_economy_r040_p240_v1_r120_summary.json`
- `logs/sim/ml_expanded_boss_economy_r040_p240_v1_r120_economy_audit.json`

해석:

- 두 상위 economy candidate 모두 balanced+v9를 balanced+none보다 낮게 만든다.
- 이는 좋은 market proxy가 none/control보다 나빠지면 안 된다는 정책 기대를 위반한다.
- 현재는 `reward 0.40 / price 2.2 / catalog_normalized_v1`를 더 안전한 baseline으로 유지한다.
- 업데이트된 모델은 offline handoff 기준으로 유용하다. station/tier는 구간 위험을 보고, sequence/path는 후보 선별을 본다.

## 사람 검토 결정

현재 결정:

- target 변경을 적용하지 않는다.
- 새 economy 변경을 적용하지 않는다.
- 현재 runtime economy baseline을 유지한다. Expanded boss r400 economy에는 즉시 경고가 없지만, 모델의 상위 economy candidate는 fresh r120에서 balanced+v9 기준을 통과하지 못했다.
- offline ML transition은 feature rebuild, baseline metric generation, grouped validation, candidate ranking, fresh r400+ filtering 경로까지 구현된 상태로 본다. production 자동 적용은 아니며, source split 점수를 함께 본다.

다음 필수 gate:

- runtime target/boss/market/economy 값 변경 전 사람 승인.
- ML 작업을 더 진행할 때는 상위 economy candidate를 직접 적용하지 말고, sequence/path gate와 fresh r400+ 결과를 함께 통과하는지 먼저 본다.
- 다음 모델 리포트부터 MAE, RMSE, R2를 모두 기록하고, train/test split과 데이터 수가 실무 추천에 충분한지 별도 판단한다.
- 모델 지표가 충분히 좋아져도 fresh resimulation과 사람 검토를 통과하기 전에는 runtime 적용 후보로만 둔다.
