#!/usr/bin/env python3
"""Run a local Ollama model over RummiPoker LLM action requests."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path
from typing import Any, Iterable

from adapters.ollama_gemma import OllamaConfig, generate_json


ROOT = Path(__file__).resolve().parent
DEFAULT_SYSTEM_PROMPT = ROOT / "prompts" / "rummi_policy_system.md"
DEFAULT_SCHEMA_PROMPT = ROOT / "prompts" / "rummi_policy_action_schema.md"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run local Ollama policy over RummiPoker LLM request JSON/JSONL.",
    )
    parser.add_argument("--input", required=True, help="request JSON or JSONL path")
    parser.add_argument("--out", required=True, help="response JSON or JSONL path")
    parser.add_argument("--backend", choices=["ollama"], default="ollama")
    parser.add_argument("--model", default="gemma4:e4b")
    parser.add_argument("--base-url", default="http://127.0.0.1:11434")
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.9)
    parser.add_argument("--timeout-seconds", type=int, default=60)
    parser.add_argument("--system-prompt", default=str(DEFAULT_SYSTEM_PROMPT))
    parser.add_argument("--schema-prompt", default=str(DEFAULT_SCHEMA_PROMPT))
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Process at most this many requests. 0 means all.",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    out_path = Path(args.out)
    system_prompt = Path(args.system_prompt).read_text(encoding="utf-8")
    schema_prompt = Path(args.schema_prompt).read_text(encoding="utf-8")
    config = OllamaConfig(
        model=args.model,
        base_url=args.base_url,
        temperature=args.temperature,
        top_p=args.top_p,
        timeout_seconds=args.timeout_seconds,
    )

    requests = list(read_requests(input_path))
    if args.limit > 0:
        requests = requests[: args.limit]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    is_jsonl = out_path.suffix == ".jsonl" or len(requests) != 1
    responses = []

    with out_path.open("w", encoding="utf-8") as handle:
        for request in requests:
            started = time.monotonic()
            prompt = build_prompt(
                request,
                system_prompt=system_prompt,
                schema_prompt=schema_prompt,
            )
            response = generate_json(
                prompt,
                config=config,
                format_schema=response_schema_for(request),
            )
            response.setdefault("schema_version", 1)
            response.setdefault("status", "ok")
            response["request_id"] = request.get("request_id")
            response["model"] = args.model
            response["latency_ms"] = round((time.monotonic() - started) * 1000)
            responses.append(response)
            if is_jsonl:
                handle.write(json.dumps(response, ensure_ascii=False) + "\n")
        if not is_jsonl:
            handle.write(json.dumps(responses[0], ensure_ascii=False, indent=2) + "\n")

    print(f"responses: {out_path}")
    print(f"count: {len(responses)}")
    return 0


def read_requests(path: Path) -> Iterable[dict[str, Any]]:
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".jsonl":
        for line in text.splitlines():
            if line.strip():
                yield json.loads(line)
        return
    loaded = json.loads(text)
    if isinstance(loaded, list):
        for item in loaded:
            yield item
    elif isinstance(loaded, dict):
        yield loaded
    else:
        raise SystemExit("input JSON must be an object, array, or JSONL rows")


def build_prompt(
    request: dict[str, Any],
    *,
    system_prompt: str,
    schema_prompt: str,
) -> str:
    action_ids = [
        str(action["id"])
        for action in request.get("legal_actions", [])
        if isinstance(action, dict) and "id" in action
    ]
    return "\n\n".join(
        [
            system_prompt.strip(),
            schema_prompt.strip(),
            "Allowed selected_action_id values:",
            json.dumps(action_ids, ensure_ascii=False),
            "You must copy exactly one string from the allowed list into `selected_action_id`.",
            "Do not return `action`, `tool_name`, `tool_input`, `card_name`, or any keys outside the required JSON contract.",
            "RummiPoker request JSON:",
            json.dumps(request, ensure_ascii=False, indent=2),
            "Return the JSON object now.",
        ],
    )


def response_schema_for(request: dict[str, Any]) -> dict[str, Any]:
    action_ids = [
        str(action["id"])
        for action in request.get("legal_actions", [])
        if isinstance(action, dict) and "id" in action
    ]
    selected_action_schema: dict[str, Any] = {"type": "string"}
    if action_ids:
        selected_action_schema["enum"] = action_ids
    return {
        "type": "object",
        "properties": {
            "schema_version": {"type": "integer", "const": 1},
            "status": {"type": "string", "enum": ["ok"]},
            "selected_action_id": selected_action_schema,
            "confidence": {"type": "number", "minimum": 0, "maximum": 1},
            "reason": {"type": "string"},
        },
        "required": ["schema_version", "status", "selected_action_id"],
        "additionalProperties": False,
    }


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        raise SystemExit(130)
