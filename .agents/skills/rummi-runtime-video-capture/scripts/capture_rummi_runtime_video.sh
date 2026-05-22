#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
ROUTE="/game?fixture=special_tile_battle_preview&debug_suppress_fixture_notice=1"
OUTPUT_DIR="$ROOT_DIR/logs/runtime_videos"
NAME="runtime_capture"
PORT="18744"
VIEWPORT="390,844"
INITIAL_WAIT_MS="4500"
CLICKS=""
SKIP_BUILD="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --route)
      ROUTE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --viewport)
      VIEWPORT="$2"
      shift 2
      ;;
    --initial-wait-ms)
      INITIAL_WAIT_MS="$2"
      shift 2
      ;;
    --clicks)
      CLICKS="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD="true"
      shift
      ;;
    -h|--help)
      cat <<'USAGE'
Usage:
  capture_rummi_runtime_video.sh [options]

Options:
  --route <route>              Flutter route. Default special tile battle fixture.
  --output-dir <dir>           Output dir. Default logs/runtime_videos.
  --name <basename>            Output basename. Default runtime_capture.
  --port <port>                Static server port. Default 18744.
  --viewport <w,h>             Browser viewport. Default 390,844.
  --initial-wait-ms <ms>       Wait after navigation. Default 4500.
  --clicks "x,y,ms;..."        Click sequence with wait after each click.
  --skip-build                 Reuse existing build/web.

Example:
  .agents/skills/rummi-runtime-video-capture/scripts/capture_rummi_runtime_video.sh \
    --route "/game?fixture=special_tile_battle_preview&debug_suppress_fixture_notice=1" \
    --name special_tile_effect_validation \
    --clicks "195,461,1200;335,668,8500"
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

if [[ "$SKIP_BUILD" != "true" ]]; then
  flutter build web --dart-define=SHOW_DEBUG_FIXTURES=true
fi

if lsof -ti "tcp:$PORT" >/dev/null 2>&1; then
  lsof -ti "tcp:$PORT" | xargs -r kill
fi

SERVER_LOG="$OUTPUT_DIR/${NAME}_server.log"
python3 - "$PORT" "$ROOT_DIR/build/web" >"$SERVER_LOG" 2>&1 <<'PY' &
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import os
import sys

port = int(sys.argv[1])
root = Path(sys.argv[2])
os.chdir(root)

class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        raw_path = self.path.split('?', 1)[0]
        path = self.translate_path(raw_path)
        if raw_path.startswith('/game') and (not os.path.exists(path) or os.path.isdir(path)):
            self.path = '/index.html'
        return super().do_GET()

server = ThreadingHTTPServer(('127.0.0.1', port), Handler)
server.serve_forever()
PY
SERVER_PID="$!"
TMP_DIR=""

cleanup() {
  kill "$SERVER_PID" >/dev/null 2>&1 || true
  wait "$SERVER_PID" 2>/dev/null || true
  if [[ -n "${TMP_DIR:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

for _ in {1..50}; do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

TMP_DIR="$(mktemp -d /tmp/rummi_playwright_video.XXXXXX)"
pushd "$TMP_DIR" >/dev/null
npm init -y >/dev/null
npm install playwright@1.60.0 >/dev/null

cat > capture.cjs <<'NODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const route = process.env.RUMMI_CAPTURE_ROUTE;
const outputDir = process.env.RUMMI_CAPTURE_OUTPUT_DIR;
const name = process.env.RUMMI_CAPTURE_NAME;
const port = process.env.RUMMI_CAPTURE_PORT;
const [width, height] = process.env.RUMMI_CAPTURE_VIEWPORT.split(',').map(Number);
const initialWaitMs = Number(process.env.RUMMI_CAPTURE_INITIAL_WAIT_MS);
const clicks = process.env.RUMMI_CAPTURE_CLICKS
  ? process.env.RUMMI_CAPTURE_CLICKS.split(';').filter(Boolean).map((raw) => {
      const [x, y, waitAfterMs] = raw.split(',').map(Number);
      return { x, y, waitAfterMs };
    })
  : [];

(async () => {
  fs.mkdirSync(outputDir, { recursive: true });
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: 1,
    recordVideo: { dir: outputDir, size: { width, height } },
  });
  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${port}${route}`, {
    waitUntil: 'domcontentloaded',
  });
  await page.waitForTimeout(initialWaitMs);
  await page.screenshot({ path: path.join(outputDir, `${name}_before.png`) });
  for (const click of clicks) {
    await page.mouse.click(click.x, click.y);
    await page.waitForTimeout(click.waitAfterMs);
  }
  await page.screenshot({ path: path.join(outputDir, `${name}_after.png`) });
  const video = page.video();
  await context.close();
  await browser.close();
  if (!video) throw new Error('No Playwright video object created');
  const original = await video.path();
  const webm = path.join(outputDir, `${name}.webm`);
  fs.copyFileSync(original, webm);
  if (original !== webm) {
    fs.unlinkSync(original);
  }
  console.log(webm);
})();
NODE

RUMMI_CAPTURE_ROUTE="$ROUTE" \
RUMMI_CAPTURE_OUTPUT_DIR="$OUTPUT_DIR" \
RUMMI_CAPTURE_NAME="$NAME" \
RUMMI_CAPTURE_PORT="$PORT" \
RUMMI_CAPTURE_VIEWPORT="$VIEWPORT" \
RUMMI_CAPTURE_INITIAL_WAIT_MS="$INITIAL_WAIT_MS" \
RUMMI_CAPTURE_CLICKS="$CLICKS" \
node capture.cjs
popd >/dev/null

WEBM="$OUTPUT_DIR/$NAME.webm"
MP4="$OUTPUT_DIR/$NAME.mp4"
if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y -i "$WEBM" -vf "fps=30,format=yuv420p" -movflags +faststart "$MP4" >/dev/null 2>&1
fi

echo "Saved:"
echo "  $WEBM"
if [[ -f "$MP4" ]]; then
  echo "  $MP4"
fi
echo "  $OUTPUT_DIR/${NAME}_before.png"
echo "  $OUTPUT_DIR/${NAME}_after.png"
