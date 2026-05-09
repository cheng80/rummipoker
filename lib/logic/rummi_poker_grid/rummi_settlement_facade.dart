import 'jester_meta.dart';
import 'hand_rank.dart';
import 'models/tile.dart';

/// Current cash-out result를 장기 Settlement 용어로 읽기 위한 read model.
///
/// Important:
/// - 현재 `RummiCashOutBreakdown` 계산/저장 semantics는 유지한다.
/// - 이 facade는 `GameView -> cash-out sheet` 경계를 얇게 만드는 용도다.
/// - settlement 화면 구조를 미리 전면 교체하지 않는다.
enum RummiSettlementEntryKind {
  stationReward,
  firstBlindClearBonus,
  boardDiscardReward,
  handDiscardReward,
  boardMoveReward,
  economyBonus,
  itemBonus,
  deckTileReward,
  overkillGrowthBonus,
}

class RummiSettlementEntryView {
  const RummiSettlementEntryView({
    required this.kind,
    required this.leadingLabel,
    required this.description,
    required this.gold,
    this.jesterId,
    this.itemId,
    this.displayName,
    this.tile,
  });

  final RummiSettlementEntryKind kind;
  final String leadingLabel;
  final String description;
  final int gold;
  final String? jesterId;
  final String? itemId;
  final String? displayName;
  final Tile? tile;

  bool get isEconomyBonus => kind == RummiSettlementEntryKind.economyBonus;
  bool get isItemBonus => kind == RummiSettlementEntryKind.itemBonus;
  bool get isFirstBlindClearBonus =>
      kind == RummiSettlementEntryKind.firstBlindClearBonus;
  bool get isOverkillGrowthBonus =>
      kind == RummiSettlementEntryKind.overkillGrowthBonus;
  bool get isBonus =>
      isFirstBlindClearBonus ||
      isEconomyBonus ||
      isItemBonus ||
      isOverkillGrowthBonus;
  bool get isDeckTileReward => kind == RummiSettlementEntryKind.deckTileReward;
}

class RummiSettlementRuntimeFacade {
  const RummiSettlementRuntimeFacade({
    required this.stageIndex,
    required this.targetScore,
    required this.currentGold,
    required this.totalGold,
    required this.entries,
  });

  factory RummiSettlementRuntimeFacade.fromCashOut({
    required RummiCashOutBreakdown breakdown,
    required int currentGold,
  }) {
    final entries = <RummiSettlementEntryView>[
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.stationReward,
        leadingLabel: _stationSettlementLabel(breakdown.stageIndex),
        description: breakdown.stageIndex > 8
            ? '무한 도전 목표 ${breakdown.targetScore} 달성 보상'
            : 'Station Goal ${breakdown.targetScore} 달성 보상',
        gold: breakdown.blindReward,
      ),
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.boardDiscardReward,
        leadingLabel: '${breakdown.remainingBoardDiscards}',
        description:
            '남은 보드 버림 ${breakdown.remainingBoardDiscards}회 x ${breakdown.perBoardDiscardBonus}',
        gold: breakdown.boardDiscardGold,
      ),
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.handDiscardReward,
        leadingLabel: '${breakdown.remainingHandDiscards}',
        description:
            '남은 손패 버림 ${breakdown.remainingHandDiscards}회 x ${breakdown.perHandDiscardBonus}',
        gold: breakdown.handDiscardGold,
      ),
      RummiSettlementEntryView(
        kind: RummiSettlementEntryKind.boardMoveReward,
        leadingLabel: '${breakdown.remainingBoardMoves}',
        description:
            '남은 보드 이동 ${breakdown.remainingBoardMoves}회 x ${breakdown.perBoardMoveBonus}',
        gold: breakdown.boardMoveGold,
      ),
      if (breakdown.firstBlindClearBonusGold > 0)
        RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.firstBlindClearBonus,
          leadingLabel: 'First',
          description: '첫 블라인드 클리어 보너스',
          gold: breakdown.firstBlindClearBonusGold,
        ),
      ...breakdown.economyBonuses.map(
        (bonus) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.economyBonus,
          leadingLabel: 'J',
          description: '${bonus.displayName} 보너스',
          gold: bonus.gold,
          jesterId: bonus.jesterId,
          displayName: bonus.displayName,
        ),
      ),
      ...breakdown.itemBonuses.map(
        (bonus) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.itemBonus,
          leadingLabel: 'I',
          description: '${bonus.displayName} 보너스',
          gold: bonus.gold,
          itemId: bonus.itemId,
          displayName: bonus.displayName,
        ),
      ),
      ...breakdown.deckTileRewards.map(
        (tile) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.deckTileReward,
          leadingLabel: 'Tile',
          description: '보스 클리어 보상 - 다음 전투 덱에 추가',
          gold: 0,
          tile: tile,
        ),
      ),
      ...breakdown.overkillGrowthBonuses.map(
        (bonus) => RummiSettlementEntryView(
          kind: RummiSettlementEntryKind.overkillGrowthBonus,
          leadingLabel: 'Growth',
          description:
              '초과 달성: ${_handRankLabel(bonus.rank)} 성장 +${bonus.amount}',
          gold: 0,
          displayName: _handRankLabel(bonus.rank),
        ),
      ),
    ];

    return RummiSettlementRuntimeFacade(
      stageIndex: breakdown.stageIndex,
      targetScore: breakdown.targetScore,
      currentGold: currentGold,
      totalGold: breakdown.totalGold,
      entries: List<RummiSettlementEntryView>.unmodifiable(entries),
    );
  }

  final int stageIndex;
  final int targetScore;
  final int currentGold;
  final int totalGold;
  final List<RummiSettlementEntryView> entries;

  bool get isEndless => stageIndex > 8;
}

String _stationSettlementLabel(int stageIndex) {
  return stageIndex > 8 ? '무한 S$stageIndex' : 'Station $stageIndex';
}

String _handRankLabel(RummiHandRank rank) {
  return switch (rank) {
    RummiHandRank.highCard => '하이',
    RummiHandRank.onePair => '원페어',
    RummiHandRank.twoPair => '투페어',
    RummiHandRank.threeOfAKind => '트리플',
    RummiHandRank.straight => '스트레이트',
    RummiHandRank.flush => '플러시',
    RummiHandRank.fullHouse => '풀하우스',
    RummiHandRank.fourOfAKind => '포카드',
    RummiHandRank.straightFlush => '스티플',
    RummiHandRank.prismStraight => '프리즘 스트레이트',
    RummiHandRank.crownFourOfAKind => '크라운 포카드',
    RummiHandRank.lowStraightFlush => '로우 스티플',
    RummiHandRank.royalStraightFlush => '로열 스티플',
    RummiHandRank.fiveOfAKind => '파이브 카드',
  };
}
