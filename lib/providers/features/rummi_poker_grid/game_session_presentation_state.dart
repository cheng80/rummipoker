part of 'game_session_state.dart';

/// 저장하지 않는 화면 입력, overlay, settlement animation 상태.
///
/// [GameSessionState]의 runtime source-of-truth와 분리해 둔다. 이 객체가 비어
/// 있거나 초기화되어도 저장/복원 결과와 실제 게임 진행은 달라지면 안 된다.
class GameSessionPresentationState {
  const GameSessionPresentationState({
    this.selectedHandTile,
    this.selectedBoardRow,
    this.selectedBoardCol,
    this.selectedJesterOverlayIndex,
    this.stageFlowPhase = GameStageFlowPhase.none,
    this.stageScoreAdded = 0,
    this.activeSettlementLine,
    this.activeSettlementStep = ScoringPresentationStep.none,
    this.activeSettlementEffectIndex,
    this.activeSettlementEffectIndexes = const [],
    this.settlementGoalDisplayScore,
    this.settlementBoardSnapshot = const {},
    this.settlementSequenceTick = 0,
  });

  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final int? selectedJesterOverlayIndex;
  final GameStageFlowPhase stageFlowPhase;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final List<int> activeSettlementEffectIndexes;
  final int? settlementGoalDisplayScore;
  final Map<String, Tile> settlementBoardSnapshot;
  final int settlementSequenceTick;

  static const Object unsetValue = Object();
  static const Object _unset = unsetValue;

  GameSessionPresentationState copyWith({
    Object? selectedHandTile = _unset,
    Object? selectedBoardRow = _unset,
    Object? selectedBoardCol = _unset,
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
  }) {
    return GameSessionPresentationState(
      selectedHandTile: selectedHandTile == _unset
          ? this.selectedHandTile
          : selectedHandTile as Tile?,
      selectedBoardRow: selectedBoardRow == _unset
          ? this.selectedBoardRow
          : selectedBoardRow as int?,
      selectedBoardCol: selectedBoardCol == _unset
          ? this.selectedBoardCol
          : selectedBoardCol as int?,
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
      activeSettlementEffectIndexes:
          activeSettlementEffectIndexes ?? this.activeSettlementEffectIndexes,
      settlementGoalDisplayScore: settlementGoalDisplayScore == _unset
          ? this.settlementGoalDisplayScore
          : settlementGoalDisplayScore as int?,
      settlementBoardSnapshot:
          settlementBoardSnapshot ?? this.settlementBoardSnapshot,
      settlementSequenceTick:
          settlementSequenceTick ?? this.settlementSequenceTick,
    );
  }
}
