#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-8791}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="$ROOT_DIR"
BUILD_DIR="$ROOT_DIR/rummipoker"
URL="http://127.0.0.1:${PORT}/rummipoker/"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "rummipoker/ 폴더가 없습니다."
  echo "먼저 아래 명령으로 웹 빌드를 생성하세요:"
  echo '  flutter build web --release --base-href "/rummipoker/"'
  echo '  mkdir -p rummipoker && cp -R build/web/. rummipoker/'
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3를 찾을 수 없습니다. macOS Command Line Tools 또는 Python 3 설치가 필요합니다."
  exit 1
fi

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "포트 ${PORT}가 이미 사용 중입니다."
  echo "브라우저 저장소는 포트별로 분리되므로 자동으로 다른 포트를 쓰지 않습니다."
  echo "기존 서버를 종료하거나 같은 URL로 접속하세요:"
  echo "  $URL"
  exit 1
fi

echo "RummiPoker local web server"
echo "URL: $URL"
echo "종료: Ctrl+C"
cd "$SERVE_DIR"
python3 -m http.server "$PORT" --bind 127.0.0.1
