import '../app_config.dart';
import '../utils/storage_helper.dart';

/// 튜토리얼 노출 여부를 로컬 저장소에 기록한다.
class TutorialStateService {
  TutorialStateService._();

  static bool get battleIntroSeen =>
      _readBoolOrSeen(StorageKeys.tutorialBattleIntroSeen);

  static bool get marketIntroSeen =>
      _readBoolOrSeen(StorageKeys.tutorialMarketIntroSeen);

  static Future<void> markBattleIntroSeen() async {
    await _writeBoolIfReady(StorageKeys.tutorialBattleIntroSeen);
  }

  static Future<void> markMarketIntroSeen() async {
    await _writeBoolIfReady(StorageKeys.tutorialMarketIntroSeen);
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

  static Future<void> _writeBoolIfReady(String key) async {
    try {
      await StorageHelper.write(key, true);
    } on StateError {
      // 저장소가 없는 테스트 환경의 수동 다시 보기는 저장하지 않는다.
    }
  }
}
