#!/usr/bin/env python3
"""Balance summary를 사람이 읽기 쉬운 한글 Markdown/차트로 변환한다."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


TIER_ORDER = {"small": 0, "big": 1, "boss": 2}
DIFFICULTY_ORDER = {"relaxed": 0, "standard": 1, "pressure": 2}


@dataclass(frozen=True)
class SummaryGroup:
    experiment_id: str
    loadout_id: str
    station: int
    blind_tier: str
    difficulty: str
    run_count: int
    clear_count: int
    slow_clear_count: int
    clear_rate: float
    slow_clear_rate: float
    slow_clear_share_of_clears: float
    tempo_risk_label: str
    avg_turn_count: float
    avg_discarded_board_count: float
    avg_max_single_confirm_score: float
    scored_run_count: int
    avg_first_score_turn: float | None
    avg_last_score_turn: float | None
    outcome_counts: dict[str, int]
    clear_tempo_label_counts: dict[str, int]

    @classmethod
    def from_json(cls, raw: dict[str, Any]) -> "SummaryGroup":
        return cls(
            experiment_id=_optional_str(raw, "experiment_id", default="baseline"),
            loadout_id=_required_str(raw, "loadout_id"),
            station=_required_int(raw, "station"),
            blind_tier=_required_str(raw, "blind_tier"),
            difficulty=_required_str(raw, "difficulty"),
            run_count=_required_int(raw, "run_count"),
            clear_count=_required_int(raw, "clear_count"),
            slow_clear_count=_optional_int(raw, "slow_clear_count", default=0),
            clear_rate=_required_float(raw, "clear_rate"),
            slow_clear_rate=_optional_float_value(raw, "slow_clear_rate", default=0.0),
            slow_clear_share_of_clears=_optional_float_value(
                raw,
                "slow_clear_share_of_clears",
                default=0.0,
            ),
            tempo_risk_label=_optional_str(raw, "tempo_risk_label", default="none"),
            avg_turn_count=_required_float(raw, "avg_turn_count"),
            avg_discarded_board_count=_required_float(
                raw,
                "avg_discarded_board_count",
            ),
            avg_max_single_confirm_score=_required_float(
                raw,
                "avg_max_single_confirm_score",
            ),
            scored_run_count=_required_int(raw, "scored_run_count"),
            avg_first_score_turn=_optional_float(raw, "avg_first_score_turn"),
            avg_last_score_turn=_optional_float(raw, "avg_last_score_turn"),
            outcome_counts=_parse_outcome_counts(raw.get("outcome_counts")),
            clear_tempo_label_counts=_parse_optional_counts(
                raw.get("clear_tempo_label_counts"),
            ),
        )

    @property
    def label(self) -> str:
        base = f"{self.loadout_id} S{self.station} {self.blind_tier} {self.difficulty}"
        if self.experiment_id == "baseline":
            return base
        return f"{self.experiment_id} {base}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="밸런스 시뮬레이션 summary.json을 한글 리포트로 변환합니다.",
    )
    parser.add_argument("summary_json", help="run_balance_sim.dart summary JSON 경로")
    parser.add_argument(
        "--out-dir",
        help="리포트/차트 출력 폴더. 기본값은 summary 파일이 있는 폴더입니다.",
    )
    args = parser.parse_args(argv)

    summary_path = Path(args.summary_json)
    out_dir = Path(args.out_dir) if args.out_dir else summary_path.parent

    try:
        groups = load_groups(summary_path)
        out_dir.mkdir(parents=True, exist_ok=True)
        report_path = out_dir / f"{summary_path.stem}_report.md"
        chart_paths, chart_warning = write_charts(groups, out_dir, summary_path.stem)
        report = render_markdown(
            groups,
            source_path=summary_path,
            chart_paths=chart_paths,
            chart_warning=chart_warning,
        )
        report_path.write_text(report, encoding="utf-8")
    except BalanceReportError as error:
        print(f"오류: {error}", file=sys.stderr)
        return 64
    except OSError as error:
        print(f"파일 오류: {error}", file=sys.stderr)
        return 1

    print(f"한글 리포트: {report_path}")
    for chart_path in chart_paths:
        print(f"차트: {chart_path}")
    if chart_warning:
        print(chart_warning)
    return 0


def load_groups(summary_path: Path) -> list[SummaryGroup]:
    if not summary_path.exists():
        raise BalanceReportError(f"summary 파일을 찾을 수 없습니다: {summary_path}")
    try:
        decoded = json.loads(summary_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise BalanceReportError(f"JSON을 읽을 수 없습니다: {error}") from error
    if not isinstance(decoded, dict):
        raise BalanceReportError("summary JSON의 최상위 값은 object여야 합니다.")
    raw_groups = decoded.get("groups")
    if not isinstance(raw_groups, list):
        raise BalanceReportError("summary JSON에 groups list가 없습니다.")
    groups = [SummaryGroup.from_json(dict(raw)) for raw in raw_groups]
    return sorted(
        groups,
        key=lambda group: (
            group.experiment_id,
            group.loadout_id,
            group.station,
            TIER_ORDER.get(group.blind_tier, 99),
            DIFFICULTY_ORDER.get(group.difficulty, 99),
        ),
    )


def render_markdown(
    groups: list[SummaryGroup],
    *,
    source_path: Path,
    chart_paths: list[Path],
    chart_warning: str | None,
) -> str:
    lines: list[str] = [
        "# 밸런스 시뮬레이션 요약",
        "",
        f"- 입력 파일: `{source_path}`",
        f"- 그룹 수: {len(groups)}",
        "",
        "## 한줄 해석",
        "",
        one_line_summary(groups),
        "",
        "## 위험 구간",
        "",
        *risk_lines(groups),
        "",
        "## 느린 클리어",
        "",
        *slow_clear_lines(groups),
        "",
        "## 재미 신호",
        "",
        *fun_signal_lines(groups),
        "",
        "## 유입/조합 기준 평가",
        "",
        *onboarding_lines(groups),
        "",
        "## 차트",
        "",
    ]
    if chart_paths:
        for chart_path in chart_paths:
            title = chart_title_for_path(chart_path)
            lines.append(f"![{title}]({chart_path.name})")
    else:
        lines.append(f"- {chart_warning or '차트를 생성하지 않았습니다.'}")
    lines.extend(["", "## 상세 표", ""])
    lines.append(
        "| Experiment | Loadout | Station | Tier | 난이도 | 클리어율 | 평균 턴 | 큰 한방 | 첫 점수 | 마지막 점수 | 보드 버림 | 결과 |",
    )
    lines.append(
        "|---|---|---:|---|---|---:|---:|---:|---:|---:|---:|---|",
    )
    for group in groups:
        lines.append(
            "| "
            + " | ".join(
                [
                    group.experiment_id,
                    group.loadout_id,
                    str(group.station),
                    group.blind_tier,
                    group.difficulty,
                    _percent(group.clear_rate),
                    _fixed(group.avg_turn_count),
                    _fixed(group.avg_max_single_confirm_score),
                    _optional_fixed(group.avg_first_score_turn),
                    _optional_fixed(group.avg_last_score_turn),
                    _fixed(group.avg_discarded_board_count),
                    _outcomes_text(group.outcome_counts),
                ],
            )
            + " |",
        )
    lines.append("")
    return "\n".join(lines)


def one_line_summary(groups: list[SummaryGroup]) -> str:
    if not groups:
        return "- 분석할 그룹이 없습니다."
    clear_rates = [group.clear_rate for group in groups]
    avg_clear = sum(clear_rates) / len(clear_rates)
    hard_count = sum(1 for group in groups if group.clear_rate < 0.25)
    easy_count = sum(1 for group in groups if group.clear_rate > 0.85)
    fun_count = sum(
        1
        for group in groups
        if _has_good_fun_signal(group)
    )
    return (
        f"- 평균 클리어율은 {_percent(avg_clear)}입니다. "
        f"어려운 후보 {hard_count}개, 쉬운 후보 {easy_count}개, "
        f"큰 한방/후반 점수 재미 신호 {fun_count}개, "
        f"느린 클리어 위험 {slow_clear_group_count(groups)}개가 보입니다."
    )


def risk_lines(groups: list[SummaryGroup]) -> list[str]:
    risks: list[str] = []
    for group in groups:
        reasons: list[str] = []
        if group.clear_rate < 0.25:
            reasons.append(f"클리어율 낮음 {_percent(group.clear_rate)}")
        if group.clear_rate > 0.85:
            reasons.append(f"클리어율 높음 {_percent(group.clear_rate)}")
        if group.avg_turn_count > 100:
            reasons.append(f"턴이 김 {_fixed(group.avg_turn_count)}")
        if group.outcome_counts.get("board_locked", 0) > 0:
            reasons.append(f"보드 락 {group.outcome_counts['board_locked']}회")
        if group.outcome_counts.get("deck_exhausted", 0) > 0:
            reasons.append(f"덱 소진 {group.outcome_counts['deck_exhausted']}회")
        if reasons:
            risks.append(f"- `{group.label}`: " + ", ".join(reasons))
    return risks or ["- 뚜렷한 위험 구간이 없습니다."]


def slow_clear_group_count(groups: list[SummaryGroup]) -> int:
    return sum(1 for group in groups if group.tempo_risk_label == "clear_but_too_slow")


def slow_clear_lines(groups: list[SummaryGroup]) -> list[str]:
    slow_groups = [
        group
        for group in groups
        if group.tempo_risk_label == "clear_but_too_slow"
        or group.slow_clear_count > 0
    ]
    if not slow_groups:
        return ["- 클리어가 과도하게 늘어지는 구간은 없습니다."]
    lines: list[str] = []
    for group in sorted(
        slow_groups,
        key=lambda item: (
            item.tempo_risk_label != "clear_but_too_slow",
            -item.slow_clear_share_of_clears,
            -item.avg_turn_count,
        ),
    ):
        label = (
            "클리어는 되지만 너무 느림"
            if group.tempo_risk_label == "clear_but_too_slow"
            else "일부 느린 클리어"
        )
        lines.append(
            f"- `{group.label}`: {label}, "
            f"느린 클리어 {group.slow_clear_count}/{group.clear_count}, "
            f"클리어 중 비중 {_percent(group.slow_clear_share_of_clears)}, "
            f"평균 턴 {_fixed(group.avg_turn_count)}"
        )
    return lines


def fun_signal_lines(groups: list[SummaryGroup]) -> list[str]:
    signals: list[str] = []
    for group in groups:
        if group.tempo_risk_label == "clear_but_too_slow":
            signals.append(
                f"- `{group.label}`: 후반 점수는 있으나 템포 위험으로 재미 신호에서 제외"
            )
            continue
        reasons: list[str] = []
        if group.avg_max_single_confirm_score >= 100:
            reasons.append(f"큰 한방 {_fixed(group.avg_max_single_confirm_score)}")
        if (group.avg_last_score_turn or 0) >= 80:
            reasons.append(f"후반 점수 {_optional_fixed(group.avg_last_score_turn)}턴")
        if 0.35 <= group.clear_rate <= 0.75:
            reasons.append(f"긴장감 있는 클리어율 {_percent(group.clear_rate)}")
        if reasons:
            signals.append(f"- `{group.label}`: " + ", ".join(reasons))
    return signals or ["- 큰 한방이나 후반 점수 신호가 약합니다."]


def _has_good_fun_signal(group: SummaryGroup) -> bool:
    if group.tempo_risk_label == "clear_but_too_slow":
        return False
    return (
        group.avg_max_single_confirm_score >= 100
        or (group.avg_last_score_turn or 0) >= 80
    )


def onboarding_lines(groups: list[SummaryGroup]) -> list[str]:
    by_key = {
        (group.experiment_id, group.loadout_id, group.station, group.blind_tier, group.difficulty): group
        for group in groups
    }
    lines = [
        _judge_minimum_jester_onboarding(by_key),
        _judge_first_boss_wall(by_key),
        _judge_baseline_build_need(by_key),
        _judge_safety_item_tempo(by_key),
        _judge_mobility_item_value(by_key),
    ]
    return [f"- {line}" for line in lines if line]


def _judge_minimum_jester_onboarding(
    by_key: dict[tuple[str, str, int, str, str], SummaryGroup],
) -> str:
    small = by_key.get(("baseline", "pair_mult", 1, "small", "standard"))
    big = by_key.get(("baseline", "pair_mult", 1, "big", "standard"))
    if small is None or big is None:
        return "최소 Jester 유입: pair_mult Station 1 small/big standard 데이터가 부족합니다."
    if small.clear_rate >= 0.80 and big.clear_rate >= 0.80:
        return (
            "최소 Jester 유입: 안정권입니다. "
            f"pair_mult S1 small {_percent(small.clear_rate)}, "
            f"big {_percent(big.clear_rate)}."
        )
    return (
        "최소 Jester 유입: 보강 필요. "
        f"pair_mult S1 small {_percent(small.clear_rate)}, "
        f"big {_percent(big.clear_rate)}."
    )


def _judge_first_boss_wall(
    by_key: dict[tuple[str, str, int, str, str], SummaryGroup],
) -> str:
    boss = by_key.get(("baseline", "pair_mult", 1, "boss", "standard"))
    if boss is None:
        return "첫 Boss 벽: pair_mult S1 boss standard 데이터가 부족합니다."
    if boss.clear_rate >= 0.45:
        return f"첫 Boss 벽: 통과권입니다. pair_mult S1 boss standard {_percent(boss.clear_rate)}."
    return (
        "첫 Boss 벽: 너무 높습니다. "
        f"pair_mult S1 boss standard {_percent(boss.clear_rate)}."
    )


def _judge_baseline_build_need(
    by_key: dict[tuple[str, str, int, str, str], SummaryGroup],
) -> str:
    small = by_key.get(("baseline", "baseline", 1, "small", "standard"))
    boss = by_key.get(("baseline", "baseline", 1, "boss", "standard"))
    if small is None or boss is None:
        return "무장해제 기준: baseline S1 small/boss standard 데이터가 부족합니다."
    small_ok = small.clear_rate >= 0.60
    boss_ok = boss.clear_rate <= 0.30
    if small_ok and boss_ok:
        return (
            "무장해제 기준: 초반 유입과 build 필요성이 함께 보입니다. "
            f"S1 small {_percent(small.clear_rate)}, boss {_percent(boss.clear_rate)}."
        )
    return (
        "무장해제 기준: 조정 필요. "
        f"S1 small {_percent(small.clear_rate)}(목표 60%+), "
        f"boss {_percent(boss.clear_rate)}(목표 30%-)."
    )


def _judge_safety_item_tempo(
    by_key: dict[tuple[str, str, int, str, str], SummaryGroup],
) -> str:
    safety_groups = [
        group
        for group in by_key.values()
        if group.experiment_id == "baseline" and group.loadout_id == "safety_item"
    ]
    if not safety_groups:
        return "Safety Item 템포: 데이터가 부족합니다."
    slow_groups = [
        group
        for group in safety_groups
        if group.tempo_risk_label == "clear_but_too_slow"
        or group.avg_turn_count > 130
    ]
    if not slow_groups:
        return "Safety Item 템포: 안정권입니다. 평균 턴 130 초과 구간이 없습니다."
    worst = max(slow_groups, key=lambda group: group.avg_turn_count)
    return (
        "Safety Item 템포: 늘어짐 위험. "
        f"평균 턴 130 초과 {len(slow_groups)}개, "
        f"최대 {worst.label} {_fixed(worst.avg_turn_count)}턴."
    )


def _judge_mobility_item_value(
    by_key: dict[tuple[str, str, int, str, str], SummaryGroup],
) -> str:
    comparable: list[tuple[SummaryGroup, SummaryGroup, float]] = []
    for key, mobility in by_key.items():
        if key[0] != "baseline" or key[1] != "mobility_item":
            continue
        baseline = by_key.get(("baseline", "baseline", key[2], key[3], key[4]))
        if baseline is None:
            continue
        comparable.append((baseline, mobility, mobility.clear_rate - baseline.clear_rate))
    if not comparable:
        return "Mobility Item 가치: baseline 비교 데이터가 부족합니다."
    useful = [entry for entry in comparable if entry[2] >= 0.10]
    if useful:
        best = max(useful, key=lambda entry: entry[2])
        return (
            "Mobility Item 가치: 일부 구간에서 의미가 있습니다. "
            f"+10%p 이상 {len(useful)}개, "
            f"최대 {best[1].label} +{round(best[2] * 100)}%p."
        )
    return "Mobility Item 가치: 약합니다. baseline 대비 +10%p 이상 개선 구간이 없습니다."


def chart_title_for_path(path: Path) -> str:
    name = path.name
    if name.endswith("_clear_rate.png"):
        return "클리어율 차트"
    if name.endswith("_turns.png"):
        return "평균 턴 차트"
    if name.endswith("_max_hit.png"):
        return "평균 큰 한방 차트"
    return "밸런스 차트"


def write_charts(
    groups: list[SummaryGroup],
    out_dir: Path,
    stem: str,
) -> tuple[list[Path], str | None]:
    try:
        import matplotlib.pyplot as plt  # type: ignore
    except Exception:
        return [], "matplotlib이 없어 차트 생성을 건너뛰었습니다."

    font_warning = configure_korean_matplotlib_font(plt)
    chart_specs = [
        (
            "clear_rate",
            "클리어율",
            [group.clear_rate * 100 for group in groups],
            "%",
        ),
        (
            "turns",
            "평균 턴",
            [group.avg_turn_count for group in groups],
            "turn",
        ),
        (
            "max_hit",
            "평균 큰 한방",
            [group.avg_max_single_confirm_score for group in groups],
            "score",
        ),
    ]
    labels = [group.label for group in groups]
    paths: list[Path] = []
    for suffix, title, values, ylabel in chart_specs:
        path = out_dir / f"{stem}_{suffix}.png"
        width = max(8, min(22, len(groups) * 0.55))
        plt.figure(figsize=(width, 5))
        plt.bar(range(len(groups)), values)
        plt.title(title)
        plt.ylabel(ylabel)
        plt.xticks(range(len(groups)), labels, rotation=60, ha="right")
        plt.tight_layout()
        plt.savefig(path)
        plt.close()
        paths.append(path)
    return paths, font_warning


def configure_korean_matplotlib_font(plt: Any) -> str | None:
    """matplotlib 차트의 한글 깨짐과 음수 기호 깨짐을 줄인다."""
    from matplotlib import font_manager  # type: ignore

    plt.rcParams["axes.unicode_minus"] = False
    preferred_fonts = [
        "AppleGothic",
        "NanumGothic",
        "Noto Sans CJK KR",
        "Noto Sans KR",
        "Malgun Gothic",
        "Arial Unicode MS",
    ]
    available_names = {font.name for font in font_manager.fontManager.ttflist}
    for font_name in preferred_fonts:
        if font_name in available_names:
            plt.rcParams["font.family"] = font_name
            return None

    return "한글 matplotlib 폰트를 찾지 못했습니다. 차트 글자가 깨질 수 있습니다."


class BalanceReportError(Exception):
    pass


def _required_str(raw: dict[str, Any], field: str) -> str:
    value = raw.get(field)
    if isinstance(value, str):
        return value
    raise BalanceReportError(f"필수 문자열 필드가 없습니다: {field}")


def _required_int(raw: dict[str, Any], field: str) -> int:
    value = raw.get(field)
    if isinstance(value, int):
        return value
    raise BalanceReportError(f"필수 정수 필드가 없습니다: {field}")


def _optional_int(raw: dict[str, Any], field: str, *, default: int) -> int:
    value = raw.get(field)
    if value is None:
        return default
    if isinstance(value, int):
        return value
    raise BalanceReportError(f"정수여야 하는 필드입니다: {field}")


def _required_float(raw: dict[str, Any], field: str) -> float:
    value = raw.get(field)
    if isinstance(value, (int, float)):
        return float(value)
    raise BalanceReportError(f"필수 숫자 필드가 없습니다: {field}")


def _optional_float(raw: dict[str, Any], field: str) -> float | None:
    value = raw.get(field)
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    raise BalanceReportError(f"숫자 또는 null이어야 하는 필드입니다: {field}")


def _optional_float_value(raw: dict[str, Any], field: str, *, default: float) -> float:
    value = raw.get(field)
    if value is None:
        return default
    if isinstance(value, (int, float)):
        return float(value)
    raise BalanceReportError(f"숫자여야 하는 필드입니다: {field}")


def _optional_str(raw: dict[str, Any], field: str, *, default: str) -> str:
    value = raw.get(field)
    if value is None:
        return default
    if isinstance(value, str):
        return value
    raise BalanceReportError(f"문자열이어야 하는 필드입니다: {field}")


def _parse_outcome_counts(raw: Any) -> dict[str, int]:
    if not isinstance(raw, dict):
        raise BalanceReportError("outcome_counts map이 없습니다.")
    return {str(key): int(value) for key, value in raw.items()}


def _parse_optional_counts(raw: Any) -> dict[str, int]:
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        raise BalanceReportError("clear_tempo_label_counts map이 아닙니다.")
    return {str(key): int(value) for key, value in raw.items()}


def _percent(value: float) -> str:
    return f"{round(value * 100)}%"


def _fixed(value: float) -> str:
    return f"{value:.1f}"


def _optional_fixed(value: float | None) -> str:
    return "-" if value is None else _fixed(value)


def _outcomes_text(outcomes: dict[str, int]) -> str:
    if not outcomes:
        return "-"
    entries = sorted(outcomes.items(), key=lambda item: (-item[1], item[0]))
    return ", ".join(f"{key}:{value}" for key, value in entries)


if __name__ == "__main__":
    raise SystemExit(main())
