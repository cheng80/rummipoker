/// 에셋 경로 상수.
/// 하드코딩을 피하고 한곳에서 관리한다.
class AssetPaths {
  AssetPaths._();

  /// 효과음 경로. FlameAudio.play()에는 assets/audio/ 이후 상대 경로를 전달한다.
  static const String sfxTimeTic = 'sfx/TimeTic.mp3';
  static const String sfxStart = 'sfx/Start.mp3';
  static const String sfxCollect = 'sfx/Collect.mp3';
  static const String sfxFail = 'sfx/Fail.mp3';
  static const String sfxBtnSnd = 'sfx/BtnSnd.mp3';
  static const String sfxClear = 'sfx/Clear.mp3';

  /// BGM 경로. FlameAudio.bgm에는 assets/audio/ 이후 상대 경로를 전달한다.
  static const String bgmMenu = 'music/Menu_BGM.mp3';
  static const String bgmMain = 'music/Main_BGM.mp3';

  /// 폰트 family 이름 (pubspec.yaml에 등록된 이름과 동일)
  static const String fontNexonLv2Gothic = 'NexonLv2Gothic';

  /// 데이터 에셋 경로.
  static const String jestersCommon = 'data/common/jesters_common_phase5.json';
  static const String itemsCommon = 'data/common/items_common_v1.json';

  /// UI 이미지 경로.
  static const String uiGreed = 'assets/images/ui/greed.png';
}
