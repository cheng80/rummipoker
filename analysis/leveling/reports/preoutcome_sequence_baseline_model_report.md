# Leveling ML Transition Scaffold Report

## Scope

이 리포트는 실제 ML 전환 완료 보고서가 아니다.
현재 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target score, boss severity, market weight, economy scale 후보를 추천하지 않는다.
런타임 밸런스를 자동으로 바꾸지 않으며, 현재 산출물을 ML 기반 밸런스 자동 조정 근거로 사용하지 않는다.

## Dataset

- feature table: `analysis/leveling/data/features/leveling_preoutcome_sequence_feature_table.csv`
- rows: 92
- train rows: 69
- test rows: 23
- target: `path_clear_rate`

Source summaries:

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

Each row is a simulation group aggregated by experiment, loadout, blind tier, difficulty, market profile, run modifier, station, and outcome summary values. The current dataset is simulation-derived. It is not live player telemetry.

## Feature And Target Definition

Target:

- `path_clear_rate`: clear share for the aggregated simulation group.

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

Silver-label columns are preserved in the feature table as analysis context, but this first model predicts the selected target directly rather than training on heuristic labels.

## Model

Model type: `RandomForestRegressor`.

Reason:

- It handles non-linear interactions between station, blind tier, market profile, and resource residuals without requiring a fixed linear assumption.
- It can mix numeric and one-hot categorical features through a simple preprocessing pipeline.
- Feature importance is easy to inspect for a first scaffold report.

This model is intentionally offline-only and descriptive. It does not patch runtime target scores, boss modifiers, market weights, or economy constants.

## Metric

- MAE: 0.0651
- R2: 0.4202

Interpretation:

- MAE around `0.0651` is the average held-out group prediction error for `path_clear_rate`.
- R2 around `0.4202` means the model explains most held-out variance in this simulation dataset when the value is high.
- This is not evidence that the game is fully balanced.
- This is also not evidence that ML transition is complete.
- It only shows that the current summary rows can be loaded into a supervised modeling scaffold and that outcome-derived features can explain held-out clear-rate variance.

## Feature Importance Snapshot

| Feature | Importance |
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

Reading:

- If outcome-derived features dominate, the model is more descriptive than prescriptive.
- Future recommendation models should add pre-battle configuration features so they can suggest interventions rather than only explain outcomes.

## Artifacts

- metrics JSON: `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json`
- feature importance CSV: `analysis/leveling/models/path_clear_rate_preoutcome_sequence_feature_importance.csv`

## Interpretation Rule

휴리스틱 라벨은 초기 silver label로만 사용한다. 실제 유저 데이터가 충분해지면 target과 metric을 다시 정의한다.

## Recommendation Boundary

Current valid use:

- Rank which simulation factors are associated with clear-rate changes.
- Identify candidate regions for follow-up probes.
- Verify that the project has enough structured summary data to start designing a real ML transition.

Current invalid use:

- Automatically changing runtime target score.
- Automatically changing boss cycle/severity.
- Automatically changing market candidate weights.
- Treating this as player-behavior modeling.
- Claiming that balance is already ML-driven.

## Next ML Step

Actual ML transition has not happened yet. The next model must add pre-outcome candidate features so it can recommend interventions rather than only explain outcomes:

- target multiplier candidate
- boss modifier category and severity
- market candidate availability/weight profile
- reward scale and price scale
- reroll lane spend and final gold features after the recent reroll split

Then run a candidate loop:

1. Model ranks candidate settings offline.
2. Simulator runs the top candidates.
3. Human review checks policy constraints and playfeel.
4. Only approved candidates are applied to runtime data/code.
