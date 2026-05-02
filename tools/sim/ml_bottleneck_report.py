#!/usr/bin/env python3
"""ML sweep summary에서 station/tier/loadout 병목을 빠르게 분해한다."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


class BottleneckReportError(Exception):
    """사용자가 읽을 수 있는 병목 리포트 오류."""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="시뮬레이션 summary로 S5/S6 같은 병목 구간을 분해합니다.",
    )
    parser.add_argument("summary_json")
    parser.add_argument("--out", default="")
    parser.add_argument("--stations", default="")
    parser.add_argument("--tiers", default="")
    parser.add_argument("--top-n", type=int, default=20)
    args = parser.parse_args(argv)

    try:
        result = run_from_options(
            {
                "summary_json": args.summary_json,
                "out": args.out,
                "stations": args.stations,
                "tiers": args.tiers,
                "top_n": args.top_n,
            },
        )
    except BottleneckReportError as error:
        print(f"오류: {error}", file=sys.stderr)
        return 64
    except OSError as error:
        print(f"파일 오류: {error}", file=sys.stderr)
        return 1

    print(f"병목 리포트: {result['report_path']}")
    return 0


def run_from_options(options: dict[str, Any]) -> dict[str, Any]:
    summary_path = Path(str(options["summary_json"]))
    summary = _load_summary(summary_path)
    groups = _filtered_groups(
        summary.get("groups"),
        stations=_parse_int_filter(str(options.get("stations", ""))),
        tiers=_parse_string_filter(str(options.get("tiers", ""))),
    )
    if not groups:
        raise BottleneckReportError("조건에 맞는 group이 없습니다.")

    top_n = max(1, int(options.get("top_n", 20)))
    out = str(options.get("out", ""))
    report_path = (
        Path(out)
        if out
        else summary_path.with_name(f"{summary_path.stem}_bottleneck_report.md")
    )
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        _render_report(summary_path=summary_path, groups=groups, top_n=top_n),
        encoding="utf-8",
    )
    return {"report_path": str(report_path)}


def _load_summary(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise BottleneckReportError(f"summary 파일을 찾을 수 없습니다: {path}")
    decoded = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise BottleneckReportError("summary 최상위 값은 object여야 합니다.")
    return decoded


def _filtered_groups(
    raw_groups: Any,
    *,
    stations: set[int],
    tiers: set[str],
) -> list[dict[str, Any]]:
    if not isinstance(raw_groups, list):
        raise BottleneckReportError("summary에 groups list가 없습니다.")
    groups = [group for group in raw_groups if isinstance(group, dict)]
    if stations:
        groups = [group for group in groups if int(group.get("station", -1)) in stations]
    if tiers:
        groups = [group for group in groups if str(group.get("blind_tier", "")) in tiers]
    return groups


def _render_report(
    *,
    summary_path: Path,
    groups: list[dict[str, Any]],
    top_n: int,
) -> str:
    total_runs = sum(_run_count(group) for group in groups)
    top_groups = sorted(groups, key=_bottleneck_score, reverse=True)[:top_n]
    experiment_rows = _aggregate_by(groups, _experiment_key)
    loadout_rows = _aggregate_by(groups, lambda group: str(group.get("loadout_id", "")))
    market_rows = _aggregate_by(groups, _market_key)
    station_tier_rows = _aggregate_by(groups, _station_tier_key)

    lines = [
        "# ML 병목 분해 리포트",
        "",
        f"- 입력 파일: `{summary_path}`",
        f"- group 수: {len(groups)}",
        f"- 총 run 수: {total_runs}",
        "",
        "## 한줄 판정",
        "",
        _one_line_judgement(groups),
        "",
        "## 병목 Top Groups",
        "",
    ]
    for group in top_groups:
        lines.append(f"- {_group_summary(group)}")

    lines.extend(
        [
            "",
            "## Experiment 비교",
            "",
            *_aggregate_lines(experiment_rows, top_n=top_n),
            "",
            "## Station/Tier 비교",
            "",
            *_aggregate_lines(station_tier_rows, top_n=top_n),
            "",
            "## Loadout 비교",
            "",
            *_aggregate_lines(loadout_rows, top_n=top_n),
            "",
            "## Market 비교",
            "",
            *_aggregate_lines(market_rows, top_n=top_n),
            "",
            "## 다음 액션",
            "",
            *_next_actions(groups),
        ],
    )
    return "\n".join(lines) + "\n"


def _one_line_judgement(groups: list[dict[str, Any]]) -> str:
    worst = max(groups, key=_bottleneck_score)
    aggregates = _aggregate(groups)
    if aggregates["deck_exhausted_rate"] >= 0.35:
        reason = "덱 고갈"
    elif aggregates["board_locked_rate"] >= 0.20:
        reason = "보드 락"
    elif aggregates["avg_max_single_confirm_score"] < 130:
        reason = "확정 점수 부족"
    else:
        reason = "station/tier/loadout 상호작용"
    return (
        f"- 주요 병목은 `{reason}`입니다. 전체 clear {aggregates['clear_rate']:.0%}, "
        f"deck exhausted {aggregates['deck_exhausted_rate']:.0%}, "
        f"board locked {aggregates['board_locked_rate']:.0%}. "
        f"최악 group은 `{_group_key(worst)}`입니다."
    )


def _next_actions(groups: list[dict[str, Any]]) -> list[str]:
    aggregates = _aggregate(groups)
    actions: list[str] = []
    if aggregates["deck_exhausted_rate"] >= 0.30:
        actions.append(
            "- 덱 고갈이 높습니다. 다음 sweep은 hand/deck sustain, S5/S6 market profile, bot의 낮은 점수 confirm 회피를 분리하세요.",
        )
    if aggregates["board_locked_rate"] >= 0.15:
        actions.append(
            "- 보드 락이 높습니다. board move/discard 보정과 placement policy의 보드 압박 페널티를 비교하세요.",
        )
    if aggregates["avg_max_single_confirm_score"] < 140:
        actions.append(
            "- 평균 최대 confirm 점수가 낮습니다. build 선택이 multiplier보다 hand-shape/confirm engine을 못 만들고 있는지 확인하세요.",
        )
    if not actions:
        actions.append(
            "- 병목 원인이 한 축으로 몰리지 않습니다. 최악 top group만 500~1000 runs로 재검증하세요.",
        )
    actions.append(
        "- 모델 추천값은 바로 반영하지 말고, 같은 seed 범위에서 summary-only 재시뮬레이션으로 확인하세요.",
    )
    return actions


def _aggregate_by(
    groups: list[dict[str, Any]],
    key_fn: Any,
) -> list[tuple[str, dict[str, float]]]:
    buckets: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for group in groups:
        buckets[str(key_fn(group))].append(group)
    rows = [(key, _aggregate(bucket)) for key, bucket in buckets.items()]
    return sorted(rows, key=lambda row: row[1]["bottleneck_score"], reverse=True)


def _aggregate(groups: list[dict[str, Any]]) -> dict[str, float]:
    runs = sum(_run_count(group) for group in groups)
    if runs <= 0:
        return {
            "runs": 0,
            "clear_rate": 0,
            "deck_exhausted_rate": 0,
            "board_locked_rate": 0,
            "avg_turn_count": 0,
            "avg_max_single_confirm_score": 0,
            "bottleneck_score": 0,
        }
    return {
        "runs": runs,
        "clear_rate": _weighted(groups, "clear_rate"),
        "deck_exhausted_rate": _outcome_rate(groups, "deck_exhausted"),
        "board_locked_rate": _outcome_rate(groups, "board_locked"),
        "avg_turn_count": _weighted(groups, "avg_turn_count"),
        "avg_max_single_confirm_score": _weighted(
            groups,
            "avg_max_single_confirm_score",
        ),
        "bottleneck_score": sum(
            _bottleneck_score(group) * _run_count(group) for group in groups
        )
        / runs,
    }


def _aggregate_lines(
    rows: list[tuple[str, dict[str, float]]],
    *,
    top_n: int,
) -> list[str]:
    lines = []
    for key, row in rows[:top_n]:
        lines.append(
            f"- `{key}`: score {row['bottleneck_score']:.2f}, "
            f"clear {row['clear_rate']:.0%}, deck exhausted {row['deck_exhausted_rate']:.0%}, "
            f"board locked {row['board_locked_rate']:.0%}, turn {row['avg_turn_count']:.1f}, "
            f"maxHit {row['avg_max_single_confirm_score']:.1f}, runs {int(row['runs'])}"
        )
    return lines


def _group_summary(group: dict[str, Any]) -> str:
    labels = group.get("ml_target_labels_v2")
    label_text = ""
    if isinstance(labels, dict):
        label_text = (
            f", difficulty `{labels.get('difficulty')}`, "
            f"resource `{labels.get('resource_pressure')}`"
        )
    return (
        f"`{_group_key(group)}`: score {_bottleneck_score(group):.2f}, "
        f"clear {_num(group, 'clear_rate'):.0%}, "
        f"deck exhausted {_outcome_rate([group], 'deck_exhausted'):.0%}, "
        f"board locked {_outcome_rate([group], 'board_locked'):.0%}, "
        f"turn {_num(group, 'avg_turn_count'):.1f}, "
        f"maxHit {_num(group, 'avg_max_single_confirm_score'):.1f}"
        f"{label_text}"
    )


def _bottleneck_score(group: dict[str, Any]) -> float:
    clear_rate = _num(group, "clear_rate")
    deck_exhausted = _outcome_rate([group], "deck_exhausted")
    board_locked = _outcome_rate([group], "board_locked")
    score_ratio_gap = max(0.0, 1.0 - _num(group, "avg_score_ratio"))
    turn_pressure = max(0.0, (_num(group, "avg_turn_count") - 95.0) / 60.0)
    confirm_gap = max(0.0, (140.0 - _num(group, "avg_max_single_confirm_score")) / 140.0)
    attention_bonus = 0.20 if group.get("needs_balance_attention_v2") else 0.0
    return (
        (1.0 - clear_rate) * 1.20
        + deck_exhausted * 0.75
        + board_locked * 0.50
        + score_ratio_gap * 0.80
        + turn_pressure * 0.30
        + confirm_gap * 0.25
        + attention_bonus
    )


def _weighted(groups: list[dict[str, Any]], key: str) -> float:
    runs = sum(_run_count(group) for group in groups)
    if runs <= 0:
        return 0.0
    return sum(_num(group, key) * _run_count(group) for group in groups) / runs


def _outcome_rate(groups: list[dict[str, Any]], outcome: str) -> float:
    runs = sum(_run_count(group) for group in groups)
    if runs <= 0:
        return 0.0
    count = 0
    for group in groups:
        outcomes = group.get("outcome_counts")
        if isinstance(outcomes, dict):
            count += int(outcomes.get(outcome, 0) or 0)
    return count / runs


def _group_key(group: dict[str, Any]) -> str:
    return (
        f"{_experiment_key(group)} {group.get('loadout_id')} "
        f"S{group.get('station')} {group.get('blind_tier')} {group.get('difficulty')}"
    )


def _experiment_key(group: dict[str, Any]) -> str:
    return str(
        group.get("experiment_matrix_id")
        or group.get("station_growth_experiment_id")
        or group.get("base_experiment_id")
        or group.get("experiment_id")
        or "",
    )


def _station_tier_key(group: dict[str, Any]) -> str:
    return f"S{group.get('station')} {group.get('blind_tier')}"


def _market_key(group: dict[str, Any]) -> str:
    loadout = str(group.get("loadout_id", ""))
    if "__" not in loadout:
        return "none"
    return loadout.split("__", 1)[1]


def _run_count(group: dict[str, Any]) -> int:
    return int(group.get("run_count", 0) or 0)


def _num(group: dict[str, Any], key: str) -> float:
    value = group.get(key, 0)
    if isinstance(value, (int, float)):
        return float(value)
    return 0.0


def _parse_int_filter(raw: str) -> set[int]:
    if not raw.strip():
        return set()
    return {int(part.strip()) for part in raw.split(",") if part.strip()}


def _parse_string_filter(raw: str) -> set[str]:
    if not raw.strip():
        return set()
    return {part.strip() for part in raw.split(",") if part.strip()}


if __name__ == "__main__":
    raise SystemExit(main())
