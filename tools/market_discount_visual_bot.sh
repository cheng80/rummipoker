#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR=""
REPEAT_PER_SCENARIO="${MARKET_DISCOUNT_BOT_REPEAT_PER_SCENARIO:-1}"
SCENARIOS="${MARKET_DISCOUNT_BOT_SCENARIOS:-jester_discount_purchase_sale,item_discount_offer_visual,passive_sell_offer_stability,reroll_discount_feedback,baseline_jester_prices,baseline_item_prices,slot_unlock_market_visual}"
LOCALE="${MARKET_DISCOUNT_BOT_LOCALE:-ko}"
ACTION_DELAY_MS="${MARKET_DISCOUNT_BOT_ACTION_DELAY_MS:-220}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-4444}"
WEB_PORT="${MARKET_DISCOUNT_BOT_WEB_PORT:-7371}"
PUB_GET=1
CHROMEDRIVER_PID=""

usage() {
  cat <<'EOF'
Usage:
  tools/market_discount_visual_bot.sh [options]

Options:
  --scenarios <csv>          Scenario ids. Default: core market matrix.
  --repeat-per-scenario <n>  Fresh browser runs per scenario. Default: 1.
  --iterations <number>      Alias for --repeat-per-scenario.
  --locale <code>           ko | en | ja | zh-CN | zh-TW. Default: ko.
  --action-delay-ms <ms>     Delay after UI actions. Default: 220.
  --web-port <number>        Fixed Flutter web port. Default: 7371.
  --output-dir <path>        Directory for logs.
  --skip-pub-get             Skip `flutter pub get`.
  -h, --help                 Show this help.

Environment:
  CHROMEDRIVER_CMD           Custom chromedriver command.
  CHROMEDRIVER_PORT          WebDriver port. Default: 4444.

Notes:
  This bot uses debug fixtures for shop regression eye-checks. It is not
  full-play evidence.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iterations)
      REPEAT_PER_SCENARIO="${2:?missing iterations}"
      shift 2
      ;;
    --repeat-per-scenario)
      REPEAT_PER_SCENARIO="${2:?missing repeat count}"
      shift 2
      ;;
    --scenarios)
      SCENARIOS="${2:?missing scenarios}"
      shift 2
      ;;
    --locale)
      LOCALE="${2:?missing locale}"
      shift 2
      ;;
    --action-delay-ms)
      ACTION_DELAY_MS="${2:?missing action delay}"
      shift 2
      ;;
    --web-port)
      WEB_PORT="${2:?missing web port}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?missing output dir}"
      shift 2
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
  OUTPUT_DIR="/tmp/rummipoker_market_discount_visual_bot/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

port_is_open() {
  nc -z 127.0.0.1 "$CHROMEDRIVER_PORT" >/dev/null 2>&1
}

cleanup_bot_processes() {
  [[ -n "${CHROMEDRIVER_PID:-}" ]] && kill "$CHROMEDRIVER_PID" 2>/dev/null || true
  pkill -f 'flutter drive.*integration_test/market_discount_visual_bot_test.dart' \
    2>/dev/null || true
  pkill -f 'flutter_tools_chrome_device' 2>/dev/null || true
  pkill -f 'chromedriver.*--port='"$CHROMEDRIVER_PORT" 2>/dev/null || true
  local web_pids
  web_pids="$(lsof -ti tcp:"$WEB_PORT" 2>/dev/null || true)"
  [[ -n "$web_pids" ]] && kill $web_pids 2>/dev/null || true
  local webdriver_pids
  webdriver_pids="$(ps -axo pid,command | awk \
    '/--test-type=webdriver/ && /Google Chrome/ && !/awk/ {print $1}')"
  if [[ -n "$webdriver_pids" ]]; then
    kill $webdriver_pids 2>/dev/null || true
    sleep 1
    webdriver_pids="$(ps -axo pid,command | awk \
      '/--test-type=webdriver/ && /Google Chrome/ && !/awk/ {print $1}')"
    [[ -n "$webdriver_pids" ]] && kill -9 $webdriver_pids 2>/dev/null || true
  fi
}
trap cleanup_bot_processes EXIT

install_chromedriver() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "chromedriver not found. Install it or set CHROMEDRIVER_CMD." >&2
    exit 1
  fi

  local chrome_bin="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  local chrome_version="stable"
  if [[ -x "$chrome_bin" ]]; then
    chrome_version="$("$chrome_bin" --version | awk '{print $3}')"
  fi

  local cache_dir="/tmp/rummipoker_chromedriver"
  mkdir -p "$cache_dir"
  local install_log="$OUTPUT_DIR/chromedriver_install.log"
  echo "Installing chromedriver@$chrome_version" >&2
  npx --yes @puppeteer/browsers install "chromedriver@$chrome_version" \
    --path "$cache_dir" >"$install_log" 2>&1
  awk 'NF {path=$NF} END {print path}' "$install_log"
}

start_chromedriver() {
  if port_is_open; then
    echo "Using existing chromedriver on port $CHROMEDRIVER_PORT"
    return
  fi

  local cmd=()
  if [[ -n "${CHROMEDRIVER_CMD:-}" ]]; then
    read -r -a cmd <<<"$CHROMEDRIVER_CMD"
  elif command -v chromedriver >/dev/null 2>&1; then
    cmd=(chromedriver)
  else
    cmd=("$(install_chromedriver)")
  fi

  echo "Starting chromedriver on port $CHROMEDRIVER_PORT"
  "${cmd[@]}" --port="$CHROMEDRIVER_PORT" \
    >"$OUTPUT_DIR/chromedriver.log" 2>&1 &
  CHROMEDRIVER_PID=$!

  for _ in {1..30}; do
    if port_is_open; then
      return
    fi
    sleep 1
  done

  echo "chromedriver did not start. Log: $OUTPUT_DIR/chromedriver.log" >&2
  exit 1
}

run_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  "$@" 2>&1 | tee "$log_file"
}

run_drive_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  : >"$log_file"
  "$@" >"$log_file" 2>&1 &
  local drive_pid=$!
  tail -f "$log_file" &
  local tail_pid=$!
  local passed=0

  while kill -0 "$drive_pid" 2>/dev/null; do
    if grep -q 'MARKET_DISCOUNT_VISUAL_BOT_PASS' "$log_file" &&
      grep -q 'All tests passed!' "$log_file"; then
      passed=1
      sleep 2
      kill "$drive_pid" 2>/dev/null || true
      break
    fi
    sleep 1
  done

  wait "$drive_pid" 2>/dev/null || true
  kill "$tail_pid" 2>/dev/null || true
  wait "$tail_pid" 2>/dev/null || true

  if [[ "$passed" -eq 1 ]]; then
    return 0
  fi
  if grep -q 'MARKET_DISCOUNT_VISUAL_BOT_PASS' "$log_file" &&
    grep -q 'All tests passed!' "$log_file"; then
    return 0
  fi
  return 1
}

echo "Output: $OUTPUT_DIR"
cleanup_bot_processes
start_chromedriver

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/00_pub_get.log" flutter pub get
fi

COMBINED_LOG="$OUTPUT_DIR/10_market_discount_visual_bot.log"
: >"$COMBINED_LOG"
IFS=',' read -r -a SCENARIO_LIST <<<"$SCENARIOS"
expected_passes=0
for scenario in "${SCENARIO_LIST[@]}"; do
  scenario="${scenario//[[:space:]]/}"
  [[ -z "$scenario" ]] && continue
  for run_index in $(seq 1 "$REPEAT_PER_SCENARIO"); do
    expected_passes=$((expected_passes + 1))
    echo "market_discount_visual_bot scenario=$scenario run=$run_index/$REPEAT_PER_SCENARIO"
    cleanup_bot_processes
    start_chromedriver
    ITERATION_LOG="$OUTPUT_DIR/10_market_discount_visual_bot_${expected_passes}_${scenario}.log"
    run_drive_and_capture "$ITERATION_LOG" \
      flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/market_discount_visual_bot_test.dart \
        -d chrome \
        --web-port="$WEB_PORT" \
        --driver-port="$CHROMEDRIVER_PORT" \
        --no-keep-app-running \
        --dart-define=MARKET_DISCOUNT_BOT_ITERATIONS=1 \
        --dart-define=MARKET_DISCOUNT_BOT_SCENARIO="$scenario" \
        --dart-define=MARKET_DISCOUNT_BOT_LOCALE="$LOCALE" \
        --dart-define=MARKET_DISCOUNT_BOT_ACTION_DELAY_MS="$ACTION_DELAY_MS"
    cat "$ITERATION_LOG" >>"$COMBINED_LOG"
  done
done

if [[ "$(grep -c 'MARKET_DISCOUNT_VISUAL_BOT_PASS' "$COMBINED_LOG")" -lt "$expected_passes" ]]; then
  echo "MARKET_DISCOUNT_VISUAL_BOT_PASS not found in log." >&2
  exit 1
fi

echo "market_discount_visual_bot complete."
echo "Logs: $OUTPUT_DIR"
