import 'hand_rank.dart';
import 'boss_modifier.dart';
import 'models/board.dart';
import 'models/tile.dart';
import 'rummi_poker_grid_session.dart';
import 'item_definition.dart';
import 'jester_meta.dart';
import 'owned_content_instance.dart';

class RummiScoringPreview {
  const RummiScoringPreview({
    required this.lineCount,
    required this.representativeRank,
    required this.baseScore,
    required this.overlapBonus,
    required this.expectedJesterEffectCount,
    required this.expectedItemEffectCount,
    required this.expectedScore,
    required this.constraintPenaltyPercent,
  });

  factory RummiScoringPreview.fromBreakdowns({
    required List<ConfirmedLineBreakdown> lines,
    required int expectedScore,
    required Set<String> jesterIds,
  }) {
    final representative = lines.reduce(
      (best, line) => line.finalScore > best.finalScore ? line : best,
    );
    final effectIds = <String>{};
    var jesterEffectCount = 0;
    var itemEffectCount = 0;
    RummiConstraintPenaltyBreakdown? constraintPenalty;
    for (final line in lines) {
      if (constraintPenalty == null && line.constraintPenalties.isNotEmpty) {
        constraintPenalty = line.constraintPenalties.first;
      }
      for (final effect in line.effects) {
        final key = '${effect.jesterId}:${effect.displayToken}';
        if (!effectIds.add(key)) continue;
        if (jesterIds.contains(effect.jesterId)) {
          jesterEffectCount += 1;
        } else {
          itemEffectCount += 1;
        }
      }
    }
    return RummiScoringPreview(
      lineCount: lines.length,
      representativeRank: representative.rank,
      baseScore: lines.fold<int>(0, (sum, line) => sum + line.baseScore),
      overlapBonus: lines.fold<int>(0, (sum, line) => sum + line.overlapBonus),
      expectedJesterEffectCount: jesterEffectCount,
      expectedItemEffectCount: itemEffectCount,
      expectedScore: expectedScore,
      constraintPenaltyPercent: constraintPenalty == null
          ? null
          : ((1 - constraintPenalty.scoreMultiplier) * 100).round(),
    );
  }

  final int lineCount;
  final RummiHandRank representativeRank;
  final int baseScore;
  final int overlapBonus;
  final int expectedJesterEffectCount;
  final int expectedItemEffectCount;
  final int expectedScore;
  final int? constraintPenaltyPercent;

  int get expectedEffectCount =>
      expectedJesterEffectCount + expectedItemEffectCount;
  bool get hasConstraintPenalty => constraintPenaltyPercent != null;
}

class RummiBattleItemSlotView {
  const RummiBattleItemSlotView({
    required this.slotIndex,
    required this.slotLabel,
    required this.contentId,
    required this.displayName,
    required this.displayNameKey,
    required this.effectText,
    required this.effectTextKey,
    required this.count,
    required this.placement,
    required this.usableInBattle,
    required this.item,
  });

  factory RummiBattleItemSlotView.fromOwnedItem({
    required int slotIndex,
    required String slotLabel,
    required OwnedItemEntry entry,
    required ItemDefinition item,
  }) {
    return RummiBattleItemSlotView.fromInstance(
      slotIndex: slotIndex,
      slotLabel: slotLabel,
      instance: OwnedItemInstance(entry: entry, definition: item),
    );
  }

  factory RummiBattleItemSlotView.fromInstance({
    required int slotIndex,
    required String slotLabel,
    required OwnedItemInstance instance,
  }) {
    return RummiBattleItemSlotView(
      slotIndex: slotIndex,
      slotLabel: slotLabel,
      contentId: instance.id,
      displayName: instance.displayName,
      displayNameKey: instance.displayNameKey,
      effectText: instance.effectText,
      effectTextKey: instance.effectTextKey,
      count: instance.count,
      placement: instance.placement,
      usableInBattle: instance.usableInBattle,
      item: instance.definition,
    );
  }

  final int slotIndex;
  final String slotLabel;
  final String contentId;
  final String displayName;
  final String displayNameKey;
  final String effectText;
  final String effectTextKey;
  final int count;
  final ItemPlacement placement;
  final bool usableInBattle;
  final ItemDefinition item;
}

/// Read-only facade for the current battle screen.
///
/// Important:
/// - This is a compatibility/read-path adapter only.
/// - It keeps battle UI from depending on the full mutable runtime object graph.
class RummiBattleRuntimeFacade {
  const RummiBattleRuntimeFacade({
    required this.stageIndex,
    this.currentBlindTierIndex = 0,
    required this.currentGold,
    required this.totalDeckSize,
    required this.board,
    required this.hand,
    required this.scoringCellKeys,
    this.constrainedScoringCellKeys = const {},
    this.bossModifier,
    this.scoringPreview,
    this.pendingConfirmItemCount = 0,
    this.pendingBoardMoveSlideBonus = false,
    this.itemSlots = const [],
    this.quickSlotCapacity = RunInventoryState.defaultQuickSlotCapacity,
    this.passiveRelicCapacity = RunInventoryState.defaultPassiveRelicCapacity,
  });

  factory RummiBattleRuntimeFacade.fromRuntime({
    required RummiPokerGridSession session,
    required RummiRunProgress runProgress,
  }) {
    final scoringCellKeys = <String>{};
    final lines = session.engine.listEvaluatedLines(session.board);
    for (final line in lines) {
      if (line.report.evaluation.isDeadLine) continue;
      final refs = line.ref.cells();
      for (final index in line.report.evaluation.contributingIndexes) {
        if (index < 0 || index >= refs.length) continue;
        final (row, col) = refs[index];
        scoringCellKeys.add('$row:$col');
      }
    }

    final previewSession = session.copySnapshot();
    final previewOut = previewSession.confirmAllFullLines(
      jesters: runProgress.ownedJesters,
      runtimeSnapshot: runProgress.buildRuntimeSnapshot(),
      applyScoreToBlind: false,
    );
    final scoringPreview = previewOut.result.ok
        ? RummiScoringPreview.fromBreakdowns(
            lines: previewOut.result.lineBreakdowns,
            expectedScore: previewOut.result.scoreAdded,
            jesterIds: {
              for (final jester in runProgress.ownedJesters) jester.id,
            },
          )
        : null;
    final constrainedScoringCellKeys = <String>{};
    if (previewOut.result.ok) {
      for (final line in previewOut.result.lineBreakdowns) {
        if (line.constraintPenalties.isEmpty) continue;
        for (final (row, col) in _constrainedPreviewCells(
          line: line,
          board: session.board,
          modifier: session.blind.bossModifier,
        )) {
          constrainedScoringCellKeys.add('$row:$col');
        }
      }
    }

    return RummiBattleRuntimeFacade(
      stageIndex: runProgress.stageIndex,
      currentBlindTierIndex: runProgress.currentStationBlindTierIndex,
      currentGold: runProgress.gold,
      totalDeckSize: session.totalDeckSize,
      board: session.board,
      hand: List<Tile>.unmodifiable(session.hand),
      scoringCellKeys: Set<String>.unmodifiable(scoringCellKeys),
      constrainedScoringCellKeys: Set<String>.unmodifiable(
        constrainedScoringCellKeys,
      ),
      bossModifier: session.blind.bossModifier,
      scoringPreview: scoringPreview,
      pendingConfirmItemCount: _pendingManualConfirmModifierCount(
        session.confirmModifiers,
      ),
      pendingBoardMoveSlideBonus: session.nextBoardMoveSlideBonusQueued,
      itemSlots: const [],
      quickSlotCapacity: runProgress.quickSlotCapacity(),
      passiveRelicCapacity: runProgress.passiveRelicCapacity(),
    );
  }

  RummiBattleRuntimeFacade withItemSlots(
    List<RummiBattleItemSlotView> nextItemSlots, {
    int? quickSlotCapacity,
    int? passiveRelicCapacity,
  }) {
    return RummiBattleRuntimeFacade(
      stageIndex: stageIndex,
      currentBlindTierIndex: currentBlindTierIndex,
      currentGold: currentGold,
      totalDeckSize: totalDeckSize,
      board: board,
      hand: hand,
      scoringCellKeys: scoringCellKeys,
      constrainedScoringCellKeys: constrainedScoringCellKeys,
      bossModifier: bossModifier,
      scoringPreview: scoringPreview,
      pendingConfirmItemCount: pendingConfirmItemCount,
      pendingBoardMoveSlideBonus: pendingBoardMoveSlideBonus,
      itemSlots: List<RummiBattleItemSlotView>.unmodifiable(nextItemSlots),
      quickSlotCapacity: quickSlotCapacity ?? this.quickSlotCapacity,
      passiveRelicCapacity: passiveRelicCapacity ?? this.passiveRelicCapacity,
    );
  }

  final int stageIndex;
  final int currentBlindTierIndex;
  final int currentGold;
  final int totalDeckSize;
  final RummiBoard board;
  final List<Tile> hand;
  final Set<String> scoringCellKeys;
  final Set<String> constrainedScoringCellKeys;
  final RummiBossModifier? bossModifier;
  final RummiScoringPreview? scoringPreview;
  final int pendingConfirmItemCount;
  final bool pendingBoardMoveSlideBonus;
  final List<RummiBattleItemSlotView> itemSlots;
  final int quickSlotCapacity;
  final int passiveRelicCapacity;

  bool isTileConstrained(Tile tile) => bossModifier?.affectsTile(tile) ?? false;
}

int _pendingManualConfirmModifierCount(
  Iterable<RummiConfirmModifier> modifiers,
) {
  return modifiers
      .where(
        (modifier) =>
            modifier.consumeOnApply &&
            modifier.timing.startsWith('next_confirm'),
      )
      .length;
}

Iterable<(int, int)> _constrainedPreviewCells({
  required ConfirmedLineBreakdown line,
  required RummiBoard board,
  required RummiBossModifier? modifier,
}) sync* {
  if (modifier == null) return;
  switch (modifier.category) {
    case RummiBossModifierCategory.tileColorWeaken:
    case RummiBossModifierCategory.faceTileWeaken:
      for (final (row, col) in line.contributingCells) {
        final tile = board.cellAt(row, col);
        if (tile != null && modifier.affectsTile(tile)) {
          yield (row, col);
        }
      }
    case RummiBossModifierCategory.lineKindWeaken:
    case RummiBossModifierCategory.allScoreWeaken:
    case RummiBossModifierCategory.firstConfirmWeaken:
    case RummiBossModifierCategory.confirmCountWeaken:
      yield* line.contributingCells;
    case RummiBossModifierCategory.repeatHandRankWeaken:
    case RummiBossModifierCategory.singleHandRankPressure:
      return;
  }
}
