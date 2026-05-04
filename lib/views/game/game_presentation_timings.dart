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

  static const Duration boardEffectVisible = Duration(milliseconds: 1300);
  static const Duration lineConfirmSweep = Duration(milliseconds: 520);
  static const Duration constraintCellFlash = Duration(milliseconds: 760);
  static const Duration constraintImpactBadge = Duration(milliseconds: 900);
  static const Duration largeScoreBurstBadge = Duration(milliseconds: 680);
  static const Duration settlementScoreMote = Duration(milliseconds: 620);

  static const Duration settlementEffectBurst = Duration(milliseconds: 940);
  static const Duration itemEffectSparkBurst = Duration(milliseconds: 560);
  static const Duration itemEffectToastIn = Duration(milliseconds: 340);
}
