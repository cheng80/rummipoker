#!/usr/bin/env python3
"""Convert full_run_bot trace JSONL into sim-friendly decision reference data."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


def _load_events(paths: list[Path]) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for path in paths:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                row = json.loads(line)
                if row.get("row_type") == "full_run_trace_event":
                    row["_source_path"] = str(path)
                    events.append(row)
    events.sort(key=lambda row: (row.get("_source_path", ""), row.get("sequence", 0)))
    return events


def _stage_key(row: dict[str, Any]) -> str:
    stage = row.get("stage")
    tier = row.get("tier")
    if stage is None:
        progress = row.get("run_progress")
        if isinstance(progress, dict):
            stage = progress.get("stage")
    if tier is None:
        before = row.get("before")
        progress = before.get("run_progress") if isinstance(before, dict) else None
        if isinstance(progress, dict):
            tier_index = progress.get("tier_index")
            tier = {0: "small", 1: "big", 2: "boss"}.get(tier_index)
    return f"S{stage or '?'}:{tier or 'unknown'}"


def _counter_dict(counter: Counter[str]) -> dict[str, int]:
    return {key: counter[key] for key in sorted(counter)}


def _battle_reference(events: list[dict[str, Any]]) -> dict[str, Any]:
    actions = [event for event in events if event.get("event_type") == "battle_action"]
    by_stage: dict[str, Counter[str]] = defaultdict(Counter)
    confirm_scores: dict[str, list[int]] = defaultdict(list)
    placement_cells: dict[str, Counter[str]] = defaultdict(Counter)
    for event in actions:
        key = _stage_key(event)
        action = event.get("action") or {}
        action_type = action.get("type", "unknown")
        by_stage[key][action_type] += 1
        if action_type == "place":
            placement_cells[key][f"{action.get('row')},{action.get('col')}"] += 1
        before = event.get("before") or {}
        preview = before.get("confirm_preview")
        if isinstance(preview, dict) and isinstance(preview.get("score_added"), int):
            confirm_scores[key].append(preview["score_added"])

    return {
        "action_counts": {
            key: _counter_dict(counter) for key, counter in sorted(by_stage.items())
        },
        "placement_cells": {
            key: _counter_dict(counter)
            for key, counter in sorted(placement_cells.items())
        },
        "confirm_score_stats": {
            key: {
                "count": len(values),
                "min": min(values),
                "max": max(values),
                "avg": sum(values) / len(values),
            }
            for key, values in sorted(confirm_scores.items())
            if values
        },
    }


def _market_reference(events: list[dict[str, Any]]) -> dict[str, Any]:
    decisions = [event for event in events if event.get("event_type") == "market_decision"]
    lane_decisions: dict[str, Counter[str]] = defaultdict(Counter)
    bought_ids: dict[str, Counter[str]] = defaultdict(Counter)
    for event in decisions:
        lane = str(event.get("lane") or "unknown")
        decision = str(event.get("decision") or "unknown")
        lane_decisions[lane][decision] += 1
        offer = event.get("offer") or event.get("target_offer") or {}
        content_id = offer.get("content_id")
        if content_id:
            bought_ids[lane][str(content_id)] += 1
    return {
        "lane_decisions": {
            lane: _counter_dict(counter)
            for lane, counter in sorted(lane_decisions.items())
        },
        "offer_ids_seen_in_decisions": {
            lane: _counter_dict(counter)
            for lane, counter in sorted(bought_ids.items())
        },
    }


def _item_reference(events: list[dict[str, Any]]) -> dict[str, Any]:
    starts = [event for event in events if event.get("event_type") == "battle_item_use_start"]
    applied = [
        event for event in events if event.get("event_type") == "battle_item_use_applied"
    ]
    by_item = Counter(
        str((event.get("item") or {}).get("id") or "unknown") for event in starts
    )
    return {
        "attempt_count": len(starts),
        "applied_count": len(applied),
        "item_ids": _counter_dict(by_item),
    }


def build_reference(events: list[dict[str, Any]], sources: list[Path]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "row_type": "full_run_decision_reference",
        "sources": [str(path) for path in sources],
        "event_count": len(events),
        "event_counts": _counter_dict(
            Counter(str(event.get("event_type") or "unknown") for event in events)
        ),
        "difficulties": _counter_dict(
            Counter(str(event.get("difficulty") or "unknown") for event in events)
        ),
        "battle": _battle_reference(events),
        "market": _market_reference(events),
        "items": _item_reference(events),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_jsonl", type=Path, nargs="+")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    events = _load_events(args.trace_jsonl)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(build_reference(events, args.trace_jsonl), ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
