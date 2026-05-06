# 레벨링 Pre-Outcome 전환 스캐폴드 리포트

## 최종 결론 요약

- 결론: 현재 모델은 pre-outcome 후보 추천 scaffold이며 ML 마감 또는 추천 gate 완료 근거가 아니다.
- 핵심 점수: MAE 0.0561, RMSE 0.1207, R2 0.6066.
- 데이터: 120000 rows, train 90000, test 30000, target `clear_rate`.
- 사용 가능: 후속 시뮬레이션 후보를 고르는 참고 신호와 feature sanity check.
- 사용 금지: runtime 자동 밸런싱, production ML 주장, 사람 승인 없는 target/boss/market/economy 적용.
- NotebookLM 상태: 지표가 사용 수준이 아니므로 보고서/인포그래픽 재생성 source로 쓰기 전 단계.
- 다음 액션: boss/market/economy candidate grid와 raw run-level 데이터를 늘리고 MAE/RMSE/R2를 재평가한다.

## 핵심 점수

| 항목 | 현재값 | 이상값/최선 | 실무 사용 기준 | 판단 |
|---|---:|---:|---|---|
| MAE | 0.0561 | 0.0000 | target 0~1 기준 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| RMSE | 0.1207 | 0.0000 | target 0~1 기준 큰 오차가 충분히 낮아야 함, 프로젝트 임계값 미정 | 기준 정의와 개선 필요 |
| R2 | 0.6066 | 1.0000 | 실무 추천용은 높은 설명력이 필요, 프로젝트 임계값 미정 | 실무 추천 기준에는 부족 |
| Row | 120000 | 많을수록 좋음 | 후보 grid와 run-level 다양성이 충분해야 함 | 데이터 규모 확인용 |

## 범위

이 리포트는 계획된 ML transition scaffold다.
기존 outcome-derived summary feature를 제거하고, 시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 `clear_rate`를 예측한다.
모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.
이 산출물만으로 실제 ML 이행 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 승인 보고서가 별도로 필요하다.

## 데이터셋

- feature table: `analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv`
- rows: 120000
- train rows: 90000
- test rows: 30000
- target: `clear_rate`
- feature mode: `preoutcome`

소스 summary:

- `logs/sim/boss_expansion_confirm_limit_v1_r400_summary.json`
- `logs/sim/boss_expansion_probe_v1_r120_summary.json`
- `logs/sim/boss_expansion_probe_v1_r80_summary.json`
- `logs/sim/boss_expansion_split_probe_v1_r80_summary.json`
- `logs/sim/boss_expansion_stage_a_probe_v1_r80_summary.json`
- `logs/sim/boss_expansion_stage_a_split_probe_v1_r80_summary.json`
- `logs/sim/candidate_baseline_v1_station_path_r400_summary.json`
- `logs/sim/confirm_color_position_probe_v1_r80_summary.json`
- `logs/sim/confirm_color_position_smoke_summary.json`
- `logs/sim/economy_budget_v1_r20_summary.json`
- `logs/sim/economy_catalog_audit_v2_r120_summary.json`
- `logs/sim/economy_catalog_normalized_reward040_price220_v1_r120_summary.json`
- `logs/sim/economy_catalog_normalized_reward040_price240_v1_r120_summary.json`
- `logs/sim/economy_catalog_normalized_reward040_v1_r120_summary.json`
- `logs/sim/economy_catalog_normalized_seed91460_r120_summary.json`
- `logs/sim/economy_choice_affordable_v1_r120_summary.json`
- `logs/sim/economy_choice_affordable_v1_r20_summary.json`
- `logs/sim/economy_choice_reward036_price240_v1_r120_summary.json`
- `logs/sim/economy_choice_reward036_price260_v1_r120_summary.json`
- `logs/sim/economy_choice_reward038_price240_catalog_flags_v1_r120_summary.json`
- `logs/sim/economy_choice_reward038_price240_v1_r120_summary.json`
- `logs/sim/economy_choice_reward038_price260_v1_r120_summary.json`
- `logs/sim/economy_choice_reward039_price240_v1_r120_summary.json`
- `logs/sim/economy_choice_reward040_price240_v1_r800_summary.json`
- `logs/sim/economy_combo045_220_v1_r120_summary.json`
- `logs/sim/economy_combo045_220_v1_r20_summary.json`
- `logs/sim/economy_gated_v1_r20_summary.json`
- `logs/sim/economy_jester_hook_price_r120_summary.json`
- `logs/sim/economy_jester_hook_price_r400_summary.json`
- `logs/sim/economy_price294_v1_r20_summary.json`
- `logs/sim/economy_price_band_soft_v1_r20_summary.json`
- `logs/sim/economy_price_band_v1_r20_summary.json`
- `logs/sim/economy_probe_v1_r20_summary.json`
- `logs/sim/economy_reward034_v1_r120_summary.json`
- `logs/sim/economy_reward034_v1_r20_summary.json`
- `logs/sim/economy_runtime_v91_long_r800_summary.json`
- `logs/sim/economy_runtime_v91_market_probe_r120_summary.json`
- `logs/sim/economy_runtime_v91_market_probe_raw_r120_summary.json`
- `logs/sim/economy_runtime_v91_market_v11_raw_r120_summary.json`
- `logs/sim/economy_runtime_v91_preflight_r1_summary.json`
- `logs/sim/economy_spend_cli_smoke_summary.json`
- `logs/sim/economy_spend_combo040_240_v1_r120_summary.json`
- `logs/sim/economy_spend_combo045_220_v1_r120_summary.json`
- `logs/sim/economy_spend_reward034_v1_r120_summary.json`
- `logs/sim/economy_spend_v1_r20_summary.json`
- `logs/sim/economy_trace_v1_r20_summary.json`
- `logs/sim/hand_discard_position_probe_v1_r80_summary.json`
- `logs/sim/hand_discard_position_smoke_summary.json`
- `logs/sim/late_offer_exposure_v86_r200_summary.json`
- `logs/sim/ml_actual_economy_r040_p220_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p240_v1_r80_summary.json`
- `logs/sim/ml_actual_target_grid_v1_r80_summary.json`
- `logs/sim/ml_expanded_boss_economy_r038_p240_v1_r120_summary.json`
- `logs/sim/ml_expanded_boss_economy_r040_p240_v1_r120_summary.json`
- `logs/sim/ml_preoutcome_candidate_v1_r120_summary.json`
- `logs/sim/ml_sweep_banded_market_v37_r400_summary.json`
- `logs/sim/ml_sweep_banded_market_v38_smoke_r100_summary.json`
- `logs/sim/ml_sweep_banded_market_v38b_smoke_r100_summary.json`
- `logs/sim/ml_sweep_base_curve_v2_constraints_v21_r400_summary.json`
- `logs/sim/ml_sweep_base_score_curve_v2_final_r400_summary.json`
- `logs/sim/ml_sweep_base_score_curve_v2_probe_r150_summary.json`
- `logs/sim/ml_sweep_base_v2_constraint_v4_candidate_pool_v22_r400_summary.json`
- `logs/sim/ml_sweep_board_relief_probe_v77_r200_summary.json`
- `logs/sim/ml_sweep_boss_constraints_full_curve_v13_summary.json`
- `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s6_s7_summary.json`
- `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_s7_summary.json`
- `logs/sim/ml_sweep_boss_constraints_v13_raw_probe_summary.json`
- `logs/sim/ml_sweep_boss_runtime_v90_long_r800_summary.json`
- `logs/sim/ml_sweep_boss_runtime_v90_smoke_r120_summary.json`
- `logs/sim/ml_sweep_boss_runtime_v91_confirm_tax_parity_r800_summary.json`
- `logs/sim/ml_sweep_candidate_baseline_v1_full_r400_summary.json`
- `logs/sim/ml_sweep_early_curve_v33_r400_summary.json`
- `logs/sim/ml_sweep_early_mid_gate_v65_r800_summary.json`
- `logs/sim/ml_sweep_early_s2_bridge_v34_r400_summary.json`
- `logs/sim/ml_sweep_experiment_v4_summary.json`
- `logs/sim/ml_sweep_face_boss_v89_smoke_r120_summary.json`
- `logs/sim/ml_sweep_final_regression_v70_pressure_r800_summary.json`
- `logs/sim/ml_sweep_final_regression_v70_relaxed_r800_summary.json`
- `logs/sim/ml_sweep_final_regression_v70_standard_r800_summary.json`
- `logs/sim/ml_sweep_full_safe_candidate_pool_v12_summary.json`
- `logs/sim/ml_sweep_integrated_runtime_transition_v63_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v56_s8_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v57_s8_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v58_s8_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v59_s8_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v60_s8_r800_summary.json`
- `logs/sim/ml_sweep_integrated_weighted_boss_v61_s8_r1600_summary.json`
- `logs/sim/ml_sweep_late_boss_v64_r800_summary.json`
- `logs/sim/ml_sweep_market_availability_v66_r800_summary.json`
- `logs/sim/ml_sweep_market_availability_v67_r800_summary.json`
- `logs/sim/ml_sweep_market_exposure_v72_smoke_r200_summary.json`
- `logs/sim/ml_sweep_market_exposure_v73_confirm_r800_summary.json`
- `logs/sim/ml_sweep_market_exposure_v75_smoke_r200_summary.json`
- `logs/sim/ml_sweep_market_guard_v50_r400_summary.json`
- `logs/sim/ml_sweep_market_guard_v51_r400_summary.json`
- `logs/sim/ml_sweep_market_guard_v52_r800_summary.json`
- `logs/sim/ml_sweep_market_price_probe_v79_r120_experiment_base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068_summary.json`
- `logs/sim/ml_sweep_market_price_probe_v79_r120_summary.json`
- `logs/sim/ml_sweep_market_tempo_v45_smoke_r100_summary.json`
- `logs/sim/ml_sweep_market_tempo_v46_r400_summary.json`
- `logs/sim/ml_sweep_market_tempo_v46_smoke_r100_summary.json`
- `logs/sim/ml_sweep_market_v12_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_market_v13_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_market_v9_v11_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_mid_growth_spacing_v29_r400_summary.json`
- `logs/sim/ml_sweep_ordered_boss_v55_r800_summary.json`
- `logs/sim/ml_sweep_ordered_boss_v55_s8_r800_summary.json`
- `logs/sim/ml_sweep_pack_size_v10_summary.json`
- `logs/sim/ml_sweep_path_survival_role_pools_v25_r400_summary.json`
- `logs/sim/ml_sweep_probabilistic_candidates_v11_summary.json`
- `logs/sim/ml_sweep_progression_routes_v26_r400_summary.json`
- `logs/sim/ml_sweep_random_market_v9_summary.json`
- `logs/sim/ml_sweep_rank_cycle_isolated_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_rank_cycle_probe_v1_explore_r120_summary.json`
- `logs/sim/ml_sweep_rank_cycle_probe_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_rank_cycle_soft_v90_explore_r120_summary.json`
- `logs/sim/ml_sweep_rare_xmult_v7_summary.json`
- `logs/sim/ml_sweep_role_candidate_pools_v24_r400_summary.json`
- `logs/sim/ml_sweep_runtime_table_v71_smoke_r200_summary.json`
- `logs/sim/ml_sweep_s1_boss_axis_v80_r400_summary.json`
- `logs/sim/ml_sweep_s1_curve_v35_r400_summary.json`
- `logs/sim/ml_sweep_s1_onboarding_progression_v27_r400_summary.json`
- `logs/sim/ml_sweep_s1_red_runtime_probe_v81_r400_summary.json`
- `logs/sim/ml_sweep_s1_red_soft060_v82_r400_summary.json`
- `logs/sim/ml_sweep_s1_soft_market_roles_v30_r400_summary.json`
- `logs/sim/ml_sweep_s4_constraint_v17_r400_summary.json`
- `logs/sim/ml_sweep_s4_constraint_v17b_r400_summary.json`
- `logs/sim/ml_sweep_s4_constraint_v18_r400_summary.json`
- `logs/sim/ml_sweep_s5_sustain_v5_summary.json`
- `logs/sim/ml_sweep_sequence_metric_v47_r400_summary.json`
- `logs/sim/ml_sweep_sequence_metric_v47_smoke_r100_summary.json`
- `logs/sim/ml_sweep_shape_floor_v87_runtime_parity_r120_summary.json`
- `logs/sim/ml_sweep_shape_floor_v87_smoke_r120_summary.json`
- `logs/sim/ml_sweep_shape_floor_v88_runtime_parity_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v39_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v39_smoke_r100_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v39b_smoke_r100_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v40_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v40_smoke_r100_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v41_r400_summary.json`
- `logs/sim/ml_sweep_shop_slot_market_v41_smoke_r100_summary.json`
- `logs/sim/ml_sweep_stage_curve_v42_r400_summary.json`
- `logs/sim/ml_sweep_stage_curve_v42_smoke_r100_summary.json`
- `logs/sim/ml_sweep_stage_curve_v43_r400_summary.json`
- `logs/sim/ml_sweep_stage_curve_v43_smoke_r100_summary.json`
- `logs/sim/ml_sweep_stage_curve_v44_smoke_r100_summary.json`
- `logs/sim/ml_sweep_state_weighted_market_v32_r400_summary.json`
- `logs/sim/ml_sweep_state_weighted_market_v32b_r400_summary.json`
- `logs/sim/ml_sweep_static_vs_progression_guard_v28_r400_summary.json`
- `logs/sim/ml_sweep_station_weighted_market_v31_r400_summary.json`
- `logs/sim/ml_sweep_target_curve_v48_r400_summary.json`
- `logs/sim/ml_sweep_target_curve_v49_r800_summary.json`
- `logs/sim/ml_sweep_target_v3_summary.json`
- `logs/sim/ml_sweep_target_v4_constraints_full_safe_r400_summary.json`
- `logs/sim/ml_sweep_target_v5_constraint_v2_r400_summary.json`
- `logs/sim/ml_sweep_target_v6_s5_r400_summary.json`
- `logs/sim/ml_sweep_three_band_curve_v36_r400_summary.json`
- `logs/sim/ml_sweep_tile_pack_v8_summary.json`
- `logs/sim/ml_sweep_train_v1_summary.json`
- `logs/sim/ml_sweep_train_v2_summary.json`
- `logs/sim/ml_sweep_v72_exposure_smoke_v84_r120_summary.json`
- `logs/sim/ml_sweep_virtual_enhance_v6_summary.json`
- `logs/sim/planner_v2_8station_curve_100_summary.json`
- `logs/sim/planner_v2_baseline_summary.json`
- `logs/sim/planner_v2_boss_diversity_summary.json`
- `logs/sim/planner_v2_early_boss_bridge_200_summary.json`
- `logs/sim/planner_v2_early_onboarding_joker_200_summary.json`
- `logs/sim/planner_v2_early_run_bridge_200_summary.json`
- `logs/sim/planner_v2_early_run_bridge_v2_200_summary.json`
- `logs/sim/planner_v2_full_progression_loadouts_100_summary.json`
- `logs/sim/planner_v2_ml_label_v1_preview_100_summary.json`
- `logs/sim/planner_v2_progression_loadouts_100_summary.json`
- `logs/sim/planner_v2_s1_boss_soften_summary.json`
- `logs/sim/planner_v2_s1_safety_resource_probe_300_summary.json`
- `logs/sim/planner_v2_s1_safety_sequence_200_summary.json`
- `logs/sim/planner_v2_s2_boss_experiment_100_summary.json`
- `logs/sim/planner_v2_s2_boss_target_sweep_100_summary.json`
- `logs/sim/planner_v2_sequence_market_minimal_200_summary.json`
- `logs/sim/planner_v2_sequence_onboarding_200_summary.json`
- `logs/sim/post_lane_reroll_economy_current_boss_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_expanded_boss_confirm_limit_r400_summary.json`
- `logs/sim/post_lane_reroll_probe_r120_summary.json`
- `logs/sim/post_lane_reroll_probe_raw_r120_summary.json`
- `logs/sim/prototype_s1_easy_entry_v91_r240_summary.json`
- `logs/sim/prototype_s1_probe_v91_r240_summary.json`
- `logs/sim/prototype_s1_red035_v91_r240_summary.json`
- `logs/sim/prototype_s1_softened_v91_r240_summary.json`
- `logs/sim/prototype_stability_submission_r120_summary.json`
- `logs/sim/prototype_stability_v91_r120_summary.json`
- `logs/sim/prototype_stability_v91_s1_easy_r120_summary.json`
- `logs/sim/rank_runtime_position_probe_v1_r80_summary.json`
- `logs/sim/rank_runtime_position_smoke_summary.json`
- `logs/sim/run_modifier_basic_direct_r400_summary.json`
- `logs/sim/run_modifier_basic_economy_probe_r120_summary.json`
- `logs/sim/run_modifier_basic_probe_r120_summary.json`
- `logs/sim/run_modifier_candidate_fair_t102_r112_r120_summary.json`
- `logs/sim/run_modifier_candidate_fair_t102_r112_r400_summary.json`
- `logs/sim/run_modifier_candidate_fair_t104_r112_r120_summary.json`
- `logs/sim/run_modifier_candidate_fair_t104_r112_r400_summary.json`
- `logs/sim/run_modifier_candidate_fair_t106_r116_r120_summary.json`
- `logs/sim/run_modifier_candidate_fair_t108_r112_r120_summary.json`
- `logs/sim/run_modifier_candidate_fair_t108_r120_r120_summary.json`
- `logs/sim/run_modifier_candidate_t104_r112_probe_r120_summary.json`
- `logs/sim/run_modifier_candidate_t106_r116_probe_r120_summary.json`
- `logs/sim/run_modifier_candidate_t108_r112_probe_r120_summary.json`
- `logs/sim/run_modifier_candidate_t108_r120_probe_r120_summary.json`
- `logs/sim/run_modifier_high_stakes_direct_r400_summary.json`
- `logs/sim/run_modifier_high_stakes_economy_probe_r120_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_direct_r120_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_direct_r400_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_effective_t102_r120_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r120_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r1_preflight_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r400_summary.json`
- `logs/sim/run_modifier_high_stakes_market_pressure_effective_t104_r800_summary.json`
- `logs/sim/run_modifier_high_stakes_probe_r120_summary.json`
- `logs/sim/run_modifier_pressure_market_probe_t104_r112_r120_summary.json`
- `logs/sim/run_modifier_pressure_market_probe_t104_r112_v9_v10_r400_summary.json`
- `logs/sim/run_modifier_pressure_market_probe_t108_r112_v9_v10_r120_summary.json`
- `logs/sim/runtime_boss_seed_pool_smoke_summary.json`
- `logs/sim/runtime_station_pool_economy_r400_summary.json`
- `logs/sim/runtime_station_pool_leveling_r400_summary.json`
- `logs/sim/runtime_station_pool_leveling_r80_summary.json`
- `logs/sim/runtime_station_pool_market_availability_r80_summary.json`
- `logs/sim/runtime_station_pool_profile_smoke_summary.json`
- `logs/sim/s8_boss_axis_v85_r400_summary.json`
- `logs/sim/station_curve_growth_gate_probe_r120_summary.json`
- `logs/sim/runtime_s4_rank_growth_access_probe_r80_summary.json`
- `logs/sim/runtime_s4_rank_weight_v1_growth_access_confirm_r240_summary.json`
- `logs/sim/runtime_s4_rank_weight_v1_growth_access_final_r400_summary.json`
- `logs/sim/single_s4_growth_access_r400_summary.json`
- `logs/sim/single_s4_growth_access_seed91623_r240_summary.json`

## 피처와 타깃 정의

Target:

- `clear_rate`: 집계된 시뮬레이션 그룹의 clear 비율.

Pre-outcome numeric features:

- `station`
- `tier_index`
- `station_band_index`
- `is_boss_tier`
- `is_late_station`
- `is_final_station`
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
- `run_count`

제외된 필드는 outcome 또는 sample-size metadata이므로, 시뮬레이션 실행 전 후보 추천에는 사용할 수 없다.

## 모델

모델 전략: `auto`.
선택된 모델: `ExtraTreesRegressor`.

선택 이유:

- numeric/categorical simulation setting이 섞인 데이터를 다루는 단순 baseline으로 적합하다.
- station, tier, market, boss, modifier 사이의 비선형 상호작용을 포착할 수 있다.
- 첫 사람 검토에서 feature importance를 확인하기 쉽다.

## 지표

- MAE: 0.0561
- RMSE: 0.1207
- R2: 0.6066

해석:

- post-run result를 볼 수 없으므로 이전 outcome-summary scaffold보다 점수가 약한 것이 자연스럽다.
- RMSE `0.1207` 수준은 큰 오차에 더 민감한 회귀 오차다.
- signal이 약하면 모델 ranking에 기대기 전에 candidate 다양성이나 raw run-level data를 늘리고 MAE/RMSE/R2를 함께 재평가해야 한다.

## 피처 중요도 스냅샷

| Feature | 중요도 |
|---|---:|
| `station` | 0.0982 |
| `station_band_index` | 0.0570 |
| `is_late_station` | 0.0459 |
| `resolved_market_profile_nan` | 0.0422 |
| `market_profile_nan` | 0.0411 |
| `loadout_id_baseline` | 0.0312 |
| `tier_index` | 0.0283 |
| `blind_tier_boss` | 0.0230 |
| `is_boss_tier` | 0.0228 |
| `blind_tier_small` | 0.0200 |

## 산출물

- metrics JSON: `analysis/leveling/models/clear_rate_preoutcome_metrics.json`
- feature importance CSV: `analysis/leveling/models/clear_rate_preoutcome_feature_importance.csv`

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
