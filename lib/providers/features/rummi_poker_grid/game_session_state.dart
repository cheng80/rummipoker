import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
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
    this.activeRunScene = ActiveRunScene.battle,
    this.pendingResumeShop = false,
    this.debugFixtureId,
    this.selectedHandTile,
    this.selectedBoardRow,
    this.selectedBoardCol,
    this.jesterCatalog,
    this.selectedJesterOverlayIndex,
    this.stageFlowPhase = GameStageFlowPhase.none,
    this.stageScoreAdded = 0,
    this.activeSettlementLine,
    this.settlementBoardSnapshot = const {},
    this.settlementSequenceTick = 0,
    this.revision = 0,
  });

  final RummiPokerGridSession? session;
  final RummiRunProgress? runProgress;
  final ActiveRunStageSnapshot? stageStartSnapshot;
  final ActiveRunScene activeRunScene;
  final bool pendingResumeShop;
  final String? debugFixtureId;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final RummiJesterCatalog? jesterCatalog;
  final int? selectedJesterOverlayIndex;
  final GameStageFlowPhase stageFlowPhase;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
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
    ActiveRunScene? activeRunScene,
    bool? pendingResumeShop,
    Object? debugFixtureId = _unset,
    Object? selectedHandTile = _unset,
    Object? selectedBoardRow = _unset,
    Object? selectedBoardCol = _unset,
    Object? jesterCatalog = _unset,
    Object? selectedJesterOverlayIndex = _unset,
    GameStageFlowPhase? stageFlowPhase,
    int? stageScoreAdded,
    Object? activeSettlementLine = _unset,
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
      activeRunScene: activeRunScene ?? this.activeRunScene,
      pendingResumeShop: pendingResumeShop ?? this.pendingResumeShop,
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
      settlementBoardSnapshot:
          settlementBoardSnapshot ?? this.settlementBoardSnapshot,
      settlementSequenceTick:
          settlementSequenceTick ?? this.settlementSequenceTick,
      revision: revision ?? this.revision,
    );
  }
}

/// 전투 화면의 잠금/연출 단계.
enum GameStageFlowPhase { none, confirmSettlement, cleared, settlement }
