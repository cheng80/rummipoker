import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import vm from 'node:vm';

test('re-unlocks only after the page was hidden', async () => {
  const listeners = new Map();
  const document = {
    baseURI: 'https://example.test/rummipoker/',
    visibilityState: 'visible',
    addEventListener(type, listener) {
      listeners.set(type, listener);
    },
  };

  class FakeAudio {
    load() {}
    pause() {}
    play() {
      return Promise.resolve();
    }
  }

  const window = {};
  const source = await readFile(
    new URL('../../web/rummi_poker_sfx.js', import.meta.url),
    'utf8',
  );
  vm.runInNewContext(source, {
    Audio: FakeAudio,
    URL,
    clearTimeout,
    document,
    setTimeout,
    window,
  });

  const sfx = window.rummiPokerSfx;
  sfx.initialize('sfx/BtnSnd.mp3');
  sfx.unlock();
  sfx.unlock();
  assert.equal(sfx.getState().unlocks, 1);

  assert.ok(listeners.has('visibilitychange'));
  assert.equal(sfx.play('sfx/BtnSnd.mp3', 1), true);
  assert.equal(sfx.getState().active, 1);
  document.visibilityState = 'hidden';
  listeners.get('visibilitychange')();
  assert.equal(sfx.getState().active, 0);

  document.visibilityState = 'visible';
  listeners.get('visibilitychange')();
  sfx.unlock();
  sfx.unlock();
  assert.equal(sfx.getState().unlocks, 2);
});
