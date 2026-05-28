#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
IMAGE_GEN="$CODEX_HOME/skills/.system/imagegen/scripts/image_gen.py"
INPUT="$ROOT/tmp/imagegen/card_emblem_prompts.jsonl"
OUT_DIR="$ROOT/output/imagegen/card_emblems"

if [[ ! -f "$IMAGE_GEN" ]]; then
  echo "imagegen CLI not found: $IMAGE_GEN" >&2
  exit 1
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=(--dry-run)
else
  DRY_RUN=()
fi

python3 "$ROOT/tools/imagegen/build_card_image_prompt_manifest.py" \
  --mode emblem \
  --out "$INPUT"

mkdir -p "$OUT_DIR"

python3 "$IMAGE_GEN" generate-batch \
  --input "$INPUT" \
  --out-dir "$OUT_DIR" \
  --concurrency "${IMAGEGEN_CONCURRENCY:-3}" \
  --quality "${IMAGEGEN_QUALITY:-medium}" \
  --output-format png \
  --downscale-max-dim 256 \
  --downscale-suffix="-preview" \
  "${DRY_RUN[@]}"
