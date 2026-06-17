import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';

import '../services/game_settings.dart';
import 'asset_paths.dart';

/// 앱 전역 사운드 관리. BGM·효과음 재생, 볼륨·음소거 적용.
/// 웹: 사용자 상호작용 전까지 자동재생 차단. 첫 탭 시 unlock.
class SoundManager {
  SoundManager._();

  static const Duration _resumeStateSettleDelay = Duration(milliseconds: 120);

  static String? _currentBgm;
  static bool _webUnlocked = false;
  static String? _pendingBgm;
  static Future<void> _bgmOp = Future<void>.value();
  static int _bgmRequestSerial = 0;
  static int _bgmAutoResumeBlockDepth = 0;
  static bool _webBgmReplayInFlight = false;
  static bool _webBgmResumeInFlight = false;
  static bool _webPendingResumeTried = false;

  @visibleForTesting
  static String? get debugCurrentBgm => _currentBgm;

  @visibleForTesting
  static void debugResetForTest() {
    _currentBgm = null;
    _webUnlocked = false;
    _pendingBgm = null;
    _bgmOp = Future<void>.value();
    _bgmRequestSerial = 0;
    _bgmAutoResumeBlockDepth = 0;
    _webBgmReplayInFlight = false;
    _webBgmResumeInFlight = false;
    _webPendingResumeTried = false;
  }

  @visibleForTesting
  static bool debugShouldReplayWebBgm({
    required String requestedBgm,
    required String? currentBgm,
    required String? pendingBgm,
    required bool audioPlayerReportsPlaying,
  }) {
    return _shouldReplayWebBgm(
      requestedBgm: requestedBgm,
      currentBgm: currentBgm,
      pendingBgm: pendingBgm,
      audioPlayerReportsPlaying: audioPlayerReportsPlaying,
    );
  }

  static bool _shouldReplayWebBgm({
    required String requestedBgm,
    required String? currentBgm,
    required String? pendingBgm,
    required bool audioPlayerReportsPlaying,
  }) {
    if (pendingBgm == requestedBgm) return true;
    if (currentBgm == requestedBgm && audioPlayerReportsPlaying) return false;
    return true;
  }

  @visibleForTesting
  static String? debugPendingBgmAfterPause({
    required bool recoverOnNextWebGesture,
    required String? currentBgm,
  }) {
    return _pendingBgmAfterPause(
      recoverOnNextWebGesture: recoverOnNextWebGesture,
      currentBgm: currentBgm,
    );
  }

  static String? _pendingBgmAfterPause({
    required bool recoverOnNextWebGesture,
    required String? currentBgm,
  }) {
    if (!recoverOnNextWebGesture) return null;
    return currentBgm;
  }

  @visibleForTesting
  static bool debugShouldResumeBgmImmediately({
    required bool isWeb,
    required String target,
    required String? pendingBgm,
  }) {
    return _shouldResumeBgmImmediately(
      isWeb: isWeb,
      target: target,
      pendingBgm: pendingBgm,
    );
  }

  static bool _shouldResumeBgmImmediately({
    required bool isWeb,
    required String target,
    required String? pendingBgm,
  }) {
    return !(isWeb && pendingBgm == target);
  }

  @visibleForTesting
  static bool debugShouldStartWebBgmReplay({
    required bool replayInFlight,
    required String requestedBgm,
    required String? pendingBgm,
  }) {
    return _shouldStartWebBgmReplay(
      replayInFlight: replayInFlight,
      requestedBgm: requestedBgm,
      pendingBgm: pendingBgm,
    );
  }

  static bool _shouldStartWebBgmReplay({
    required bool replayInFlight,
    required String requestedBgm,
    required String? pendingBgm,
  }) {
    return !(replayInFlight && pendingBgm == requestedBgm);
  }

  @visibleForTesting
  static bool debugShouldResumePendingWebBgm({
    required String requestedBgm,
    required String? pendingBgm,
    required bool resumeInFlight,
    required bool resumeAlreadyTried,
  }) {
    return _shouldResumePendingWebBgm(
      requestedBgm: requestedBgm,
      pendingBgm: pendingBgm,
      resumeInFlight: resumeInFlight,
      resumeAlreadyTried: resumeAlreadyTried,
    );
  }

  static bool _shouldResumePendingWebBgm({
    required String requestedBgm,
    required String? pendingBgm,
    required bool resumeInFlight,
    required bool resumeAlreadyTried,
  }) {
    return pendingBgm == requestedBgm && !resumeInFlight && !resumeAlreadyTried;
  }

  @visibleForTesting
  static bool debugShouldPreloadAudioCache({required bool isWeb}) {
    return _shouldPreloadAudioCache(isWeb: isWeb);
  }

  static bool _shouldPreloadAudioCache({required bool isWeb}) {
    return !isWeb;
  }

  /// Pause 메뉴에서 설정을 여는 동안 mute 해제가 BGM을 자동 재개하지 못하게 막는다.
  static void beginBgmAutoResumeBlock() {
    _bgmAutoResumeBlockDepth++;
  }

  static void endBgmAutoResumeBlock() {
    if (_bgmAutoResumeBlockDepth == 0) return;
    _bgmAutoResumeBlockDepth--;
  }

  /// 웹: 사용자 상호작용 시 호출. 대기 중인 BGM을 제스처 안에서 바로 재생한다.
  static void unlockForWeb() {
    if (!kIsWeb) return;
    _webUnlocked = true;
    if (GameSettings.bgmMuted) return;
    final target = _pendingBgm ?? _currentBgm;
    if (target == null) return;
    if (!_shouldReplayWebBgm(
      requestedBgm: target,
      currentBgm: _currentBgm,
      pendingBgm: _pendingBgm,
      audioPlayerReportsPlaying:
          FlameAudio.bgm.audioPlayer.state == PlayerState.playing,
    )) {
      return;
    }
    if (_shouldResumePendingWebBgm(
      requestedBgm: target,
      pendingBgm: _pendingBgm,
      resumeInFlight: _webBgmResumeInFlight,
      resumeAlreadyTried: _webPendingResumeTried,
    )) {
      _resumePendingBgmForWebGesture(target);
      return;
    }
    _playBgmImmediatelyForWeb(target);
  }

  static void playBgmFromUserGesture(String path) {
    if (GameSettings.bgmMuted) return;
    if (!kIsWeb) {
      unawaited(playBgm(path));
      return;
    }
    _webUnlocked = true;
    _playBgmImmediatelyForWeb(path);
  }

  static void _resumePendingBgmForWebGesture(String path) {
    _webBgmResumeInFlight = true;
    _webPendingResumeTried = true;
    unawaited(
      _resumeBgm(path, replayFallback: false).whenComplete(() {
        _webBgmResumeInFlight = false;
      }),
    );
  }

  static void _playBgmImmediatelyForWeb(String path) {
    final pendingBeforeReplay = _pendingBgm;
    final previousBgm = _currentBgm;
    _currentBgm = path;
    if (!_shouldStartWebBgmReplay(
      replayInFlight: _webBgmReplayInFlight,
      requestedBgm: path,
      pendingBgm: pendingBeforeReplay,
    )) {
      return;
    }
    if (!_shouldReplayWebBgm(
      requestedBgm: path,
      currentBgm: previousBgm,
      pendingBgm: pendingBeforeReplay,
      audioPlayerReportsPlaying:
          FlameAudio.bgm.audioPlayer.state == PlayerState.playing,
    )) {
      return;
    }
    _bgmRequestSerial++;
    _webBgmReplayInFlight = true;
    try {
      unawaited(
        FlameAudio.bgm
            .stop()
            .then(
              (_) => FlameAudio.bgm.play(path, volume: GameSettings.bgmVolume),
            )
            .then((_) {
              if (_currentBgm == path) {
                _pendingBgm = null;
                _webPendingResumeTried = false;
              }
            })
            .catchError((Object _) {
              _pendingBgm = path;
              FlameAudio.bgm.isPlaying = false;
            })
            .whenComplete(() {
              _webBgmReplayInFlight = false;
            }),
      );
    } catch (_) {
      _pendingBgm = path;
      FlameAudio.bgm.isPlaying = false;
      _webBgmReplayInFlight = false;
    }
  }

  /// 게임·메뉴 BGM과 효과음을 미리 로드한다. 앱 시작 시 호출.
  static Future<void> preload() async {
    if (!_shouldPreloadAudioCache(isWeb: kIsWeb)) return;
    await Future.wait([
      FlameAudio.audioCache.load(AssetPaths.bgmMenu),
      FlameAudio.audioCache.load(AssetPaths.bgmMain),
      FlameAudio.audioCache.load(AssetPaths.sfxTimeTic),
      FlameAudio.audioCache.load(AssetPaths.sfxStart),
      FlameAudio.audioCache.load(AssetPaths.sfxCollect),
      FlameAudio.audioCache.load(AssetPaths.sfxFail),
      FlameAudio.audioCache.load(AssetPaths.sfxBtnSnd),
      FlameAudio.audioCache.load(AssetPaths.sfxClear),
      FlameAudio.audioCache.load(AssetPaths.sfxTimeUp),
    ]);
  }

  /// BGM 재생. 음소거 시에는 _currentBgm만 갱신하고 재생하지 않음.
  /// 웹: unlock 전이면 대기 후 첫 탭 시 재생.
  static Future<void> playBgm(String path) async {
    final requestId = ++_bgmRequestSerial;
    _bgmOp = _bgmOp.then((_) async {
      if (GameSettings.bgmMuted) {
        _pendingBgm = null;
        _currentBgm = path;
        return;
      }
      if (!_shouldReplayWebBgm(
        requestedBgm: path,
        currentBgm: _currentBgm,
        pendingBgm: _pendingBgm,
        audioPlayerReportsPlaying:
            FlameAudio.bgm.audioPlayer.state == PlayerState.playing,
      )) {
        return;
      }
      _currentBgm = path;
      if (kIsWeb && !_webUnlocked) {
        _pendingBgm = path;
        return;
      }
      if (requestId != _bgmRequestSerial) return;
      try {
        await FlameAudio.bgm.stop();
        if (requestId != _bgmRequestSerial) return;
        await FlameAudio.bgm.play(path, volume: GameSettings.bgmVolume);
        _pendingBgm = null;
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
    _webPendingResumeTried = false;
    _currentBgm = null;
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  /// BGM 일시정지. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void pauseBgm({
    String? onlyIfCurrent,
    bool recoverOnNextWebGesture = false,
  }) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    final pendingAfterPause = _pendingBgmAfterPause(
      recoverOnNextWebGesture: recoverOnNextWebGesture,
      currentBgm: _currentBgm,
    );
    if (kIsWeb && pendingAfterPause != null) {
      // 웹 복귀 후 브라우저가 playing 상태를 잘못 유지해도 다음 제스처에서 재시도한다.
      _pendingBgm = pendingAfterPause;
      _webPendingResumeTried = false;
    }
    unawaited(FlameAudio.bgm.pause().catchError((Object _) {}));
  }

  /// BGM 재개. [onlyIfCurrent]가 지정되면 현재 BGM과 일치할 때만 적용.
  static void resumeBgm({String? onlyIfCurrent}) {
    if (onlyIfCurrent != null && _currentBgm != onlyIfCurrent) return;
    if (GameSettings.bgmMuted) return;
    final target = _currentBgm;
    if (target == null) return;
    if (!_shouldResumeBgmImmediately(
      isWeb: kIsWeb,
      target: target,
      pendingBgm: _pendingBgm,
    )) {
      return;
    }
    if (FlameAudio.bgm.audioPlayer.state == PlayerState.playing &&
        (!kIsWeb || _pendingBgm != target)) {
      return;
    }
    if (kIsWeb && !_webUnlocked) return;
    unawaited(_resumeBgm(target));
  }

  static Future<void> _resumeBgm(
    String target, {
    bool replayFallback = true,
  }) async {
    final resumeRequestSerial = _bgmRequestSerial;
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
    await Future<void>.delayed(_resumeStateSettleDelay);
    if (_currentBgm != target ||
        resumeRequestSerial != _bgmRequestSerial ||
        GameSettings.bgmMuted) {
      return;
    }
    if (FlameAudio.bgm.audioPlayer.state == PlayerState.playing ||
        FlameAudio.bgm.isPlaying) {
      if (kIsWeb && _pendingBgm == target) {
        _pendingBgm = null;
        _webPendingResumeTried = false;
      }
      return;
    }
    if (kIsWeb) {
      _pendingBgm = target;
    }
    if (!replayFallback) return;
    await playBgm(target);
  }

  /// 음소거 해제 시 BGM 재생. pause 상태면 resume, stop 상태면 play.
  static Future<void> playBgmIfUnmuted() async {
    if (_bgmAutoResumeBlockDepth > 0) return;
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
