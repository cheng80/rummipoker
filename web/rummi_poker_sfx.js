(() => {
  if (window.rummiPokerSfx) return;

  // Web Audio 하나로 효과음을 재생한다. AudioBufferSourceNode.playbackRate는
  // 음높이 보정 없이 재생 속도를 바꾸므로 pitch 변주가 된다.
  // HTMLAudioElement의 rate는 음높이를 유지해 쓰지 않는다.
  const maxActive = 8;
  const stats = { plays: 0, drops: 0, errors: 0, unlocks: 0, lastError: '' };
  const buffers = new Map();
  const loading = new Map();
  const active = new Set();
  let context = null;
  let needsUnlock = true;

  const recordError = (error) => {
    stats.errors += 1;
    stats.lastError = String(error?.message || error || 'unknown audio error');
  };

  const getContext = () => {
    if (context) return context;
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioContextClass) return null;
    try {
      // iOS 무음 스위치에서도 BGM(HTMLAudio)과 같은 경로로 들리게 한다.
      if (navigator.audioSession) navigator.audioSession.type = 'playback';
    } catch (error) {
      recordError(error);
    }
    context = new AudioContextClass();
    return context;
  };

  const stopAll = () => {
    for (const source of active) {
      try {
        source.onended = null;
        source.stop();
      } catch (_) {}
    }
    active.clear();
  };

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'hidden') return;
    needsUnlock = true;
    stopAll();
  });

  const resolveAsset = (path) =>
    new URL(`assets/assets/audio/${path}`, document.baseURI).href;

  const load = (path) => {
    if (buffers.has(path)) return Promise.resolve(buffers.get(path));
    if (loading.has(path)) return loading.get(path);
    const ctx = getContext();
    if (!ctx) return Promise.resolve(null);
    const request = fetch(resolveAsset(path))
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status} ${path}`);
        return response.arrayBuffer();
      })
      .then((data) => ctx.decodeAudioData(data))
      .then((buffer) => {
        buffers.set(path, buffer);
        return buffer;
      })
      .catch((error) => {
        recordError(error);
        return null;
      })
      .finally(() => loading.delete(path));
    loading.set(path, request);
    return request;
  };

  // 앱 시작 때 효과음을 미리 디코딩한다. 여러 번 불러도 한 번만 받는다.
  const initialize = (path) => {
    load(path);
  };

  // 사용자 제스처 안에서 동기로 불러야 한다. setTimeout을 거치면 iOS가 막는다.
  const unlock = () => {
    if (!needsUnlock) return;
    const ctx = getContext();
    if (!ctx) return;
    needsUnlock = false;
    stats.unlocks += 1;
    try {
      const resumed = ctx.resume?.();
      resumed?.catch?.(recordError);
      // iOS는 무음 버퍼를 한 번 재생해야 출력이 열린다.
      const silent = ctx.createBufferSource();
      silent.buffer = ctx.createBuffer(1, 1, 22050);
      silent.connect(ctx.destination);
      silent.start(0);
    } catch (error) {
      recordError(error);
    }
  };

  const play = (path, volume, rate = 1) => {
    const ctx = getContext();
    const buffer = buffers.get(path);
    // resume()은 비동기라 같은 제스처의 첫 소리는 suspended에서 예약되고 곧 재생된다.
    if (!ctx || ctx.state === 'closed' || needsUnlock || !buffer) {
      if (!buffer) load(path);
      stats.drops += 1;
      return false;
    }
    if (active.size >= maxActive) {
      stats.drops += 1;
      return false;
    }
    try {
      const source = ctx.createBufferSource();
      source.buffer = buffer;
      source.playbackRate.value = Math.max(0.25, Math.min(4, rate));
      const gain = ctx.createGain();
      gain.gain.value = Math.max(0, Math.min(1, volume));
      source.connect(gain);
      gain.connect(ctx.destination);
      source.onended = () => active.delete(source);
      active.add(source);
      source.start(0);
      stats.plays += 1;
      return true;
    } catch (error) {
      recordError(error);
      return false;
    }
  };

  const getState = () => ({
    ...stats,
    active: active.size,
    loaded: buffers.size,
    contextState: context?.state ?? 'none',
  });

  window.rummiPokerSfx = Object.freeze({ initialize, unlock, play, getState });
})();
