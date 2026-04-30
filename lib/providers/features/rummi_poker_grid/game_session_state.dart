import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';

/// `GameView`가 구독하는 현재 런의 UI 상태 스냅샷이다.
///
/// 세션/진행도는 mutable 객체를 품고 있으므로, 내부 값이 바뀐 뒤에는
/// `revision`을 올려 Riverpod 구독 위젯이 다시 그려지게 한다.
class GameSessionState {
  const GameSessionState({
    this.session,
    this.runProgress,
    this.stageStartSnapshot,
    this.ruleset = RummiRuleset.currentDefaults,
    this.stationView,
    this.marketView,
    this.battleView,
    this.activeRunSaveView,
    this.runLoopPhase = GameRunLoopPhase.battle,
    this.activeRunScene = ActiveRunScene.battle,
    this.debugFixtureId,
    this.selectedHandTile,
    this.selectedBoardRow,
    this.selectedBoardCol,
    this.jesterCatalog,
    this.selectedJesterOverlayIndex,
    this.stageFlowPhase = GameStageFlowPhase.none,
    this.stageScoreAdded = 0,
    this.activeSettlementLine,
    this.activeSettlementStep = ScoringPresentationStep.none,
    this.activeSettlementEffectIndex,
    this.settlementBoardSnapshot = const {},
    this.settlementSequenceTick = 0,
    this.revision = 0,
  });

  final RummiPokerGridSession? session;
  final RummiRunProgress? runProgress;
  final ActiveRunStageSnapshot? stageStartSnapshot;
  final RummiRuleset ruleset;
  final RummiStationRuntimeFacade? stationView;
  final RummiMarketRuntimeFacade? marketView;
  final RummiBattleRuntimeFacade? battleView;
  final RummiActiveRunSaveFacade? activeRunSaveView;
  final GameRunLoopPhase runLoopPhase;
  final ActiveRunScene activeRunScene;
  final String? debugFixtureId;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final RummiJesterCatalog? jesterCatalog;
  final int? selectedJesterOverlayIndex;
  final GameStageFlowPhase stageFlowPhase;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final Map<String, Tile> settlementBoardSnapshot;
  final int settlementSequenceTick;
  final int revision;

  bool get isReady => session != null && runProgress != null;
  bool get isUiLocked => stageFlowPhase != GameStageFlowPhase.none;

  static const Object _unset = Object();

  GameSessionState copyWith({
    Object? session = _unset,
    Object? runProgress = _unset,
    Object? stageStartSnapshot = _unset,
    RummiRuleset? ruleset,
    Object? stationView = _unset,
    Object? marketView = _unset,
    Object? battleView = _unset,
    Object? activeRunSaveView = _unset,
    GameRunLoopPhase? runLoopPhase,
    ActiveRunScene? activeRunScene,
    Object? debugFixtureId = _unset,
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
    Map<String, Tile>? settlementBoardSnapshot,
    int? settlementSequenceTick,
    int? revision,
  }) {
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
      ruleset: ruleset ?? this.ruleset,
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
      selectedHandTile: selectedHandTile == _unset
          ? this.selectedHandTile
          : selectedHandTile as Tile?,
      selectedBoardRow: selectedBoardRow == _unset
          ? this.selectedBoardRow
          : selectedBoardRow as int?,
      selectedBoardCol: selectedBoardCol == _unset
          ? this.selectedBoardCol
          : selectedBoardCol as int?,
      jesterCatalog: jesterCatalog == _unset
          ? this.jesterCatalog
          : jesterCatalog as RummiJesterCatalog?,
      selectedJesterOverlayIndex: selectedJesterOverlayIndex == _unset
          ? this.selectedJesterOverlayIndex
          : selectedJesterOverlayIndex as int?,
      stageFlowPhase: stageFlowPhase ?? this.stageFlowPhase,
      stageScoreAdded: stageScoreAdded ?? this.stageScoreAdded,
      activeSettlementLine: activeSettlementLine == _unset
          ? this.activeSettlementLine
          : activeSettlementLine as ConfirmedLineBreakdown?,
      activeSettlementStep: activeSettlementStep ?? this.activeSettlementStep,
      activeSettlementEffectIndex: activeSettlementEffectIndex == _unset
          ? this.activeSettlementEffectIndex
          : activeSettlementEffectIndex as int?,
      settlementBoardSnapshot:
          settlementBoardSnapshot ?? this.settlementBoardSnapshot,
      settlementSequenceTick:
          settlementSequenceTick ?? this.settlementSequenceTick,
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
  item,
  finalScore,
}
