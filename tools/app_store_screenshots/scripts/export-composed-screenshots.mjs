import { existsSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from '@playwright/test';

const toolDir = resolve(new URL('..', import.meta.url).pathname);
const nextDir = join(toolDir, '.next/server/app');
const outputRoot = join(toolDir, 'exports');
const port = Number(process.env.RUMMIPOKER_GENERATOR_EXPORT_PORT ?? 4344);
const baseUrl = `http://127.0.0.1:${port}`;

const slideIds = [
  '01-title',
  '02-battle-grid',
  '03-run-growth',
  '04-market-build',
  '05-boss-rule',
  '06-cash-out',
];
const locales = ['ko', 'en'];

function run(command, args, options = {}) {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, {
      cwd: toolDir,
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

function startNextServer() {
  const child = spawn('npx', ['next', 'start', '--port', String(port)], {
    cwd: toolDir,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  child.stdout.on('data', (data) => process.stdout.write(data));
  child.stderr.on('data', (data) => process.stderr.write(data));
  return child;
}

async function waitForServer() {
  for (let attempt = 0; attempt < 80; attempt++) {
    try {
      const response = await fetch(baseUrl);
      if (response.ok) return;
    } catch {}
    await new Promise((resolvePromise) => setTimeout(resolvePromise, 250));
  }
  throw new Error(`Timed out waiting for ${baseUrl}`);
}

async function launchBrowser() {
  try {
    return await chromium.launch({ channel: 'chrome', headless: true });
  } catch {
    return chromium.launch({ headless: true });
  }
}

await mkdir(outputRoot, { recursive: true });
if (!existsSync(nextDir)) {
  await run('npm', ['run', 'build']);
}

const server = startNextServer();
await waitForServer();
const browser = await launchBrowser();

try {
  const page = await browser.newPage({ viewport: { width: 1500, height: 3200 } });
  await page.goto(baseUrl, { waitUntil: 'networkidle' });
  for (const locale of locales) {
    const localeDir = join(outputRoot, locale);
    await mkdir(localeDir, { recursive: true });
    await page.locator('select').first().selectOption(locale);
    for (const slideId of slideIds) {
      await page.locator('select').nth(1).selectOption(slideId);
      await page.waitForTimeout(250);
      await page.locator('.canvas').screenshot({
        path: join(localeDir, `${slideId}-${locale}.png`),
      });
      console.log(`Exported ${locale}/${slideId}`);
    }
  }
} finally {
  await browser.close();
  server.kill('SIGTERM');
}

console.log(`Saved composed screenshots to ${outputRoot}`);
