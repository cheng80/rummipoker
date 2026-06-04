import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/item_presentation_event.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';
import '../../../services/new_run_setup.dart';

part 'game_session_presentation_state.dart';

/// `GameView`가 구독하는 현재 런의 상태 스냅샷이다.
///
/// 세션/진행도는 mutable 객체를 품고 있으므로, 내부 값이 바뀐 뒤에는
/// `revision`을 올려 Riverpod 구독 위젯이 다시 그려지게 한다.
///
/// 저장 가능한 정답 상태는 [session], [runProgress], [stageStartSnapshot]이다.
/// Battle / Market / Settlement의 애니메이션, 선택, 표시 지연값은 transient
/// presentation state이며 저장 데이터나 이어하기 복원 기준으로 사용하지 않는다.
class GameSessionState {
  GameSessionState({
    this.session,
    this.runProgress,
    this.stageStartSnapshot,
    this.stakeStartSnapshot,
    this.ruleset = RummiRuleset.currentDefaults,
    this.runModifier = NewRunModifier.basic,
    this.stationView,
    this.marketView,
    this.battleView,
    this.activeRunSaveView,
    this.runLoopPhase = GameRunLoopPhase.battle,
    this.activeRunScene = ActiveRunScene.battle,
    this.debugFixtureId,
    GameSessionPresentationState? presentationState,
    Tile? selectedHandTile,
    int? selectedBoardRow,
    int? selectedBoardCol,
    this.jesterCatalog,
    int? selectedJesterOverlayIndex,
    GameStageFlowPhase stageFlowPhase = GameStageFlowPhase.none,
    int stageScoreAdded = 0,
    ConfirmedLineBreakdown? activeSettlementLine,
    ScoringPresentationStep activeSettlementStep = ScoringPresentationStep.none,
    int? activeSettlementEffectIndex,
    List<int> activeSettlementEffectIndexes = const [],
    int? settlementGoalDisplayScore,
    Map<String, Tile> settlementBoardSnapshot = const {},
    int settlementSequenceTick = 0,
    this.revision = 0,
  }) : presentation =
           presentationState ??
           GameSessionPresentationState(
             selectedHandTile: selectedHandTile,
             selectedBoardRow: selectedBoardRow,
             selectedBoardCol: selectedBoardCol,
             selectedJesterOverlayIndex: selectedJesterOverlayIndex,
             stageFlowPhase: stageFlowPhase,
             stageScoreAdded: stageScoreAdded,
             activeSettlementLine: activeSettlementLine,
             activeSettlementStep: activeSettlementStep,
             activeSettlementEffectIndex: activeSettlementEffectIndex,
             activeSettlementEffectIndexes: activeSettlementEffectIndexes,
             settlementGoalDisplayScore: settlementGoalDisplayScore,
             settlementBoardSnapshot: settlementBoardSnapshot,
             settlementSequenceTick: settlementSequenceTick,
           );

  final RummiPokerGridSession? session;
  final RummiRunProgress? runProgress;
  final ActiveRunStageSnapshot? stageStartSnapshot;
  final ActiveRunStageSnapshot? stakeStartSnapshot;
  final RummiRuleset ruleset;
  final NewRunModifier runModifier;
  final RummiStationRuntimeFacade? stationView;
  final RummiMarketRuntimeFacade? marketView;
  final RummiBattleRuntimeFacade? battleView;
  final RummiActiveRunSaveFacade? activeRunSaveView;
  final GameRunLoopPhase runLoopPhase;
  final ActiveRunScene activeRunScene;
  final String? debugFixtureId;
  final GameSessionPresentationState presentation;

  final RummiJesterCatalog? jesterCatalog;

  final int revision;

  Tile? get selectedHandTile => presentation.selectedHandTile;
  int? get selectedBoardRow => presentation.selectedBoardRow;
  int? get selectedBoardCol => presentation.selectedBoardCol;
  int? get selectedJesterOverlayIndex =>
      presentation.selectedJesterOverlayIndex;
  GameStageFlowPhase get stageFlowPhase => presentation.stageFlowPhase;
  int get stageScoreAdded => presentation.stageScoreAdded;
  ConfirmedLineBreakdown? get activeSettlementLine =>
      presentation.activeSettlementLine;
  ScoringPresentationStep get activeSettlementStep =>
      presentation.activeSettlementStep;
  int? get activeSettlementEffectIndex =>
      presentation.activeSettlementEffectIndex;
  List<int> get activeSettlementEffectIndexes =>
      presentation.activeSettlementEffectIndexes;
  int? get settlementGoalDisplayScore =>
      presentation.settlementGoalDisplayScore;
  Map<String, Tile> get settlementBoardSnapshot =>
      presentation.settlementBoardSnapshot;
  int get settlementSequenceTick => presentation.settlementSequenceTick;
  List<ItemPresentationEvent> get pendingItemPresentationEvents =>
      presentation.pendingItemPresentationEvents;

  bool get isReady => session != null && runProgress != null;
  bool get isUiLocked => stageFlowPhase != GameStageFlowPhase.none;

  static const Object unsetValue = Object();
  static const Object _unset = unsetValue;

  GameSessionState copyWith({
    Object? session = _unset,
    Object? runProgress = _unset,
    Object? stageStartSnapshot = _unset,
    Object? stakeStartSnapshot = _unset,
    RummiRuleset? ruleset,
    NewRunModifier? runModifier,
    Object? stationView = _unset,
    Object? marketView = _unset,
    Object? battleView = _unset,
    Object? activeRunSaveView = _unset,
    GameRunLoopPhase? runLoopPhase,
    ActiveRunScene? activeRunScene,
    Object? debugFixtureId = _unset,
    Object? presentationState = _unset,
    Object? selectedHandTile = _unset,
    Object? selectedBoardRow = _unset,
    Object? selectedBoardCol = _unset,
    Object? jesterCatalog = _unset,
    Object? selectedJesterOverlayIndex = _unset,
    GameStageFlowPhase? stageFlowPhase,
    int? stageScoreAdded,
    Object? activeSettlementLine = _unset,
    ScoringPresentationStep? activeSettlementStep,
    Object? activeSettlementEffectIndex = _unset,
    List<int>? activeSettlementEffectIndexes,
    Object? settlementGoalDisplayScore = _unset,
    Map<String, Tile>? settlementBoardSnapshot,
    int? settlementSequenceTick,
    List<ItemPresentationEvent>? pendingItemPresentationEvents,
    int? revision,
  }) {
    final nextPresentation = presentationState == _unset
        ? presentation.copyWith(
            selectedHandTile: selectedHandTile,
            selectedBoardRow: selectedBoardRow,
            selectedBoardCol: selectedBoardCol,
            selectedJesterOverlayIndex: selectedJesterOverlayIndex,
            stageFlowPhase: stageFlowPhase,
            stageScoreAdded: stageScoreAdded,
            activeSettlementLine: activeSettlementLine,
            activeSettlementStep: activeSettlementStep,
            activeSettlementEffectIndex: activeSettlementEffectIndex,
            activeSettlementEffectIndexes: activeSettlementEffectIndexes,
            settlementGoalDisplayScore: settlementGoalDisplayScore,
            settlementBoardSnapshot: settlementBoardSnapshot,
            settlementSequenceTick: settlementSequenceTick,
            pendingItemPresentationEvents: pendingItemPresentationEvents,
          )
        : presentationState as GameSessionPresentationState;
    return GameSessionState(
      session: session == _unset
          ? this.session
          : session as RummiPokerGridSession?,
      runProgress: runProgress == _unset
          ? this.runProgress
          : runProgress as RummiRunProgress?,
      stageStartSnapshot: stageStartSnapshot == _unset
          ? this.stageStartSnapshot
          : stageStartSnapshot as ActiveRunStageSnapshot?,
      stakeStartSnapshot: stakeStartSnapshot == _unset
          ? this.stakeStartSnapshot
          : stakeStartSnapshot as ActiveRunStageSnapshot?,
      ruleset: ruleset ?? this.ruleset,
      runModifier: runModifier ?? this.runModifier,
      stationView: stationView == _unset
          ? this.stationView
          : stationView as RummiStationRuntimeFacade?,
      marketView: marketView == _unset
          ? this.marketView
          : marketView as RummiMarketRuntimeFacade?,
      battleView: battleView == _unset
          ? this.battleView
          : battleView as RummiBattleRuntimeFacade?,
      activeRunSaveView: activeRunSaveView == _unset
          ? this.activeRunSaveView
          : activeRunSaveView as RummiActiveRunSaveFacade?,
      runLoopPhase: runLoopPhase ?? this.runLoopPhase,
      activeRunScene: activeRunScene ?? this.activeRunScene,
      debugFixtureId: debugFixtureId == _unset
          ? this.debugFixtureId
          : debugFixtureId as String?,
      presentationState: nextPresentation,
      jesterCatalog: jesterCatalog == _unset
          ? this.jesterCatalog
          : jesterCatalog as RummiJesterCatalog?,
      revision: revision ?? this.revision,
    );
  }
}

/// 장기 `Battle -> Settlement -> Market -> Next Station` 루프를 읽기 위한 단계 구분.
enum GameRunLoopPhase { battle, settlement, market, nextStationTransition }

/// 전투 화면의 잠금/연출 단계.
enum GameStageFlowPhase { none, confirmSettlement, cleared, settlement }

enum ScoringPresentationStep {
  none,
  boardLine,
  handRank,
  overlap,
  constraint,
  jester,
  tile,
  item,
  finalScore,
}
