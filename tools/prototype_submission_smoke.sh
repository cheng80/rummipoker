#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_BUILD=1
PUB_GET=1
OUTPUT_DIR=""

usage() {
  cat <<'EOF'
Usage:
  tools/prototype_submission_smoke.sh [options]

Options:
  --output-dir <path>   Directory for command logs.
  --skip-build          Skip `flutter build web`.
  --skip-pub-get        Skip `flutter pub get`.
  -h, --help            Show this help.

Examples:
  tools/prototype_submission_smoke.sh
  tools/prototype_submission_smoke.sh --skip-build
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:?missing output dir}"
      shift 2
      ;;
    --skip-build)
      RUN_BUILD=0
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

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="/tmp/rummipoker_submission_smoke/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

run_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  "$@" 2>&1 | tee "$log_file"
}

echo "Output: $OUTPUT_DIR"

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/00_pub_get.log" flutter pub get
fi

run_and_capture "$OUTPUT_DIR/10_analyze.log" flutter analyze \
  lib/services/debug_run_fixture_service.dart \
  lib/views/game_view.dart \
  lib/views/game/widgets/game_cashout_widgets.dart \
  lib/views/game/widgets/game_shared_widgets.dart \
  test/services/debug_run_fixture_service_test.dart \
  test/services/run_progression_service_test.dart \
  test/services/run_unlock_state_service_test.dart \
  test/services/run_completion_flow_test.dart \
  test/views/game/game_view_test.dart \
  test/views/game/widgets/game_cashout_widgets_test.dart

run_and_capture "$OUTPUT_DIR/20_tests.log" flutter test \
  test/services/debug_run_fixture_service_test.dart \
  test/services/run_progression_service_test.dart \
  test/services/run_unlock_state_service_test.dart \
  test/services/run_completion_flow_test.dart \
  test/views/game/game_view_test.dart \
  test/views/game/widgets/game_cashout_widgets_test.dart \
  --reporter expanded

if [[ "$RUN_BUILD" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/30_build_web.log" flutter build web
fi

echo "Prototype submission smoke complete."
echo "Logs: $OUTPUT_DIR"
