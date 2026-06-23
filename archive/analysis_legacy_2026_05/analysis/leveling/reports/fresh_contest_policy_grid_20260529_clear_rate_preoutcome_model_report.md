# 레벨링 Pre-Outcome 전환 스캐폴드 리포트

## 최종 결론 요약

- 결론: 현재 모델은 pre-outcome 후보 추천 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다.
- 핵심 점수: MAE 0.1289, RMSE 0.1921, R2 0.4958.
- 데이터: 323 rows, train 242, test 81, target `clear_rate`.
- task: `regression`.
- 사용 가능: 후속 시뮬레이션 후보를 고르는 참고 신호와 feature sanity check.
- 사용 금지: runtime 자동 밸런싱, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.
- NotebookLM 상태: 지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계.
- 다음 액션: boss/market/economy candidate grid와 raw run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다.

## 핵심 점수

| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---:|---:|---|---|
| MAE | 0.1289 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| RMSE | 0.1921 | 0.0000 | target 0~1 기준 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| R2 | 0.4958 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 실무 추천 기준에는 부족 |
| Row | 323 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 데이터 규모 확인용 |

## 범위

이 리포트는 계획된 ML transition scaffold다.
기존 outcome-derived summary feature를 제거하고, 시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 `clear_rate`를 예측한다.
모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.
이 산출물만으로 production ML 자동 적용 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 검토 보고서를 함께 본다.

## 데이터셋

- feature table: `analysis/leveling/generated/features/fresh_contest_policy_grid_20260529_preoutcome_battle.csv`
- rows: 323
- train rows: 242
- test rows: 81
- target: `clear_rate`
- task: `regression`
- feature mode: `preoutcome`

소스 summary:

- `logs/sim/fresh_runtime_20260529_contest_policy_grid_r200_summary.json`

## 피처와 타깃 정의

Target:

- `clear_rate`: 집계된 시뮬레이션 그룹의 clear 비율.

Pre-outcome numeric features:

- `station`
- `station_tier_index`
- `tier_index`
- `station_band_index`
- `is_boss_tier`
- `is_late_station`
- `is_final_station`
- `expected_target_score`
- `expected_reward_gold`
- `board_discard_pressure`
- `hand_discard_pressure`
- `max_hand_size_pressure`
- `difficulty_multiplier`
- `target_multiplier`
- `small_target_multiplier`
- `big_target_multiplier`
- `boss_target_multiplier`
- `s1_boss_target_multiplier`
- `s2_boss_target_multiplier`
- `s3_boss_target_multiplier`
- `reward_multiplier`
- `sweep_reward_scale`
- `sweep_price_scale`
- `has_market_profile`
- `market_profile_version`
- `is_shop_slot_market`
- `is_sim_policy_market`
- `market_availability_index`
- `has_boss_constraint`
- `boss_family_index`
- `boss_level_index`
- `boss_pressure_index`
- `is_runtime_boss_modifier`
- `economy_pressure_index`
- `station_boss_interaction`
- `station_pressure_interaction`
- `market_station_interaction`
- `economy_market_interaction`
- `price_band_growth_access`
- `price_band_catalog_normalized`
- `spend_mode_slot_sell`
- `spend_mode_first_reroll_free`
- `spend_mode_reroll_slot_sell_soft`
- `spend_mode_reroll_slot_sell`
- `choice_mode_affordable_alternative`

Pre-outcome categorical features:

- `base_experiment_id`
- `loadout_id`
- `blind_tier`
- `difficulty`
- `market_profile`
- `resolved_market_profile`
- `run_modifier`
- `sim_boss_constraint_id`
- `sim_economy_mode`
- `sim_market_budget_mode`
- `sim_market_spend_mode`
- `sim_price_band_mode`
- `sim_market_choice_mode`

모델 feature에서 제외한 항목:

- `avg_score_ratio`
- `avg_turn_count`
- `avg_confirm_action_count`
- `avg_max_single_confirm_score`
- `avg_remaining_deck`
- `avg_remaining_board_discards`
- `avg_remaining_hand_discards`
- `avg_remaining_board_moves`
- `slow_clear_share_of_clears`

제외된 필드는 outcome 값이므로, 시뮬레이션 실행 전 후보 추천에는 사용할 수 없다.
`run_count`는 후보 조건 feature가 아니라 같은 조건을 몇 번 돌렸는지 나타내는 sample-size metadata이므로, 모델 입력 대신 학습 가중치와 저신뢰 row 필터로만 사용한다.

## 모델

모델 전략: `auto`.
선택된 모델: `RandomForestRegressor`.

선택 이유:

- numeric/categorical simulation setting이 섞인 데이터를 다루는 단순 baseline으로 적합하다.
- station, tier, market, boss, modifier 사이의 비선형 상호작용을 포착할 수 있다.
- 첫 사람 검토에서 feature importance를 확인하기 쉽다.

## 지표

- MAE: 0.1289
- RMSE: 0.1921
- R2: 0.4958

해석:

- post-run result를 볼 수 없으므로 이전 outcome-summary scaffold보다 점수가 약한 것이 자연스럽다.
- RMSE `0.1921` 수준은 큰 오차에 더 민감한 회귀 오차다.
- signal이 약하면 모델 ranking에 기대기 전에 candidate 다양성이나 raw run-level data를 늘리고 MAE/RMSE/R2를 함께 재평가해야 한다.

## 피처 중요도 스냅샷

| Feature | 중요도 |
|---|---:|
| `boss_pressure_index` | 0.1066 |
| `station_pressure_interaction` | 0.1022 |
| `station_boss_interaction` | 0.0925 |
| `boss_family_index` | 0.0704 |
| `boss_level_index` | 0.0628 |
| `station_tier_index` | 0.0592 |
| `sim_boss_constraint_id_` | 0.0480 |
| `blind_tier_boss` | 0.0461 |
| `is_boss_tier` | 0.0455 |
| `tier_index` | 0.0408 |

## 산출물

- metrics JSON: `analysis/leveling/models/fresh_contest_policy_grid_20260529_preoutcome/clear_rate/clear_rate_preoutcome_metrics.json`
- feature importance CSV: `analysis/leveling/models/fresh_contest_policy_grid_20260529_preoutcome/clear_rate/clear_rate_preoutcome_feature_importance.csv`

## 추천 경계

허용되는 다음 사용:

- 후속 시뮬레이션을 위한 candidate setting 순위화
- clear-rate variance를 설명하는 pre-run setting 식별
- 사람 검토용 작은 candidate probe 선택

허용되지 않는 사용:

- runtime 자동 밸런싱
- 재시뮬레이션 없는 target/boss/market/economy 직접 패치
- 플레이어 telemetry modeling으로 해석
- ML 마감 또는 추천 gate 완료 근거로 사용
