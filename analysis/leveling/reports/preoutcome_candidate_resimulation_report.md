# 레벨링 Pre-Outcome 후보 재시뮬레이션 리포트

## 최종 결론 요약

- 결론: 이 재시뮬레이션은 scaffold 검증이며 ML 마감 또는 NotebookLM 최종 source가 아니다.
- 핵심 점수: 기존 baseline report 기준 MAE 0.0439, R2 0.2208, RMSE 미기록. 최신 pre-outcome 재생성 지표는 별도 baseline report를 따른다.
- 사용 가능: 후보 axis가 fresh simulation에서 어떤 방향인지 확인하는 참고자료.
- 사용 금지: runtime 자동 적용, ML 추천 gate 완료 주장, NotebookLM 보고서/인포그래픽 재생성.
- 다음 액션: 최신 MAE/RMSE/R2 기준으로 candidate grid를 다시 만들고 fresh resimulation을 재실행한다.

## 핵심 점수

| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---:|---:|---|---|
| rows | 4666 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 과거 scaffold 기준 |
| MAE | 0.0439 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 참고용 |
| RMSE | 미기록 | 0.0000 | 반드시 기록 필요 | 재평가 필요 |
| R2 | 0.2208 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 부족 |

## 범위

이 리포트는 첫 계획형 ML 전환 loop의 scaffold 진행 상태를 정리한다.

1. pre-outcome feature table을 만든다.
2. offline baseline model을 학습한다.
3. metric과 feature importance를 검토한다.
4. 현재 모델 관련 candidate axis를 재시뮬레이션한다.
5. runtime 변경은 사람 검토 gate 뒤에 둔다.

이 산출물은 production ML이 아니다. target, boss, market, economy 변경을 자동 적용하지 않는다.
현재 모델 지표는 실무 추천 기준에 부족하므로 ML 마감이나 추천 gate 완료로 보지 않는다.

## 산출물

| 산출물 | 경로 |
|---|---|
| pre-outcome feature table | `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv` |
| metadata | `analysis/leveling/data/features/leveling_preoutcome_feature_table.metadata.json` |
| metric JSON | `analysis/leveling/models/clear_rate_preoutcome_metrics.json` |
| feature importance | `analysis/leveling/models/clear_rate_preoutcome_feature_importance.csv` |
| baseline report | `analysis/leveling/reports/preoutcome_baseline_model_report.md` |
| resimulation summary | `logs/sim/ml_preoutcome_candidate_v1_r120_summary.json` |
| resimulation report | `logs/sim/ml_preoutcome_candidate_v1_r120_report.md` |

## 피처 테이블

Rows: `4666`

포함한 pre-outcome feature group:

- station and blind tier
- difficulty and inferred target/reward multiplier
- market profile and resolved market profile
- run modifier
- boss constraint family
- sim sweep reward/price scale

모델 feature에서 제외한 항목:

- score ratio
- turn count
- confirm action count
- max single confirm score
- remaining deck/discards/moves
- slow clear share
- run count

제외된 필드는 post-outcome 값 또는 sample-size metadata다. 진단에는 사용할 수 있지만, 시뮬레이션 실행 전 후보 추천에는 사용할 수 없다.

## Baseline 지표

Model: `RandomForestRegressor`

| Metric | Value |
|---|---:|
| rows | 4666 |
| train rows | 3499 |
| test rows | 1167 |
| MAE | 0.0439 |
| RMSE | 미기록 |
| R2 | 0.2208 |

해석:

- 이전 outcome-summary scaffold보다 모델 점수가 약한 것은 예상된 결과다.
- 이전 scaffold는 post-run result를 볼 수 있었지만, 이 모델은 볼 수 없다.
- `R2 0.2208`은 실무 추천 기준에 한참 부족하다.
- RMSE가 빠져 있어 회귀 모델 품질 판단이 불완전하다.

Top feature importance snapshot:

| Feature | Importance |
|---|---:|
| `loadout_id_baseline__shop_slot_market_v9` | 0.3372 |
| `station` | 0.1237 |
| `boss_family_index` | 0.0595 |
| `loadout_id_baseline` | 0.0581 |
| `sim_boss_constraint_id_single_rank_pressure` | 0.0214 |

읽는 법:

- 현재 summary dataset은 여전히 loadout/market encoded identity의 영향을 크게 받는다.
- 다음 ML iteration은 더 넓은 candidate grid를 만들어 모델이 intervention setting을 더 직접 비교할 수 있게 해야 한다.

## 후보 재시뮬레이션

명령:

```bash
python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 120600 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_preoutcome_candidate_v1_r120
```

결과:

| Loadout | Market | Path clear | Avg total turn | Top bottlenecks | Stop reasons |
|---|---|---:|---:|---|---|
| balanced | none | 60.8% | 1410.4 | S4 boss 8, S3 boss 5, S1 boss 5, S8 boss 5 | board 26, draw 21 |
| power | none | 61.7% | 1344.1 | S8 boss 10, S1 boss 5, S3 big 4, S3 boss 3 | board 36, draw 10 |
| balanced | `shop_slot_market_v9` | 72.5% | 1450.8 | S8 boss 7, S2 boss 4, S5 big 3, S1 big 3 | board 24, draw 9 |
| power | `shop_slot_market_v9` | 70.8% | 1323.2 | S1 big 5, S8 boss 4, S3 boss 4, S7 boss 4 | board 28, draw 7 |

해석:

- `shop_slot_market_v9`는 이 r120 probe에서 여전히 강한 positive market axis다.
- S8 boss 압박을 지우지는 않는다.
- 이 결과는 candidate-validation 참고 신호이지, 그 자체로 새 runtime patch나 ML gate 완료 근거가 아니다.

## 결정

현재 결정:

- pre-outcome pipeline은 계획된 transition scaffold로 유지하되, ML 마감으로 보지 않는다.
- 이 모델에서 나온 runtime 변경을 자동 적용하지 않는다.
- `shop_slot_market_v9`는 후속 분석에 사용할 만큼 유효하다고 보되, 이 r120 run이 장기 경제 closure는 아니라는 점을 명시한다.

ML을 다시 열 때 다음 작업:

- target/boss/market/economy lever에 대한 더 넓은 pre-outcome candidate grid 생성
- encoded loadout identity가 아니라 candidate setting 중심 학습
- MAE/RMSE/R2를 함께 기록하고 실무 추천 기준 충족 여부 판단
- candidate prediction과 fresh resimulation 비교
- runtime 값을 건드리기 전에 사람 검토용 추천표 작성
