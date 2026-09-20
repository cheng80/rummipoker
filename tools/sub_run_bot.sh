#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR=""
SEED="${FULL_RUN_BOT_SEED:-91460}"
MAX_BATTLE_ACTIONS="${FULL_RUN_BOT_MAX_BATTLE_ACTIONS:-420}"
MAX_GAME_OVER_RETRIES="${FULL_RUN_BOT_MAX_GAME_OVER_RETRIES:-24}"
ACTION_DELAY_MS="${FULL_RUN_BOT_ACTION_DELAY_MS:-250}"
TARGET_STAGE=1
TARGET_TIER="small"
TARGET_SCENE="cashOut"
REQUIRED_EVIDENCE=""
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
FLUTTER_DRIVE_MODE="${FULL_RUN_BOT_FLUTTER_MODE:-profile}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-4444}"
WEB_PORT="${FULL_RUN_BOT_WEB_PORT:-7357}"
BROWSER_PROFILE_DIR="${FULL_RUN_BOT_BROWSER_PROFILE_DIR:-/tmp/rummipoker_full_run_bot/chrome_profile}"
RESUME_ACTIVE_RUN=false
PUB_GET=1
CHROMEDRIVER_PID=""
PROGRESS_PORT=0

usage() {
  cat <<'EOF'
Usage:
  tools/sub_run_bot.sh [options]

Options:
  --seed <number>             Run seed. Default: 91460.
  --max-actions <number>      Max battle actions per station. Default: 420.
  --max-retries <number>      Max game-over retries per bot run. Default: 24.
  --action-delay-ms <ms>      Delay after battle actions. Default: 250.
  --target-stage <1..8>       Stop target stage. Default: 1.
  --target-tier <tier>        small | big | boss. Default: small.
  --target-scene <scene>      stationSelect | battle | cashOut | market.
                              Default: cashOut.
  --required-evidence <name>  market_purchase | item_purchase | item_use.
  --resume-active-run         Load the saved active run from the checkpoint env file.
  --browser-profile-dir <p>   Directory used for bot checkpoint env files.
                              Default: /tmp/rummipoker_full_run_bot/chrome_profile.
  --web-port <number>         Fixed Flutter web port for persisted browser storage.
                              Default: 7357.
  --output-dir <path>         Directory for logs.
  --skip-pub-get              Skip `flutter pub get`.
  -h, --help                  Show this help.

Environment:
  CHROMEDRIVER_CMD            Custom chromedriver command.
  CHROMEDRIVER_PORT           WebDriver port. Default: 4444.
  FLUTTER_BIN                 Flutter executable. Default: flutter.
  FULL_RUN_BOT_FLUTTER_MODE   debug | profile | release. Default: profile.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed)
      SEED="${2:?missing seed}"
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
    --action-delay-ms)
      ACTION_DELAY_MS="${2:?missing action delay}"
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
    --resume-active-run)
      RESUME_ACTIVE_RUN=true
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
  OUTPUT_DIR="/tmp/rummipoker_full_run_sub_run_bot/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

port_is_open() {
  nc -z 127.0.0.1 "$CHROMEDRIVER_PORT" >/dev/null 2>&1
}

case "$FLUTTER_DRIVE_MODE" in
  debug|profile|release) ;;
  *) echo "Invalid FULL_RUN_BOT_FLUTTER_MODE: $FLUTTER_DRIVE_MODE" >&2; exit 1 ;;
esac

for required_command in nc lsof; do
  command -v "$required_command" >/dev/null 2>&1 || {
    echo "$required_command is required for bot port ownership checks." >&2
    exit 1
  }
done
if [[ "$WEB_PORT" == "0" || "$CHROMEDRIVER_PORT" == "0" ||
      "$WEB_PORT" == "$CHROMEDRIVER_PORT" ||
      "${PROGRESS_PORT:-0}" == "$WEB_PORT" || "${PROGRESS_PORT:-0}" == "$CHROMEDRIVER_PORT" ]]; then
  echo "Bot ports must be distinct; only the progress port may be 0." >&2
  exit 1
fi

# Only signal live jobs started by this shell. Each helper owns and reaps a
# private process group, including descendants left behind by Flutter/Chrome.
PROCESS_HELPER="$ROOT_DIR/tools/full_run_bot_process.py"
PROFILE_OWNER="$$:$RANDOM:$RANDOM"
BROWSER_PROFILE_DIR="$(python3 "$PROCESS_HELPER" acquire "$BROWSER_PROFILE_DIR" "$PROFILE_OWNER")"

kill_pids() {
  local pid
  for pid in "$@"; do
    if jobs -pr | grep -qx "$pid"; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
  done
}

cleanup_bot_processes() {
  local pid
  for pid in "${DRIVE_PID:-}" "${CHROMEDRIVER_PID:-}" "${PROGRESS_SERVER_PID:-}" "${PUB_GET_PID:-}"; do
    [[ -z "$pid" ]] || kill_pids "$pid"
  done
  DRIVE_PID=""
  CHROMEDRIVER_PID=""
  PROGRESS_SERVER_PID=""
  PUB_GET_PID=""
}

cleanup() {
  cleanup_bot_processes
  python3 "$PROCESS_HELPER" release "$BROWSER_PROFILE_DIR" "$PROFILE_OWNER"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# Reject external listeners; a port number never establishes ownership.
for port in "$WEB_PORT" "$CHROMEDRIVER_PORT" "${PROGRESS_PORT:-0}"; do
  if [[ ! "$port" =~ ^(0|[1-9][0-9]{0,4})$ ]] || (( 10#$port > 65535 )); then
    echo "Invalid bot port: $port" >&2
    exit 1
  fi
  if [[ "$port" != "0" ]] && { nc -z 127.0.0.1 "$port" >/dev/null 2>&1 || nc -z ::1 "$port" >/dev/null 2>&1; }; then
    echo "Bot port already in use: $port" >&2
    exit 1
  fi
done

start_chromedriver() {
  if port_is_open; then
    echo "WebDriver port already in use: $CHROMEDRIVER_PORT" >&2
    exit 1
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
  python3 "$PROCESS_HELPER" run "${cmd[@]}" --port="$CHROMEDRIVER_PORT" \
    >"$OUTPUT_DIR/chromedriver.log" 2>&1 &
  CHROMEDRIVER_PID=$!

  for _ in {1..30}; do
    if ! kill -0 "$CHROMEDRIVER_PID" 2>/dev/null; then
      echo "chromedriver exited before startup. Log: $OUTPUT_DIR/chromedriver.log" >&2
      exit 1
    fi
    if port_is_open; then
      if ! python3 "$PROCESS_HELPER" owns-port "$CHROMEDRIVER_PID" "$CHROMEDRIVER_PORT"; then
        echo "WebDriver listener is not owned by this run: $CHROMEDRIVER_PORT" >&2
        exit 1
      fi
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
  awk 'NF {path=$NF} END {print path}' "$install_log"
}

run_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  python3 "$PROCESS_HELPER" run "$@" > >(tee "$log_file") 2>&1 &
  PUB_GET_PID=$!
  wait "$PUB_GET_PID"
  PUB_GET_PID=""
}

run_flutter_drive_and_capture() {
  local log_file="$1"
  shift
  echo "Running: $*"
  set +e
  python3 "$PROCESS_HELPER" run "$@" > >(tee "$log_file") 2>&1 &
  local run_pid=$!
  DRIVE_PID="$run_pid"

  while kill -0 "$run_pid" 2>/dev/null; do
    if grep -q "All tests passed!" "$log_file" 2>/dev/null; then
      persist_checkpoint "$log_file"
      sleep 3
      if kill -0 "$run_pid" 2>/dev/null; then
        echo "Detected pass; cleaning up lingering flutter drive session." \
          | tee -a "$log_file"
        cleanup_bot_processes
      fi
      set -e
      return 0
    fi
    sleep 2
  done

  wait "$run_pid"
  local status=$?
  DRIVE_PID=""
  persist_checkpoint "$log_file"
  cleanup_bot_processes
  set -e
  if [[ "$status" -ne 0 ]] && grep -q "All tests passed!" "$log_file" 2>/dev/null; then
    return 0
  fi
  return "$status"
}

persist_checkpoint() {
  local log_file="$1"
  local checkpoint
  checkpoint="$(grep -a 'FULL_RUN_BOT_CHECKPOINT_B64:' "$log_file" 2>/dev/null \
    | tail -1 | sed 's/^.*FULL_RUN_BOT_CHECKPOINT_B64://')"
  if [[ -z "$checkpoint" ]]; then
    return
  fi
  mkdir -p "$BROWSER_PROFILE_DIR"
  printf 'FULL_RUN_BOT_RESUME_SAVE_B64=%s\n' "$checkpoint" \
    >"$BROWSER_PROFILE_DIR/latest_checkpoint.env"
}

export FULL_RUN_BOT_BROWSER_PROFILE_DIR="$BROWSER_PROFILE_DIR"

echo "Output: $OUTPUT_DIR"
if [[ "$RESUME_ACTIVE_RUN" != "true" ]]; then
  rm -rf "$BROWSER_PROFILE_DIR/chrome"
  rm -f "$BROWSER_PROFILE_DIR/latest_checkpoint.env"
fi
start_chromedriver
mkdir -p "$BROWSER_PROFILE_DIR"
RESUME_DEFINE_ARG=""
if [[ "$RESUME_ACTIVE_RUN" == "true" && -f "$BROWSER_PROFILE_DIR/latest_checkpoint.env" ]]; then
  RESUME_DEFINE_ARG="--dart-define-from-file=$BROWSER_PROFILE_DIR/latest_checkpoint.env"
fi

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/00_pub_get.log" "$FLUTTER_BIN" pub get
fi

run_flutter_drive_and_capture "$OUTPUT_DIR/10_sub_run_bot.log" \
  "$FLUTTER_BIN" drive \
    --"$FLUTTER_DRIVE_MODE" \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/full_run_bot_test.dart \
    -d web-server \
    --no-start-paused \
    --web-launch-url="http://127.0.0.1:$WEB_PORT/" \
    --web-browser-flag="--user-data-dir=$BROWSER_PROFILE_DIR/chrome" \
    --headless \
    --no-dds \
    --web-port="$WEB_PORT" \
    --driver-port="$CHROMEDRIVER_PORT" \
    --no-keep-app-running \
    ${RESUME_DEFINE_ARG:+"$RESUME_DEFINE_ARG"} \
    --dart-define=FULL_RUN_BOT_MODE=sub \
    --dart-define=FULL_RUN_BOT_SEED="$SEED" \
    --dart-define=FULL_RUN_BOT_MAX_BATTLE_ACTIONS="$MAX_BATTLE_ACTIONS" \
    --dart-define=FULL_RUN_BOT_MAX_GAME_OVER_RETRIES="$MAX_GAME_OVER_RETRIES" \
    --dart-define=FULL_RUN_BOT_ACTION_DELAY_MS="$ACTION_DELAY_MS" \
    --dart-define=FULL_RUN_BOT_RESUME_ACTIVE_RUN="$RESUME_ACTIVE_RUN" \
    --dart-define=FULL_RUN_BOT_TARGET_STAGE="$TARGET_STAGE" \
    --dart-define=FULL_RUN_BOT_TARGET_TIER="$TARGET_TIER" \
    --dart-define=FULL_RUN_BOT_TARGET_SCENE="$TARGET_SCENE" \
    --dart-define=FULL_RUN_BOT_REQUIRED_EVIDENCE="$REQUIRED_EVIDENCE"

echo "sub_run_bot complete."
echo "Logs: $OUTPUT_DIR"
