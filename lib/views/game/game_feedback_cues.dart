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

/// 현재 음원 7개(BtnSnd, Collect, Clear, TimeUp, Start, Fail, TimeTic)와
/// pitch·변주 조합으로 만든 매핑.
const Map<GameCue, GameCueSpec> gameFeedbackCues = {
  GameCue.buttonTap: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitchVariance: 0.04,
    haptic: HapticGrade.select,
  ),
  GameCue.tileSelect: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.2,
    pitchVariance: 0.06,
    haptic: HapticGrade.select,
  ),
  GameCue.tilePlace: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 0.85,
    pitchVariance: 0.08,
    haptic: HapticGrade.place,
  ),
  GameCue.tileDraw: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 0.9,
    pitchVariance: 0.1,
    haptic: HapticGrade.select,
  ),
  GameCue.discard: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 0.7,
    pitchVariance: 0.06,
    haptic: HapticGrade.place,
  ),
  GameCue.itemUse: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.15,
    pitchVariance: 0.04,
    haptic: HapticGrade.impact,
  ),
  GameCue.buy: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.1,
    pitchVariance: 0.04,
    haptic: HapticGrade.impact,
  ),
  GameCue.sell: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 0.85,
    pitchVariance: 0.04,
    haptic: HapticGrade.place,
  ),
  GameCue.reroll: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitchVariance: 0.08,
    haptic: HapticGrade.select,
  ),
  GameCue.deny: GameCueSpec(
    sfx: AssetPaths.sfxFail,
    pitch: 1.25,
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
    sfx: AssetPaths.sfxStart,
    pitchVariance: 0.05,
    haptic: HapticGrade.impact,
  ),
  GameCue.penalty: GameCueSpec(
    sfx: AssetPaths.sfxFail,
    pitch: 0.8,
    haptic: HapticGrade.heavy,
  ),
  GameCue.bigScore1: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    pitch: 0.9,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore2: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    haptic: HapticGrade.impact,
  ),
  GameCue.bigScore3: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    pitch: 1.12,
    haptic: HapticGrade.heavy,
  ),
  GameCue.bigScore4: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    pitch: 1.25,
    haptic: HapticGrade.heavy,
  ),
  GameCue.unlock: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    pitch: 1.2,
    haptic: HapticGrade.impact,
  ),
  GameCue.marketEntry: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.05,
    pitchVariance: 0.03,
    haptic: HapticGrade.impact,
  ),
  GameCue.marketTab: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.08,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.marketPage: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 0.96,
    pitchVariance: 0.04,
    haptic: HapticGrade.select,
  ),
  GameCue.stationAdvance: GameCueSpec(
    sfx: AssetPaths.sfxClear,
    pitch: 1.08,
    haptic: HapticGrade.impact,
  ),
  GameCue.menuNavigate: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 0.9,
    pitchVariance: 0.04,
    haptic: HapticGrade.select,
  ),
  GameCue.cashOutCollect: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 1.06,
    haptic: HapticGrade.impact,
  ),
  GameCue.newReveal: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.28,
    pitchVariance: 0.03,
    haptic: HapticGrade.impact,
  ),
  GameCue.bossIntro: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 0.7,
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
    pitch: 0.9,
    haptic: HapticGrade.heavy,
  ),
  GameCue.runRestore: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.1,
    haptic: HapticGrade.impact,
  ),
  GameCue.choiceSelect: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.1,
    pitchVariance: 0.03,
    haptic: HapticGrade.select,
  ),
  GameCue.panelOpen: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 1.15,
    haptic: HapticGrade.select,
  ),
  GameCue.noticeTop: GameCueSpec(sfx: AssetPaths.sfxTimeTic, pitch: 1.35),
  GameCue.noticeBottom: GameCueSpec(sfx: AssetPaths.sfxTimeTic, pitch: 1.6),

  // ── 전투 레인 ──
  GameCue.countTick: GameCueSpec(sfx: AssetPaths.sfxTimeTic, pitch: 1.35),
  GameCue.tileModifierFire: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.5,
    haptic: HapticGrade.select,
  ),
  GameCue.itemFire: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 1.3,
    haptic: HapticGrade.impact,
  ),
  GameCue.tileMove: GameCueSpec(
    sfx: AssetPaths.sfxBtnSnd,
    pitch: 1.1,
    pitchVariance: 0.06,
    haptic: HapticGrade.place,
  ),
  GameCue.lineTransform: GameCueSpec(
    sfx: AssetPaths.sfxStart,
    pitch: 0.95,
    haptic: HapticGrade.impact,
  ),
  GameCue.previewChange: GameCueSpec(
    sfx: AssetPaths.sfxTimeTic,
    pitch: 1.6,
    pitchVariance: 0.05,
  ),
  GameCue.confirmPress: GameCueSpec(
    sfx: AssetPaths.sfxCollect,
    pitch: 0.9,
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
