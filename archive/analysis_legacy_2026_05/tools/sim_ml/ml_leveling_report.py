#!/usr/bin/env python3
"""규칙 기반 balance label summary를 한글 레벨링 리포트로 변환한다."""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_OPTIONS: dict[str, Any] = {
    "summary_json": "logs/sim/planner_v2_ml_label_v1_preview_100_summary.json",
    "out_dir": "logs/sim",
    "leveling_goal": "overall",
    "target_labels": ["too_hard", "tempo_drag", "good_playfeel"],
    "top_n": 12,
    "auto_install_missing": False,
}

LEVELING_GOAL_LABELS: dict[str, list[str]] = {
    "overall": ["needs_balance_attention", "good_playfeel", "tempo_drag"],
    "onboarding": ["too_easy", "good_playfeel", "too_hard"],
    "boss_wall": ["too_hard", "good_playfeel"],
    "tempo": ["tempo_drag", "good_playfeel"],
}

REQUIRED_PACKAGES: dict[str, str] = {
    "pandas": "pandas",
    "matplotlib": "matplotlib",
    "sklearn": "scikit-learn",
}


class MlLevelingError(Exception):
    """사용자가 읽을 수 있는 리포트 생성 오류."""


@dataclass(frozen=True)
class MlSummaryGroup:
    """summary의 group 한 줄을 사람이 읽기 좋은 객체로 감싼다."""

    experiment_id: str
    loadout_id: str
    station: int
    blind_tier: str
    difficulty: str
    run_count: int
    clear_rate: float
    avg_score_ratio: float
    avg_turn_count: float
    avg_confirm_action_count: float
    avg_max_single_confirm_score: float
    avg_remaining_deck: float
    avg_remaining_board_discards: float
    avg_remaining_hand_discards: float
    avg_remaining_board_moves: float
    slow_clear_share_of_clears: float
    tempo_risk_label: str
    outcome_counts: dict[str, int]
    ml_labels: list[str]
    needs_balance_attention: bool
    ml_target_labels_v2: dict[str, str]
    needs_balance_attention_v2: bool
    sweep_metadata: dict[str, str | float]

    @classmethod
    def from_json(cls, raw: dict[str, Any]) -> "MlSummaryGroup":
        # 변수 의미:
        # - clear_rate: 해당 조건에서 목표 점수를 넘긴 비율이다.
        # - avg_score_ratio: 최종 점수 / 목표 점수의 평균이다.
        # - slow_clear_share_of_clears: 클리어한 run 중 느린 클리어의 비중이다.
        # - ml_labels: Dart summary가 붙인 해석용 label v1 목록이다.
        # - ml_target_labels_v2: 난이도/템포/자원/스파이크/선택 밀도별 진단값이다.
        return cls(
            experiment_id=_optional_str(raw, "experiment_id", default="baseline"),
            loadout_id=_required_str(raw, "loadout_id"),
            station=_required_int(raw, "station"),
            blind_tier=_required_str(raw, "blind_tier"),
            difficulty=_required_str(raw, "difficulty"),
            run_count=_required_int(raw, "run_count"),
            clear_rate=_required_float(raw, "clear_rate"),
            avg_score_ratio=_required_float(raw, "avg_score_ratio"),
            avg_turn_count=_required_float(raw, "avg_turn_count"),
            avg_confirm_action_count=_optional_float(
                raw,
                "avg_confirm_action_count",
                default=0.0,
            ),
            avg_max_single_confirm_score=_required_float(
                raw,
                "avg_max_single_confirm_score",
            ),
            avg_remaining_deck=_optional_float(
                raw,
                "avg_remaining_deck",
                default=0.0,
            ),
            avg_remaining_board_discards=_optional_float(
                raw,
                "avg_remaining_board_discards",
                default=0.0,
            ),
            avg_remaining_hand_discards=_optional_float(
                raw,
                "avg_remaining_hand_discards",
                default=0.0,
            ),
            avg_remaining_board_moves=_optional_float(
                raw,
                "avg_remaining_board_moves",
                default=0.0,
            ),
            slow_clear_share_of_clears=_optional_float(
                raw,
                "slow_clear_share_of_clears",
                default=0.0,
            ),
            tempo_risk_label=_optional_str(
                raw,
                "tempo_risk_label",
                default="none",
            ),
            outcome_counts=_parse_int_counter(raw.get("outcome_counts")),
            ml_labels=_parse_labels(raw.get("ml_labels")),
            needs_balance_attention=bool(raw.get("needs_balance_attention", False)),
            ml_target_labels_v2=_parse_target_labels_v2(
                raw.get("ml_target_labels_v2"),
            ),
            needs_balance_attention_v2=bool(
                raw.get("needs_balance_attention_v2", False),
            ),
            sweep_metadata=_parse_sweep_metadata(raw),
        )

    @property
    def label(self) -> str:
        base = (
            f"{self.loadout_id} S{self.station} "
            f"{self.blind_tier} {self.difficulty}"
        )
        if self.experiment_id == "baseline":
            return base
        return f"{self.experiment_id} {base}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="규칙 기반 balance label summary를 한글 레벨링 리포트로 변환합니다.",
    )
    parser.add_argument("summary_json", help="run_balance_sim.dart summary JSON 경로")
    parser.add_argument("--out-dir", default=None, help="리포트/차트 출력 폴더")
    parser.add_argument(
        "--goal",
        default="overall",
        choices=sorted(LEVELING_GOAL_LABELS.keys()),
        help="레벨링 해석 목표",
    )
    parser.add_argument("--top-n", type=int, default=12, help="목록별 표시 개수")
    parser.add_argument(
        "--install-missing",
        action="store_true",
        help="없는 Python 라이브러리를 현재 인터프리터에 설치합니다.",
    )
    args = parser.parse_args(argv)

    options = dict(DEFAULT_OPTIONS)
    options.update(
        {
            "summary_json": args.summary_json,
            "out_dir": args.out_dir,
            "leveling_goal": args.goal,
            "top_n": args.top_n,
            "auto_install_missing": args.install_missing,
        },
    )

    try:
        result = run_from_options(options)
    except MlLevelingError as error:
        print(f"오류: {error}", file=sys.stderr)
        return 64
    except OSError as error:
        print(f"파일 오류: {error}", file=sys.stderr)
        return 1

    print(f"휴리스틱 레벨링 워크벤치 리포트: {result['report_path']}")
    for chart_path in result["chart_paths"]:
        print(f"차트: {chart_path}")
    for warning in result["warnings"]:
        print(f"경고: {warning}")
    return 0


def run_from_options(options: dict[str, Any]) -> dict[str, Any]:
    """노트북과 CLI가 같은 옵션 구조로 리포트를 만들기 위한 진입점."""

    # 사용자가 옵션 셀에서 바꾸는 값들을 안정적인 타입으로 정규화한다.
    resolved = resolve_options(options)
    if resolved["auto_install_missing"]:
        ensure_libraries(auto_install=True)

    # summary JSON을 읽고, group 단위 분석 객체로 변환한다.
    summary_path = Path(resolved["summary_json"])
    groups = load_groups(summary_path)
    if not groups:
        raise MlLevelingError("summary에 분석할 group이 없습니다.")

    # out_dir이 없으면 summary 파일 옆에 결과를 저장한다.
    out_dir = Path(resolved["out_dir"] or summary_path.parent)
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = summary_path.stem

    # 차트는 matplotlib이 있을 때만 생성한다. 없으면 Markdown 해석은 계속 만든다.
    chart_paths, warnings = write_charts(groups, out_dir, stem)

    # sklearn은 선택 기능이다. 설치되어 있으면 실제 train/test 검증이 있는
    # tabular 모델을 붙이고, 부족하면 데이터/피처 보강 방향을 먼저 말한다.
    ml_workbench_lines, ml_workbench_warning = ml_leveling_workbench_lines(groups)
    if ml_workbench_warning:
        warnings.append(ml_workbench_warning)

    # legacy 힌트는 규칙 기반 label이 왜 갈렸는지 빠르게 확인하는 보조 설명이다.
    sklearn_lines, sklearn_warning = sklearn_hint_lines(groups)
    if sklearn_warning:
        warnings.append(sklearn_warning)

    markdown = render_markdown(
        groups,
        summary_path=summary_path,
        goal=resolved["leveling_goal"],
        target_labels=resolved["target_labels"],
        top_n=resolved["top_n"],
        chart_paths=chart_paths,
        ml_workbench_lines=ml_workbench_lines,
        sklearn_lines=sklearn_lines,
        warnings=warnings,
    )
    report_path = out_dir / f"{stem}_ml_insights_report.md"
    report_path.write_text(markdown, encoding="utf-8")
    return {
        "report_path": str(report_path),
        "chart_paths": [str(path) for path in chart_paths],
        "warnings": warnings,
    }


def resolve_options(options: dict[str, Any]) -> dict[str, Any]:
    """노트북 옵션 셀과 CLI 옵션을 같은 형태로 맞춘다."""

    resolved = dict(DEFAULT_OPTIONS)
    resolved.update(options)
    goal = str(resolved["leveling_goal"])
    if goal not in LEVELING_GOAL_LABELS:
        raise MlLevelingError(f"알 수 없는 leveling_goal입니다: {goal}")
    if not isinstance(resolved["target_labels"], list):
        raise MlLevelingError("target_labels는 문자열 list여야 합니다.")
    if int(resolved["top_n"]) <= 0:
        raise MlLevelingError("top_n은 1 이상이어야 합니다.")
    resolved["top_n"] = int(resolved["top_n"])
    return resolved


def ensure_libraries(*, auto_install: bool) -> dict[str, bool]:
    """노트북에서 현재 커널 환경에 필요한 라이브러리가 있는지 확인한다."""

    installed: dict[str, bool] = {}
    missing_packages: list[str] = []
    for import_name, package_name in REQUIRED_PACKAGES.items():
        try:
            __import__(import_name)
            installed[package_name] = True
        except Exception:
            installed[package_name] = False
            missing_packages.append(package_name)

    if auto_install and missing_packages:
        # sys.executable은 현재 노트북 커널의 Python을 의미한다.
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", *missing_packages],
        )
    return installed


def load_groups(summary_path: Path) -> list[MlSummaryGroup]:
    """summary JSON의 groups를 읽어 휴리스틱 해석 객체 목록으로 변환한다."""

    if not summary_path.exists():
        raise MlLevelingError(f"summary 파일을 찾을 수 없습니다: {summary_path}")
    decoded = json.loads(summary_path.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise MlLevelingError("summary JSON의 최상위 값은 object여야 합니다.")
    raw_groups = decoded.get("groups")
    if not isinstance(raw_groups, list):
        raise MlLevelingError("summary JSON에 groups list가 없습니다.")
    groups = [MlSummaryGroup.from_json(dict(raw)) for raw in raw_groups]
    return sorted(groups, key=lambda group: group.label)


def render_markdown(
    groups: list[MlSummaryGroup],
    *,
    summary_path: Path,
    goal: str,
    target_labels: list[str],
    top_n: int,
    chart_paths: list[Path],
    ml_workbench_lines: list[str],
    sklearn_lines: list[str],
    warnings: list[str],
) -> str:
    """계산된 해석 결과를 사람이 읽는 Markdown으로 만든다."""

    label_counts = count_labels(groups)
    attention_groups = [group for group in groups if group.needs_balance_attention]
    coach = leveling_coach_v1(groups)
    lines: list[str] = [
        "# 휴리스틱 레벨링 워크벤치 리포트",
        "",
        f"- 입력 파일: `{summary_path}`",
        f"- 그룹 수: {len(groups)}",
        f"- 레벨링 목표: `{goal}`",
        f"- 집중 label: `{', '.join(target_labels)}`",
        "",
        "## 분석 방식",
        "",
        "- 먼저 시뮬레이션 summary로 레벨링 목표 band와의 거리인 `leveling_loss`를 계산합니다.",
        "- 데이터가 충분하면 train/test split으로 tabular 회귀 모델을 학습해 loss 예측 성능을 확인합니다.",
        "- 현재 summary에 조정 가능한 knob가 부족하면, 모델 추천보다 추가 실험 설계를 우선 제안합니다.",
        "",
        "## 한줄 해석",
        "",
        (
            f"- balance attention 그룹은 {len(attention_groups)}/{len(groups)}개입니다. "
            f"good_playfeel {label_counts.get('good_playfeel', 0)}개, "
            f"tempo_drag {label_counts.get('tempo_drag', 0)}개, "
            f"too_hard {label_counts.get('too_hard', 0)}개가 보입니다."
        ),
        "",
        "## Leveling Coach v1",
        "",
        f"- 현재 등급: **{coach['grade']}**",
        f"- 한줄 판정: {coach['summary']}",
        f"- 신뢰도: {coach['confidence']}",
        "",
        "### 가장 먼저 할 일",
        "",
        *[f"- {action}" for action in coach["actions"]],
        "",
        "### 근거",
        "",
        *[f"- {evidence}" for evidence in coach["evidence"]],
        "",
        "## Label 분포",
        "",
        *label_count_lines(label_counts),
        "",
        "## 실험별 비교",
        "",
        *experiment_comparison_lines(groups),
        "",
        "## 기본 런 곡선 진단",
        "",
        *basic_run_curve_lines(groups),
        "",
        "## Heuristic Target v2 진단",
        "",
        *target_v2_diagnostic_lines(groups, top_n=top_n),
        "",
        "## Good Playfeel 후보",
        "",
        *group_lines(
            select_groups(groups, include_label="good_playfeel", top_n=top_n),
        ),
        "",
        "## Balance Attention 후보",
        "",
        *group_lines(
            select_groups(
                groups,
                include_label="needs_balance_attention",
                top_n=top_n,
                attention_first=True,
            ),
        ),
        "",
        "## Tempo Drag 분석",
        "",
        *group_lines(select_groups(groups, include_label="tempo_drag", top_n=top_n)),
        "",
        "## 목표별 추천",
        "",
        *goal_recommendation_lines(groups, goal=goal, top_n=top_n),
        "",
        "## 휴리스틱 레벨링 워크벤치",
        "",
        *ml_workbench_lines,
        "",
        "## 차트",
        "",
    ]
    if chart_paths:
        for path in chart_paths:
            lines.append(f"![{chart_title_for_path(path)}]({path.name})")
    else:
        lines.append("- 차트를 생성하지 않았습니다.")
    lines.extend(["", "## Decision Tree 설명 힌트", "", *sklearn_lines])
    if warnings:
        lines.extend(["", "## 경고", "", *[f"- {warning}" for warning in warnings]])
    lines.append("")
    return "\n".join(lines)


def leveling_coach_v1(groups: list[MlSummaryGroup]) -> dict[str, Any]:
    """비기획자가 바로 읽을 수 있는 등급과 다음 액션을 만든다."""

    # 이 함수는 자동 튜닝을 하지 않는다.
    # 수치가 의미하는 바를 "어느 knob을 어느 방향으로 볼지"로 번역한다.
    group_count = max(len(groups), 1)
    attention_groups = [group for group in groups if group.needs_balance_attention]
    tempo_groups = [group for group in groups if "tempo_drag" in group.ml_labels]
    too_hard_groups = [group for group in groups if "too_hard" in group.ml_labels]
    good_groups = [group for group in groups if "good_playfeel" in group.ml_labels]

    # 초반 기본기 판단에 쓰는 대표 지표다.
    pair_s1_boss_standard = find_group(groups, "pair_mult", 1, "boss", "standard")
    baseline_s1_boss_standard = find_group(groups, "baseline", 1, "boss", "standard")
    s2_boss_too_hard_count = sum(
        1
        for group in too_hard_groups
        if group.station == 2 and group.blind_tier == "boss"
    )
    safety_tempo_count = sum(
        1 for group in tempo_groups if group.loadout_id == "safety_item"
    )

    score = 100
    evidence: list[str] = []
    actions: list[str] = []

    attention_ratio = len(attention_groups) / group_count
    if attention_ratio >= 0.60:
        score -= 25
        evidence.append(
            f"balance attention 그룹이 {len(attention_groups)}/{group_count}개로 많습니다."
        )
        actions.append("전체 자동 튜닝보다 우선순위를 좁혀 S1 boss, safety_item, S2 boss를 순서대로 보세요.")

    if pair_s1_boss_standard is None:
        score -= 10
        evidence.append("pair_mult S1 boss standard 데이터가 없어 첫 보스 벽을 판정하기 어렵습니다.")
    elif pair_s1_boss_standard.clear_rate < 0.45:
        score -= 20
        evidence.append(
            "최소 Jester 기준 첫 보스 벽이 높습니다. "
            f"pair_mult S1 boss standard clear {_percent(pair_s1_boss_standard.clear_rate)}."
        )
        actions.append("S1 boss target multiplier나 boss modifier 강도를 소폭 완화하세요.")
    else:
        evidence.append(
            "최소 Jester 기준 첫 보스 벽은 통과권입니다. "
            f"pair_mult S1 boss standard clear {_percent(pair_s1_boss_standard.clear_rate)}."
        )

    if baseline_s1_boss_standard is not None and baseline_s1_boss_standard.clear_rate > 0.30:
        score -= 10
        evidence.append(
            "baseline S1 boss가 너무 잘 깨질 수 있습니다. "
            f"clear {_percent(baseline_s1_boss_standard.clear_rate)}."
        )
        actions.append("baseline으로도 boss가 쉬우면 build 필요성이 약해지므로 S1 boss 완화를 되돌리거나 보상 구조를 확인하세요.")

    if safety_tempo_count > 0:
        score -= min(25, safety_tempo_count * 4)
        worst = max(
            [group for group in tempo_groups if group.loadout_id == "safety_item"],
            key=lambda group: group.avg_turn_count,
        )
        evidence.append(
            f"safety_item tempo_drag가 {safety_tempo_count}개입니다. "
            f"최악 구간은 {worst.label}, 평균 {_fixed(worst.avg_turn_count)}턴."
        )
        actions.append("safety_item은 클리어 보조보다 전투 지연을 만들고 있습니다. 발동 횟수/보호량/조건을 제한하세요.")

    if s2_boss_too_hard_count > 0:
        score -= min(20, s2_boss_too_hard_count * 3)
        evidence.append(f"S2 boss too_hard 그룹이 {s2_boss_too_hard_count}개입니다.")
        actions.append("S2 boss는 target/resource/modifier 중 하나만 완화해 병목 원인을 분리하세요.")

    if not good_groups:
        score -= 15
        evidence.append("good_playfeel 그룹이 없습니다.")
        actions.append("목표 점수나 보상형 Jester/item 조합을 낮은 위험 구간부터 다시 잡으세요.")
    else:
        evidence.append(f"good_playfeel 그룹은 {len(good_groups)}개입니다.")

    if score >= 85:
        grade = "A"
        summary = "초반 기본기가 대체로 통과권입니다."
    elif score >= 70:
        grade = "B"
        summary = "플레이테스트 전 일부 튜닝이 필요합니다."
    elif score >= 50:
        grade = "C"
        summary = "유입/보스/템포 중 명확한 병목이 있어 우선순위 튜닝이 필요합니다."
    else:
        grade = "D"
        summary = "현재 수치로는 플레이테스트 전에 기본 레벨링 보강이 필요합니다."

    if not actions:
        actions.append("큰 병목은 보이지 않습니다. 500 runs 이상으로 표본을 키워 확인하세요.")

    confidence = "중간"
    if group_count >= 90:
        confidence = "높음"
    elif group_count < 20:
        confidence = "낮음"

    return {
        "grade": grade,
        "summary": summary,
        "confidence": confidence,
        "actions": actions[:5],
        "evidence": evidence,
    }


def find_group(
    groups: list[MlSummaryGroup],
    loadout_id: str,
    station: int,
    blind_tier: str,
    difficulty: str,
) -> MlSummaryGroup | None:
    """특정 조건의 group을 찾는다."""

    for group in groups:
        if (
            group.loadout_id == loadout_id
            and group.experiment_id == "baseline"
            and group.station == station
            and group.blind_tier == blind_tier
            and group.difficulty == difficulty
        ):
            return group
    return None


def experiment_comparison_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """실험 프리셋별 평균 지표를 비교해 병목 축을 읽기 쉽게 만든다."""

    experiment_ids = sorted({group.experiment_id for group in groups})
    if len(experiment_ids) <= 1:
        return ["- 단일 실험 세트입니다."]

    lines: list[str] = []
    stats: dict[str, tuple[float, float]] = {}
    for experiment_id in experiment_ids:
        experiment_groups = [
            group for group in groups if group.experiment_id == experiment_id
        ]
        group_count = len(experiment_groups)
        if group_count == 0:
            continue
        avg_clear = sum(group.clear_rate for group in experiment_groups) / group_count
        avg_turn = sum(group.avg_turn_count for group in experiment_groups) / group_count
        stats[experiment_id] = (avg_clear, avg_turn)
        attention_count = sum(
            1 for group in experiment_groups if group.needs_balance_attention
        )
        too_hard_count = sum(
            1 for group in experiment_groups if "too_hard" in group.ml_labels
        )
        tempo_drag_count = sum(
            1 for group in experiment_groups if "tempo_drag" in group.ml_labels
        )
        good_count = sum(
            1 for group in experiment_groups if "good_playfeel" in group.ml_labels
        )
        lines.append(
            f"- `{experiment_id}`: 평균 clear {_percent(avg_clear)}, "
            f"평균 턴 {_fixed(avg_turn)}, attention {attention_count}/{group_count}, "
            f"too_hard {too_hard_count}, tempo_drag {tempo_drag_count}, "
            f"good_playfeel {good_count}"
        )

    baseline_stats = stats.get("baseline")
    candidate_stats = {
        experiment_id: values
        for experiment_id, values in stats.items()
        if experiment_id != "baseline"
    }
    if baseline_stats is None or not candidate_stats:
        return lines

    best_clear_id, best_clear_values = max(
        candidate_stats.items(),
        key=lambda entry: entry[1][0],
    )
    fastest_id, fastest_values = min(
        candidate_stats.items(),
        key=lambda entry: entry[1][1],
    )
    lines.extend(
        [
            (
                f"- 기준 baseline 대비 평균 clear 개선 후보: `{best_clear_id}` "
                f"{_percent(baseline_stats[0])} -> {_percent(best_clear_values[0])}."
            ),
            (
                f"- 전투 시간 관점 후보: `{fastest_id}` "
                f"{_fixed(fastest_values[1])}턴."
            ),
        ]
    )
    return lines


def basic_run_curve_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """8 station 기본 런에서 curve별 병목 station을 요약한다."""

    curve_ids = sorted(
        {
            group.experiment_id
            for group in groups
            if group.experiment_id == "baseline_curve_160"
            or group.experiment_id.startswith("station_curve_")
        }
    )
    if not curve_ids:
        return ["- station curve 실험 데이터가 없습니다."]

    lines: list[str] = []
    for experiment_id in curve_ids:
        curve_groups = [group for group in groups if group.experiment_id == experiment_id]
        stations = sorted({group.station for group in curve_groups})
        if not stations:
            continue
        boss_groups = [group for group in curve_groups if group.blind_tier == "boss"]
        avg_clear = sum(group.clear_rate for group in curve_groups) / len(curve_groups)
        boss_clear = (
            sum(group.clear_rate for group in boss_groups) / len(boss_groups)
            if boss_groups
            else 0
        )
        attention_count = sum(
            1 for group in curve_groups if group.needs_balance_attention
        )
        lines.append(
            f"- `{experiment_id}`: 전체 평균 clear {_percent(avg_clear)}, "
            f"boss 평균 clear {_percent(boss_clear)}, "
            f"attention {attention_count}/{len(curve_groups)}"
        )
        for station in stations:
            station_groups = [group for group in curve_groups if group.station == station]
            station_boss_groups = [
                group for group in station_groups if group.blind_tier == "boss"
            ]
            station_clear = sum(group.clear_rate for group in station_groups) / len(
                station_groups
            )
            station_boss_clear = (
                sum(group.clear_rate for group in station_boss_groups)
                / len(station_boss_groups)
                if station_boss_groups
                else 0
            )
            hard_count = sum(
                1 for group in station_groups if "too_hard" in group.ml_labels
            )
            tempo_count = sum(
                1 for group in station_groups if "tempo_drag" in group.ml_labels
            )
            lines.append(
                f"  - S{station}: 전체 {_percent(station_clear)}, "
                f"boss {_percent(station_boss_clear)}, "
                f"too_hard {hard_count}, tempo_drag {tempo_count}"
            )
    return lines


def count_labels(groups: list[MlSummaryGroup]) -> Counter[str]:
    """모든 group의 ml_labels를 세어 label 분포를 만든다."""

    counter: Counter[str] = Counter()
    for group in groups:
        counter.update(group.ml_labels)
    return counter


def target_v2_diagnostic_lines(
    groups: list[MlSummaryGroup],
    *,
    top_n: int,
) -> list[str]:
    """ml_label_v2의 다중 타겟을 사람이 읽을 수 있는 섹션으로 만든다."""

    groups_with_v2 = [group for group in groups if group.ml_target_labels_v2]
    if not groups_with_v2:
        return ["- v2 target label이 없습니다. 최신 summary를 다시 생성해야 합니다."]

    lines: list[str] = [
        (
            f"- v2 attention 그룹은 "
            f"{sum(1 for group in groups_with_v2 if group.needs_balance_attention_v2)}"
            f"/{len(groups_with_v2)}개입니다."
        )
    ]
    target_order = [
        "difficulty",
        "tempo",
        "resource_pressure",
        "score_spike",
        "decision_density",
    ]
    for target in target_order:
        counter: Counter[str] = Counter(
            group.ml_target_labels_v2.get(target, "unknown")
            for group in groups_with_v2
        )
        lines.append(f"- `{target}` 분포: {_counter_inline(counter)}")
    lines.extend(["", "### v2 우선 점검 후보"])

    candidates = sorted(
        [group for group in groups_with_v2 if group.needs_balance_attention_v2],
        key=lambda group: (
            _target_v2_priority(group),
            -group.avg_turn_count,
            group.clear_rate,
        ),
    )[:top_n]
    if not candidates:
        lines.append("- v2 기준 우선 점검 후보가 없습니다.")
        return lines

    for group in candidates:
        labels = group.ml_target_labels_v2
        lines.append(
            f"- `{group.label}`: clear {_percent(group.clear_rate)}, "
            f"turn {_fixed(group.avg_turn_count)}, "
            f"difficulty `{labels.get('difficulty', 'unknown')}`, "
            f"tempo `{labels.get('tempo', 'unknown')}`, "
            f"resource `{labels.get('resource_pressure', 'unknown')}`, "
            f"spike `{labels.get('score_spike', 'unknown')}`, "
            f"agency `{labels.get('decision_density', 'unknown')}`"
        )
    return lines


def _counter_inline(counter: Counter[str]) -> str:
    if not counter:
        return "없음"
    return ", ".join(f"{label} {count}" for label, count in counter.most_common())


def _target_v2_priority(group: MlSummaryGroup) -> int:
    """한눈에 보기 위한 v2 위험도 정렬값이다. 숫자가 낮을수록 먼저 본다."""

    labels = group.ml_target_labels_v2
    high_risk = {
        "too_hard",
        "tempo_drag",
        "deck_pressure_high",
        "resource_starved",
        "spike_flat",
        "low_agency",
        "too_many_steps",
    }
    medium_risk = {"too_easy", "tempo_too_fast", "resource_too_loose"}
    if any(value in high_risk for value in labels.values()):
        return 0
    if any(value in medium_risk for value in labels.values()):
        return 1
    return 2


def label_count_lines(counter: Counter[str]) -> list[str]:
    """label 분포를 Markdown bullet로 만든다."""

    if not counter:
        return ["- label이 없습니다."]
    return [f"- `{label}`: {count}개" for label, count in counter.most_common()]


def select_groups(
    groups: list[MlSummaryGroup],
    *,
    include_label: str,
    top_n: int,
    attention_first: bool = False,
) -> list[MlSummaryGroup]:
    """특정 label을 가진 group을 우선순위 순서로 고른다."""

    selected = [group for group in groups if include_label in group.ml_labels]
    if attention_first:
        return sorted(
            selected,
            key=lambda group: (
                "tempo_drag" not in group.ml_labels,
                "too_hard" not in group.ml_labels,
                -group.avg_turn_count,
            ),
        )[:top_n]
    return sorted(
        selected,
        key=lambda group: (
            -group.slow_clear_share_of_clears,
            -group.clear_rate,
            -group.avg_max_single_confirm_score,
        ),
    )[:top_n]


def group_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """group 목록을 핵심 지표가 포함된 Markdown bullet로 만든다."""

    if not groups:
        return ["- 해당 group이 없습니다."]
    lines: list[str] = []
    for group in groups:
        lines.append(
            f"- `{group.label}`: clear {_percent(group.clear_rate)}, "
            f"turn {_fixed(group.avg_turn_count)}, "
            f"maxHit {_fixed(group.avg_max_single_confirm_score)}, "
            f"slowClearShare {_percent(group.slow_clear_share_of_clears)}, "
            f"labels `{', '.join(group.ml_labels)}`"
        )
    return lines


def goal_recommendation_lines(
    groups: list[MlSummaryGroup],
    *,
    goal: str,
    top_n: int,
) -> list[str]:
    """사용자가 고른 레벨링 목표에 맞는 우선 점검 후보를 만든다."""

    labels = LEVELING_GOAL_LABELS[goal]
    candidates = [
        group
        for group in groups
        if any(label in group.ml_labels for label in labels)
    ]
    if not candidates:
        return ["- 목표에 맞는 후보가 없습니다."]
    candidates = sorted(
        candidates,
        key=lambda group: (
            "needs_balance_attention" not in group.ml_labels,
            "tempo_drag" not in group.ml_labels,
            "too_hard" not in group.ml_labels,
            -group.avg_turn_count,
        ),
    )
    return group_lines(candidates[:top_n])


def ml_leveling_workbench_lines(
    groups: list[MlSummaryGroup],
) -> tuple[list[str], str | None]:
    """레벨링용 tabular ML의 데이터 상태, 목표, 모델 결과를 요약한다."""

    losses = [leveling_loss(group) for group in groups]
    lines: list[str] = [
        "### 목표/타겟",
        "",
        "- supervised target은 규칙 label이 아니라 `leveling_loss`입니다.",
        "- `leveling_loss`는 clear rate, score ratio, turn count, slow clear share가 목표 band에서 벗어난 정도입니다.",
        "- 보조 분류 target은 `leveling_class`입니다. 문제 유형을 `good_run`, `too_hard`, `too_easy`, `tempo_drag`, `no_agency`, `high_roll_fun`, `unstable`로 나눕니다.",
        "- 낮을수록 현재 구간의 기획 목표에 가깝고, 높을수록 튜닝 우선순위가 높습니다.",
        "",
        "### 데이터 충분성",
        "",
        *data_sufficiency_lines(groups),
        "",
        "### 분류 타겟 분포",
        "",
        *leveling_class_distribution_lines(groups),
        "",
        "### 상관 관계",
        "",
        *correlation_lines(groups, losses),
        "",
        "### 모델 학습/검증",
        "",
    ]

    model_lines, warning = train_leveling_model_lines(groups, losses)
    lines.extend(model_lines)
    lines.extend(
        [
            "",
            "### 분류 모델/오차행렬",
            "",
            *train_leveling_classifier_lines(groups),
        ],
    )
    lines.extend(["", "### 모델 기반 다음 액션", "", *model_action_lines(groups, losses)])
    return lines, warning


def data_sufficiency_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """모델을 믿기 전에 봐야 하는 데이터 크기와 커버리지를 점검한다."""

    group_count = len(groups)
    total_runs = sum(group.run_count for group in groups)
    stations = sorted({group.station for group in groups})
    tiers = sorted({group.blind_tier for group in groups})
    difficulties = sorted({group.difficulty for group in groups})
    loadouts = sorted({group.loadout_id for group in groups})
    experiments = sorted({group.experiment_id for group in groups})
    thin_groups = sum(1 for group in groups if group.run_count < 100)
    sparse_slice_count = sum(
        1
        for station in stations
        for tier in tiers
        for difficulty in difficulties
        if not any(
            group.station == station
            and group.blind_tier == tier
            and group.difficulty == difficulty
            for group in groups
        )
    )
    lines = [
        f"- group 수: {group_count}개, 총 run 수: {total_runs}회.",
        (
            f"- coverage: station {len(stations)}개, tier {len(tiers)}개, "
            f"difficulty {len(difficulties)}개, loadout {len(loadouts)}개, "
            f"experiment {len(experiments)}개."
        ),
    ]
    if thin_groups:
        lines.append(f"- run_count 100 미만 group이 {thin_groups}개입니다. 우선 100~300 runs로 키우세요.")
    if sparse_slice_count:
        lines.append(f"- station/tier/difficulty 빈 조합이 {sparse_slice_count}개입니다.")
    if group_count < 40:
        lines.append("- 모델 검증에는 부족합니다. 최소 40 group, 권장 120 group 이상을 먼저 확보하세요.")
    elif group_count < 120:
        lines.append("- 1차 모델은 가능하지만 추천안 신뢰도는 중간입니다. 120 group 이상을 권장합니다.")
    else:
        lines.append("- 1차 tabular 모델을 학습/검증할 수 있는 크기입니다.")

    if len(experiments) <= 1:
        lines.append(
            "- 조정 가능한 knob 실험이 부족합니다. target multiplier, boss 완화, resource knob sweep을 추가하세요."
        )
    if any(group.sweep_metadata for group in groups):
        numeric_keys = sorted(
            {
                key
                for group in groups
                for key, value in group.sweep_metadata.items()
                if isinstance(value, (int, float))
            },
        )
        if numeric_keys:
            lines.append(f"- sweep numeric feature: `{', '.join(numeric_keys)}`.")
    return lines


def correlation_lines(groups: list[MlSummaryGroup], losses: list[float]) -> list[str]:
    """주요 결과 지표와 leveling_loss의 Pearson 상관을 보여준다."""

    feature_values: dict[str, list[float]] = {
        "clear_rate": [group.clear_rate for group in groups],
        "avg_score_ratio": [group.avg_score_ratio for group in groups],
        "avg_turn_count": [group.avg_turn_count for group in groups],
        "avg_max_single_confirm_score": [
            group.avg_max_single_confirm_score for group in groups
        ],
        "slow_clear_share_of_clears": [
            group.slow_clear_share_of_clears for group in groups
        ],
        "avg_confirm_action_count": [group.avg_confirm_action_count for group in groups],
        "deck_exhausted_rate": [
            group.outcome_counts.get("deck_exhausted", 0) / max(group.run_count, 1)
            for group in groups
        ],
        "board_locked_rate": [
            group.outcome_counts.get("board_locked", 0) / max(group.run_count, 1)
            for group in groups
        ],
    }
    correlations = sorted(
        (
            (name, pearson(values, losses))
            for name, values in feature_values.items()
        ),
        key=lambda item: abs(item[1]),
        reverse=True,
    )
    lines = [
        "- 상관은 인과가 아니라, 어떤 결과 지표가 목표 이탈과 같이 움직이는지 보는 우선순위 신호입니다."
    ]
    for name, value in correlations[:6]:
        lines.append(f"- `{name}` vs `leveling_loss`: {_signed_fixed(value)}")
    return lines


def leveling_class_distribution_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """분류 타겟의 분포를 보여준다."""

    counter = Counter(leveling_class(group) for group in groups)
    if not counter:
        return ["- 분류할 group이 없습니다."]
    return [f"- `{label}`: {count}개" for label, count in counter.most_common()]


def train_leveling_model_lines(
    groups: list[MlSummaryGroup],
    losses: list[float],
) -> tuple[list[str], str | None]:
    """현재 summary 피처로 loss 예측 모델을 학습하고 검증한다."""

    if len(groups) < 20:
        return (
            [
                "- 데이터가 20 group 미만이라 모델 학습을 건너뜁니다.",
                "- 먼저 station/tier/difficulty/loadout 조합을 넓혀 summary를 다시 생성하세요.",
            ],
            None,
        )

    try:
        from sklearn.ensemble import RandomForestRegressor  # type: ignore
        from sklearn.linear_model import Ridge  # type: ignore
        from sklearn.metrics import mean_absolute_error, r2_score  # type: ignore
    except Exception:
        return (
            [
                "- scikit-learn이 없어 학습/검증을 건너뜁니다.",
                "- 노트북의 `auto_install_missing=True`를 켜거나 `pip install scikit-learn` 후 다시 실행하세요.",
            ],
            None,
        )

    x_rows, feature_names = feature_matrix(groups)
    train_indexes, test_indexes = grouped_train_test_indexes(groups)
    if len(test_indexes) < 4 or len(train_indexes) < 12:
        return (
            [
                "- train/test split을 만들기에는 조합 수가 부족합니다.",
                "- 같은 조건 seed만 늘리는 것보다 서로 다른 experiment/loadout/난이도 조합을 늘리세요.",
            ],
            None,
        )

    x_train = [x_rows[index] for index in train_indexes]
    x_test = [x_rows[index] for index in test_indexes]
    y_train = [losses[index] for index in train_indexes]
    y_test = [losses[index] for index in test_indexes]

    baseline = Ridge(alpha=1.0)
    baseline.fit(x_train, y_train)
    baseline_pred = baseline.predict(x_test)

    model = RandomForestRegressor(
        n_estimators=120,
        max_depth=5,
        min_samples_leaf=2,
        random_state=42,
    )
    model.fit(x_train, y_train)
    model_pred = model.predict(x_test)

    baseline_mae = float(mean_absolute_error(y_test, baseline_pred))
    model_mae = float(mean_absolute_error(y_test, model_pred))
    model_r2 = float(r2_score(y_test, model_pred)) if len(set(y_test)) > 1 else 0.0

    importances = sorted(
        zip(feature_names, model.feature_importances_, strict=True),
        key=lambda item: item[1],
        reverse=True,
    )
    lines = [
        f"- split: train {len(train_indexes)} group / test {len(test_indexes)} group.",
        f"- baseline Ridge MAE: {_fixed(baseline_mae)}.",
        f"- RandomForestRegressor MAE: {_fixed(model_mae)}, R2: {_signed_fixed(model_r2)}.",
        "- 추천 기본 모델: 현재 aggregate tabular 데이터에는 딥러닝보다 tree ensemble이 맞습니다.",
        "- 중요 피처:",
    ]
    for name, value in importances[:8]:
        if value > 0:
            lines.append(f"  - `{name}`: {_fixed(float(value))}")
    if model_mae >= baseline_mae:
        lines.append("- tree ensemble이 baseline을 이기지 못했습니다. knob sweep 데이터가 더 필요합니다.")
    else:
        lines.append("- tree ensemble이 baseline보다 낫습니다. 다음 단계는 모델 추천안을 재시뮬레이션으로 검증하는 것입니다.")
    return lines, None


def train_leveling_classifier_lines(groups: list[MlSummaryGroup]) -> list[str]:
    """leveling_class를 예측하는 분류 모델과 오차행렬을 만든다."""

    labels = [leveling_class(group) for group in groups]
    if len(groups) < 20:
        return [
            "- 데이터가 20 group 미만이라 분류 모델 학습을 건너뜁니다.",
            "- 그래도 위 분류 타겟 분포는 현재 데이터의 문제 유형을 읽는 데 사용할 수 있습니다.",
        ]
    if len(set(labels)) < 2:
        return ["- `leveling_class`가 한 종류뿐이라 분류 모델을 만들지 않았습니다."]

    try:
        from sklearn.ensemble import RandomForestClassifier  # type: ignore
        from sklearn.metrics import (  # type: ignore
            accuracy_score,
            confusion_matrix,
            precision_recall_fscore_support,
        )
    except Exception:
        return [
            "- scikit-learn이 없어 분류 모델과 confusion matrix를 건너뜁니다.",
        ]

    x_rows, feature_names = feature_matrix(groups)
    train_indexes, test_indexes = grouped_train_test_indexes(groups)
    if len(test_indexes) < 4 or len(train_indexes) < 12:
        return [
            "- train/test split을 만들기에는 조합 수가 부족해 분류 모델을 건너뜁니다.",
            "- 대량 progression sweep을 만든 뒤 다시 확인하세요.",
        ]

    x_train = [x_rows[index] for index in train_indexes]
    x_test = [x_rows[index] for index in test_indexes]
    y_train = [labels[index] for index in train_indexes]
    y_test = [labels[index] for index in test_indexes]
    if len(set(y_train)) < 2:
        return ["- train split의 `leveling_class`가 한 종류뿐이라 분류 모델을 만들지 않았습니다."]

    model = RandomForestClassifier(
        n_estimators=160,
        max_depth=6,
        min_samples_leaf=2,
        random_state=42,
        class_weight="balanced",
    )
    model.fit(x_train, y_train)
    y_pred = list(model.predict(x_test))
    ordered_labels = [
        label
        for label in [
            "good_run",
            "too_hard",
            "too_easy",
            "tempo_drag",
            "no_agency",
            "high_roll_fun",
            "unstable",
        ]
        if label in set(y_test) or label in set(y_pred) or label in set(y_train)
    ]
    precision, recall, f1, support = precision_recall_fscore_support(
        y_test,
        y_pred,
        labels=ordered_labels,
        zero_division=0,
    )
    matrix = confusion_matrix(y_test, y_pred, labels=ordered_labels)
    importances = sorted(
        zip(feature_names, model.feature_importances_, strict=True),
        key=lambda item: item[1],
        reverse=True,
    )
    lines = [
        f"- split: train {len(train_indexes)} group / test {len(test_indexes)} group.",
        f"- accuracy: {_fixed(float(accuracy_score(y_test, y_pred)))}.",
        "- class별 precision/recall/F1:",
    ]
    for label, p_value, r_value, f_value, support_value in zip(
        ordered_labels,
        precision,
        recall,
        f1,
        support,
        strict=True,
    ):
        lines.append(
            f"  - `{label}`: precision {_fixed(float(p_value))}, "
            f"recall {_fixed(float(r_value))}, F1 {_fixed(float(f_value))}, "
            f"support {int(support_value)}"
        )
    lines.extend(["", "#### Confusion Matrix", ""])
    lines.extend(confusion_matrix_markdown(ordered_labels, matrix.tolist()))
    lines.extend(["", "- 분류 중요 피처:"])
    for name, value in importances[:8]:
        if value > 0:
            lines.append(f"  - `{name}`: {_fixed(float(value))}")
    return lines


def confusion_matrix_markdown(labels: list[str], matrix: list[list[int]]) -> list[str]:
    """confusion matrix를 Markdown table로 만든다."""

    if not labels:
        return ["- 표시할 label이 없습니다."]
    header = "| actual \\ predicted | " + " | ".join(f"`{label}`" for label in labels) + " |"
    divider = "|---|" + "|".join("---:" for _ in labels) + "|"
    rows = [header, divider]
    for label, values in zip(labels, matrix, strict=True):
        rows.append(
            f"| `{label}` | " + " | ".join(str(value) for value in values) + " |"
        )
    return rows


def model_action_lines(groups: list[MlSummaryGroup], losses: list[float]) -> list[str]:
    """학습 결과와 관계없이 지금 당장 추가해야 할 실험/튜닝 후보를 정한다."""

    ranked = sorted(zip(groups, losses, strict=True), key=lambda item: item[1], reverse=True)
    worst_lines = [
        (
            f"- 우선 재시뮬레이션 후보 `{group.label}`: loss {_fixed(loss)}, "
            f"목표 band {target_band_label(group)}."
        )
        for group, loss in ranked[:5]
    ]
    lines = [
        "- 다음 batch는 random이 아니라 knob sweep으로 만드세요: target multiplier, boss modifier 강도, resource 보정, market profile.",
        "- 각 후보는 최소 100 runs, 모델 검증용 상위 후보는 300~500 runs로 재확인하세요.",
        "- 모델이 추천한 값은 바로 게임에 반영하지 말고, 반드시 Dart simulator 재실행으로 `leveling_loss` 감소를 확인하세요.",
        "",
        "#### 우선 수집/검증 후보",
        *worst_lines,
    ]
    return lines


def feature_matrix(groups: list[MlSummaryGroup]) -> tuple[list[list[float]], list[str]]:
    """summary에서 현재 사용 가능한 입력 피처를 수치 행렬로 바꾼다."""

    tier_order = {"small": 0, "big": 1, "boss": 2}
    difficulty_order = {"relaxed": 0, "standard": 1, "challenge": 2}
    loadouts = sorted({group.loadout_id for group in groups})
    experiments = sorted({group.experiment_id for group in groups})
    numeric_sweep_keys = sorted(
        {
            key
            for group in groups
            for key, value in group.sweep_metadata.items()
            if isinstance(value, (int, float))
        },
    )
    categorical_sweep_values: dict[str, list[str]] = {}
    for group in groups:
        for key, value in group.sweep_metadata.items():
            if isinstance(value, str):
                categorical_sweep_values.setdefault(key, []).append(value)
    categorical_sweep_values = {
        key: sorted(set(values)) for key, values in categorical_sweep_values.items()
    }
    base_names = ["station", "tier_index", "difficulty_index"]
    feature_names = [
        *base_names,
        *[f"loadout={loadout}" for loadout in loadouts],
        *[f"experiment={experiment}" for experiment in experiments],
        *numeric_sweep_keys,
        *[
            f"{key}={value}"
            for key, values in categorical_sweep_values.items()
            for value in values
        ],
    ]
    rows: list[list[float]] = []
    for group in groups:
        row = [
            float(group.station),
            float(tier_order.get(group.blind_tier, 99)),
            float(difficulty_order.get(group.difficulty, 99)),
        ]
        row.extend(1.0 if group.loadout_id == loadout else 0.0 for loadout in loadouts)
        row.extend(
            1.0 if group.experiment_id == experiment else 0.0
            for experiment in experiments
        )
        row.extend(
            float(group.sweep_metadata.get(key, 0.0))
            if isinstance(group.sweep_metadata.get(key), (int, float))
            else 0.0
            for key in numeric_sweep_keys
        )
        for key, values in categorical_sweep_values.items():
            raw_value = group.sweep_metadata.get(key)
            row.extend(1.0 if raw_value == value else 0.0 for value in values)
        rows.append(row)
    return rows, feature_names


def grouped_train_test_indexes(groups: list[MlSummaryGroup]) -> tuple[list[int], list[int]]:
    """같은 config가 양쪽에 섞이지 않도록 group 단위 split을 만든다."""

    indexes = list(range(len(groups)))
    test_indexes = [
        index
        for index in indexes
        if stable_bucket(groups[index].label, modulo=5) == 0
    ]
    train_indexes = [index for index in indexes if index not in set(test_indexes)]
    return train_indexes, test_indexes


def stable_bucket(value: str, *, modulo: int) -> int:
    total = 0
    for char in value:
        total = (total * 31 + ord(char)) % 1_000_003
    return total % modulo


def leveling_loss(group: MlSummaryGroup) -> float:
    """기획 목표 band에서 벗어난 정도를 하나의 최적화 target으로 만든다."""

    clear_min, clear_max = target_clear_band(group)
    turn_min, turn_max = target_turn_band(group)
    score_min, score_max = 0.95, 1.15
    slow_max = 0.20 if group.blind_tier == "boss" else 0.10
    clear_loss = band_distance(group.clear_rate, clear_min, clear_max) / 0.20
    turn_loss = band_distance(group.avg_turn_count, turn_min, turn_max) / 35.0
    score_loss = band_distance(group.avg_score_ratio, score_min, score_max) / 0.20
    slow_loss = max(0.0, group.slow_clear_share_of_clears - slow_max) / 0.30
    return clear_loss * 0.40 + turn_loss * 0.25 + score_loss * 0.25 + slow_loss * 0.10


def leveling_class(group: MlSummaryGroup) -> str:
    """기획자가 읽을 수 있는 문제 유형 분류 target을 만든다."""

    clear_min, clear_max = target_clear_band(group)
    turn_min, turn_max = target_turn_band(group)
    loss = leveling_loss(group)
    deck_exhausted_rate = group.outcome_counts.get("deck_exhausted", 0) / max(
        group.run_count,
        1,
    )
    if (
        group.slow_clear_share_of_clears > (0.25 if group.blind_tier == "boss" else 0.15)
        or group.avg_turn_count > turn_max + 20
        or group.tempo_risk_label == "clear_but_too_slow"
    ):
        return "tempo_drag"
    if (
        group.clear_rate < clear_min - 0.12
        or group.avg_score_ratio < 0.80
        or deck_exhausted_rate > 0.45
    ):
        return "too_hard"
    if (
        group.clear_rate > clear_max + 0.10
        or (group.avg_score_ratio > 1.25 and group.avg_turn_count < turn_min)
    ):
        return "too_easy"
    if group.avg_confirm_action_count < 2.0 and group.avg_turn_count > turn_min + 20:
        return "no_agency"
    if (
        group.avg_max_single_confirm_score >= 150
        and clear_min - 0.05 <= group.clear_rate <= clear_max + 0.10
        and group.avg_turn_count <= turn_max + 10
    ):
        return "high_roll_fun"
    if loss <= 0.35:
        return "good_run"
    return "unstable"


def target_clear_band(group: MlSummaryGroup) -> tuple[float, float]:
    tier_base = {
        "small": (0.70, 0.92),
        "big": (0.50, 0.78),
        "boss": (0.35, 0.62),
    }.get(group.blind_tier, (0.45, 0.75))
    difficulty_shift = {
        "relaxed": 0.08,
        "standard": 0.0,
        "challenge": -0.08,
    }.get(
        group.difficulty,
        0.0,
    )
    station_shift = -0.03 * max(group.station - 1, 0)
    low = max(0.05, tier_base[0] + difficulty_shift + station_shift)
    high = min(0.98, tier_base[1] + difficulty_shift + station_shift)
    return low, max(low + 0.10, high)


def target_turn_band(group: MlSummaryGroup) -> tuple[float, float]:
    base = {
        "small": (60.0, 95.0),
        "big": (75.0, 120.0),
        "boss": (90.0, 135.0),
    }.get(group.blind_tier, (75.0, 120.0))
    difficulty_shift = {
        "relaxed": -8.0,
        "standard": 0.0,
        "challenge": 10.0,
    }.get(
        group.difficulty,
        0.0,
    )
    station_shift = 4.0 * max(group.station - 1, 0)
    return base[0] + difficulty_shift + station_shift, base[1] + difficulty_shift + station_shift


def target_band_label(group: MlSummaryGroup) -> str:
    clear_min, clear_max = target_clear_band(group)
    turn_min, turn_max = target_turn_band(group)
    return (
        f"clear {_percent(clear_min)}~{_percent(clear_max)}, "
        f"turn {_fixed(turn_min)}~{_fixed(turn_max)}"
    )


def band_distance(value: float, low: float, high: float) -> float:
    if value < low:
        return low - value
    if value > high:
        return value - high
    return 0.0


def pearson(left: list[float], right: list[float]) -> float:
    if len(left) != len(right) or len(left) < 2:
        return 0.0
    left_mean = sum(left) / len(left)
    right_mean = sum(right) / len(right)
    numerator = sum(
        (left_value - left_mean) * (right_value - right_mean)
        for left_value, right_value in zip(left, right, strict=True)
    )
    left_denominator = math.sqrt(
        sum((left_value - left_mean) ** 2 for left_value in left)
    )
    right_denominator = math.sqrt(
        sum((right_value - right_mean) ** 2 for right_value in right)
    )
    if left_denominator == 0 or right_denominator == 0:
        return 0.0
    return numerator / (left_denominator * right_denominator)


def write_charts(
    groups: list[MlSummaryGroup],
    out_dir: Path,
    stem: str,
) -> tuple[list[Path], list[str]]:
    """label 분포와 loadout별 attention 수를 PNG 차트로 저장한다."""

    try:
        import matplotlib.pyplot as plt  # type: ignore
    except Exception:
        return [], ["matplotlib이 없어 차트 생성을 건너뛰었습니다."]

    configure_korean_matplotlib_font(plt)
    label_counts = count_labels(groups)
    has_experiment_matrix = len({group.experiment_id for group in groups}) > 1
    loadout_attention = Counter(
        (
            f"{group.experiment_id}/{group.loadout_id}"
            if has_experiment_matrix
            else group.loadout_id
        )
        for group in groups
        if group.needs_balance_attention
    )
    paths: list[Path] = []
    for suffix, title, counter in [
        ("label_distribution", "휴리스틱 Label 분포", label_counts),
        ("attention_by_loadout", "Loadout별 Balance Attention", loadout_attention),
    ]:
        path = out_dir / f"{stem}_{suffix}.png"
        labels = list(counter.keys())
        values = [counter[label] for label in labels]
        plt.figure(figsize=(max(8, len(labels) * 0.9), 5))
        plt.bar(range(len(labels)), values)
        plt.title(title)
        plt.xticks(range(len(labels)), labels, rotation=35, ha="right")
        plt.tight_layout()
        plt.savefig(path)
        plt.close()
        paths.append(path)
    return paths, []


def sklearn_hint_lines(groups: list[MlSummaryGroup]) -> tuple[list[str], str | None]:
    """sklearn이 있으면 규칙 기반 attention을 설명하는 feature를 보여준다."""

    try:
        from sklearn.tree import DecisionTreeClassifier  # type: ignore
    except Exception:
        return ["- scikit-learn이 없어 decision tree 설명 힌트를 건너뛰었습니다."], None

    # feature 의미:
    # - station: 어느 스테이션인지.
    # - tier_index: small/big/boss를 숫자로 바꾼 값.
    # - clear_rate: 클리어율.
    # - avg_turn_count: 평균 턴 수.
    # - avg_max_single_confirm_score: 평균 최대 한방 점수.
    tier_order = {"small": 0, "big": 1, "boss": 2}
    difficulty_order = {"relaxed": 0, "standard": 1, "challenge": 2}
    feature_names = [
        "station",
        "tier_index",
        "difficulty_index",
        "clear_rate",
        "avg_turn_count",
        "avg_max_single_confirm_score",
        "slow_clear_share_of_clears",
    ]
    x_rows = [
        [
            group.station,
            tier_order.get(group.blind_tier, 99),
            difficulty_order.get(group.difficulty, 99),
            group.clear_rate,
            group.avg_turn_count,
            group.avg_max_single_confirm_score,
            group.slow_clear_share_of_clears,
        ]
        for group in groups
    ]
    y_rows = [1 if group.needs_balance_attention else 0 for group in groups]
    if len(set(y_rows)) < 2:
        return ["- needs_balance_attention 값이 한쪽뿐이라 tree를 만들지 않았습니다."], None

    model = DecisionTreeClassifier(max_depth=3, random_state=42)
    model.fit(x_rows, y_rows)
    importances = sorted(
        zip(feature_names, model.feature_importances_, strict=True),
        key=lambda item: item[1],
        reverse=True,
    )
    lines = [
        "- 검증용 모델이 아니라 전체 group의 `needs_balance_attention` 규칙 판정을 설명하는 decision tree입니다.",
        "- feature importance:",
    ]
    for name, value in importances:
        if value > 0:
            lines.append(f"  - `{name}`: {_fixed(value)}")
    return lines, None


def configure_korean_matplotlib_font(plt: Any) -> None:
    """matplotlib에서 한글과 음수 기호가 깨질 가능성을 줄인다."""

    try:
        from matplotlib import font_manager  # type: ignore
    except Exception:
        return
    candidates = ["AppleGothic", "NanumGothic", "Noto Sans KR", "Malgun Gothic"]
    installed = {font.name for font in font_manager.fontManager.ttflist}
    for candidate in candidates:
        if candidate in installed:
            plt.rcParams["font.family"] = candidate
            break
    plt.rcParams["axes.unicode_minus"] = False


def chart_title_for_path(path: Path) -> str:
    name = path.name
    if name.endswith("_label_distribution.png"):
        return "Label 분포 차트"
    if name.endswith("_attention_by_loadout.png"):
        return "Loadout별 Attention 차트"
    return "레벨링 차트"


def _required_str(raw: dict[str, Any], field: str) -> str:
    value = raw.get(field)
    if isinstance(value, str):
        return value
    raise MlLevelingError(f"필수 문자열 필드가 없습니다: {field}")


def _required_int(raw: dict[str, Any], field: str) -> int:
    value = raw.get(field)
    if isinstance(value, int):
        return value
    raise MlLevelingError(f"필수 정수 필드가 없습니다: {field}")


def _required_float(raw: dict[str, Any], field: str) -> float:
    value = raw.get(field)
    if isinstance(value, (int, float)):
        return float(value)
    raise MlLevelingError(f"필수 숫자 필드가 없습니다: {field}")


def _optional_float(raw: dict[str, Any], field: str, *, default: float) -> float:
    value = raw.get(field)
    if value is None:
        return default
    if isinstance(value, (int, float)):
        return float(value)
    raise MlLevelingError(f"숫자여야 하는 필드입니다: {field}")


def _optional_str(raw: dict[str, Any], field: str, *, default: str) -> str:
    value = raw.get(field)
    if value is None:
        return default
    if isinstance(value, str):
        return value
    raise MlLevelingError(f"문자열이어야 하는 필드입니다: {field}")


def _parse_labels(raw: Any) -> list[str]:
    if raw is None:
        return []
    if not isinstance(raw, list):
        raise MlLevelingError("ml_labels는 list여야 합니다.")
    return [str(value) for value in raw]


def _parse_target_labels_v2(raw: Any) -> dict[str, str]:
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        raise MlLevelingError("ml_target_labels_v2는 object여야 합니다.")
    return {str(key): str(value) for key, value in raw.items()}


def _parse_sweep_metadata(raw: dict[str, Any]) -> dict[str, str | float]:
    """sweep dataset runner가 붙인 knob metadata를 모델 피처로 보존한다."""

    keys = [
        "sweep_mode",
        "sweep_candidate_id",
        "candidate_id",
        "base_experiment_id",
        "station_growth_experiment_id",
        "small_target_multiplier",
        "big_target_multiplier",
        "boss_target_multiplier",
        "s1_boss_target_multiplier",
        "s2_boss_target_multiplier",
        "s3_boss_target_multiplier",
    ]
    metadata: dict[str, str | float] = {}
    for key in keys:
        value = raw.get(key)
        if isinstance(value, str):
            metadata[key] = value
        elif isinstance(value, (int, float)):
            metadata[key] = float(value)
    return metadata


def _parse_int_counter(raw: Any) -> dict[str, int]:
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        raise MlLevelingError("outcome_counts는 object여야 합니다.")
    counter: dict[str, int] = {}
    for key, value in raw.items():
        if isinstance(value, int):
            counter[str(key)] = value
    return counter


def _percent(value: float) -> str:
    return f"{round(value * 100)}%"


def _fixed(value: float) -> str:
    return f"{value:.2f}"


def _signed_fixed(value: float) -> str:
    return f"{value:+.2f}"


if __name__ == "__main__":
    raise SystemExit(main())
