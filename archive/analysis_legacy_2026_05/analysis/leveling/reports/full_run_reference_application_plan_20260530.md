# Full-run Reference Application Plan 2026-05-30

## Current Data

- Reference folder: `data/full_run_bot/reference_runs/ko_challenge_20260530_130411/`
- Raw trace: `435` events
- Derived policy dataset: `392` chosen-action rows
- Dataset split:
  - battle choices: `368`
  - market choices: `20`
  - battle item choices: `4`
- Result: `ko`, `challenge`, seed `91460`, S8 boss clear

## Usefulness Judgment

This run is useful as a high-stage full-run behavior reference.

Good uses:

- Validate that trace extraction captures battle, market, and item choices.
- Compare LLM decisions against full-run bot action priors by stage/tier.
- Smoke-test ML feature extraction and chosen-action target shapes.
- Keep a tracked example of runtime evidence outside `/private/tmp`.

Bad uses:

- Do not train or tune balance directly from this single run.
- Do not treat its purchases or board placement pattern as a general optimum.
- Do not use it as a clear-rate model source; it has one successful outcome and no failure contrast.

Key limitation:

- The trace records chosen actions, but not the full legal-action candidate set available at each step. It is descriptive imitation data, not a complete supervised policy dataset yet.

## LLM Application

1. Load `full_run_policy_prior.json` when producing LLM smoke reports.
2. Compare each LLM-selected action against the reference prior at the same stage/tier:
   - action type distribution
   - confirm timing
   - resource-spend timing
   - market lane and buy/sell pattern
3. Report divergence as diagnostics, not as automatic failure.
4. Keep `rummi_full_run_policy_guide.md` as the human-readable policy contract; use this reference only as evidence-backed priors.

Done criteria:

- LLM reports show `reference_prior_path`, same-stage action prior, selected action, and divergence notes.
- Invalid or low-value LLM actions still fall back to `full_run_policy_v1`.

## ML Application

1. Use `full_run_policy_dataset.jsonl` to validate feature columns:
   - battle: score ratio, board pressure, deck remaining, confirm preview, resources
   - market: gold, slot usage, offer counts, selected lane/content
   - item: item id, effect op, planned action type/gain
2. Do not fit production recommendation models from this run alone.
3. Once multi-seed traces exist, create a wider imitation dataset with:
   - chosen action
   - legal-action candidates
   - baseline policy score
   - outcome after action where available

Done criteria:

- Feature extractor can read multiple reference folders and emit one combined dataset.
- Training scripts reject datasets that are below minimum seed/run diversity.

## Data Expansion

Next reference collection order:

1. Add matching `ko standard` full-run trace.
2. Add `ko challenge` fresh full-cycle trace from S1 when feasible.
3. Add `en`, `ja`, `zh-CN`, `zh-TW` locale cycles.
4. Add multi-seed standard/challenge traces in chunks.
5. Preserve failed/retry/game-over traces separately for bottleneck detection.

Minimum useful ML threshold:

- At least `20` seeds per difficulty for descriptive model probes.
- At least `50` seeds per difficulty with legal-action snapshots before imitation model training.

## Next Implementation Steps

1. Add a loader that merges all `data/full_run_bot/reference_runs/*/full_run_policy_dataset.jsonl` files.
2. Add an LLM comparison report that reads `full_run_policy_prior.json`.
3. Extend future full-run trace logging with legal-action candidate snapshots at decision time.
4. Add automatic copy/export from `/private/tmp` run output to a project reference folder when a run is promoted.
