#!/usr/bin/env python3
"""Ollama adapter for RummiPoker LLM policy smoke runs."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class OllamaConfig:
    model: str = "gemma4:e4b"
    base_url: str = "http://127.0.0.1:11434"
    temperature: float = 0.2
    top_p: float = 0.9
    timeout_seconds: int = 60


def generate_json(prompt: str, *, config: OllamaConfig) -> dict[str, Any]:
    payload = {
        "model": config.model,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "options": {
            "temperature": config.temperature,
            "top_p": config.top_p,
        },
    }
    request = urllib.request.Request(
        f"{config.base_url.rstrip('/')}/api/generate",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(
            request,
            timeout=config.timeout_seconds,
        ) as response:
            body = json.loads(response.read().decode("utf-8"))
    except TimeoutError:
        return _error("timeout", "Ollama request timed out.")
    except urllib.error.URLError as error:
        return _error("connection_error", str(error))
    except json.JSONDecodeError as error:
        return _error("invalid_ollama_response", str(error))

    raw_response = body.get("response")
    if not isinstance(raw_response, str) or not raw_response.strip():
        return _error("empty_response", "Ollama returned an empty response.")
    try:
        parsed = json.loads(raw_response)
    except json.JSONDecodeError as error:
        return _error("invalid_json", str(error), raw_response=raw_response)
    if not isinstance(parsed, dict):
        return _error("invalid_json_type", "Model JSON response is not an object.")
    return parsed


def _error(
    error_code: str,
    message: str,
    *,
    raw_response: str | None = None,
) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "error",
        "error_code": error_code,
        "message": message,
        **({"raw_response": raw_response} if raw_response is not None else {}),
    }
