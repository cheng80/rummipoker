import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import vm from 'node:vm';

const createHarness = async () => {
  const listeners = new Map();
  const document = {
    baseURI: 'https://example.test/rummipoker/',
    visibilityState: 'visible',
    addEventListener(type, listener) {
      listeners.set(type, listener);
    },
  };
  const started = [];

  class FakeAudioContext {
    constructor() {
      this.state = 'suspended';
      this.destination = {};
    }
    resume() {
      this.state = 'running';
      return Promise.resolve();
    }
    createBuffer() {
      return {};
    }
    createGain() {
      return { gain: { value: 1 }, connect() {} };
    }
    createBufferSource() {
      const source = {
        buffer: null,
        playbackRate: { value: 1 },
        onended: null,
        connect() {},
        start() {
          started.push(source);
        },
        stop() {},
      };
      return source;
    }
    decodeAudioData() {
      return Promise.resolve({ decoded: true });
    }
  }

  const fetch = async () => ({
    ok: true,
    arrayBuffer: async () => new ArrayBuffer(8),
  });

  const window = { AudioContext: FakeAudioContext };
  const source = await readFile(
    new URL('../../web/rummi_poker_sfx.js', import.meta.url),
    'utf8',
  );
  vm.runInNewContext(source, {
    URL,
    document,
    fetch,
    navigator: {},
    window,
  });
  return { sfx: window.rummiPokerSfx, document, listeners, started };
};

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

test('re-unlocks only after the page was hidden', async () => {
  const { sfx, document, listeners, started } = await createHarness();
  sfx.initialize('sfx/BtnSnd.mp3');
  await flush();
  sfx.unlock();
  sfx.unlock();
  assert.equal(sfx.getState().unlocks, 1);

  assert.ok(listeners.has('visibilitychange'));
  assert.equal(sfx.play('sfx/BtnSnd.mp3', 1, 1), true);
  // unlock 무음 버퍼 1개 + 효과음 1개
  assert.equal(started.length, 2);
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

test('applies playbackRate for pitch and clamps it', async () => {
  const { sfx, started } = await createHarness();
  sfx.initialize('sfx/Collect.mp3');
  await flush();
  sfx.unlock();
  assert.equal(sfx.play('sfx/Collect.mp3', 0.5, 1.25), true);
  assert.equal(started.at(-1).playbackRate.value, 1.25);
  assert.equal(sfx.play('sfx/Collect.mp3', 0.5, 9), true);
  assert.equal(started.at(-1).playbackRate.value, 4);
});

test('drops sounds before unlock or before decoding', async () => {
  const { sfx } = await createHarness();
  sfx.initialize('sfx/Clear.mp3');
  await flush();
  assert.equal(sfx.play('sfx/Clear.mp3', 1, 1), false);
  sfx.unlock();
  assert.equal(sfx.play('sfx/NotLoaded.mp3', 1, 1), false);
  assert.equal(sfx.getState().drops, 2);
});
