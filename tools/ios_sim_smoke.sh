#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_ID="com.cheng80.rummipoker"
DEVICE_ID=""
ROUTE=""
OUTPUT_DIR=""
OPEN_URL_AFTER_LAUNCH=""
RELAUNCH_AFTER_URL=0
NO_TERMINATE=0
TIMEOUT_SECONDS=90
SETTLE_SECONDS=4
APP_READY_PATTERN="Dart VM Service|Flutter run key commands|Syncing files to device|A Dart VM Service on"

usage() {
  cat <<'EOF'
Usage:
  tools/ios_sim_smoke.sh [options]

Options:
  --device-id <id>       Target simulator device id. Defaults to the first booted iPhone simulator.
  --route <route>        Flutter route to launch, e.g. /game?fixture=stage2_scoring_snapshot
  --output-dir <path>    Directory for logs and screenshots.
  --open-url <url>       Open URL after app launch. Useful for background-save checks.
  --relaunch            Relaunch app after opening URL.
  --bundle-id <id>       App bundle id. Default: com.cheng80.rummipoker
  --timeout <seconds>    Launch wait timeout. Default: 90
  --settle <seconds>     Wait after launch/open-url/relaunch before screenshot. Default: 4
  --no-terminate         Leave flutter run session alive when script ends.
  -h, --help             Show this help.

Examples:
  tools/ios_sim_smoke.sh
  tools/ios_sim_smoke.sh --route "/game?fixture=stage2_scoring_snapshot"
  tools/ios_sim_smoke.sh --open-url "https://example.com" --relaunch
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-id)
      DEVICE_ID="${2:?missing device id}"
      shift 2
      ;;
    --route)
      ROUTE="${2:?missing route}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?missing output dir}"
      shift 2
      ;;
    --open-url)
      OPEN_URL_AFTER_LAUNCH="${2:?missing url}"
      shift 2
      ;;
    --relaunch)
      RELAUNCH_AFTER_URL=1
      shift
      ;;
    --bundle-id)
      BUNDLE_ID="${2:?missing bundle id}"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="${2:?missing timeout}"
      shift 2
      ;;
    --settle)
      SETTLE_SECONDS="${2:?missing settle seconds}"
      shift 2
      ;;
    --no-terminate)
      NO_TERMINATE=1
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
  OUTPUT_DIR="/tmp/rummipoker_ios_smoke/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | grep 'Booted' | grep 'iPhone' | sed -E 's/.*\(([A-F0-9-]+)\) \(Booted\).*/\1/' | head -n 1)"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No booted iPhone simulator found." >&2
  exit 1
fi

LOG_FILE="$OUTPUT_DIR/flutter_run.log"
TITLE_SHOT="$OUTPUT_DIR/01_launch.png"
URL_SHOT="$OUTPUT_DIR/02_after_url.png"
RELAUNCH_SHOT="$OUTPUT_DIR/03_relaunch.png"

cleanup() {
  if [[ "${NO_TERMINATE}" -eq 0 && -n "${FLUTTER_PID:-}" ]]; then
    kill -INT "$FLUTTER_PID" >/dev/null 2>&1 || true
    wait "$FLUTTER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

RUN_CMD=(flutter run -d "$DEVICE_ID")
if [[ -n "$ROUTE" ]]; then
  RUN_CMD+=(--route="$ROUTE")
fi

echo "Device: $DEVICE_ID"
echo "Bundle ID: $BUNDLE_ID"
echo "Output: $OUTPUT_DIR"
echo "Route: ${ROUTE:-<default>}"
echo "Settle wait: ${SETTLE_SECONDS}s"

"${RUN_CMD[@]}" >"$LOG_FILE" 2>&1 &
FLUTTER_PID=$!

SECONDS_WAITED=0
until grep -Eq "$APP_READY_PATTERN" "$LOG_FILE"; do
  if ! kill -0 "$FLUTTER_PID" >/dev/null 2>&1; then
    echo "flutter run exited early. See $LOG_FILE" >&2
    exit 1
  fi
  if [[ "$SECONDS_WAITED" -ge "$TIMEOUT_SECONDS" ]]; then
    echo "Timed out waiting for flutter run. See $LOG_FILE" >&2
    exit 1
  fi
  sleep 1
  SECONDS_WAITED=$((SECONDS_WAITED + 1))
done

sleep "$SETTLE_SECONDS"
xcrun simctl io "$DEVICE_ID" screenshot "$TITLE_SHOT" >/dev/null
echo "Saved launch screenshot: $TITLE_SHOT"

if [[ -n "$OPEN_URL_AFTER_LAUNCH" ]]; then
  xcrun simctl openurl "$DEVICE_ID" "$OPEN_URL_AFTER_LAUNCH"
  sleep "$SETTLE_SECONDS"
  xcrun simctl io "$DEVICE_ID" screenshot "$URL_SHOT" >/dev/null
  echo "Saved post-URL screenshot: $URL_SHOT"

  if [[ "$RELAUNCH_AFTER_URL" -eq 1 ]]; then
    xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null
    sleep "$SETTLE_SECONDS"
    xcrun simctl io "$DEVICE_ID" screenshot "$RELAUNCH_SHOT" >/dev/null
    echo "Saved relaunch screenshot: $RELAUNCH_SHOT"
  fi
fi

echo "Smoke run complete."
echo "Artifacts:"
echo "  log: $LOG_FILE"
echo "  screenshots: $OUTPUT_DIR"
