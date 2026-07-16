import 'dart:async';

import '../app_config.dart';
import '../utils/storage_helper.dart';
import 'game_analytics_service.dart';

/// 튜토리얼 노출 여부를 로컬 저장소에 기록한다.
class TutorialStateService {
  TutorialStateService._();

  static const String completeOutcome = 'complete';
  static const String skipOutcome = 'skip';
  static const String legacySeenOutcome = 'legacy_seen';

  static bool get battleIntroSeen =>
      _readBoolOrSeen(StorageKeys.tutorialBattleIntroSeen);

  static bool get marketIntroSeen =>
      _readBoolOrSeen(StorageKeys.tutorialMarketIntroSeen);

  static Future<void> markBattleIntroSeen({
    String outcome = completeOutcome,
  }) async {
    await _writeSeenIfReady(
      seenKey: StorageKeys.tutorialBattleIntroSeen,
      outcomeKey: StorageKeys.tutorialBattleIntroOutcome,
      outcome: outcome,
    );
    _logTutorialEvent(_completionEventName(outcome), 'battle_intro', outcome);
  }

  static Future<void> markMarketIntroSeen({
    String outcome = completeOutcome,
  }) async {
    await _writeSeenIfReady(
      seenKey: StorageKeys.tutorialMarketIntroSeen,
      outcomeKey: StorageKeys.tutorialMarketIntroOutcome,
      outcome: outcome,
    );
    _logTutorialEvent(_completionEventName(outcome), 'market_intro', outcome);
  }

  static void logBattleIntroStart() {
    _logTutorialEvent('tutorial_start', 'battle_intro', 'start');
  }

  static void logMarketIntroStart() {
    _logTutorialEvent('tutorial_start', 'market_intro', 'start');
  }

  static void logBattleIntroAlreadySeen() {
    _logAlreadySeen(
      tutorialId: 'battle_intro',
      outcomeKey: StorageKeys.tutorialBattleIntroOutcome,
    );
  }

  static void logMarketIntroAlreadySeen() {
    _logAlreadySeen(
      tutorialId: 'market_intro',
      outcomeKey: StorageKeys.tutorialMarketIntroOutcome,
    );
  }

  static bool _readBoolOrSeen(String key) {
    try {
      return StorageHelper.readBool(key);
    } on StateError {
      // 분리 위젯 테스트처럼 저장소가 초기화되지 않은 환경에서는
      // 자동 튜토리얼을 건너뛰어 기존 렌더링 경로를 유지한다.
      return true;
    }
  }

  static Future<void> _writeSeenIfReady({
    required String seenKey,
    required String outcomeKey,
    required String outcome,
  }) async {
    try {
      await StorageHelper.write(seenKey, true);
      await StorageHelper.write(outcomeKey, outcome);
    } on StateError {
      // 저장소가 없는 테스트 환경의 수동 다시 보기는 저장하지 않는다.
    }
  }

  static void _logAlreadySeen({
    required String tutorialId,
    required String outcomeKey,
  }) {
    final outcome = _readStringOrDefault(outcomeKey, legacySeenOutcome);
    _logTutorialEvent('tutorial_already_seen', tutorialId, outcome);
  }

  static String _readStringOrDefault(String key, String defaultValue) {
    try {
      final value = StorageHelper.readString(key);
      return value.isEmpty ? defaultValue : value;
    } on StateError {
      return defaultValue;
    }
  }

  static void _logTutorialEvent(
    String eventName,
    String tutorialId,
    String outcome,
  ) {
    unawaited(
      GameAnalyticsService.instance.logEvent(
        eventName,
        parameters: {'tutorial_id': tutorialId, 'outcome': outcome},
      ),
    );
  }

  static String _completionEventName(String outcome) {
    return outcome == skipOutcome ? 'tutorial_skip' : 'tutorial_complete';
  }
}
