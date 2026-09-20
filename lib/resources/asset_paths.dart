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
  static const String sfxTimeUp = 'sfx/TimeUp.wav';

  /// Kenney CC0 팩에서 가져온 효과음. 출처와 가공은 `assets/audio/sfx/CREDITS.md`,
  /// 만드는 방법은 `tools/build_sfx.py`에 있다.
  ///
  /// 아주 짧은 UI 소리만 wav다. mp3 인코더가 앞에 붙이는 패딩 때문에 손가락을
  /// 떼는 순간보다 소리가 늦게 들리는 것을 피하기 위해서다.
  static const String sfxUiToggle = 'sfx/UiToggle.wav';
  static const String sfxPanelOpen = 'sfx/PanelOpen.mp3';
  static const String sfxPanelClose = 'sfx/PanelClose.mp3';
  static const String sfxDeny = 'sfx/Deny.mp3';
  static const String sfxTilePick = 'sfx/TilePick.wav';
  static const String sfxTilePlace = 'sfx/TilePlace.wav';
  static const String sfxCardDraw = 'sfx/CardDraw.mp3';
  static const String sfxCardToss = 'sfx/CardToss.mp3';
  static const String sfxLineLoad = 'sfx/LineLoad.mp3';
  static const String sfxStationTick = 'sfx/StationTick.wav';
  static const String sfxScoreTick = 'sfx/ScoreTick.wav';
  static const String sfxMultHit = 'sfx/MultHit.mp3';
  static const String sfxJesterFire = 'sfx/JesterFire.mp3';
  static const String sfxScoreImpact = 'sfx/ScoreImpact.mp3';
  static const String sfxGold = 'sfx/Gold.mp3';
  static const String sfxShuffle = 'sfx/Shuffle.mp3';
  static const String sfxBossIntro = 'sfx/BossIntro.mp3';
  static const String sfxReward = 'sfx/Reward.mp3';

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
  static const String uiRummiPokerLogo =
      'assets/images/ui/rummi_poker_logo.png';
}
