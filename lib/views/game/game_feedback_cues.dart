import '../../resources/asset_paths.dart';
import '../../resources/game_haptics.dart';
import '../../resources/sound_manager.dart';

/// 게임 안에서 일어나는 일의 의미 키. 소리와 햅틱은 이 키로만 고른다.
///
/// 새 음원이 들어오면 [gameFeedbackCues]의 매핑만 바꾼다.
enum GameCue {
  buttonTap,
  tileSelect,
  tilePlace,
  tileDraw,
  discard,
  itemUse,
  buy,
  sell,
  reroll,
  deny,
  scoreTick,
  overlapHit,
  jesterFire,
  penalty,
  bigScore1,
  bigScore2,
  bigScore3,
  bigScore4,
  unlock,
  marketEntry,
  marketTab,
  marketPage,
  stationAdvance,
  menuNavigate,
  cashOutCollect,
  newReveal,
  bossIntro,
  victory,
  gameOver,

  // --- T0: 공통 입력·팝업·화면 전환 ---
  runStart,
  battleStart,
  runRestore,
  choiceSelect,
  panelOpen,
  noticeTop,
  noticeBottom,

  // ── 전투 레인 ──
  countTick,
  tileModifierFire,
  itemFire,
  tileMove,
  lineTransform,
  previewChange,
  confirmPress,
}

/// 의미 키 하나가 내는 소리와 햅틱.
class GameCueSpec {
  const GameCueSpec({
    required this.sfx,
    this.pitch = 1,
    this.pitchVariance = 0,
    this.haptic,
  });

  final String sfx;

  /// 재생 배율(1 = 원음). 웹에서만 음높이가 바뀐다.
  final double pitch;

  /// 반복 동작이 기계적으로 들리지 않게 주는 ±무작위 변주 비율.
  final double pitchVariance;
  final HapticGrade? haptic;
}

/// Kenney CC0 팩에서 가져온 효과음 18개와 원래 있던 7개를 계열로 묶은 매핑.
///
/// 한 계열 안의 차이는 pitch로 낸다. 네이티브는 pitch 없이 원음으로 재생하므로
/// 기본값을 1 근처에 두고, 정산 상승처럼 뜻이 있는 사다리만 크게 벌린다.
const Map<GameCue, GameCueSpec> gameFeedbackCues = {
  GameCue.buttonTap: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitchVariance: 0.04,
    haptic: HapticGrade.select,
  ),
  GameCue.tileSelect: GameCueSpec(
    sfx: AssetPaths.sfxTilePick,
    pitchVariance: 0.05,
    haptic: HapticGrade.select,
  ),
  GameCue.tilePlace: GameCueSpec(
    sfx: AssetPaths.sfxTilePlace,
    pitchVariance: 0.06,
    haptic: HapticGrade.place,
  ),
  GameCue.tileDraw: GameCueSpec(
    sfx: AssetPaths.sfxCardDraw,
    pitchVariance: 0.06,
    haptic: HapticGrade.select,
  ),
  GameCue.discard: GameCueSpec(
    sfx: AssetPaths.sfxCardToss,
    pitchVariance: 0.05,
    haptic: HapticGrade.place,
  ),
  GameCue.itemUse: GameCueSpec(
    sfx: AssetPaths.sfxJesterFire,
    pitch: 1.08,
    pitchVariance: 0.04,
    haptic: HapticGrade.impact,
  ),
  GameCue.buy: GameCueSpec(
    sfx: AssetPaths.sfxGold,
    pitch: 0.92,
    pitchVariance: 0.03,
    haptic: HapticGrade.impact,
  ),
  GameCue.sell: GameCueSpec(
    sfx: AssetPaths.sfxGold,
    pitch: 1.06,
    pitchVariance: 0.03,
    haptic: HapticGrade.place,
  ),
  GameCue.reroll: GameCueSpec(
    sfx: AssetPaths.sfxShuffle,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.deny: GameCueSpec(
    sfx: AssetPaths.sfxDeny,
    haptic: HapticGrade.error,
  ),
  GameCue.scoreTick: GameCueSpec(
    sfx: AssetPaths.sfxScoreTick,
    haptic: HapticGrade.select,
  ),
  GameCue.overlapHit: GameCueSpec(
    sfx: AssetPaths.sfxMultHit,
    pitchVariance: 0.04,
    haptic: HapticGrade.impact,
  ),
  GameCue.jesterFire: GameCueSpec(
    sfx: AssetPaths.sfxJesterFire,
    pitchVariance: 0.04,
    haptic: HapticGrade.impact,
  ),
  GameCue.penalty: GameCueSpec(
    sfx: AssetPaths.sfxFail,
    pitch: 0.85,
    haptic: HapticGrade.heavy,
  ),
  // 정산 단계마다 올라가는 사다리. 여기만 pitch를 크게 벌린다.
  GameCue.bigScore1: GameCueSpec(
    sfx: AssetPaths.sfxScoreImpact,
    pitch: 0.92,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore2: GameCueSpec(
    sfx: AssetPaths.sfxScoreImpact,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore3: GameCueSpec(
    sfx: AssetPaths.sfxScoreImpact,
    pitch: 1.1,
    haptic: HapticGrade.heavy,
  ),
  GameCue.bigScore4: GameCueSpec(
    sfx: AssetPaths.sfxScoreImpact,
    pitch: 1.2,
    haptic: HapticGrade.heavy,
  ),
  GameCue.unlock: GameCueSpec(
    sfx: AssetPaths.sfxReward,
    haptic: HapticGrade.impact,
  ),
  GameCue.marketEntry: GameCueSpec(
    sfx: AssetPaths.sfxPanelOpen,
    pitch: 0.92,
    haptic: HapticGrade.impact,
  ),
  GameCue.marketTab: GameCueSpec(
    sfx: AssetPaths.sfxUiToggle,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.marketPage: GameCueSpec(
    sfx: AssetPaths.sfxUiToggle,
    pitch: 0.94,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.stationAdvance: GameCueSpec(
    sfx: AssetPaths.sfxStationTick,
    haptic: HapticGrade.impact,
  ),
  GameCue.menuNavigate: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 0.95,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.cashOutCollect: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    haptic: HapticGrade.impact,
  ),
  GameCue.newReveal: GameCueSpec(
    sfx: AssetPaths.sfxReward,
    pitch: 1.12,
    haptic: HapticGrade.impact,
  ),
  GameCue.bossIntro: GameCueSpec(
    sfx: AssetPaths.sfxBossIntro,
    haptic: HapticGrade.heavy,
  ),
  GameCue.victory: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    haptic: HapticGrade.heavy,
  ),
  GameCue.gameOver: GameCueSpec(
    sfx: AssetPaths.sfxTimeUp,
    haptic: HapticGrade.heavy,
  ),

  // --- T0: 공통 입력·팝업·화면 전환 ---
  GameCue.runStart: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    haptic: HapticGrade.impact,
  ),
  GameCue.battleStart: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 0.95,
    haptic: HapticGrade.heavy,
  ),
  GameCue.runRestore: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.05,
    haptic: HapticGrade.impact,
  ),
  GameCue.choiceSelect: GameCueSpec(
    sfx: AssetPaths.sfxTilePick,
    pitch: 1.05,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.panelOpen: GameCueSpec(
    sfx: AssetPaths.sfxPanelOpen,
    haptic: HapticGrade.select,
  ),
  GameCue.noticeTop: GameCueSpec(sfx: AssetPaths.sfxPanelOpen, pitch: 1.1),
  GameCue.noticeBottom: GameCueSpec(sfx: AssetPaths.sfxPanelClose),

  // ── 전투 레인 ──
  GameCue.countTick: GameCueSpec(sfx: AssetPaths.sfxTimeTic),
  GameCue.tileModifierFire: GameCueSpec(
    sfx: AssetPaths.sfxMultHit,
    pitch: 1.2,
    pitchVariance: 0.05,
    haptic: HapticGrade.select,
  ),
  GameCue.itemFire: GameCueSpec(
    sfx: AssetPaths.sfxJesterFire,
    pitch: 1.15,
    haptic: HapticGrade.impact,
  ),
  GameCue.tileMove: GameCueSpec(
    sfx: AssetPaths.sfxTilePlace,
    pitch: 1.08,
    pitchVariance: 0.05,
    haptic: HapticGrade.place,
  ),
  GameCue.lineTransform: GameCueSpec(
    sfx: AssetPaths.sfxLineLoad,
    pitch: 0.95,
    haptic: HapticGrade.impact,
  ),
  GameCue.previewChange: GameCueSpec(
    sfx: AssetPaths.sfxScoreTick,
    pitch: 1.25,
    pitchVariance: 0.04,
  ),
  GameCue.confirmPress: GameCueSpec(
    sfx: AssetPaths.sfxLineLoad,
    haptic: HapticGrade.impact,
  ),
};

/// 의미 키로 소리와 햅틱을 같은 시점에 낸다.
class GameFeedback {
  GameFeedback._();

  /// [pitch]는 cue 기본 pitch에 곱한다. 정산 단계마다 올라가는 음 등에 쓴다.
  static void play(GameCue cue, {double pitch = 1}) {
    final spec = gameFeedbackCues[cue]!;
    SoundManager.playSfx(
      spec.sfx,
      pitch: spec.pitch * pitch,
      pitchVariance: spec.pitchVariance,
    );
    final haptic = spec.haptic;
    if (haptic != null) GameHaptics.play(haptic);
  }
}
