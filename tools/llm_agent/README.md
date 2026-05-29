# RummiPoker LLM Agent

This folder contains the local Ollama runner for prompt-only RummiPoker autoplay experiments.

## Scope

The LLM policy is not a balance oracle.
It is only a slow strategic sampler and decision-label source.
Bulk balance decisions remain based on Dart simulator runs, `planner_v3`, `full_run_policy_v1`, and tracked leveling reports.

## Local Model

Current local target:

- backend: `ollama`
- model: `gemma4:e4b`
- temperature: `0.2`
- top_p: `0.9`
- timeout: `60s`

Check local setup:

```bash
ollama list
ollama show gemma4:e4b
```

## Run

Export deterministic smoke requests:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/export_smoke_requests.dart \
  --out logs/llm/requests_smoke.jsonl \
  --count 10 \
  --seed 20260529
```

```bash
python3 tools/llm_agent/run_llm_policy.py \
  --input logs/llm/requests_smoke.jsonl \
  --out logs/llm/responses_smoke.jsonl \
  --backend ollama \
  --model gemma4:e4b \
  --temperature 0.2 \
  --timeout-seconds 60
```

The runner accepts JSON or JSONL request files.
Raw request/response logs stay under `logs/llm/` and are not tracked by git.
The runner sends an Ollama JSON schema whose `selected_action_id` is an enum of the exported legal action ids. This is required for `gemma4:e4b`; prompt-only JSON mode produced invalid keys such as `action` or `selection`.
The prompt also includes `prompts/rummi_full_run_policy_guide.md`; Dart runners
mirror the same contract by pre-ranking/filtering legal actions before the
request is sent.

Validate response ids against the exported legal action list:

```bash
python3 tools/llm_agent/validate_llm_responses.py \
  --requests logs/llm/requests_smoke.jsonl \
  --responses logs/llm/responses_smoke.jsonl \
  --report-out analysis/leveling/reports/llm_decision_cache_smoke_20260529.md \
  --csv-out analysis/leveling/models/llm_decision_cache_smoke_20260529.csv
```

Run a one-step decision-cache execution smoke:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_decision_cache_smoke.dart \
  --responses logs/llm/responses_smoke_20260529_schema.jsonl \
  --out logs/llm/decision_cache_one_step_20260529.jsonl \
  --report-out analysis/leveling/reports/llm_decision_cache_one_step_20260529.md \
  --count 10 \
  --seed 20260529
```

Run a short multi-turn loop with baseline comparison:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_llm_turn_loop_smoke.dart \
  --out logs/llm/turn_loop_smoke_20260529.jsonl \
  --report-out analysis/leveling/reports/llm_turn_loop_smoke_20260529.md \
  --runs 2 \
  --turn-cap 3 \
  --model gemma4:e4b
```

This invokes the local Ollama runner once per turn, validates the returned
`selected_action_id`, falls back to `full_run_policy_v1` on invalid responses,
and records divergence from a same-seed baseline policy. Keep raw JSONL under
`logs/llm/`; commit only the summary report.

Run the first real-blind battle smoke:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_llm_battle_smoke.dart \
  --out logs/llm/battle_smoke_20260529.jsonl \
  --report-out analysis/leveling/reports/llm_battle_smoke_20260529.md \
  --runs 1 \
  --turn-cap 4 \
  --model gemma4:e4b
```

This starts real `RummiPokerGridSession` blind states through
`RummiRunProgress.startBlind`, then collects validated LLM decisions turn by
turn. It is the bridge from fixture smoke to future long-run data collection;
shop path, item inventory, and full economy are still outside this smoke.

Run an S1-S8-capable station path smoke:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_llm_station_path_smoke.dart \
  --out logs/llm/station_path_smoke_20260529.jsonl \
  --report-out analysis/leveling/reports/llm_station_path_smoke_20260529.md \
  --station-start 1 \
  --station-end 8 \
  --tiers small,big,boss \
  --turn-cap-per-blind 4 \
  --continue-after-fail \
  --model gemma4:e4b
```

This uses the real `BlindSelectionSpecBuilder` S1-S8 target table, resources,
and boss modifier assignment. `--continue-after-fail` is useful for checking all
S1-S8 specs even when a short smoke does not clear an early blind. Market
buy/sell/reroll decision contracts are included as smoke rows. It is still not
complete balance evidence until battle item-use and full economy application are
added.

For item-use contract smoke, seed a quick-slot item and enough gold for market
choices:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_llm_station_path_smoke.dart \
  --out logs/llm/station_path_item_market_smoke_20260530.jsonl \
  --report-out analysis/leveling/reports/llm_station_path_item_market_smoke_20260530.md \
  --station-start 1 \
  --station-end 1 \
  --tiers small \
  --turn-cap-per-blind 1 \
  --initial-gold 20 \
  --initial-item board_scrap \
  --continue-after-fail \
  --model gemma4:e4b
```

For cashout/economy handoff smoke, force a cleared blind with `--initial-score`
equal to the target:

```bash
/Users/cheng80/flutter/bin/dart run tools/llm_agent/run_llm_station_path_smoke.dart \
  --out logs/llm/station_path_cashout_smoke_20260530.jsonl \
  --report-out analysis/leveling/reports/llm_station_path_cashout_smoke_20260530.md \
  --station-start 1 \
  --station-end 1 \
  --tiers small \
  --turn-cap-per-blind 1 \
  --initial-score 480 \
  --continue-after-fail \
  --model gemma4:e4b
```

## Response Contract

The model must return JSON only:

```json
{
  "schema_version": 1,
  "status": "ok",
  "selected_action_id": "ACTION_ID",
  "confidence": 0.72,
  "reason": "short reason"
}
```

Dart validation uses only `selected_action_id`.
`confidence` and `reason` are log fields.

## Failure

The runner returns `status=error` JSON for timeout, invalid JSON, empty response, or Ollama connection failure.
Dart-side validation must fallback to `full_run_policy_v1`.
