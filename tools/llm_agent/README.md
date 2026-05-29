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
