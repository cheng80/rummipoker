#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="$ROOT_DIR/.env"
DEPLOY_URL="${RUMMIPOKER_DEPLOY_URL:-}"
DEPLOY_TOKEN="${RUMMIPOKER_DEPLOY_TOKEN:-}"
BASE_HREF="/rummipoker/"
PACKAGE_DIR="$ROOT_DIR/rummipoker"
ZIP_PATH="$ROOT_DIR/rummipoker.zip"
SHOW_DEBUG_FIXTURES=false
CURRENT_STEP="startup"
TOTAL_STEPS=6

usage() {
  cat <<'EOF'
Usage:
  tools/deploy_rummipoker_web.sh [options]

Options:
  --env-file <path>      Env file path. Default: .env
  --deploy-url <url>     Override RUMMIPOKER_DEPLOY_URL
  --token <token>        Override RUMMIPOKER_DEPLOY_TOKEN
  --debug-fixtures       Build with SHOW_DEBUG_FIXTURES=true for QA
  -h, --help             Show this help.

Required env:
  RUMMIPOKER_DEPLOY_URL=https://cheng80.myqnapcloud.com/deploy_rummipoker.php
  RUMMIPOKER_DEPLOY_TOKEN=<same token as /share/Web/.rummipoker_deploy.env>

Flow:
  1. flutter build web --release --base-href "/rummipoker/"
  2. Remove local rummipoker/ package directory if it exists.
  3. Copy build/web/* into local rummipoker/.
  4. Create rummipoker.zip.
  5. Upload the zip to NAS deploy PHP.
EOF
}

log_step() {
  local step_number="$1"
  local message="$2"
  CURRENT_STEP="$message"
  echo
  echo "[$step_number/$TOTAL_STEPS] $message"
}

log_info() {
  echo "  - $*"
}

fail() {
  local message="$1"
  echo
  echo "ERROR at step: $CURRENT_STEP" >&2
  echo "$message" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  echo
  echo "ERROR at step: $CURRENT_STEP" >&2
  echo "Command failed with exit code $exit_code." >&2
  exit "$exit_code"
}

trap on_error ERR

load_env_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] || return 0

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    [[ "$line" == *"="* ]] || continue

    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"

    case "$key" in
      RUMMIPOKER_DEPLOY_URL)
        if [[ -z "${RUMMIPOKER_DEPLOY_URL:-}" && -z "$DEPLOY_URL" ]]; then
          DEPLOY_URL="$value"
        fi
        ;;
      RUMMIPOKER_DEPLOY_TOKEN)
        if [[ -z "${RUMMIPOKER_DEPLOY_TOKEN:-}" && -z "$DEPLOY_TOKEN" ]]; then
          DEPLOY_TOKEN="$value"
        fi
        ;;
    esac
  done < "$file_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      ENV_FILE="${2:?missing env file path}"
      shift 2
      ;;
    --deploy-url)
      DEPLOY_URL="${2:?missing deploy url}"
      shift 2
      ;;
    --token)
      DEPLOY_TOKEN="${2:?missing deploy token}"
      shift 2
      ;;
    --debug-fixtures)
      SHOW_DEBUG_FIXTURES=true
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

load_env_file "$ENV_FILE"

log_step 1 "환경 설정 확인"
log_info "env file: $ENV_FILE"

if [[ -z "$DEPLOY_URL" ]]; then
  fail "RUMMIPOKER_DEPLOY_URL is required. Set it in $ENV_FILE or pass --deploy-url."
fi
log_info "deploy URL: $DEPLOY_URL"

if [[ -z "$DEPLOY_TOKEN" ]]; then
  fail "RUMMIPOKER_DEPLOY_TOKEN is required. Set it in $ENV_FILE or pass --token."
fi

if [[ "$DEPLOY_TOKEN" == "replace_with_output_of_openssl_rand_hex_32" ]]; then
  fail "RUMMIPOKER_DEPLOY_TOKEN still has the placeholder value. Generate a real token with: openssl rand -hex 32"
fi
log_info "deploy token: configured (${#DEPLOY_TOKEN} chars)"

if ! command -v flutter >/dev/null 2>&1; then
  fail "flutter command not found."
fi
log_info "flutter: $(command -v flutter)"

if ! command -v zip >/dev/null 2>&1; then
  fail "zip command not found."
fi
log_info "zip: $(command -v zip)"

if ! command -v curl >/dev/null 2>&1; then
  fail "curl command not found."
fi
log_info "curl: $(command -v curl)"

log_step 2 "Flutter 웹 릴리즈 빌드"
log_info "base href: $BASE_HREF"
build_args=(web --release --base-href "$BASE_HREF")
if [[ "$SHOW_DEBUG_FIXTURES" == true ]]; then
  build_args+=(--dart-define=SHOW_DEBUG_FIXTURES=true)
  log_info "debug fixtures: enabled"
fi
flutter build "${build_args[@]}"

log_step 3 "로컬 rummipoker 폴더 재생성"
log_info "package directory: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"
cp -R build/web/. "$PACKAGE_DIR/"
log_info "copied build/web into rummipoker/"

log_step 4 "zip 압축"
log_info "zip path: $ZIP_PATH"
rm -f "$ZIP_PATH"
zip -qry "$ZIP_PATH" "$(basename "$PACKAGE_DIR")"
zip_size="$(du -h "$ZIP_PATH" | awk '{print $1}')"
log_info "zip size: $zip_size"

log_step 5 "NAS 업로드 및 서버 배포"
response_file="$(mktemp)"
cleanup_response_file() {
  rm -f "$response_file"
}
trap cleanup_response_file EXIT

log_info "uploading: $ZIP_PATH"
http_code="$(
  curl -sS \
    -o "$response_file" \
    -w "%{http_code}" \
    -X POST "$DEPLOY_URL" \
    -H "X-Deploy-Token: $DEPLOY_TOKEN" \
    -F "file=@$ZIP_PATH;type=application/zip"
)"

log_info "HTTP $http_code"
cat "$response_file"
echo
cleanup_response_file
trap - EXIT

if [[ "$http_code" != "200" ]]; then
  fail "Deploy failed. Review the HTTP status and JSON response above."
fi

log_step 6 "배포 결과 확인"
log_info "server response: OK"
log_info "public URL: https://cheng80.myqnapcloud.com/rummipoker/"
log_info "local package: $PACKAGE_DIR"
log_info "local zip: $ZIP_PATH"

echo
echo "Deploy complete."
