/// 앱 전반에서 사용하는 상수 모음.
/// private 생성자(_)로 인스턴스 생성을 막고, static 상수만 제공한다.
class AppConfig {
  AppConfig._();

  /// iOS/MacOS: App Store Connect > General > App Information > Apple ID. 출시 시 설정.
  static const String appStoreId = '';

  static const String appTitle = '순서대로 TapTap';
  static const String gameTitle = '순서대로';
  static const String gameTitleSub = 'TapTap';
  static const String gameSubtitle = '숫자와 알파벳을 순서대로 눌러보자!';
}

/// 로컬 저장소(GetStorage) 키 상수.
class StorageKeys {
  StorageKeys._();

  static const String bgmVolume = 'bgm_volume';
  static const String sfxVolume = 'sfx_volume';
  static const String bgmMuted = 'bgm_muted';
  static const String sfxMuted = 'sfx_muted';
  static const String keepScreenOn = 'keep_screen_on';
  static const String bestScorePrefix = 'best_score_mode_';
  static const String firstLaunchDate = 'first_launch_date';
  static const String reviewRequestedAfterFirstClear = 'review_requested_after_first_clear';
  static const String reviewRequestedOnTitle = 'review_requested_on_title';
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
}
