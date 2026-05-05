# Leveling Pre-Outcome Candidate Resimulation Report

## Scope

This report closes the first planned ML transition loop at scaffold level:

1. Build a pre-outcome feature table.
2. Train an offline baseline model.
3. Inspect metrics and feature importance.
4. Re-simulate the current model-relevant candidate axis.
5. Keep runtime changes gated behind human review.

This is not production ML. It does not auto-apply target, boss, market, or economy changes.

## Artifacts

| Artifact | Path |
|---|---|
| pre-outcome feature table | `analysis/leveling/data/features/leveling_preoutcome_feature_table.csv` |
| metadata | `analysis/leveling/data/features/leveling_preoutcome_feature_table.metadata.json` |
| metric JSON | `analysis/leveling/models/clear_rate_preoutcome_metrics.json` |
| feature importance | `analysis/leveling/models/clear_rate_preoutcome_feature_importance.csv` |
| baseline report | `analysis/leveling/reports/preoutcome_baseline_model_report.md` |
| resimulation summary | `logs/sim/ml_preoutcome_candidate_v1_r120_summary.json` |
| resimulation report | `logs/sim/ml_preoutcome_candidate_v1_r120_report.md` |

## Feature Table

Rows: `4666`

Included pre-outcome feature groups:

- station and blind tier
- difficulty and inferred target/reward multiplier
- market profile and resolved market profile
- run modifier
- boss constraint family
- sim sweep reward/price scale

Excluded from model features:

- score ratio
- turn count
- confirm action count
- max single confirm score
- remaining deck/discards/moves
- slow clear share
- run count

Those excluded fields are post-outcome values or sample-size metadata. They can be used for diagnosis, but not for recommending a candidate before running a simulation.

## Baseline Metric

Model: `RandomForestRegressor`

| Metric | Value |
|---|---:|
| rows | 4666 |
| train rows | 3499 |
| test rows | 1167 |
| MAE | 0.0439 |
| R2 | 0.2208 |

Interpretation:

- The model is weaker than the older outcome-summary scaffold, as expected.
- The older scaffold could see post-run results; this one cannot.
- `R2 0.2208` is enough for a first candidate-ranking scaffold, not enough for autonomous balancing.

Top feature importance snapshot:

| Feature | Importance |
|---|---:|
| `loadout_id_baseline__shop_slot_market_v9` | 0.3372 |
| `station` | 0.1237 |
| `boss_family_index` | 0.0595 |
| `loadout_id_baseline` | 0.0581 |
| `sim_boss_constraint_id_single_rank_pressure` | 0.0214 |

Reading:

- The current summary dataset is still strongly shaped by loadout/market encoded identities.
- The next stronger ML iteration should generate a broader candidate grid so the model can compare intervention settings more directly.

## Candidate Resimulation

Command:

```bash
python3 tools/sim/ml_sweep_dataset.py --mode experiment_matrix --runs 120 --seed 120600 --bot planner_v2 --stations 1,2,3,4,5,6,7,8 --difficulty standard --experiment-ids base_score_curve_v2_boss_constraint_pool_v4_s1_soft_v2_late_guard_v1_s1_resource_weighted_boss_v3_late_boss_068 --loadout-ids progression_route_balanced,progression_route_power --market-profiles none,shop_slot_market_v9 --summary-only --jobs 4 --out-prefix logs/sim/ml_preoutcome_candidate_v1_r120
```

Result:

| Loadout | Market | Path clear | Avg total turn | Top bottlenecks | Stop reasons |
|---|---|---:|---:|---|---|
| balanced | none | 60.8% | 1410.4 | S4 boss 8, S3 boss 5, S1 boss 5, S8 boss 5 | board 26, draw 21 |
| power | none | 61.7% | 1344.1 | S8 boss 10, S1 boss 5, S3 big 4, S3 boss 3 | board 36, draw 10 |
| balanced | `shop_slot_market_v9` | 72.5% | 1450.8 | S8 boss 7, S2 boss 4, S5 big 3, S1 big 3 | board 24, draw 9 |
| power | `shop_slot_market_v9` | 70.8% | 1323.2 | S1 big 5, S8 boss 4, S3 boss 4, S7 boss 4 | board 28, draw 7 |

Interpretation:

- `shop_slot_market_v9` remains a strong positive market axis in this r120 probe.
- It does not erase S8 boss pressure.
- The result is a candidate-validation signal, not a new runtime patch by itself.

## Decision

Current decision:

- Keep the pre-outcome pipeline as planned transition scaffold.
- Do not auto-apply any runtime change from this model.
- Treat `shop_slot_market_v9` as still valid enough for follow-up analysis, while noting that this r120 run is not a long-run economic closure.

Next ML work, when reopened:

- generate a broader pre-outcome candidate grid for target/boss/market/economy levers
- train on candidate settings rather than encoded loadout identities
- compare candidate predictions against fresh resimulation
- write a human-review recommendation table before touching runtime values
