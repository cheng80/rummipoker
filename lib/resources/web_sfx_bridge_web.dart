import 'dart:js_interop';

void initializeWebSfx(String defaultPath) {
  try {
    _initialize(defaultPath.toJS);
  } catch (_) {}
}

void unlockWebSfx() {
  try {
    _unlock();
  } catch (_) {}
}

bool playWebSfx(String path, double volume) {
  try {
    return _play(path.toJS, volume.toJS).toDart;
  } catch (_) {
    return false;
  }
}

@JS('rummiPokerSfx.initialize')
external void _initialize(JSString defaultPath);

@JS('rummiPokerSfx.unlock')
external void _unlock();

@JS('rummiPokerSfx.play')
external JSBoolean _play(JSString path, JSNumber volume);
