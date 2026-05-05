# Actual ML Transition Human Review

## Scope

This report closes the current offline ML transition gate for human review.

It does not enable production ML, runtime auto-balancing, or automatic target/boss/market/economy patches. The model is used only to rank candidate settings and select fresh resimulation probes.

## Data Sufficiency

| Dataset | Rows | Target | Metric | Judgment |
|---|---:|---|---|---|
| station/tier pre-outcome table | 14,544 | `clear_rate` | MAE 0.0360, R2 0.1548 | Enough for feature sanity checks, still weak for autonomous recommendation |
| sequence/path pre-outcome table | 92 | `path_clear_rate` | MAE 0.0651, R2 0.4202 | Better aligned with run-level decisions, still small |

The existing heuristic pipeline was used as a bootstrap source:

- historical simulation summary files were folded into the pre-outcome feature table;
- `failure_counts` and `failure_stop_reason_counts` are retained as heuristic diagnostics;
- heuristic labels remain silver-label context, not production ML truth.

The data was still sparse for target candidate comparison, so an additional r80 target grid was generated:

- `logs/sim/ml_actual_target_grid_v1_r80_summary.json`
- `logs/sim/ml_actual_target_grid_v1_r80_report.md`

Fresh economy probes were also generated for the top economy candidates:

- `logs/sim/ml_actual_economy_r040_p220_v1_r80_summary.json`
- `logs/sim/ml_actual_economy_r040_p240_v1_r80_summary.json`

After boss pool expansion, additional inputs were added:

- `logs/sim/boss_expansion_confirm_limit_v1_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_current_boss_r400_summary.json`
- `logs/sim/post_lane_reroll_economy_expanded_boss_confirm_limit_r400_summary.json`

The expanded-boss data improves coverage but does not make the station/tier model strong enough for autonomous recommendations.

## Model Artifacts

| Artifact | Path |
|---|---|
| station/tier feature table | `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv` |
| sequence feature table | `analysis/leveling/data/features/leveling_preoutcome_sequence_feature_table.csv` |
| station/tier metric | `analysis/leveling/models/clear_rate_preoutcome_metrics.json` |
| sequence metric | `analysis/leveling/models/path_clear_rate_preoutcome_sequence_metrics.json` |
| station/tier recommendation CSV | `analysis/leveling/models/preoutcome_candidate_recommendations.csv` |
| station/tier recommendation report | `analysis/leveling/reports/preoutcome_candidate_recommendation_report.md` |
| sequence model report | `analysis/leveling/reports/preoutcome_sequence_baseline_model_report.md` |

## Candidate Resimulation

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

Interpretation:

- The target grid is still r80, so it is exploratory.
- `boss 1.02` does not immediately collapse v9 and keeps S8 boss failures visible.
- `boss 0.98` makes power+v9 too strong in this seed.
- Current target is not cleanly dominated because balanced+v9 dipped in this r80 seed.
- No target change should be applied without a larger confirmation run.

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

Interpretation:

- In both economy r80 probes, balanced+v9 is lower than balanced+none.
- That is a red flag under the current policy: a good market proxy should not be worse than none/control.
- r80 is not enough to close the economy gate, but it is enough to prevent calling the post lane-reroll economy state closed.

### Expanded Boss Economy Fresh r120

The updated recommendation table ranked `economy_r038_p240_spend_choice` and `economy_r040_p240_spend_choice` above the current baseline, but fresh resimulation did not support applying either candidate.

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

Sources:

- `logs/sim/ml_expanded_boss_economy_r038_p240_v1_r120_summary.json`
- `logs/sim/ml_expanded_boss_economy_r038_p240_v1_r120_economy_audit.json`
- `logs/sim/ml_expanded_boss_economy_r040_p240_v1_r120_summary.json`
- `logs/sim/ml_expanded_boss_economy_r040_p240_v1_r120_economy_audit.json`

Interpretation:

- Both top economy candidates still make balanced+v9 lower than balanced+none.
- That violates the policy expectation that a good market proxy should not be worse than none/control.
- Keep `reward 0.40 / price 2.2 / catalog_normalized_v1` as the safer baseline for now.
- The updated model is useful for selecting probes, but fresh resimulation remains the gate.

## Human Review Decision

Current decision:

- Do not apply target changes.
- Do not apply new economy changes.
- Keep the current runtime economy baseline. Expanded boss r400 economy has no immediate warning, but the model's top economy candidates failed fresh r120 on balanced+v9.
- Treat the offline ML transition as implemented for candidate ranking, feature rebuild, metric generation, and fresh-resimulation filtering. It is still not production ML and does not auto-apply runtime values.

Next required gate:

- human approval before any runtime target/boss/market/economy value change.
- if more ML work is needed, expand the candidate grid around boss pool placement and market availability rather than applying the top economy candidates directly.
