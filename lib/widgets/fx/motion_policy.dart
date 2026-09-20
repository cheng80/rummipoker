import 'package:flutter/widgets.dart';

import '../../services/game_settings.dart';

/// 연출 설정과 OS 동작 줄이기를 합쳐 연출 배율을 정한다.
///
/// OS의 동작 줄이기(`disableAnimations`, `reduceMotion`)가 켜져 있으면 juice와
/// 화면 흔들림은 설정과 무관하게 0이다.
class MotionPolicy {
  MotionPolicy._();

  /// 테스트에서 OS 동작 줄이기 상태를 고정한다.
  @visibleForTesting
  static bool? debugReduceMotionOverride;

  static bool get reduceMotion {
    final override = debugReduceMotionOverride;
    if (override != null) return override;
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.reduceMotion;
  }

  /// 버튼·발동·구매 juice 세기 배율.
  static double get juiceScale =>
      reduceMotion ? 0 : GameSettings.fxIntensity.scale;

  /// 화면 흔들림 배율.
  static double get shakeScale =>
      reduceMotion || !GameSettings.screenShakeEnabled
      ? 0
      : GameSettings.fxIntensity.scale;

  /// 파티클 개수 배율. 파티클은 시점 이동이 없어 동작 줄이기와 무관하게 강도만 따른다.
  static double get particleScale => GameSettings.fxIntensity.scale;
}
