---
name: rummi-leveling-ml
description: Run and evolve the Rummi Poker leveling/ML pipeline: fresh Dart simulator data collection, chunked contest_policy_v1 runs, economy audit, feature table generation, supervised model smoke reports, and safe tracked report updates. Use when the user says "레벨링 ML", "fresh 데이터", "밸런스 ML", "학습 데이터 쌓기", "시뮬 데이터 수집", or asks to continue the internal leveling data pipeline.
---

# Rummi Leveling ML

Use this skill from the repository root: `/Users/cheng80/Desktop/flame_binggo_card`.

Core policy:

- Use internal Dart simulator logs first. Do not rely on external poker/RL datasets for runtime balance truth.
- Keep old/archive rows out of current training inputs unless explicitly used as low-trust historical prior.
- Keep raw JSONL, generated CSV, venvs, and logs ignored. Commit lightweight metadata, metrics, feature importance, reports, scripts, and docs.
- Models create candidate evidence only. Never auto-apply target, boss, economy, market, item, or Jester balance changes without human review.
- Prefer `/Users/cheng80/flutter/bin/dart` and `/Users/cheng80/flutter/bin/flutter`.

## Quick Run

For the standard fresh pipeline, run:

```bash
.agents/skills/rummi-leveling-ml/scripts/run_fresh_leveling_pipeline.sh
```

Useful overrides:

```bash
CHUNKS=3 RUNS_PER_CHUNK=2 DO_MODEL=0 \
  .agents/skills/rummi-leveling-ml/scripts/run_fresh_leveling_pipeline.sh
```

```bash
BOT=planner_v2 OUT_PREFIX=logs/sim/fresh_runtime_planner_probe \
  .agents/skills/rummi-leveling-ml/scripts/run_fresh_leveling_pipeline.sh
```

Grid sweep mode widens the default market/loadout axes:

```bash
MODE=grid CHUNKS=12 RUNS_PER_CHUNK=4 \
  .agents/skills/rummi-leveling-ml/scripts/run_fresh_leveling_pipeline.sh
```

Model target controls:

```bash
MODEL_TARGETS="clear_rate avg_score_ratio cleared_majority" \
  .agents/skills/rummi-leveling-ml/scripts/run_fresh_leveling_pipeline.sh
```

Default pipeline:

1. `tools/sim/chunked_balance_run.py --resume`
2. `tools/sim/economy_audit.py`
3. `tools/leveling/build_feature_table.py`
4. optional `tools/leveling/train_leveling_model.py`
   - `clear_rate`: regression
   - `avg_score_ratio`: regression
   - `cleared_majority`: classification
5. print row count, summary paths, metadata/report paths

## Manual Checks

After a run, inspect:

```bash
wc -l "$OUT_PREFIX.jsonl"
cat "$OUT_PREFIX"_manifest.json
cat "$OUT_PREFIX"_economy_audit.json
```

Expected quality gates:

- JSONL rows >= requested minimum, normally 5,000+ for a real fresh dataset.
- manifest `complete: true`.
- `missing_cost_events: 0` in economy audit for shop slot market traces.
- model smoke report explicitly says whether it is only scaffold or usable for candidate ranking.

## Commit Guidance

Commit these if changed:

- `analysis/leveling/data/features/*.metadata.json`
- `analysis/leveling/models/**/*_metrics.json`
- `analysis/leveling/models/**/*_feature_importance.csv`
- `analysis/leveling/reports/*.md`
- `tools/sim/*.dart`, `tools/sim/*.py`, `tools/leveling/*.py`
- this skill and its scripts

Do not commit:

- `logs/`
- `analysis/leveling/generated/`
- `.venv_leveling/`
- raw JSONL or generated feature CSV

Validation before commit:

```bash
/Users/cheng80/flutter/bin/dart analyze tools/sim/run_balance_sim.dart tools/sim/summarize_balance_jsonl.dart
/Users/cheng80/flutter/bin/flutter test test/tools/sim/chunked_balance_run_test.dart
python3 -m py_compile tools/sim/chunked_balance_run.py
```
