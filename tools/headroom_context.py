#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


DEFAULT_MODEL = "claude-sonnet-4-5-20250929"
DEFAULT_MAX_CHARS = 160_000


@dataclass
class FileSummary:
    path: str
    sha256: str
    byte_count: int
    char_count: int
    line_count: int
    truncated: bool
    estimated_tokens_before: int
    estimated_tokens_after: int
    method: str
    headroom_retrieve_hashes: list[str]
    note: str


def estimate_tokens(text: str) -> int:
    try:
        import tiktoken  # type: ignore

        encoding = tiktoken.get_encoding("cl100k_base")
        return len(encoding.encode(text))
    except Exception:
        return max(1, len(text) // 4)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", value.strip()).strip("-")
    return slug[:72] or "context"


def read_text(path: Path, max_chars: int) -> tuple[str, bytes, bool]:
    data = path.read_bytes()
    text = data.decode("utf-8", errors="replace")
    truncated = len(text) > max_chars
    if truncated:
        text = text[:max_chars]
    return text, data, truncated


def fallback_compress(text: str) -> tuple[str, str]:
    lines = text.splitlines()
    interesting_patterns = [
        "error",
        "exception",
        "failed",
        "failure",
        "overflow",
        "warning",
        "traceback",
        "fatal",
        "assert",
        "diff",
        "changed",
    ]
    matches: list[str] = []
    for index, line in enumerate(lines, start=1):
        lower = line.lower()
        if any(pattern in lower for pattern in interesting_patterns):
            matches.append(f"{index}: {line}")
        if len(matches) >= 80:
            break

    head = lines[:80]
    tail = lines[-80:] if len(lines) > 160 else []
    parts = [
        "[deterministic fallback summary]",
        f"lines: {len(lines)}",
        "",
        "## Head",
        "\n".join(head) if head else "(empty)",
    ]
    if matches:
        parts.extend(["", "## Notable Matches", "\n".join(matches)])
    if tail:
        parts.extend(["", "## Tail", "\n".join(tail)])
    return "\n".join(parts), "headroom unavailable or disabled; used deterministic head/match/tail summary"


def headroom_compress(text: str, model: str, no_headroom: bool) -> tuple[str, str, str]:
    if no_headroom:
        compressed, note = fallback_compress(text)
        return compressed, "fallback", note

    try:
        from headroom.compress import compress  # type: ignore

        result = compress(
            [{"role": "tool", "content": text}],
            model=model,
        )
        content: Any = result.messages[0].get("content", text)
        if not isinstance(content, str):
            content = json.dumps(content, ensure_ascii=False, indent=2)
        return content, "headroom.compress", f"model={model}"
    except Exception as exc:
        compressed, note = fallback_compress(text)
        return compressed, "fallback", f"{note}; error={type(exc).__name__}: {exc}"


def extract_retrieve_hashes(text: str) -> list[str]:
    return sorted(set(re.findall(r"hash=([0-9a-fA-F]{12,})", text)))


def build_summary(
    paths: list[Path],
    label: str,
    model: str,
    max_chars: int,
    no_headroom: bool,
) -> tuple[str, dict[str, Any]]:
    generated_at = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    sections = [
        f"# Headroom Context Summary: {label}",
        "",
        f"- generated_at: `{generated_at}`",
        f"- model: `{model}`",
        "- source_of_truth: original files listed below; inspect originals before exact code fixes.",
        "- retrieval: this local wrapper records source paths and hashes, not MCP retrieve keys.",
        "",
    ]
    manifest: dict[str, Any] = {
        "label": label,
        "generated_at": generated_at,
        "model": model,
        "max_chars_per_file": max_chars,
        "files": [],
    }

    for path in paths:
        resolved = path.expanduser().resolve()
        text, data, truncated = read_text(resolved, max_chars)
        compressed, method, note = headroom_compress(text, model, no_headroom)
        retrieve_hashes = extract_retrieve_hashes(compressed)
        before = estimate_tokens(text)
        after = estimate_tokens(compressed)
        file_summary = FileSummary(
            path=str(resolved),
            sha256=sha256_bytes(data),
            byte_count=len(data),
            char_count=len(text),
            line_count=text.count("\n") + (1 if text else 0),
            truncated=truncated,
            estimated_tokens_before=before,
            estimated_tokens_after=after,
            method=method,
            headroom_retrieve_hashes=retrieve_hashes,
            note=note,
        )
        manifest["files"].append(asdict(file_summary))
        sections.extend(
            [
                f"## {resolved.name}",
                "",
                f"- path: `{resolved}`",
                f"- sha256: `{file_summary.sha256}`",
                f"- bytes: `{file_summary.byte_count}`",
                f"- lines_read: `{file_summary.line_count}`",
                f"- truncated: `{str(truncated).lower()}`",
                f"- tokens_estimate: `{before}` -> `{after}`",
                f"- method: `{method}`",
                f"- headroom_retrieve_hashes: `{', '.join(retrieve_hashes) if retrieve_hashes else 'none'}`",
                f"- note: {note}",
                "",
                "```text",
                compressed.rstrip(),
                "```",
                "",
            ]
        )

    return "\n".join(sections), manifest


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compress long Rummi Poker context files with Headroom and keep source hashes."
    )
    parser.add_argument("paths", nargs="+", help="Files to compress/summarize.")
    parser.add_argument("--label", default="context", help="Short label for the output folder.")
    parser.add_argument(
        "--out-dir",
        default="output/headroom_context",
        help="Base output directory. Default: output/headroom_context",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Headroom model argument.")
    parser.add_argument(
        "--max-chars-per-file",
        type=int,
        default=DEFAULT_MAX_CHARS,
        help=f"Maximum characters read per file. Default: {DEFAULT_MAX_CHARS}",
    )
    parser.add_argument(
        "--no-headroom",
        action="store_true",
        help="Skip Headroom import and use deterministic fallback summary.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    paths = [Path(value) for value in args.paths]
    missing = [str(path) for path in paths if not path.expanduser().exists()]
    if missing:
        for path in missing:
            print(f"missing file: {path}", file=sys.stderr)
        return 2

    label = slugify(args.label)
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = Path(args.out_dir).expanduser().resolve() / f"{stamp}_{label}"
    output_dir.mkdir(parents=True, exist_ok=True)

    summary, manifest = build_summary(
        paths=paths,
        label=label,
        model=args.model,
        max_chars=args.max_chars_per_file,
        no_headroom=args.no_headroom,
    )

    summary_path = output_dir / "headroom_summary.md"
    manifest_path = output_dir / "headroom_manifest.json"
    summary_path.write_text(summary, encoding="utf-8")
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"summary: {summary_path}")
    print(f"manifest: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
