import '../app_config.dart';
import '../utils/storage_helper.dart';

/// 연출 강도. juice·흔들림·파티클 양에 곱하는 배율을 가진다.
enum FxIntensity {
  off(0),
  normal(1),
  strong(1.5);

  const FxIntensity(this.scale);

  final double scale;
}

/// 정산 연출 속도. [instant]는 대기 없이 결과만 보여 준다.
enum SettlementSpeed {
  x1(1),
  x2(2),
  x4(4),
  instant(double.infinity);

  const SettlementSpeed(this.multiplier);

  final double multiplier;
}

T _enumAt<T extends Enum>(List<T> values, int index, T fallback) =>
    index >= 0 && index < values.length ? values[index] : fallback;

/// 게임 설정 저장/로드. StorageHelper(SharedPreferences)로 로컬에 영구 저장한다.
class GameSettings {
  GameSettings._();

  /// BGM 볼륨 (0.0 ~ 1.0).
  static double get bgmVolume =>
      StorageHelper.readDouble(StorageKeys.bgmVolume, defaultValue: 0.5);

  static set bgmVolume(double v) {
    StorageHelper.write(StorageKeys.bgmVolume, v.clamp(0.0, 1.0));
  }

  /// 효과음 볼륨 (0.0 ~ 1.0).
  static double get sfxVolume =>
      StorageHelper.readDouble(StorageKeys.sfxVolume, defaultValue: 1.0);

  static set sfxVolume(double v) {
    StorageHelper.write(StorageKeys.sfxVolume, v.clamp(0.0, 1.0));
  }

  /// BGM 음소거 여부.
  static bool get bgmMuted =>
      StorageHelper.readBool(StorageKeys.bgmMuted, defaultValue: false);

  static set bgmMuted(bool v) => StorageHelper.write(StorageKeys.bgmMuted, v);

  /// 효과음 음소거 여부.
  static bool get sfxMuted =>
      StorageHelper.readBool(StorageKeys.sfxMuted, defaultValue: false);

  static set sfxMuted(bool v) => StorageHelper.write(StorageKeys.sfxMuted, v);

  /// 화면 꺼짐 방지 여부.
  static bool get keepScreenOn =>
      StorageHelper.readBool(StorageKeys.keepScreenOn, defaultValue: true);

  static set keepScreenOn(bool v) =>
      StorageHelper.write(StorageKeys.keepScreenOn, v);

  /// 연출 강도. 저장값은 enum index다.
  /// 연출 설정 getter는 저장소 init 전이면 기본값을 돌려준다.
  static FxIntensity get fxIntensity => !StorageHelper.isInitialized
      ? FxIntensity.normal
      : _enumAt(
          FxIntensity.values,
          StorageHelper.readInt(
            StorageKeys.fxIntensity,
            defaultValue: FxIntensity.normal.index,
          ),
          FxIntensity.normal,
        );

  static set fxIntensity(FxIntensity v) =>
      StorageHelper.write(StorageKeys.fxIntensity, v.index);

  /// 정산 연출 속도. 저장값은 enum index다.
  static SettlementSpeed get settlementSpeed => !StorageHelper.isInitialized
      ? SettlementSpeed.x1
      : _enumAt(
          SettlementSpeed.values,
          StorageHelper.readInt(StorageKeys.settlementSpeed),
          SettlementSpeed.x1,
        );

  static set settlementSpeed(SettlementSpeed v) =>
      StorageHelper.write(StorageKeys.settlementSpeed, v.index);

  /// 화면 흔들림 사용 여부.
  static bool get screenShakeEnabled =>
      !StorageHelper.isInitialized ||
      StorageHelper.readBool(
        StorageKeys.screenShakeEnabled,
        defaultValue: true,
      );

  static set screenShakeEnabled(bool v) =>
      StorageHelper.write(StorageKeys.screenShakeEnabled, v);

  /// 햅틱 사용 여부.
  static bool get hapticsEnabled =>
      !StorageHelper.isInitialized ||
      StorageHelper.readBool(StorageKeys.hapticsEnabled, defaultValue: true);

  static set hapticsEnabled(bool v) =>
      StorageHelper.write(StorageKeys.hapticsEnabled, v);
}
