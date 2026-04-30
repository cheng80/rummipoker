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
    for (final line in lines) {
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
    );
  }

  final int lineCount;
  final RummiHandRank representativeRank;
  final int baseScore;
  final int overlapBonus;
  final int expectedJesterEffectCount;
  final int expectedItemEffectCount;
  final int expectedScore;

  int get expectedEffectCount =>
      expectedJesterEffectCount + expectedItemEffectCount;
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
    this.bossModifier,
    this.scoringPreview,
    this.itemSlots = const [],
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

    return RummiBattleRuntimeFacade(
      stageIndex: runProgress.stageIndex,
      currentBlindTierIndex: runProgress.currentStationBlindTierIndex,
      currentGold: runProgress.gold,
      totalDeckSize: session.totalDeckSize,
      board: session.board,
      hand: List<Tile>.unmodifiable(session.hand),
      scoringCellKeys: Set<String>.unmodifiable(scoringCellKeys),
      bossModifier: session.blind.bossModifier,
      scoringPreview: scoringPreview,
      itemSlots: const [],
    );
  }

  RummiBattleRuntimeFacade withItemSlots(
    List<RummiBattleItemSlotView> nextItemSlots,
  ) {
    return RummiBattleRuntimeFacade(
      stageIndex: stageIndex,
      currentBlindTierIndex: currentBlindTierIndex,
      currentGold: currentGold,
      totalDeckSize: totalDeckSize,
      board: board,
      hand: hand,
      scoringCellKeys: scoringCellKeys,
      bossModifier: bossModifier,
      scoringPreview: scoringPreview,
      itemSlots: List<RummiBattleItemSlotView>.unmodifiable(nextItemSlots),
    );
  }

  final int stageIndex;
  final int currentBlindTierIndex;
  final int currentGold;
  final int totalDeckSize;
  final RummiBoard board;
  final List<Tile> hand;
  final Set<String> scoringCellKeys;
  final RummiBossModifier? bossModifier;
  final RummiScoringPreview? scoringPreview;
  final List<RummiBattleItemSlotView> itemSlots;

  bool isTileConstrained(Tile tile) => bossModifier?.affectsTile(tile) ?? false;
}
