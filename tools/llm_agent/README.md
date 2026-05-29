# RummiPoker LLM Agent

This folder contains the local Ollama runner for prompt-only RummiPoker autoplay experiments.

## Scope

The LLM policy is not a balance oracle.
It is only a slow strategic sampler and decision-label source.
Bulk balance decisions remain based on Dart simulator runs, `planner_v3`, `contest_policy_v1`, and tracked leveling reports.

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
Dart-side validation must fallback to `contest_policy_v1`.
