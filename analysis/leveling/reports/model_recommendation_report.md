# Leveling ML Transition Scaffold Report

## Scope

이 리포트는 실제 ML 전환 완료 보고서가 아니다.
현재 모델은 outcome-derived summary feature로 `clear_rate`를 설명하는 baseline이며, target score, boss severity, market weight, economy scale 후보를 추천하지 않는다.
런타임 밸런스를 자동으로 바꾸지 않으며, 현재 산출물을 ML 기반 밸런스 자동 조정 근거로 사용하지 않는다.

## Dataset

- feature table: `analysis/leveling/data/features/leveling_feature_table.csv`
- rows: 4666
- train rows: 3499
- test rows: 1167
- target: `clear_rate`

Source summaries:

- `analysis/leveling/data/raw/prototype_stability_submission_r120_summary.json`
- `analysis/leveling/data/raw/run_modifier_high_stakes_market_pressure_effective_t104_r800_summary.json`
- `analysis/leveling/data/raw/run_modifier_candidate_fair_t104_r112_r400_summary.json`
- `analysis/leveling/data/raw/run_modifier_pressure_market_probe_t104_r112_v9_v10_r400_summary.json`
- `analysis/leveling/data/raw/station_curve_growth_gate_probe_r120_summary.json`

Each row is a simulation group aggregated by experiment, loadout, blind tier, difficulty, market profile, run modifier, station, and outcome summary values. The current dataset is simulation-derived. It is not live player telemetry.

## Feature And Target Definition

Target:

- `clear_rate`: clear share for the aggregated simulation group.

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

- MAE: 0.0120
- R2: 0.9407

Interpretation:

- MAE around `0.0120` is the average held-out group prediction error for `clear_rate`.
- R2 around `0.9407` means the model explains most held-out variance in this simulation dataset when the value is high.
- This is not evidence that the game is fully balanced.
- This is also not evidence that ML transition is complete.
- It only shows that the current summary rows can be loaded into a supervised modeling scaffold and that outcome-derived features can explain held-out clear-rate variance.

## Feature Importance Snapshot

| Feature | Importance |
|---|---:|
| `avg_score_ratio` | 0.6942 |
| `run_count` | 0.1764 |
| `avg_remaining_deck` | 0.0673 |
| `avg_turn_count` | 0.0350 |
| `avg_remaining_board_discards` | 0.0116 |
| `avg_confirm_action_count` | 0.0042 |
| `avg_max_single_confirm_score` | 0.0039 |
| `avg_remaining_board_moves` | 0.0013 |
| `avg_remaining_hand_discards` | 0.0011 |
| `station` | 0.0008 |

Reading:

- If outcome-derived features dominate, the model is more descriptive than prescriptive.
- Future recommendation models should add pre-battle configuration features so they can suggest interventions rather than only explain outcomes.

## Artifacts

- metrics JSON: `analysis/leveling/models/clear_rate_metrics.json`
- feature importance CSV: `analysis/leveling/models/clear_rate_feature_importance.csv`

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
