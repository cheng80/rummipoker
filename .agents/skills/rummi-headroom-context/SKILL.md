---
name: rummi-headroom-context
description: Preserve and recover long Rummi Poker working context with Headroom. Use for full_run_bot logs, large trace JSONL, long test/build outputs, large diffs, simulation reports, or next-session context compression when exact originals must remain traceable.
---

# Rummi Headroom Context

Use this skill from the repository root: `/Users/cheng80/Desktop/flame_binggo_card`.

Purpose:

- Compress long logs, traces, diffs, and reports without losing the original source path.
- Keep enough context for later Codex turns while avoiding raw mega-output in chat.
- Never treat a compressed summary as source-of-truth for exact code edits.

## Quick Commands

Project wrapper:

```bash
python3 tools/headroom_context.py --label full-run-ko \
  /path/to/runner_console.log \
  /path/to/full_run_trace.jsonl \
  /path/to/full_run_trace_reference.md \
  /path/to/full_run_decision_reference.json
```

Fallback-only mode, useful when Headroom import is slow or broken:

```bash
python3 tools/headroom_context.py --no-headroom --label test-failure /tmp/test.log
```

Outputs:

- `output/headroom_context/<timestamp>_<label>/headroom_summary.md`
- `output/headroom_context/<timestamp>_<label>/headroom_manifest.json`

## Workflow

1. Use for long context only: full-run bot logs, `*.jsonl` traces, multi-hundred-line test failures, large `git diff`, simulation CSV/MD reports, or large doc sweeps.
2. Run the wrapper and report the generated summary path.
3. Read `headroom_summary.md` first when resuming context.
4. If Headroom emitted retrieve hashes, check `headroom_manifest.json` under `headroom_retrieve_hashes`.
5. Before fixing exact code, checking a line number, or validating a bug, open the original file path from `headroom_manifest.json`.
6. If a summary becomes part of the active plan, mention its path in the final response or current planning doc.

## MCP Option

If Headroom MCP tools are exposed in the session, prefer:

- `headroom_compress` for live content compression.
- `headroom_retrieve` for exact recovery by stored hash/key.
- `headroom_stats` for compression stats.

For local setup, the server command is:

```bash
headroom mcp serve
```

The project wrapper records original absolute paths, SHA-256 hashes, and any retrieve hashes Headroom prints in compressed output.

## Guardrails

- Do not compress short outputs where exact text is clearer.
- Do not commit raw generated logs or JSONL just because they were compressed.
- Do not edit production code based only on `headroom_summary.md`; inspect the original source/log first.
- For `풀런봇`, compress logs after run or interruption before making long-context conclusions.
