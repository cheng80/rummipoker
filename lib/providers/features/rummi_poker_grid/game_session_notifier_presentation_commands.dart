part of 'game_session_notifier.dart';

mixin GameSessionNotifierPresentationCommands
    on FamilyNotifier<GameSessionState, GameSessionArgs> {
  void _replaceState(GameSessionState next);

  void _replacePresentationState(GameSessionState next) {
    state = next;
  }

  void markDirty() {
    _replaceState(state.copyWith(revision: state.revision + 1));
  }

  void setJesterCatalog(RummiJesterCatalog? catalog) {
    _replacePresentationState(
      state.copyWith(jesterCatalog: catalog, revision: state.revision + 1),
    );
  }

  void setActiveRunScene(ActiveRunScene scene) {
    _replaceState(
      state.copyWith(
        runLoopPhase: _loopPhaseForScene(scene),
        activeRunScene: scene,
        revision: state.revision + 1,
      ),
    );
  }

  void setDebugMaxHandSize(int value) {
    final session = state.session;
    if (session == null) return;
    final ruleset = state.ruleset;
    final clamped = value.clamp(
      ruleset.minDebugMaxHandSize,
      ruleset.maxDebugMaxHandSize,
    );
    session.setDebugMaxHandSize(clamped);
    final selectedHandTile = state.selectedHandTile;
    _replaceState(
      state.copyWith(
        selectedHandTile:
            selectedHandTile != null && !session.hand.contains(selectedHandTile)
            ? null
            : selectedHandTile,
        revision: state.revision + 1,
      ),
    );
  }

  void clearSelections() {
    _replacePresentationState(
      state.copyWith(
        selectedHandTile: null,
        selectedBoardRow: null,
        selectedBoardCol: null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedHandTile(Tile? tile) {
    _replacePresentationState(
      state.copyWith(
        selectedHandTile: tile,
        selectedBoardRow: tile == null ? state.selectedBoardRow : null,
        selectedBoardCol: tile == null ? state.selectedBoardCol : null,
        revision: state.revision + 1,
      ),
    );
  }

  void toggleSelectedHandTile(Tile tile) {
    setSelectedHandTile(state.selectedHandTile == tile ? null : tile);
  }

  void setSelectedBoardCell(int? row, int? col) {
    _replacePresentationState(
      state.copyWith(
        selectedBoardRow: row,
        selectedBoardCol: col,
        selectedHandTile: row == null && col == null
            ? state.selectedHandTile
            : null,
        revision: state.revision + 1,
      ),
    );
  }

  void setSelectedJesterOverlayIndex(int? index) {
    _replacePresentationState(
      state.copyWith(
        selectedJesterOverlayIndex: index,
        revision: state.revision + 1,
      ),
    );
  }

  void setSettlementBoardSnapshot(Map<String, Tile> snapshot) {
    _replacePresentationState(
      state.copyWith(
        settlementBoardSnapshot: snapshot,
        revision: state.revision + 1,
      ),
    );
  }

  void setStageFlow({
    required GameStageFlowPhase phase,
    int? stageScoreAdded,
    ConfirmedLineBreakdown? activeSettlementLine,
    ScoringPresentationStep activeSettlementStep = ScoringPresentationStep.none,
    int? activeSettlementEffectIndex,
    List<int> activeSettlementEffectIndexes = const [],
    Object? settlementGoalDisplayScore = GameSessionState.unsetValue,
    Map<String, Tile>? settlementBoardSnapshot,
    bool bumpSettlementSequence = false,
  }) {
    _replacePresentationState(
      state.copyWith(
        stageFlowPhase: phase,
        stageScoreAdded: stageScoreAdded,
        activeSettlementLine: activeSettlementLine,
        activeSettlementStep: activeSettlementStep,
        activeSettlementEffectIndex: activeSettlementEffectIndex,
        activeSettlementEffectIndexes: activeSettlementEffectIndexes,
        settlementGoalDisplayScore: settlementGoalDisplayScore,
        settlementBoardSnapshot: settlementBoardSnapshot,
        settlementSequenceTick: bumpSettlementSequence
            ? state.settlementSequenceTick + 1
            : state.settlementSequenceTick,
        revision: state.revision + 1,
      ),
    );
  }

  void clearPendingItemPresentationEvents() {
    if (state.pendingItemPresentationEvents.isEmpty) return;
    _replacePresentationState(
      state.copyWith(
        pendingItemPresentationEvents: const [],
        revision: state.revision + 1,
      ),
    );
  }

  GameSessionState withValidSelections(GameSessionState current) {
    final session = current.session;
    if (session == null) return current;

    final selectedHandTile = current.selectedHandTile;
    final keepHandSelection =
        selectedHandTile != null && session.hand.contains(selectedHandTile);
    final selectedBoardRow = current.selectedBoardRow;
    final selectedBoardCol = current.selectedBoardCol;
    final keepBoardSelection =
        selectedBoardRow != null &&
        selectedBoardCol != null &&
        selectedBoardRow >= 0 &&
        selectedBoardRow < kBoardSize &&
        selectedBoardCol >= 0 &&
        selectedBoardCol < kBoardSize &&
        session.board.cellAt(selectedBoardRow, selectedBoardCol) != null;

    return current.copyWith(
      selectedHandTile: keepHandSelection ? selectedHandTile : null,
      selectedBoardRow: keepBoardSelection ? selectedBoardRow : null,
      selectedBoardCol: keepBoardSelection ? selectedBoardCol : null,
    );
  }
}
