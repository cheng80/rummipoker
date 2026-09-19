import '../../../services/game_settings.dart';

/// 앱 설정의 UI 상태 스냅샷.
class SettingsState {
  const SettingsState({
    this.bgmVolume = 0.5,
    this.sfxVolume = 1.0,
    this.bgmMuted = false,
    this.sfxMuted = false,
    this.keepScreenOn = true,
    this.fxIntensity = FxIntensity.normal,
    this.settlementSpeed = SettlementSpeed.x1,
    this.screenShakeEnabled = true,
    this.hapticsEnabled = true,
  });

  final double bgmVolume;
  final double sfxVolume;
  final bool bgmMuted;
  final bool sfxMuted;
  final bool keepScreenOn;
  final FxIntensity fxIntensity;
  final SettlementSpeed settlementSpeed;
  final bool screenShakeEnabled;
  final bool hapticsEnabled;

  SettingsState copyWith({
    double? bgmVolume,
    double? sfxVolume,
    bool? bgmMuted,
    bool? sfxMuted,
    bool? keepScreenOn,
    FxIntensity? fxIntensity,
    SettlementSpeed? settlementSpeed,
    bool? screenShakeEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmMuted: bgmMuted ?? this.bgmMuted,
      sfxMuted: sfxMuted ?? this.sfxMuted,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      fxIntensity: fxIntensity ?? this.fxIntensity,
      settlementSpeed: settlementSpeed ?? this.settlementSpeed,
      screenShakeEnabled: screenShakeEnabled ?? this.screenShakeEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
