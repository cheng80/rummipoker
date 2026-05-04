/// 전투/정산 연출의 시간 기준을 한곳에서 관리한다.
///
/// 실제 게임 결과와 저장 상태는 이 값에 의존하지 않고, 화면에서 읽히는 박자만 조정한다.
class GamePresentationTimings {
  const GamePresentationTimings._();

  static const Duration presentationPauseTick = Duration(milliseconds: 50);
  static const Duration itemEffectFeedback = Duration(seconds: 2);

  static const Duration settlementBoardLineStep = Duration(milliseconds: 720);
  static const Duration settlementHandRankStep = Duration(milliseconds: 720);
  static const Duration settlementOverlapStep = Duration(milliseconds: 680);
  static const Duration settlementConstraintStep = Duration(milliseconds: 1240);
  static const Duration settlementEffectStep = Duration(milliseconds: 1040);
  static const Duration settlementFinalScoreStep = Duration(milliseconds: 920);
  static const Duration settlementLineTail = Duration(milliseconds: 300);
  static const Duration settlementStepCalloutIn = Duration(milliseconds: 280);

  static const Duration stageClearOverlayPop = Duration(milliseconds: 320);
  static const Duration stageClearScoreCount = Duration(milliseconds: 720);
  static const Duration stageClearSpark = Duration(milliseconds: 520);

  static const Duration cashOutAutoInitialDelay = Duration(milliseconds: 80);
  static const Duration cashOutInitialDelay = Duration(milliseconds: 220);
  static const Duration cashOutAutoStepDelay = Duration(milliseconds: 80);
  static const Duration cashOutStepDelay = Duration(milliseconds: 260);
  static const Duration cashOutAutoAdvanceDelay = Duration(milliseconds: 120);
  static const Duration cashOutAdvanceDelay = Duration(milliseconds: 300);
  static const Duration cashOutLineReveal = Duration(milliseconds: 180);
  static const Duration cashOutLinePulse = Duration(milliseconds: 360);
  static const Duration cashOutCollectBadge = Duration(milliseconds: 420);
  static const Duration cashOutCoinBurst = Duration(milliseconds: 520);

  static const Duration hudGoalPulse = Duration(milliseconds: 420);
  static const Duration hudGoldPulse = Duration(milliseconds: 420);
  static const Duration bottomInfoPulseHold = Duration(milliseconds: 420);
  static const Duration bottomResourcePulse = Duration(milliseconds: 360);
  static const Duration handCountToggle = Duration(milliseconds: 120);
  static const Duration handTileTransition = Duration(milliseconds: 260);

  static const Duration boardTileState = Duration(milliseconds: 120);
  static const Duration boardTileMoveFlight = Duration(milliseconds: 280);
  static const Duration boardTileRemoveFlight = Duration(milliseconds: 280);
  static const Duration boardTilePlacePop = Duration(milliseconds: 260);
  static const Duration settlementTileLift = Duration(milliseconds: 420);

  static const Duration boardEffectVisible = Duration(milliseconds: 1300);
  static const Duration lineConfirmSweep = Duration(milliseconds: 520);
  static const Duration lineConfirmSweepStagger = Duration(milliseconds: 32);
  static const Duration constraintCellFlash = Duration(milliseconds: 760);
  static const Duration constraintCellFlashStagger = Duration(milliseconds: 28);
  static const Duration constraintImpactBadge = Duration(milliseconds: 900);
  static const Duration largeScoreBurstBadge = Duration(milliseconds: 680);
  static const Duration settlementScoreMote = Duration(milliseconds: 620);
  static const Duration settlementScoreMoteStagger = Duration(milliseconds: 34);

  static const Duration settlementEffectBurst = Duration(milliseconds: 940);
  static const Duration itemEffectSparkBurst = Duration(milliseconds: 560);
  static const Duration itemEffectToastIn = Duration(milliseconds: 340);

  static const Duration marketAutoAdvanceDelay = Duration(milliseconds: 120);
  static const Duration marketPurchaseFlight = Duration(milliseconds: 560);
  static const Duration marketDenyFeedbackHold = Duration(milliseconds: 560);
  static const Duration marketUseFeedbackHold = Duration(milliseconds: 620);
  static const Duration marketTabSwitch = Duration(milliseconds: 140);
  static const Duration marketEntryIntro = Duration(milliseconds: 220);
  static const Duration marketUseFeedbackIn = Duration(milliseconds: 260);
  static const Duration marketActionDenyShake = Duration(milliseconds: 360);
  static const Duration marketDenyBadgeIn = Duration(milliseconds: 260);
  static const Duration marketRerollSuccess = Duration(milliseconds: 420);
  static const Duration marketOfferReveal = Duration(milliseconds: 180);
  static const Duration marketOfferRevealStagger = Duration(milliseconds: 42);
  static const Duration marketGoldBadge = Duration(milliseconds: 460);
  static const Duration marketSlotPulse = Duration(milliseconds: 520);
}
