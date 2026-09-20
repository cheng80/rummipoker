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
  cashOutOpen,
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
    this.sfx,
    this.pitch = 1,
    this.pitchVariance = 0,
    this.preserveOriginalPitch = false,
    this.haptic,
  });

  final String? sfx;

  /// 재생 배율(1 = 원음). 웹과 네이티브에서 음높이·속도가 함께 바뀐다.
  final double pitch;

  /// 반복 동작이 기계적으로 들리지 않게 주는 ±무작위 변주 비율.
  final double pitchVariance;

  /// UI 입력은 호출부 변주·전역 감속과 무관하게 원음을 유지한다.
  final bool preserveOriginalPitch;
  final HapticGrade? haptic;
}

/// 등록 음원 12개 중 승인된 상황 매핑을 사용한다.
/// 비언어 효과만 pitch·변주에 사용하며, 소리 없는 시각·햅틱 cue도 허용한다.
const Map<GameCue, GameCueSpec> gameFeedbackCues = {
  GameCue.buttonTap: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.tileSelect: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxTilePick,
    haptic: HapticGrade.select,
  ),
  GameCue.tilePlace: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxTilePlace,
    haptic: HapticGrade.place,
  ),
  GameCue.tileDraw: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.discard: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxCardToss,
    haptic: HapticGrade.place,
  ),
  GameCue.itemUse: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.buy: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.sell: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.place,
  ),
  GameCue.reroll: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.deny: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxDeny,
    haptic: HapticGrade.error,
  ),
  GameCue.scoreTick: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    haptic: HapticGrade.select,
  ),
  GameCue.overlapHit: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.3,
    haptic: HapticGrade.impact,
  ),
  GameCue.jesterFire: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitchVariance: 0.05,
    haptic: HapticGrade.impact,
  ),
  GameCue.penalty: GameCueSpec(
    sfx: AssetPaths.sfxFail,
    haptic: HapticGrade.heavy,
  ),
  GameCue.bigScore1: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 0.9,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore2: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore3: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.12,
    haptic: HapticGrade.heavy,
  ),
  GameCue.bigScore4: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.25,
    haptic: HapticGrade.heavy,
  ),
  GameCue.unlock: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.marketEntry: GameCueSpec(haptic: HapticGrade.impact),
  GameCue.marketTab: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.marketPage: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.stationAdvance: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.menuNavigate: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.cashOutOpen: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    haptic: HapticGrade.impact,
  ),
  GameCue.cashOutCollect: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.06,
    haptic: HapticGrade.impact,
  ),
  GameCue.newReveal: GameCueSpec(haptic: HapticGrade.impact),
  GameCue.bossIntro: GameCueSpec(
    preserveOriginalPitch: true,
    haptic: HapticGrade.heavy,
  ),
  GameCue.victory: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxReward,
    haptic: HapticGrade.heavy,
  ),
  GameCue.gameOver: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxDeny,
    haptic: HapticGrade.heavy,
  ),

  // --- T0: 공통 입력·팝업·화면 전환 ---
  GameCue.runStart: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.battleStart: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.heavy,
  ),
  GameCue.runRestore: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.choiceSelect: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.panelOpen: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.select,
  ),
  GameCue.noticeTop: GameCueSpec(preserveOriginalPitch: true),
  GameCue.noticeBottom: GameCueSpec(preserveOriginalPitch: true),

  // ── 전투 레인 ──
  GameCue.countTick: GameCueSpec(sfx: AssetPaths.sfxTimeTic, pitch: 1.35),
  GameCue.tileModifierFire: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.5,
    haptic: HapticGrade.select,
  ),
  GameCue.itemFire: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.3,
    haptic: HapticGrade.impact,
  ),
  GameCue.tileMove: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.place,
  ),
  GameCue.lineTransform: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
  GameCue.previewChange: GameCueSpec(preserveOriginalPitch: true),
  GameCue.confirmPress: GameCueSpec(
    preserveOriginalPitch: true,
    sfx: AssetPaths.sfxBtnSnd,
    haptic: HapticGrade.impact,
  ),
};

/// 의미 키로 소리와 햅틱을 같은 시점에 낸다.
class GameFeedback {
  GameFeedback._();

  /// [pitch]는 cue 기본 pitch에 곱한다. 정산 단계마다 올라가는 음 등에 쓴다.
  static void play(GameCue cue, {double pitch = 1}) {
    final spec = gameFeedbackCues[cue]!;
    final sfx = spec.sfx;
    if (sfx != null) {
      SoundManager.playSfx(
        sfx,
        pitch: spec.pitch * pitch,
        pitchVariance: spec.pitchVariance,
        preserveOriginalPitch: spec.preserveOriginalPitch,
      );
    }
    final haptic = spec.haptic;
    if (haptic != null) GameHaptics.play(haptic);
  }
}
