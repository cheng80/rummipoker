#!/usr/bin/env python3
"""Extract full-run bot JSONL trace rows from a flutter drive log."""

from __future__ import annotations

import argparse
import base64
import json
import re
import sys
from pathlib import Path


CHUNK_RE = re.compile(
    r"FULL_RUN_BOT_TRACE_CHUNK:(?P<seq>\d+):(?P<part>\d+):"
    r"(?P<total>\d+):(?P<data>[A-Za-z0-9+/=]+)"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("log_path", type=Path)
    parser.add_argument("--out", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.log_path.exists():
        print(f"trace log not found: {args.log_path}", file=sys.stderr)
        return 1

    chunks: dict[int, dict[int, str]] = {}
    totals: dict[int, int] = {}
    for line in args.log_path.read_text(errors="ignore").splitlines():
        match = CHUNK_RE.search(line)
        if match is None:
            continue
        seq = int(match.group("seq"))
        part = int(match.group("part"))
        total = int(match.group("total"))
        chunks.setdefault(seq, {})[part] = match.group("data")
        totals[seq] = total

    if not chunks:
        print(f"no full-run trace chunks found in {args.log_path}")
        return 0

    rows: list[dict[str, object]] = []
    missing: list[str] = []
    for seq in sorted(chunks):
        total = totals[seq]
        parts = chunks[seq]
        if len(parts) != total:
            missing_parts = [str(i) for i in range(total) if i not in parts]
            missing.append(f"{seq}: {','.join(missing_parts)}")
            continue
        encoded = "".join(parts[index] for index in range(total))
        decoded = base64.b64decode(encoded).decode("utf-8")
        rows.append(json.loads(decoded))

    if missing:
        print(
            "missing full-run trace chunks: " + "; ".join(missing),
            file=sys.stderr,
        )
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as sink:
        for row in rows:
            sink.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")))
            sink.write("\n")

    print(f"wrote full-run trace: {args.out} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
