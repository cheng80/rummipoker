#!/usr/bin/env python3
"""레벨링 summary JSON을 모델링 준비용 feature table로 변환한다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_OUT = "analysis/leveling/data/features/leveling_feature_table.csv"
DEFAULT_PREOUTCOME_OUT = "analysis/leveling/data/features/leveling_preoutcome_feature_table.csv"


NUMERIC_FIELDS = [
    "station",
    "run_count",
    "clear_rate",
    "avg_score_ratio",
    "avg_turn_count",
    "avg_confirm_action_count",
    "avg_max_single_confirm_score",
    "avg_remaining_deck",
    "avg_remaining_board_discards",
    "avg_remaining_hand_discards",
    "avg_remaining_board_moves",
    "slow_clear_share_of_clears",
    "needs_balance_attention",
    "needs_balance_attention_v2",
]

CATEGORICAL_FIELDS = [
    "experiment_id",
    "loadout_id",
    "blind_tier",
    "difficulty",
    "market_profile",
    "run_modifier",
    "tempo_risk_label",
]

LABEL_FIELDS = [
    "heuristic_labels",
    "heuristic_target_labels_v2",
    "outcome_counts",
]

PREOUTCOME_NUMERIC_FIELDS = [
    "station",
    "tier_index",
    "difficulty_multiplier",
    "target_multiplier",
    "reward_multiplier",
    "sweep_reward_scale",
    "sweep_price_scale",
    "has_market_profile",
    "market_profile_version",
    "has_boss_constraint",
    "boss_family_index",
]

PREOUTCOME_CATEGORICAL_FIELDS = [
    "experiment_id",
    "base_experiment_id",
    "loadout_id",
    "blind_tier",
    "difficulty",
    "market_profile",
    "resolved_market_profile",
    "run_modifier",
    "sim_boss_constraint_id",
]

PREOUTCOME_TARGET_FIELDS = [
    "clear_rate",
    "needs_balance_attention",
    "needs_balance_attention_v2",
]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="run_balance_sim summary JSON을 feature table CSV로 변환합니다.",
    )
    parser.add_argument("summary_json", nargs="+", help="summary JSON 경로")
    parser.add_argument(
        "--feature-mode",
        choices=["outcome_summary", "preoutcome"],
        default="outcome_summary",
        help="feature table 모드. preoutcome은 추천 가능한 사전 조건 feature만 사용합니다.",
    )
    parser.add_argument("--out", default=None, help="CSV 출력 경로")
    parser.add_argument(
        "--metadata-out",
        default=None,
        help="입력 파일 목록과 row 수를 기록할 JSON 경로",
    )
    args = parser.parse_args()

    rows: list[dict[str, Any]] = []
    source_paths = [Path(path) for path in args.summary_json]
    for path in source_paths:
        rows.extend(rows_from_summary(path, feature_mode=args.feature_mode))

    if not rows:
        raise SystemExit("feature table로 만들 group이 없습니다.")

    default_out = DEFAULT_PREOUTCOME_OUT if args.feature_mode == "preoutcome" else DEFAULT_OUT
    out_path = Path(args.out or default_out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if args.feature_mode == "preoutcome":
        fieldnames = [
            "source_path",
            *PREOUTCOME_CATEGORICAL_FIELDS,
            *PREOUTCOME_NUMERIC_FIELDS,
            *PREOUTCOME_TARGET_FIELDS,
            *LABEL_FIELDS,
        ]
    else:
        fieldnames = ["source_path", *CATEGORICAL_FIELDS, *NUMERIC_FIELDS, *LABEL_FIELDS]
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})

    metadata_path = Path(args.metadata_out) if args.metadata_out else out_path.with_suffix(".metadata.json")
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(
        json.dumps(
            {
                "row_count": len(rows),
                "source_paths": [str(path) for path in source_paths],
                "output": str(out_path),
                "feature_mode": args.feature_mode,
                "note": metadata_note(args.feature_mode),
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"feature table: {out_path}")
    print(f"metadata: {metadata_path}")
    print(f"rows: {len(rows)}")
    return 0


def rows_from_summary(path: Path, *, feature_mode: str) -> list[dict[str, Any]]:
    root = json.loads(path.read_text(encoding="utf-8"))
    groups = root.get("groups")
    if not isinstance(groups, list):
        raise SystemExit(f"{path}: groups 배열이 없습니다.")

    sweep = root.get("sweep")
    sweep_context = sweep if isinstance(sweep, dict) else {}
    rows = []
    for raw in groups:
        if not isinstance(raw, dict):
            continue
        if feature_mode == "preoutcome":
            rows.append(preoutcome_row_from_group(path, raw, sweep_context))
        else:
            rows.append(row_from_group(path, raw))
    return rows


def row_from_group(path: Path, raw: dict[str, Any]) -> dict[str, Any]:
    row: dict[str, Any] = {"source_path": str(path)}
    for key in CATEGORICAL_FIELDS:
        row[key] = value_or_empty(raw.get(key))
    for key in NUMERIC_FIELDS:
        row[key] = numeric_or_zero(raw.get(key))

    # 기존 summary key 이름은 호환을 위해 유지한다. feature table에서는 의미를 명확히 바꾼다.
    row["heuristic_labels"] = compact_json(raw.get("ml_labels", []))
    row["heuristic_target_labels_v2"] = compact_json(raw.get("ml_target_labels_v2", {}))
    row["outcome_counts"] = compact_json(raw.get("outcome_counts", {}))
    return row


def preoutcome_row_from_group(
    path: Path,
    raw: dict[str, Any],
    sweep_context: dict[str, Any],
) -> dict[str, Any]:
    run_modifier = value_or_empty(raw.get("run_modifier_id") or raw.get("run_modifier"))
    market_profile = value_or_empty(raw.get("market_profile"))
    resolved_market_profile = value_or_empty(raw.get("resolved_market_profile"))
    boss_constraint = value_or_empty(raw.get("sim_boss_constraint_id"))
    base_experiment = value_or_empty(raw.get("base_experiment_id") or raw.get("experiment_matrix_id"))

    row: dict[str, Any] = {
        "source_path": str(path),
        "experiment_id": value_or_empty(raw.get("experiment_id")),
        "base_experiment_id": base_experiment,
        "loadout_id": value_or_empty(raw.get("loadout_id")),
        "blind_tier": value_or_empty(raw.get("blind_tier")),
        "difficulty": value_or_empty(raw.get("difficulty")),
        "market_profile": market_profile,
        "resolved_market_profile": resolved_market_profile,
        "run_modifier": run_modifier,
        "sim_boss_constraint_id": boss_constraint,
        "station": numeric_or_zero(raw.get("station")),
        "tier_index": tier_index(raw.get("blind_tier")),
        "difficulty_multiplier": difficulty_multiplier(raw.get("difficulty")),
        "target_multiplier": inferred_target_multiplier(run_modifier, base_experiment),
        "reward_multiplier": inferred_reward_multiplier(run_modifier, base_experiment),
        "sweep_reward_scale": numeric_or_default(sweep_context.get("sim_reward_scale"), 1.0),
        "sweep_price_scale": numeric_or_default(sweep_context.get("sim_price_scale"), 1.0),
        "has_market_profile": int(market_profile not in ("", "none")),
        "market_profile_version": market_profile_version(market_profile, resolved_market_profile),
        "has_boss_constraint": int(boss_constraint != ""),
        "boss_family_index": boss_family_index(boss_constraint),
        "clear_rate": numeric_or_zero(raw.get("clear_rate")),
        "needs_balance_attention": numeric_or_zero(raw.get("needs_balance_attention")),
        "needs_balance_attention_v2": numeric_or_zero(raw.get("needs_balance_attention_v2")),
    }
    row["heuristic_labels"] = compact_json(raw.get("ml_labels", []))
    row["heuristic_target_labels_v2"] = compact_json(raw.get("ml_target_labels_v2", {}))
    row["outcome_counts"] = compact_json(raw.get("outcome_counts", {}))
    return row


def value_or_empty(value: Any) -> str:
    if value is None:
        return ""
    return str(value)


def numeric_or_zero(value: Any) -> int | float:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, (int, float)):
        return value
    return 0


def numeric_or_default(value: Any, default: float) -> int | float:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, (int, float)):
        return value
    return default


def tier_index(value: Any) -> int:
    return {"small": 0, "big": 1, "boss": 2}.get(value_or_empty(value), -1)


def difficulty_multiplier(value: Any) -> float:
    return {"relaxed": 0.8, "standard": 1.0, "pressure": 1.2}.get(value_or_empty(value), 1.0)


def inferred_target_multiplier(run_modifier: str, experiment_id: str) -> float:
    if run_modifier == "high_stakes":
        return 1.04
    return token_multiplier(experiment_id, "t", default=1.0)


def inferred_reward_multiplier(run_modifier: str, experiment_id: str) -> float:
    if run_modifier == "high_stakes":
        return 1.12
    return token_multiplier(experiment_id, "r", default=1.0)


def token_multiplier(text: str, prefix: str, *, default: float) -> float:
    import re

    match = re.search(rf"(?:^|_){prefix}(\d{{3}})(?:_|$)", text)
    if not match:
        return default
    return int(match.group(1)) / 100.0


def market_profile_version(*values: str) -> int:
    import re

    for value in values:
        match = re.search(r"(?:_v|v)(\d+)", value)
        if match:
            return int(match.group(1))
    return 0


def boss_family_index(value: str) -> int:
    if value == "":
        return -1
    families = [
        "color",
        "line",
        "face",
        "repeat",
        "single",
        "confirm_count",
        "all_score",
        "first_confirm",
        "target_spike",
        "resource",
    ]
    for index, family in enumerate(families):
        if family in value:
            return index
    return len(families)


def metadata_note(feature_mode: str) -> str:
    if feature_mode == "preoutcome":
        return (
            "Pre-outcome feature table for planned ML transition scaffold. "
            "Outcome summary fields are excluded from model features; clear_rate remains the supervised target. "
            "This is not production ML and does not auto-apply runtime balance changes."
        )
    return "This is ML-transition scaffolding. heuristic_labels is derived from legacy ml_labels silver labels."


def compact_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    raise SystemExit(main())
