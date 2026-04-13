import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../resources/sound_manager.dart';
import '../../../services/game_settings.dart';
import 'settings_state.dart';

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return SettingsState(
      bgmVolume: GameSettings.bgmVolume,
      sfxVolume: GameSettings.sfxVolume,
      bgmMuted: GameSettings.bgmMuted,
      sfxMuted: GameSettings.sfxMuted,
      keepScreenOn: GameSettings.keepScreenOn,
    );
  }

  void setBgmVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    GameSettings.bgmVolume = clamped;
    SoundManager.applyBgmVolume();
    state = state.copyWith(bgmVolume: clamped);
  }

  void setSfxVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    GameSettings.sfxVolume = clamped;
    state = state.copyWith(sfxVolume: clamped);
  }

  void setBgmMuted(bool value) {
    GameSettings.bgmMuted = value;
    if (value) {
      SoundManager.pauseBgm();
    } else {
      SoundManager.playBgmIfUnmuted();
    }
    state = state.copyWith(bgmMuted: value);
  }

  void setSfxMuted(bool value) {
    GameSettings.sfxMuted = value;
    state = state.copyWith(sfxMuted: value);
  }

  void setKeepScreenOn(bool value) {
    GameSettings.keepScreenOn = value;
    _applyWakelock(value);
    state = state.copyWith(keepScreenOn: value);
  }

  /// 앱 시작 시 저장된 설정에 따라 Wakelock을 적용한다.
  /// main.dart에서 ProviderScope 구성 후 한 번 호출.
  void applyInitialWakelock() {
    _applyWakelock(state.keepScreenOn);
  }

  static void _applyWakelock(bool enabled) {
    if (enabled) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }
}
