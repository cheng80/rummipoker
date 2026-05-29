#!/usr/bin/env python3
"""Build compact simulation reference data from full-run trace JSONL."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize RummiPoker full-run trace events for later sim probes.",
    )
    parser.add_argument("--trace", required=True, help="Full-run trace JSONL path")
    parser.add_argument("--out", required=True, help="Reference JSON output path")
    parser.add_argument("--report-out", help="Markdown report output path")
    args = parser.parse_args()

    rows = list(_read_jsonl(Path(args.trace)))
    reference = build_reference(rows, source_path=args.trace)

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(reference, ensure_ascii=False, indent=2) + "\n")

    if args.report_out:
        report = Path(args.report_out)
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(build_report(reference), encoding="utf-8")

    print(f"trace_rows: {len(rows)}")
    print(f"out: {out}")
    if args.report_out:
        print(f"report: {args.report_out}")
    return 0


def _read_jsonl(path: Path):
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                yield json.loads(line)


def build_reference(rows: list[dict[str, Any]], *, source_path: str) -> dict[str, Any]:
    event_counts = Counter(row.get("event_type", "unknown") for row in rows)
    battle_actions: dict[str, Counter[str]] = defaultdict(Counter)
    market_actions: dict[str, Counter[str]] = defaultdict(Counter)
    item_actions: dict[str, Counter[str]] = defaultdict(Counter)
    confirm_ranks: dict[str, Counter[str]] = defaultdict(Counter)
    market_offers: dict[str, Counter[str]] = defaultdict(Counter)
    market_buys: dict[str, Counter[str]] = defaultdict(Counter)
    terminal_rows = []

    for row in rows:
        key = _scope_key(row)
        event_type = row.get("event_type")
        if event_type == "battle_action":
            battle_actions[key][str(row.get("executed_action_type"))] += 1
            confirm = row.get("confirm_preview")
            if isinstance(confirm, dict):
                for line in confirm.get("lines", []):
                    if isinstance(line, dict):
                        confirm_ranks[key][str(line.get("rank"))] += 1
        elif event_type == "battle_item_decision":
            selected = row.get("selected_action")
            if isinstance(selected, dict):
                item_actions[key][str(selected.get("type"))] += 1
        elif event_type == "market_enter":
            for offer in row.get("jester_offers", []):
                if isinstance(offer, dict):
                    market_offers[f"{key}|jester"][str(offer.get("content_id"))] += 1
            for offer in row.get("item_offers", []):
                if isinstance(offer, dict):
                    market_offers[f"{key}|item"][str(offer.get("content_id"))] += 1
        elif event_type == "market_decision":
            selected = row.get("selected_action")
            if isinstance(selected, dict):
                action_type = str(selected.get("type"))
                market_actions[key][action_type] += 1
                content_id = selected.get("content_id")
                if action_type.startswith("buy") and content_id:
                    market_buys[key][str(content_id)] += 1
        elif event_type == "blind_terminal":
            terminal_rows.append(
                {
                    "difficulty": row.get("difficulty"),
                    "station": row.get("station"),
                    "blind_tier": row.get("blind_tier"),
                    "stop_reason": row.get("stop_reason"),
                    "reached_target": row.get("reached_target"),
                    "score": (row.get("session") or {}).get("score_toward_blind")
                    if isinstance(row.get("session"), dict)
                    else None,
                    "target_score": row.get("target_score"),
                }
            )

    return {
        "schema_version": 1,
        "source_path": source_path,
        "row_count": len(rows),
        "event_counts": dict(event_counts),
        "battle_action_priors": _counter_map(battle_actions),
        "battle_item_action_priors": _counter_map(item_actions),
        "confirm_rank_observations": _counter_map(confirm_ranks),
        "market_action_priors": _counter_map(market_actions),
        "market_offer_observations": _counter_map(market_offers),
        "market_buy_observations": _counter_map(market_buys),
        "terminal_rows": terminal_rows,
    }


def _scope_key(row: dict[str, Any]) -> str:
    return "|".join(
        [
            str(row.get("difficulty", "unknown")),
            f"S{row.get('station', 'unknown')}",
            str(row.get("blind_tier", "unknown")),
        ]
    )


def _counter_map(groups: dict[str, Counter[str]]) -> dict[str, dict[str, int]]:
    return {key: dict(counter) for key, counter in sorted(groups.items())}


def build_report(reference: dict[str, Any]) -> str:
    lines = [
        "# Full Run Trace Reference",
        "",
        "## Summary",
        "",
        f"- source: `{reference['source_path']}`",
        f"- rows: {reference['row_count']}",
        "",
        "## Event Counts",
        "",
    ]
    for key, value in reference["event_counts"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Terminals", ""])
    for row in reference["terminal_rows"]:
        lines.append(
            "- {difficulty} S{station} {blind_tier}: {score}/{target_score} "
            "stop={stop_reason} cleared={reached_target}".format(**row)
        )
    lines.extend(["", "## Use", ""])
    lines.append(
        "This reference is evidence for candidate probes and policy comparison, "
        "not an automatic balance patch input."
    )
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    raise SystemExit(main())
