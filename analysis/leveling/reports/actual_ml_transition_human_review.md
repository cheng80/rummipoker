# 실제 ML 전환 진행 상태 리포트

## 최종 결론 요약

- 결론: 현재 ML 품질은 마감 기준이 아니며 NotebookLM 보고서/인포그래픽 재생성 source로 쓰기 전 단계다.
- 핵심 점수: station/tier MAE 0.0657, RMSE 0.1392, R2 0.5414 / sequence MAE 0.0483, RMSE 0.0866, R2 0.9178.
- 사용 가능: 현재 모델과 추천표는 후보 탐색과 후속 probe 설계 참고자료로만 사용한다.
- 사용 금지: production ML 주장, runtime 자동 적용, NotebookLM 최종 보고서 재생성.
- 다음 액션: boss pool/market/economy candidate grid를 확장하고 데이터 증량 후 MAE/RMSE/R2를 재평가한다.

## 핵심 점수

| 데이터셋 | 지표 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---|---:|---:|---|---|
| station/tier pre-outcome | MAE | 0.0657 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| station/tier pre-outcome | RMSE | 0.1392 | 0.0000 | 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| station/tier pre-outcome | R2 | 0.5414 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 개선됐지만 부족 |
| sequence/path pre-outcome | MAE | 0.0483 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| sequence/path pre-outcome | RMSE | 0.0866 | 0.0000 | 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| sequence/path pre-outcome | R2 | 0.9178 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | path triage 신호로 유망 |
| sequence/path pre-outcome | Row | 2,938 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 더 증량 필요 |

## 범위

이 리포트는 현재 offline ML transition의 진행 상태와 남은 gate를 사람 검토 기준으로 정리한다. 현재 품질은 ML 마감으로 인정하지 않는다.

이 산출물은 production ML, runtime auto-balancing, target/boss/market/economy 자동 patch를 활성화하지 않는다. 모델은 candidate setting 순위를 정하고 fresh resimulation probe를 고르는 용도로만 사용한다.

## 데이터 충분성

| 데이터셋 | Row | Target | Metric | 판단 |
|---|---:|---|---|---|
| station/tier pre-outcome table | 237,507 source / 60,000 train sample | `clear_rate` | MAE 0.0657, RMSE 0.1392, R2 0.5414 | 이전보다 개선됐지만 실무 추천 모델 기준에는 부족함 |
| sequence/path pre-outcome table | 2,938 | `path_clear_rate` | MAE 0.0483, RMSE 0.0866, R2 0.9178 | path-level triage 신호는 유망하지만 단독 ML 마감 기준은 아님 |

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

expanded-boss/runtime-station data는 coverage를 넓히고 sequence/path model을 크게 개선했지만, station/tier model을 실무 추천에 충분할 만큼 강하게 만들지는 않는다. 다음 학습에서도 MAE/RMSE/R2를 모두 비교한다.

## 모델 산출물

| 산출물 | 경로 |
|---|---|
| station/tier feature table | `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv` |
| sequence feature table | `analysis/leveling/generated/features/leveling_preoutcome_sequence_feature_table.csv` |
| station/tier metric | `analysis/leveling/models/clear_rate_preoutcome_metrics.json` |
| sequence metric | `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json` |
| station/tier recommendation CSV | `analysis/leveling/models/preoutcome_candidate_recommendations.csv` |
| station/tier recommendation report | `analysis/leveling/reports/preoutcome_candidate_recommendation_report.md` |
| sequence model report | `analysis/leveling/reports/preoutcome_sequence_baseline_model_report.md` |

## 후보 재시뮬레이션

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
- 업데이트된 모델은 probe 선택의 참고 신호로만 유용하다. 낮은 R2와 작은 sequence dataset 때문에 ML 추천 gate는 닫히지 않았다.

## 사람 검토 결정

현재 결정:

- target 변경을 적용하지 않는다.
- 새 economy 변경을 적용하지 않는다.
- 현재 runtime economy baseline을 유지한다. Expanded boss r400 economy에는 즉시 경고가 없지만, 모델의 상위 economy candidate는 fresh r120에서 balanced+v9 기준을 통과하지 못했다.
- offline ML transition은 feature rebuild, baseline metric generation, candidate ranking scaffold, fresh-resimulation filtering 경로까지만 구현된 진행 중 상태로 본다. 현재 지표는 실무 사용 기준에 한참 못 미치므로 ML 마감이나 추천 gate 완료로 기록하지 않는다.

다음 필수 gate:

- runtime target/boss/market/economy 값 변경 전 사람 승인.
- ML 작업을 더 진행할 때는 상위 economy candidate를 직접 적용하지 말고, boss pool placement와 market availability 중심으로 candidate grid를 확장한다.
- 다음 모델 리포트부터 MAE, RMSE, R2를 모두 기록하고, train/test split과 데이터 수가 실무 추천에 충분한지 별도 판단한다.
- 모델 지표가 충분히 좋아져도 fresh resimulation과 사람 검토를 통과하기 전에는 runtime 적용 후보로만 둔다.
