#!/usr/bin/env python3
"""Validate LLM selected_action_id values against exported legal actions."""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from pathlib import Path
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate RummiPoker LLM response JSONL against request JSONL.",
    )
    parser.add_argument("--requests", required=True)
    parser.add_argument("--responses", required=True)
    parser.add_argument("--report-out", required=True)
    parser.add_argument("--csv-out", default=None)
    args = parser.parse_args()

    requests = {row["request_id"]: row for row in read_jsonl(Path(args.requests))}
    responses = list(read_jsonl(Path(args.responses)))
    rows = [validate_response(response, requests) for response in responses]
    report = build_report(rows, request_count=len(requests))

    report_path = Path(args.report_out)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report, encoding="utf-8")
    if args.csv_out:
        write_csv(Path(args.csv_out), rows)

    print(f"report: {report_path}")
    if args.csv_out:
        print(f"csv: {args.csv_out}")
    return 0 if all(row["is_valid"] for row in rows) else 1


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def validate_response(
    response: dict[str, Any],
    requests: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    request_id = response.get("request_id")
    request = requests.get(str(request_id))
    if request is None:
        return base_row(response, is_valid=False, invalid_reason="missing_request")

    legal_actions = {
        action["id"]: action for action in request.get("legal_actions", [])
    }
    if response.get("status", "ok") != "ok":
        return base_row(
            response,
            is_valid=False,
            invalid_reason=str(response.get("error_code") or "status_not_ok"),
        )
    selected = response.get("selected_action_id")
    if not selected:
        return base_row(
            response,
            is_valid=False,
            invalid_reason="missing_selected_action_id",
        )
    action = legal_actions.get(str(selected))
    if action is None:
        return base_row(response, is_valid=False, invalid_reason="unknown_action_id")
    return {
        **base_row(response, is_valid=True, invalid_reason=""),
        "selected_action_type": action.get("type", ""),
        "clears_target": bool(action.get("clears_target", False)),
        "preview_score": action.get("preview_score", ""),
        "legal_action_count": len(legal_actions),
    }


def base_row(
    response: dict[str, Any],
    *,
    is_valid: bool,
    invalid_reason: str,
) -> dict[str, Any]:
    return {
        "request_id": response.get("request_id", ""),
        "model": response.get("model", ""),
        "status": response.get("status", "ok"),
        "selected_action_id": response.get("selected_action_id", ""),
        "selected_action_type": "",
        "is_valid": is_valid,
        "invalid_reason": invalid_reason,
        "confidence": response.get("confidence", ""),
        "latency_ms": response.get("latency_ms", ""),
        "clears_target": "",
        "preview_score": "",
        "legal_action_count": "",
        "reason": response.get("reason", ""),
    }


def build_report(rows: list[dict[str, Any]], *, request_count: int) -> str:
    response_count = len(rows)
    valid_count = sum(1 for row in rows if row["is_valid"])
    invalid_count = response_count - valid_count
    latency_values = [
        float(row["latency_ms"])
        for row in rows
        if isinstance(row.get("latency_ms"), (int, float))
        or str(row.get("latency_ms", "")).replace(".", "", 1).isdigit()
    ]
    avg_latency = sum(latency_values) / len(latency_values) if latency_values else 0
    type_counts = Counter(
        str(row["selected_action_type"])
        for row in rows
        if row["selected_action_type"]
    )
    invalid_counts = Counter(
        str(row["invalid_reason"])
        for row in rows
        if row["invalid_reason"]
    )
    lines = [
        "# LLM Decision Cache Smoke Report",
        "",
        "## Summary",
        "",
        f"- requests: {request_count}",
        f"- responses: {response_count}",
        f"- valid responses: {valid_count}",
        f"- invalid responses: {invalid_count}",
        f"- invalid_action_rate: {invalid_count / response_count if response_count else 0:.4f}",
        f"- fallback_rate_if_executed: {invalid_count / response_count if response_count else 0:.4f}",
        f"- avg_latency_ms: {avg_latency:.1f}",
        "",
        "## Selected Action Types",
        "",
    ]
    if type_counts:
        for action_type, count in type_counts.most_common():
            lines.append(f"- {action_type}: {count}")
    else:
        lines.append("- none")
    lines.extend(["", "## Invalid Reasons", ""])
    if invalid_counts:
        for reason, count in invalid_counts.most_common():
            lines.append(f"- {reason}: {count}")
    else:
        lines.append("- none")
    lines.extend(
        [
            "",
            "## Scope",
            "",
            "This smoke validates request/response schema compatibility only.",
            "It is not a full autoplay run and must not be used as a balance recommendation.",
        ],
    )
    return "\n".join(lines) + "\n"


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "request_id",
        "model",
        "status",
        "selected_action_id",
        "selected_action_type",
        "is_valid",
        "invalid_reason",
        "confidence",
        "latency_ms",
        "clears_target",
        "preview_score",
        "legal_action_count",
        "reason",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    raise SystemExit(main())
