import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'native_sfx_player.dart';

NativeSfxPlayer createNativeSfxPlayer() => NativeSfxPlayer(
  engine: SoloudSfxEngine(),
  loadAsset: (path) async {
    final data = await rootBundle.load('assets/audio/$path');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  },
  log: (message, error) => debugPrint('$message: $error'),
);

/// 네이티브 효과음만 소유한다. BGM은 기존 flame_audio를 쓴다.
class SoloudSfxEngine implements NativeSfxEngine {
  SoLoud get _engine => SoLoud.instance;

  @override
  Future<void> initialize(int maxVoices) async {
    await _engine.init(bufferSize: 512);
    _engine.setMaxActiveVoiceCount(maxVoices);
  }

  @override
  Future<Object> load(String path, Uint8List bytes) =>
      _engine.loadMem(path, bytes, mode: LoadMode.memory);

  @override
  int playPaused(Object source, double volume) =>
      _engine.play(source as AudioSource, volume: volume, paused: true).id;

  @override
  void setRate(int handle, double rate) =>
      _engine.setRelativePlaySpeed(SoundHandle(handle), rate);

  @override
  void setPaused(int handle, bool paused) =>
      _engine.setPause(SoundHandle(handle), paused);

  @override
  void setVolume(int handle, double volume) =>
      _engine.setVolume(SoundHandle(handle), volume);

  @override
  bool isValid(int handle) =>
      handle > 0 &&
      _engine.isInitialized &&
      _engine.getIsValidVoiceHandle(SoundHandle(handle));

  @override
  Future<void> stop(int handle) async {
    if (isValid(handle)) await _engine.stop(SoundHandle(handle));
  }

  @override
  Future<void> dispose() => _engine.deinitAsync();
}
