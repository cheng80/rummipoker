import { createServer } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { extname, join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from '@playwright/test';

const toolDir = resolve(new URL('..', import.meta.url).pathname);
const repoRoot = resolve(toolDir, '../..');
const buildDir = join(repoRoot, 'build/web');
const outputRoot = join(toolDir, 'public/screenshots');
const port = Number(process.env.RUMMIPOKER_SCREENSHOT_PORT ?? 7394);
const baseUrl = `http://127.0.0.1:${port}`;
const phoneFrame = { width: 390, height: 750 };

const scenes = [
  { id: '01-title', path: '/new-run', waitMs: 2500 },
  {
    id: '02-battle-grid',
    path: '/game?fixture=stage2_scoring_snapshot&debug_suppress_fixture_notice=1',
    waitMs: 4200,
  },
  {
    id: '03-run-growth',
    path:
      '/game?fixture=screenshot_run_growth_battle&debug_open_run_info=1&debug_suppress_fixture_notice=1',
    waitMs: 4600,
  },
  {
    id: '04-market-build',
    path: '/game?fixture=market_modifier_shop&debug_suppress_fixture_notice=1',
    waitMs: 5200,
  },
  {
    id: '05-boss-rule',
    path:
      '/game?fixture=boss_row_constraint_preview&debug_suppress_fixture_notice=1',
    waitMs: 4200,
  },
  {
    id: '06-cash-out',
    path:
      '/game?fixture=final_boss_cash_out_ready&auto_cashout_loop=1&debug_suppress_fixture_notice=1',
    waitMs: 5600,
  },
];

const locales = [
  { id: 'ko', browserLocale: 'ko-KR' },
  { id: 'en', browserLocale: 'en-US' },
];

function run(command, args, options = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, {
      cwd: repoRoot,
      stdio: 'inherit',
      shell: false,
      ...options,
    });
    child.on('error', reject);
    child.on('exit', (code) => {
      if (code === 0) {
        resolvePromise();
        return;
      }
      reject(new Error(`${command} ${args.join(' ')} exited with ${code}`));
    });
  });
}

function contentType(filePath) {
  switch (extname(filePath)) {
    case '.html':
      return 'text/html; charset=utf-8';
    case '.js':
      return 'text/javascript; charset=utf-8';
    case '.css':
      return 'text/css; charset=utf-8';
    case '.json':
      return 'application/json; charset=utf-8';
    case '.png':
      return 'image/png';
    case '.svg':
      return 'image/svg+xml';
    case '.wasm':
      return 'application/wasm';
    default:
      return 'application/octet-stream';
  }
}

function startStaticServer() {
  const server = createServer((request, response) => {
    const url = new URL(request.url ?? '/', baseUrl);
    const cleanPath = decodeURIComponent(url.pathname).replace(/^\/+/, '');
    let filePath = join(buildDir, cleanPath);
    if (!existsSync(filePath) || statSync(filePath).isDirectory()) {
      filePath = join(buildDir, 'index.html');
    }
    response.writeHead(200, { 'Content-Type': contentType(filePath) });
    createReadStream(filePath).pipe(response);
  });

  return new Promise((resolvePromise, reject) => {
    server.on('error', reject);
    server.listen(port, '127.0.0.1', () => resolvePromise(server));
  });
}

async function launchBrowser() {
  try {
    return await chromium.launch({ channel: 'chrome', headless: true });
  } catch {
    return chromium.launch({ headless: true });
  }
}

await mkdir(outputRoot, { recursive: true });
console.log('Building Flutter web with screenshot fixtures enabled...');
await run('flutter', [
  'build',
  'web',
  '--release',
  '--base-href=/',
  '--dart-define=SHOW_DEBUG_FIXTURES=true',
]);

const server = await startStaticServer();
const browser = await launchBrowser();

try {
  for (const locale of locales) {
    const localeDir = join(outputRoot, locale.id);
    await mkdir(localeDir, { recursive: true });
    const context = await browser.newContext({
      locale: locale.browserLocale,
      viewport: phoneFrame,
      deviceScaleFactor: 3,
      isMobile: true,
      hasTouch: true,
    });
    const page = await context.newPage();
    for (const scene of scenes) {
      const target = `${baseUrl}${scene.path}`;
      console.log(`Capturing ${locale.id}/${scene.id}: ${target}`);
      await page.goto(target, { waitUntil: 'networkidle' });
      await page.waitForTimeout(scene.waitMs);
      await page.screenshot({
        path: join(localeDir, `${scene.id}.png`),
        clip: { x: 0, y: 0, ...phoneFrame },
        fullPage: false,
        captureBeyondViewport: false,
      });
    }
    await context.close();
  }
} finally {
  await browser.close();
  await new Promise((resolvePromise) => server.close(resolvePromise));
}

console.log(`Saved raw screenshots to ${outputRoot}`);
