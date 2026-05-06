# 레벨링 ML 전환 스캐폴드 리포트

## 최종 결론 요약

- 결론: 현재 모델은 설명용 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다.
- 핵심 점수: MAE 0.0651, RMSE 0.1246, R2 0.4202.
- 데이터: 92 rows, train 69, test 23, target `path_clear_rate`.
- 사용 가능: 후속 probe 후보 영역 탐색과 feature sanity check.
- 사용 금지: runtime 자동 변경, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.
- NotebookLM 상태: 지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계.
- 다음 액션: pre-outcome candidate grid와 run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다.

## 핵심 점수

| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---:|---:|---|---|
| MAE | 0.0651 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| RMSE | 0.1246 | 0.0000 | target 0~1 기준 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| R2 | 0.4202 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 실무 추천 기준에는 부족 |
| Row | 92 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 데이터 규모 확인용 |

## 범위

이 리포트는 실제 ML 전환 완료 보고서가 아니다.
현재 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target score, boss severity, market weight, economy scale 후보를 추천하지 않는다.
런타임 밸런스를 자동으로 바꾸지 않으며, 현재 산출물을 ML 기반 밸런스 자동 조정 근거로 사용하지 않는다.

## 데이터셋

- feature table: `analysis/leveling/data/features/leveling_preoutcome_sequence_feature_table.csv`
- rows: 92
- train rows: 69
- test rows: 23
- target: `path_clear_rate`

소스 summary:

- `analysis/leveling/data/raw/prototype_stability_submission_r120_summary.json`
- `analysis/leveling/data/raw/run_modifier_high_stakes_market_pressure_effective_t104_r800_summary.json`
- `analysis/leveling/data/raw/run_modifier_candidate_fair_t104_r112_r400_summary.json`
- `analysis/leveling/data/raw/run_modifier_pressure_market_probe_t104_r112_v9_v10_r400_summary.json`
- `analysis/leveling/data/raw/station_curve_growth_gate_probe_r120_summary.json`
- `logs/sim/economy_choice_affordable_v1_r120_summary.json`
- `logs/sim/economy_choice_reward038_price240_v1_r120_summary.json`
- `logs/sim/economy_choice_reward039_price240_v1_r120_summary.json`
- `logs/sim/economy_choice_reward036_price260_v1_r120_summary.json`
- `logs/sim/economy_choice_reward038_price260_v1_r120_summary.json`
- `logs/sim/post_lane_reroll_probe_r120_summary.json`
- `logs/sim/prototype_stability_submission_r120_summary.json`
- `logs/sim/prototype_s1_easy_entry_v91_r240_summary.json`
- `logs/sim/prototype_stability_v91_r120_summary.json`
- `logs/sim/ml_actual_target_grid_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p220_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p240_v1_r80_summary.json`
- `logs/sim/boss_expansion_confirm_limit_v1_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_current_boss_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_expanded_boss_confirm_limit_r400_summary.json`

각 row는 experiment, loadout, blind tier, difficulty, market profile, run modifier, station, outcome summary 값으로 집계한 시뮬레이션 그룹이다. 현재 데이터셋은 시뮬레이션 기반이며 실제 플레이어 telemetry가 아니다.

## 피처와 타깃 정의

Target:

- `path_clear_rate`: 집계된 시뮬레이션 그룹의 clear 비율.

Numeric features:

- `station`
- `run_count`
- `avg_score_ratio`
- `avg_turn_count`
- `avg_confirm_action_count`
- `avg_max_single_confirm_score`
- `avg_remaining_deck`
- `avg_remaining_board_discards`
- `avg_remaining_hand_discards`
- `avg_remaining_board_moves`
- `slow_clear_share_of_clears`

Categorical features:

- `experiment_id`
- `loadout_id`
- `blind_tier`
- `difficulty`
- `market_profile`
- `run_modifier`
- `tempo_risk_label`

Silver-label 컬럼은 분석 맥락으로 feature table에 보존하지만, 이 첫 모델은 휴리스틱 라벨을 학습하지 않고 선택된 target을 직접 예측한다.

## 모델

모델 종류: `RandomForestRegressor`.

선택 이유:

- station, blind tier, market profile, resource residual 사이의 비선형 상호작용을 고정된 선형 가정 없이 다룰 수 있다.
- 간단한 전처리 pipeline으로 numeric feature와 one-hot categorical feature를 함께 사용할 수 있다.
- 첫 scaffold report에서 feature importance를 검토하기 쉽다.

이 모델은 의도적으로 offline-only 설명 모델이다. runtime target score, boss modifier, market weight, economy constant를 직접 패치하지 않는다.

## 지표

- MAE: 0.0651
- RMSE: 0.1246
- R2: 0.4202

해석:

- MAE `0.0651` 수준은 held-out group에서 `path_clear_rate`를 예측할 때의 평균 오차다.
- RMSE `0.1246` 수준은 큰 오차에 더 민감한 회귀 오차다.
- R2 `0.4202` 수준은 값이 높을수록 이 시뮬레이션 데이터셋의 held-out variance를 더 많이 설명한다는 뜻이다.
- 이것은 게임 밸런스가 완전히 닫혔다는 근거가 아니다.
- 이것은 ML 전환이 완료됐다는 근거도 아니다.
- 현재 summary row를 supervised modeling scaffold에 올릴 수 있고, outcome-derived feature가 clear-rate variance를 설명할 수 있음을 보여줄 뿐이다.

## 피처 중요도 스냅샷

| Feature | 중요도 |
|---|---:|
| `station_path_length` | 0.3463 |
| `loadout_id_progression_route_power` | 0.1968 |
| `base_experiment_id_nan` | 0.1417 |
| `base_experiment_id_base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068` | 0.0620 |
| `loadout_id_progression_route_balanced` | 0.0529 |
| `market_profile_shop_slot_market_v9` | 0.0414 |
| `resolved_market_profile_shop_slot_market_v9` | 0.0368 |
| `market_profile_version` | 0.0162 |
| `resolved_market_profile_none` | 0.0162 |
| `market_profile_none` | 0.0151 |

읽는 법:

- outcome-derived feature가 지배적이면 이 모델은 처방형보다 설명형에 가깝다.
- 이후 추천 모델은 outcome 설명을 넘어서 개입안을 추천할 수 있도록 전투 전 configuration feature를 추가해야 한다.

## 산출물

- metrics JSON: `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json`
- feature importance CSV: `analysis/leveling/models/path_clear_rate_preoutcome_sequence_feature_importance.csv`

## 해석 규칙

휴리스틱 라벨은 초기 silver label로만 사용한다. 실제 유저 데이터가 충분해지면 target과 metric을 다시 정의한다.

## 추천 경계

현재 허용되는 사용:

- clear-rate 변화와 관련 있는 시뮬레이션 factor의 우선순위를 본다.
- 후속 probe를 돌릴 후보 영역을 찾는다.
- 실제 ML 전환 설계를 시작할 만큼 구조화된 summary data가 있는지 확인한다.

현재 금지되는 사용:

- runtime target score 자동 변경.
- boss cycle/severity 자동 변경.
- market candidate weight 자동 변경.
- 플레이어 행동 모델링으로 해석.
- 이미 ML 기반 밸런스라고 주장.
- ML 마감 또는 추천 gate 완료 근거로 사용.

## 다음 ML 단계

실제 ML 전환은 아직 완료되지 않았다. 다음 모델은 outcome 설명을 넘어 개입안을 추천할 수 있도록 pre-outcome candidate feature를 추가해야 한다.

- target multiplier candidate
- boss modifier category and severity
- market candidate availability/weight profile
- reward scale and price scale
- reroll lane spend and final gold features after the recent reroll split

그 다음 후보 loop를 실행한다.

1. 모델이 offline에서 candidate setting 순위를 매긴다.
2. 시뮬레이터가 상위 후보를 실행한다.
3. 사람 검토로 정책 제약과 playfeel을 확인한다.
4. 승인된 후보만 runtime data/code에 적용한다.
