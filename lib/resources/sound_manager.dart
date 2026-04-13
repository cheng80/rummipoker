import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

import '../services/game_settings.dart';
import 'asset_paths.dart';

/// 앱 전역 사운드 관리. BGM·효과음 재생, 볼륨·음소거 적용.
/// 웹: 사용자 상호작용 전까지 자동재생 차단. 첫 탭 시 unlock.
class SoundManager {
  SoundManager._();

  static String? _currentBgm;
  static bool _webUnlocked = false;
  static String? _pendingBgm;
  static Future<void> _bgmOp = Future<void>.value();
  static int _bgmRequestSerial = 0;

  /// 웹: 첫 사용자 상호작용 시 호출. 대기 중인 BGM 재생.
  /// playBgm(path) 대신 playBgmIfUnmuted() 사용: 이미 _currentBgm이 설정된 상태에서
  /// playBgm(path)를 호출하면 _currentBgm == path로 early return되어 실제 재생이 안 됨.
  static void unlockForWeb() {
    if (!kIsWeb || _webUnlocked) return;
    _webUnlocked = true;
    if (_pendingBgm != null) {
      final pending = _pendingBgm!;
      _pendingBgm = null;
      playBgm(pending);
    }
  }

  /// 게임·메뉴 BGM과 효과음을 미리 로드한다. 앱 시작 시 호출.
  static Future<void> preload() async {
    await Future.wait([
      FlameAudio.audioCache.load(AssetPaths.bgmMenu),
      FlameAudio.audioCache.load(AssetPaths.bgmMain),
      FlameAudio.audioCache.load(AssetPaths.sfxTimeTic),
      FlameAudio.audioCache.load(AssetPaths.sfxStart),
      FlameAudio.audioCache.load(AssetPaths.sfxCollect),
      FlameAudio.audioCache.load(AssetPaths.sfxFail),
      FlameAudio.audioCache.load(AssetPaths.sfxBtnSnd),
      FlameAudio.audioCache.load(AssetPaths.sfxClear),
    ]);
  }

  /// BGM 재생. 음소거 시에는 _currentBgm만 갱신하고 재생하지 않음.
  /// 웹: unlock 전이면 대기 후 첫 탭 시 재생.
  static Future<void> playBgm(String path) async {
    final requestId = ++_bgmRequestSerial;
    _bgmOp = _bgmOp.then((_) async {
      if (_currentBgm == path && FlameAudio.bgm.isPlaying) return;
      FlameAudio.bgm.stop();
      _currentBgm = path;
      if (GameSettings.bgmMuted) return;
      if (kIsWeb && !_webUnlocked) {
        _pendingBgm = path;
        return;
      }
      if (requestId != _bgmRequestSerial) return;
      try {
        await FlameAudio.bgm.play(path, volume: GameSettings.bgmVolume);
      } catch (_) {
        _pendingBgm = path;
      }
    });
    await _bgmOp;
  }

  /// BGM 중지.
  static Future<void> stopBgm() async {
    _bgmRequestSerial++;
    _pendingBgm = null;
    FlameAudio.bgm.stop();
    _currentBgm = null;
  }

  /// BGM 일시정지. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void pauseBgm({String? onlyIfCurrent}) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    FlameAudio.bgm.pause();
  }

  /// BGM 재개. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void resumeBgm({String? onlyIfCurrent}) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    if (GameSettings.bgmMuted) return;
    if (_currentBgm == null) return;
    if (FlameAudio.bgm.isPlaying) return;
    if (kIsWeb && !_webUnlocked) return;
    try {
      FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// 음소거 해제 시 BGM 재생. pause 상태면 resume, stop 상태면 play.
  static Future<void> playBgmIfUnmuted() async {
    final current = _currentBgm;
    if (current == null) return;
    await playBgm(current);
  }

  /// BGM 볼륨을 설정에 맞게 적용. 볼륨 슬라이더 변경 시 호출.
  static void applyBgmVolume() {
    if (GameSettings.bgmMuted) return;
    FlameAudio.bgm.audioPlayer.setVolume(GameSettings.bgmVolume);
  }

  /// 효과음 재생. 음소거 시 무시, 볼륨은 GameSettings.sfxVolume 적용.
  /// 웹: unlock 전이면 무시 (카운트다운 등 자동 재생 방지).
  ///
  /// **웹(kIsWeb):** [FlameAudio.play]는 내부적으로 [PlayerMode.lowLatency]를 쓰는데,
  /// 브라우저에서는 자주 묵음/재생 실패가 난다. HTML5 `<audio>`에 가까운
  /// [PlayerMode.mediaPlayer] 경로인 [FlameAudio.playLongAudio]로 재생한다.
  /// BGM은 기존처럼 [FlameAudio.bgm]을 그대로 사용한다.
  static void playSfx(String path) {
    if (GameSettings.sfxMuted) return;
    if (kIsWeb && !_webUnlocked) return;
    final vol = GameSettings.sfxVolume;
    try {
      if (kIsWeb) {
        _playSfxWeb(path, vol);
      } else {
        FlameAudio.play(path, volume: vol);
      }
    } catch (_) {}
  }

  /// 웹 전용 SFX — [FlameAudio.playLongAudio] = mediaPlayer 모드 (짧은 클립에도 사용 가능).
  static void _playSfxWeb(String path, double volume) {
    FlameAudio.playLongAudio(path, volume: volume);
  }
}
