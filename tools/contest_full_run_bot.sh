#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR=""
SEED="${CONTEST_BOT_SEED:-91460}"
MAX_BATTLE_ACTIONS="${CONTEST_BOT_MAX_BATTLE_ACTIONS:-420}"
MAX_GAME_OVER_RETRIES="${CONTEST_BOT_MAX_GAME_OVER_RETRIES:-24}"
ACTION_DELAY_MS="${CONTEST_BOT_ACTION_DELAY_MS:-250}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-4444}"
WEB_PORT="${CONTEST_BOT_WEB_PORT:-7357}"
BROWSER_PROFILE_DIR="${CONTEST_BOT_BROWSER_PROFILE_DIR:-/tmp/rummipoker_contest_bot/chrome_profile}"
RESUME_ACTIVE_RUN=false
PUB_GET=1

usage() {
  cat <<'EOF'
Usage:
  tools/contest_full_run_bot.sh [options]

Options:
  --seed <number>           Run seed. Default: 91460.
  --max-actions <number>    Max battle actions per station. Default: 420.
  --max-retries <number>    Max game-over retries per bot run. Default: 24.
  --action-delay-ms <ms>    Delay after battle actions. Default: 250.
  --resume-active-run       Load the saved active run from the checkpoint env file.
  --browser-profile-dir <p> Directory used for bot checkpoint env files.
                            Default: /tmp/rummipoker_contest_bot/chrome_profile.
  --web-port <number>       Fixed Flutter web port for persisted browser storage.
                            Default: 7357.
  --output-dir <path>       Directory for logs.
  --skip-pub-get            Skip `flutter pub get`.
  -h, --help                Show this help.

Environment:
  CHROMEDRIVER_CMD          Custom chromedriver command.
  CHROMEDRIVER_PORT         WebDriver port. Default: 4444.
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
  OUTPUT_DIR="/tmp/rummipoker_contest_full_run_bot/$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$OUTPUT_DIR"

port_is_open() {
  nc -z 127.0.0.1 "$CHROMEDRIVER_PORT" >/dev/null 2>&1
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
  trap '[[ -n "${CHROMEDRIVER_PID:-}" ]] && kill "$CHROMEDRIVER_PID" 2>/dev/null || true' EXIT

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
  awk 'NF {path=$NF} END {print path}' "$install_log"
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
      persist_checkpoint "$log_file"
      sleep 3
      if kill -0 "$run_pid" 2>/dev/null; then
        echo "Detected pass; cleaning up lingering flutter drive session." \
          | tee -a "$log_file"
        pkill -f 'flutter drive.*integration_test/competition_full_play_bot_test.dart' \
          2>/dev/null || true
        pkill -f 'flutter_tools_chrome_device' 2>/dev/null || true
        lsof -ti tcp:"$WEB_PORT" | xargs -r kill 2>/dev/null || true
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
  lsof -ti tcp:"$WEB_PORT" | xargs -r kill 2>/dev/null || true
  set -e
  if [[ "$status" -ne 0 ]] && grep -q "All tests passed!" "$log_file" 2>/dev/null; then
    return 0
  fi
  return "$status"
}

persist_checkpoint() {
  local log_file="$1"
  local checkpoint
  checkpoint="$(grep -a 'CONTEST_BOT_CHECKPOINT_B64:' "$log_file" 2>/dev/null \
    | tail -1 | sed 's/^.*CONTEST_BOT_CHECKPOINT_B64://')"
  if [[ -z "$checkpoint" ]]; then
    return
  fi
  mkdir -p "$BROWSER_PROFILE_DIR"
  printf 'CONTEST_BOT_RESUME_SAVE_B64=%s\n' "$checkpoint" \
    >"$BROWSER_PROFILE_DIR/latest_checkpoint.env"
}

echo "Output: $OUTPUT_DIR"
start_chromedriver
mkdir -p "$BROWSER_PROFILE_DIR"
RESUME_DEFINE_ARG=""
if [[ "$RESUME_ACTIVE_RUN" == "true" && -f "$BROWSER_PROFILE_DIR/latest_checkpoint.env" ]]; then
  RESUME_DEFINE_ARG="--dart-define-from-file=$BROWSER_PROFILE_DIR/latest_checkpoint.env"
fi

if [[ "$PUB_GET" -eq 1 ]]; then
  run_and_capture "$OUTPUT_DIR/00_pub_get.log" flutter pub get
fi

run_flutter_drive_and_capture "$OUTPUT_DIR/10_contest_full_run_bot.log" \
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/competition_full_play_bot_test.dart \
    -d chrome \
    --web-port="$WEB_PORT" \
    --driver-port="$CHROMEDRIVER_PORT" \
    --no-keep-app-running \
    ${RESUME_DEFINE_ARG:+"$RESUME_DEFINE_ARG"} \
    --dart-define=CONTEST_BOT_MODE=full \
    --dart-define=CONTEST_BOT_SEED="$SEED" \
    --dart-define=CONTEST_BOT_MAX_BATTLE_ACTIONS="$MAX_BATTLE_ACTIONS" \
    --dart-define=CONTEST_BOT_MAX_GAME_OVER_RETRIES="$MAX_GAME_OVER_RETRIES" \
    --dart-define=CONTEST_BOT_ACTION_DELAY_MS="$ACTION_DELAY_MS" \
    --dart-define=CONTEST_BOT_RESUME_ACTIVE_RUN="$RESUME_ACTIVE_RUN"

echo "contest_full_run_bot complete."
echo "Logs: $OUTPUT_DIR"
