#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR=""
RUN_WEB=1
RUN_WASM=1
PUB_GET=1

usage() {
  cat <<'EOF'
Usage:
  tools/web_build_smoke.sh [options]

Options:
  --output-dir <path>   Directory for logs and copied build artifacts.
  --web-only            Run only `flutter build web`.
  --wasm-only           Run only `flutter build web --wasm`.
  --skip-pub-get        Skip `flutter pub get`.
  -h, --help            Show this help.

Examples:
  tools/web_build_smoke.sh
  tools/web_build_smoke.sh --web-only
  tools/web_build_smoke.sh --wasm-only --output-dir /tmp/rummipoker_web_smoke/latest
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:?missing output dir}"
      shift 2
      ;;
    --web-only)
      RUN_WEB=1
      RUN_WASM=0
      shift
      ;;
    --wasm-only)
      RUN_WEB=0
      RUN_WASM=1
      shift
      ;;
    --skip-pub-get)
      PUB_GET=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$RUN_WEB" -eq 0 && "$RUN_WASM" -eq 0 ]]; then
  echo "Nothing to run. Choose at least one of --web-only or --wasm-only." >&2
  exit 1
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="/tmp/rummipoker_web_smoke/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

PUB_GET_LOG="$OUTPUT_DIR/00_pub_get.log"
WEB_LOG="$OUTPUT_DIR/10_build_web.log"
WASM_LOG="$OUTPUT_DIR/20_build_web_wasm.log"
WEB_ARTIFACT_DIR="$OUTPUT_DIR/build_web"
WASM_ARTIFACT_DIR="$OUTPUT_DIR/build_web_wasm"

run_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  "$@" 2>&1 | tee "$log_file"
}

copy_build_artifacts() {
  local destination="$1"
  rm -rf "$destination"
  mkdir -p "$destination"
  cp -R build/web/. "$destination/"
}

echo "Output: $OUTPUT_DIR"

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$PUB_GET_LOG" flutter pub get
fi

if [[ "$RUN_WEB" -eq 1 ]]; then
  run_and_capture "$WEB_LOG" flutter build web
  copy_build_artifacts "$WEB_ARTIFACT_DIR"
  echo "Saved web build artifacts: $WEB_ARTIFACT_DIR"
fi

if [[ "$RUN_WASM" -eq 1 ]]; then
  run_and_capture "$WASM_LOG" flutter build web --wasm
  copy_build_artifacts "$WASM_ARTIFACT_DIR"
  echo "Saved wasm build artifacts: $WASM_ARTIFACT_DIR"
fi

echo "Web build smoke complete."
echo "Artifacts:"
echo "  output: $OUTPUT_DIR"
if [[ "$PUB_GET" -eq 1 ]]; then
  echo "  pub get log: $PUB_GET_LOG"
fi
if [[ "$RUN_WEB" -eq 1 ]]; then
  echo "  web log: $WEB_LOG"
  echo "  web build: $WEB_ARTIFACT_DIR"
fi
if [[ "$RUN_WASM" -eq 1 ]]; then
  echo "  wasm log: $WASM_LOG"
  echo "  wasm build: $WASM_ARTIFACT_DIR"
fi
