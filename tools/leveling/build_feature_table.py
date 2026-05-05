#!/usr/bin/env python3
"""레벨링 summary JSON을 모델 학습용 feature table로 변환한다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_OUT = "analysis/leveling/data/features/leveling_feature_table.csv"


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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="run_balance_sim summary JSON을 feature table CSV로 변환합니다.",
    )
    parser.add_argument("summary_json", nargs="+", help="summary JSON 경로")
    parser.add_argument("--out", default=DEFAULT_OUT, help="CSV 출력 경로")
    parser.add_argument(
        "--metadata-out",
        default=None,
        help="입력 파일 목록과 row 수를 기록할 JSON 경로",
    )
    args = parser.parse_args()

    rows: list[dict[str, Any]] = []
    source_paths = [Path(path) for path in args.summary_json]
    for path in source_paths:
        rows.extend(rows_from_summary(path))

    if not rows:
        raise SystemExit("feature table로 만들 group이 없습니다.")

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
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
                "note": "heuristic_labels is derived from legacy ml_labels silver labels.",
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


def rows_from_summary(path: Path) -> list[dict[str, Any]]:
    root = json.loads(path.read_text(encoding="utf-8"))
    groups = root.get("groups")
    if not isinstance(groups, list):
        raise SystemExit(f"{path}: groups 배열이 없습니다.")

    rows = []
    for raw in groups:
        if not isinstance(raw, dict):
            continue
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


def compact_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    raise SystemExit(main())
