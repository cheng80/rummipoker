#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_ID="com.cheng80.rummipoker"
DEVICE_ID=""
OUTPUT_DIR="$ROOT_DIR/tools/app_store_screenshots/public/screenshots"
LOCALES="ko,en"
SCENE_FILTER=""
SETTLE_SECONDS=5
TIMEOUT_SECONDS=120
APP_READY_PATTERN="Dart VM Service|Flutter run key commands|Syncing files to device|A Dart VM Service on"
FLUTTER_PID=""

usage() {
  cat <<'EOF'
Usage:
  tools/ios_app_store_screenshot_capture.sh [options]

Options:
  --device-id <id>      Target booted iPhone simulator id. Defaults to first booted iPhone.
  --output-dir <path>   Output root. Default: tools/app_store_screenshots/public/screenshots
  --locales <csv>       Locale list. Default: ko,en
  --scenes <csv>        Scene id list. Default: all scenes
  --settle <seconds>    Wait before each screenshot. Default: 5
  --timeout <seconds>   Wait for flutter run readiness. Default: 120
  -h, --help            Show this help.

Notes:
  Reuses an already booted iPhone simulator. It does not boot a new device.
  Runs fixtures with SHOW_DEBUG_FIXTURES=true but hides debug chrome in capture routes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-id)
      DEVICE_ID="${2:?missing device id}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?missing output dir}"
      shift 2
      ;;
    --locales)
      LOCALES="${2:?missing locales}"
      shift 2
      ;;
    --scenes)
      SCENE_FILTER="${2:?missing scenes}"
      shift 2
      ;;
    --settle)
      SETTLE_SECONDS="${2:?missing settle seconds}"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="${2:?missing timeout seconds}"
      shift 2
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

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | grep 'Booted' | grep 'iPhone' | sed -E 's/.*\(([A-F0-9-]+)\) \(Booted\).*/\1/' | head -n 1)"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No booted iPhone simulator found. Boot an iPhone simulator first." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

cleanup() {
  if [[ -n "${FLUTTER_PID:-}" ]]; then
    kill -INT "$FLUTTER_PID" >/dev/null 2>&1 || true
    wait "$FLUTTER_PID" >/dev/null 2>&1 || true
    FLUTTER_PID=""
  fi
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

run_scene() {
  local locale="$1"
  local scene_id="$2"
  local route="$3"
  local locale_dir="$OUTPUT_DIR/$locale"
  local log_dir="$OUTPUT_DIR/_logs/$locale"
  local log_file="$log_dir/${scene_id}.log"
  local shot_file="$locale_dir/${scene_id}.png"

  mkdir -p "$locale_dir" "$log_dir"
  cleanup

  echo "Capturing locale=$locale scene=$scene_id route=$route"
  flutter run \
    -d "$DEVICE_ID" \
    --dart-define=SHOW_DEBUG_FIXTURES=true \
    --dart-define=START_LOCALE="$locale" \
    --route="$route" >"$log_file" 2>&1 &
  FLUTTER_PID=$!

  local waited=0
  until grep -Eq "$APP_READY_PATTERN" "$log_file"; do
    if ! kill -0 "$FLUTTER_PID" >/dev/null 2>&1; then
      echo "flutter run exited early. See $log_file" >&2
      return 1
    fi
    if [[ "$waited" -ge "$TIMEOUT_SECONDS" ]]; then
      echo "Timed out waiting for flutter run. See $log_file" >&2
      return 1
    fi
    sleep 1
    waited=$((waited + 1))
  done

  sleep "$SETTLE_SECONDS"
  xcrun simctl io "$DEVICE_ID" screenshot --type=png "$shot_file" >/dev/null
  echo "Saved $shot_file"
}

declare -a SCENES=(
  "01-title|/new-run"
  "02-battle-grid|/game?fixture=stage2_scoring_snapshot&debug_suppress_fixture_notice=1"
  "03-run-growth|/game?fixture=screenshot_run_growth_battle&debug_open_run_info=1&debug_suppress_fixture_notice=1"
  "04-market-build|/game?fixture=market_modifier_shop&debug_suppress_fixture_notice=1"
  "05-boss-rule|/game?fixture=boss_row_constraint_preview&debug_suppress_fixture_notice=1"
  "06-cash-out|/game?fixture=final_boss_cash_out_ready&auto_cashout_loop=1&debug_suppress_fixture_notice=1"
)

echo "Device: $DEVICE_ID"
echo "Output: $OUTPUT_DIR"
echo "Locales: $LOCALES"
if [[ -n "$SCENE_FILTER" ]]; then
  echo "Scenes: $SCENE_FILTER"
fi

scene_selected() {
  local scene_id="$1"
  [[ -z "$SCENE_FILTER" ]] && return 0
  local selected
  IFS=',' read -r -a selected <<<"$SCENE_FILTER"
  for candidate in "${selected[@]}"; do
    candidate="${candidate//[[:space:]]/}"
    [[ "$candidate" == "$scene_id" ]] && return 0
  done
  return 1
}

IFS=',' read -r -a LOCALE_LIST <<<"$LOCALES"
for locale in "${LOCALE_LIST[@]}"; do
  locale="${locale//[[:space:]]/}"
  [[ -z "$locale" ]] && continue
  for scene in "${SCENES[@]}"; do
    scene_id="${scene%%|*}"
    scene_selected "$scene_id" || continue
    route="${scene#*|}"
    run_scene "$locale" "$scene_id" "$route"
  done
done

cleanup
echo "iOS App Store screenshots saved to $OUTPUT_DIR"
