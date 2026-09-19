import 'package:flutter/widgets.dart';

/// 전투/정산 연출의 시간 기준을 한곳에서 관리한다.
///
/// 실제 게임 결과와 저장 상태는 이 값에 의존하지 않고, 화면에서 읽히는 박자만 조정한다.
class GamePresentationTimings {
  const GamePresentationTimings._();

  static const Duration presentationPauseTick = Duration(milliseconds: 50);
  static const Duration inactiveLifecycleDebounce = Duration(milliseconds: 250);
  static const Duration itemEffectFeedback = Duration(seconds: 2);
  static const Duration gameOverFade = Duration(seconds: 2);

  static const Duration stageClearClearedHold = Duration(milliseconds: 850);
  static const Duration stageClearSettlementHold = Duration(milliseconds: 950);
  static const Duration stageTransitionOverlayHold = Duration(
    milliseconds: 520,
  );
  static const Duration settlementToMarketOverlayIn = Duration(
    milliseconds: 380,
  );
  static const Duration nextStationOverlayIn = Duration(milliseconds: 420);

  // 전투 레인: boardLine은 타일 tick 뒤 남은 정지 시간이다.
  static const Duration settlementBoardLineStep = Duration(milliseconds: 260);
  static const Duration settlementHandRankStep = Duration(milliseconds: 560);
  static const Duration settlementOverlapStep = Duration(milliseconds: 520);
  static const Duration settlementConstraintStep = Duration(milliseconds: 960);
  static const Duration settlementEffectStep = Duration(milliseconds: 640);
  static const Duration settlementFinalScoreStep = Duration(milliseconds: 720);
  static const Duration settlementLineTail = Duration(milliseconds: 180);
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
  static const Duration handCapacityPulse = Duration(milliseconds: 620);
  static const Duration handTileTransition = Duration(milliseconds: 260);
  static const Duration tileChoiceSelectFeedback = Duration(milliseconds: 220);

  static const Duration boardTileState = Duration(milliseconds: 120);
  static const Duration boardTileMoveFlight = Duration(milliseconds: 280);
  static const Duration boardMoveBonusFlash = Duration(milliseconds: 620);
  static const Duration fateLineTransformFlash = Duration(milliseconds: 920);
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
  static const Duration ritualGoldFlight = Duration(milliseconds: 1400);
  static const Duration ritualDeckTileFlight = Duration(milliseconds: 1800);
  static const Duration boardScoringCalloutIn = Duration(milliseconds: 420);
  static const Duration scoringPreviewFadeIn = Duration(milliseconds: 260);
  static const Duration scoringPreviewScale = Duration(milliseconds: 300);

  static const Duration marketAutoAdvanceDelay = Duration(milliseconds: 120);
  static const Duration marketPurchaseFlight = Duration(milliseconds: 560);
  static const Duration marketDenyFeedbackHold = Duration(milliseconds: 560);
  static const Duration marketUseFeedbackHold = Duration(milliseconds: 1800);
  static const Duration marketTabSwitch = Duration(milliseconds: 140);
  static const Duration marketEntryIntro = Duration(milliseconds: 220);
  static const Duration marketUseFeedbackIn = Duration(milliseconds: 260);
  static const Duration marketActionDenyShake = Duration(milliseconds: 360);
  static const Duration marketDenyBadgeIn = Duration(milliseconds: 260);
  static const Duration marketRerollSuccess = Duration(milliseconds: 420);
  static const Duration marketOfferReveal = Duration(milliseconds: 180);
  static const Duration marketOfferRevealStagger = Duration(milliseconds: 42);
  static const Duration marketPassiveEffectPulse = Duration(milliseconds: 620);
  static const Duration marketGoldBadge = Duration(milliseconds: 460);
  static const Duration marketGoldGainBadge = Duration(milliseconds: 1400);
  static const Duration marketSlotPulse = Duration(milliseconds: 520);
  static const Duration marketSlotUnlockBannerDelay = Duration(
    milliseconds: 850,
  );
  static const Duration marketSlotUnlockBannerVisible = Duration(
    milliseconds: 1250,
  );
  static const Duration marketSlotUnlockPulse = Duration(milliseconds: 1200);
  static const Duration marketSlotUnlockBannerIn = Duration(milliseconds: 420);

  static const Duration debugGameOverOnLoadDelay = Duration(milliseconds: 220);

  // --- T0: 공통 입력·팝업·화면 전환 ---
  /// 팝업 scale-pop 등장과 barrier fade.
  static const Duration dialogPopIn = Duration(milliseconds: 220);

  /// 팝업 닫힘. 등장보다 짧게 둔다.
  static const Duration dialogPopOut = Duration(milliseconds: 140);

  /// 화면 전환 fade·slide. 지시 상한 400ms보다 짧게 둔다.
  static const Duration routeTransition = Duration(milliseconds: 280);
  static const Duration routeReverseTransition = Duration(milliseconds: 220);

  /// 타이틀 이탈 때 BGM 페이드 아웃.
  static const Duration titleBgmFadeOut = Duration(milliseconds: 320);

  /// 거절 좌우 흔들림.
  static const Duration denyShake = Duration(milliseconds: 320);

  /// 난이도·modifier·Archive 카드 선택 상태 전환.
  static const Duration choiceSelect = Duration(milliseconds: 180);

  // ── 전투 레인(T2 정산 클라이맥스 · T1 전투 입력) ──
  /// 줄 안 타일 하나가 반응하는 박자.
  static const Duration settlementTileTick = Duration(milliseconds: 80);

  /// Jester 한 장이 발동하는 박자(왼쪽부터 한 장씩).
  static const Duration settlementJesterFire = Duration(milliseconds: 420);

  /// Jester 발동 모션(내려찍기·부풀기·회전 섬광) 길이.
  static const Duration jesterFireMotion = Duration(milliseconds: 380);

  /// 목표 점수·골드 count-up과 진행 바 채움.
  static const Duration hudCountUp = Duration(milliseconds: 500);

  /// count-up tick 소리 간격.
  static const Duration hudCountTickInterval = Duration(milliseconds: 70);

  /// 상위 등급 줄의 hit-stop.
  static const Duration settlementGradeHitStop = Duration(milliseconds: 90);

  /// 목표 달성 피니셔의 마지막 타격 hit-stop.
  static const Duration settlementFinisherHitStop = Duration(milliseconds: 100);

  /// 피니셔 finalScore 스텝의 슬로모션 배율.
  static const double settlementFinisherSlowMo = 0.5;

  /// 확정 후 contributor 타일이 줄 방향을 따라 터지는 간격.
  static const Duration contributorClearStagger = Duration(milliseconds: 35);

  /// contributor 타일 하나가 터지며 사라지는 길이.
  static const Duration contributorClearPop = Duration(milliseconds: 220);

  /// 빈 칸에 남는 잔광.
  static const Duration contributorClearAfterglow = Duration(milliseconds: 420);

  /// 정산 결과 시트 등장 전환.
  static const Duration cashOutSheetIn = Duration(milliseconds: 260);

  /// 줄 예고 숨쉬기 한 주기와 반복 횟수(유휴 시 멈춘다).
  static const Duration lineHintBreath = Duration(milliseconds: 1400);
  static const int lineHintBreathCycles = 3;

  /// 타일 착지 뒤 주변 타일 파문 간격.
  static const Duration landingRippleStagger = Duration(milliseconds: 25);

  /// 덱→손패, 손패→보드 호 비행.
  static const Duration tileArcFlight = Duration(milliseconds: 300);

  /// 전투 진입 stagger.
  static const Duration battleEntryStagger = Duration(milliseconds: 28);
  static const Duration battleEntryDeal = Duration(milliseconds: 320);

  /// Boss 제약 표시가 찍히는 모션.
  static const Duration bossMarkStamp = Duration(milliseconds: 360);

  // --- T4: 흐름과 메타 화면 ---
  /// 화면 진입 때 카드·배너가 차례로 들어오는 한 장의 길이와 간격.
  static const Duration flowEntranceIn = Duration(milliseconds: 320);
  static const Duration flowEntranceStagger = Duration(milliseconds: 80);

  /// Boss 인트로 배너 등장, 이름 도장, 제약 아이콘 낙하 간격.
  static const Duration bossIntroBannerIn = Duration(milliseconds: 280);
  static const Duration bossIntroTitleStamp = Duration(milliseconds: 300);
  static const Duration bossIntroIconDrop = Duration(milliseconds: 260);
  static const Duration bossIntroIconStagger = Duration(milliseconds: 90);

  /// 배너가 닫힌 뒤 제약 표시가 보드 칸으로 날아가는 길이와 칸 사이 간격.
  static const Duration bossMarkFlight = Duration(milliseconds: 420);
  static const Duration bossMarkFlightStagger = Duration(milliseconds: 60);

  /// 비행이 끝났다는 신호가 오지 않아도 이 시간이 더 지나면 제약 표시를 드러낸다.
  static const Duration bossMarkFlightGuard = Duration(milliseconds: 600);

  /// Blind 카드 고른 뒤 전투로 넘어가기 전 선택 강조(입력 잠금 상한).
  static const Duration blindPlayCommit = Duration(milliseconds: 240);

  /// Blind 상태 배지 전환과 Boss 위험 표시 맥동(횟수만큼 돌고 멈춘다).
  static const Duration blindBadgeSwap = Duration(milliseconds: 260);
  static const Duration blindDangerPulse = Duration(milliseconds: 520);
  static const int blindDangerPulseCycles = 3;

  /// 런 진행 띠에서 현재 위치가 한 칸 나아가는 길이.
  static const Duration runProgressAdvance = Duration(milliseconds: 520);

  /// 런 완료 승리 장면 전체 길이(탭으로 건너뛸 수 있다)와 수치 tally 간격.
  static const Duration runVictoryHold = Duration(milliseconds: 2400);
  static const Duration runVictoryTallyStagger = Duration(milliseconds: 260);
  static const Duration runVictoryBgmFadeOut = Duration(milliseconds: 420);

  /// 게임오버 결과 창의 기억 카드 공개.
  static const Duration gameOverRewardReveal = Duration(milliseconds: 420);
  static const Duration gameOverRewardRevealDelay = Duration(milliseconds: 260);

  /// 타이틀 로고 내려앉기와 강도 '강'의 idle 흔들림 한 주기.
  static const Duration titleLogoSettle = Duration(milliseconds: 520);
  static const Duration titleLogoIdle = Duration(milliseconds: 3200);

  /// Archive 새 항목 카드가 처음 열릴 때 뒤집히는 공개.
  static const Duration archiveNewReveal = Duration(milliseconds: 420);
}

/// 반복되는 duration/stagger 조합을 이름 붙여 쓰는 presentation 전용 보조 타입.
///
/// 저장 가능한 runtime state를 들지 않고, 화면 박자 계산만 담당한다.
class GamePresentationCue {
  const GamePresentationCue({
    required this.duration,
    this.stagger = Duration.zero,
  });

  final Duration duration;
  final Duration stagger;

  Duration delayFor(int index) => stagger * index;
}

class GamePresentationCues {
  const GamePresentationCues._();

  static const GamePresentationCue lineConfirmSweep = GamePresentationCue(
    duration: GamePresentationTimings.lineConfirmSweep,
    stagger: GamePresentationTimings.lineConfirmSweepStagger,
  );

  static const GamePresentationCue constraintCellFlash = GamePresentationCue(
    duration: GamePresentationTimings.constraintCellFlash,
    stagger: GamePresentationTimings.constraintCellFlashStagger,
  );

  static const GamePresentationCue settlementScoreMote = GamePresentationCue(
    duration: GamePresentationTimings.settlementScoreMote,
    stagger: GamePresentationTimings.settlementScoreMoteStagger,
  );

  static const GamePresentationCue marketOfferReveal = GamePresentationCue(
    duration: GamePresentationTimings.marketOfferReveal,
    stagger: GamePresentationTimings.marketOfferRevealStagger,
  );
}

class GamePresentationMotion {
  const GamePresentationMotion._();

  static double flightProgress(double value) {
    final t = value.clamp(0.0, 1.0);
    if (t < 0.5) return 8 * t * t * t * t;
    final inverse = -2 * t + 2;
    return 1 - (inverse * inverse * inverse * inverse) / 2;
  }

  static Offset flightOffset(Offset start, Offset end, double value) =>
      Offset.lerp(start, end, flightProgress(value))!;

  static Alignment flightAlignment(
    Alignment start,
    Alignment end,
    double value,
  ) => Alignment.lerp(start, end, flightProgress(value))!;
}
