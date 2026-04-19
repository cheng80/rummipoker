import '../app_config.dart';
import '../utils/storage_helper.dart';

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
}
