#!/usr/bin/env python3
"""ML 레벨링 학습용 sweep dataset을 생성한다."""

from __future__ import annotations

import argparse
import itertools
import json
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_OPTIONS: dict[str, Any] = {
    "mode": "progression_curve",
    "runs": 100,
    "seed": 12000,
    "bot": "planner_v2",
    "stations": "1,2,3,4,5,6,7,8",
    "difficulty": "standard",
    "station_growth_experiments": ["station_curve_125", "station_curve_135"],
    "experiment_id": "station_curve_125",
    "loadout_ids": [
        "baseline",
        "s1_entry_bridge_build",
        "s2_foundation_build",
        "s3_hand_growth_build",
        "s4_resource_build",
        "s5_power_build",
        "s8_finale_build",
    ],
    "market_profiles": ["none", "s1_buy_sly"],
    "small_multipliers": [0.95, 1.0],
    "big_multipliers": [0.90, 1.0],
    "boss_multipliers": [0.75, 0.85, 1.0],
    "s1_multipliers": [0.75, 0.70],
    "s2_multipliers": [0.85, 0.80, 0.75],
    "s3_multipliers": [0.80, 0.775, 0.75],
    "packages": [],
    "out_prefix": "logs/sim/ml_sweep_dataset",
    "keep_candidate_files": False,
}


class MlSweepError(Exception):
    """사용자가 읽을 수 있는 sweep 생성 오류."""


@dataclass(frozen=True)
class SweepCandidate:
    """하나의 target multiplier sweep 후보."""

    candidate_id: str
    mode: str
    experiment_id_base: str
    target_multipliers: dict[str, float]
    metadata_values: dict[str, float | str]

    @property
    def experiment_id(self) -> str:
        return f"sweep_{self.candidate_id}"

    @property
    def target_multiplier_args(self) -> list[str]:
        return [
            f"{key.replace(' ', ':')}:{value}"
            for key, value in self.target_multipliers.items()
        ]

    @property
    def metadata(self) -> dict[str, float | str]:
        return {
            "sweep_mode": self.mode,
            "candidate_id": self.candidate_id,
            "base_experiment_id": self.experiment_id_base,
            **self.metadata_values,
        }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="추천 기본값으로 ML 레벨링용 sweep dataset을 생성합니다.",
    )
    parser.add_argument(
        "--mode",
        choices=["progression_curve", "boss_package"],
        default=DEFAULT_OPTIONS["mode"],
        help="progression_curve는 전체 station/tier/loadout 기준, boss_package는 기존 보스 병목 탐색입니다.",
    )
    parser.add_argument("--runs", type=int, default=DEFAULT_OPTIONS["runs"])
    parser.add_argument("--seed", type=int, default=DEFAULT_OPTIONS["seed"])
    parser.add_argument("--bot", default=DEFAULT_OPTIONS["bot"])
    parser.add_argument("--stations", default=DEFAULT_OPTIONS["stations"])
    parser.add_argument("--difficulty", default=DEFAULT_OPTIONS["difficulty"])
    parser.add_argument("--experiment-id", default=DEFAULT_OPTIONS["experiment_id"])
    parser.add_argument(
        "--station-growth-experiments",
        default=_join(DEFAULT_OPTIONS["station_growth_experiments"]),
        help="progression_curve용 station curve 후보. 예: station_curve_125,station_curve_135",
    )
    parser.add_argument(
        "--loadout-ids",
        default=_join(DEFAULT_OPTIONS["loadout_ids"]),
        help="쉼표로 구분한 loadout preset 목록.",
    )
    parser.add_argument(
        "--market-profiles",
        default=_join(DEFAULT_OPTIONS["market_profiles"]),
        help="쉼표로 구분한 market profile 목록.",
    )
    parser.add_argument(
        "--small-multipliers",
        default=_join(DEFAULT_OPTIONS["small_multipliers"]),
        help="progression_curve용 small target multiplier 후보.",
    )
    parser.add_argument(
        "--big-multipliers",
        default=_join(DEFAULT_OPTIONS["big_multipliers"]),
        help="progression_curve용 big target multiplier 후보.",
    )
    parser.add_argument(
        "--boss-multipliers",
        default=_join(DEFAULT_OPTIONS["boss_multipliers"]),
        help="progression_curve용 boss target multiplier 후보.",
    )
    parser.add_argument(
        "--s1-multipliers",
        default=_join(DEFAULT_OPTIONS["s1_multipliers"]),
        help="boss_package용 S1 boss target multiplier 후보.",
    )
    parser.add_argument(
        "--s2-multipliers",
        default=_join(DEFAULT_OPTIONS["s2_multipliers"]),
        help="boss_package용 S2 boss target multiplier 후보.",
    )
    parser.add_argument(
        "--s3-multipliers",
        default=_join(DEFAULT_OPTIONS["s3_multipliers"]),
        help="boss_package용 S3 boss target multiplier 후보.",
    )
    parser.add_argument(
        "--packages",
        default="",
        help="boss_package 명시 후보. 예: 0.75:0.80:0.80;0.70:0.75:0.775",
    )
    parser.add_argument("--out-prefix", default=DEFAULT_OPTIONS["out_prefix"])
    parser.add_argument(
        "--keep-candidate-files",
        action="store_true",
        help="후보별 JSONL/summary 파일을 삭제하지 않습니다.",
    )
    args = parser.parse_args(argv)

    options = dict(DEFAULT_OPTIONS)
    options.update(
        {
            "mode": args.mode,
            "runs": args.runs,
            "seed": args.seed,
            "bot": args.bot,
            "stations": args.stations,
            "difficulty": args.difficulty,
            "experiment_id": args.experiment_id,
            "station_growth_experiments": _parse_strings(
                args.station_growth_experiments,
                "station_growth_experiments",
            ),
            "loadout_ids": _parse_strings(args.loadout_ids, "loadout_ids"),
            "market_profiles": _parse_strings(
                args.market_profiles,
                "market_profiles",
            ),
            "small_multipliers": _parse_multipliers(args.small_multipliers),
            "big_multipliers": _parse_multipliers(args.big_multipliers),
            "boss_multipliers": _parse_multipliers(args.boss_multipliers),
            "s1_multipliers": _parse_multipliers(args.s1_multipliers),
            "s2_multipliers": _parse_multipliers(args.s2_multipliers),
            "s3_multipliers": _parse_multipliers(args.s3_multipliers),
            "packages": _parse_packages(args.packages),
            "out_prefix": args.out_prefix,
            "keep_candidate_files": args.keep_candidate_files,
        },
    )

    try:
        result = run_from_options(options)
    except MlSweepError as error:
        print(f"오류: {error}", file=sys.stderr)
        return 64
    except OSError as error:
        print(f"파일 오류: {error}", file=sys.stderr)
        return 1

    print(f"Sweep JSONL: {result['jsonl_path']}")
    print(f"Sweep summary: {result['summary_path']}")
    print(f"Sweep report: {result['report_path']}")
    print(f"후보 수: {result['candidate_count']}")
    print(f"group 수: {result['group_count']}")
    return 0


def run_from_options(options: dict[str, Any]) -> dict[str, Any]:
    """노트북과 CLI가 같은 옵션 구조로 sweep dataset을 생성하는 진입점."""

    resolved = _resolve_options(options)
    out_prefix = Path(resolved["out_prefix"])
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    combined_jsonl_path = out_prefix.with_suffix(".jsonl")
    combined_summary_path = out_prefix.with_name(f"{out_prefix.name}_summary.json")
    report_path = out_prefix.with_name(f"{out_prefix.name}_report.md")

    candidates = _build_candidates(resolved)
    combined_lines: list[str] = []
    combined_groups: list[dict[str, Any]] = []
    total_run_count = 0
    candidate_summaries: list[dict[str, Any]] = []
    sweep_started_at = time.monotonic()

    print(
        f"[sweep] mode={resolved['mode']} candidates={len(candidates)} "
        f"runs={resolved['runs']} out_prefix={out_prefix}",
        flush=True,
    )

    for index, candidate in enumerate(candidates):
        candidate_started_at = time.monotonic()
        candidate_seed = int(resolved["seed"]) + _candidate_seed_offset(candidate)
        raw_path = out_prefix.with_name(
            f"{out_prefix.name}_{candidate.candidate_id}.jsonl",
        )
        summary_path = out_prefix.with_name(
            f"{out_prefix.name}_{candidate.candidate_id}_summary.json",
        )
        print(
            f"[sweep] start {index + 1}/{len(candidates)} "
            f"{candidate.candidate_id} seed={candidate_seed}",
            flush=True,
        )
        _run_candidate(
            resolved=resolved,
            candidate=candidate,
            seed=candidate_seed,
            raw_path=raw_path,
            summary_path=summary_path,
        )
        candidate_summary = _read_summary(summary_path)
        candidate_summaries.append(candidate_summary)
        total_run_count += int(candidate_summary.get("run_count", 0))
        combined_lines.extend(_candidate_jsonl_lines(raw_path, candidate, index))
        combined_groups.extend(_candidate_groups(candidate_summary, candidate))
        print(
            f"[sweep] done {index + 1}/{len(candidates)} "
            f"{candidate.candidate_id} groups={len(candidate_summary.get('groups', []))} "
            f"elapsed={_duration(time.monotonic() - candidate_started_at)}",
            flush=True,
        )
        if not resolved["keep_candidate_files"]:
            raw_path.unlink(missing_ok=True)
            summary_path.unlink(missing_ok=True)

    combined_jsonl_path.write_text("\n".join(combined_lines) + "\n", encoding="utf-8")
    combined_summary = {
        "schema_version": 1,
        "source_path": str(combined_jsonl_path),
        "run_count": total_run_count,
        "group_by": [
            "experiment_id",
            "loadout_id",
            "station",
            "blind_tier",
            "difficulty",
        ],
        "sweep": {
            "kind": resolved["mode"],
            "candidate_count": len(candidates),
            "runs_per_candidate": resolved["runs"],
            "bot": resolved["bot"],
            "stations": resolved["stations"],
            "difficulty": resolved["difficulty"],
            "loadout_ids": resolved["loadout_ids"],
            "market_profiles": resolved["market_profiles"],
        },
        "groups": combined_groups,
    }
    combined_summary_path.write_text(
        json.dumps(combined_summary, ensure_ascii=False),
        encoding="utf-8",
    )
    report_path.write_text(
        _render_report(
            resolved=resolved,
            candidates=candidates,
            candidate_summaries=candidate_summaries,
            combined_summary_path=combined_summary_path,
        ),
        encoding="utf-8",
    )
    print(
        f"[sweep] merged candidates={len(candidates)} groups={len(combined_groups)} "
        f"elapsed={_duration(time.monotonic() - sweep_started_at)}",
        flush=True,
    )
    return {
        "jsonl_path": str(combined_jsonl_path),
        "summary_path": str(combined_summary_path),
        "report_path": str(report_path),
        "candidate_count": len(candidates),
        "group_count": len(combined_groups),
    }


def _resolve_options(options: dict[str, Any]) -> dict[str, Any]:
    resolved = dict(DEFAULT_OPTIONS)
    resolved.update(options)
    mode = str(resolved["mode"])
    if mode not in {"progression_curve", "boss_package"}:
        raise MlSweepError("mode는 progression_curve 또는 boss_package여야 합니다.")
    runs = int(resolved["runs"])
    if runs <= 0:
        raise MlSweepError("runs는 1 이상이어야 합니다.")
    for key in [
        "small_multipliers",
        "big_multipliers",
        "boss_multipliers",
        "s1_multipliers",
        "s2_multipliers",
        "s3_multipliers",
    ]:
        values = [float(value) for value in resolved[key]]
        if not values or any(value <= 0 for value in values):
            raise MlSweepError(f"{key}는 양수 목록이어야 합니다.")
        resolved[key] = values
    for key in ["station_growth_experiments", "loadout_ids", "market_profiles"]:
        values = [str(value) for value in resolved[key] if str(value)]
        if not values:
            raise MlSweepError(f"{key}는 1개 이상이어야 합니다.")
        resolved[key] = values
    resolved["packages"] = [
        tuple(float(value) for value in package)
        for package in resolved.get("packages", [])
    ]
    for package in resolved["packages"]:
        if len(package) != 3 or any(value <= 0 for value in package):
            raise MlSweepError("packages는 양수 3개 묶음이어야 합니다.")
    resolved["mode"] = mode
    resolved["runs"] = runs
    resolved["seed"] = int(resolved["seed"])
    return resolved


def _build_candidates(resolved: dict[str, Any]) -> list[SweepCandidate]:
    if resolved["mode"] == "boss_package":
        return _build_boss_package_candidates(resolved)
    return _build_progression_curve_candidates(resolved)


def _build_progression_curve_candidates(resolved: dict[str, Any]) -> list[SweepCandidate]:
    candidates: list[SweepCandidate] = []
    stations = _parse_station_values(str(resolved["stations"]))
    for experiment_id, small, big, boss in itertools.product(
        resolved["station_growth_experiments"],
        resolved["small_multipliers"],
        resolved["big_multipliers"],
        resolved["boss_multipliers"],
    ):
        candidate_id = (
            f"{experiment_id}_small_{_multiplier_slug(small)}_"
            f"big_{_multiplier_slug(big)}_boss_{_multiplier_slug(boss)}"
        )
        target_multipliers = {
            f"S{station} small": small
            for station in stations
        }
        target_multipliers.update({f"S{station} big": big for station in stations})
        target_multipliers.update({f"S{station} boss": boss for station in stations})
        candidates.append(
            SweepCandidate(
                candidate_id=candidate_id,
                mode="progression_curve",
                experiment_id_base=experiment_id,
                target_multipliers=target_multipliers,
                metadata_values={
                    "station_growth_experiment_id": experiment_id,
                    "small_target_multiplier": small,
                    "big_target_multiplier": big,
                    "boss_target_multiplier": boss,
                },
            ),
        )
    return _require_candidates(candidates)


def _build_boss_package_candidates(resolved: dict[str, Any]) -> list[SweepCandidate]:
    package_values = resolved["packages"] or itertools.product(
        resolved["s1_multipliers"],
        resolved["s2_multipliers"],
        resolved["s3_multipliers"],
    )
    candidates = [
        SweepCandidate(
            candidate_id=(
                f"s1_{_multiplier_slug(s1)}_"
                f"s2_{_multiplier_slug(s2)}_"
                f"s3_{_multiplier_slug(s3)}"
            ),
            mode="boss_package",
            experiment_id_base=str(resolved["experiment_id"]),
            target_multipliers={
                "S1 boss": s1,
                "S2 boss": s2,
                "S3 boss": s3,
            },
            metadata_values={
                "s1_boss_target_multiplier": s1,
                "s2_boss_target_multiplier": s2,
                "s3_boss_target_multiplier": s3,
            },
        )
        for s1, s2, s3 in package_values
    ]
    return _require_candidates(candidates)


def _require_candidates(candidates: list[SweepCandidate]) -> list[SweepCandidate]:
    if not candidates:
        raise MlSweepError("생성할 후보가 없습니다.")
    return candidates


def _run_candidate(
    *,
    resolved: dict[str, Any],
    candidate: SweepCandidate,
    seed: int,
    raw_path: Path,
    summary_path: Path,
) -> None:
    """Dart 시뮬레이터를 후보 하나에 대해 실행한다."""

    cmd = [
        "dart",
        "run",
        "tools/sim/run_balance_sim.dart",
        "--runs",
        str(resolved["runs"]),
        "--bot",
        str(resolved["bot"]),
        "--seed",
        str(seed),
        "--sequence-mode",
        "station_path",
        "--stations",
        str(resolved["stations"]),
        "--difficulty",
        str(resolved["difficulty"]),
        "--experiment-id",
        candidate.experiment_id_base,
        "--summary-out",
        str(summary_path),
        "--out",
        str(raw_path),
    ]
    for market_profile in resolved["market_profiles"]:
        cmd.extend(["--market-profile", str(market_profile)])
    for loadout_id in resolved["loadout_ids"]:
        cmd.extend(["--loadout-id", str(loadout_id)])
    for target_multiplier in candidate.target_multiplier_args:
        cmd.extend(["--target-multiplier", target_multiplier])
    completed = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if completed.returncode != 0:
        raise MlSweepError(
            f"후보 실행 실패 candidate={candidate.candidate_id}: "
            f"{completed.stderr.strip()}",
        )


def _read_summary(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise MlSweepError(f"후보 summary 파일이 없습니다: {path}")
    decoded = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise MlSweepError(f"후보 summary 최상위 값은 object여야 합니다: {path}")
    return decoded


def _candidate_jsonl_lines(
    raw_path: Path,
    candidate: SweepCandidate,
    candidate_index: int,
) -> list[str]:
    lines: list[str] = []
    for line in raw_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if isinstance(row, dict):
            row["experiment_id"] = candidate.experiment_id
            row["sweep_candidate_id"] = candidate.candidate_id
            row["sweep_candidate_index"] = candidate_index
            row.update(candidate.metadata)
        lines.append(json.dumps(row, ensure_ascii=False))
    return lines


def _candidate_groups(
    summary: dict[str, Any],
    candidate: SweepCandidate,
) -> list[dict[str, Any]]:
    raw_groups = summary.get("groups")
    if not isinstance(raw_groups, list):
        raise MlSweepError("후보 summary에 groups list가 없습니다.")
    groups: list[dict[str, Any]] = []
    for raw_group in raw_groups:
        if not isinstance(raw_group, dict):
            continue
        group = dict(raw_group)
        group["experiment_id"] = candidate.experiment_id
        group["sweep_candidate_id"] = candidate.candidate_id
        group.update(candidate.metadata)
        groups.append(group)
    return groups


def _render_report(
    *,
    resolved: dict[str, Any],
    candidates: list[SweepCandidate],
    candidate_summaries: list[dict[str, Any]],
    combined_summary_path: Path,
) -> str:
    lines = [
        "# ML 레벨링 Sweep Dataset",
        "",
        f"- summary: `{combined_summary_path}`",
        f"- mode: `{resolved['mode']}`",
        f"- 후보 수: {len(candidates)}",
        f"- runs per candidate: {resolved['runs']}",
        f"- stations: `{resolved['stations']}`",
        f"- difficulty: `{resolved['difficulty']}`",
        f"- loadouts: `{', '.join(resolved['loadout_ids'])}`",
        f"- markets: `{', '.join(resolved['market_profiles'])}`",
        "",
        "## 기준값 활용",
        "",
        "- `progression_curve`는 `v4_pacing_baseline_1`에서 잡아 온 station curve, blind tier pressure, progression build 기준을 함께 흔듭니다.",
        "- `boss_package`는 기존 S1/S2/S3 boss 병목 탐색을 보존하는 좁은 모드입니다.",
        "- 생성된 metadata는 ML 워크벤치에서 숫자 피처로 사용됩니다.",
        "",
        "## 후보",
        "",
    ]
    for candidate, summary in zip(candidates, candidate_summaries, strict=True):
        lines.append(
            f"- `{candidate.experiment_id}`: "
            f"{_format_metadata(candidate.metadata_values)}, "
            f"groups {len(summary.get('groups', []))}"
        )
    lines.extend(
        [
            "",
            "## 다음 단계",
            "",
            (
                "- 생성된 summary를 `tools/sim/ml_leveling_report.py` 또는 "
                "`notebooks/sim_ml_leveling.ipynb`의 `summary_json`으로 넣어 "
                "상관 관계, 모델 검증, 우선 튜닝 후보를 확인하세요."
            ),
        ],
    )
    return "\n".join(lines) + "\n"


def _candidate_seed_offset(candidate: SweepCandidate) -> int:
    total = 0
    for index, value in enumerate(candidate.target_multipliers.values()):
        total += (index + 1) * int(round(value * 1000))
    for char in candidate.candidate_id:
        total = (total * 31 + ord(char)) % 1_000_003
    return total


def _parse_station_values(raw: str) -> list[int]:
    values = []
    for part in raw.split(","):
        stripped = part.strip()
        if not stripped:
            continue
        parsed = int(stripped)
        if parsed <= 0:
            raise MlSweepError("stations는 양수 목록이어야 합니다.")
        values.append(parsed)
    if not values:
        raise MlSweepError("stations는 1개 이상이어야 합니다.")
    return values


def _parse_multipliers(raw: str) -> list[float]:
    values = [part.strip() for part in raw.split(",") if part.strip()]
    if not values:
        raise MlSweepError("multiplier 목록이 비어 있습니다.")
    try:
        return [float(value) for value in values]
    except ValueError as error:
        raise MlSweepError("multiplier는 숫자 목록이어야 합니다.") from error


def _parse_packages(raw: str) -> list[tuple[float, float, float]]:
    if not raw.strip():
        return []
    packages: list[tuple[float, float, float]] = []
    for chunk in raw.split(";"):
        parts = [part.strip() for part in chunk.split(":") if part.strip()]
        if len(parts) != 3:
            raise MlSweepError(f"package는 s1:s2:s3 형식이어야 합니다: {chunk}")
        try:
            packages.append((float(parts[0]), float(parts[1]), float(parts[2])))
        except ValueError as error:
            raise MlSweepError(f"package multiplier는 숫자여야 합니다: {chunk}") from error
    return packages


def _parse_strings(raw: str, name: str) -> list[str]:
    values = [part.strip() for part in raw.split(",") if part.strip()]
    if not values:
        raise MlSweepError(f"{name}이 비어 있습니다.")
    return values


def _multiplier_slug(value: float) -> str:
    return str(value).replace(".", "p")


def _join(values: Any) -> str:
    return ",".join(str(value) for value in values)


def _format_metadata(metadata: dict[str, float | str]) -> str:
    return ", ".join(f"{key}={value}" for key, value in metadata.items())


def _duration(seconds: float) -> str:
    rounded = int(round(seconds))
    minutes, sec = divmod(rounded, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours}h{minutes:02d}m{sec:02d}s"
    if minutes:
        return f"{minutes}m{sec:02d}s"
    return f"{sec}s"


if __name__ == "__main__":
    raise SystemExit(main())
