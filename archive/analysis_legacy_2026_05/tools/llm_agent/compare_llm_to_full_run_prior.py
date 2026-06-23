#!/usr/bin/env python3
"""Compare LLM smoke decisions against tracked full_run_bot behavior priors."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


BATTLE_ROW_TYPES = {"llm_station_path_turn"}
MARKET_ROW_TYPES = {"llm_market_decision"}
ITEM_ROW_TYPES = {"llm_battle_item_decision"}
RESOURCE_ACTIONS = {"discardBoard", "discardHand", "moveBoard"}


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))
    return rows


def _stage_key(row: dict[str, Any]) -> str:
    stage = row.get("station") or row.get("stage")
    tier = row.get("blind_tier") or row.get("tier") or "unknown"
    return f"S{stage or '?'}:{tier}"


def _row_action_type(row: dict[str, Any]) -> str:
    for key in ("executed_action_type", "selected_action_type", "baseline_action_type"):
        value = row.get(key)
        if value:
            return str(value)
    return "unknown"


def _market_lane(action_type: str | None) -> str:
    if action_type == "buyJester" or action_type == "sellJester":
        return "jester"
    if action_type == "buyItem":
        return "quickSlot"
    if action_type == "buyTile":
        return "tile"
    return "unknown"


def _top_key(counter: dict[str, int]) -> str | None:
    if not counter:
        return None
    return sorted(counter.items(), key=lambda item: (-item[1], item[0]))[0][0]


def _counter_ratio(counter: dict[str, int], key: str) -> float:
    total = sum(counter.values())
    if total <= 0:
        return 0.0
    return round(counter.get(key, 0) / total, 4)


def _load_prior(path: Path) -> dict[str, Any]:
    prior = json.loads(path.read_text(encoding="utf-8"))
    if prior.get("row_type") != "full_run_policy_prior":
        raise ValueError(f"not a full_run_policy_prior: {path}")
    return prior


def _classify_row(
    row: dict[str, Any],
    prior: dict[str, Any],
    source: Path,
) -> dict[str, Any] | None:
    row_type = row.get("row_type")
    if row_type in BATTLE_ROW_TYPES:
        stage_key = _stage_key(row)
        priors = prior.get("battle_action_priors", {}).get(stage_key, {})
        action_type = _row_action_type(row)
        top = _top_key(priors)
        return {
            "schema_version": 1,
            "row_type": "llm_full_run_prior_comparison",
            "source_path": str(source),
            "input_row_type": row_type,
            "request_id": row.get("request_id"),
            "stage_key": stage_key,
            "turn": row.get("turn"),
            "selected_action_type": row.get("selected_action_type"),
            "executed_action_type": action_type,
            "baseline_action_type": row.get("baseline_action_type"),
            "prior_available": bool(priors),
            "prior_top_action_type": top,
            "prior_selected_ratio": _counter_ratio(priors, action_type),
            "prior_action_counts": priors,
            "diverged_from_baseline": row.get("diverged_from_baseline"),
            "used_fallback": row.get("used_fallback"),
            "policy_guard_overrode": row.get("policy_guard_overrode"),
            "llm_reached_target": row.get("llm_reached_target"),
            "risk_flags": _battle_risks(row, action_type, priors),
        }
    if row_type in MARKET_ROW_TYPES:
        lane = _market_lane(row.get("selected_action_type"))
        priors = prior.get("market_decision_priors", {}).get(lane, {})
        decision = _market_decision(row)
        return {
            "schema_version": 1,
            "row_type": "llm_full_run_prior_comparison",
            "source_path": str(source),
            "input_row_type": row_type,
            "request_id": row.get("request_id"),
            "stage_key": _stage_key(row),
            "selected_action_type": row.get("selected_action_type"),
            "lane": lane,
            "decision": decision,
            "prior_available": bool(priors),
            "prior_top_decision": _top_key(priors),
            "prior_selected_ratio": _counter_ratio(priors, decision),
            "prior_decision_counts": priors,
            "execute_ok": row.get("execute_ok"),
            "risk_flags": _market_risks(row, lane, priors),
        }
    if row_type in ITEM_ROW_TYPES:
        item_observations = prior.get("battle_item_observations", {})
        selected_type = str(row.get("selected_action_type") or "unknown")
        return {
            "schema_version": 1,
            "row_type": "llm_full_run_prior_comparison",
            "source_path": str(source),
            "input_row_type": row_type,
            "request_id": row.get("request_id"),
            "stage_key": _stage_key(row),
            "selected_action_type": selected_type,
            "prior_available": bool(item_observations),
            "prior_item_observations": item_observations,
            "execute_ok": row.get("execute_ok"),
            "risk_flags": _item_risks(row, item_observations),
        }
    return None


def _market_decision(row: dict[str, Any]) -> str:
    action_type = row.get("selected_action_type")
    if action_type in {"buyJester", "buyItem", "buyTile"}:
        return "consider_buy"
    if action_type == "sellJester":
        return "sell_for_replacement"
    if action_type:
        return str(action_type)
    return "unknown"


def _battle_risks(
    row: dict[str, Any],
    action_type: str,
    priors: dict[str, int],
) -> list[str]:
    flags: list[str] = []
    if not priors:
        flags.append("no_reference_prior_for_stage")
    elif action_type not in priors:
        flags.append("action_absent_from_reference_stage")
    if action_type in RESOURCE_ACTIONS and not row.get("llm_reached_target"):
        flags.append("resource_spend_without_target_clear")
    if row.get("policy_guard_overrode") is True:
        flags.append("policy_guard_overrode_llm")
    if row.get("used_fallback") is True:
        flags.append("fallback_used")
    if row.get("diverged_from_baseline") is True:
        flags.append("diverged_from_baseline")
    if row.get("selected_action_type") == "confirm" and not row.get("llm_reached_target"):
        flags.append("confirm_without_target_clear")
    return flags


def _market_risks(row: dict[str, Any], lane: str, priors: dict[str, int]) -> list[str]:
    flags: list[str] = []
    if lane == "unknown":
        flags.append("unknown_market_lane")
    if not priors:
        flags.append("no_reference_prior_for_lane")
    if row.get("execute_ok") is False:
        flags.append("market_execute_failed")
    return flags


def _item_risks(row: dict[str, Any], item_observations: dict[str, int]) -> list[str]:
    flags: list[str] = []
    if not item_observations:
        flags.append("no_reference_item_prior")
    if row.get("execute_ok") is False:
        flags.append("item_execute_failed")
    if row.get("selected_action_type") not in {None, "skip"}:
        flags.append("llm_attempted_item_use")
    return flags


def compare(rows: list[dict[str, Any]], prior: dict[str, Any], source: Path) -> list[dict[str, Any]]:
    comparisons: list[dict[str, Any]] = []
    for row in rows:
        compared = _classify_row(row, prior, source)
        if compared is not None:
            comparisons.append(compared)
    return comparisons


def build_summary(
    comparisons: list[dict[str, Any]],
    *,
    input_path: Path,
    prior_path: Path,
) -> dict[str, Any]:
    by_type = Counter(str(row.get("input_row_type")) for row in comparisons)
    prior_available = sum(1 for row in comparisons if row.get("prior_available"))
    flags: Counter[str] = Counter()
    action_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for row in comparisons:
        for flag in row.get("risk_flags") or []:
            flags[str(flag)] += 1
        stage = str(row.get("stage_key"))
        action = str(row.get("executed_action_type") or row.get("selected_action_type") or row.get("decision"))
        action_counts[stage][action] += 1
    return {
        "schema_version": 1,
        "row_type": "llm_full_run_prior_comparison_summary",
        "input_path": str(input_path),
        "prior_path": str(prior_path),
        "comparison_rows": len(comparisons),
        "rows_by_type": dict(sorted(by_type.items())),
        "prior_available_rows": prior_available,
        "prior_gap_rows": len(comparisons) - prior_available,
        "risk_flags": dict(sorted(flags.items())),
        "actions_by_stage": {
            key: dict(sorted(counter.items())) for key, counter in sorted(action_counts.items())
        },
    }


def build_report(summary: dict[str, Any], comparisons: list[dict[str, Any]]) -> str:
    lines = [
        "# LLM vs Full-run Prior Comparison",
        "",
        "## Summary",
        "",
        f"- input: `{summary['input_path']}`",
        f"- prior: `{summary['prior_path']}`",
        f"- comparison rows: {summary['comparison_rows']}",
        f"- prior available rows: {summary['prior_available_rows']}",
        f"- prior gap rows: {summary['prior_gap_rows']}",
        "",
        "## Rows By Type",
        "",
    ]
    for key, value in summary["rows_by_type"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## Risk Flags", ""])
    if summary["risk_flags"]:
        for key, value in summary["risk_flags"].items():
            lines.append(f"- {key}: {value}")
    else:
        lines.append("- none")
    lines.extend(["", "## Actions By Stage", ""])
    for key, counts in summary["actions_by_stage"].items():
        lines.append(f"- {key}: {counts}")
    lines.extend(["", "## Sample Divergences", ""])
    samples = [row for row in comparisons if row.get("risk_flags")][:12]
    if not samples:
        lines.append("- none")
    else:
        for row in samples:
            lines.append(
                "- {stage} {kind} selected={selected} executed={executed} prior_top={prior} flags={flags}".format(
                    stage=row.get("stage_key"),
                    kind=row.get("input_row_type"),
                    selected=row.get("selected_action_type") or row.get("decision"),
                    executed=row.get("executed_action_type"),
                    prior=row.get("prior_top_action_type") or row.get("prior_top_decision"),
                    flags=",".join(row.get("risk_flags") or []),
                )
            )
    lines.extend(
        [
            "",
            "## Use",
            "",
            "This report is diagnostic only. A prior gap means the tracked reference run does not cover that station/tier yet.",
            "Use repeated divergences in covered S7/S8 stages to decide which LLM prompt or guard rule to improve.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True, help="LLM JSONL output")
    parser.add_argument("--prior", type=Path, required=True, help="full_run_policy_prior.json")
    parser.add_argument("--out", type=Path, required=True, help="comparison JSONL output")
    parser.add_argument("--summary-out", type=Path, required=True)
    parser.add_argument("--report-out", type=Path, required=True)
    args = parser.parse_args()

    prior = _load_prior(args.prior)
    rows = _read_jsonl(args.input)
    comparisons = compare(rows, prior, args.input)
    summary = build_summary(comparisons, input_path=args.input, prior_path=args.prior)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as handle:
        for row in comparisons:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
    args.summary_out.parent.mkdir(parents=True, exist_ok=True)
    args.summary_out.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    args.report_out.parent.mkdir(parents=True, exist_ok=True)
    args.report_out.write_text(build_report(summary, comparisons), encoding="utf-8")
    print(f"comparison_rows: {len(comparisons)}")
    print(f"prior_available_rows: {summary['prior_available_rows']}")
    print(f"out: {args.out}")
    print(f"summary: {args.summary_out}")
    print(f"report: {args.report_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
