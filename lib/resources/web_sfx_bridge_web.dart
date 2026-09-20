import 'dart:js_interop';

void initializeWebSfx(String path) {
  try {
    _initialize(path.toJS);
  } catch (_) {}
}

void unlockWebSfx() {
  try {
    _unlock();
  } catch (_) {}
}

bool playWebSfx(String path, double volume, double rate) {
  try {
    return _play(path.toJS, volume.toJS, rate.toJS).toDart;
  } catch (_) {
    return false;
  }
}

@JS('rummiPokerSfx.initialize')
external void _initialize(JSString path);

@JS('rummiPokerSfx.unlock')
external void _unlock();

@JS('rummiPokerSfx.play')
external JSBoolean _play(JSString path, JSNumber volume, JSNumber rate);
