import 'dart:js_interop';

@JS('navigator.vibrate')
external JSAny? get _vibrateFunction;

@JS('navigator.vibrate')
external JSBoolean _vibrate(JSNumber milliseconds);

/// Android 웹(Chrome, Samsung Internet)만 지원한다. 없으면 조용히 무시한다.
void vibrateWeb(int milliseconds) {
  try {
    if (_vibrateFunction == null) return;
    _vibrate(milliseconds.toJS);
  } catch (_) {}
}
