(() => {
  if (window.rummiPokerSfx) return;

  const slotCount = 4;
  const slots = Array.from({ length: slotCount }, () => ({
    audio: new Audio(),
    busy: false,
    timer: 0,
    token: 0,
  }));
  const stats = { plays: 0, drops: 0, errors: 0, unlocks: 0, lastError: '' };
  let needsUnlock = true;

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'hidden') return;
    needsUnlock = true;
    for (const slot of slots) {
      slot.token += 1;
      clearTimeout(slot.timer);
      slot.timer = 0;
      slot.busy = false;
      slot.audio.pause();
      slot.audio.currentTime = 0;
      slot.audio.onended = null;
      slot.audio.onerror = null;
    }
  });

  const resolveAsset = (path) =>
    new URL(`assets/assets/audio/${path}`, document.baseURI).href;

  const recordError = (error) => {
    stats.errors += 1;
    stats.lastError = String(error?.message || error || 'unknown audio error');
  };

  const release = (slot, token, error) => {
    if (slot.token !== token || !slot.busy) return;
    if (error) recordError(error);
    clearTimeout(slot.timer);
    slot.timer = 0;
    slot.busy = false;
    slot.audio.onended = null;
    slot.audio.onerror = null;
  };

  const initialize = (defaultPath) => {
    const url = resolveAsset(defaultPath);
    for (const slot of slots) {
      slot.audio.preload = 'auto';
      slot.audio.src = url;
      slot.audio.load();
    }
  };

  const unlock = () => {
    if (!needsUnlock) return;
    needsUnlock = false;
    stats.unlocks += 1;
    for (const slot of slots) {
      if (slot.busy) continue;
      const token = ++slot.token;
      const audio = slot.audio;
      const previousVolume = audio.volume;
      audio.volume = 0;
      audio.currentTime = 0;
      audio.play()?.then(() => {
        if (slot.token !== token || slot.busy) return;
        audio.pause();
        audio.currentTime = 0;
        audio.volume = previousVolume;
      }).catch((error) => {
        if (slot.token === token && !slot.busy) recordError(error);
      });
    }
  };

  const play = (path, volume) => {
    const slot = slots.find((candidate) => !candidate.busy);
    if (!slot) {
      stats.drops += 1;
      return false;
    }

    slot.busy = true;
    const token = ++slot.token;
    const audio = slot.audio;
    const url = resolveAsset(path);
    clearTimeout(slot.timer);
    audio.pause();
    if (audio.src !== url) {
      audio.src = url;
      audio.load();
    }
    audio.volume = Math.max(0, Math.min(1, volume));
    audio.currentTime = 0;
    audio.onended = () => release(slot, token);
    audio.onerror = () => release(slot, token, audio.error);
    slot.timer = setTimeout(() => {
      if (slot.token !== token) return;
      audio.pause();
      audio.currentTime = 0;
      release(slot, token);
    }, 8000);

    stats.plays += 1;
    audio.play()?.catch((error) => release(slot, token, error));
    return true;
  };

  const getState = () => ({
    ...stats,
    active: slots.filter((slot) => slot.busy).length,
    slots: slotCount,
  });

  window.rummiPokerSfx = Object.freeze({ initialize, unlock, play, getState });
})();
