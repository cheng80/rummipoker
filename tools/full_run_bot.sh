#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR=""
TRACE_PATH="${FULL_RUN_BOT_TRACE_PATH:-}"
MODE="${FULL_RUN_BOT_MODE:-full}"
SEED="${FULL_RUN_BOT_SEED:-91460}"
DIFFICULTY="${FULL_RUN_BOT_DIFFICULTY:-standard}"
RUN_MODIFIER="${FULL_RUN_BOT_RUN_MODIFIER:-basic}"
LOCALE="${FULL_RUN_BOT_LOCALE:-ko}"
MAX_BATTLE_ACTIONS="${FULL_RUN_BOT_MAX_BATTLE_ACTIONS:-420}"
MAX_GAME_OVER_RETRIES="${FULL_RUN_BOT_MAX_GAME_OVER_RETRIES:-24}"
RETRY_RECOVERY_MIN_ATTEMPT="${FULL_RUN_BOT_RETRY_RECOVERY_MIN_ATTEMPT:-2}"
ACTION_DELAY_MS="${FULL_RUN_BOT_ACTION_DELAY_MS:-250}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-4444}"
WEB_PORT="${FULL_RUN_BOT_WEB_PORT:-7357}"
BROWSER_PROFILE_DIR="${FULL_RUN_BOT_BROWSER_PROFILE_DIR:-/tmp/rummipoker_full_run_bot/chrome_profile}"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/cheng80/flutter/bin/flutter}"
FLUTTER_DRIVE_MODE="${FULL_RUN_BOT_FLUTTER_MODE:-debug}"
RESUME_ACTIVE_RUN=false
RESTART_STAGE_ON_RESUME=false
TUTORIALS_ALREADY_SEEN=false
TARGET_STAGE="${FULL_RUN_BOT_TARGET_STAGE:-1}"
TARGET_TIER="${FULL_RUN_BOT_TARGET_TIER:-boss}"
TARGET_SCENE="${FULL_RUN_BOT_TARGET_SCENE:-cashOut}"
REQUIRED_EVIDENCE="${FULL_RUN_BOT_REQUIRED_EVIDENCE:-}"
BRIDGE_RESUME_LIMIT="${FULL_RUN_BOT_BRIDGE_RESUME_LIMIT:-12}"
PUB_GET=1
CHROMEDRIVER_PID=""
TRACE_APPEND=0
HEADLESS=true
DDS=true
START_CHROMEDRIVER=true

usage() {
  cat <<'EOF'
Usage:
  tools/full_run_bot.sh [options]

Options:
  --seed <number>           Run seed. Default: 91460.
  --mode <name>             full | sub. Default: full.
  --difficulty <name>       standard | challenge. Default: standard.
  --run-modifier <name>     basic | high_stakes. Default: basic.
  --locale <code>           ko | en | ja | zh-CN | zh-TW. Default: ko.
  --max-actions <number>    Max battle actions per station. Default: 420.
  --max-retries <number>    Max game-over retries per bot run. Default: 24.
  --retry-recovery-min-attempt <n>
                            Enable retry recovery policy at retry n.
                            Default: 2. Use 0 for hard-section reinforcement.
  --action-delay-ms <ms>    Delay after battle actions. Default: 250.
  --resume-active-run       Load the saved active run from the checkpoint env file.
  --restart-stage-on-resume Restart the saved active run from its Station start
                            snapshot after loading the checkpoint.
  --tutorials-already-seen  Start with battle/market tutorial seen flags enabled.
  --browser-profile-dir <p> Directory used for bot checkpoint env files.
                            Default: /tmp/rummipoker_full_run_bot/chrome_profile.
  --web-port <number>       Fixed Flutter web port for persisted browser storage.
                            Default: 7357.
  --output-dir <path>       Directory for logs.
  --trace-path <path>       JSONL trace path. Default: <output-dir>/full_run_trace.jsonl.
  --target-stage <number>   Sub-run target stage. Default: 1.
  --target-tier <name>      small | big | boss. Default: boss.
  --target-scene <name>     stationSelect | battle | cashOut | market | runComplete.
                            Default: cashOut.
  --required-evidence <key> market_purchase | item_purchase | item_use.
  --bridge-resume-limit <n> Auto-resume count for FlutterDriver request_data
                            bridge failures. Default: 12.
  --no-headless             Run WebDriver Chrome visibly instead of headless.
  --no-dds                  Disable Dart Developer Service for flutter drive.
  --no-start-chromedriver   Let flutter drive manage WebDriver server startup.
  --skip-pub-get            Skip `flutter pub get`.
  -h, --help                Show this help.

Environment:
  CHROMEDRIVER_CMD          Custom chromedriver command.
  CHROMEDRIVER_PORT         WebDriver port. Default: 4444.
  FLUTTER_BIN               Flutter executable. Default: /Users/cheng80/flutter/bin/flutter.
  FULL_RUN_BOT_FLUTTER_MODE Flutter drive mode: debug | profile | release.
                            Default: debug.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed)
      SEED="${2:?missing seed}"
      shift 2
      ;;
    --mode)
      MODE="${2:?missing mode}"
      shift 2
      ;;
    --difficulty)
      DIFFICULTY="${2:?missing difficulty}"
      shift 2
      ;;
    --run-modifier)
      RUN_MODIFIER="${2:?missing run modifier}"
      shift 2
      ;;
    --locale)
      LOCALE="${2:?missing locale}"
      shift 2
      ;;
    --max-actions)
      MAX_BATTLE_ACTIONS="${2:?missing max actions}"
      shift 2
      ;;
    --max-retries)
      MAX_GAME_OVER_RETRIES="${2:?missing max retries}"
      shift 2
      ;;
    --retry-recovery-min-attempt)
      RETRY_RECOVERY_MIN_ATTEMPT="${2:?missing retry recovery min attempt}"
      shift 2
      ;;
    --action-delay-ms)
      ACTION_DELAY_MS="${2:?missing action delay}"
      shift 2
      ;;
    --resume-active-run)
      RESUME_ACTIVE_RUN=true
      shift
      ;;
    --restart-stage-on-resume)
      RESTART_STAGE_ON_RESUME=true
      shift
      ;;
    --tutorials-already-seen)
      TUTORIALS_ALREADY_SEEN=true
      shift
      ;;
    --browser-profile-dir)
      BROWSER_PROFILE_DIR="${2:?missing browser profile dir}"
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
    --trace-path)
      TRACE_PATH="${2:?missing trace path}"
      shift 2
      ;;
    --target-stage)
      TARGET_STAGE="${2:?missing target stage}"
      shift 2
      ;;
    --target-tier)
      TARGET_TIER="${2:?missing target tier}"
      shift 2
      ;;
    --target-scene)
      TARGET_SCENE="${2:?missing target scene}"
      shift 2
      ;;
    --required-evidence)
      REQUIRED_EVIDENCE="${2:?missing required evidence}"
      shift 2
      ;;
    --bridge-resume-limit)
      BRIDGE_RESUME_LIMIT="${2:?missing bridge resume limit}"
      shift 2
      ;;
    --no-headless)
      HEADLESS=false
      shift
      ;;
    --no-dds)
      DDS=false
      shift
      ;;
    --no-start-chromedriver)
      START_CHROMEDRIVER=false
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
  OUTPUT_DIR="/tmp/rummipoker_full_run_bot/$(date +%Y%m%d_%H%M%S)"
fi
if [[ -z "$TRACE_PATH" ]]; then
  TRACE_PATH="$OUTPUT_DIR/full_run_trace.jsonl"
fi
mkdir -p "$(dirname "$TRACE_PATH")"
mkdir -p "$OUTPUT_DIR"

case "$FLUTTER_DRIVE_MODE" in
  debug|profile|release)
    ;;
  *)
    echo "Invalid FULL_RUN_BOT_FLUTTER_MODE: $FLUTTER_DRIVE_MODE" >&2
    echo "Expected: debug, profile, or release." >&2
    exit 1
    ;;
esac

DRIVE_MODE_ARGS=()
if [[ "$FLUTTER_DRIVE_MODE" != "debug" ]]; then
  DRIVE_MODE_ARGS=(--"$FLUTTER_DRIVE_MODE")
fi
HEADLESS_ARG="--headless"
if [[ "$HEADLESS" != "true" ]]; then
  HEADLESS_ARG="--no-headless"
fi
DDS_ARG="--dds"
if [[ "$DDS" != "true" ]]; then
  DDS_ARG="--no-dds"
fi

port_is_open() {
  nc -z 127.0.0.1 "$CHROMEDRIVER_PORT" >/dev/null 2>&1
}

cleanup_bot_processes() {
  [[ -n "${CHROMEDRIVER_PID:-}" ]] && kill "$CHROMEDRIVER_PID" 2>/dev/null || true
  pkill -f 'flutter drive.*integration_test/full_run_bot_test.dart' \
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
  local chrome_helper_pids
  chrome_helper_pids="$(ps -axo pid,command | awk -v profile="$BROWSER_PROFILE_DIR" \
    '/Google Chrome Helper/ && !/awk/ && \
     (/--test-type=webdriver/ || /rummipoker_full_run/ || (profile != "" && index($0, profile) > 0)) {print $1}')"
  if [[ -n "$chrome_helper_pids" ]]; then
    kill $chrome_helper_pids 2>/dev/null || true
    sleep 1
    chrome_helper_pids="$(ps -axo pid,command | awk -v profile="$BROWSER_PROFILE_DIR" \
      '/Google Chrome Helper/ && !/awk/ && \
       (/--test-type=webdriver/ || /rummipoker_full_run/ || (profile != "" && index($0, profile) > 0)) {print $1}')"
    [[ -n "$chrome_helper_pids" ]] && kill -9 $chrome_helper_pids 2>/dev/null || true
  fi
  local regular_chrome_pids
  regular_chrome_pids="$(ps -axo pid,command | awk \
    '/Google Chrome/ && !/Google Chrome Helper/ && !/--test-type=webdriver/ && !/awk/ {print $1}')"
  if [[ -z "$regular_chrome_pids" ]]; then
    chrome_helper_pids="$(ps -axo pid,command | awk \
      '/Google Chrome Helper/ && !/awk/ {print $1}')"
    if [[ -n "$chrome_helper_pids" ]]; then
      kill $chrome_helper_pids 2>/dev/null || true
      sleep 1
      chrome_helper_pids="$(ps -axo pid,command | awk \
        '/Google Chrome Helper/ && !/awk/ {print $1}')"
      [[ -n "$chrome_helper_pids" ]] && kill -9 $chrome_helper_pids 2>/dev/null || true
    fi
  fi
}
trap cleanup_bot_processes EXIT

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
  awk '/^chromedriver@/ {print $NF; exit}' "$install_log"
}

run_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  "$@" 2>&1 | tee "$log_file"
}

run_flutter_drive_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  set +e
  "$@" 2>&1 | tee "$log_file" &
  local run_pid=$!

  while kill -0 "$run_pid" 2>/dev/null; do
    if grep -q "All tests passed!" "$log_file" 2>/dev/null; then
      sleep 3
      persist_checkpoint "$log_file"
      extract_trace_from_log "$log_file"
      if kill -0 "$run_pid" 2>/dev/null; then
        echo "Detected pass; cleaning up lingering flutter drive session." \
          | tee -a "$log_file"
        pkill -f 'flutter drive.*integration_test/full_run_bot_test.dart' \
          2>/dev/null || true
        pkill -f 'flutter_tools_chrome_device' 2>/dev/null || true
        cleanup_bot_processes
        pkill -f "tee $log_file" 2>/dev/null || true
        kill "$run_pid" 2>/dev/null || true
      fi
      set -e
      return 0
    fi
    sleep 2
  done

  wait "$run_pid"
  local status=$?
  persist_checkpoint "$log_file"
  extract_trace_from_log "$log_file"
  cleanup_bot_processes
  set -e
  if [[ "$status" -ne 0 ]] && grep -q "All tests passed!" "$log_file" 2>/dev/null; then
    return 0
  fi
  return "$status"
}

extract_trace_from_log() {
  local log_file="$1"
  if [[ "$TRACE_APPEND" == "1" && -f "$TRACE_PATH" ]]; then
    python3 tools/extract_full_run_trace_from_log.py "$log_file" \
      --out "$TRACE_PATH" --append || true
    return
  fi
  python3 tools/extract_full_run_trace_from_log.py "$log_file" \
    --out "$TRACE_PATH" || true
}

persist_checkpoint() {
  local log_file="$1"
  mkdir -p "$BROWSER_PROFILE_DIR"

  local checkpoint
  checkpoint="$(grep -a 'FULL_RUN_BOT_CHECKPOINT_B64:' "$log_file" 2>/dev/null \
    | tail -1 | sed 's/^.*FULL_RUN_BOT_CHECKPOINT_B64://')"
  if [[ -n "$checkpoint" ]]; then
    printf 'FULL_RUN_BOT_RESUME_SAVE_B64=%s\n' "$checkpoint" \
      >"$BROWSER_PROFILE_DIR/latest_checkpoint.env"
  fi

  local carryover
  carryover="$(grep -a 'FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64:' "$log_file" 2>/dev/null \
    | tail -1 | sed 's/^.*FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64://')"
  if [[ -n "$carryover" ]]; then
    printf 'FULL_RUN_BOT_CHALLENGE_CARRYOVER_B64=%s\n' "$carryover" \
      >"$BROWSER_PROFILE_DIR/latest_challenge_carryover.env"
  fi
}

echo "Output: $OUTPUT_DIR"
cleanup_bot_processes
CARRYOVER_ENV_BACKUP=""
if [[ "$DIFFICULTY" == "challenge" && -f "$BROWSER_PROFILE_DIR/latest_challenge_carryover.env" ]]; then
  CARRYOVER_ENV_BACKUP="$(mktemp /tmp/rummipoker_challenge_carryover.XXXXXX.env)"
  cp "$BROWSER_PROFILE_DIR/latest_challenge_carryover.env" "$CARRYOVER_ENV_BACKUP"
fi
if [[ "$RESUME_ACTIVE_RUN" != "true" ]]; then
  if [[ -z "$BROWSER_PROFILE_DIR" || "$BROWSER_PROFILE_DIR" == "/" ]]; then
    echo "Refusing to clear unsafe browser profile dir: $BROWSER_PROFILE_DIR" >&2
    exit 1
  fi
  rm -rf "$BROWSER_PROFILE_DIR"
fi
if [[ "$START_CHROMEDRIVER" == "true" ]]; then
  start_chromedriver
fi
mkdir -p "$BROWSER_PROFILE_DIR"
if [[ -n "$CARRYOVER_ENV_BACKUP" && -f "$CARRYOVER_ENV_BACKUP" ]]; then
  cp "$CARRYOVER_ENV_BACKUP" "$BROWSER_PROFILE_DIR/latest_challenge_carryover.env"
  rm -f "$CARRYOVER_ENV_BACKUP"
fi
RESUME_DEFINE_ARG=""
if [[ "$RESUME_ACTIVE_RUN" == "true" && -f "$BROWSER_PROFILE_DIR/latest_checkpoint.env" ]]; then
  RESUME_DEFINE_ARG="--dart-define-from-file=$BROWSER_PROFILE_DIR/latest_checkpoint.env"
fi
CARRYOVER_DEFINE_ARG=""
if [[ -f "$BROWSER_PROFILE_DIR/latest_challenge_carryover.env" ]]; then
  CARRYOVER_DEFINE_ARG="--dart-define-from-file=$BROWSER_PROFILE_DIR/latest_challenge_carryover.env"
fi

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/00_pub_get.log" "$FLUTTER_BIN" pub get
fi
export FULL_RUN_BOT_BROWSER_PROFILE_DIR="$BROWSER_PROFILE_DIR"

segment_index=0
while true; do
  if [[ "$segment_index" -eq 0 ]]; then
    log_file="$OUTPUT_DIR/10_full_run_bot.log"
  else
    log_file="$OUTPUT_DIR/$(printf '%02d' $((10 + segment_index)))_full_run_bot_resume_${segment_index}.log"
  fi

  if run_flutter_drive_and_capture "$log_file" \
    "$FLUTTER_BIN" drive \
      ${DRIVE_MODE_ARGS[@]+"${DRIVE_MODE_ARGS[@]}"} \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/full_run_bot_test.dart \
      -d chrome \
      --no-start-paused \
      --web-port="$WEB_PORT" \
      --web-launch-url="http://127.0.0.1:$WEB_PORT/" \
      --driver-port="$CHROMEDRIVER_PORT" \
      "$HEADLESS_ARG" \
      "$DDS_ARG" \
      --no-keep-app-running \
      ${RESUME_DEFINE_ARG:+"$RESUME_DEFINE_ARG"} \
      ${CARRYOVER_DEFINE_ARG:+"$CARRYOVER_DEFINE_ARG"} \
      --dart-define=FULL_RUN_BOT_MODE="$MODE" \
      --dart-define=FULL_RUN_BOT_SEED="$SEED" \
      --dart-define=FULL_RUN_BOT_DIFFICULTY="$DIFFICULTY" \
      --dart-define=FULL_RUN_BOT_RUN_MODIFIER="$RUN_MODIFIER" \
      --dart-define=FULL_RUN_BOT_LOCALE="$LOCALE" \
      --dart-define=FULL_RUN_BOT_MAX_BATTLE_ACTIONS="$MAX_BATTLE_ACTIONS" \
      --dart-define=FULL_RUN_BOT_MAX_GAME_OVER_RETRIES="$MAX_GAME_OVER_RETRIES" \
      --dart-define=FULL_RUN_BOT_RETRY_RECOVERY_MIN_ATTEMPT="$RETRY_RECOVERY_MIN_ATTEMPT" \
      --dart-define=FULL_RUN_BOT_ACTION_DELAY_MS="$ACTION_DELAY_MS" \
      --dart-define=FULL_RUN_BOT_RESUME_ACTIVE_RUN="$RESUME_ACTIVE_RUN" \
      --dart-define=FULL_RUN_BOT_RESTART_STAGE_ON_RESUME="$RESTART_STAGE_ON_RESUME" \
      --dart-define=FULL_RUN_BOT_TUTORIALS_ALREADY_SEEN="$TUTORIALS_ALREADY_SEEN" \
      --dart-define=FULL_RUN_BOT_TRACE_PATH="$TRACE_PATH" \
      --dart-define=FULL_RUN_BOT_TARGET_STAGE="$TARGET_STAGE" \
      --dart-define=FULL_RUN_BOT_TARGET_TIER="$TARGET_TIER" \
      --dart-define=FULL_RUN_BOT_TARGET_SCENE="$TARGET_SCENE" \
      --dart-define=FULL_RUN_BOT_REQUIRED_EVIDENCE="$REQUIRED_EVIDENCE"; then
    break
  else
    status=$?
  fi

  has_bridge_failure=0
  if grep -q "DriverError: Error while reading FlutterDriver result.*request_data" "$log_file"; then
    has_bridge_failure=1
  fi

  if [[ "$segment_index" -ge "$BRIDGE_RESUME_LIMIT" ]] || \
     [[ "$has_bridge_failure" -ne 1 ]] || \
     [[ ! -f "$BROWSER_PROFILE_DIR/latest_checkpoint.env" ]]; then
    exit "$status"
  fi

  segment_index=$((segment_index + 1))
  echo "FlutterDriver request_data bridge failed; resuming from checkpoint segment $segment_index/$BRIDGE_RESUME_LIMIT." \
    | tee -a "$log_file"
  RESUME_ACTIVE_RUN=true
  RESUME_DEFINE_ARG="--dart-define-from-file=$BROWSER_PROFILE_DIR/latest_checkpoint.env"
  TRACE_APPEND=1
  cleanup_bot_processes
  start_chromedriver
done

echo "full_run_bot complete."
echo "Logs: $OUTPUT_DIR"
echo "Trace: $TRACE_PATH"
