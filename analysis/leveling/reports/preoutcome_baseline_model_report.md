# Leveling Pre-Outcome Transition Scaffold Report

## Scope

이 리포트는 planned ML transition scaffold다.
기존 outcome-derived summary feature를 제거하고, 시뮬레이션 실행 전에 알 수 있는 조건만 feature로 사용해 `clear_rate`를 예측한다.
모델은 후보 추천 루프를 설계하기 위한 오프라인 분석 도구이며, production ML이 아니고 런타임 target, boss, market, economy 값을 자동 변경하지 않는다.
이 산출물만으로 실제 ML 이행 완료를 주장하지 않는다. 후보 재시뮬레이션과 사람 승인 보고서가 별도로 필요하다.

## Dataset

- feature table: `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv`
- rows: 13113
- train rows: 9834
- test rows: 3279
- target: `clear_rate`
- feature mode: `preoutcome`

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

## Feature And Target Definition

Target:

- `clear_rate`: aggregated simulation group clear share.

Pre-outcome numeric features:

- `station`
- `tier_index`
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
- `has_boss_constraint`
- `boss_family_index`

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

Excluded from model features:

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

These excluded fields are outcomes or sample-size metadata, so they cannot be used for candidate recommendation before a simulation is run.

## Model

Model type: `RandomForestRegressor`.

Reason:

- It is a simple baseline for mixed numeric/categorical simulation settings.
- It can capture non-linear station, tier, market, boss, and modifier interactions.
- Feature importance is inspectable enough for a first human review.

## Metric

- MAE: 0.0367
- R2: 0.1056

Interpretation:

- This score is expected to be weaker than the previous outcome-summary scaffold because it cannot peek at post-run results.
- Useful signal here means candidate settings have enough structure for a first recommendation loop.
- Poor signal means more candidate diversity or raw run-level data is needed before relying on model ranking.

## Feature Importance Snapshot

| Feature | Importance |
|---|---:|
| `loadout_id_baseline__shop_slot_market_v9` | 0.1939 |
| `station` | 0.1119 |
| `boss_family_index` | 0.0749 |
| `sweep_reward_scale` | 0.0479 |
| `loadout_id_baseline` | 0.0294 |
| `sweep_price_scale` | 0.0273 |
| `resolved_market_profile_s1_candidate_uncommon_build_jester` | 0.0239 |
| `resolved_market_profile_s1_candidate_planet_rank_level` | 0.0230 |
| `sim_boss_constraint_id_target_spike_wall` | 0.0226 |
| `resolved_market_profile_s1_candidate_tarot_build_pack` | 0.0219 |

## Artifacts

- metrics JSON: `analysis/leveling/models/clear_rate_preoutcome_metrics.json`
- feature importance CSV: `analysis/leveling/models/clear_rate_preoutcome_feature_importance.csv`

## Recommendation Boundary

Allowed next use:

- rank candidate settings for follow-up simulation
- identify which pre-run settings explain clear-rate variance
- choose small candidate probes for human review

Not allowed:

- runtime auto-balancing
- direct target/boss/market/economy patch without resimulation
- treating this as player telemetry modeling
