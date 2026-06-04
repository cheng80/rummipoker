/// 앱 전반에서 사용하는 상수 모음.
/// private 생성자(_)로 인스턴스 생성을 막고, static 상수만 제공한다.
class AppConfig {
  AppConfig._();

  /// iOS/MacOS: App Store Connect > General > App Information > Apple ID. 출시 시 설정.
  static const String appStoreId = '';

  static const String appTitle = 'RummiPoker';

  /// 타이틀 화면 메인 로고 (줄바꿈 포함).
  static const String gameTitleBlock = 'Rummi\nPoker';
  static const String gameSubtitle = '타일로 만드는 포커 런';

  /// Station/Blind 목표 점수를 한 번에 미세 조정하는 전역 스케일.
  static const double stationTargetScoreScale = 0.9;

  /// QA/눈검증용 디버그 픽스처 노출 플래그.
  ///
  /// 시연/제출 영상에 개발용 진입점이 섞이지 않도록 모든 빌드에서
  /// 기본 숨김 처리하고, QA 빌드에서만 dart-define으로 노출한다.
  static const bool showDebugFixtures = bool.fromEnvironment(
    'SHOW_DEBUG_FIXTURES',
  );
}

/// 로컬 저장소(SharedPreferences) 키 상수.
class StorageKeys {
  StorageKeys._();

  static const String bgmVolume = 'bgm_volume';
  static const String sfxVolume = 'sfx_volume';
  static const String bgmMuted = 'bgm_muted';
  static const String sfxMuted = 'sfx_muted';
  static const String keepScreenOn = 'keep_screen_on';
  static const String firstLaunchDate = 'first_launch_date';
  static const String reviewRequestedAfterFirstClear =
      'review_requested_after_first_clear';
  static const String reviewRequestedOnTitle = 'review_requested_on_title';
  static const String tutorialBattleIntroSeen = 'tutorial_battle_intro_seen';
  static const String tutorialMarketIntroSeen = 'tutorial_market_intro_seen';
  static const String activeRunPayloadV1 = 'active_run_payload_v1';
  static const String activeRunSignatureV1 = 'active_run_signature_v1';
  static const String activeRunBookmarkPayloadPrefix =
      'active_run_bookmark_payload_v1_';
  static const String activeRunBookmarkSignaturePrefix =
      'active_run_bookmark_signature_v1_';
  static const String saveDeviceKeyV1 = 'save_device_key_v1';
  static const String runUnlockStateV1 = 'run_unlock_state_v1';
}

/// 인앱 리뷰: TitleView에서 일정 기간(일) 경과 후 requestReview 호출.
const int reviewDaysAfterFirstLaunch = 3;

/// GoRouter에서 사용할 경로 상수.
/// 라우트 경로를 한곳에서 관리하여 오타를 방지한다.
class RoutePaths {
  RoutePaths._();

  static const String title = '/';
  static const String game = '/game';
  static const String setting = '/setting';
  static const String newRun = '/new-run';
  static const String blindSelect = '/blind-select';
  static const String trial = '/trial';
  static const String archive = '/archive';
}
