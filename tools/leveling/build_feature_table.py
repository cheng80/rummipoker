#!/usr/bin/env python3
"""레벨링 summary JSON을 모델링 준비용 feature table로 변환한다."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


DEFAULT_OUT = "analysis/leveling/generated/features/leveling_feature_table.csv"
DEFAULT_PREOUTCOME_OUT = "analysis/leveling/generated/features/leveling_preoutcome_feature_table.csv"


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
    "station_band_index",
    "is_boss_tier",
    "is_late_station",
    "is_final_station",
    "difficulty_multiplier",
    "target_multiplier",
    "small_target_multiplier",
    "big_target_multiplier",
    "boss_target_multiplier",
    "s1_boss_target_multiplier",
    "s2_boss_target_multiplier",
    "s3_boss_target_multiplier",
    "reward_multiplier",
    "sweep_reward_scale",
    "sweep_price_scale",
    "has_market_profile",
    "market_profile_version",
    "has_boss_constraint",
    "boss_family_index",
    "boss_level_index",
    "boss_pressure_index",
    "is_runtime_boss_modifier",
    "economy_pressure_index",
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
    "sim_economy_mode",
    "sim_market_budget_mode",
    "sim_market_spend_mode",
    "sim_price_band_mode",
    "sim_market_choice_mode",
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
        choices=["outcome_summary", "preoutcome", "preoutcome_sequence"],
        default="outcome_summary",
        help="feature table 모드. preoutcome은 추천 가능한 사전 조건 feature만 사용합니다.",
    )
    parser.add_argument("--out", default=None, help="CSV 출력 경로")
    parser.add_argument(
        "--metadata-out",
        default=None,
        help="입력 파일 목록과 row 수를 기록할 JSON 경로",
    )
    parser.add_argument(
        "--max-rows",
        type=int,
        default=0,
        help="0보다 크면 deterministic even sampling으로 CSV row 수를 제한합니다.",
    )
    args = parser.parse_args()

    rows: list[dict[str, Any]] = []
    source_paths = [Path(path) for path in args.summary_json]
    for path in source_paths:
        rows.extend(rows_from_summary(path, feature_mode=args.feature_mode))

    if not rows:
        raise SystemExit("feature table로 만들 group이 없습니다.")
    source_row_count = len(rows)
    if args.max_rows > 0 and len(rows) > args.max_rows:
        rows = even_sample_rows(rows, args.max_rows)

    default_out = DEFAULT_PREOUTCOME_OUT if args.feature_mode == "preoutcome" else DEFAULT_OUT
    out_path = Path(args.out or default_out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if args.feature_mode in {"preoutcome", "preoutcome_sequence"}:
        fieldnames = [
            "source_path",
            *PREOUTCOME_CATEGORICAL_FIELDS,
            *PREOUTCOME_NUMERIC_FIELDS,
            *PREOUTCOME_TARGET_FIELDS,
            *LABEL_FIELDS,
        ]
        if args.feature_mode == "preoutcome_sequence":
            fieldnames = [
                "source_path",
                *PREOUTCOME_CATEGORICAL_FIELDS,
                "station_path_length",
                "tier_path_length",
                "difficulty_multiplier",
                "target_multiplier",
                "small_target_multiplier",
                "big_target_multiplier",
                "boss_target_multiplier",
                "s1_boss_target_multiplier",
                "s2_boss_target_multiplier",
                "s3_boss_target_multiplier",
                "reward_multiplier",
                "sweep_reward_scale",
                "sweep_price_scale",
                "has_market_profile",
                "market_profile_version",
                "path_clear_rate",
                "heuristic_failure_counts",
                "heuristic_stop_reason_counts",
            ]
    else:
        fieldnames = ["source_path", *CATEGORICAL_FIELDS, *NUMERIC_FIELDS, *LABEL_FIELDS]
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})

    metadata_path = Path(args.metadata_out) if args.metadata_out else default_metadata_path(out_path)
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(
        json.dumps(
            {
                "row_count": len(rows),
                "source_row_count": source_row_count,
                "max_rows": args.max_rows,
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
    if source_row_count != len(rows):
        print(f"source rows: {source_row_count}")
    return 0


def even_sample_rows(rows: list[dict[str, Any]], max_rows: int) -> list[dict[str, Any]]:
    if max_rows <= 0 or len(rows) <= max_rows:
        return rows
    if max_rows == 1:
        return [rows[0]]
    last_index = len(rows) - 1
    return [
        rows[round(index * last_index / (max_rows - 1))]
        for index in range(max_rows)
    ]


def default_metadata_path(out_path: Path) -> Path:
    parts = out_path.parts
    generated_marker = ("analysis", "leveling", "generated", "features")
    if parts[: len(generated_marker)] == generated_marker:
        return Path("analysis/leveling/data/features") / out_path.with_suffix(".metadata.json").name
    return out_path.with_suffix(".metadata.json")


def rows_from_summary(path: Path, *, feature_mode: str) -> list[dict[str, Any]]:
    root = json.loads(path.read_text(encoding="utf-8"))
    sweep = root.get("sweep")
    sweep_context = sweep if isinstance(sweep, dict) else {}
    if feature_mode == "preoutcome_sequence":
        groups = root.get("sequence_groups")
        if not isinstance(groups, list):
            return []
        return [
            preoutcome_sequence_row_from_group(path, raw, sweep_context)
            for raw in groups
            if isinstance(raw, dict)
        ]

    groups = root.get("groups")
    if not isinstance(groups, list):
        raise SystemExit(f"{path}: groups 배열이 없습니다.")
    rows = []
    for raw in groups:
        if not isinstance(raw, dict):
            continue
        if feature_mode == "preoutcome":
            rows.append(preoutcome_row_from_group(path, raw, sweep_context))
        else:
            rows.append(row_from_group(path, raw))
    return rows


def preoutcome_sequence_row_from_group(
    path: Path,
    raw: dict[str, Any],
    sweep_context: dict[str, Any],
) -> dict[str, Any]:
    run_modifier = value_or_empty(raw.get("run_modifier_id") or raw.get("run_modifier"))
    market_profile = value_or_empty(raw.get("market_profile"))
    resolved_market_profile = value_or_empty(raw.get("resolved_market_profile"))
    base_experiment = value_or_empty(raw.get("base_experiment_id") or raw.get("experiment_matrix_id"))
    station_path = raw.get("station_path")
    tier_path = raw.get("tier_path")
    return {
        "source_path": str(path),
        "base_experiment_id": base_experiment,
        "loadout_id": value_or_empty(raw.get("loadout_id")),
        "blind_tier": "path",
        "difficulty": value_or_empty(raw.get("difficulty")),
        "market_profile": market_profile,
        "resolved_market_profile": resolved_market_profile,
        "run_modifier": run_modifier,
        "sim_boss_constraint_id": value_or_empty(raw.get("sim_boss_constraint_id")),
        "sim_economy_mode": value_or_empty(sweep_context.get("sim_economy_mode") or "trace_only"),
        "sim_market_budget_mode": value_or_empty(sweep_context.get("sim_market_budget_mode") or "none"),
        "sim_market_spend_mode": value_or_empty(sweep_context.get("sim_market_spend_mode") or "none"),
        "sim_price_band_mode": value_or_empty(sweep_context.get("sim_price_band_mode") or "none"),
        "sim_market_choice_mode": value_or_empty(sweep_context.get("sim_market_choice_mode") or "none"),
        "station_path_length": len(station_path) if isinstance(station_path, list) else 0,
        "tier_path_length": len(tier_path) if isinstance(tier_path, list) else 0,
        "difficulty_multiplier": difficulty_multiplier(raw.get("difficulty")),
        "target_multiplier": inferred_target_multiplier(run_modifier, base_experiment),
        "small_target_multiplier": numeric_or_default(raw.get("small_target_multiplier"), 1.0),
        "big_target_multiplier": numeric_or_default(raw.get("big_target_multiplier"), 1.0),
        "boss_target_multiplier": numeric_or_default(raw.get("boss_target_multiplier"), 1.0),
        "s1_boss_target_multiplier": numeric_or_default(raw.get("s1_boss_target_multiplier"), 1.0),
        "s2_boss_target_multiplier": numeric_or_default(raw.get("s2_boss_target_multiplier"), 1.0),
        "s3_boss_target_multiplier": numeric_or_default(raw.get("s3_boss_target_multiplier"), 1.0),
        "reward_multiplier": inferred_reward_multiplier(run_modifier, base_experiment),
        "sweep_reward_scale": numeric_or_default(sweep_context.get("sim_reward_scale"), 1.0),
        "sweep_price_scale": numeric_or_default(sweep_context.get("sim_price_scale"), 1.0),
        "has_market_profile": int(market_profile not in ("", "none")),
        "market_profile_version": market_profile_version(market_profile, resolved_market_profile),
        "path_clear_rate": numeric_or_zero(raw.get("path_clear_rate")),
        "heuristic_failure_counts": compact_json(raw.get("failure_counts", {})),
        "heuristic_stop_reason_counts": compact_json(raw.get("failure_stop_reason_counts", {})),
    }


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
        "station_band_index": station_band_index(raw.get("station")),
        "is_boss_tier": int(value_or_empty(raw.get("blind_tier")) == "boss"),
        "is_late_station": int(numeric_or_zero(raw.get("station")) >= 6),
        "is_final_station": int(numeric_or_zero(raw.get("station")) >= 8),
        "difficulty_multiplier": difficulty_multiplier(raw.get("difficulty")),
        "target_multiplier": inferred_target_multiplier(run_modifier, base_experiment),
        "small_target_multiplier": numeric_or_default(
            raw.get("small_target_multiplier"),
            1.0,
        ),
        "big_target_multiplier": numeric_or_default(
            raw.get("big_target_multiplier"),
            1.0,
        ),
        "boss_target_multiplier": numeric_or_default(
            raw.get("boss_target_multiplier"),
            1.0,
        ),
        "s1_boss_target_multiplier": numeric_or_default(
            raw.get("s1_boss_target_multiplier"),
            1.0,
        ),
        "s2_boss_target_multiplier": numeric_or_default(
            raw.get("s2_boss_target_multiplier"),
            1.0,
        ),
        "s3_boss_target_multiplier": numeric_or_default(
            raw.get("s3_boss_target_multiplier"),
            1.0,
        ),
        "reward_multiplier": inferred_reward_multiplier(run_modifier, base_experiment),
        "sweep_reward_scale": numeric_or_default(sweep_context.get("sim_reward_scale"), 1.0),
        "sweep_price_scale": numeric_or_default(sweep_context.get("sim_price_scale"), 1.0),
        "has_market_profile": int(market_profile not in ("", "none")),
        "market_profile_version": market_profile_version(market_profile, resolved_market_profile),
        "has_boss_constraint": int(boss_constraint != ""),
        "boss_family_index": boss_family_index(boss_constraint),
        "boss_level_index": boss_level_index(boss_constraint),
        "boss_pressure_index": boss_pressure_index(boss_constraint),
        "is_runtime_boss_modifier": int(is_runtime_boss_modifier(boss_constraint)),
        "economy_pressure_index": economy_pressure_index(
            sweep_context.get("sim_reward_scale"),
            sweep_context.get("sim_price_scale"),
        ),
        "sim_economy_mode": value_or_empty(sweep_context.get("sim_economy_mode") or "trace_only"),
        "sim_market_budget_mode": value_or_empty(sweep_context.get("sim_market_budget_mode") or "none"),
        "sim_market_spend_mode": value_or_empty(sweep_context.get("sim_market_spend_mode") or "none"),
        "sim_price_band_mode": value_or_empty(sweep_context.get("sim_price_band_mode") or "none"),
        "sim_market_choice_mode": value_or_empty(sweep_context.get("sim_market_choice_mode") or "none"),
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


def station_band_index(value: Any) -> int:
    station = int(numeric_or_zero(value))
    if station <= 2:
        return 0
    if station <= 5:
        return 1
    if station <= 7:
        return 2
    return 3


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
    family_patterns = [
        ("tile_color", ["color", "red_", "yellow_", "blue_", "black_"]),
        ("line_kind", ["line", "row_", "column_", "diagonal_"]),
        ("face_tile", ["face"]),
        ("repeat_rank", ["repeat"]),
        ("single_rank", ["single"]),
        ("confirm_count", ["confirm_count"]),
        ("confirm_limit", ["confirm_limit"]),
        ("all_score", ["all_score"]),
        ("first_confirm", ["first_confirm"]),
        ("target_spike", ["target_spike"]),
        ("resource", ["resource", "discard"]),
        ("draw_refill", ["refill", "draw"]),
        ("reward_tax", ["reward_tax"]),
        ("memory", ["memory", "decay"]),
        ("jester", ["jester"]),
    ]
    for index, (_, patterns) in enumerate(family_patterns):
        if any(pattern in value for pattern in patterns):
            return index
    return len(family_patterns)


def boss_level_index(value: str) -> int:
    if value == "":
        return -1
    level_map = {
        "red_dampener_v1": 0,
        "yellow_dampener_v1": 0,
        "row_line_dampener_v1": 0,
        "blue_dampener_v1": 1,
        "face_tile_dampener_v1": 1,
        "face_tile_dampener": 1,
        "black_dampener_v1": 2,
        "column_line_dampener_v1": 2,
        "diagonal_line_dampener_v1": 3,
        "repeat_rank_pressure_v4": 3,
        "single_rank_pressure": 3,
        "all_score_dampener_v1": 4,
        "all_score_dampener": 4,
        "first_confirm_tax_v1": 5,
        "first_confirm_tax": 5,
        "confirm_count_tax_v2": 5,
        "confirm_limit_tax_v1": 6,
    }
    return level_map.get(value, 7)


def boss_pressure_index(value: str) -> float:
    if value == "":
        return 0.0
    pressure_map = {
        "red_dampener_v1": 0.35,
        "yellow_dampener_v1": 0.40,
        "blue_dampener_v1": 0.40,
        "black_dampener_v1": 0.40,
        "row_line_dampener_v1": 0.25,
        "column_line_dampener_v1": 0.25,
        "diagonal_line_dampener_v1": 0.25,
        "face_tile_dampener_v1": 0.35,
        "face_tile_dampener": 0.35,
        "all_score_dampener_v1": 0.20,
        "all_score_dampener": 0.20,
        "first_confirm_tax_v1": 0.30,
        "first_confirm_tax": 0.30,
        "confirm_count_tax_v2": 0.25,
        "confirm_limit_tax_v1": 0.30,
        "repeat_rank_pressure_v4": 0.20,
        "single_rank_pressure": 0.30,
    }
    return pressure_map.get(value, 0.0)


def is_runtime_boss_modifier(value: str) -> bool:
    return value in {
        "red_dampener_v1",
        "yellow_dampener_v1",
        "blue_dampener_v1",
        "black_dampener_v1",
        "row_line_dampener_v1",
        "column_line_dampener_v1",
        "diagonal_line_dampener_v1",
        "face_tile_dampener_v1",
        "all_score_dampener_v1",
        "first_confirm_tax_v1",
        "confirm_count_tax_v2",
        "confirm_limit_tax_v1",
        "repeat_rank_pressure_v4",
        "single_rank_pressure",
    }


def economy_pressure_index(reward_scale: Any, price_scale: Any) -> float:
    reward = float(numeric_or_default(reward_scale, 1.0))
    price = float(numeric_or_default(price_scale, 1.0))
    if reward <= 0:
        return price
    return price / reward



def metadata_note(feature_mode: str) -> str:
    if feature_mode == "preoutcome":
        return (
            "Pre-outcome feature table for planned ML transition scaffold. "
            "Outcome summary fields are excluded from model features; clear_rate remains the supervised target. "
            "This is not production ML and does not auto-apply runtime balance changes."
        )
    if feature_mode == "preoutcome_sequence":
        return (
            "Pre-outcome sequence-level feature table for planned ML transition. "
            "The supervised target is path_clear_rate. Failure counts are kept as heuristic diagnostics, not model features. "
            "This does not auto-apply runtime balance changes."
        )
    return "This is ML-transition scaffolding. heuristic_labels is derived from legacy ml_labels silver labels."


def compact_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    raise SystemExit(main())
