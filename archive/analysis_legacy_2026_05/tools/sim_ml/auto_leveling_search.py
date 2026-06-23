#!/usr/bin/env python3
"""시뮬레이션 후보를 자동으로 돌리고 한글 리포트로 추천값을 고른다."""

from __future__ import annotations

import argparse
import json
import itertools
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_OPTIONS: dict[str, Any] = {
    "mode": "s3_boss",
    "runs": 180,
    "seed": 9090,
    "bot": "planner_v2",
    "stations": "1,2,3",
    "difficulty": "standard",
    "experiment_id": "s1_boss_target_070",
    "package_experiment_id": "station_curve_125",
    "loadout_id": "s1_entry_bridge_build",
    "market_profile": "s1_buy_sly",
    "target_station": 3,
    "target_tier": "boss",
    "current_recommended_multiplier": 0.775,
    "multipliers": [0.8, 0.775, 0.75, 0.725, 0.7],
    "s1_multipliers": [0.75, 0.7],
    "s2_multipliers": [0.85, 0.8, 0.75],
    "s3_multipliers": [0.8, 0.775, 0.75],
    "packages": [],
    "out_prefix": "logs/sim/auto_leveling_s3_boss",
    "keep_jsonl": False,
}


class AutoLevelingError(Exception):
    """사용자가 읽을 수 있는 자동 탐색 오류."""


@dataclass(frozen=True)
class CandidateTarget:
    """한 후보가 실제 시뮬레이터에 넘길 target multiplier 묶음."""

    candidate_id: str
    multipliers: dict[str, float]

    @property
    def primary_multiplier(self) -> float:
        """기존 단일 탐색 리포트와 호환되는 대표 multiplier."""

        if "S3 boss" in self.multipliers:
            return self.multipliers["S3 boss"]
        return next(iter(self.multipliers.values()))

    @property
    def override_args(self) -> list[str]:
        """Dart CLI가 받는 --target-multiplier 문자열 목록."""

        args = []
        for key, value in self.multipliers.items():
            station, tier = key.split(" ", maxsplit=1)
            args.append(f"{station}:{tier}:{value}")
        return args


@dataclass(frozen=True)
class CandidateResult:
    """후보 target multiplier 묶음의 sequence summary 해석 결과."""

    target: CandidateTarget
    run_count: int
    path_clear_rate: float
    avg_cleared_steps: float
    avg_total_turn_count: float
    s3_boss_fail_rate: float
    s3_boss_avg_score_ratio: float
    s3_boss_avg_remaining_deck: float
    s3_boss_avg_max_hit: float
    failure_counts: dict[str, int]

    @property
    def recommendation_score(self) -> float:
        """기본기 있는 초반 런에 가까울수록 높은 점수를 준다."""

        # 목표는 완전 클리어가 아니라 S3 boss가 막힌 벽에서 어려운 벽으로 바뀌는지다.
        path_target = 0.22
        path_score = 1.0 - min(1.0, abs(self.path_clear_rate - path_target) / 0.22)

        # 너무 초반에 끊기지 않고 S3까지 도달하는 후보를 우선한다.
        depth_score = min(1.0, self.avg_cleared_steps / 6.5)

        # S3 boss 실패가 score ratio 0.85 근처면 한두 선택으로 돌파 가능한 벽이다.
        ratio_target = 0.85
        ratio_score = 1.0 - min(
            1.0,
            abs(self.s3_boss_avg_score_ratio - ratio_target) / 0.35,
        )

        # 덱이 거의 0장으로 끝나면 압박은 있으나 반복 플레이 피로가 커진다.
        deck_score = min(1.0, self.s3_boss_avg_remaining_deck / 4.0)

        # S3 boss가 적절히 주 병목이어야 S1/S2 온보딩을 망치지 않는다.
        s3_wall_score = min(1.0, self.s3_boss_fail_rate / 0.45)

        # 패키지 탐색에서는 S1/S2가 너무 일찍 막히면 학습 데이터가 뒤 구간까지 못 간다.
        s1_fail_rate = self.failure_rate("S1 boss")
        s2_fail_rate = self.failure_rate("S2 boss")
        early_gate_score = 1.0
        early_gate_score -= min(0.45, s1_fail_rate * 1.6)
        early_gate_score -= min(0.25, max(0.0, s2_fail_rate - 0.25) * 0.8)
        early_gate_score = max(0.0, early_gate_score)

        return (
            path_score * 0.25
            + depth_score * 0.22
            + ratio_score * 0.18
            + deck_score * 0.10
            + s3_wall_score * 0.12
            + early_gate_score * 0.13
        )

    @property
    def multiplier(self) -> float:
        """기존 노트북/CLI 호출 코드가 읽던 대표 multiplier."""

        return self.target.primary_multiplier

    def failure_rate(self, key: str) -> float:
        if self.run_count <= 0:
            return 0.0
        return self.failure_counts.get(key, 0) / self.run_count


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="추천 기본값으로 balance sim 후보를 자동 탐색합니다.",
    )
    parser.add_argument(
        "--mode",
        choices=["s3_boss", "early_package"],
        default=DEFAULT_OPTIONS["mode"],
        help="s3_boss는 기존 단일 탐색, early_package는 S1/S2/S3 보스 묶음 탐색입니다.",
    )
    parser.add_argument("--runs", type=int, default=DEFAULT_OPTIONS["runs"])
    parser.add_argument("--seed", type=int, default=DEFAULT_OPTIONS["seed"])
    parser.add_argument("--out-prefix", default=DEFAULT_OPTIONS["out_prefix"])
    parser.add_argument(
        "--experiment-id",
        default=None,
        help="고정 실험 id. early_package에서 생략하면 station_curve_125를 사용합니다.",
    )
    parser.add_argument("--loadout-id", default=DEFAULT_OPTIONS["loadout_id"])
    parser.add_argument("--market-profile", default=DEFAULT_OPTIONS["market_profile"])
    parser.add_argument(
        "--multipliers",
        default=",".join(str(v) for v in DEFAULT_OPTIONS["multipliers"]),
        help="S3 boss target multiplier 후보. 예: 0.95,0.9,0.85",
    )
    parser.add_argument(
        "--s1-multipliers",
        default=",".join(str(v) for v in DEFAULT_OPTIONS["s1_multipliers"]),
        help="early_package용 S1 boss multiplier 후보.",
    )
    parser.add_argument(
        "--s2-multipliers",
        default=",".join(str(v) for v in DEFAULT_OPTIONS["s2_multipliers"]),
        help="early_package용 S2 boss multiplier 후보.",
    )
    parser.add_argument(
        "--s3-multipliers",
        default=",".join(str(v) for v in DEFAULT_OPTIONS["s3_multipliers"]),
        help="early_package용 S3 boss multiplier 후보.",
    )
    parser.add_argument(
        "--packages",
        default="",
        help=(
            "early_package용 명시 후보. "
            "예: 0.70:0.75:0.775;0.70:0.80:0.80"
        ),
    )
    parser.add_argument(
        "--keep-jsonl",
        action="store_true",
        help="후보별 raw JSONL을 삭제하지 않습니다.",
    )
    args = parser.parse_args(argv)

    options = dict(DEFAULT_OPTIONS)
    options.update(
        {
            "mode": args.mode,
            "runs": args.runs,
            "seed": args.seed,
            "out_prefix": args.out_prefix,
            "loadout_id": args.loadout_id,
            "market_profile": args.market_profile,
            "multipliers": _parse_multipliers(args.multipliers),
            "s1_multipliers": _parse_multipliers(args.s1_multipliers),
            "s2_multipliers": _parse_multipliers(args.s2_multipliers),
            "s3_multipliers": _parse_multipliers(args.s3_multipliers),
            "packages": _parse_packages(args.packages),
            "keep_jsonl": args.keep_jsonl,
        },
    )
    if args.experiment_id is not None:
        options["experiment_id"] = args.experiment_id

    try:
        result = run_from_options(options)
    except AutoLevelingError as error:
        print(f"오류: {error}", file=sys.stderr)
        return 64
    except OSError as error:
        print(f"파일 오류: {error}", file=sys.stderr)
        return 1

    print(f"자동 탐색 리포트: {result['report_path']}")
    if result.get("chart_path"):
        print(f"차트: {result['chart_path']}")
    print(f"추천 후보: {result['best_candidate']}")
    return 0


def run_from_options(options: dict[str, Any]) -> dict[str, Any]:
    """노트북과 CLI가 같은 옵션 구조로 자동 탐색을 실행하는 진입점."""

    resolved = _resolve_options(options)
    out_prefix = Path(resolved["out_prefix"])
    out_prefix.parent.mkdir(parents=True, exist_ok=True)

    targets = _build_candidate_targets(resolved)
    results: list[CandidateResult] = []
    for target in targets:
        # 후보별 seed를 분리해서 같은 후보는 재현 가능하고 후보 간 run_id도 겹치지 않게 한다.
        candidate_seed = resolved["seed"] + _target_seed_offset(target)
        raw_path = out_prefix.with_name(
            f"{out_prefix.name}_{target.candidate_id}.jsonl",
        )
        _run_candidate(
            resolved=resolved,
            target=target,
            seed=candidate_seed,
            raw_path=raw_path,
        )
        results.append(_summarize_candidate(raw_path, target))
        if not resolved["keep_jsonl"]:
            raw_path.unlink(missing_ok=True)

    if not results:
        raise AutoLevelingError("분석할 후보 결과가 없습니다.")

    ordered = sorted(
        results,
        key=lambda result: result.recommendation_score,
        reverse=True,
    )
    report_path = out_prefix.with_name(f"{out_prefix.name}_report.md")
    chart_path = out_prefix.with_name(f"{out_prefix.name}_score_chart.png")
    _write_report(report_path, ordered, resolved)
    _write_chart(chart_path, ordered)

    return {
        "report_path": str(report_path),
        "chart_path": str(chart_path),
        "best_multiplier": ordered[0].multiplier,
        "best_candidate": ordered[0].target.candidate_id,
        "results": ordered,
    }


def _resolve_options(options: dict[str, Any]) -> dict[str, Any]:
    """옵션을 실행 가능한 타입으로 정규화한다."""

    resolved = dict(DEFAULT_OPTIONS)
    resolved.update(options)
    runs = int(resolved["runs"])
    if runs <= 0:
        raise AutoLevelingError("runs는 1 이상이어야 합니다.")
    mode = str(resolved["mode"])
    if mode not in {"s3_boss", "early_package"}:
        raise AutoLevelingError("mode는 s3_boss 또는 early_package여야 합니다.")
    multipliers = [float(value) for value in resolved["multipliers"]]
    if not multipliers or any(value <= 0 for value in multipliers):
        raise AutoLevelingError("multipliers는 양수 목록이어야 합니다.")
    s1_multipliers = [float(value) for value in resolved["s1_multipliers"]]
    s2_multipliers = [float(value) for value in resolved["s2_multipliers"]]
    s3_multipliers = [float(value) for value in resolved["s3_multipliers"]]
    packages = [tuple(float(value) for value in package) for package in resolved["packages"]]
    package_values = [*s1_multipliers, *s2_multipliers, *s3_multipliers]
    for package in packages:
        package_values.extend(package)
    if not package_values or any(value <= 0 for value in package_values):
        raise AutoLevelingError("package multipliers는 양수 목록이어야 합니다.")
    if (
        mode == "early_package"
        and resolved["experiment_id"] == DEFAULT_OPTIONS["experiment_id"]
    ):
        # S1 전용 safety experiment 위에 S1 override를 또 곱하면 목표가 이중 보정된다.
        resolved["experiment_id"] = resolved["package_experiment_id"]
    resolved["runs"] = runs
    resolved["seed"] = int(resolved["seed"])
    resolved["mode"] = mode
    resolved["multipliers"] = multipliers
    resolved["s1_multipliers"] = s1_multipliers
    resolved["s2_multipliers"] = s2_multipliers
    resolved["s3_multipliers"] = s3_multipliers
    resolved["packages"] = packages
    return resolved


def _build_candidate_targets(resolved: dict[str, Any]) -> list[CandidateTarget]:
    """탐색 모드에 맞춰 후보 target multiplier 묶음을 만든다."""

    if resolved["mode"] == "s3_boss":
        return [
            CandidateTarget(
                candidate_id=f"m{_multiplier_slug(multiplier)}",
                multipliers={
                    f"S{resolved['target_station']} {resolved['target_tier']}": multiplier,
                },
            )
            for multiplier in resolved["multipliers"]
        ]

    package_values = resolved["packages"] or itertools.product(
        resolved["s1_multipliers"],
        resolved["s2_multipliers"],
        resolved["s3_multipliers"],
    )
    targets: list[CandidateTarget] = []
    for s1, s2, s3 in package_values:
        targets.append(
            CandidateTarget(
                candidate_id=(
                    f"s1_{_multiplier_slug(s1)}_"
                    f"s2_{_multiplier_slug(s2)}_"
                    f"s3_{_multiplier_slug(s3)}"
                ),
                multipliers={
                    "S1 boss": s1,
                    "S2 boss": s2,
                    "S3 boss": s3,
                },
            ),
        )
    return targets


def _run_candidate(
    *,
    resolved: dict[str, Any],
    target: CandidateTarget,
    seed: int,
    raw_path: Path,
) -> None:
    """Dart 시뮬레이터를 후보 target multiplier 묶음 하나에 대해 실행한다."""

    cmd = [
        "dart",
        "run",
        "tools/sim/run_balance_sim.dart",
        "--runs",
        str(resolved["runs"]),
        "--bot",
        resolved["bot"],
        "--seed",
        str(seed),
        "--sequence-mode",
        "station_path",
        "--stations",
        resolved["stations"],
        "--difficulty",
        resolved["difficulty"],
        "--experiment-id",
        resolved["experiment_id"],
        "--market-profile",
        resolved["market_profile"],
        "--loadout-id",
        resolved["loadout_id"],
        "--out",
        str(raw_path),
    ]
    for target_override in target.override_args:
        cmd.extend(["--target-multiplier", target_override])
    completed = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if completed.returncode != 0:
        raise AutoLevelingError(
            "후보 실행 실패 "
            f"candidate={target.candidate_id}: {completed.stderr.strip()}",
        )


def _summarize_candidate(raw_path: Path, target: CandidateTarget) -> CandidateResult:
    """JSONL의 sequence_summary만 읽어 후보 점수 계산에 필요한 값을 만든다."""

    sequence_rows: list[dict[str, Any]] = []
    for line in raw_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if row.get("row_type") == "sequence_summary":
            sequence_rows.append(row)
    if not sequence_rows:
        raise AutoLevelingError(f"{raw_path}에 sequence_summary가 없습니다.")

    run_count = len(sequence_rows)
    path_clear_count = sum(1 for row in sequence_rows if row["path_cleared"])
    failure_counts: Counter[str] = Counter()
    s3_boss_states: list[dict[str, Any]] = []
    for row in sequence_rows:
        if not row["path_cleared"]:
            key = f"S{row.get('failed_at_station')} {row.get('failed_at_tier')}"
            failure_counts[key] += 1
        state = row.get("failed_step_resource_state")
        if (
            isinstance(state, dict)
            and state.get("station") == 3
            and state.get("blind_tier") == "boss"
        ):
            s3_boss_states.append(state)

    def avg(states: list[dict[str, Any]], key: str) -> float:
        if not states:
            return 0.0
        return sum(float(state.get(key) or 0) for state in states) / len(states)

    return CandidateResult(
        target=target,
        run_count=run_count,
        path_clear_rate=path_clear_count / run_count,
        avg_cleared_steps=sum(
            float(row["cleared_step_count"]) for row in sequence_rows
        )
        / run_count,
        avg_total_turn_count=sum(
            float(row["total_turn_count"]) for row in sequence_rows
        )
        / run_count,
        s3_boss_fail_rate=len(s3_boss_states) / run_count,
        s3_boss_avg_score_ratio=avg(s3_boss_states, "score_ratio"),
        s3_boss_avg_remaining_deck=avg(s3_boss_states, "remaining_deck"),
        s3_boss_avg_max_hit=avg(s3_boss_states, "max_single_confirm_score"),
        failure_counts=dict(failure_counts.most_common()),
    )


def _target_seed_offset(target: CandidateTarget) -> int:
    """후보 조합이 달라지면 seed offset도 안정적으로 달라지게 만든다."""

    return sum(
        (index + 1) * int(round(value * 1000))
        for index, value in enumerate(target.multipliers.values())
    )


def _write_report(
    report_path: Path,
    results: list[CandidateResult],
    resolved: dict[str, Any],
) -> None:
    """후보 순위와 해석을 한글 Markdown으로 저장한다."""

    best = results[0]
    is_package = resolved["mode"] == "early_package"
    target_label = (
        "S1/S2/S3 boss target multiplier package"
        if is_package
        else f"S{resolved['target_station']} {resolved['target_tier']} target multiplier"
    )
    lines = [
        "# 자동 레벨링 탐색 리포트",
        "",
        f"- 탐색 모드: `{resolved['mode']}`",
        f"- runs per candidate: `{resolved['runs']}`",
        f"- 고정 실험: `{resolved['experiment_id']}`",
        f"- 고정 loadout: `{resolved['loadout_id']}`",
        f"- 고정 market profile: `{resolved['market_profile']}`",
        f"- 탐색 대상: `{target_label}`",
        f"- 현재 기준 추천값: `{resolved['current_recommended_multiplier']}`",
        "",
        "## 추천",
        "",
        f"- 추천 후보: **{best.target.candidate_id}**",
        f"- 추천 multiplier 묶음: `{_format_target_multipliers(best.target)}`",
        f"- 추천 점수: `{best.recommendation_score:.3f}`",
        f"- path clear: `{best.path_clear_rate:.1%}`",
        f"- 평균 진행 step: `{best.avg_cleared_steps:.2f}/9`",
        f"- S1 boss 실패율: `{best.failure_rate('S1 boss'):.1%}`",
        f"- S2 boss 실패율: `{best.failure_rate('S2 boss'):.1%}`",
        f"- S3 boss 실패율: `{best.s3_boss_fail_rate:.1%}`",
        f"- S3 boss 실패 평균 score ratio: `{best.s3_boss_avg_score_ratio:.2f}`",
        "",
        "## 후보 순위",
        "",
        "| 순위 | 후보 | multiplier 묶음 | score | path clear | avg steps | S1 boss fail | S2 boss fail | S3 boss fail | S3 score ratio | S3 rem deck | 주요 실패 |",
        "|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for index, result in enumerate(results, start=1):
        main_fail = ", ".join(
            f"{key}:{value}" for key, value in list(result.failure_counts.items())[:3]
        )
        lines.append(
            "| "
            f"{index} | {result.target.candidate_id} | "
            f"{_format_target_multipliers(result.target)} | "
            f"{result.recommendation_score:.3f} | "
            f"{result.path_clear_rate:.1%} | "
            f"{result.avg_cleared_steps:.2f} | "
            f"{result.failure_rate('S1 boss'):.1%} | "
            f"{result.failure_rate('S2 boss'):.1%} | "
            f"{result.s3_boss_fail_rate:.1%} | "
            f"{result.s3_boss_avg_score_ratio:.2f} | "
            f"{result.s3_boss_avg_remaining_deck:.1f} | "
            f"{main_fail} |"
        )
    lines.extend(
        [
            "",
            "## 해석 기준",
            "",
            "- path clear가 너무 낮으면 아직 막힌 벽입니다.",
            "- path clear가 너무 높으면 S3 boss가 빨리 풀려 마켓 선택 의미가 약해집니다.",
            "- S1/S2 boss 실패율이 높으면 여러 판을 이어 가는 마켓/돈 밸런스 검증까지 도달하지 못합니다.",
            "- S3 boss 실패 평균 score ratio가 0.8 이상이면 한두 번의 선택/운으로 돌파 가능한 벽에 가깝습니다.",
            "- remaining deck이 0에 가까우면 전투가 끝까지 늘어지는 압박입니다.",
        ],
    )
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_chart(chart_path: Path, results: list[CandidateResult]) -> None:
    """matplotlib 한글 폰트 깨짐을 막고 후보 점수 차트를 저장한다."""

    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        from matplotlib import font_manager
    except ImportError:
        return

    # macOS/Windows/Linux에서 가능한 한글 폰트를 우선 지정한다.
    font_candidates = [
        "AppleGothic",
        "NanumGothic",
        "Malgun Gothic",
        "Noto Sans CJK KR",
    ]
    installed = {font.name for font in font_manager.fontManager.ttflist}
    for font_name in font_candidates:
        if font_name in installed:
            plt.rcParams["font.family"] = font_name
            break
    plt.rcParams["axes.unicode_minus"] = False

    if len(results) > 12:
        ordered = sorted(
            results,
            key=lambda result: result.recommendation_score,
            reverse=True,
        )[:12]
        ordered = list(reversed(ordered))
    else:
        ordered = sorted(results, key=lambda result: result.multiplier)
    labels = [result.target.candidate_id for result in ordered]
    scores = [result.recommendation_score for result in ordered]
    clears = [result.path_clear_rate for result in ordered]

    fig, ax1 = plt.subplots(figsize=(11, 6))
    ax1.barh(labels, scores, color="#4C78A8", label="추천 점수")
    ax1.set_xlim(0, 1)
    ax1.set_xlabel("추천 점수")
    ax1.set_ylabel("후보")
    ax1.set_title("자동 레벨링 후보 비교")

    ax2 = ax1.twiny()
    ax2.plot(clears, labels, color="#F58518", marker="o", label="path clear")
    ax2.set_xlim(0, max(0.35, max(clears) + 0.05))
    ax2.set_xlabel("path clear")

    fig.tight_layout()
    fig.savefig(chart_path, dpi=160)
    plt.close(fig)


def _format_target_multipliers(target: CandidateTarget) -> str:
    return ", ".join(
        f"{key}={value:.3f}".rstrip("0").rstrip(".")
        for key, value in target.multipliers.items()
    )


def _parse_multipliers(raw: str) -> list[float]:
    values = [part.strip() for part in raw.split(",") if part.strip()]
    if not values:
        raise AutoLevelingError("multipliers가 비어 있습니다.")
    try:
        return [float(value) for value in values]
    except ValueError as error:
        raise AutoLevelingError("multipliers는 숫자 목록이어야 합니다.") from error


def _parse_packages(raw: str) -> list[tuple[float, float, float]]:
    """S1:S2:S3 형식의 명시 패키지 후보를 파싱한다."""

    if not raw.strip():
        return []
    packages: list[tuple[float, float, float]] = []
    for chunk in raw.split(";"):
        value = chunk.strip()
        if not value:
            continue
        parts = [part.strip() for part in value.split(":")]
        if len(parts) != 3:
            raise AutoLevelingError("packages는 S1:S2:S3 형식이어야 합니다.")
        try:
            s1, s2, s3 = (float(part) for part in parts)
        except ValueError as error:
            raise AutoLevelingError("packages는 숫자 목록이어야 합니다.") from error
        packages.append((s1, s2, s3))
    if not packages:
        raise AutoLevelingError("packages가 비어 있습니다.")
    return packages


def _multiplier_slug(value: float) -> str:
    label = f"{value:.3f}".rstrip("0").rstrip(".")
    return label.replace(".", "p")


if __name__ == "__main__":
    raise SystemExit(main())
