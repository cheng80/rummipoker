#!/usr/bin/env python3
"""필요할 때 ignored feature table을 metadata 기준으로 재생성한다."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def ensure_feature_table(
    feature_path: Path,
    *,
    feature_mode: str,
    max_rows: int = 0,
) -> None:
    if feature_path.exists():
        return

    metadata_path = feature_metadata_path(feature_path)
    if not metadata_path.exists():
        raise SystemExit(
            "feature table이 없고 재생성 metadata도 없습니다: "
            f"{feature_path}\n"
            f"metadata expected: {metadata_path}"
        )

    metadata = read_metadata(metadata_path)
    source_paths = metadata.get("source_paths")
    if not isinstance(source_paths, list) or not source_paths:
        raise SystemExit(f"metadata에 source_paths가 없습니다: {metadata_path}")

    missing = [str(path) for path in source_paths if not Path(str(path)).exists()]
    if missing:
        preview = "\n".join(f"- {path}" for path in missing[:12])
        rest = "" if len(missing) <= 12 else f"\n... 외 {len(missing) - 12}개"
        raise SystemExit(
            "feature table 자동 재생성에 필요한 summary JSON이 로컬에 없습니다.\n"
            f"feature table: {feature_path}\n"
            f"metadata: {metadata_path}\n"
            "누락된 source 예시:\n"
            f"{preview}{rest}\n"
            "다른 PC에서는 먼저 summary 로그를 외부 저장소에서 복원하거나, "
            "해당 시뮬레이션을 다시 실행해야 합니다."
        )

    metadata_max_rows = metadata.get("max_rows")
    build_max_rows = (
        metadata_max_rows
        if isinstance(metadata_max_rows, int) and metadata_max_rows > 0
        else max_rows
    )

    feature_path.parent.mkdir(parents=True, exist_ok=True)
    command = [
        sys.executable,
        str(Path("tools/leveling/build_feature_table.py")),
        *[str(path) for path in source_paths],
        "--feature-mode",
        feature_mode,
        "--out",
        str(feature_path),
        "--metadata-out",
        str(metadata_path),
    ]
    if build_max_rows > 0:
        command.extend(["--max-rows", str(build_max_rows)])

    subprocess.run(command, check=True)


def feature_metadata_path(feature_path: Path) -> Path:
    parts = feature_path.parts
    generated_marker = ("analysis", "leveling", "generated", "features")
    if parts[: len(generated_marker)] == generated_marker:
        return (
            Path(".omo/legacy_leveling/data/features")
            / feature_path.with_suffix(".metadata.json").name
        )
    return feature_path.with_suffix(".metadata.json")


def read_metadata(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"metadata JSON을 읽을 수 없습니다: {path}: {error}") from error
    if not isinstance(value, dict):
        raise SystemExit(f"metadata JSON 루트가 object가 아닙니다: {path}")
    return value
