import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/game_settings.dart';
import 'web_vibrate_bridge.dart';

/// 햅틱 등급. 가벼운 쪽부터 무거운 쪽 순서다.
enum HapticGrade {
  select(8),
  place(12),
  impact(16),
  heavy(20),
  error(20);

  const HapticGrade(this.webVibrateMs);

  /// Android 웹 `navigator.vibrate` 길이. 모터가 거칠어 20ms 이하로 둔다.
  final int webVibrateMs;
}

/// 등급이 있는 햅틱. 소리와 같은 시점에 부르도록 [GameFeedback]을 거친다.
///
/// 네이티브는 [HapticFeedback], Android 웹은 `navigator.vibrate`, iOS 웹은
/// Vibration API가 없어 아무것도 하지 않는다.
class GameHaptics {
  GameHaptics._();

  /// 테스트에서 실제 햅틱 대신 등급을 받는다.
  @visibleForTesting
  static void Function(HapticGrade grade)? debugSink;

  static void play(HapticGrade grade) {
    if (!GameSettings.hapticsEnabled) return;
    final sink = debugSink;
    if (sink != null) {
      sink(grade);
      return;
    }
    if (kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        vibrateWeb(grade.webVibrateMs);
      }
      return;
    }
    final Future<void> request = switch (grade) {
      HapticGrade.select => HapticFeedback.selectionClick(),
      HapticGrade.place => HapticFeedback.lightImpact(),
      HapticGrade.impact => HapticFeedback.mediumImpact(),
      HapticGrade.heavy => HapticFeedback.heavyImpact(),
      HapticGrade.error => HapticFeedback.vibrate(),
    };
    request.catchError((Object _) {});
  }
}
