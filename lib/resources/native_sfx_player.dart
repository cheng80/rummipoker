import 'dart:async';
import 'dart:typed_data';

/// 실제 엔진과 분리한 짧은 효과음의 캐시·수명주기 계약.
abstract interface class NativeSfxEngine {
  Future<void> initialize(int maxVoices);
  Future<Object> load(String path, Uint8List bytes);
  int playPaused(Object source, double volume);
  void setRate(int handle, double rate);
  void setPaused(int handle, bool paused);
  void setVolume(int handle, double volume);
  bool isValid(int handle);
  Future<void> stop(int handle);
  Future<void> dispose();
}

class NativeSfxPlayer {
  NativeSfxPlayer({
    required this.engine,
    required this.loadAsset,
    required this.log,
    this.maxVoices = 32,
    this.initializationTimeout = const Duration(seconds: 8),
  });

  final NativeSfxEngine engine;
  final Future<Uint8List> Function(String path) loadAsset;
  final void Function(String message, Object error) log;
  final int maxVoices;
  final Duration initializationTimeout;
  final Map<String, Object> _sources = {};
  final Set<int> _voices = {};
  Future<void>? _initializing;
  Future<void>? _disposing;
  Timer? _cleanup;
  bool _ready = false;
  bool _suspended = false;
  bool _muted = false;
  int _generation = 0;

  bool get isReady => _ready;
  int get cachedSourceCount => _sources.length;
  Set<int> get activeHandles => Set.unmodifiable(_voices);

  Future<void> initialize(Iterable<String> paths) {
    if (_ready) return Future.value();
    return _initializing ??= _initialize(paths.toList()).whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initialize(List<String> paths) async {
    final generation = ++_generation;
    await _disposing;
    if (generation != _generation) return;
    try {
      await (() async {
        await engine.initialize(maxVoices);
        for (final path in paths.toSet()) {
          if (generation != _generation) return;
          final bytes = await loadAsset(path);
          if (generation != _generation) return;
          final source = await engine.load(path, bytes);
          if (generation != _generation) return;
          _sources[path] = source;
        }
        if (generation == _generation) _ready = true;
      })().timeout(initializationTimeout);
    } catch (error) {
      log('Native SFX initialization failed; resume/preload can retry', error);
      await dispose();
    }
  }

  /// 로딩 중의 오래된 입력은 나중에 몰아서 재생하지 않는다.
  int? play(String path, {required double volume, required double rate}) {
    if (!_ready || _suspended || _muted || volume <= 0) return null;
    final source = _sources[path];
    if (source == null) return null;
    int? handle;
    try {
      _prune();
      if (_voices.length >= maxVoices) return null;
      handle = engine.playPaused(source, volume.clamp(0, 1));
      if (!engine.isValid(handle)) {
        throw StateError('Invalid SFX voice $handle');
      }
      _voices.add(handle);
      // 4.x는 scale 인자가 없다. 첫 오디오 프레임 전에 rate를 설정한다.
      engine.setRate(handle, rate.clamp(0.25, 4));
      engine.setPaused(handle, false);
      _cleanup ??= Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _prune(),
      );
      return handle;
    } catch (error) {
      if (handle != null) {
        _voices.remove(handle);
        unawaited(_stop(handle));
      }
      log('Native SFX playback failed: $path (rate=$rate)', error);
      return null;
    }
  }

  void _prune() {
    _voices.removeWhere((handle) => !engine.isValid(handle));
    if (_voices.isEmpty) {
      _cleanup?.cancel();
      _cleanup = null;
    }
  }

  void configure({required bool muted, required double volume}) {
    _muted = muted;
    if (muted || volume <= 0) {
      _stopVoices();
    } else if (_ready) {
      _prune();
      for (final handle in _voices) {
        engine.setVolume(handle, volume.clamp(0, 1));
      }
    }
  }

  void suspend() {
    _suspended = true;
    _stopVoices();
  }

  void resume() => _suspended = false;

  void _stopVoices() {
    _cleanup?.cancel();
    _cleanup = null;
    for (final handle in _voices) {
      unawaited(_stop(handle));
    }
    _voices.clear();
  }

  Future<void> _stop(int handle) async {
    try {
      await engine.stop(handle);
    } catch (error) {
      log('Native SFX stop failed', error);
    }
  }

  Future<void> dispose() {
    _generation++;
    _ready = false;
    _cleanup?.cancel();
    _cleanup = null;
    _voices.clear();
    _sources.clear();
    return _disposing ??= _disposeEngine().whenComplete(
      () => _disposing = null,
    );
  }

  Future<void> _disposeEngine() async {
    try {
      await engine.dispose().timeout(const Duration(seconds: 2));
    } catch (error) {
      log('Native SFX dispose failed', error);
    }
  }
}
