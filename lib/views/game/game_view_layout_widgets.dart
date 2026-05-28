part of '../game_view.dart';

class _GameSurface extends StatelessWidget {
  const _GameSurface({
    required this.battle,
    required this.station,
    required this.market,
    required this.stageFlowPhase,
    required this.presentationPaused,
    required this.stageScoreAdded,
    required this.activeSettlementLine,
    required this.activeSettlementStep,
    required this.activeSettlementEffectIndex,
    required this.activeSettlementEffectIndexes,
    required this.settlementGoalDisplayScore,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.boardMoveMode,
    required this.pendingBoardMoveSourceRow,
    required this.pendingBoardMoveSourceCol,
    required this.boardMoveBonusTargetCellKey,
    required this.boardMoveBonusFlashTick,
    required this.selectedJesterOverlayIndex,
    required this.selectedBattleItemSlot,
    required this.selectedHandInfoTile,
    required this.itemEffectFeedback,
    required this.itemEffectFeedbackTick,
    required this.suppressDebugChrome,
    required this.difficultyLabel,
    required this.battleBoardTutorialKey,
    required this.battlePreviewTutorialKey,
    required this.battleActionsTutorialKey,
    required this.battleHandTutorialKey,
    required this.onOptionsTap,
    required this.onTutorialTap,
    required this.onRunInfoTap,
    required this.onBlindInfoTap,
    required this.onDebugTap,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onHandTileLongPress,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onStartBoardMove,
    required this.onBattleItemTap,
    required this.onConfirm,
    required this.onClearSelection,
    required this.onJesterSell,
    required this.onJesterOverlayClose,
    required this.onBattleItemUse,
    required this.onBattleItemOverlayClose,
    required this.onHandTileInfoOverlayClose,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final GameStageFlowPhase stageFlowPhase;
  final bool presentationPaused;
  final int stageScoreAdded;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final List<int> activeSettlementEffectIndexes;
  final int? settlementGoalDisplayScore;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final bool boardMoveMode;
  final int? pendingBoardMoveSourceRow;
  final int? pendingBoardMoveSourceCol;
  final String? boardMoveBonusTargetCellKey;
  final int boardMoveBonusFlashTick;
  final int? selectedJesterOverlayIndex;
  final RummiBattleItemSlotView? selectedBattleItemSlot;
  final Tile? selectedHandInfoTile;
  final _ItemEffectFeedback? itemEffectFeedback;
  final int itemEffectFeedbackTick;
  final bool suppressDebugChrome;
  final String difficultyLabel;
  final GlobalKey battleBoardTutorialKey;
  final GlobalKey battlePreviewTutorialKey;
  final GlobalKey battleActionsTutorialKey;
  final GlobalKey battleHandTutorialKey;
  final VoidCallback onOptionsTap;
  final VoidCallback onTutorialTap;
  final VoidCallback onRunInfoTap;
  final VoidCallback onBlindInfoTap;
  final VoidCallback onDebugTap;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final ValueChanged<Tile> onHandTileLongPress;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onStartBoardMove;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemTap;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;
  final VoidCallback onJesterSell;
  final VoidCallback onJesterOverlayClose;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemUse;
  final VoidCallback onBattleItemOverlayClose;
  final VoidCallback onHandTileInfoOverlayClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kGameSurfaceFrameRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiPalette.battleFrameGradientStart,
            GameUiPalette.battleFrameGradientMid,
            GameUiPalette.battleFrameGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: GameUiPalette.ink.withValues(alpha: 0.4),
            blurRadius: kGameSurfaceShadowBlur,
            spreadRadius: kGameSurfaceShadowSpread,
          ),
        ],
        border: Border.all(
          color: GameUiPalette.marketFrameBorder.withValues(alpha: 0.55),
          width: kGameSurfaceBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kGameSurfaceFrameRadius),
        child: Stack(
          children: [
            const Positioned.fill(child: GameTableBackdrop()),
            Positioned.fill(
              child: Padding(
                padding: kBattleSurfacePadding,
                child: _GameLayout(
                  battle: battle,
                  station: station,
                  market: market,
                  activeSettlementEffects:
                      activeSettlementLine?.effects ?? const [],
                  activeSettlementStep: activeSettlementStep,
                  activeSettlementEffectIndex: activeSettlementEffectIndex,
                  activeSettlementEffectIndexes: activeSettlementEffectIndexes,
                  settlementGoalDisplayScore: settlementGoalDisplayScore,
                  activeSettlementLine: activeSettlementLine,
                  settlementSequenceTick: settlementSequenceTick,
                  settlementBoardSnapshot: settlementBoardSnapshot,
                  selectedHandTile: selectedHandTile,
                  selectedBoardRow: selectedBoardRow,
                  selectedBoardCol: selectedBoardCol,
                  boardMoveMode: boardMoveMode,
                  pendingBoardMoveSourceRow: pendingBoardMoveSourceRow,
                  pendingBoardMoveSourceCol: pendingBoardMoveSourceCol,
                  boardMoveBonusTargetCellKey: boardMoveBonusTargetCellKey,
                  boardMoveBonusFlashTick: boardMoveBonusFlashTick,
                  selectedJesterOverlayIndex: selectedJesterOverlayIndex,
                  selectedBattleItemSlot: selectedBattleItemSlot,
                  suppressDebugChrome: suppressDebugChrome,
                  difficultyLabel: difficultyLabel,
                  battleBoardTutorialKey: battleBoardTutorialKey,
                  battlePreviewTutorialKey: battlePreviewTutorialKey,
                  battleActionsTutorialKey: battleActionsTutorialKey,
                  battleHandTutorialKey: battleHandTutorialKey,
                  onOptionsTap: onOptionsTap,
                  onTutorialTap: onTutorialTap,
                  onRunInfoTap: onRunInfoTap,
                  onBlindInfoTap: onBlindInfoTap,
                  onDebugTap: onDebugTap,
                  onJesterTap: onJesterTap,
                  onHandTileTap: onHandTileTap,
                  onHandTileLongPress: onHandTileLongPress,
                  onBoardCellTap: onBoardCellTap,
                  onDraw: onDraw,
                  onBoardDiscard: onBoardDiscard,
                  onHandDiscard: onHandDiscard,
                  onStartBoardMove: onStartBoardMove,
                  onBattleItemTap: onBattleItemTap,
                  onConfirm: onConfirm,
                  onClearSelection: onClearSelection,
                ),
              ),
            ),
            if (!presentationPaused &&
                stageFlowPhase == GameStageFlowPhase.confirmSettlement)
              if (_showsFloatingSettlementBurst(activeSettlementStep))
                Positioned.fill(
                  child: GameFloatingSettlementBurst(
                    key: ValueKey(
                      'settlement-$settlementSequenceTick-$activeSettlementStep-$activeSettlementEffectIndex',
                    ),
                    line: activeSettlementLine,
                    step: activeSettlementStep,
                    effectIndex: _floatingSettlementEffectIndex(
                      activeSettlementEffectIndex,
                      activeSettlementEffectIndexes,
                    ),
                  ),
                ),
            if (!presentationPaused &&
                (stageFlowPhase == GameStageFlowPhase.cleared ||
                    stageFlowPhase == GameStageFlowPhase.settlement))
              Positioned.fill(
                child: GameStageClearOverlay(
                  phase: stageFlowPhase,
                  stageIndex: battle.stageIndex,
                  scoreAdded: stageScoreAdded,
                ),
              ),
            if (itemEffectFeedback != null)
              const Positioned.fill(child: GameInputBarrier.feedback()),
            if (itemEffectFeedback != null)
              Positioned(
                left: 22,
                right: 22,
                bottom: 238,
                child: _ItemEffectFeedbackToast(
                  key: ValueKey('item-effect-$itemEffectFeedbackTick'),
                  feedback: itemEffectFeedback!,
                ),
              ),
            if (selectedJesterOverlayIndex != null &&
                selectedJesterOverlayIndex! < market.ownedEntries.length)
              Positioned.fill(
                child: Stack(
                  children: [
                    const GameInputBarrier.modal(),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameJesterInfoOverlay(
                        card: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .card,
                        runtimeValueText: jesterRuntimeValueText(
                          market.ownedEntries[selectedJesterOverlayIndex!].card,
                          market.runtimeSnapshot,
                          slotIndex: selectedJesterOverlayIndex!,
                        ),
                        sellGold: market
                            .ownedEntries[selectedJesterOverlayIndex!]
                            .sellPrice,
                        onSell: onJesterSell,
                        onClose: onJesterOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedBattleItemSlot != null)
              Positioned.fill(
                child: Stack(
                  children: [
                    const GameInputBarrier.modal(),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameBattleItemInfoOverlay(
                        itemSlot: selectedBattleItemSlot!,
                        onUse: () => onBattleItemUse(selectedBattleItemSlot!),
                        onClose: onBattleItemOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedHandInfoTile != null)
              Positioned.fill(
                child: Stack(
                  children: [
                    const GameInputBarrier.modal(),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 118,
                      child: GameHandTileInfoOverlay(
                        tile: selectedHandInfoTile!,
                        constrained: battle.isTileConstrained(
                          selectedHandInfoTile!,
                        ),
                        bossModifier: battle.bossModifier,
                        onClose: onHandTileInfoOverlayClose,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GameLayout extends StatelessWidget {
  const _GameLayout({
    required this.battle,
    required this.station,
    required this.market,
    required this.activeSettlementEffects,
    required this.activeSettlementStep,
    required this.activeSettlementEffectIndex,
    required this.activeSettlementEffectIndexes,
    required this.settlementGoalDisplayScore,
    required this.activeSettlementLine,
    required this.settlementSequenceTick,
    required this.settlementBoardSnapshot,
    required this.selectedHandTile,
    required this.selectedBoardRow,
    required this.selectedBoardCol,
    required this.boardMoveMode,
    required this.pendingBoardMoveSourceRow,
    required this.pendingBoardMoveSourceCol,
    required this.boardMoveBonusTargetCellKey,
    required this.boardMoveBonusFlashTick,
    required this.selectedJesterOverlayIndex,
    required this.selectedBattleItemSlot,
    required this.onHandTileLongPress,
    required this.suppressDebugChrome,
    required this.difficultyLabel,
    required this.battleBoardTutorialKey,
    required this.battlePreviewTutorialKey,
    required this.battleActionsTutorialKey,
    required this.battleHandTutorialKey,
    required this.onOptionsTap,
    required this.onTutorialTap,
    required this.onRunInfoTap,
    required this.onBlindInfoTap,
    required this.onDebugTap,
    required this.onJesterTap,
    required this.onHandTileTap,
    required this.onBoardCellTap,
    required this.onDraw,
    required this.onBoardDiscard,
    required this.onHandDiscard,
    required this.onStartBoardMove,
    required this.onBattleItemTap,
    required this.onConfirm,
    required this.onClearSelection,
  });

  final RummiBattleRuntimeFacade battle;
  final RummiStationRuntimeFacade station;
  final RummiMarketRuntimeFacade market;
  final List<RummiJesterEffectBreakdown> activeSettlementEffects;
  final ScoringPresentationStep activeSettlementStep;
  final int? activeSettlementEffectIndex;
  final List<int> activeSettlementEffectIndexes;
  final int? settlementGoalDisplayScore;
  final ConfirmedLineBreakdown? activeSettlementLine;
  final int settlementSequenceTick;
  final Map<String, Tile> settlementBoardSnapshot;
  final Tile? selectedHandTile;
  final int? selectedBoardRow;
  final int? selectedBoardCol;
  final bool boardMoveMode;
  final int? pendingBoardMoveSourceRow;
  final int? pendingBoardMoveSourceCol;
  final String? boardMoveBonusTargetCellKey;
  final int boardMoveBonusFlashTick;
  final int? selectedJesterOverlayIndex;
  final RummiBattleItemSlotView? selectedBattleItemSlot;
  final bool suppressDebugChrome;
  final String difficultyLabel;
  final GlobalKey battleBoardTutorialKey;
  final GlobalKey battlePreviewTutorialKey;
  final GlobalKey battleActionsTutorialKey;
  final GlobalKey battleHandTutorialKey;
  final VoidCallback onOptionsTap;
  final VoidCallback onTutorialTap;
  final VoidCallback onRunInfoTap;
  final VoidCallback onBlindInfoTap;
  final VoidCallback onDebugTap;
  final ValueChanged<int> onJesterTap;
  final ValueChanged<Tile> onHandTileTap;
  final ValueChanged<Tile> onHandTileLongPress;
  final void Function(int row, int col) onBoardCellTap;
  final VoidCallback onDraw;
  final VoidCallback onBoardDiscard;
  final VoidCallback onHandDiscard;
  final VoidCallback onStartBoardMove;
  final ValueChanged<RummiBattleItemSlotView> onBattleItemTap;
  final VoidCallback onConfirm;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final scoringCells = battle.scoringCellKeys;
    final constrainedCells = <String>{
      for (var row = 0; row < kBoardSize; row++)
        for (var col = 0; col < kBoardSize; col++)
          if (battle.board.cellAt(row, col) != null &&
              battle.isTileConstrained(battle.board.cellAt(row, col)!))
            '$row:$col',
    };
    final activeSettlementCells = activeSettlementLine == null
        ? <String>{}
        : {
            for (final (row, col) in activeSettlementLine!.contributingCells)
              '$row:$col',
          };
    final visibleSettlementEffects = _visibleSettlementEffects(
      activeSettlementEffects,
      activeSettlementStep,
      activeSettlementEffectIndex,
      activeSettlementEffectIndexes,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileWidth = boardTileVisualWidth(boardSide);

        return Column(
          children: [
            GameTopHud(
              station: station,
              battle: battle,
              difficultyLabel: difficultyLabel,
              onOptionsTap: onOptionsTap,
              onBlindInfoTap: onBlindInfoTap,
              stationGoalDisplayScore: settlementGoalDisplayScore,
              stationGoalPulse:
                  activeSettlementStep == ScoringPresentationStep.finalScore,
              stationGoalPulseTick: settlementSequenceTick,
              onTutorialTap: onTutorialTap,
            ),
            const SizedBox(height: 4),
            GameJesterZone(
              market: market,
              activeEffects: visibleSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              selectedIndex: selectedJesterOverlayIndex,
              onTapCard: onJesterTap,
            ),
            const SizedBox(height: 4),
            GameItemZoneSkeleton(
              battle: battle,
              activeEffects: visibleSettlementEffects,
              settlementSequenceTick: settlementSequenceTick,
              selectedSlotIndex: selectedBattleItemSlot?.slotIndex,
              onItemSlotTap: onBattleItemTap,
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return Align(
                          alignment: Alignment.center,
                          child: SizedBox.square(
                            dimension: side,
                            child: _GameTutorialTarget(
                              showcaseKey: battleBoardTutorialKey,
                              child: GameBoardGrid(
                                board: battle.board,
                                scoringCells: scoringCells,
                                constrainedScoringCells:
                                    battle.constrainedScoringCellKeys,
                                constrainedCells: constrainedCells,
                                activeSettlementCells: activeSettlementCells,
                                settlementBoardSnapshot:
                                    settlementBoardSnapshot,
                                selectedRow: selectedBoardRow,
                                selectedCol: selectedBoardCol,
                                boardMoveMode: boardMoveMode,
                                moveSourceRow: pendingBoardMoveSourceRow,
                                moveSourceCol: pendingBoardMoveSourceCol,
                                bonusFlashCellKey: boardMoveBonusTargetCellKey,
                                bonusFlashTick: boardMoveBonusFlashTick,
                                onTapCell: onBoardCellTap,
                                onLongPressTile: onHandTileLongPress,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: GameBoardEffectOverlay(
                      activeSettlementLine: activeSettlementLine,
                      activeSettlementStep: activeSettlementStep,
                      settlementSequenceTick: settlementSequenceTick,
                      frameInset: kBoardFrameInset,
                      gridGap: kBoardGridGap,
                    ),
                  ),
                  if (_showsBoardScoringCallout(activeSettlementStep) &&
                      activeSettlementLine != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 10,
                      child: _BoardScoringCallout(
                        key: ValueKey(
                          'board-score-$settlementSequenceTick-$activeSettlementStep',
                        ),
                        line: activeSettlementLine!,
                        step: activeSettlementStep,
                      ),
                    ),
                  if (AppConfig.showDebugFixtures && !suppressDebugChrome)
                    Positioned(
                      right: 0,
                      bottom: 16,
                      child: GameIconButtonChip(
                        tooltip: '디버그',
                        size: 34,
                        icon: Icons.bug_report_rounded,
                        iconSize: 16,
                        borderRadius: 8,
                        backgroundColor: GameUiPalette.marketNeutralButton,
                        onPressed: onDebugTap,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _GameTutorialTarget(
              showcaseKey: battlePreviewTutorialKey,
              child: _ScoringPreviewChip(
                preview: battle.scoringPreview,
                pendingConfirmItemCount: battle.pendingConfirmItemCount,
              ),
            ),
            const SizedBox(height: 4),
            _GameTutorialTarget(
              showcaseKey: battleActionsTutorialKey,
              child: _BattleActionBar(
                scoringPreview: battle.scoringPreview,
                canStartBoardMove:
                    !boardMoveMode &&
                    selectedBoardRow != null &&
                    selectedBoardCol != null &&
                    station.resources.boardMovesRemaining > 0,
                onConfirm: onConfirm,
                onClearSelection: onClearSelection,
                onRunInfo: onRunInfoTap,
                onStartBoardMove: onStartBoardMove,
                onBoardDiscard: onBoardDiscard,
                onHandDiscard: onHandDiscard,
                confirmEnabled: !boardMoveMode,
                utilityEnabled: !boardMoveMode,
              ),
            ),
            if (boardMoveMode) ...[
              const SizedBox(height: 4),
              Text(
                '빈 칸을 선택해 이동을 확정하세요. 원본 타일을 누르면 취소됩니다.',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameUiPalette.textPrimary.withValues(alpha: 0.74),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _GameTutorialTarget(
              showcaseKey: battleHandTutorialKey,
              child: GameHandZone(
                battle: battle,
                station: station,
                hand: battle.hand,
                selectedHandTile: selectedHandTile,
                onHandTileTap: onHandTileTap,
                onHandTileLongPress: onHandTileLongPress,
                onDraw: onDraw,
                tileWidth: tileWidth,
              ),
            ),
          ],
        );
      },
    );
  }
}

List<RummiJesterEffectBreakdown> _visibleSettlementEffects(
  List<RummiJesterEffectBreakdown> effects,
  ScoringPresentationStep step,
  int? effectIndex,
  List<int> effectIndexes,
) {
  if (step != ScoringPresentationStep.jester &&
      step != ScoringPresentationStep.item) {
    return const [];
  }
  if (effectIndexes.isNotEmpty) {
    return [
      for (final index in effectIndexes)
        if (index >= 0 && index < effects.length) effects[index],
    ];
  }
  if (effectIndex == null || effectIndex < 0 || effectIndex >= effects.length) {
    return const [];
  }
  return [effects[effectIndex]];
}

bool _showsBoardScoringCallout(ScoringPresentationStep step) {
  return step == ScoringPresentationStep.boardLine ||
      step == ScoringPresentationStep.handRank ||
      step == ScoringPresentationStep.overlap ||
      step == ScoringPresentationStep.constraint;
}

bool _showsFloatingSettlementBurst(ScoringPresentationStep step) {
  return step == ScoringPresentationStep.jester ||
      step == ScoringPresentationStep.item ||
      step == ScoringPresentationStep.finalScore;
}

int? _floatingSettlementEffectIndex(int? effectIndex, List<int> effectIndexes) {
  if (effectIndex != null) return effectIndex;
  return effectIndexes.length == 1 ? effectIndexes.single : null;
}

class _GameTutorialTarget extends StatelessWidget {
  const _GameTutorialTarget({required this.showcaseKey, required this.child});

  final GlobalKey showcaseKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: showcaseKey, child: child);
  }
}
