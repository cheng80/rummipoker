/// 앱 설정의 UI 상태 스냅샷.
class SettingsState {
  const SettingsState({
    this.bgmVolume = 0.5,
    this.sfxVolume = 1.0,
    this.bgmMuted = false,
    this.sfxMuted = false,
    this.keepScreenOn = true,
  });

  final double bgmVolume;
  final double sfxVolume;
  final bool bgmMuted;
  final bool sfxMuted;
  final bool keepScreenOn;

  SettingsState copyWith({
    double? bgmVolume,
    double? sfxVolume,
    bool? bgmMuted,
    bool? sfxMuted,
    bool? keepScreenOn,
  }) {
    return SettingsState(
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmMuted: bgmMuted ?? this.bgmMuted,
      sfxMuted: sfxMuted ?? this.sfxMuted,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }
}
