#!/usr/bin/env python3
"""Build a compact reference report from full_run_bot trace JSONL."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


def _load_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            if row.get("row_type") == "full_run_trace_event":
                rows.append(row)
    return rows


def _safe_int(value: Any) -> int:
    return value if isinstance(value, int) else 0


def _event_stage(row: dict[str, Any]) -> str:
    stage = row.get("stage")
    tier = row.get("tier")
    if stage is None:
        progress = row.get("run_progress")
        if isinstance(progress, dict):
            stage = progress.get("stage")
    return f"S{stage or '?'} {tier or ''}".strip()


def _battle_summary(rows: list[dict[str, Any]]) -> list[str]:
    actions = [row for row in rows if row.get("event_type") == "battle_action"]
    action_counts = Counter(
        (row.get("action") or {}).get("type", "unknown") for row in actions
    )
    by_stage: dict[str, Counter[str]] = defaultdict(Counter)
    confirm_scores: list[int] = []
    for row in actions:
        stage_key = _event_stage(row)
        action = row.get("action") or {}
        action_type = action.get("type", "unknown")
        by_stage[stage_key][action_type] += 1
        before = row.get("before") or {}
        preview = before.get("confirm_preview")
        if isinstance(preview, dict):
            confirm_scores.append(_safe_int(preview.get("score_added")))

    lines = [
        f"- battle actions: {len(actions)}",
        f"- action mix: {dict(action_counts)}",
    ]
    if confirm_scores:
        lines.append(
            "- confirm preview score: "
            f"min={min(confirm_scores)} "
            f"max={max(confirm_scores)} "
            f"avg={sum(confirm_scores) / len(confirm_scores):.1f}"
        )
    lines.append("- by stage:")
    for stage_key in sorted(by_stage):
        lines.append(f"  - {stage_key}: {dict(by_stage[stage_key])}")
    return lines


def _market_summary(rows: list[dict[str, Any]]) -> list[str]:
    market_rows = [
        row for row in rows if str(row.get("event_type", "")).startswith("market_")
    ]
    decisions = [row for row in rows if row.get("event_type") == "market_decision"]
    bought = Counter(row.get("event_type") for row in market_rows if "bought" in str(row.get("event_type")))
    sold = Counter(row.get("event_type") for row in market_rows if "sold" in str(row.get("event_type")))
    lanes = Counter((row.get("lane") or "unknown") for row in decisions)
    return [
        f"- market state events: {len(market_rows)}",
        f"- market decisions: {len(decisions)}",
        f"- decision lanes: {dict(lanes)}",
        f"- buys: {dict(bought)}",
        f"- sells: {dict(sold)}",
    ]


def _item_summary(rows: list[dict[str, Any]]) -> list[str]:
    starts = [row for row in rows if row.get("event_type") == "battle_item_use_start"]
    applied = [row for row in rows if row.get("event_type") == "battle_item_use_applied"]
    items = Counter(
        ((row.get("item") or {}).get("id") or "unknown") for row in starts
    )
    return [
        f"- battle item attempts: {len(starts)}",
        f"- battle item applied: {len(applied)}",
        f"- battle item ids: {dict(items)}",
    ]


def build_report(rows: list[dict[str, Any]], source: Path) -> str:
    event_counts = Counter(row.get("event_type", "unknown") for row in rows)
    lines = [
        "# Full Run Bot Trace Reference",
        "",
        f"- source: `{source}`",
        f"- rows: {len(rows)}",
        f"- event types: {dict(event_counts)}",
        "",
        "## Battle",
        *_battle_summary(rows),
        "",
        "## Market",
        *_market_summary(rows),
        "",
        "## Items",
        *_item_summary(rows),
        "",
        "## Usage",
        "Use this report for trace sanity only. Use the raw JSONL as the training/reference source.",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_jsonl", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    rows = _load_rows(args.trace_jsonl)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(build_report(rows, args.trace_jsonl), encoding="utf-8")


if __name__ == "__main__":
    main()
