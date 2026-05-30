#!/usr/bin/env python3
"""Build reusable ML/LLM reference rows from full_run_bot trace JSONL."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
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


def _stage_key(row: dict[str, Any]) -> str:
    stage = row.get("stage")
    tier = row.get("tier")
    if stage is None:
        progress = row.get("run_progress")
        if isinstance(progress, dict):
            stage = progress.get("stage")
            tier = tier or {0: "small", 1: "big", 2: "boss"}.get(
                progress.get("tier_index")
            )
    if tier is None:
        before = row.get("before")
        progress = before.get("run_progress") if isinstance(before, dict) else None
        if isinstance(progress, dict):
            tier = {0: "small", 1: "big", 2: "boss"}.get(progress.get("tier_index"))
    return f"S{stage or '?'}:{tier or 'unknown'}"


def _session(row: dict[str, Any], side: str = "before") -> dict[str, Any]:
    parent = row.get(side)
    if not isinstance(parent, dict):
        return {}
    session = parent.get("session")
    return session if isinstance(session, dict) else {}


def _confirm_preview(row: dict[str, Any]) -> dict[str, Any]:
    parent = row.get("before")
    if not isinstance(parent, dict):
        return {}
    preview = parent.get("confirm_preview")
    return preview if isinstance(preview, dict) else {}


def _run_progress(row: dict[str, Any]) -> dict[str, Any]:
    progress = row.get("run_progress")
    if isinstance(progress, dict):
        return progress
    before = row.get("before")
    if isinstance(before, dict) and isinstance(before.get("run_progress"), dict):
        return before["run_progress"]
    return {}


def _market(row: dict[str, Any]) -> dict[str, Any]:
    market = row.get("market")
    return market if isinstance(market, dict) else {}


def _offer_id(row: dict[str, Any]) -> str | None:
    offer = row.get("offer") or row.get("target_offer")
    if isinstance(offer, dict):
        content_id = offer.get("content_id")
        return str(content_id) if content_id else None
    return None


def _base_row(row: dict[str, Any], source: Path, row_type: str) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "row_type": row_type,
        "source_path": str(source),
        "sequence": row.get("sequence"),
        "event_type": row.get("event_type"),
        "mode": row.get("mode"),
        "seed": row.get("seed"),
        "difficulty": row.get("difficulty"),
        "locale": row.get("locale"),
        "stage": row.get("stage"),
        "tier": row.get("tier"),
        "stage_key": _stage_key(row),
        "timestamp": row.get("timestamp"),
    }


def _battle_training_row(row: dict[str, Any], source: Path) -> dict[str, Any]:
    session = _session(row)
    progress = _run_progress(row)
    preview = _confirm_preview(row)
    action = row.get("action") if isinstance(row.get("action"), dict) else {}
    resources = session.get("resources") if isinstance(session.get("resources"), dict) else {}
    lines = preview.get("lines") if isinstance(preview.get("lines"), list) else []
    return {
        **_base_row(row, source, "full_run_policy_battle_choice"),
        "policy": row.get("policy"),
        "retry_recovery": row.get("retry_recovery"),
        "features": {
            "score": session.get("score"),
            "target_score": session.get("target_score"),
            "score_ratio": _ratio(session.get("score"), session.get("target_score")),
            "remaining_score": _remaining(session.get("score"), session.get("target_score")),
            "deck_remaining": session.get("deck_remaining"),
            "max_hand_size": session.get("max_hand_size"),
            "hand_size": len(session.get("hand") or []),
            "board_occupied": session.get("board_occupied"),
            "board_pressure": _ratio(session.get("board_occupied"), 25),
            "hand_discards_remaining": resources.get("hand_discards_remaining"),
            "board_discards_remaining": resources.get("board_discards_remaining"),
            "board_moves_remaining": resources.get("board_moves_remaining"),
            "confirm_available": bool(preview.get("ok")),
            "confirm_score_added": preview.get("score_added"),
            "confirm_line_count": preview.get("line_count"),
            "confirm_rank_counts": _rank_counts(lines),
        },
        "target": {
            "action_type": action.get("type"),
            "hand_index": action.get("hand_index"),
            "hand_tile": action.get("hand_tile"),
            "row": action.get("row"),
            "col": action.get("col"),
            "to_row": action.get("to_row"),
            "to_col": action.get("to_col"),
        },
    }


def _market_training_row(row: dict[str, Any], source: Path) -> dict[str, Any]:
    market = _market(row)
    slots = market.get("jester_slots") if isinstance(market.get("jester_slots"), dict) else {}
    offer_id = _offer_id(row)
    return {
        **_base_row(row, source, "full_run_policy_market_choice"),
        "features": {
            "gold": market.get("gold"),
            "jester_slots_used": slots.get("used"),
            "jester_slots_capacity": slots.get("capacity"),
            "quick_slot_capacity": market.get("quick_slot_capacity"),
            "owned_jester_count": len(market.get("owned_jesters") or []),
            "jester_offer_count": len(market.get("jester_offers") or []),
            "item_offer_count": len(market.get("item_offers") or []),
        },
        "target": {
            "lane": row.get("lane"),
            "decision": row.get("decision"),
            "content_id": offer_id,
        },
    }


def _item_training_row(row: dict[str, Any], source: Path) -> dict[str, Any]:
    session = _session(row)
    item = row.get("item") if isinstance(row.get("item"), dict) else {}
    effect = item.get("effect") if isinstance(item.get("effect"), dict) else {}
    planned = row.get("planned_action") if isinstance(row.get("planned_action"), dict) else {}
    return {
        **_base_row(row, source, "full_run_policy_item_choice"),
        "features": {
            "score": session.get("score"),
            "target_score": session.get("target_score"),
            "score_ratio": _ratio(session.get("score"), session.get("target_score")),
            "deck_remaining": session.get("deck_remaining"),
            "board_occupied": session.get("board_occupied"),
        },
        "target": {
            "item_id": item.get("id"),
            "slot_index": row.get("slot_index"),
            "effect_op": effect.get("op"),
            "planned_action_type": planned.get("type"),
            "planned_gain": planned.get("gain"),
        },
    }


def _ratio(numerator: Any, denominator: Any) -> float | None:
    if not isinstance(numerator, (int, float)) or not isinstance(denominator, (int, float)):
        return None
    if denominator == 0:
        return None
    return round(float(numerator) / float(denominator), 4)


def _remaining(score: Any, target: Any) -> int | None:
    if not isinstance(score, int) or not isinstance(target, int):
        return None
    return max(0, target - score)


def _rank_counts(lines: Iterable[Any]) -> dict[str, int]:
    counter: Counter[str] = Counter()
    for line in lines:
        if isinstance(line, dict) and line.get("rank"):
            counter[str(line["rank"])] += 1
    return dict(sorted(counter.items()))


def build_dataset(rows: list[dict[str, Any]], source: Path) -> list[dict[str, Any]]:
    dataset: list[dict[str, Any]] = []
    for row in rows:
        event_type = row.get("event_type")
        if event_type == "battle_action":
            dataset.append(_battle_training_row(row, source))
        elif event_type == "market_decision":
            dataset.append(_market_training_row(row, source))
        elif event_type == "battle_item_use_start":
            dataset.append(_item_training_row(row, source))
    return dataset


def build_prior(rows: list[dict[str, Any]], dataset: list[dict[str, Any]], source: Path) -> dict[str, Any]:
    event_counts = Counter(str(row.get("event_type") or "unknown") for row in rows)
    battle_actions: dict[str, Counter[str]] = defaultdict(Counter)
    confirm_scores: dict[str, list[int]] = defaultdict(list)
    market_decisions: dict[str, Counter[str]] = defaultdict(Counter)
    market_content: dict[str, Counter[str]] = defaultdict(Counter)
    item_usage = Counter()

    for row in dataset:
        if row["row_type"] == "full_run_policy_battle_choice":
            stage = str(row["stage_key"])
            action_type = str(row["target"].get("action_type") or "unknown")
            battle_actions[stage][action_type] += 1
            score = row["features"].get("confirm_score_added")
            if isinstance(score, int):
                confirm_scores[stage].append(score)
        elif row["row_type"] == "full_run_policy_market_choice":
            lane = str(row["target"].get("lane") or "unknown")
            decision = str(row["target"].get("decision") or "unknown")
            market_decisions[lane][decision] += 1
            content_id = row["target"].get("content_id")
            if content_id:
                market_content[lane][str(content_id)] += 1
        elif row["row_type"] == "full_run_policy_item_choice":
            item_id = row["target"].get("item_id")
            if item_id:
                item_usage[str(item_id)] += 1

    return {
        "schema_version": 1,
        "row_type": "full_run_policy_prior",
        "source_path": str(source),
        "trace_rows": len(rows),
        "dataset_rows": len(dataset),
        "event_counts": dict(sorted(event_counts.items())),
        "coverage": {
            "difficulties": dict(Counter(str(row.get("difficulty")) for row in rows)),
            "locales": dict(Counter(str(row.get("locale")) for row in rows)),
            "stage_keys": dict(Counter(_stage_key(row) for row in rows)),
            "has_success_terminal": any(row.get("event_type") == "run_complete" for row in rows),
        },
        "llm_usage": {
            "status": "reference_prior_only",
            "guidance": [
                "Use as full_run_bot behavior prior, not as an automatic balance patch.",
                "Compare LLM decisions against action-type and market lane priors by stage.",
                "Do not treat this single successful seed as general policy truth.",
            ],
        },
        "ml_usage": {
            "status": "chosen_action_descriptive_dataset",
            "limitations": [
                "Single seed and single challenge run.",
                "Chosen actions are present, but full legal-action candidate sets are absent.",
                "Useful for feature sanity and imitation schema smoke before broad collection.",
            ],
        },
        "battle_action_priors": {
            key: dict(sorted(counter.items())) for key, counter in sorted(battle_actions.items())
        },
        "confirm_score_stats": {
            key: {
                "count": len(values),
                "min": min(values),
                "max": max(values),
                "avg": round(sum(values) / len(values), 2),
            }
            for key, values in sorted(confirm_scores.items())
            if values
        },
        "market_decision_priors": {
            key: dict(sorted(counter.items())) for key, counter in sorted(market_decisions.items())
        },
        "market_content_observations": {
            key: dict(sorted(counter.items())) for key, counter in sorted(market_content.items())
        },
        "battle_item_observations": dict(sorted(item_usage.items())),
    }


def build_report(prior: dict[str, Any]) -> str:
    lines = [
        "# Full-run Policy Dataset Report",
        "",
        "## Summary",
        "",
        f"- source: `{prior['source_path']}`",
        f"- trace rows: {prior['trace_rows']}",
        f"- dataset rows: {prior['dataset_rows']}",
        f"- success terminal: {prior['coverage']['has_success_terminal']}",
        "",
        "## Event Coverage",
        "",
    ]
    for key, value in prior["event_counts"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Battle Priors", ""])
    for key, counts in prior["battle_action_priors"].items():
        lines.append(f"- {key}: {counts}")
    lines.extend(["", "## Market Priors", ""])
    for key, counts in prior["market_decision_priors"].items():
        lines.append(f"- {key}: {counts}")
    lines.extend(["", "## Item Observations", ""])
    for key, value in prior["battle_item_observations"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(
        [
            "",
            "## Judgment",
            "",
            "This is useful as a high-stage full-run behavior reference and schema smoke.",
            "It is not enough for model training by itself because it is a single successful seed and does not include full legal-action candidate sets.",
            "",
            "## Recommended Next Use",
            "",
            "1. Feed `full_run_policy_prior.json` into LLM comparison reports as a behavior prior.",
            "2. Use `full_run_policy_dataset.jsonl` to validate ML feature extraction and chosen-action target shape.",
            "3. Collect more standard/challenge multi-seed traces before training or balance recommendation.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_jsonl", type=Path)
    parser.add_argument("--dataset-out", type=Path, required=True)
    parser.add_argument("--prior-out", type=Path, required=True)
    parser.add_argument("--report-out", type=Path, required=True)
    args = parser.parse_args()

    rows = _read_jsonl(args.trace_jsonl)
    dataset = build_dataset(rows, args.trace_jsonl)
    prior = build_prior(rows, dataset, args.trace_jsonl)

    args.dataset_out.parent.mkdir(parents=True, exist_ok=True)
    with args.dataset_out.open("w", encoding="utf-8") as handle:
        for row in dataset:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
    args.prior_out.parent.mkdir(parents=True, exist_ok=True)
    args.prior_out.write_text(
        json.dumps(prior, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    args.report_out.parent.mkdir(parents=True, exist_ok=True)
    args.report_out.write_text(build_report(prior), encoding="utf-8")
    print(f"trace_rows: {len(rows)}")
    print(f"dataset_rows: {len(dataset)}")
    print(f"dataset: {args.dataset_out}")
    print(f"prior: {args.prior_out}")
    print(f"report: {args.report_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
