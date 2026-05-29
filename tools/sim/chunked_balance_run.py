#!/usr/bin/env python3
"""Run balance simulation in resumable chunks and merge raw JSONL safely."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


class ChunkedRunError(Exception):
    """User-facing chunk runner error."""


def main() -> int:
    try:
      config, sim_args = _parse_args(sys.argv[1:])
      _run_chunks(config, sim_args)
      return 0
    except ChunkedRunError as error:
      print(str(error), file=sys.stderr)
      return 1


def _parse_args(argv: list[str]) -> tuple[argparse.Namespace, list[str]]:
    if "--" not in argv:
        raise ChunkedRunError(
            "sim args separator is required: use `-- ...run_balance_sim args...`",
        )
    separator = argv.index("--")
    own_args = argv[:separator]
    sim_args = argv[separator + 1 :]
    if not sim_args:
        raise ChunkedRunError("run_balance_sim args after `--` are required")

    parser = argparse.ArgumentParser(
        description="Run tools/sim/run_balance_sim.dart in chunked mode.",
    )
    parser.add_argument("--chunks", type=int, required=True)
    parser.add_argument("--runs-per-chunk", type=int, required=True)
    parser.add_argument("--seed", type=int, required=True)
    parser.add_argument("--seed-stride", type=int, default=100000)
    parser.add_argument("--out-prefix", type=Path, required=True)
    parser.add_argument("--dart", default="dart")
    parser.add_argument("--flush-every-rows", type=int, default=50)
    parser.add_argument("--resume", action="store_true")
    config = parser.parse_args(own_args)

    if config.chunks <= 0:
        raise ChunkedRunError("--chunks must be positive")
    if config.runs_per_chunk <= 0:
        raise ChunkedRunError("--runs-per-chunk must be positive")
    if config.flush_every_rows <= 0:
        raise ChunkedRunError("--flush-every-rows must be positive")
    forbidden = {"--runs", "--seed", "--out", "--summary-out", "--flush-every-rows"}
    overlap = sorted(set(sim_args).intersection(forbidden))
    if overlap:
        raise ChunkedRunError(
            "chunk runner owns these run_balance_sim args: " + ", ".join(overlap),
        )
    return config, sim_args


def _run_chunks(config: argparse.Namespace, sim_args: list[str]) -> None:
    prefix: Path = config.out_prefix
    prefix.parent.mkdir(parents=True, exist_ok=True)
    chunks_dir = prefix.parent / f"{prefix.name}_chunks"
    chunks_dir.mkdir(parents=True, exist_ok=True)

    merged_jsonl = prefix.with_suffix(".jsonl")
    merged_summary = prefix.parent / f"{prefix.name}_summary.json"
    manifest_path = prefix.parent / f"{prefix.name}_manifest.json"
    manifest = _read_manifest(manifest_path)
    completed = set(manifest.get("completed_chunks", []))
    started_at = time.monotonic()

    for chunk_index in range(config.chunks):
        chunk_id = f"{chunk_index:04d}"
        chunk_jsonl = chunks_dir / f"{prefix.name}_{chunk_id}.jsonl"
        chunk_summary = chunks_dir / f"{prefix.name}_{chunk_id}_summary.json"
        if config.resume and chunk_id in completed and chunk_jsonl.exists():
            print(f"[chunked] skip {chunk_id} existing={chunk_jsonl}", flush=True)
        else:
            seed = config.seed + chunk_index * config.seed_stride
            cmd = [
                config.dart,
                "run",
                "tools/sim/run_balance_sim.dart",
                "--runs",
                str(config.runs_per_chunk),
                "--seed",
                str(seed),
                "--out",
                str(chunk_jsonl),
                "--summary-out",
                str(chunk_summary),
                "--flush-every-rows",
                str(config.flush_every_rows),
                *sim_args,
            ]
            print(
                f"[chunked] start {chunk_index + 1}/{config.chunks} "
                f"seed={seed} out={chunk_jsonl}",
                flush=True,
            )
            subprocess.run(cmd, check=True)
            print(f"[chunked] done {chunk_index + 1}/{config.chunks}", flush=True)
            completed.add(chunk_id)
            manifest = _update_manifest(
                manifest_path=manifest_path,
                config=config,
                sim_args=sim_args,
                completed=completed,
                merged_jsonl=merged_jsonl,
                merged_summary=merged_summary,
                chunks_dir=chunks_dir,
                started_at=started_at,
            )

        _merge_chunks(
            chunks_dir=chunks_dir,
            prefix_name=prefix.name,
            completed=completed,
            merged_jsonl=merged_jsonl,
        )
        _summarize_merged(
            dart=config.dart,
            merged_jsonl=merged_jsonl,
            merged_summary=merged_summary,
        )

    _update_manifest(
        manifest_path=manifest_path,
        config=config,
        sim_args=sim_args,
        completed=completed,
        merged_jsonl=merged_jsonl,
        merged_summary=merged_summary,
        chunks_dir=chunks_dir,
        started_at=started_at,
        complete=True,
    )
    print(
        f"[chunked] complete chunks={len(completed)} "
        f"jsonl={merged_jsonl} summary={merged_summary}",
        flush=True,
    )


def _read_manifest(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def _update_manifest(
    *,
    manifest_path: Path,
    config: argparse.Namespace,
    sim_args: list[str],
    completed: set[str],
    merged_jsonl: Path,
    merged_summary: Path,
    chunks_dir: Path,
    started_at: float,
    complete: bool = False,
) -> dict[str, Any]:
    manifest = {
        "schema_version": 1,
        "complete": complete,
        "chunks": config.chunks,
        "runs_per_chunk": config.runs_per_chunk,
        "seed": config.seed,
        "seed_stride": config.seed_stride,
        "sim_args": sim_args,
        "completed_chunks": sorted(completed),
        "merged_jsonl": str(merged_jsonl),
        "merged_summary": str(merged_summary),
        "chunks_dir": str(chunks_dir),
        "elapsed_seconds": round(time.monotonic() - started_at, 3),
    }
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    return manifest


def _merge_chunks(
    *,
    chunks_dir: Path,
    prefix_name: str,
    completed: set[str],
    merged_jsonl: Path,
) -> None:
    with merged_jsonl.open("w") as merged:
        for chunk_id in sorted(completed):
            chunk_jsonl = chunks_dir / f"{prefix_name}_{chunk_id}.jsonl"
            if not chunk_jsonl.exists():
                raise ChunkedRunError(f"completed chunk is missing: {chunk_jsonl}")
            with chunk_jsonl.open() as chunk:
                for line in chunk:
                    if line.strip():
                        merged.write(line)


def _summarize_merged(*, dart: str, merged_jsonl: Path, merged_summary: Path) -> None:
    subprocess.run(
        [
            dart,
            "run",
            "tools/sim/summarize_balance_jsonl.dart",
            str(merged_jsonl),
            "--out",
            str(merged_summary),
        ],
        check=True,
    )


if __name__ == "__main__":
    raise SystemExit(main())
